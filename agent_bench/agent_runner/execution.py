# -*- coding: utf-8 -*-
"""单次 agent 执行编排。"""

import time

from agent_bench.agent_runner.factory import create_adapter
from agent_bench.agent_runner.runtime_options import build_agent_runtime_options, merge_runtime_options
from agent_bench.agent_runner.skills import log_agent_configuration, verify_runtime_skills
from agent_bench.agent_runner.spec import AgentSpec


class AgentRunner:
    def __init__(self,
                 agent_spec: AgentSpec,
                 runtime_options: dict | None = None,
                 on_progress=None,
                 fallback_timeout: int = 180,
                 artifact_prefix: str = "agent",
                 artifact_base_dir: str = "generate"):
        self.agent_spec = agent_spec
        self.on_progress = on_progress
        self.fallback_timeout = fallback_timeout
        self.artifact_prefix = artifact_prefix or "agent"
        self.artifact_base_dir = artifact_base_dir or "generate"
        self.runtime_options = merge_runtime_options(
            build_agent_runtime_options(agent_spec.raw),
            runtime_options or {},
        )
        self.adapter = None

    def _notify(self, level: str, message: str):
        if self.on_progress:
            self.on_progress("log", {"level": level, "message": message})

    def _resolve_timeout(self) -> int:
        timeout = int(self.agent_spec.timeout or 0)
        return timeout if timeout > 0 else self.fallback_timeout

    def prepare(self, workspace_dir: str):
        self._notify("WARNING", f"开始准备 {self.agent_spec.display_name} 运行配置...")
        log_agent_configuration(self.agent_spec, self.on_progress)
        skill_result = verify_runtime_skills(self.agent_spec, workspace_dir, self.on_progress)
        if not skill_result.get("ok"):
            raise RuntimeError(f"{self.agent_spec.display_name} 运行前 skill 校验失败")
        if skill_result.get("mounted"):
            self._notify("INFO", "本轮已完成 skill 挂载与复检，后续将基于挂载后的状态创建 OpenCode 会话并发起 HTTP 请求")
        if skill_result.get("config_path"):
            self._notify("INFO", f"当前任务 OpenCode 配置文件: {skill_result.get('config_path')}")
        if skill_result.get("skill_root"):
            self._notify("INFO", f"当前任务 OpenCode skill 目录: {skill_result.get('skill_root')}")
        self._notify("INFO", "已采用 CLI 对齐消息组织：skill 要求仅保留在用户消息中，工程目录通过 HTTP directory 传递")
        self.adapter = create_adapter(
            self.agent_spec.raw,
            timeout=self._resolve_timeout(),
            on_progress=self.on_progress,
            artifact_prefix=self.artifact_prefix,
            artifact_base_dir=self.artifact_base_dir,
        )
        self.adapter.setup(self.runtime_options, on_progress=self.on_progress)
        self._notify("WARNING", f"{self.agent_spec.display_name} 准备完成，开始处理任务...")

    def execute(self, task_prompt: str, workspace_dir: str, tag: str = "") -> tuple[str, float]:
        if self.adapter is None:
            raise RuntimeError("AgentRunner 尚未 prepare")
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
