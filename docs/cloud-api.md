# 云测接口说明

当前执行器对接的云端接口只有三类：

## 1. 下发任务

`POST /api/cloud-api/start`

最小请求体：

```json
{
  "executionId": 135,
  "cloudBaseUrl": "http://127.0.0.1:3000",
  "agentId": "agent_default",
  "token": "xxx",
  "testCase": {
    "input": "修复问题",
    "expectedOutput": "",
    "fileUrl": "https://example.com/original_project.zip"
  }
}
```

字段说明：

- `executionId`
  - 云测任务 ID
- `cloudBaseUrl`
  - 云端服务地址
- `agentId`
  - 本次使用的 agent
- `token`
  - 云端认证 token
- `testCase.fileUrl`
  - 原始工程压缩包地址

## 2. 上报执行进度

`POST /api/test-executions/{id}/report`

请求体：

```json
{
  "status": "running",
  "errorMessage": "",
  "conversation": [],
  "executionLog": "[{\"stage\":\"generating\",\"message\":\"Agent正在处理\",\"detail\":[{\"time\":\"20260410-11:20:00\",\"message\":\"任务已发送\"}]}]"
}
```

字段说明：

- `status`
  - `pending`
  - `running`
  - `completed`
  - `failed`
- `executionLog`
  - 传字符串
  - 内部是阶段日志数组

阶段固定为：

- `pending`
- `preparing`
- `generating`
- `validating`
- `constraint_scoring`
- `static_scoring`
- `completed`

## 3. 上报最终结果

`POST /api/execution-results`

请求体：

```json
{
  "testExecutionId": 135,
  "data": {
    "isBuildSuccess": true,
    "executionTime": 402835,
    "tokenConsumption": 38804,
    "iterationCount": 1,
    "codeQualityScore": 87,
    "expectedOutputScore": 9,
    "outputCodeUrl": "https://example.com/output.zip",
    "diffFileUrl": "https://example.com/changes.patch"
  }
}
```

字段说明：

- `outputCodeUrl`
  - `workspace/` 打包上传后的地址
- `diffFileUrl`
  - `diff/changes.patch` 上传后的地址

## 本地审计文件

每个任务目录下会生成：

- `executor_events.jsonl`
  - 本地运行日志
- `cloud_api_events.jsonl`
  - 云端接口 request/response 审计

其中：

- `status_report_request`
- `status_report_response`
- `result_report_request`
- `result_report_response`

都会先落盘，再发到云端。
