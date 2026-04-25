# Changelog

## 0.0.5

- 时间: `2026-04-24 12:08:02`
- 主要变更:
  - 执行器版本升级到 `0.0.5`
  - 无额外功能变更，本次仅同步版本号与文档

## 0.0.4

- 时间: `2026-04-24 11:51:58`
- 主要变更:
  - 执行器版本升级到 `0.0.4`
  - 任务启动前会从 `XDG` 目录预热复制 `.opencode` 运行时文件到任务级 `workspace/.opencode`
  - OpenCode 慢启动问题明显缓解，任务可更快进入 `session/SSE/message` 阶段
  - HTTP 轮询日志增强：支持主 session、child session、todo 变化追踪
  - 本地日志文案优化：`reasoning` 会带摘要，delta 日志改为 `当前模型还在输出Delta：...`

## 0.0.3

- 时间: `2026-04-23 20:11:35`
- 主要变更:
  - 执行器版本升级到 `0.0.3`
  - OpenCode 自动启动前会按配置复制全局 `opencode.json` 到隔离 XDG 目录
  - 新增 `opencode.opencode_config_path` 三平台配置，缺失配置时启动失败
  - `.opencode_runtime/` 加入 Git 忽略

## 0.0.2

- 时间: `2026-04-23 16:59:02`
- 主要变更:
  - 执行器版本升级到 `0.0.2`
  - 云测接口新增动态 agent 路由：`/api/cloud-api/agent/{agent_id}`，兼容 `/api/cloud-api/agent/id={agent_id}`
  - 补齐并修正 4 个可用 agent 配置：`baseline`、`baseline-minimax`、`harmonyos-plugin`、`harmonyos-plugin-minimax`
  - 默认超时从 `300s` 提升到 `600s`
  - 本地使用指南同步更新 agent 访问方式与当前默认配置

## 0.0.1

- 时间: `2026-04-22 11:58:32`
- 主要变更:
  - 首版本
