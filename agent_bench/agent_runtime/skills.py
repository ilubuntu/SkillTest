# -*- coding: utf-8 -*-
"""Agent Skill 检查与日志。"""

import json
import os
import shutil
import sys

from agent_bench.agent_runtime.spec import AgentSpec
from agent_bench.opencode_cli import resolve_opencode_config_root, run_opencode_command


def _run_opencode_debug_command(*args: str) -> tuple[bool, str, str]:
    return run_opencode_command("debug", *args, timeout=10)


def _resolve_opencode_config_root() -> str:
    return resolve_opencode_config_root()


def _notify(on_progress, level: str, message: str):
    if on_progress:
        on_progress("log", {"level": level, "message": message})


def log_agent_configuration(agent_spec: AgentSpec, on_progress):
    _notify(on_progress, "INFO", "，".join(
        part for part in [
            f"读取 Agent 配置: 名称={agent_spec.display_name}",
            f"适配器={agent_spec.adapter}",
            f"内部Agent={agent_spec.opencode_agent}" if agent_spec.adapter.lower() == "opencode" and agent_spec.opencode_agent else "",
            f"模型={agent_spec.model}",
            f"skills={', '.join(agent_spec.mounted_skill_names)}" if agent_spec.mounted_skill_names else "",
        ] if part
    ))
    if agent_spec.mounted_skill_names:
        _notify(on_progress, "WARNING", f"检测 Agent 是否正确挂载 skill: {', '.join(agent_spec.mounted_skill_names)}")


def _run_opencode_debug_skill() -> tuple[bool, list[dict], str]:
    try:
        ok, stdout, error_message = _run_opencode_debug_command("skill")
        if not ok:
            return False, [], error_message
        payload = json.loads(stdout or "[]")
        items = payload if isinstance(payload, list) else []
        normalized = [item for item in items if isinstance(item, dict)]
        return True, normalized, ""
    except Exception as exc:
        return False, [], str(exc)


def _opencode_has_skill(skill_name: str) -> tuple[bool, str]:
    ok, items, error_message = _run_opencode_debug_skill()
    if not ok:
        return False, error_message
    found = any(
        str(item.get("name") or "").strip() == skill_name
        for item in items
    )
    return found, ""


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


def _resolve_opencode_skill_root() -> str:
    return os.path.join(_resolve_opencode_config_root(), "skills")


def _remove_existing_path(path: str):
    if not os.path.lexists(path):
        return
    if os.path.islink(path) or os.path.isfile(path):
        os.unlink(path)
        return
    shutil.rmtree(path)


def _mount_skill_directory(skill_name: str, source_dir: str, on_progress) -> bool:
    target_root = _resolve_opencode_skill_root()
    target_dir = os.path.join(target_root, skill_name)
    _notify(on_progress, "WARNING", f"开始挂载 skill: {skill_name}")
    _notify(on_progress, "INFO", f"skill 挂载源目录: {source_dir}")
    _notify(on_progress, "INFO", f"skill 挂载目标目录: {target_dir}")

    if not os.path.isdir(source_dir):
        _notify(on_progress, "ERROR", f"skill 挂载失败: 源目录不存在 {source_dir}")
        return False

    try:
        os.makedirs(target_root, exist_ok=True)
        if os.path.lexists(target_dir):
            _remove_existing_path(target_dir)
        shutil.copytree(source_dir, target_dir)
        _notify(on_progress, "INFO", f"skill 挂载完成: {target_dir} (copy)")
        return True
    except Exception as exc:
        _notify(on_progress, "ERROR", f"skill 挂载失败: {exc}")
        return False


def _validate_mounted_skill_target(skill_name: str, skill_path: str, on_progress) -> bool:
    target_dir = os.path.join(_resolve_opencode_skill_root(), skill_name)
    target_skill_md = os.path.join(target_dir, "SKILL.md")
    if not os.path.isdir(target_dir):
        _notify(on_progress, "ERROR", f"skill 挂载校验失败: 目标目录不存在 {target_dir}")
        return False
    if not os.path.isfile(target_skill_md):
        _notify(on_progress, "ERROR", f"skill 挂载校验失败: 目标目录缺少 SKILL.md {target_skill_md}")
        return False
    try:
        source_dir = _resolve_declared_skill_source(skill_path)
        _notify(on_progress, "INFO", f"skill 挂载校验通过: source={source_dir} target={target_dir}")
    except Exception:
        _notify(on_progress, "INFO", f"skill 挂载校验通过: target={target_dir}")
    return True


def _try_mount_opencode_skill(skill_name: str, skill_path: str, on_progress) -> bool:
    try:
        source_dir = _resolve_declared_skill_source(skill_path)
    except Exception as exc:
        _notify(on_progress, "ERROR", f"{skill_name} 挂载失败: 无法解析 skill 路径: {exc}")
        return False
    return _mount_skill_directory(skill_name, source_dir, on_progress)


def verify_runtime_skills(agent_spec: AgentSpec, on_progress) -> dict:
    if agent_spec.adapter.lower() != "opencode":
        return {"ok": True, "mounted": False}
    all_ok = True
    mounted_any = False
    for skill_spec in agent_spec.mounted_skills:
        skill_name = skill_spec.name
        if not skill_name:
            continue
        _notify(on_progress, "WARNING", f"{agent_spec.display_name} skill 检测开始: 正在通过 `opencode debug skill` 检查 OpenCode 是否正确配置 {skill_name}")
        found, error_message = _opencode_has_skill(skill_name)
        if found:
            _notify(on_progress, "INFO", f"{agent_spec.display_name} skill 检测完成: 已通过 `opencode debug skill` 确认 OpenCode 已正确配置 {skill_name}")
            continue
        if error_message:
            _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 检测命令异常: {error_message}")

        _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 初次检测结果: `opencode debug skill` 未检测到 {skill_name}")
        if _try_mount_opencode_skill(skill_name, skill_spec.path, on_progress):
            mounted_any = True
            if not _validate_mounted_skill_target(skill_name, skill_spec.path, on_progress):
                all_ok = False
                continue
            _notify(on_progress, "WARNING", f"{agent_spec.display_name} skill 复检开始: 挂载完成后，再次执行 `opencode debug skill` 检查 {skill_name}")
            found, error_message = _opencode_has_skill(skill_name)
            if found:
                _notify(on_progress, "INFO", f"{agent_spec.display_name} skill 检测完成: 已通过 `opencode debug skill` 确认尝试挂载后 OpenCode 已正确配置 {skill_name}")
                continue
            if error_message:
                _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 复检命令异常: {error_message}")
        _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 检测完成: 尝试挂载后再次执行 `opencode debug skill`，仍未检测到 {skill_name}")
        all_ok = False
    return {"ok": all_ok, "mounted": mounted_any}
