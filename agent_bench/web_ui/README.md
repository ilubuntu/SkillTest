# 鸿蒙开发工具评测系统 Web UI

## 快速启动

### 方式一：使用启动脚本（推荐）

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

服务启动后访问：**http://localhost:5177**

## 功能特性

- **可视化配置**：通过界面选择 Profile 和评测场景
- **实时进度**：SSE 流式展示评测进度和日志
- **结果展示**：自动计算并展示基线/增强得分对比
- **并行评测**：支持多场景并行执行

## 项目结构

```
web_ui/
├── start_web_ui.py      # 一键启动脚本（自动构建前端）
├── frontend/
│   ├── index.html       # 开发环境入口
│   └── dist/            # 构建后的静态资源
└── backend/
    ├── main.py          # FastAPI 主程序
    ├── models.py        # 数据模型
    ├── evaluator.py     # 评测任务管理器
    └── requirements.txt # Python 依赖
```

## API 接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/profiles` | GET | 获取 Profile 列表 |
| `/api/scenarios` | GET | 获取场景列表 |
| `/api/cascader-options` | GET | 获取级联选择器选项 |
| `/api/evaluation/start` | POST | 启动评测任务 |
| `/api/evaluation/stop` | POST | 停止评测任务 |
| `/api/evaluation/status` | GET | 获取评测状态 |
| `/api/evaluation/logs` | GET | SSE 实时日志流 |

## 常见问题

**Q: 前端页面空白**  
A: 确保 `frontend/dist` 目录存在，或运行 `npm install && npm run build` 重新构建

**Q: 端口被占用**  
A: 修改 `backend/main.py` 中的端口号（默认 5177）

**Q: 评测失败**  
A: 检查 OpenCode 服务是否启动，以及 Profile/场景配置是否正确
