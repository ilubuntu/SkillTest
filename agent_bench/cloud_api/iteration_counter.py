# -*- coding: utf-8 -*-
"""iterationCount 换算逻辑。"""

from typing import Any, Dict


class IterationCounter:
    """从交互指标中提取 iterationCount。"""

    def extract_build_execution_count(self, metrics: Dict[str, Any]) -> int:
        """统计真实编译执行次数（去重）。

        只统计 bash 命令中真正触发 HarmonyOS 编译的 assembleHap/assembleHar 调用次数。
        不再使用额外的输出标记，避免统计口径与真实命令执行不一致。
        """
        if not isinstance(metrics, dict):
            return 0

        raw = metrics.get("http") if isinstance(metrics.get("http"), dict) else {}
        parts = []
        if isinstance(raw, dict):
            message_history = raw.get("message_history") if isinstance(raw.get("message_history"), list) else []
            for message in message_history:
                if not isinstance(message, dict):
                    continue
                message_parts = message.get("parts")
                if isinstance(message_parts, list):
                    parts.extend(item for item in message_parts if isinstance(item, dict))

        build_call_ids = set()
        build_call_count = 0

        for part in parts:
            if not isinstance(part, dict):
                continue
            part_type = str(part.get("type") or "").strip().lower()
            if part_type != "tool":
                continue

            state = part.get("state") if isinstance(part.get("state"), dict) else {}
            status = str(state.get("status") or "").strip().lower()
            if status not in {"completed", "running"}:
                continue

            command_input = state.get("input") if isinstance(state.get("input"), dict) else {}
            tool_name = str(part.get("tool") or "").strip().lower()

            if tool_name == "bash":
                command_str = str(command_input.get("command") or "").strip().lower()
                if "assemblehap" in command_str or "assemblehar" in command_str:
                    call_id = str(part.get("callID") or "").strip() or str(part.get("id") or "").strip()
                    if call_id and call_id not in build_call_ids:
                        build_call_ids.add(call_id)
                        build_call_count += 1

        return build_call_count

    def extract_iteration_count(self, metrics: Dict[str, Any], output_text: str = "", total_tokens: int = 0) -> int:
        """提取迭代次数。

        当前只认真实编译执行次数；如果没有编译痕迹，则退化为 1/0。
        不再使用 step-start 数或 observed_calls 数，避免把模型内部步骤误报成迭代次数。
        """
        if not isinstance(metrics, dict):
            return 1 if (output_text or "").strip() else 0

        build_execution_count = self.extract_build_execution_count(metrics)
        if build_execution_count > 0:
            return build_execution_count

        http = metrics.get("http") if isinstance(metrics.get("http"), dict) else {}
        if (http.get("session_id") or "").strip():
            return 1
        if total_tokens > 0:
            return 1
        return 1 if (output_text or "").strip() else 0
