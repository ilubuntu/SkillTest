# Changelog

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
