# -*- coding: utf-8 -*-
"""Agent 适配器抽象接口

定义与 Agent 交互的统一协议，所有 Agent 对接（OpenCode、Claude Code 等）
都通过实现此接口完成，使评测系统与具体 Agent 实现解耦。

增强工具类型：
- skills: Prompt 级最佳实践文档
- mcp_servers: MCP Server 工具（代码分析、编译检查等）
- system_prompt: Agent 系统提示词
- tools: Agent 内置工具开关配置
"""

from abc import ABC, abstractmethod
from typing import Optional


class AgentAdapter(ABC):
    """Agent 适配器基类

    生命周期：
        adapter = SomeAdapter(api_base, model, ...)
        adapter.setup(enhancements)   # 配置增强工具
        result = adapter.execute(prompt)  # 执行任务
        adapter.teardown()            # 清理资源

    每个用例执行前后都应调用 setup/teardown，确保增强配置隔离。
    """

    @abstractmethod
    def setup(self, enhancements: dict, on_progress=None):
        """配置 Agent 增强工具

        在执行用例前调用，将 Profile 中定义的增强配置应用到 Agent。

        Args:
            enhancements: 增强配置字典，结构如下：
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
                所有字段均为可选，空 dict 表示无增强（基线模式）。
            on_progress: 进度回调 (event, data) -> None
        """
        pass

    @abstractmethod
    def execute(self, prompt: str, tag: str = "") -> str:
        """执行一次任务

        发送用户 prompt 给 Agent，返回 Agent 的响应文本。
        增强工具已在 setup 阶段配置，execute 只需发送任务内容。

        Args:
            prompt: 用户任务提示词（含代码等上下文）
            tag: 日志前缀标识

        Returns:
            Agent 响应的文本内容，失败返回空字符串
        """
        pass

    @abstractmethod
    def teardown(self):
        """清理资源

        在用例执行完成后调用，移除本次配置的增强工具，
        确保不影响下一个用例的执行环境。
        """
        pass
