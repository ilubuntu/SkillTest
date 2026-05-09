# Agent/LLM 交互流程拉取接口

本文档定义云测平台从执行器拉取 Agent 和 LLM 交互流程的接口。

接口目标：

- 云测平台可以展示 Agent 执行过程时间线。
- 展示模型输出、思考摘要、工具调用、工具耗时、token 统计。
- 执行器本地先把交互流程快照落盘，云测需要展示时再主动请求。
- 该接口不做鉴权。
- `results` 目录可能随时清理，因此交互流程快照需要另存长期目录。

## 1. 接口地址

执行器提供：

```http
GET {executorBaseUrl}/api/cloud-api/agent-interaction?executionId={executionId}
```

兼容路径：

```http
GET {executorBaseUrl}/api/cloud-api/agent-interaction/{executionId}
```

示例：

```http
GET http://127.0.0.1:8000/api/cloud-api/agent-interaction?executionId=997
```

```http
GET http://127.0.0.1:8000/api/cloud-api/agent-interaction/997
```

说明：

| 字段 | 说明 |
| --- | --- |
| `executorBaseUrl` | 执行器服务地址 |
| `executionId` | 云测任务 ID |

## 2. 本地长期保存

任务执行结束后，执行器需要把交互流程快照写入长期保存目录。云测调用接口时，执行器直接读取该目录中的快照并返回。

建议目录：

```text
agent_traces/
  execution_<executionId>_interaction.json
```

示例：

```text
agent_traces/execution_1001_interaction.json
```

目录说明：

| 路径 | 说明 |
| --- | --- |
| `agent_traces/execution_<executionId>_interaction.json` | 云测接口直接返回的最终快照 |

原始数据仍保存在 `results/execution_<id>_<timestamp>/generate/metrics/`：

| 路径 | 说明 |
| --- | --- |
| `generate/metrics/message_history.json` | 主 session 原始 HTTP message 列表 |
| `generate/metrics/sub_<agentname>.json` | subAgent 原始 HTTP message 列表 |
| `generate/metrics/derived.json` | 本地计算出的统计信息 |

保存策略：

- `results` 是任务运行产物目录，可以按磁盘空间策略清理。
- `agent_traces` 是云测展示依赖的长期数据目录，不应跟随 `results` 一起清理。
- 如果需要清理 `agent_traces`，建议按保留天数或 executionId 范围单独清理。
- 接口优先读取 `execution_<executionId>_interaction.json`；如果任务仍在当前进程内且 `results` 未清理，可以从 `results` 的 metrics 临时生成一份快照。

## 3. 成功响应体

正式响应体必须是标准 JSON，不能包含注释。

```json
{
  "executionId": 997,
  "agent": "build",
  "model": "zhipuai-coding-plan/glm-5.1",
  "status": "completed",
  "workingDirectory": "results/execution_997_20260508_195112/workspace",
  "startTime": 1778241084833,
  "endTime": 1778241184863,
  "durationMs": 100030,
  "steps": [
    {
      "index": 0,
      "startTime": 1778241089000,
      "endTime": 1778241093000,
      "durationMs": 4000,
      "tokens": {
        "input": 17415,
        "output": 1554,
        "reasoning": 446,
        "cacheRead": 268096,
        "cacheWrite": 0,
        "total": 287511
      },
      "cost": 0,
      "textLength": 0,
      "text": "",
      "reasoning": "需要先查看商品列表和详情页的数据刷新逻辑。",
      "tools": [
        {
          "tool": "read",
          "status": "completed",
          "input": {
            "filePath": "entry/src/main/ets/pages/Index.ets"
          },
          "outputPreview": "<content>...</content>",
          "durationMs": 8
        }
      ]
    }
  ],
  "subAgents": [
    {
      "name": "harmonyos-explore",
      "title": "Explore network/http and favor API usage",
      "sessionId": "ses_1f845f34fffeDbQyRDQJJZ5GRp",
      "status": "completed",
      "startTime": 1778246094000,
      "endTime": 1778246372342,
      "durationMs": 278342,
      "steps": [
        {
          "index": 0,
          "startTime": 1778246094000,
          "endTime": 1778246101469,
          "durationMs": 7469,
          "tokens": {
            "input": 1200,
            "output": 300,
            "reasoning": 50,
            "cacheRead": 8000,
            "cacheWrite": 0,
            "total": 9550
          },
          "cost": 0,
          "textLength": 0,
          "text": "",
          "reasoning": "Now let me read the key remaining files...",
          "tools": [
            {
              "tool": "read",
              "status": "completed",
              "input": {
                "filePath": "components/attraction_note/src/main/ets/utils/AxiosBase.ets"
              },
              "outputPreview": "<content>...</content>",
              "durationMs": 8
            }
          ]
        }
      ],
      "toolSummary": {
        "read": {
          "count": 12,
          "totalDurationMs": 96
        },
        "glob": {
          "count": 3,
          "totalDurationMs": 20
        }
      },
      "summary": {
        "stepCount": 12,
        "toolCallCount": 15,
        "textLength": 6000,
        "durationMs": 278342,
        "usage": {
          "input_tokens": 10000,
          "output_tokens": 2000,
          "reasoning_tokens": 500,
          "cache_read_tokens": 80000,
          "cache_write_tokens": 0,
          "cost": 0
        }
      }
    }
  ],
  "toolSummary": {
    "read": {
      "count": 5,
      "totalDurationMs": 17
    },
    "edit": {
      "count": 1,
      "totalDurationMs": 1
    },
    "bash": {
      "count": 5,
      "totalDurationMs": 32
    }
  },
  "summary": {
    "stepCount": 17,
    "toolCallCount": 20,
    "subAgentCount": 1,
    "subAgentStepCount": 12,
    "subAgentToolCallCount": 15,
    "textLength": 1181,
    "durationMs": 100030,
    "usage": {
      "input_tokens": 17415,
      "output_tokens": 1554,
      "reasoning_tokens": 446,
      "cache_read_tokens": 268096,
      "cache_write_tokens": 0,
      "cost": 0
    }
  }
}
```

## 4. 顶层字段说明

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `executionId` | number | 是 | 云测任务 ID |
| `agent` | string | 是 | 本次执行使用的 Agent 名称 |
| `model` | string | 否 | 本次执行使用的模型名称 |
| `status` | string | 是 | 交互流程状态，建议值：`completed`、`failed` |
| `workingDirectory` | string | 否 | 本地工作目录，仅用于排障展示 |
| `startTime` | number | 是 | Agent 开始时间，毫秒时间戳 |
| `endTime` | number | 否 | Agent 结束时间，毫秒时间戳 |
| `durationMs` | number | 否 | Agent 总耗时，单位毫秒 |
| `steps` | array | 是 | Agent/LLM 交互步骤列表 |
| `subAgents` | array | 否 | subAgent 交互流程列表。没有 subAgent 时传空数组或不传 |
| `toolSummary` | object | 否 | 工具调用聚合统计 |
| `summary` | object | 否 | 本次交互流程整体统计 |

## 5. steps 字段说明

`steps` 是主 Agent 时间线的核心字段。一个 step 对应一次主 Agent 模型消息或一次模型处理阶段。

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `index` | number | 是 | 步骤序号，从 0 开始 |
| `startTime` | number | 否 | 当前步骤开始时间，毫秒时间戳 |
| `endTime` | number | 否 | 当前步骤结束时间，毫秒时间戳 |
| `durationMs` | number | 否 | 当前步骤耗时，单位毫秒 |
| `tokens` | object | 否 | 当前步骤 token 统计 |
| `cost` | number | 否 | 当前步骤成本，没有时传 0 |
| `textLength` | number | 否 | `text` 字符长度 |
| `text` | string | 否 | 模型对用户可见的输出内容，执行器侧最多保留 500 字符 |
| `reasoning` | string | 否 | 模型思考摘要或推理内容，执行器侧最多保留 500 字符 |
| `tools` | array | 否 | 当前步骤内的工具调用列表 |

## 6. subAgents 字段说明

`subAgents` 用于展示 subAgent 的独立执行过程。不要把 subAgent 的步骤直接混入主 `steps`，否则云测无法区分主 Agent 和 subAgent 的责任边界。

每个 subAgent 的 `steps` 结构和主流程 `steps` 一致。

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `name` | string | 是 | subAgent 名称，例如 `harmonyos-explore` |
| `title` | string | 否 | subAgent 任务标题，例如 `Explore network/http and favor API usage` |
| `sessionId` | string | 否 | OpenCode subAgent session ID，用于本地排障 |
| `status` | string | 否 | subAgent 最终状态，建议值：`completed`、`failed`、`running` |
| `startTime` | number | 否 | subAgent 开始时间，毫秒时间戳 |
| `endTime` | number | 否 | subAgent 结束时间，毫秒时间戳 |
| `durationMs` | number | 否 | subAgent 总耗时，单位毫秒 |
| `steps` | array | 是 | subAgent 内部模型消息、思考和工具调用时间线 |
| `toolSummary` | object | 否 | 当前 subAgent 的工具调用统计 |
| `summary` | object | 否 | 当前 subAgent 的 token、耗时、文本长度等统计 |

subAgent 数据来源：

- 主 Agent 消息里会有 `task` 工具调用，表示启动了 subAgent。
- 执行器通过 subAgent 的 `sessionId` 拉取 `/session/{subSessionId}/message`。
- 每个 subAgent 原始消息会独立保存为 `results/execution_<id>_<timestamp>/generate/metrics/sub_<agentname>.json`，例如 `sub_harmonyos-explore.json`。

## 7. tools 字段说明

`tools` 用于展示模型调用了哪些工具，以及工具执行结果。

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `tool` | string | 是 | 工具名称，例如 `read`、`edit`、`bash`、`skill` |
| `status` | string | 否 | 工具调用状态，例如 `completed`、`failed`、`running` |
| `input` | object | 否 | 工具入参，不同工具结构不同；字符串字段执行器侧最多保留 500 字符 |
| `outputPreview` | string | 否 | 工具输出预览，建议执行器侧截断 |
| `durationMs` | number | 否 | 工具耗时，单位毫秒 |

云测展示时不要强行统一 `input` 的结构。建议按 `tool` 类型定制展示；未知工具直接展示 JSON。

参考 OpenCode 官方 tools 文档，内置工具包括 `bash`、`edit`、`write`、`read`、`grep`、`glob`、`lsp`、`apply_patch`、`skill`、`todowrite`、`webfetch`、`websearch`、`question`。

当前 `test2.json` 中已经出现的工具类型：

```text
read
glob
grep
edit
write
bash
skill
task
todowrite
```

文档中额外补充但 `test2.json` 暂未出现的工具类型：

```text
lsp
apply_patch
patch
webfetch
websearch
question
```

说明：

- `task` 是当前 OpenCode 消息中实际出现的 subAgent 启动工具，虽然不在官方内置工具列表中，也需要展示。
- 官方英文文档当前使用 `apply_patch`，中文文档中仍可能出现 `patch`。展示层建议同时兼容这两个名称。

### 7.1 read

用途：读取文件或目录。

典型入参：

```json
{
  "filePath": "features/mine/src/main/ets/pages/MineView.ets"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `read` | 展示为“读取文件”或“读取目录” |
| 路径 | `input.filePath` | 优先展示相对 workspace 的路径 |
| 状态 | `status` | 展示成功、失败或执行中 |
| 耗时 | `durationMs` | 单位毫秒 |
| 输出预览 | `outputPreview` | 文件内容或目录列表，建议最多展示 500 字符 |

### 7.2 glob

用途：按通配符查找文件。

典型入参：

```json
{
  "pattern": "features/mine/src/main/ets/viewmodel/*.ets"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `glob` | 展示为“查找文件” |
| 匹配规则 | `input.pattern` | 展示 glob 表达式 |
| 状态 | `status` | 展示成功、失败或执行中 |
| 输出预览 | `outputPreview` | 展示命中的文件列表，建议最多 20 行 |

### 7.3 grep

用途：按关键字或正则搜索内容。

典型入参：

```json
{
  "pattern": "FAVOR_TRAVELOGUE|CANCEL_FAVOR_TRAVELOGUE",
  "path": "workspace"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `grep` | 展示为“搜索内容” |
| 搜索词 | `input.pattern` | 展示关键字或正则 |
| 搜索路径 | `input.path` | 优先展示相对 workspace 的路径 |
| 输出预览 | `outputPreview` | 展示匹配文件和行号，建议最多 500 字符 |

### 7.4 edit

用途：修改已有文件。

典型入参：

```json
{
  "filePath": "features/mine/src/main/ets/model/ManagementInfo.ets",
  "oldString": "...",
  "newString": "..."
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `edit` | 展示为“修改文件” |
| 文件路径 | `input.filePath` | 优先展示相对 workspace 的路径 |
| 修改前 | `input.oldString` | 可折叠展示，默认截断 |
| 修改后 | `input.newString` | 可折叠展示，默认截断 |
| 输出预览 | `outputPreview` | 展示编辑是否成功 |

### 7.5 write

用途：新增或覆盖写入文件。

典型入参：

```json
{
  "filePath": "features/mine/src/main/resources/base/media/collections.svg",
  "content": "<svg>...</svg>"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `write` | 展示为“写入文件” |
| 文件路径 | `input.filePath` | 优先展示相对 workspace 的路径 |
| 写入内容 | `input.content` | 可折叠展示，默认截断 |
| 输出预览 | `outputPreview` | 展示写入是否成功 |

### 7.6 bash

用途：执行命令，例如依赖安装、编译验证。

典型入参：

```json
{
  "command": "hvigorw --mode project -p product=default assembleApp --analyze=normal",
  "description": "Build project",
  "timeout": 600000
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `bash` | 展示为“执行命令” |
| 命令 | `input.command` | 等宽字体展示，过长可折叠 |
| 说明 | `input.description` | 没有时不展示 |
| 超时 | `input.timeout` | 单位通常是毫秒 |
| 输出预览 | `outputPreview` | 展示 stdout/stderr 片段，建议最多 500 字符 |

### 7.7 skill

用途：加载或调用本地 skill。

典型入参：

```json
{
  "name": "harmonyos-atomic-dev"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `skill` | 展示为“加载 Skill” |
| Skill 名称 | `input.name` | 展示具体 skill |
| 输出预览 | `outputPreview` | 通常是 skill 文档内容，建议默认折叠 |

### 7.8 task

用途：启动 subAgent。

典型入参：

```json
{
  "description": "Explore network/http and favor API usage",
  "prompt": "Search the codebase...",
  "subagent_type": "harmonyos-explore"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `task` | 展示为“启动 subAgent” |
| subAgent 类型 | `input.subagent_type` | 例如 `harmonyos-explore` |
| 任务说明 | `input.description` | 简短展示 |
| 子任务 Prompt | `input.prompt` | 默认折叠，建议最多展示 500 字符 |
| 输出预览 | `outputPreview` | 通常包含 subAgent 结果摘要，可和 `subAgents` 详情互相跳转 |

### 7.9 todowrite

用途：更新 Agent 的 todo 列表。

典型入参：

```json
{
  "todos": [
    {
      "content": "Create CollectionsVM.ets ViewModel",
      "status": "in_progress",
      "priority": "high"
    }
  ]
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `todowrite` | 展示为“更新 TODO” |
| TODO 列表 | `input.todos` | 按 `status` 和 `priority` 展示 |
| 输出预览 | `outputPreview` | 可不重点展示，优先展示结构化 TODO |

TODO 状态建议映射：

| 原始状态 | 展示文案 |
| --- | --- |
| `pending` | 待处理 |
| `in_progress` | 进行中 |
| `completed` | 已完成 |

### 7.10 lsp

用途：调用项目配置的 LSP 服务，获取定义跳转、引用查找、hover、符号列表、调用层级等代码智能信息。

典型入参：

```json
{
  "operation": "goToDefinition",
  "filePath": "features/mine/src/main/ets/pages/MineView.ets",
  "line": 42,
  "character": 18
}
```

也可能出现：

```json
{
  "operation": "findReferences",
  "filePath": "features/mine/src/main/ets/pages/MineView.ets",
  "line": 42,
  "character": 18
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `lsp` | 展示为“代码智能查询” |
| 操作类型 | `input.operation` | 例如 `goToDefinition`、`findReferences`、`hover` |
| 文件路径 | `input.filePath` | 优先展示相对 workspace 的路径 |
| 位置 | `input.line`、`input.character` | 展示为 `line:character` |
| 输出预览 | `outputPreview` | 展示定义位置、引用列表或 hover 内容 |

支持的常见 `operation`：

```text
goToDefinition
findReferences
hover
documentSymbol
workspaceSymbol
goToImplementation
prepareCallHierarchy
incomingCalls
outgoingCalls
```

### 7.11 apply_patch / patch

用途：应用补丁修改文件。

典型入参：

```json
{
  "patchText": "*** Begin Patch\n*** Update File: src/example.ts\n...\n*** End Patch"
}
```

兼容旧格式：

```json
{
  "patch": "*** Begin Patch\n*** Update File: src/example.ts\n...\n*** End Patch"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `apply_patch` 或 `patch` | 展示为“应用补丁” |
| 补丁内容 | `input.patchText` 或 `input.patch` | 可折叠展示，默认截断 |
| 影响文件 | 从补丁头解析 | 解析 `*** Add File`、`*** Update File`、`*** Delete File`、`*** Move to` |
| 输出预览 | `outputPreview` | 展示补丁是否应用成功 |

路径解析规则：

- `*** Add File: path` 展示为新增文件。
- `*** Update File: path` 展示为修改文件。
- `*** Delete File: path` 展示为删除文件。
- `*** Move to: path` 展示为移动/重命名目标。

### 7.12 webfetch

用途：获取指定网页内容。

典型入参：

```json
{
  "url": "https://opencode.ai/docs/tools/"
}
```

可能附带提示：

```json
{
  "url": "https://opencode.ai/docs/tools/",
  "prompt": "Summarize the built-in tool list"
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `webfetch` | 展示为“读取网页” |
| URL | `input.url` | 可点击展示 |
| 提示 | `input.prompt` | 没有时不展示 |
| 输出预览 | `outputPreview` | 展示网页摘要或正文片段，默认折叠 |

### 7.13 websearch

用途：联网搜索信息。

典型入参：

```json
{
  "query": "OpenCode built-in tools"
}
```

可能附带搜索参数：

```json
{
  "query": "HarmonyOS hvigor build error",
  "numResults": 5
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `websearch` | 展示为“联网搜索” |
| 搜索词 | `input.query` | 展示用户/模型搜索的关键词 |
| 结果数量 | `input.numResults`、`input.limit` | 没有时不展示 |
| 输出预览 | `outputPreview` | 展示搜索结果标题、链接和摘要 |

### 7.14 question

用途：在执行过程中向用户提问，通常用于方案确认、需求澄清或选择分支。

典型入参：

```json
{
  "title": "确认修复方案",
  "question": "是否按当前方案修改 Index.ets？",
  "options": [
    {
      "label": "同意",
      "description": "继续按当前方案修改"
    },
    {
      "label": "取消",
      "description": "停止修改"
    }
  ]
}
```

可能的返回内容：

```json
{
  "answers": [
    [
      "同意"
    ]
  ]
}
```

展示建议：

| 展示项 | 来源 | 说明 |
| --- | --- | --- |
| 工具标题 | `question` | 展示为“用户确认” |
| 标题 | `input.title` 或 `input.header` | 没有时不展示 |
| 问题 | `input.question` | 展示问题正文 |
| 选项 | `input.options` | 展示 label 和 description |
| 用户回答 | `outputPreview` 或 answer 字段 | 展示最终选择 |
| 状态 | `status` | 展示等待中、已完成或失败 |

通用展示规则：

- `input` 保留原始 JSON，不同工具允许字段不同。
- 路径类字段优先展示相对 `workingDirectory` 的路径。
- 长文本默认折叠，`input` 内字符串字段最多保留 500 字符，`outputPreview` 最多保留 500 字符。
- `outputPreview` 里的 ANSI 颜色码建议在执行器侧去除；如果未去除，云测展示前也应清理。
- 未识别的工具类型按通用 JSON 卡片展示：工具名、状态、耗时、入参、输出预览。

## 8. summary 字段说明

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `stepCount` | number | 步骤总数 |
| `toolCallCount` | number | 工具调用总数 |
| `subAgentCount` | number | subAgent 数量 |
| `subAgentStepCount` | number | 所有 subAgent 的 step 总数 |
| `subAgentToolCallCount` | number | 所有 subAgent 的工具调用总数 |
| `textLength` | number | 模型可见输出总字符数 |
| `durationMs` | number | 总耗时，单位毫秒 |
| `usage.input_tokens` | number | 输入 token 总数 |
| `usage.output_tokens` | number | 输出 token 总数 |
| `usage.reasoning_tokens` | number | 推理 token 总数 |
| `usage.cache_read_tokens` | number | 缓存读取 token 总数 |
| `usage.cache_write_tokens` | number | 缓存写入 token 总数 |
| `usage.cost` | number | 成本，没有时传 0 |

## 9. 未准备好响应

接口不做鉴权。数据未准备好或 executionId 不存在时，仍返回 HTTP 200，响应体用 `status=not_ready` 表示。

```json
{
  "executionId": 997,
  "status": "not_ready",
  "message": "executionId=997 的 Agent/LLM 交互流程数据尚未准备好，或该任务 ID 不存在"
}
```

## 10. 拉取策略

第一版建议使用结果验证阶段后拉取：

- Agent 执行结束、结果验证开始前，执行器生成长期快照。
- 云测展示详情页时主动调用 `GET /api/cloud-api/agent-interaction?executionId={executionId}`。
- 兼容 `GET /api/cloud-api/agent-interaction/{executionId}`，但推荐查询参数形式，和现有状态查询接口风格一致。
- 同一个 `executionId` 多次请求时，返回同一份长期快照。
- 如果 Agent 阶段尚未完成或任务 ID 不存在，返回 `status=not_ready`。
- 不做鉴权。

后续如果要实时展示，可以新增独立的实时接口；不要把该长期快照接口改成流式协议。
