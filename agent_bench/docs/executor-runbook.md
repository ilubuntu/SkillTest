# 执行器运行说明

## 当前形态

当前项目已经收敛为本地执行器模式，不再提供本地网页。

本地只保留两个运行组件：

- `OpenCode Server`
  - 端口 `4096`
  - 负责 Agent 执行
- `执行器服务`
  - 端口 `8000`
  - 负责接收任务、准备工程、调用 Agent、上报进度和结果

执行器入口代码在：

- [main.py](/Users/bb/work/benchmark/github/agent_bench/executor/main.py)
- [cloud_api.py](/Users/bb/work/benchmark/github/agent_bench/executor/cloud_api.py)

---

## 启动方式

在仓库根目录执行：

```bash
./deploy.sh start
```

启动后会做这些事：

1. 检查 `opencode` 和 `python3`
2. 启动 `OpenCode Server`
3. 启动本地执行器服务
4. 直接进入流程日志视图

启动完成后会提示：

```text
执行器已就绪，等待任务下发...
```

同时会打印：

- 健康检查地址
- 任务入口地址
- 状态查询地址
- 当前日志文件路径

---

## 启动后的交互方式

`./deploy.sh start` 启动后会直接 tail 执行器流程日志。

此时：

- `Ctrl+C`
  - 会退出日志查看
  - 同时停止本次启动的全部服务

如果只想单独查看日志，而不影响服务运行，使用：

```bash
./deploy.sh logs
```

此时：

- `Ctrl+C`
  - 只退出日志查看
  - 不停止服务

---

## 其他常用命令

查看状态：

```bash
./deploy.sh status
```

停止全部服务：

```bash
./deploy.sh stop
```

整套重启：

```bash
./deploy.sh restart
```

只重启执行器服务，不重启 OpenCode：

```bash
./deploy.sh restart-executor
```

---

## 本地模拟任务下发

本地模拟脚本：

- [mock_cloud_task.sh](/Users/bb/work/benchmark/github/scripts/mock_cloud_task.sh)

执行：

```bash
./scripts/mock_cloud_task.sh
```

默认会下发一条本地测试任务，包含：

- `executionId`
- `fileUrl`
- `input`
- `expectedOutput`

默认工程包地址：

```text
https://agc-storage-drcn.platform.dbankcloud.cn/v0/agent-bench-lpgvk/original_project.zip
```

也可以覆盖参数，例如：

```bash
EXECUTION_ID=2001 \
AGENT_ID=agent_default \
FILE_URL='https://agc-storage-drcn.platform.dbankcloud.cn/v0/agent-bench-lpgvk/original_project.zip' \
INPUT_TEXT='这是一个商品管理工程，首页展示商品列表（Index.ets），点击添加进入修改添加商品页面（DetailPage.ets），当前添加商品后首页列表不更新,请修复，直接在当前工程中修改代码,并说明修改了哪些文件' \
EXPECTED_OUTPUT='请修复问题，并说明修改了哪些文件。' \
./scripts/mock_cloud_task.sh
```

---

## 云测联调方式

云测页面里，Agent 接口地址填写：

```text
http://127.0.0.1:8000/api/cloud-api/start
```

前提：

- 云测页面是本机浏览器打开
- 本地执行器已经启动

本地健康检查：

```text
http://127.0.0.1:8000/api/health
```

任务状态查询：

```text
http://127.0.0.1:8000/api/cloud-api/status
```

---

## 日志与运行产物

### 主日志

OpenCode 服务日志：

- [opencode.log](/Users/bb/work/benchmark/github/logs/opencode.log)

执行器流程日志：

- `logs/agent_bench_<timestamp>.log`

当前正在使用的执行器日志文件路径会写到：

- `logs/current_executor_log`

`./deploy.sh logs` 会自动跟随当前这份日志。

### 单次任务目录

每次任务会生成一个运行目录：

```text
agent_bench/results/cloud_api/execution_<executionId>_<timestamp>/
```

重点文件：

- `executor_events.jsonl`
  - 本地事件总流水
- `progress_events.jsonl`
  - 进度事件队列
- `progress_upload_state.json`
  - 进度上传游标
- `case/agent_meta/interaction_metrics.json`
  - OpenCode 结构化交互数据
- `case/agent_meta/opencode_sse_events.jsonl`
  - 过滤后的 SSE 原始事件
- `case/agent_meta/opencode_progress_events.jsonl`
  - 映射后的进度事件
- `case/agent_workspace/`
  - Agent 修改后的工程目录

---

## 当前日志风格

当前主日志以流程为主，不再打印本地网页时代的旧标签。

常见形式：

```text
收到任务下发 taskId=1001 agentId=agent_default fileUrl=https://...
[状态] 任务开始执行
[准备] 工程已就绪: ...
Case Prompt:
开始处理用例: ...
[开始] Agent运行
配置 OpenCode 运行...
开始 OpenCode 运行...
OpenCode 运行完成, 输出=...
```

设计原则：

- 任务号只在“收到任务下发”时打印一次
- 后续流程日志不重复打印任务号
- HTTP access log 已关闭
- 日志重点放在程序实际运行状态

---

## 当前默认执行模型

当前默认 Agent：

- `agent_default`
- 展示名：`OpenCode`

当前流程是单 Agent 模式：

- 不再有 `baseline / candidate`
- 不再有 `side_a / side_b`

输出目录统一为：

- `agent_workspace`
- `agent_meta`

---

## 维护建议

后续如果继续收敛，优先保持这几个原则：

1. 本地执行器只保留最小 HTTP 接口
2. 日志优先写流程状态，不要回退到 HTTP 访问日志
3. 本地模拟和云测联调必须共用同一条任务入口
4. 单 Agent 模式下不要再引入双侧比较概念
