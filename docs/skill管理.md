# Skill 管理与任务下发接口设计

## 1. 设计目标

后续 Agent 和 Skill 全部由云测平台托管。执行器本地不再维护 Agent / Skill 配置文件，也不再通过本地 `agents.yaml` 查找 Agent。

执行器只负责：

- 接收云测下发的任务。
- 根据云端下发的 Agent 配置创建 OpenCode 会话。
- 提供本地可用 LLM 列表，供云测选择模型和供应商。
- 下载、缓存、解压、校验并挂载 Skill。
- 执行任务并上报进度、结果。

## 2. LLM 列表接口

LLM 可用列表由本地执行器提供，因为实际可用的 provider 和 model 取决于当前机器的 OpenCode 配置。

```text
GET /api/cloud-api/llm-catalog
```

响应体最外层直接返回数组：

```json
[
  {
    "model": "glm-5.1",
    "providers": [
      {
        "providerId": "glm5-local",
        "providerName": "本地 GLM5.1",
        "modelId": "glm-5.1",
        "enabled": true
      },
      {
        "providerId": "zhipuai-coding-plan",
        "providerName": "智谱 Coding Plan",
        "modelId": "glm-5.1",
        "enabled": true
      }
    ]
  },
  {
    "model": "glm-5",
    "providers": [
      {
        "providerId": "zhipuai-coding-plan",
        "providerName": "智谱 Coding Plan",
        "modelId": "glm-5-turbo",
        "enabled": true
      }
    ]
  },
  {
    "model": "MiniMax-M2.7",
    "providers": [
      {
        "providerId": "minimax",
        "providerName": "MiniMax",
        "modelId": "MiniMax-M2.7",
        "enabled": true
      }
    ]
  }
]
```

云测选择流程：

1. 先选择 Agent。
2. 调用 `GET /api/cloud-api/llm-catalog`。
3. 先选择 `model`。
4. 再从该 `model.providers` 中选择供应商。
5. 任务下发时只携带最终选择的 `providerId` 和 `modelId`。

## 3. 任务下发接口

新协议接口名称改为创建执行任务语义：

```text
POST /api/cloud-api/executions
```

不再使用 URL 中的 `agentId` 区分 Agent。Agent 信息全部放在请求体的 `agentConfig` 中。

当前老接口继续保留，兼容现有云测任务下发流程：

```text
POST /api/cloud-api/agent/{agent_id}
POST /api/cloud-api/agent/id={agent_id}
```

老接口仍按本地 `config/agents.yaml` 查找 Agent，不受新协议影响。新旧接口可以并存，后续云测切到新协议后再评估是否下线老接口。

## 4. 请求体

```json
{
  "executionId": 1001,
  "agentConfig": {
    "id": "harmonyos-plugin",
    "agent": "harmonyos-plugin",
    "llm": {
      "providerId": "zhipuai-coding-plan",
      "modelId": "glm-5.1"
    },
    "pluginVersion": "1.0.0",
    "extraPrompt": "在调用工具或 skill 处理任务时，请使用默认选项直接执行，不需要询问我。",
    "defaultSkills": [
      {
        "name": "harmonyos-atomic-dev",
        "version": "1.2.0",
        "path": "https://example.com/skills/harmonyos-atomic-dev-1.2.0.zip"
      }
    ]
  },
  "dynamicSkills": [
    {
      "name": "custom-rating-fix",
      "version": "0.1.0",
      "path": "https://example.com/skills/custom-rating-fix-0.1.0.zip"
    }
  ],
  "testCase": {
    "input": "修复首页列表不刷新问题",
    "expectedOutput": "",
    "fileUrl": "https://example.com/project.zip"
  }
}
```

## 5. 字段说明

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `executionId` | number | 是 | 云测任务 ID |
| `agentConfig` | object | 是 | 云端托管的 Agent 运行配置 |
| `agentConfig.id` | string | 是 | Agent 标识，用于日志、统计和结果归属；不要包含模型名称，模型由 `llm` 字段单独选择 |
| `agentConfig.agent` | string | 是 | OpenCode Agent 名称，支持 `build`、`harmonyos-plugin`，执行器不再做映射 |
| `agentConfig.llm.providerId` | string | 是 | OpenCode 使用的供应商 ID |
| `agentConfig.llm.modelId` | string | 是 | OpenCode 使用的模型 ID |
| `agentConfig.pluginVersion` | string | 否 | Plugin 版本，非插件 Agent 可为空 |
| `agentConfig.extraPrompt` | string | 否 | 追加给 Agent 的执行要求 |
| `agentConfig.defaultSkills` | array | 否 | 当前 Agent 默认挂载的 Skill |
| `dynamicSkills` | array | 否 | 本次任务动态挂载的 Skill |
| `testCase.input` | string | 是 | 真实任务输入，不能为空 |
| `testCase.expectedOutput` | string | 否 | 期望结果，允许为空 |
| `testCase.fileUrl` | string | 否 | 原始工程包地址，允许为空 |

Skill 字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `name` | string | 是 | OpenCode 中可调用的 Skill 名称 |
| `version` | string | 是 | Skill 版本 |
| `path` | string | 是 | Skill 压缩包下载地址，仅支持 HTTP/HTTPS |

执行器发送给 OpenCode 时，会把 `llm` 转换为：

```json
{
  "model": {
    "providerID": "zhipuai-coding-plan",
    "modelID": "glm-5.1"
  }
}
```

## 6. Agent 名称

云测直接下发 OpenCode Agent 名称，执行器不再做二次映射：

```text
build
harmonyos-plugin
```

后续新增 Agent 时，也直接使用 OpenCode 配置里的 Agent 名称。

## 7. Skill 挂载规则

最终挂载 Skill 由两部分组成：

```text
effectiveSkills = agentConfig.defaultSkills + dynamicSkills
```

规则：

- `agentConfig.defaultSkills` 是云端 Agent 配置中声明的默认 Skill。
- `dynamicSkills` 是本次任务临时增加的 Skill。
- 同名 Skill 冲突时，`dynamicSkills` 覆盖 `defaultSkills`。
- `dynamicSkills` 为空或不传时，只使用 `agentConfig.defaultSkills`。
- `agentConfig.defaultSkills` 为空或不传时，只使用 `dynamicSkills`。
- 两者都为空时，本次任务不挂载任何 Skill。

## 8. Skill 包处理流程

执行器收到任务后，对最终 Skill 列表逐个处理：

1. 校验 `name`、`version`、`path`。
2. 使用 `name + version + path hash` 作为缓存 key。
3. 下载 Skill 包到本地缓存目录。
4. 解压到当前任务目录。
5. 校验解压结果中存在 `SKILL.md`。
6. 挂载到当前 workspace：

```text
workspace/.opencode/skills/{name}
```

7. 写入当前 workspace 的 OpenCode 配置，只允许本次最终 Skill：

```json
{
  "permission": {
    "skill": {
      "*": "deny",
      "harmonyos-atomic-dev": "allow",
      "custom-rating-fix": "allow"
    }
  },
  "tools": {
    "skill": true
  }
}
```

## 9. 响应体

响应保持和当前任务下发接口一致：

```json
{
  "accepted": true,
  "executionId": 1001,
  "message": "任务已接收"
}
```

## 10. 失败场景

以下情况直接拒绝任务或执行失败，并上报明确错误：

- `agentConfig` 缺失。
- `agentConfig.id` 为空。
- `agentConfig.agent` 不是 `build` 或 `harmonyos-plugin`。
- `agentConfig.llm.providerId` 为空。
- `agentConfig.llm.modelId` 为空。
- `testCase.input` 为空。
- Skill `name`、`version`、`path` 任一为空。
- Skill `path` 不是 HTTP/HTTPS URL。
- Skill 包下载失败。
- Skill 包解压失败。
- Skill 包中不存在 `SKILL.md`。

## 11. 本地配置策略

新协议下，本地不再维护 Agent / Skill 主配置，但会维护可用 LLM 列表：

```text
config/llm.yaml
```

`config/llm.yaml` 示例：

```yaml
- model: "glm-5.1"
  providers:
    - providerId: "glm5-local"
      providerName: "本地 GLM5.1"
      modelId: "glm-5.1"
      enabled: true
    - providerId: "zhipuai-coding-plan"
      providerName: "智谱 Coding Plan"
      modelId: "glm-5.1"
      enabled: true

- model: "glm-5"
  providers:
    - providerId: "zhipuai-coding-plan"
      providerName: "智谱 Coding Plan"
      modelId: "glm-5-turbo"
      enabled: true

- model: "MiniMax-M2.7"
  providers:
    - providerId: "minimax"
      providerName: "MiniMax"
      modelId: "MiniMax-M2.7"
      enabled: true
```

不再依赖：

- `config/agents.yaml`
- 本地默认 Skill 配置
- URL 中的 `agentId`

云测必须完整下发本次任务需要的 Agent 配置和 Skill 信息。

兼容说明：上述“不再依赖”只针对新接口 `/api/cloud-api/executions`。现有 `/api/cloud-api/agent/{agent_id}` 老接口仍继续依赖 `config/agents.yaml`，用于兼容当前流程。
