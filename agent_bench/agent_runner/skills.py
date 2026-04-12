# -*- coding: utf-8 -*-
"""Agent Skill 检查与日志。"""

import hashlib
import os
import shutil
import sys

from agent_bench.agent_runner.opencode_env import resolve_opencode_config_root
from agent_bench.agent_runner.spec import AgentSpec


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


def _opencode_has_skill(skill_name: str) -> tuple[bool, str]:
    target_dir = os.path.join(_resolve_opencode_skill_root(), skill_name)
    target_skill_md = os.path.join(target_dir, "SKILL.md")
    if os.path.isdir(target_dir) and os.path.isfile(target_skill_md):
        return True, ""
    return False, f"missing skill dir or SKILL.md: {target_dir}"


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


def _sync_mounted_skill_if_needed(skill_name: str, skill_path: str, on_progress) -> bool:
    try:
        source_dir = _resolve_declared_skill_source(skill_path)
    except Exception as exc:
        _notify(on_progress, "ERROR", f"{skill_name} 同步失败: 无法解析 skill 路径: {exc}")
        return False

    target_dir = os.path.join(_resolve_opencode_skill_root(), skill_name)
    source_fp = _directory_fingerprint(source_dir)
    target_fp = _directory_fingerprint(target_dir)
    if source_fp and source_fp == target_fp:
        return False

    _notify(on_progress, "WARNING", f"{skill_name} 本地副本不是最新版本，开始同步到 OpenCode skills 目录")
    return _mount_skill_directory(skill_name, source_dir, on_progress)


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
        if _sync_mounted_skill_if_needed(skill_name, skill_spec.path, on_progress):
            mounted_any = True
        _notify(on_progress, "WARNING", f"{agent_spec.display_name} skill 检测开始: 正在检查 OpenCode 配置目录中是否存在 {skill_name}")
        found, error_message = _opencode_has_skill(skill_name)
        if found:
            _notify(on_progress, "INFO", f"{agent_spec.display_name} skill 检测完成: 已确认 OpenCode 配置目录中存在 {skill_name}")
            continue
        if error_message:
            _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 检测命令异常: {error_message}")

        _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 初次检测结果: OpenCode 配置目录中未检测到 {skill_name}")
        if _try_mount_opencode_skill(skill_name, skill_spec.path, on_progress):
            mounted_any = True
            if not _validate_mounted_skill_target(skill_name, skill_spec.path, on_progress):
                all_ok = False
                continue
            _notify(on_progress, "WARNING", f"{agent_spec.display_name} skill 复检开始: 挂载完成后，再次检查 OpenCode 配置目录中的 {skill_name}")
            found, error_message = _opencode_has_skill(skill_name)
            if found:
                _notify(on_progress, "INFO", f"{agent_spec.display_name} skill 检测完成: 已确认尝试挂载后 OpenCode 配置目录中存在 {skill_name}")
                continue
            if error_message:
                _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 复检命令异常: {error_message}")
        _notify(on_progress, "ERROR", f"{agent_spec.display_name} skill 检测完成: 尝试挂载后再次检查 OpenCode 配置目录，仍未检测到 {skill_name}")
        all_ok = False
    return {"ok": all_ok, "mounted": mounted_any}
