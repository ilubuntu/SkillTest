# FastAPI 接口说明

本文档说明本地执行器当前对外提供的 FastAPI 接口。

默认服务地址：

```text
http://127.0.0.1:8000
```

## 1. 服务信息

### `GET /`

查看执行器服务基础信息和主要入口。

请求示例：

```bash
curl http://127.0.0.1:8000/
```

响应示例：

```json
{
  "service": "cloud_executor",
  "version": "0.0.7",
  "health": "/api/health",
  "status": "/api/cloud-api/status"
}
```

## 2. 健康检查

### `GET /api/health`

检查执行器进程是否启动成功。

请求示例：

```bash
curl http://127.0.0.1:8000/api/health
```

响应示例：

```json
{
  "ok": true,
  "service": "cloud_executor",
  "version": "0.0.7"
}
```

## 3. 下发任务

### `POST /api/cloud-api/agent/{agent_id}`

按 `agent_id` 下发云测任务。`agent_id` 必须能在 `config/agents.yaml` 中找到。

请求路径示例：

```text
POST /api/cloud-api/agent/baseline
POST /api/cloud-api/agent/harmonyos-plugin
POST /api/cloud-api/agent/baseline-glm5.1
POST /api/cloud-api/agent/harmonyos-plugin-glm5.1
```

请求头：

```text
Content-Type: application/json
Authorization: Bearer <token>
```

`Authorization` 可选。存在时会透传给后续云测上报请求。

请求体字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `executionId` | number | 是 | 云测任务 ID |
| `testCase.input` | string | 是 | 任务输入。为空会直接拒绝执行 |
| `testCase.expectedOutput` | string | 否 | 期望结果，允许为空 |
| `testCase.fileUrl` | string | 否 | 工程包地址，允许为空。为空时按空 workspace 执行 |
| `cloudBaseUrl` | string | 否 | 覆盖默认云测平台地址 |

请求示例：

```bash
curl -X POST http://127.0.0.1:8000/api/cloud-api/agent/harmonyos-plugin \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer test-token' \
  -d '{
    "executionId": 1001,
    "testCase": {
      "input": "这是一个商品管理工程，首页添加商品后列表不刷新，请修复。",
      "expectedOutput": "",
      "fileUrl": "https://example.com/original_project.zip"
    }
  }'
```

成功响应示例：

```json
{
  "accepted": true,
  "executionId": 1001,
  "message": "任务已接收",
  "agentId": "harmonyos-plugin"
}
```

排队响应示例：

```json
{
  "accepted": true,
  "executionId": 1002,
  "message": "任务已接收，当前排队序号=1",
  "agentId": "harmonyos-plugin"
}
```

失败响应示例，`agent_id` 不存在：

```json
{
  "detail": "未找到 agent 配置: unknown-agent"
}
```

失败响应示例，`input` 为空：

```json
{
  "detail": "缺少真实的任务输入，已终止执行"
}
```

### `POST /api/cloud-api/agent/id={agent_id}`

兼容路径，功能和 `/api/cloud-api/agent/{agent_id}` 相同。

请求示例：

```bash
curl -X POST http://127.0.0.1:8000/api/cloud-api/agent/id=harmonyos-plugin \
  -H 'Content-Type: application/json' \
  -d '{
    "executionId": 1003,
    "testCase": {
      "input": "修复首页列表不刷新问题",
      "expectedOutput": "",
      "fileUrl": ""
    }
  }'
```

响应示例：

```json
{
  "accepted": true,
  "executionId": 1003,
  "message": "任务已接收",
  "agentId": "harmonyos-plugin"
}
```

## 4. 查询任务状态

### `GET /api/cloud-api/status`

查询当前执行器内存中的全部任务状态。

请求示例：

```bash
curl http://127.0.0.1:8000/api/cloud-api/status
```

响应示例：

```json
{
  "items": [
    {
      "execution_id": 1001,
      "local_status": "running",
      "local_stage": "generating",
      "agent_id": "harmonyos-plugin",
      "created_at": "2026-05-06T17:18:24",
      "updated_at": "2026-05-06T17:20:09",
      "handle": {
        "has_worker_thread": true,
        "worker_alive": true,
        "has_status_thread": true,
        "status_alive": true,
        "queued": false,
        "queued_at": null,
        "started_at": "2026-05-06T17:18:24",
        "finished_at": null,
        "local_base_url": "http://127.0.0.1:8000"
      }
    }
  ]
}
```

常用判断：

| 含义 | 判断方式 |
| --- | --- |
| 正在执行 | `handle.worker_alive == true` |
| 正在排队 | `handle.queued == true` |
| 已完成 | `local_status == "completed"` |
| 执行失败 | `local_status == "failed"` |

### `GET /api/cloud-api/status?execution_id={execution_id}`

查询单个任务状态。

请求示例：

```bash
curl 'http://127.0.0.1:8000/api/cloud-api/status?execution_id=1001'
```

任务存在时响应示例：

```json
{
  "execution_id": 1001,
  "local_status": "completed",
  "local_stage": "completed",
  "agent_id": "harmonyos-plugin",
  "result": {
    "status": "completed",
    "isBuildSuccess": true,
    "executionTime": 274,
    "tokenConsumption": 182984,
    "iterationCount": 1,
    "outputCodeUrl": "https://example.com/output.zip",
    "diffFileUrl": "https://example.com/changes.patch"
  },
  "handle": {
    "has_worker_thread": false,
    "worker_alive": false,
    "has_status_thread": false,
    "status_alive": false,
    "queued": false,
    "queued_at": null,
    "started_at": "2026-05-06T17:18:24",
    "finished_at": "2026-05-06T17:23:23",
    "local_base_url": "http://127.0.0.1:8000"
  }
}
```

任务不存在时响应示例：

```json
{
  "status": "idle",
  "executionId": 999999
}
```

## 5. 查询执行器摘要

### `GET /api/cloud-api/summary`

查询当前执行器任务负载摘要。

请求示例：

```bash
curl http://127.0.0.1:8000/api/cloud-api/summary
```

响应字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `totalReceived` | number | 当前进程启动后已接收并登记的任务总数 |
| `runningCount` | number | 当前正在执行的任务数 |
| `queuedCount` | number | 当前排队等待执行的任务数 |
| `maxConcurrency` | number | 当前配置的最大并发数 |

响应示例：

```json
{
  "totalReceived": 12,
  "runningCount": 2,
  "queuedCount": 1,
  "maxConcurrency": 5
}
```

说明：

- `totalReceived` 是当前执行器进程内存统计，不是数据库累计值。
- 执行器重启后，内存中的任务状态和计数会重新开始。
- `maxConcurrency` 来自 `config/config.yaml` 的 `task_manager.max_concurrency`。

## 6. 拉取 Agent/LLM 交互流程

### `GET /api/cloud-api/agent-interaction?executionId={execution_id}`

云测主动拉取指定任务的 Agent/LLM 交互流程快照。该接口不做鉴权。

兼容路径：

```http
GET /api/cloud-api/agent-interaction/{execution_id}
```

请求示例：

```bash
curl 'http://127.0.0.1:8000/api/cloud-api/agent-interaction?executionId=1001'
```

```bash
curl http://127.0.0.1:8000/api/cloud-api/agent-interaction/1001
```

响应示例：

```json
{
  "executionId": 1001,
  "agent": "harmonyos-plugin",
  "model": "zhipuai-coding-plan/glm-5.1",
  "status": "completed",
  "workingDirectory": "results/execution_1001_20260508_211322/workspace",
  "steps": [],
  "subAgents": [],
  "toolSummary": {},
  "summary": {
    "stepCount": 0,
    "toolCallCount": 0
  }
}
```

说明：

- 接口优先读取 `agent_traces/execution_<execution_id>_interaction.json`。
- `results` 目录可以清理，`agent_traces` 是长期保存目录，不跟随 `results` 清理。
- 数据未准备好或 executionId 不存在时仍返回 HTTP 200，`status` 为 `not_ready`。
- 详细字段见 [Agent/LLM 交互流程拉取接口](./cloud-api/agent-interaction-report.md)。

未准备好响应示例：

```json
{
  "executionId": 1001,
  "status": "not_ready",
  "message": "executionId=1001 的 Agent/LLM 交互流程数据尚未准备好，或该任务 ID 不存在"
}
```
