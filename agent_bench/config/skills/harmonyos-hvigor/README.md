# Hvigor 构建工具 - 快速参考

HarmonyOS 官方构建系统命令速查表。

## 🚀 快速开始

### 最常用命令

```bash
# 查看版本
hvigorw -v

# 清理构建
hvigorw clean

# 构建 Debug 版本
hvigorw assembleHap

# 构建 Release 版本
hvigorw assembleHap -p buildMode=release

# 构建整个应用
hvigorw assembleApp
```

## 📋 命令分类

### 🔍 查询命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `hvigorw -h` | 帮助信息 | `hvigorw -h` |
| `hvigorw -v` | 版本信息 | `hvigorw -v` |
| `hvigorw tasks` | 所有任务 | `hvigorw tasks` |
| `hvigorw taskTree` | 任务依赖 | `hvigorw taskTree` |
| `hvigorw buildInfo` | 构建信息 | `hvigorw buildInfo` |

### 🔨 构建命令

| 命令 | 说明 | 常用场景 |
|------|------|----------|
| `clean` | 清理构建 | 构建前清理 |
| `assembleHap` | 构建 HAP | 开发调试 |
| `assembleApp` | 构建 APP | 发布打包 |
| `assembleHar` | 构建 HAR | 库开发 |
| `assembleHsp` | 构建 HSP | 共享包 |

### 🧪 测试命令

```bash
# 单元测试
hvigorw test

# 设备测试
hvigorw onDeviceTest -p module=entry

# 带覆盖率
hvigorw test -p coverage=true
```

### 📊 日志级别

| 参数 | 级别 | 使用场景 |
|------|------|----------|
| `-e` | ERROR | 生产环境 |
| `-w` | WARN | 开发环境 |
| `-i` | INFO | 调试 |
| `-d` | DEBUG | 详细调试 |

## 🎯 常用场景

### 场景 1: 日常开发

```bash
# 1. 清理并构建
hvigorw clean && hvigorw assembleHap

# 2. 增量构建（更快）
hvigorw assembleHap

# 3. 查看详细日志
hvigorw assembleHap -d
```

### 场景 2: 发布构建

```bash
# 1. 清理
hvigorw clean

# 2. 构建 Release 版本
hvigorw assembleApp -p buildMode=release

# 3. 查看构建信息
hvigorw buildInfo
```

### 场景 3: CI/CD 流水线

```bash
#!/bin/bash
# 推荐的 CI 构建脚本

# 禁用守护进程
hvigorw clean --no-daemon

# 运行测试
hvigorw test --no-daemon

# 构建 Release 版本
hvigorw assembleApp \
  --no-daemon \
  --no-parallel \
  -p buildMode=release \
  -e

# 停止守护进程
hvigorw --stop-daemon-all
```

### 场景 4: 性能分析

```bash
# 普通分析
hvigorw assembleHap --analyze=normal

# 详细分析
hvigorw assembleHap --analyze=advanced

# 生成 HTML 报告
hvigorw assembleHap \
  --analyze=advanced \
  --config properties.hvigor.analyzeHtml=true

# 查看报告
# 打开 .hvigor/report/*.html
```

### 场景 5: 内存优化

```bash
# 内存不足时使用
hvigorw assembleHap \
  --optimization-strategy=memory \
  --max-old-space-size=2048 \
  --no-parallel
```

### 场景 6: 指定模块构建

```bash
# 构建指定模块
hvigorw assembleHap -p module=entry@default

# 构建多个模块
hvigorw assembleHap -p module=entry,common

# 指定 product
hvigorw assembleHap -p product=default
```

## ⚙️ 构建参数

### 基本参数

```bash
# 构建模式
-p buildMode=debug      # Debug 模式
-p buildMode=release    # Release 模式

# 指定模块
-p module=entry@default
-p module=entry,common

# 指定 product
-p product=default

# 调试模式
-p debuggable=true
```

### 测试参数

```bash
# 覆盖率
-p coverage=true
-p ohos-test-coverage=true

# 指定测试用例
-p scope=MyTestSuite#testMethod

# ASan 检测
-p ohos-debug-asan=true
```

### 性能参数

```bash
# 并行构建
--parallel              # 启用（默认）
--no-parallel          # 禁用

# 增量构建
--incremental          # 启用（默认）
--no-incremental       # 禁用

# 优化策略
--optimization-strategy=performance  # 性能优先
--optimization-strategy=memory       # 内存优先（默认）
```

### Daemon 参数

```bash
# 守护进程
--daemon               # 启用（默认）
--no-daemon           # 禁用（CI 推荐）
--stop-daemon         # 停止
--stop-daemon-all     # 停止所有

# 内存配置
--max-old-space-size=4096      # 老生代内存（MB）
--max-semi-space-size=32       # 新生代内存（MB）
```

## 📁 构建产物

### 输出目录结构

```
entry/build/default/outputs/default/
├── entry-default-signed.hap       # 签名的 HAP
├── entry-default-unsigned.hap     # 未签名的 HAP
└── ...

entry/.test/default/outputs/
├── ohosTest/
│   ├── reports/                   # 测试报告
│   └── coverage_data/             # 覆盖率数据
└── test/
    ├── reports/                   # 单元测试报告
    └── coverage_data/             # 覆盖率数据
```

### 查看构建产物

```bash
# 查看构建信息
hvigorw buildInfo

# 查看任务
hvigorw tasks

# 查看任务依赖
hvigorw taskTree
```

## 🐛 故障排除

### 问题 1: 构建失败

```bash
# 1. 清理构建
hvigorw clean

# 2. 清理缓存
hvigorw prune

# 3. 重新构建
hvigorw assembleHap --no-incremental --stacktrace
```

### 问题 2: 内存不足

```bash
# 方案 1: 增加内存
hvigorw assembleHap --max-old-space-size=4096

# 方案 2: 使用内存优先策略
hvigorw assembleHap --optimization-strategy=memory

# 方案 3: 禁用并行
hvigorw assembleHap --no-parallel
```

### 问题 3: 增量构建不生效

```bash
# 清理缓存重新构建
hvigorw clean
hvigorw assembleHap --no-incremental
```

### 问题 4: CI 环境构建慢

```bash
# 优化配置
hvigorw assembleHap \
  --no-daemon \                        # 禁用守护进程
  --optimization-strategy=performance \ # 性能优先
  --max-old-space-space=8192 \         # 增加内存
  --parallel                            # 并行构建
```

## 📚 配置文件

### hvigor-config.json5

```json5
{
  "modelVersion": "5.0.0",
  "dependencies": {
    // Hvigor 插件依赖
  },
  "execution": {
    "daemon": true,
    "parallel": true,
    "incremental": true
  },
  "logging": {
    "level": "info"
  }
}
```

### build-profile.json5

```json5
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "signingConfig": "default"
      }
    ]
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry"
    }
  ]
}
```

## 💡 最佳实践

### 开发环境

```bash
# 使用默认配置
hvigorw assembleHap

# 需要调试时
hvigorw assembleHap -d --stacktrace
```

### CI/CD 环境

```bash
# 推荐配置
hvigorw assembleApp \
  --no-daemon \           # 禁用守护进程
  --no-parallel \         # 禁用并行
  -e \                    # 只显示错误
  --optimization-strategy=memory \
  -p buildMode=release
```

### 性能优化

```bash
# 首次构建
hvigorw clean
hvigorw assembleHap --analyze=advanced

# 增量构建
hvigorw assembleHap --incremental

# 性能优先
hvigorw assembleHap \
  --optimization-strategy=performance \
  --max-old-space-size=8192
```

## 🔗 相关链接

- [官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-commandline)
- [Hvigor 配置指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor)
- [构建系统概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-overview)

---

**版本**: 1.0.0 | **更新**: 2026-03-11 | **官方文档**: [华为开发者](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-commandline)
