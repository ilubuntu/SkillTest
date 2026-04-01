# Cloud API

这份文档只写最小闭环，并且同时考虑两类交互：

1. 端 -> 云
2. 云 -> 端

这里的“端”包含两种角色：
- 前端页面
- 本机执行器

目标是先把当前本机版迁到云端时最核心的链路定义清楚。

---

## 1. 总体设计

云端保存三类数据：

1. 用例元数据
2. 评测任务状态
3. 最终汇总结果

本机执行器负责：

1. 拉取任务
2. 执行 Agent
3. 推送进度
4. 推送结果

前端页面负责：

1. 创建任务
2. 查询任务状态
3. 查询最终报告

---

## 2. 最小接口数量

先定义 **6 个接口**，够跑通一条完整链路。

### 云端提供给前端 / 执行器

1. `GET /v1/cases`
2. `POST /v1/valuationTasks`
3. `GET /v1/valuationTasks/{task_id}`
4. `GET /v1/valuationTasks/{task_id}/report`

### 执行器推送给云端

5. `POST /v1/valuationTasks/{task_id}/progress`
6. `POST /v1/valuationTasks/{task_id}/report`

---

## 3. 接口和业务关系

## 3.1 `GET /v1/cases`

业务：
- 前端展示用例列表
- 执行器按 case_id 获取元数据

返回最小字段：
- `case_id`
- `title`
- `scenario`

示例：

```json
[
  {
    "case_id": "bug_fix_001",
    "title": "商品列表与详情编辑工程缺陷修复",
    "scenario": "Bug Fix"
  }
]
```

---

## 3.2 `POST /v1/valuationTasks`

业务：
- 前端创建一个评测任务

请求：

```json
{
  "mode": "agent_compare",
  "run_target": "both",
  "case_ids": ["bug_fix_001"],
  "agent_a": {
    "agent_id": "agent_default",
    "label": "基线Agent"
  },
  "agent_b": {
    "agent_id": "codex_local",
    "label": "评测Agent"
  }
}
```

返回：

```json
{
  "task_id": "task_20260401_001",
  "status": "queued"
}
```

---

## 3.3 `GET /v1/valuationTasks/{task_id}`

业务：
- 前端查询任务摘要
- 看任务当前是否排队、运行、完成

返回最小字段：
- `task_id`
- `status`
- `total_cases`
- `done_cases`
- `comparison_labels`

示例：

```json
{
  "task_id": "task_20260401_001",
  "status": "running",
  "total_cases": 1,
  "done_cases": 0,
  "comparison_labels": {
    "side_a": "基线Agent",
    "side_b": "评测Agent"
  }
}
```

---

## 3.4 `POST /v1/valuationTasks/{task_id}/progress`

业务：
- 本机执行器向云端推送进度
- 云端不会自己产生进度，必须靠执行器上报

这是最关键的端 -> 云接口。

请求示例：

```json
{
  "status": "running",
  "total_cases": 1,
  "done_cases": 0,
  "case_progresses": [
    {
      "case_id": "bug_fix_001",
      "status": "running",
      "stages": [
        { "name": "A侧运行", "status": "done" },
        { "name": "A侧编译", "status": "done" },
        { "name": "B侧运行", "status": "running" }
      ]
    }
  ],
  "logs": [
    {
      "timestamp": "20:03:21",
      "level": "ERROR",
      "message": "[bug_fix_001][Codex Local] ohpm ERROR: Run install command failed"
    }
  ]
}
```

返回：

```json
{
  "accepted": true
}
```

说明：
- 执行器可以每隔几秒推送一次
- 也可以按事件推送
- 云端负责覆盖或合并最新进度

---

## 3.5 `POST /v1/valuationTasks/{task_id}/report`

业务：
- 本机执行器或评分Agent把最终结果推送到云端
- 云端持久化最终报告

请求示例：

```json
{
  "summary": {
    "total_cases": 1,
    "side_a_avg": 100,
    "side_b_avg": 80,
    "gain": -20
  },
  "cases": [
    {
      "case_id": "bug_fix_001",
      "side_a_total": 100,
      "side_b_total": 80,
      "gain": -20
    }
  ],
  "comparison_labels": {
    "side_a": "基线Agent",
    "side_b": "评测Agent"
  }
}
```

返回：

```json
{
  "accepted": true
}
```

---

## 3.6 `GET /v1/valuationTasks/{task_id}/report`

业务：
- 前端读取最终汇总报告
- 报告展示页使用

返回：

```json
{
  "task_id": "task_20260401_001",
  "summary": {
    "total_cases": 1,
    "side_a_avg": 100,
    "side_b_avg": 80,
    "gain": -20
  },
  "cases": [
    {
      "case_id": "bug_fix_001",
      "side_a_total": 100,
      "side_b_total": 80,
      "gain": -20
    }
  ],
  "comparison_labels": {
    "side_a": "基线Agent",
    "side_b": "评测Agent"
  }
}
```

---

## 4. 一条完整链路

### 第一步：前端创建任务

前端调用：
- `POST /v1/valuationTasks`

云端返回：
- `task_id`

### 第二步：执行器执行任务

执行器拿到任务后开始运行本地 Agent。

执行过程中，执行器不断调用：
- `POST /v1/valuationTasks/{task_id}/progress`

把：
- 用例阶段状态
- 日志
- done_cases
推到云端。

### 第三步：前端查询进度

前端轮询：
- `GET /v1/valuationTasks/{task_id}`

读取：
- 任务状态
- 已完成数量

如果需要更细粒度日志，后续可以再加：
- `GET /v1/valuationTasks/{task_id}/progress`

但第一版可以先不加，避免接口过多。

### 第四步：执行器或评分Agent推送最终结果

任务完成后，执行器或评分Agent调用：
- `POST /v1/valuationTasks/{task_id}/report`

### 第五步：前端读取报告

前端调用：
- `GET /v1/valuationTasks/{task_id}/report`

展示最终结果。

---

## 5. 当前实现映射

和你现在本机版的关系：

- `GET /v1/cases`
  - 对应当前本机 `cases.py`

- `POST /v1/valuationTasks`
  - 对应当前本机 `evaluation/start`

- `POST /v1/valuationTasks/{task_id}/progress`
  - 对应当前本机执行过程里的 `status + logs + case_progresses`
  - 只是现在本机版是内存更新，云端版改成上报

- `POST /v1/valuationTasks/{task_id}/report`
  - 对应当前本机 `report.json`
  - 云端版改成结果上报

- `GET /v1/valuationTasks/{task_id}/report`
  - 对应当前本机 `reports.py`

---

## 6. 第一版建议

第一版只实现这 6 个接口，不要继续扩：

1. `GET /v1/cases`
2. `POST /v1/valuationTasks`
3. `GET /v1/valuationTasks/{task_id}`
4. `POST /v1/valuationTasks/{task_id}/progress`
5. `POST /v1/valuationTasks/{task_id}/report`
6. `GET /v1/valuationTasks/{task_id}/report`

这样最小闭环已经够了：
- 前端能发任务
- 执行器能推送进度
- 云端能保存结果
- 前端能看报告
