# 鸿蒙开发工具评测系统 Web UI 使用指南

## 概述

Web UI 提供了一个可视化的界面来管理和运行 Skill 评测任务，支持选择 Profile 和场景、实时查看评测进度和日志、查看评测结果等功能。

## 启动服务

### 方式一：使用启动脚本

```bash
cd agent_bench/web_ui
python start_web_ui.py
```

### 方式二：直接启动后端

```bash
cd agent_bench/web_ui/backend
pip install -r requirements.txt
python main.py
```

服务启动后，访问地址：**http://localhost:5177**

## 界面功能

### 1. 评测配置

在界面顶部，可以配置评测任务：

- **Profile 选择**：级联选择器，先选择场景，再选择该场景下的 Profile
  - `baseline` - 裸 Agent，无任何增强配置
  - `bug_fix_enhanced` - Bug 修复增强配置
  - `project_gen` - 工程生成配置
  - `compilable` - 可编译配置
  - `performance` - 性能优化配置

- **场景选择**：支持多选，可选择以下场景
  - `project_gen` - 工程生成场景
  - `compilable` - 可编译场景
  - `performance` - 性能优化场景
  - `bug_fix` - Bug 修复场景

### 2. 评测控制

- **开始评测**：启动评测任务（评测进行中时按钮不可用）
- **停止评测**：中断正在运行的评测任务

### 3. 实时日志

评测过程中，日志区域实时显示：
- 评测进度信息
- 各用例执行状态
- 错误和警告信息

### 4. 评测结果

评测完成后，结果区域显示：

| 指标 | 描述 |
|------|------|
| 总用例数 | 本次评测的测试用例总数 |
| 基线均分 | 裸 Agent 的平均得分 |
| 增强均分 | 使用 Skill 增强后的平均得分 |
| 增益 | 增强与基线的得分差值 |
| 通过率 | 得分 >= 60 的用例比例 |

各用例详情以折叠卡片形式展示，包括：
- 基线得分 / 增强得分 / 增益
- 各评分维度的详细分数

## API 接口

Web UI 后端提供以下 REST API：

### 获取 Profile 列表

```
GET /api/profiles
```

返回所有可用的 Profile 配置。

### 获取场景列表

```
GET /api/scenarios
```

返回所有测试场景及其用例数量。

### 获取级联选择器选项

```
GET /api/cascader-options
```

返回场景→Profile 的级联结构，用于前端组件。

### 启动评测

```
POST /api/evaluation/start
Content-Type: application/json

{
  "profiles": ["baseline", "bug_fix_enhanced"],
  "scenarios": ["bug_fix", "performance"]
}
```

### 停止评测

```
POST /api/evaluation/stop
```

### 获取评测状态

```
GET /api/evaluation/status
```

返回当前评测进度、状态和日志。

### 获取实时日志流

```
GET /api/evaluation/logs
```

SSE 实时推送日志事件。

## 目录结构

```
agent_bench/
├── web_ui/
│   ├── start_web_ui.py      # 启动脚本
│   ├── frontend/
│   │   ├── index.html       # 开发环境入口
│   │   └── dist/            # 构建后的静态文件
│   └── backend/
│       ├── main.py          # FastAPI 主程序
│       ├── models.py        # 数据模型
│       ├── evaluator.py     # 评测任务管理器
│       └── requirements.txt # Python 依赖
├── profiles/                # Profile 配置文件
├── test_cases/             # 测试用例
└── cli.py                  # CLI 评测工具
```

## 常见问题

### 1. 评测失败，退出码 1

检查日志中的具体错误信息，常见原因：
- OpenCode 服务未启动或连接失败
- Profile 或场景配置不存在
- 测试用例文件缺失

### 2. 前端页面空白

确认 `frontend/dist` 目录存在且包含构建后的文件，或运行 `npm install && npm run build` 重新构建。

### 3. 端口被占用

Web UI 默认使用 5177 端口，可通过修改 `main.py` 中的 `uvicorn.run(app, host="0.0.0.0", port=5177)` 更换端口。
