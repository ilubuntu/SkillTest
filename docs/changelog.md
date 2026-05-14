# Changelog

## 0.0.8

- 时间: `2026-05-07 19:26:32`
- 主要变更:
  - OpenCode `session.status=retry` 日志增强：
    - 当 Agent 被服务端限流或要求重试时，明确打印服务端 `message`
    - 解析并打印 `next` 重试时间
    - 同步打印 `attempt` 次数
    - 日志同时写入本地执行日志和云测进度，避免长时间轮询时误判为卡死
  - HarmonyOS 编译验证适配 HAR/HSP：
    - 编译命令不再固定只执行 `assembleHap`
    - 根据工程模块类型动态追加 `assembleHap`、`assembleHar`、`assembleHsp`
    - `harmonyos-build` skill 同步补充 HAR/HSP 构建说明
  - 编译迭代次数统计优化：
    - `iterationCount` 同时统计 `assembleHap` 和 `assembleHar`
    - 避免 HAR 工程编译次数漏计
  - OpenCode 运行时文件保留方式调整：
    - Agent 运行后不再直接删除 workspace 内 `.opencode/` 和 `opencode.json`
    - 改为移动到 execution 目录外层 `opencode/` 归档，便于后续定位问题
    - diff 和上传仍不包含这些运行时文件
  - 任务执行稳定性调整：
    - 单任务总运行时间增加 6000 秒兜底
    - 最大并发数调整为 `5`
    - 长时间无新消息时继续保留 todo 未完成任务的等待逻辑，不因 todo 未完成本身强制收口

## 0.0.7

- 时间: `2026-04-27 16:26:00`
- 主要变更:
  - 执行器版本升级到 `0.0.7`
  - 原始工程准备阶段新增 `build-profile.json5` 签名清理：
    - 若根目录存在 `app.signingConfigs` 且非空，自动清空为 `[]`
    - 若原始签名信息已为空，记录“无需清理”日志
  - 编译报错摘要逻辑优化：
    - 不再从日志前部截取
    - 优先从首个 `hvigor ERROR` 开始向后提取
    - 未命中 `hvigor ERROR` 时，回退为从日志尾部按整行截取
    - 上传云测前会清理 ANSI 颜色控制符
  - 修复 OpenCode `question` 无人值守卡死问题：
    - 支持基于 `question.asked` 的自动应答
    - 自动选择第一个选项
    - reply 改为带 `directory/workspace` 上下文
    - 新增 HTTP 轮询兜底：
      - 先从 session message 发现 `question (running)`
      - 再请求 `/question?directory=<workspace>` 获取 `requestID`
      - 命中后自动调用 `/question/{requestID}/reply`
  - OpenCode 升级到新版本后，执行器同步适配：
    - 保持隔离 `XDG` 配置复制
    - 移除旧版兼容探测与冗余预检逻辑
  - 空工程场景优化：
    - `fileUrl` 可为空
    - 空工程跳过前置编译检查，并同步上报“跳过预编译”日志
  - workspace 运行时文件隔离与 diff 优化：
    - 运行时忽略规则收敛到 `.git/info/exclude`
    - `.opencode/`、`opencode.json`、`BuildProfile.ets` 不进入 diff 与上传
    - 空 workspace 允许 `git commit --allow-empty` 建立基线

## 0.0.6

- 主要变更:
  - 移除约束规则打分 agent 和静态代码打分 agent
  - 删除对应评分 skill 资料目录
  - 主流程只保留代码生成、编译验证、产物上传和结果上报
  - `expectedOutput` 不再参与约束解析或打分，可为空

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
