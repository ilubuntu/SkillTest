---
name: harmonyos-hvigor
description: Hvigor构建工具命令行使用指南。HarmonyOS官方构建系统，支持编译、测试、打包、依赖管理。当用户询问hvigorw命令、构建配置、CI/CD流水线、编译错误、打包发布、**编译检查**、**验证构建**、**检查应用是否能编译**、**ohpm install**时使用此skill。包含完整命令参考、性能优化、编译检查流程、常见问题解决方案。
---

# Hvigor 构建工具使用指南

Hvigor 是 HarmonyOS 官方构建系统，类似于 Android 的 Gradle 或前端的 Webpack。

## 概述

**hvigorw** 是 Hvigor 的 wrapper 包装工具，提供：

- 自动安装 Hvigor 构建工具
- 管理插件依赖
- 执行构建命令
- 增量编译支持
- 并行构建能力

## 基本使用

### 命令格式

```bash
hvigorw [taskNames] [options]
```

- `taskNames`: 任务名称（可同时执行多个）
- `options`: 可选参数

### 前置要求

执行命令前需要配置：
1. **JDK 环境**
2. **Node.js 环境**
3. **Hvigor 环境变量**

## 常用命令速查

### 📋 查询命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `hvigorw -h` | 打印帮助信息 | `hvigorw -h` |
| `hvigorw -v` | 查看版本信息 | `hvigorw --version` |
| `hvigorw tasks` | 列出所有任务 | `hvigorw tasks` |
| `hvigorw taskTree` | 查看任务依赖关系 | `hvigorw taskTree` |
| `hvigorw buildInfo` | 打印配置信息 | `hvigorw buildInfo` |

**支持任意路径执行的命令**（从 5.18.4 版本开始）：
```bash
hvigorw -v
hvigorw --version
hvigorw version
hvigorw -h
hvigorw --help
```

### 🔨 编译构建

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `hvigorw clean` | 清理构建产物 | 清空 build 目录 |
| `hvigorw assembleHap` | 构建 HAP 包 | 编译应用模块 |
| `hvigorw assembleApp` | 构建 APP 包 | 打包发布版本 |
| `hvigorw assembleHsp` | 构建 HSP 包 | 编译共享包 |
| `hvigorw assembleHar` | 构建 HAR 包 | 编译库文件 |

**基本构建示例**:
```bash
# 构建 Debug 版本
hvigorw assembleHap

# 构建 Release 版本
hvigorw assembleHap -p buildMode=release

# 构建整个应用
hvigorw assembleApp
```

### 🎯 构建参数

#### 构建模式

```bash
# Debug 模式（默认）
hvigorw assembleHap -p buildMode=debug

# Release 模式
hvigorw assembleHap -p buildMode=release
```

#### 指定模块

```bash
# 构建指定模块
hvigorw assembleHap -p module=entry@default

# 构建多个模块
hvigorw assembleHap -p module=entry,common

# 指定 product
hvigorw assembleHap -p product=default
```

### ⚙️ Daemon（守护进程）

| 命令 | 说明 |
|------|------|
| `hvigorw --daemon` | 启用守护进程 |
| `hvigorw --no-daemon` | 禁用守护进程（推荐） |
| `hvigorw --stop-daemon` | 停止当前工程守护进程 |
| `hvigorw --stop-daemon-all` | 停止所有守护进程 |
| `hvigorw --status-daemon` | 查询守护进程状态 |

## 实用场景

### 场景 1: 开发调试

```bash
# 1. 清理旧构建
hvigorw clean

# 2. 构建 Debug 版本
hvigorw assembleHap -p buildMode=debug

# 3. 查看详细日志
hvigorw assembleHap -p buildMode=debug -d --stacktrace
```

### 场景 2: 发布构建

```bash
# 1. 清理构建
hvigorw clean

# 2. 构建 Release 版本
hvigorw assembleApp -p buildMode=release

# 3. 分析构建性能
hvigorw assembleApp -p buildMode=release --analyze=advanced
```

### 场景 3: 多模块构建

```bash
# 构建指定模块
hvigorw assembleHap -p module=entry@default

# 构建多个模块
hvigorw assembleHap -p module=entry,common,feature1

# 指定 product
hvigorw assembleHap -p product=default
```

### 场景 4: 编译检查（推荐）

**完整的应用编译检查流程**，确保应用能够成功编译：

#### 步骤 1: 安装依赖

```bash
# 安装项目依赖
ohpm install
```

**说明**:
- 安装 `oh-package.json5` 中声明的所有依赖
- 生成 `oh_modules/` 目录
- 必须在项目根目录执行

#### 步骤 2: 执行完整构建

```bash
# 完整的项目构建命令
hvigorw --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

**参数说明**:
- `--mode project`: 项目级构建模式
- `-p product=default`: 使用 default product 配置
- `assembleApp`: 构建整个应用（包括所有模块）
- `--analyze=normal`: 启用普通构建分析
- `--parallel`: 并行构建（加速）
- `--incremental`: 增量构建（加速）
- `--daemon`: 启用守护进程（加速后续构建）

#### 步骤 3: 验证编译结果

**编译成功的标志**:
- 命令执行完成，退出码为 0
- 无错误信息输出
- 生成构建产物（在 `build/` 目录）

**检查构建产物**:
```bash
# 查看构建产物
ls -lh build/default/outputs/default/

# 预期输出包括:
# - entry-default-signed.hap (签名的 HAP)
# - entry-default-unsigned.hap (未签名的 HAP)
```

#### 常见编译错误处理

**错误 1: 依赖安装失败**
```bash
# 清理并重新安装
ohpm clean
ohpm install
```

**错误 2: 构建缓存问题**
```bash
# 清理构建缓存
hvigorw clean
# 重新构建
hvigorw --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

**错误 3: 模块依赖问题**
```bash
# 检查 oh-package.json5 中的依赖配置
cat oh-package.json5

# 确保所有模块都正确声明
```

#### 快速检查命令

```bash
# 一键编译检查（推荐用于快速验证）
ohpm install && hvigorw --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon && echo "编译检查通过"
```

## 命令行参数完整列表

### 构建参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-p buildMode={debug\|release}` | 构建模式 | debug (HAP), release (APP) |
| `-p debuggable={true\|false}` | 调试模式 | - |
| `-p product={ProductName}` | 指定 product | default |
| `-p module={ModuleName}@{TargetName}` | 指定模块 | - |
| `-p ohos-test-coverage={true\|false}` | 测试覆盖率 | false |
| `-p coverage={true\|false}` | 覆盖率插桩 | false |
| `-p parameterFile=param.json` | 参数配置文件 | - |

### 日志参数

| 参数 | 说明 |
|------|------|
| `-e, --error` | 错误级别 |
| `-w, --warn` | 警告级别 |
| `-i, --info` | 信息级别 |
| `-d, --debug` | 调试级别 |
| `--stacktrace` | 打印堆栈 |
| `--no-stacktrace` | 不打印堆栈 |

### 性能参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--parallel` | 并行构建 | 启用 |
| `--no-parallel` | 禁用并行 | - |
| `--incremental` | 增量构建 | 启用 |
| `--no-incremental` | 禁用增量 | - |
| `--optimization-strategy=performance` | 性能优先 | - |
| `--optimization-strategy=memory` | 内存优先 | 启用 |

### Daemon 参数

| 参数 | 说明 |
|------|------|
| `--daemon` | 启用守护进程 |
| `--no-daemon` | 禁用守护进程 |
| `--stop-daemon` | 停止守护进程 |
| `--stop-daemon-all` | 停止所有守护进程 |
| `--status-daemon` | 查询守护进程状态 |
| `--max-old-space-size=<MB>` | 老生代内存大小 |
| `--max-semi-space-size=<MB>` | 新生代半空间大小 |

### 其他参数

| 参数 | 说明 |
|------|------|
| `-s, --sync` | 同步工程信息 |
| `-m, --mode` | 执行模式 |
| `--type-check` | 启用类型检查 |
| `--no-type-check` | 禁用类型检查 |
| `--config properties.key=value` | 自定义配置 |
| `-c properties.key=value` | 配置简写 |
| `--watch` | 观察模式 |
| `--node-home <path>` | Node.js 路径 |
