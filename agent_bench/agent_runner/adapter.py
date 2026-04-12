# -*- coding: utf-8 -*-
"""Agent 适配器抽象接口。

定义与 Agent 交互的统一协议。当前主链主要通过 setup 注入：
- skills
- mcp_servers
- system_prompt
- tools
"""

from abc import ABC, abstractmethod
from typing import Optional


class AgentAdapter(ABC):
    """Agent 适配器基类

    生命周期：
        adapter = SomeAdapter(api_base, model, ...)
        adapter.setup(runtime_options)   # 配置运行时能力
        result = adapter.execute(prompt)  # 执行任务
        adapter.teardown()            # 清理资源

    每个用例执行前后都应调用 setup/teardown，确保运行时配置隔离。
    """

    @abstractmethod
    def setup(self, runtime_options: dict, on_progress=None):
        """配置 Agent 运行时能力。

        Args:
            runtime_options: 运行时配置字典，结构如下：
                {
                    "skills": [
                        {"name": "bug_fix", "content": "...skill文件内容..."}
                    ],
                    "mcp_servers": [
                        {"name": "arkts-tools", "command": "npx", "args": [...]}
                    ],
                    "system_prompt": "你是一个专注于...",
                    "tools": {
                        "write": false,
                        "bash": true
                    }
                }
                所有字段均为可选，空 dict 表示使用 Agent 自身默认配置。
            on_progress: 进度回调 (event, data) -> None
        """
        pass

    @abstractmethod
    def execute(self, prompt: str, tag: str = "", workspace_dir: Optional[str] = None) -> str:
        """执行一次任务

        发送用户 prompt 给 Agent，返回 Agent 的响应文本。
        运行时能力已在 setup 阶段配置，execute 只需发送任务内容。

        Args:
            prompt: 用户任务提示词（含代码等上下文）
            tag: 日志前缀标识
            workspace_dir: 供 Agent 直接修改的工程目录

        Returns:
            Agent 响应的文本内容，失败返回空字符串
        """
        pass

    @abstractmethod
    def teardown(self):
        """清理资源

        在用例执行完成后调用，移除本次配置的运行时能力，
        确保不影响下一个用例的执行环境。
        """
        pass

    def get_last_interaction_metrics(self):
        """返回最近一次 execute 的交互指标。"""
        return None
