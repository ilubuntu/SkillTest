# -*- coding: utf-8 -*-
"""Agent 运行时编排。"""

import time

from agent_bench.agent_runtime.spec import AgentSpec
from agent_bench.agent_runtime.skills import log_agent_configuration, verify_runtime_skills
from agent_bench.pipeline.loader import build_agent_runtime_enhancements, merge_enhancements
from agent_bench.runner.factory import create_adapter


class AgentRuntime:
    def __init__(self,
                 agent_spec: AgentSpec,
                 enhancements: dict | None = None,
                 on_progress=None,
                 fallback_timeout: int = 180,
                 temperature=None):
        self.agent_spec = agent_spec
        self.on_progress = on_progress
        self.fallback_timeout = fallback_timeout
        self.temperature = temperature
        self.runtime_enhancements = merge_enhancements(
            build_agent_runtime_enhancements(agent_spec.raw),
            enhancements or {},
        )
        self.adapter = None

    def _notify(self, level: str, message: str):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": message})

    def _resolve_timeout(self) -> int:
        timeout = int(self.agent_spec.timeout or 0)
        return timeout if timeout > 0 else self.fallback_timeout

    def prepare(self):
        self._notify("WARNING", f"开始准备 {self.agent_spec.display_name} 运行配置...")
        log_agent_configuration(self.agent_spec, self.on_progress)
        verify_runtime_skills(self.agent_spec, self.on_progress)
        if self.agent_spec.adapter.lower() == "opencode":
            self._notify("INFO", "已采用 CLI 对齐消息组织：skill 要求仅保留在用户消息中，工程目录通过 HTTP directory 传递")
        self.adapter = create_adapter(
            self.agent_spec.raw,
            timeout=self._resolve_timeout(),
            on_progress=self.on_progress,
            temperature=self.temperature,
        )
        self.adapter.setup(self.runtime_enhancements, on_progress=self.on_progress)
        self._notify("WARNING", f"{self.agent_spec.display_name} 准备完成，开始处理任务...")

    def execute(self, task_prompt: str, workspace_dir: str, tag: str = "") -> tuple[str, float]:
        if self.adapter is None:
            raise RuntimeError("AgentRuntime 尚未 prepare")
        start = time.time()
        output_text = self.adapter.execute(task_prompt, tag=tag, workspace_dir=workspace_dir)
        return output_text, time.time() - start

    def get_last_error_message(self) -> str:
        if self.adapter is None:
            return ""
        getter = getattr(self.adapter, "get_last_error_message", None)
        if callable(getter):
            return str(getter() or "").strip()
        return ""

    def get_last_interaction_metrics(self):
        if self.adapter is None:
            return None
        return self.adapter.get_last_interaction_metrics()

    def teardown(self):
        if self.adapter is not None:
            self.adapter.teardown()
            self.adapter = None
