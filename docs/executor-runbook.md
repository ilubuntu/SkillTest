# 执行器运行手册

## 组件

本地运行只涉及两个组件：

- OpenCode Server
- Executor 服务

## 启动

```bash
./deploy.sh restart
```

启动后默认地址：

- OpenCode: `http://localhost:4096`
- Executor: `http://localhost:8000`

## 健康检查

```bash
curl -s http://localhost:4096/global/health
curl -s http://localhost:8000/api/health
```

## 任务入口

```text
POST /api/cloud-api/baseline
POST /api/cloud-api/harmonyos-plugin
```

## 本地日志

执行器日志：

- `logs/agent_bench_YYYYMMDD_HHMMSS.log`

当前日志指针：

- `logs/current_executor_log`

每个任务目录下还会有：

- `executor_events.jsonl`
- `cloud_api_events.jsonl`
- `generate/*`
- `diff/*`
- `checks/*`

## 进度阶段

固定阶段：

- `pending`
- `preparing`
- `generating`
- `validating`
- `completed`

## 产物目录

每次任务目录结构：

```text
results/execution_<id>_<timestamp>/
├── original/
├── workspace/
├── generate/
├── diff/
├── checks/
├── executor_events.jsonl
└── cloud_api_events.jsonl
```

## SSE 文件

主代码生成 Agent 阶段有三类文件：

- `*_opencode_sse_full.jsonl`
- `*_opencode_sse_events.jsonl`
- `*_opencode_progress_events.jsonl`

用途：

- `full`：当前 session 的完整原始 SSE
- `events`：裁剪后的原始事件
- `progress`：本地展示与进度提炼
