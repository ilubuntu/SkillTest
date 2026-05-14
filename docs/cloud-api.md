# 云测接口交互说明

本文档说明执行器和云测平台之间的接口交互。

交互方向分两类：

- 云测平台调用执行器：下发任务。
- 执行器调用云测平台：上报进度、上报最终结果。

执行器本身提供的 FastAPI 接口见 [fast-api.md](./fast-api.md)。

## 1. 云测下发任务

### `POST /api/cloud-api/executions`

新协议任务下发入口。Agent、模型、Plugin、Skill 全部由云测在请求体中下发。

请求体：

```json
{
  "executionId": 1492,
  "testCase": {
    "input": "修复首页商品列表添加后不刷新问题",
    "expectedOutput": "无",
    "fileUrl": "https://example.com/original_project.zip"
  },
  "codeAgent": {
    "id": 16,
    "name": "GLM-5.1_plugin_HW",
    "model": {
      "name": "GLM-5.1",
      "code": "huawei/glm-5.1"
    },
    "skills": [
      {
        "id": 2,
        "name": "harmonyos-hvigor",
        "version": "v1.0.0",
        "fileUrl": "https://example.com/skills/harmonyos-hvigor.zip"
      }
    ],
    "plugins": [
      {
        "id": 1,
        "name": "harmonyos-plugin",
        "version": "v1.26.05.07"
      }
    ]
  }
}
```

关键字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeAgent.model.code` | string | 是 | OpenCode 模型编码，例如 `huawei/glm-5.1` |
| `codeAgent.plugins[0].name` | string | 是 | OpenCode Agent 名称，支持 `build`、`harmonyos-plugin` |
| `codeAgent.skills[].fileUrl` | string | 是 | Skill zip 下载地址 |

成功响应：

```json
{
  "accepted": true,
  "executionId": 1492,
  "message": "任务已接收",
  "agentId": "16"
}
```

### `POST /api/cloud-api/agent/{agent_id}`

老协议兼容入口。云测平台调用本地执行器，按指定 `agent_id` 下发任务。

示例地址：

```text
http://127.0.0.1:8000/api/cloud-api/agent/baseline
http://127.0.0.1:8000/api/cloud-api/agent/harmonyos-plugin
http://127.0.0.1:8000/api/cloud-api/agent/baseline-glm5.1
http://127.0.0.1:8000/api/cloud-api/agent/harmonyos-plugin-glm5.1
```

兼容地址：

```text
http://127.0.0.1:8000/api/cloud-api/agent/id=harmonyos-plugin
```

请求头：

```text
Content-Type: application/json
Authorization: Bearer <token>
```

`Authorization` 可选。存在时执行器会保存 token，并在后续进度上报、结果上报时透传给云测平台。

请求体：

```json
{
  "executionId": 10,
  "cloudBaseUrl": "http://47.100.28.161:3000",
  "testCase": {
    "input": "修复首页商品列表添加后不刷新问题",
    "expectedOutput": "",
    "fileUrl": "https://example.com/original_project.zip"
  }
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `executionId` | number | 是 | 云测任务 ID |
| `cloudBaseUrl` | string | 否 | 覆盖本地 `config/config.yaml` 中的 `task_manager.cloud_base_url` |
| `testCase.input` | string | 是 | 真实任务输入。为空时执行器直接拒绝任务 |
| `testCase.expectedOutput` | string | 否 | 期望结果。当前主流程不打分，允许为空 |
| `testCase.fileUrl` | string | 否 | 原始工程压缩包地址。允许为空 |

`fileUrl` 为空时：

- 不下载原始工程。
- `workspace` 初始内容为空。
- 环境准备阶段跳过原始工程预编译。
- 流程不会因为缺少工程包而中断。

成功响应：

```json
{
  "accepted": true,
  "executionId": 10,
  "message": "任务已接收",
  "agentId": "harmonyos-plugin"
}
```

排队响应：

```json
{
  "accepted": true,
  "executionId": 11,
  "message": "任务已接收，当前排队序号=1",
  "agentId": "harmonyos-plugin"
}
```

失败响应，`input` 为空：

```json
{
  "detail": "缺少真实的任务输入，已终止执行"
}
```

失败响应，`agent_id` 不存在：

```json
{
  "detail": "未找到 agent 配置: unknown-agent"
}
```

## 2. 执行器上报进度

### `POST {cloudBaseUrl}/api/test-executions/{executionId}/report`

执行器周期性向云测平台上报任务状态和展示日志。

请求地址示例：

```text
POST http://47.100.28.161:3000/api/test-executions/10/report
```

请求头：

```text
Content-Type: application/json
Authorization: Bearer <token>
```

`Authorization` 来自任务下发时的请求头，若下发时未提供则不上报该请求头。

请求体：

```json
{
  "status": "running",
  "errorMessage": "",
  "conversation": [
    {
      "time": "20260506-17:18:37",
      "type": "status",
      "message": "任务已发送"
    }
  ],
  "executionLog": "[{\"stage\":\"generating\",\"message\":\"Agent处理\",\"detail\":[{\"time\":\"20260506-17:18:37\",\"message\":\"任务已发送\"}]}]"
}
```

字段说明：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `status` | string | 云测任务状态 |
| `errorMessage` | string | 失败原因。无错误时为空字符串或不传 |
| `conversation` | array | 本地事件时间线，主要用于排障 |
| `executionLog` | string | 云测展示日志，内容是 JSON 字符串 |

`status` 可选值：

```text
pending
running
completed
failed
```

本地状态映射：

| 本地状态 | 云测状态 |
| --- | --- |
| `pending` | `pending` |
| `running` | `running` |
| `completed` | `completed` |
| `failed` | `failed` |

`executionLog` 内部结构示例：

```json
[
  {
    "stage": "preparing",
    "message": "环境准备",
    "detail": [
      {
        "time": "20260506-17:18:24",
        "message": "[开始] 预编译验证"
      },
      {
        "time": "20260506-17:18:35",
        "message": "[结束] 预编译验证: 编译通过 (10.6s)"
      }
    ]
  },
  {
    "stage": "generating",
    "message": "Agent处理",
    "detail": [
      {
        "time": "20260506-17:20:08",
        "message": "【sse】 Agent 工具执行完成: question (completed)"
      }
    ]
  }
]
```

当前阶段：

```text
pending
preparing
generating
validating
completed
```

上报策略：

- 执行器会周期性上报状态。
- 状态或阶段变化时会立即进入上报。
- `executionLog` 每次传全量摘要，不是增量日志。
- 原始高频日志不会完整上传给云测，只上传适合展示的摘要。

响应示例：

```json
{
  "id": 487,
  "testExecution": {
    "id": 10,
    "status": "running"
  }
}
```

执行器不会强依赖响应体字段，只记录 HTTP 状态码和响应内容用于审计。

## 3. 执行器上报最终结果

### `POST {cloudBaseUrl}/api/execution-results`

任务完成后，执行器向云测平台上报最终结果。

请求地址示例：

```text
POST http://47.100.28.161:3000/api/execution-results
```

请求头：

```text
Content-Type: application/json
Authorization: Bearer <token>
```

请求体：

```json
{
  "testExecutionId": 10,
  "data": {
    "isBuildSuccess": true,
    "executionTime": 274,
    "tokenConsumption": 182984,
    "iterationCount": 1,
    "codeQualityScore": 0,
    "expectedOutputScore": 0,
    "outputCodeUrl": "https://example.com/output_code/execution_10_output.zip",
    "diffFileUrl": "https://example.com/diff/execution_10_changes.patch"
  }
}
```

字段说明：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `testExecutionId` | number | 云测任务 ID |
| `data.isBuildSuccess` | boolean | Agent 修改后编译验证是否通过 |
| `data.executionTime` | number | Agent 主处理耗时，单位秒 |
| `data.tokenConsumption` | number | 全流程 token 消耗 |
| `data.iterationCount` | number | 编译迭代次数 |
| `data.codeQualityScore` | number | 代码质量分。当前固定为 `0` |
| `data.expectedOutputScore` | number | 期望结果分。当前固定为 `0` |
| `data.outputCodeUrl` | string | `workspace/` 打包上传后的下载地址 |
| `data.diffFileUrl` | string | `diff/changes.patch` 上传后的下载地址 |

说明：

- 约束规则打分和静态代码打分 Agent 已移除，所以两个评分字段固定为 `0`。
- `tokenConsumption` 按全流程消息统计，不只取最后一次模型响应。
- `iterationCount` 当前按实际编译验证次数统计。
- `outputCodeUrl` 上传的是最终 workspace 代码包。
- `diffFileUrl` 上传的是最终评审 diff 文件。

响应示例：

```json
{
  "id": 488,
  "testExecution": {
    "id": 10,
    "status": "completed"
  }
}
```

执行器不会强依赖响应体字段，只记录 HTTP 状态码和响应内容用于审计。

## 4. 执行器上传 Agent/LLM 交互日志

### `POST {cloudBaseUrl}/api/test-executions/{executionId}/agent-log`

执行器在 Agent 执行结束并生成本地交互流程快照后，将 JSON 文件上传到云测平台。

请求地址示例：

```text
POST http://47.100.28.161:3000/api/test-executions/10/agent-log
```

请求头：

```text
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

`Authorization` 来自任务下发时的请求头，若下发时未提供则不上报该请求头。

参数说明：

| 参数 | 位置 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- | --- |
| `executionId` | path | number | 是 | 云测任务 ID |
| `file` | body | file | 是 | Agent/LLM 交互流程 JSON 文件 |

请求示例：

```bash
curl -X POST \
  -F 'file=@agent_traces/execution_10_interaction.json;type=application/json' \
  http://47.100.28.161:3000/api/test-executions/10/agent-log
```

执行器行为：

- 本地仍会保留 `agent_traces/execution_<executionId>_interaction.json`。
- 上传成功或失败会记录到 `cloud_api_events.json`。
- 上传失败不阻断最终结果上报。

## 5. 云测交互审计文件

每个任务目录下会生成：

```text
results/execution_<id>_<timestamp>/cloud_api_events.json
```

该文件记录和云测平台交互的请求、响应摘要。

典型事件类型：

```text
status_report_request
status_report_response
agent_log_upload_request
agent_log_upload_response
result_report_request
result_report_response
```

示例：

```json
{
  "time": "2026-05-06T17:23:23",
  "type": "result_report_request",
  "url": "http://47.100.28.161:3000/api/execution-results",
  "payload": {
    "testExecutionId": 10,
    "data": {
      "isBuildSuccess": true,
      "executionTime": 274,
      "tokenConsumption": 182984,
      "iterationCount": 1,
      "codeQualityScore": 0,
      "expectedOutputScore": 0,
      "outputCodeUrl": "https://example.com/output.zip",
      "diffFileUrl": "https://example.com/changes.patch"
    }
  }
}
```

本地排障建议：

- 看云测展示日志：优先检查 `executionLog`。
- 看接口请求响应：检查 `cloud_api_events.json`。
- 看完整本地执行过程：检查 `local_execution.log`。
