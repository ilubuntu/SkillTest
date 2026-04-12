# 本地页面与进度接口说明

## 页面总览

```text
+----------------------------------------------------------------------------------------------------------------------+
| 任务状态: Agent正在处理                                                                                              |
|                                                                                                                      |
| 进度条: [任务排队中] -> [执行环境准备中] -> [Agent正在处理] -> [结果验证中] -> [约束规则打分中] -> [静态代码打分中] |
|                                           |                                      |                      |            |
|                                           v                                      v                      v            |
|                                   +------------------+                 +------------------+     +------------------+ |
|                                   | 查看代码处理流程 |                 | 查看约束评分流程 |     | 查看静态代码流程 | |
|                                   +------------------+                 +------------------+     +------------------+ |
+----------------------------------------------------------------------------------------------------------------------+
```

点击按钮后，前端弹出对话框，并通过本地接口轮询读取对应 Agent 的事件流。

## 云端进度上报

`POST /api/test-executions/{id}/report`

请求体：

```json
{
  "status": "running",
  "errorMessage": "",
  "conversation": [],
  "executionLog": "[{\"stage\":\"generating\",\"message\":\"Agent正在处理\",\"detail\":[{\"time\":\"20260408-15:40:22\",\"message\":\"任务已发送\"}]}]"
}
```

说明：

- `executionLog` 传字符串
- 字符串内容是阶段日志数组

阶段值：

- `pending`
- `preparing`
- `generating`
- `validating`
- `constraint_scoring`
- `static_scoring`
- `completed`

## 本地事件读取接口

### 主修复 Agent

`GET /api/local/executions/{id}/generate/events?cursor=0`

### 约束评分 Agent

`GET /api/local/executions/{id}/constraint/events?cursor=0`

### 静态评分 Agent

`GET /api/local/executions/{id}/static/events?cursor=0`

## 返回结构

```json
{
  "items": [
    {
      "seq": 121,
      "timestamp": "2026-04-08T14:00:01+08:00",
      "type": "tool_call",
      "message": "read Index.ets"
    }
  ],
  "nextCursor": 121,
  "finished": false
}
```

字段说明：

- `items`
  - 本次新增事件
- `nextCursor`
  - 下次轮询游标
- `finished`
  - 当前阶段是否结束

## 前端轮询方式

1. 弹窗打开时请求一次 `cursor=0`
2. 保存 `nextCursor`
3. 每 2 秒继续请求
4. 追加新增 `items`
5. `finished=true` 时停止轮询

## 本地文件

每个 Agent 目录下有三类文件：

- `*_opencode_sse_full.jsonl`
- `*_opencode_sse_events.jsonl`
- `*_opencode_progress_events.jsonl`

其中：

- `full` 用于排查问题
- `events` 用于保存裁剪后的原始事件
- `progress` 用于本地页面展示
