# -*- coding: utf-8 -*-
"""产物持久化。"""

import json
import os
import re

ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")


def _strip_ansi_sequences(value):
    if isinstance(value, str):
        return ANSI_ESCAPE_RE.sub("", value)
    if isinstance(value, dict):
        return {key: _strip_ansi_sequences(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_strip_ansi_sequences(item) for item in value]
    return value

def stage_dir(case_dir: str, stage: str) -> str:
    """返回指定阶段目录并确保存在。"""
    d = os.path.join(case_dir, stage)
    os.makedirs(d, exist_ok=True)
    return d


def agent_workspace_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "workspace")


def agent_meta_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "generate")


def interaction_metrics_dir(case_dir: str, stage: str, ensure: bool = True) -> str:
    target_dir = agent_meta_dir(case_dir) if stage == "agent" else stage_dir(case_dir, stage)
    d = os.path.join(target_dir, "metrics")
    if ensure:
        os.makedirs(d, exist_ok=True)
    return d


def original_project_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "original")


def diff_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "diff")


def opencode_runtime_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "opencode")


def checks_dir(case_dir: str) -> str:
    return stage_dir(case_dir, "checks")


# ── Runner 阶段 ──────────────────────────────────────────────

def save_runner_artifacts(case_dir: str,
                          output: str,
                          task_prompt: str = ""):
    """保存单 agent 执行产物。"""
    sd = agent_meta_dir(case_dir)
    with open(os.path.join(sd, "output.txt"), "w", encoding="utf-8") as f:
        f.write(output)
    if task_prompt:
        with open(os.path.join(sd, "input.txt"), "w", encoding="utf-8") as f:
            f.write(task_prompt)


def _write_json(path: str, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def _load_json_if_exists(path: str):
    if not path or not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def _legacy_interaction_metrics_path(case_dir: str, stage: str) -> str:
    target_dir = agent_meta_dir(case_dir) if stage == "agent" else stage_dir(case_dir, stage)
    if stage:
        return os.path.join(target_dir, f"{stage}_interaction_metrics.json")
    return os.path.join(target_dir, "interaction_metrics.json")


def _safe_metric_file_stem(value: str, fallback: str) -> str:
    text = str(value or "").strip().lower()
    text = re.sub(r"[^a-z0-9._-]+", "_", text)
    text = text.strip("._-")
    return text or fallback


def save_interaction_metrics(case_dir: str, stage: str, metrics: dict):
    """保存拆分后的交互指标文件。"""
    if not metrics:
        return
    target_dir = interaction_metrics_dir(case_dir, stage, ensure=False)
    http = metrics.get("http") if isinstance(metrics.get("http"), dict) else {}
    _write_json(os.path.join(target_dir, "message_history.json"), http.get("message_history") or [])
    _write_json(os.path.join(target_dir, "derived.json"), metrics.get("derived") or {})
    subagent_histories = http.get("subagent_message_history")
    if isinstance(subagent_histories, list):
        used_names = set()
        for index, item in enumerate(subagent_histories, start=1):
            if not isinstance(item, dict):
                continue
            subagent_name = item.get("subagent_type") or item.get("title") or item.get("session_id")
            stem = _safe_metric_file_stem(subagent_name, f"subagent_{index}")
            file_stem = f"sub_{stem}"
            if file_stem in used_names:
                file_stem = f"{file_stem}_{index}"
            used_names.add(file_stem)
            _write_json(os.path.join(target_dir, f"{file_stem}.json"), item)


def load_interaction_metrics(case_dir: str, stage: str) -> dict:
    """读取拆分交互指标；不存在时兼容读取旧版单体文件。"""
    target_dir = interaction_metrics_dir(case_dir, stage)
    message_history = _load_json_if_exists(os.path.join(target_dir, "message_history.json"))
    derived = _load_json_if_exists(os.path.join(target_dir, "derived.json"))
    subagent_message_history = []
    if os.path.isdir(target_dir):
        for filename in sorted(os.listdir(target_dir)):
            if not filename.startswith("sub_") or not filename.endswith(".json"):
                continue
            item = _load_json_if_exists(os.path.join(target_dir, filename))
            if isinstance(item, dict):
                subagent_message_history.append(item)
    if any(item is not None for item in (message_history, derived)):
        return {
            "version": 2,
            "http": {
                "message_history": message_history if isinstance(message_history, list) else [],
                "subagent_message_history": subagent_message_history,
            },
            "derived": derived if isinstance(derived, dict) else {},
        }

    legacy = _load_json_if_exists(_legacy_interaction_metrics_path(case_dir, stage))
    if isinstance(legacy, dict) and legacy:
        return legacy
    if stage == "agent":
        legacy = _load_json_if_exists(os.path.join(agent_meta_dir(case_dir), "interaction_metrics.json"))
        if isinstance(legacy, dict):
            return legacy
    return {}


def save_compile_artifacts(case_dir: str, stage: str, compile_result: dict):
    """保存编译阶段产物。"""
    target_dir = os.path.join(checks_dir(case_dir), stage)
    os.makedirs(target_dir, exist_ok=True)
    sanitized_result = _strip_ansi_sequences(compile_result or {})
    json_result = dict(sanitized_result)
    if json_result.get("error"):
        # 完整编译日志只保留一份 compile.log.txt，避免 JSON 再复制一份大文本。
        json_result.pop("error", None)
        json_result["errorLogFile"] = "compile.log.txt"
    with open(os.path.join(target_dir, "compile_result.json"), "w", encoding="utf-8") as f:
        json.dump(json_result, f, ensure_ascii=False, indent=2)
    with open(os.path.join(target_dir, "compile.log.txt"), "w", encoding="utf-8") as f:
        f.write(sanitized_result.get("error", "") or ("编译成功" if sanitized_result.get("compilable") else ""))


def load_runner_artifacts(case_dir: str) -> tuple:
    """加载单 agent Runner 产物。"""
    meta_dir = agent_meta_dir(case_dir)
    display_path = os.path.join(meta_dir, "output.txt")
    raw_path = os.path.join(meta_dir, "raw_output.txt")
    if not os.path.exists(raw_path) and not os.path.exists(display_path):
        raise FileNotFoundError(f"Runner 产物不存在: {case_dir}，请先运行 runner 阶段")
    with open(raw_path if os.path.exists(raw_path) else display_path, "r", encoding="utf-8") as f:
        output = f.read()
    return output


def save_case_result(case_dir: str, result: dict):
    """单独保存 case 汇总结果。"""
    os.makedirs(case_dir, exist_ok=True)
    with open(os.path.join(case_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
