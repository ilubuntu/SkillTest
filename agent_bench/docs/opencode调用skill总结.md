# OpenCode 调用 Skill 总结

## 结论

当前这条 HTTP 执行链已经验证通过：

- OpenCode HTTP API 可以使用 `skill`
- `build-harmony-project` 已经能在 HTTP 会话中生效
- 这次任务已经真实完成了：
  - 代码修改
  - 编译验证
  - HAP 产物生成

不是 CLI 才能调 skill，HTTP 也可以。

## 关键现象

同一个用例在 OpenCode CLI 中表现正常：

- 能读取工程
- 能修改 `Index.ets`
- 能调用 `build-harmony-project`
- 能执行 `assembleHap`
- 能生成 `.hap`

而最初的 HTTP 集成链里，表现异常：

- 模型在 `reasoning` 里提到要调用 `build-harmony-project`
- 但运行日志里没有明显 skill 调用
- 一度只停留在第一轮“探索工程结构”

## 实际定位结果

### 1. 不是 skill 配置问题

本机已确认：

```bash
opencode debug skill
```

能返回：

- `build-harmony-project`

说明 OpenCode 本地运行时已经识别到了这个 skill。

### 2. 不是 HTTP API 天生不支持 skill

查看 OpenCode 本地服务日志：

- `~/.local/share/opencode/log/2026-04-05T022312.log`

能看到：

- `service=session.prompt status=started resolveTools`
- `service=tool.registry status=started skill`
- `service=permission permission=skill pattern=build-harmony-project`

并且还能看到真实编译命令：

- `assembleHap`
- `hvigorw.js --stop-daemon`
- `find ... -name "*.hap"`

这说明：

- HTTP 会话里 `skill` tool 是真的被注册并执行了
- 问题不在 OpenCode HTTP API 本身

### 3. 早期判断误区

之前有两条判断是不可靠的：

#### `skill_tool=no`

来自：

- `/experimental/tool` 的探测结果

这条结果不能代表真实 session 最终拿到的工具集合。它和服务端真实日志冲突，因此只能作为调试信息，不能作为最终结论。

#### `reasoning` 里提到 `build-harmony-project`

这只能说明：

- 模型知道有这个 skill
- 模型计划调用它

不能说明：

- skill 已经被实际调用

`reasoning` 是“思考过程”，不是“执行动作”。

## 本次修正的关键点

### 1. 显式传 OpenCode 内部 agent

HTTP 请求体显式传：

```json
"agent": "build"
```

因为 OpenCode 内部有自己的 agent 概念，CLI 里也能看到：

- `build`
- `plan`

不显式传时，HTTP 行为和 CLI 可能不一致。

### 2. 显式传 tools

HTTP 请求体显式传：

```json
"tools": {
  "skill": true
}
```

至少要保证当前会话允许使用 `skill` tool。

### 3. 对齐 CLI 的消息组织

后面把消息组织收敛成更接近 CLI 的形式：

- skill 要求只保留在用户消息中
- 不再重复放进 `system`
- 工程目录通过 HTTP `directory` 传递

最终请求体大致为：

```json
{
  "parts": [
    {
      "type": "text",
      "text": "任务描述... \n\n## 额外执行要求\n你有一个 HarmonyOS 工程编译验证 skill：build-harmony-project..."
    }
  ],
  "agent": "build",
  "model": {
    "providerID": "minimax-cn-coding-plan",
    "modelID": "MiniMax-M2.7"
  },
  "tools": {
    "skill": true
  }
}
```

### 4. 修复过早结束

之前 `prompt_async + SSE` 的等待逻辑会在第一轮 `finish=tool-calls` 时过早返回，导致：

- 只完成“探索工程”
- 没等到真正修复和编译结束

后面已经改成：

- 不接受 `finish=tool-calls` 作为最终完成
- 要等真正的 `finish=stop`

## 成功证据

最新成功任务目录：

- [execution_1001_20260405_111141](/Users/bb/work/benchmark/github/results/execution_1001_20260405_111141)

关键文件：

- [interaction_metrics.json](/Users/bb/work/benchmark/github/results/execution_1001_20260405_111141/case/agent_meta/interaction_metrics.json)
- [opencode_sse_events.jsonl](/Users/bb/work/benchmark/github/results/execution_1001_20260405_111141/case/agent_meta/opencode_sse_events.jsonl)
- [Index.ets](/Users/bb/work/benchmark/github/results/execution_1001_20260405_111141/case/agent_workspace/entry/src/main/ets/pages/Index.ets)
- [entry-default-unsigned.hap](/Users/bb/work/benchmark/github/results/execution_1001_20260405_111141/case/agent_workspace/entry/build/default/outputs/default/entry-default-unsigned.hap)

从这些文件可确认：

- 最终 `finish = stop`
- `Index.ets` 已被修改
- 真实 `.hap` 已生成

## 当前判定规则

“是否调用 skill” 不能只看模型文本，现在按证据强弱分层判断：

### 一级证据：显式 skill 调用

在原始事件里明确出现：

- `tool` / `skill` 事件
- 且事件内容里有 `build-harmony-project`

### 二级证据：真实编译动作

即使没抓到显式 skill 事件，只要观察到：

- `hvigor`
- `assembleHap`
- `--stop-daemon`
- `.hap` 产物

也可判定：

- 编译验证已真实发生

### 三级证据：模型自报

例如最终文本里写：

- `✅ 调用了 build-harmony-project，构建成功`

这只能作为辅助证据，不能单独作为最终判定。

## 当前剩余问题

### 1. `/experimental/tool` 探测不可靠

`skill_tool=no` 不能再用于下最终结论。

### 2. 并非每次都能直接在原始事件里看到显式 skill 事件

有些情况下：

- 可以看到真实编译产物
- 但看不到直接的 `skill` 事件

所以后续判定必须结合：

- 原始事件
- 编译命令痕迹
- `.hap` 产物

不能只看其中一项。

## 建议

后续如果还要继续接更多 skill，建议保持这几条原则：

1. OpenCode 内部 agent 显式传
2. `tools` 显式传
3. 目录上下文走 HTTP `directory`
4. 不要只靠 `reasoning` 判断 skill 是否执行
5. skill 成功与否要结合真实产物或真实副作用判断
