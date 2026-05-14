# Skill 管理与任务下发接口

## 1. 设计目标

新任务协议下，Agent、LLM、Plugin、Skill 均由云测下发。执行器不再提供 LLM 列表接口，也不再通过本地配置选择新协议任务的模型。

执行器负责：

- 接收云测任务。
- 按 `codeAgent` 创建 OpenCode Agent 配置。
- 下载、缓存、解压并挂载云测下发的 Skill。
- 执行任务并上报进度、结果和 Agent/LLM 交互日志。

## 2. 新任务下发接口

```text
POST /api/cloud-api/executions
```

请求示例：

```json
{
  "executionId": 1492,
  "testCase": {
    "input": "这是一个商品管理工程，首页展示商品列表（Index.ets），点击添加进入修改添加商品页面（DetailPage.ets），当前添加商品后首页列表不更新，请修复。",
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
        "id": 1,
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

响应示例：

```json
{
  "accepted": true,
  "executionId": 1492,
  "message": "任务已接收，等待执行",
  "agentId": "16"
}
```

## 3. 字段说明

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `executionId` | number | 是 | 云测任务 ID |
| `testCase.input` | string | 是 | 真实任务输入，不能为空 |
| `testCase.expectedOutput` | string | 否 | 期望结果，允许为空 |
| `testCase.fileUrl` | string | 否 | 原始工程包地址，允许为空 |
| `codeAgent.id` | number/string | 是 | 云测 Agent ID，用于日志和结果归属 |
| `codeAgent.name` | string | 是 | 云测 Agent 名称，用于展示和日志 |
| `codeAgent.model.name` | string | 否 | 模型展示名称 |
| `codeAgent.model.code` | string | 是 | OpenCode 模型编码，例如 `huawei/glm-5.1` |
| `codeAgent.plugins` | array | 是 | Plugin 列表，当前使用第一个 |
| `codeAgent.plugins[].name` | string | 是 | OpenCode Agent 名称，仅支持 `build`、`harmonyos-plugin` |
| `codeAgent.skills` | array | 否 | 本次任务挂载的 Skill 列表 |
| `codeAgent.skills[].name` | string | 是 | Skill 名称 |
| `codeAgent.skills[].version` | string | 是 | Skill 版本 |
| `codeAgent.skills[].fileUrl` | string | 是 | Skill zip 下载地址，仅支持 HTTP/HTTPS |

执行器发送给 OpenCode 时，会把 `codeAgent.model.code` 解析为 OpenCode model：

```json
{
  "model": {
    "providerID": "huawei",
    "modelID": "glm-5.1"
  }
}
```

## 4. Skill 处理流程

执行器收到新协议任务后，对 `codeAgent.skills` 逐个处理：

1. 校验 `name`、`version`、`fileUrl`。
2. 使用 `name + version + fileUrl hash` 作为缓存 key。
3. 下载 Skill zip 到本地缓存目录。
4. 解压到当前任务目录。
5. 定位并校验 `SKILL.md`。
6. 作为 `mounted_skills` 挂载到当前任务 OpenCode 配置。

Skill zip 内可以直接包含 `SKILL.md`，也可以只有一层目录，执行器会自动查找。

## 5. 兼容老接口

老接口继续保留：

```text
POST /api/cloud-api/agent/{agent_id}
POST /api/cloud-api/agent/id={agent_id}
```

老接口行为不变：

- `agent_id` 来自 URL。
- Agent、模型、Skill 仍从本地 `config/agents.yaml` 读取。
- 请求体仍只需要 `executionId + testCase`。
- 老接口不支持云测动态下发 `codeAgent.skills[].fileUrl`。

## 6. 已下线能力

执行器不再提供：

```text
GET /api/cloud-api/llm-catalog
```

新协议模型由云测直接通过 `codeAgent.model.code` 下发。执行器启动也不再依赖 `config/llm.yaml`。

## 7. 失败场景

以下情况直接返回 400：

- `testCase.input` 为空。
- `codeAgent` 缺失。
- `codeAgent.id` 或 `codeAgent.name` 为空。
- `codeAgent.model.code` 为空。
- `codeAgent.plugins` 为空。
- `codeAgent.plugins[0].name` 不是 `build` 或 `harmonyos-plugin`。
- Skill `name`、`version`、`fileUrl` 为空。
- Skill `fileUrl` 不是 HTTP/HTTPS。

以下情况在执行阶段失败并上报：

- Skill 包下载失败。
- Skill 包不是 zip。
- Skill 包解压失败。
- Skill 包中不存在 `SKILL.md`。
