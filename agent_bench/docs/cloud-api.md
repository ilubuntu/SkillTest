# Cloud API

本文档定义端云协同模式下的云测接口。

系统边界如下：

- 云端负责 case 管理、任务存储、进度存储和报告展示
- 端侧负责下载 case、执行被测 agent、上报进度和结果
- 云端不直接运行被测 agent，也不向端侧主动下发任务

接口统一使用以下命名：

- `agent_baseline`
- `agent_candidate`
- `baseline`
- `candidate`

---

## 1. 云端做什么

云端负责 4 件事：

1. case 管理
2. valuation task 管理
3. progress 和日志存储
4. report 和汇总结果展示

---

## 2. 端侧做什么

端侧负责 5 件事：

1. 查询 case
2. 下载 case bundle
3. 创建 valuation task
4. 本地执行 agent
5. 上报 progress 和 report

---

## 3. 业务流

1. 端侧调用 `case_list`
2. 端侧调用 `case_detail`
3. 端侧调用 `case_bundle_get` 下载资源包
4. 端侧调用 `valuation_task_create`
5. 端侧本地执行
6. 执行过程中持续调用 `valuation_task_progress_update`
7. 执行完成后调用 `valuation_task_metrics_upload`
8. 评分 agent 基于 metrics 完成评分
9. 评分完成后调用 `valuation_task_report_upload`
10. 前端页面调用 `valuation_task_detail` 查看任务详情和报告摘要

---

## 4. 接口清单

### 4.1 `case_create`

建议路径：

- `POST /v1/case/create`

作用：

- 云端创建一个 case
- 后续可扩展为导入入口

最小请求字段：

```json
{
  "case_id": "bug_fix_001",
  "title": "商品列表与详情编辑工程缺陷修复",
  "scenario": "bug_fix",
  "summary": "这是一个已有的 HarmonyOS ArkTS 工程修复 case。",
  "bundle_version": "v1"
}
```

最小返回字段：

```json
{
  "case_id": "bug_fix_001",
  "created": true
}
```

---

### 4.2 `case_list`

建议路径：

- `GET /v1/case/list`

作用：

- 查询 case 列表
- 给前端页面和端侧选择器使用

最小返回字段：

```json
[
  {
    "case_id": "bug_fix_001",
    "title": "商品列表与详情编辑工程缺陷修复",
    "scenario": "bug_fix",
    "bundle_version": "v1"
  }
]
```

---

### 4.3 `case_detail`

建议路径：

- `GET /v1/case/detail?case_id=bug_fix_001`

作用：

- 查询单个 case 详情

最小返回字段：

```json
{
  "case_id": "bug_fix_001",
  "title": "商品列表与详情编辑工程缺陷修复",
  "scenario": "bug_fix",
  "summary": "这是一个已有的 HarmonyOS ArkTS 工程修复 case。",
  "bundle_version": "v1",
  "bundle_checksum": "sha256:xxxx",
  "case_spec": {
    "project": {
      "type": "HarmonyOS ArkTS"
    },
    "problem": {
      "summary": "当前工程存在功能缺陷、错误用法以及可编译性问题。"
    }
  }
}
```

---

### 4.4 `case_bundle_get`

建议路径：

- `GET /v1/case/bundle/get?case_id=bug_fix_001`

作用：

- 获取 case 资源包
- 端侧下载后解压执行

bundle 最少包含：

- `case.yaml`
- `original_project/`
- 相关附件
- `bundle_version`

最小返回字段：

```json
{
  "case_id": "bug_fix_001",
  "bundle_version": "v1",
  "download_url": "https://example.com/cases/bug_fix_001/v1.zip",
  "checksum": "sha256:xxxx"
}
```

---

### 4.5 `valuation_task_create`

建议路径：

- `POST /v1/valuationTask/create`

作用：

- 端侧创建一个评测任务
- 云端返回 `task_id`
- 创建成功后，端侧本地立即执行

最小请求字段：

```json
{
  "mode": "agent_compare",
  "run_target": "both",
  "case_ids": ["bug_fix_001"],
  "case_bundle_versions": {
    "bug_fix_001": "v1"
  },
  "agent_baseline": {
    "agent_id": "agent_default",
    "label": "基线Agent"
  },
  "agent_candidate": {
    "agent_id": "codex_local",
    "label": "评测Agent"
  },
  "client_info": {
    "client_id": "local-client-001",
    "platform": "macOS"
  }
}
```

最小返回字段：

```json
{
  "task_id": "task_20260401_001",
  "status": "created"
}
```

---

### 4.6 `valuation_task_detail`

建议路径：

- `GET /v1/valuationTask/detail?task_id=task_20260401_001`

作用：

- 页面查询任务详情
- 第一版可同时返回：
  - 任务摘要
  - 进度摘要
  - 报告摘要

最小返回字段：

```json
{
  "task_id": "task_20260401_001",
  "status": "running",
  "mode": "agent_compare",
  "run_target": "both",
  "case_ids": ["bug_fix_001"],
  "agent_baseline": {
    "agent_id": "agent_default",
    "label": "基线Agent"
  },
  "agent_candidate": {
    "agent_id": "codex_local",
    "label": "评测Agent"
  },
  "total_cases": 1,
  "done_cases": 0,
  "progress_summary": {
    "current_case_id": "bug_fix_001"
  },
  "report_summary": null
}
```

---

### 4.7 `valuation_task_progress_update`

建议路径：

- `POST /v1/valuationTask/progress/update`

作用：

- 端侧持续上报进度和日志

说明：

- 云端不会自己生成进度
- 进度完全依赖端侧上报

最小请求字段：

```json
{
  "task_id": "task_20260401_001",
  "status": "running",
  "total_cases": 1,
  "done_cases": 0,
  "case_progresses": [
    {
      "case_id": "bug_fix_001",
      "status": "running",
      "stages": [
        { "name": "基线Agent运行", "status": "done" },
        { "name": "基线Agent编译", "status": "done" },
        { "name": "评测Agent运行", "status": "running" }
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

最小返回字段：

```json
{
  "accepted": true
}
```

---

### 4.8 `valuation_task_metrics_upload`

建议路径：

- `POST /v1/valuationTask/metrics/upload`

作用：

- 端侧上传原始执行指标
- 这些指标作为评分 agent 的输入

说明：

- 这里上传的是原始事实数据，不是最终评分结论
- 后续评分规则变化时，可以基于这份数据重跑评分

最小请求字段：

```json
{
  "task_id": "task_20260401_001",
  "cases": [
    {
      "case_id": "bug_fix_001",
      "baseline": {
        "duration_ms": 398055,
        "compilable": true,
        "compile_fix_count": 2,
        "input_tokens": 12000,
        "output_tokens": 3000,
        "total_tokens": 15000,
        "cost": 0.52
      },
      "candidate": {
        "duration_ms": 512000,
        "compilable": false,
        "compile_fix_count": 4,
        "input_tokens": 18000,
        "output_tokens": 5000,
        "total_tokens": 23000,
        "cost": 0.88
      }
    }
  ]
}
```

最小返回字段：

```json
{
  "accepted": true
}
```

---

### 4.9 `valuation_task_report_upload`

建议路径：

- `POST /v1/valuationTask/report/upload`

作用：

- 端侧上传最终结果

说明：

- 这里上传的是最终结果，不是过程进度
- 这里上传的是评分 agent 处理后的最终结果

最小请求字段：

```json
{
  "task_id": "task_20260401_001",
  "summary": {
    "total_cases": 1,
    "baseline_avg": 100,
    "candidate_avg": 80,
    "gain": -20
  },
  "cases": [
    {
      "case_id": "bug_fix_001",
      "baseline_total": 100,
      "candidate_total": 80,
      "gain": -20,
      "score_reason": "基线Agent在可编译性和执行效率上优于评测Agent。"
    }
  ],
  "comparison_labels": {
    "baseline": "基线Agent",
    "candidate": "评测Agent"
  }
}
```

最小返回字段：

```json
{
  "accepted": true
}
```

---

## 5. 第一版先不做的事情

这版先明确不做：

- 云端向端侧主动推任务
- 长连接 / WebSocket
- 执行器认领任务
- 云端直接运行被测 agent
- 云端直接分步调度 agent 内部流程

这版只做：

- 云端存储
- 端侧执行
- 端侧主动上报
- 评分 agent 基于 metrics 打分
