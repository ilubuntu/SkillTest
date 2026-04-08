## 页面交互总览

```text
+----------------------------------------------------------------------------------------------------------------------+
| 任务状态: Agent正在处理                                                                                                  |
|                                                                                                                        |
| 进度条: [任务排队中] -> [执行环境准备中] -> [Agent正在处理] -> [结果验证中] ->     [约束规则打分中] ->     [静态代码打分中] |
|                                           |                                      |                       |             |
|                                           v                                      v                       v             |
|                                   +------------------+                 +------------------+      +------------------+   |
|                                   | 查看代码处理流程 |                   | 查看约束评分流程 |         | 查看静态代码评分流程 |      |
|                                   +------------------+                 +------------------+      +------------------+   |
|                                                                                                                        |
+----------------------------------------------------------------------------------------------------------------------+

点击任一按钮后，弹出对话框；对话框通过本地执行器接口轮询读取对应 agent 的 SSE 精简事件流，
前端只展示解析后的关键流程，不直接读取本地 jsonl 文件。
```

## 执行状态上报接口设计

### 设计原则

- 云端进度接口只上报高层任务状态，不再上传 SSE 和大模型细粒度交互过程。
- 本地执行器保留 3 段 Agent 交互文件，分别用于本地页面读取：
  - `generate`
  - `constraint`
  - `static`
- 云端只需要知道任务当前状态、当前阶段、展示文案、错误信息以及本地产物是否可查看。

### 更新执行状态

`POST https://xxxxx/api/test-executions/{id}/report`

```json
{
  "status": "running",
  "stage": "generating",
  "message": "Agent正在处理",
  "errorMessage": "",
  "artifacts": {
    "generateAvailable": true,
    "constraintAvailable": false,
    "staticAvailable": false
  },
  "updatedAt": "2026-04-08T11:20:00+08:00"
}
```

### 字段说明

#### `status`

任务整体状态，固定 4 个值：

- `pending`
- `running`
- `completed`
- `failed`

#### `stage`

任务当前阶段，固定 7 个值：

- `pending`
- `preparing`
- `generating`
- `validating`
- `constraint_scoring`
- `static_scoring`
- `completed`

说明：

- 当 `status=failed` 时，`stage` 保留失败发生时所在阶段。
- 例如：
  - `status=failed`
  - `stage=constraint_scoring`

#### `message`

给前端直接展示的中文文案，建议固定映射：

- `pending` -> `任务排队中`
- `preparing` -> `执行环境准备中`
- `generating` -> `Agent正在处理`
- `validating` -> `结果验证中`
- `constraint_scoring` -> `约束规则打分中`
- `static_scoring` -> `静态代码打分中`
- `completed` -> `任务执行完成`

失败时建议：

- `status=failed`
- `message=任务执行失败`

#### `errorMessage`

- 失败时填写错误信息
- 正常情况下可为空字符串或不传

#### `artifacts`

表示本地是否已有可查看产物：

```json
{
  "generateAvailable": true,
  "constraintAvailable": false,
  "staticAvailable": false
}
```

字段含义：

- `generateAvailable`：主修复 Agent 本地产物是否已生成
- `constraintAvailable`：约束规则打分产物是否已生成
- `staticAvailable`：静态代码打分产物是否已生成

#### `updatedAt`

最后更新时间，建议使用 ISO 时间字符串。

### 说明

- `conversation` 字段不再建议用于上传大模型交互流程。
- SSE、progress、metrics 等细粒度数据只保存在本地，由本地页面通过本机接口读取。
- 云端进度上报只保留阶段化状态，避免上报过多交互细节。

### 示例

#### 排队中

```json
{
  "status": "pending",
  "stage": "pending",
  "message": "任务排队中",
  "artifacts": {
    "generateAvailable": false,
    "constraintAvailable": false,
    "staticAvailable": false
  },
  "updatedAt": "2026-04-08T11:20:00+08:00"
}
```

#### Agent 处理中

```json
{
  "status": "running",
  "stage": "generating",
  "message": "Agent正在处理",
  "artifacts": {
    "generateAvailable": true,
    "constraintAvailable": false,
    "staticAvailable": false
  },
  "updatedAt": "2026-04-08T11:23:00+08:00"
}
```

#### 失败

```json
{
  "status": "failed",
  "stage": "constraint_scoring",
  "message": "任务执行失败",
  "errorMessage": "constraint-score-review 调用超时",
  "artifacts": {
    "generateAvailable": true,
    "constraintAvailable": true,
    "staticAvailable": false
  },
  "updatedAt": "2026-04-08T11:30:00+08:00"
}
```

## 本地 SSE 交互读取接口设计

### 设计原则

- 云端状态接口不再上传 `conversation`、SSE、progress、metrics 等大模型交互细节。
- 本地执行器保留 3 段交互文件，前端弹窗通过本地接口按游标增量读取：
  - `generate`
  - `constraint`
  - `static`
- 前端不直接读取本地 jsonl 文件，只调用本地执行器 HTTP 接口。

### 本地接口

#### 主修复 Agent 交互流程

`GET /api/local/executions/{id}/generate/events?cursor=0`

#### 约束规则打分 Agent 交互流程

`GET /api/local/executions/{id}/constraint/events?cursor=0`

#### 静态代码打分 Agent 交互流程

`GET /api/local/executions/{id}/static/events?cursor=0`

### 请求参数

#### `cursor`

- 表示前端上一次已经读取到的最后一条事件序号
- 首次打开弹窗时传 `0`
- 后续轮询时传上一次返回的 `nextCursor`

### 返回结构

```json
{
  "items": [
    {
      "seq": 121,
      "timestamp": "2026-04-08T14:00:01+08:00",
      "type": "tool_call",
      "message": "read Index.ets"
    },
    {
      "seq": 122,
      "timestamp": "2026-04-08T14:00:03+08:00",
      "type": "tool_result",
      "message": "edit Index.ets (completed)"
    }
  ],
  "nextCursor": 122,
  "finished": false
}
```

### 字段说明

#### `items`

- 本次新增的事件列表
- 只返回 `seq > cursor` 的增量内容

#### `seq`

- 事件的稳定递增序号
- 前端用它做增量游标

#### `timestamp`

- 事件时间

#### `type`

建议只保留精简后的关键类型：

- `step_start`
- `reasoning`
- `tool_call`
- `tool_result`
- `text`
- `step_finish`

#### `message`

- 给前端直接展示的简短流程说明

#### `nextCursor`

- 下一次轮询时直接带回该值

#### `finished`

- `false`：当前 agent 流程仍在运行，前端继续轮询
- `true`：当前 agent 流程已结束，前端停止轮询

### 前端弹窗交互方案

#### 打开方式

- 页面顶端显示总进度条
- 根据云端状态接口中的 `artifacts` 字段控制 3 个按钮是否可点击：
  - `generateAvailable`
  - `constraintAvailable`
  - `staticAvailable`

#### 交互流程

1. 用户点击某个阶段按钮
2. 弹出对应 dialog
3. 前端首次请求本地接口，`cursor=0`
4. 前端保存返回的 `nextCursor`
5. 前端每 1 到 2 秒继续请求一次对应接口
6. 将新增 `items` 追加到弹窗时间线
7. 当 `finished=true` 时停止轮询

### 本地文件与接口对应关系

#### `generate`

- `generate/agent_opencode_sse_events.jsonl`
- `generate/agent_opencode_progress_events.jsonl`
- `generate/agent_interaction_metrics.json`

#### `constraint`

- `constraint/constraint_review_opencode_sse_events.jsonl`
- `constraint/constraint_review_opencode_progress_events.jsonl`
- `constraint/constraint_review_interaction_metrics.json`

#### `static`

- `static/static_review_opencode_sse_events.jsonl`
- `static/static_review_opencode_progress_events.jsonl`
- `static/static_review_interaction_metrics.json`

### 说明

- 本地接口内部负责读取对应 jsonl 文件，并转换为前端可展示的精简事件。
- 浏览器不直接访问本地文件路径。
- 云端页面不展示 SSE 细节，只展示阶段状态；本地页面通过弹窗查看 Agent 实时交互流程。
