# OpenCode 调用 Skill 说明

## 结论

执行器通过 OpenCode HTTP API 调用 skill。

主流程中实际使用的 skill 包括：

- `build-harmony-project`
- `constraint-score-review`
- `harmonyos-gen-code-evaluator`

## 调用方式

OpenCode 请求体中显式携带：

- `agent`
- `model`
- `tools.skill = true`

工程目录通过请求参数 `directory` 传递。

## 生效条件

要让 skill 能正常调用，需满足：

1. OpenCode 配置目录下存在对应 skill 目录
2. skill 目录中存在 `SKILL.md`
3. 当前 Agent 的 `mounted_skills` 已正确配置
4. OpenCode 会话允许使用 `skill` 工具

## 当前排查方式

排查 skill 是否可用时，直接检查：

- `~/.config/opencode/skills/<skill_name>/`
- `~/.config/opencode/skills/<skill_name>/SKILL.md`

不依赖 `opencode debug skill`。

## 相关日志

主流程里会记录：

- skill 挂载开始
- skill 挂载目标目录
- skill 挂载完成
- skill 挂载校验通过
- interaction metrics 中是否观察到预期 skill 调用痕迹

## 常见问题

### skill 已挂载但未实际调用

需要检查：

- prompt 是否明确要求调用该 skill
- 当前 Agent 的 `tools.skill` 是否开启
- interaction metrics 中是否出现对应 `tool:<skill_name>`

### 外部目录权限

当 skill 或工具需要访问外部目录时，当前 session 的完整 SSE 文件用于定位：

- `*_opencode_sse_full.jsonl`

### 输出文件路径

关键结果文件路径由 prompt 和主链目录约束共同控制。

例如静态评分结果固定写入：

- `static/harmonyos_evaluation_result.json`
