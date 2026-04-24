# -*- coding: utf-8 -*-
"""Agent Skill 检查、任务级本地配置与日志。"""

import hashlib
import json
import os
import shutil
import sys

from agent_bench.agent_runner.spec import AgentSpec


def _notify(on_progress, level: str, message: str):
    if on_progress:
        on_progress("log", {"level": level, "message": message})


def log_agent_configuration(agent_spec: AgentSpec, on_progress):
    _notify(on_progress, "INFO", "，".join(
        part for part in [
            f"读取 Agent 配置: 名称={agent_spec.display_name}",
            f"内部Agent={agent_spec.opencode_agent}" if agent_spec.opencode_agent else "",
            f"模型={agent_spec.model}",
            f"skills={', '.join(agent_spec.mounted_skill_names)}" if agent_spec.mounted_skill_names else "",
        ] if part
    ))
    if agent_spec.mounted_skill_names:
        _notify(on_progress, "WARNING", f"检测 Agent 是否正确准备任务级 skill: {', '.join(agent_spec.mounted_skill_names)}")


def _runtime_root_dir() -> str:
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.getcwd()


def _resolve_declared_skill_source(skill_path: str) -> str:
    if not skill_path:
        raise FileNotFoundError("skill path 为空")
    if os.path.isabs(skill_path):
        return skill_path
    return os.path.normpath(os.path.join(_runtime_root_dir(), skill_path))


def _workspace_opencode_dir(workspace_dir: str) -> str:
    return os.path.join(workspace_dir, ".opencode")


def _workspace_opencode_skill_root(workspace_dir: str) -> str:
    return os.path.join(_workspace_opencode_dir(workspace_dir), "skills")


def _workspace_opencode_config_path(workspace_dir: str) -> str:
    return os.path.join(workspace_dir, "opencode.json")


def _xdg_opencode_runtime_template_dir() -> str:
    return os.path.join(_runtime_root_dir(), ".opencode_runtime", "xdg_config", "opencode")


def _remove_existing_path(path: str):
    if not os.path.lexists(path):
        return
    if os.path.islink(path) or os.path.isfile(path):
        os.unlink(path)
        return
    shutil.rmtree(path)


def _directory_fingerprint(path: str) -> str:
    if not os.path.isdir(path):
        return ""
    digest = hashlib.sha256()
    for current_root, dirnames, filenames in os.walk(path):
        dirnames.sort()
        filenames.sort()
        rel_root = os.path.relpath(current_root, path).replace("\\", "/")
        digest.update(f"D:{rel_root}\n".encode("utf-8"))
        for filename in filenames:
            full_path = os.path.join(current_root, filename)
            rel_path = os.path.relpath(full_path, path).replace("\\", "/")
            digest.update(f"F:{rel_path}\n".encode("utf-8"))
            try:
                with open(full_path, "rb") as file_obj:
                    digest.update(file_obj.read())
            except Exception:
                digest.update(b"[unreadable]")
    return digest.hexdigest()


def _skill_tool_enabled(agent_spec: AgentSpec) -> bool:
    tools = agent_spec.raw.get("tools") if isinstance(agent_spec.raw, dict) else {}
    if not isinstance(tools, dict):
        return False
    return bool(tools.get("skill"))


def _seed_workspace_opencode_runtime(workspace_dir: str, on_progress) -> bool:
    source_dir = _xdg_opencode_runtime_template_dir()
    target_dir = _workspace_opencode_dir(workspace_dir)
    if not os.path.isdir(source_dir):
        return False

    copied_any = False
    for name in [".gitignore", "package.json", "package-lock.json", "node_modules"]:
        source_path = os.path.join(source_dir, name)
        target_path = os.path.join(target_dir, name)
        if not os.path.exists(source_path) or os.path.lexists(target_path):
            continue
        try:
            if os.path.isdir(source_path):
                shutil.copytree(source_path, target_path)
            else:
                shutil.copy2(source_path, target_path)
            copied_any = True
        except Exception as exc:
            _notify(on_progress, "WARNING", f"任务级 .opencode 预热失败[{name}]: {exc}")
    if copied_any:
        _notify(on_progress, "INFO", f"已从 XDG 预热任务级 .opencode 运行时目录: {target_dir}")
    return copied_any


def _write_workspace_opencode_config(agent_spec: AgentSpec, workspace_dir: str, on_progress) -> str:
    """
    为当前任务的 workspace 写入项目级 OpenCode 配置。

    这里不再依赖全局 ~/.config/opencode，而是把 skill 白名单和 tool 开关收敛到
    当前任务目录。这样多个任务共享一个 OpenCode 服务时，仍可通过 request 的
    directory 参数按任务隔离可见 skill 集。
    """
    config_path = _workspace_opencode_config_path(workspace_dir)
    allowed_skills = [name for name in agent_spec.mounted_skill_names if name]
    skill_enabled = _skill_tool_enabled(agent_spec)

    config = {
        "$schema": "https://opencode.ai/config.json",
        "permission": {
            "skill": {
                "*": "deny",
            },
        },
        "tools": {
            "skill": skill_enabled,
        },
    }
    for skill_name in allowed_skills:
        config["permission"]["skill"][skill_name] = "allow"
    if agent_spec.opencode_agent:
        config["agent"] = {
            agent_spec.opencode_agent: {
                "tools": {
                    "skill": skill_enabled,
                },
            },
        }

    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    _notify(on_progress, "INFO", f"已写入任务级 OpenCode 配置: {config_path}")
    return config_path


def _mount_skill_directory(skill_name: str, source_dir: str, target_root: str, on_progress) -> bool:
    target_dir = os.path.join(target_root, skill_name)
    _notify(on_progress, "WARNING", f"开始准备任务级 skill: {skill_name}")
    _notify(on_progress, "INFO", f"skill 源目录: {source_dir}")
    _notify(on_progress, "INFO", f"skill 目标目录: {target_dir}")

    if not os.path.isdir(source_dir):
        _notify(on_progress, "ERROR", f"skill 准备失败: 源目录不存在 {source_dir}")
        return False

    try:
        os.makedirs(target_root, exist_ok=True)
        if os.path.lexists(target_dir):
            _remove_existing_path(target_dir)
        shutil.copytree(source_dir, target_dir)
        _notify(on_progress, "INFO", f"skill 已复制到任务目录: {target_dir}")
        return True
    except Exception as exc:
        _notify(on_progress, "ERROR", f"skill 准备失败: {exc}")
        return False


def _sync_workspace_skill_if_needed(skill_name: str, skill_path: str, workspace_dir: str, on_progress) -> bool:
    source_dir = _resolve_declared_skill_source(skill_path)
    target_dir = os.path.join(_workspace_opencode_skill_root(workspace_dir), skill_name)
    source_fp = _directory_fingerprint(source_dir)
    target_fp = _directory_fingerprint(target_dir)
    if source_fp and source_fp == target_fp:
        return False
    return _mount_skill_directory(skill_name, source_dir, _workspace_opencode_skill_root(workspace_dir), on_progress)


def _validate_workspace_skill_target(skill_name: str, workspace_dir: str, on_progress) -> bool:
    target_dir = os.path.join(_workspace_opencode_skill_root(workspace_dir), skill_name)
    target_skill_md = os.path.join(target_dir, "SKILL.md")
    if not os.path.isdir(target_dir):
        _notify(on_progress, "ERROR", f"任务级 skill 校验失败: 目标目录不存在 {target_dir}")
        return False
    if not os.path.isfile(target_skill_md):
        _notify(on_progress, "ERROR", f"任务级 skill 校验失败: 缺少 SKILL.md {target_skill_md}")
        return False
    _notify(on_progress, "INFO", f"任务级 skill 校验通过: {target_dir}")
    return True


def verify_runtime_skills(agent_spec: AgentSpec, workspace_dir: str, on_progress) -> dict:
    if not workspace_dir or not os.path.isdir(workspace_dir):
        _notify(on_progress, "ERROR", f"{agent_spec.display_name} 运行前 skill 校验失败: workspace 不存在 {workspace_dir}")
        return {"ok": False, "mounted": False}

    os.makedirs(_workspace_opencode_dir(workspace_dir), exist_ok=True)
    _seed_workspace_opencode_runtime(workspace_dir, on_progress)
    config_path = _write_workspace_opencode_config(agent_spec, workspace_dir, on_progress)

    all_ok = True
    mounted_any = False
    for skill_spec in agent_spec.mounted_skills:
        skill_name = skill_spec.name
        if not skill_name:
            continue
        try:
            if _sync_workspace_skill_if_needed(skill_name, skill_spec.path, workspace_dir, on_progress):
                mounted_any = True
        except Exception as exc:
            _notify(on_progress, "ERROR", f"{skill_name} 同步失败: {exc}")
            all_ok = False
            continue
        if not _validate_workspace_skill_target(skill_name, workspace_dir, on_progress):
            all_ok = False

    if not agent_spec.mounted_skills:
        _notify(on_progress, "INFO", f"{agent_spec.display_name} 未声明任务级 skill，已仅生成项目级 OpenCode 配置")

    return {
        "ok": all_ok,
        "mounted": mounted_any,
        "config_path": config_path,
        "skill_root": _workspace_opencode_skill_root(workspace_dir),
    }
