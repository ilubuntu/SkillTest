# Hvigor 故障排除指南

Hvigor 构建工具常见问题及解决方案。

## 🚨 常见错误

### 1. 找不到模块或依赖

**错误信息**:
```
Error: Cannot find module 'xxx'
Module not found: Error: Can't resolve 'xxx'
```

**解决方案**:
```bash
# 方案 1: 清理并重新初始化
hvigorw clean
hvigorw init

# 方案 2: 删除 node_modules 和 oh_modules 重新安装
rm -rf node_modules oh_modules
hvigorw init

# 方案 3: 检查 oh-package.json5 依赖配置
# 确保依赖版本正确
```

### 2. 内存不足

**错误信息**:
```
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed
JavaScript heap out of memory
```

**解决方案**:
```bash
# 方案 1: 增加内存限制
hvigorw assembleHap --max-old-space-size=4096

# 方案 2: 使用内存优先策略
hvigorw assembleHap --optimization-strategy=memory

# 方案 3: 禁用并行构建
hvigorw assembleHap --no-parallel

# 方案 4: 禁用守护进程（CI 环境）
hvigorw assembleHap --no-daemon --optimization-strategy=memory
```

### 3. 增量构建失败

**错误信息**:
```
Incremental build failed
Cache corrupted
```

**解决方案**:
```bash
# 方案 1: 清理缓存
hvigorw clean
hvigorw prune

# 方案 2: 禁用增量构建
hvigorw assembleHap --no-incremental

# 方案 3: 删除 .hvigor 缓存目录
rm -rf .hvigor
hvigorw assembleHap
```

### 4. 签名配置错误

**错误信息**:
```
SignTool error: invalid keystore
Sign failed: certificate expired
```

**解决方案**:
```bash
# 1. 检查签名配置
cat build-profile.json5 | grep -A 20 signingConfigs

# 2. 在 DevEco Studio 中重新生成签名
# File -> Project Structure -> Signing Configs

# 3. 临时禁用签名（仅调试）
# 在 build-profile.json5 中设置:
# "signingConfigs": []
```

### 5. 版本不兼容

**错误信息**:
```
Version mismatch
Plugin version incompatible
```

**解决方案**:
```bash
# 1. 检查 Hvigor 版本
hvigorw -v

# 2. 更新 Hvigor
npm update -g @ohos/hvigor

# 3. 检查插件版本兼容性
cat hvigor-config.json5 | grep dependencies

# 4. 同步依赖
hvigorw init
```

### 6. 测试失败

**错误信息**:
```
Test failed: No test cases found
Test execution failed
```

**解决方案**:
```bash
# 1. 检查测试文件路径
find entry/src -name "*.test.ets"

# 2. 清理测试缓存
rm -rf entry/.test

# 3. 重新运行测试
hvigorw test --no-incremental

# 4. 查看详细日志
hvigorw test -d --stacktrace
```

### 7. 构建超时

**错误信息**:
```
Build timeout
Task execution timeout
```

**解决方案**:
```bash
# 方案 1: 增加超时时间（在 hvigor-config.json5 中配置）
{
  "execution": {
    "timeout": 600000  // 10 分钟
  }
}

# 方案 2: 禁用守护进程
hvigorw assembleHap --no-daemon

# 方案 3: 分模块构建
hvigorw assembleHap -p module=entry
```

### 8. 权限问题

**错误信息**:
```
Permission denied
EACCES: permission denied
```

**解决方案**:
```bash
# 1. 修复文件权限
chmod -R 755 .

# 2. 修复 Hvigor 权限
chmod +x hvigorw

# 3. 检查 Node.js 权限
which node
ls -l $(which node)
```

## 📊 性能问题

### 构建速度慢

**诊断步骤**:
```bash
# 1. 启用构建分析
hvigorw assembleHap --analyze=advanced

# 2. 查看分析报告
open .hvigor/report/build-analysis.html

# 3. 查看任务依赖
hvigorw taskTree
```

**优化方案**:
```bash
# 1. 启用并行构建
hvigorw assembleHap --parallel

# 2. 启用增量构建
hvigorw assembleHap --incremental

# 3. 使用性能优先策略
hvigorw assembleHap --optimization-strategy=performance

# 4. 增加内存
hvigorw assembleHap \
  --optimization-strategy=performance \
  --max-old-space-size=8192
```

### 内存占用高

**优化方案**:
```bash
# 1. 使用内存优先策略
hvigorw assembleHap --optimization-strategy=memory

# 2. 限制内存使用
hvigorw assembleHap --max-old-space-size=2048

# 3. 禁用守护进程
hvigorw assembleHap --no-daemon

# 4. 定期清理缓存
hvigorw prune
```

## 🔍 调试技巧

### 1. 查看详细日志

```bash
# Debug 级别日志
hvigorw assembleHap -d --stacktrace

# 保存日志到文件
hvigorw assembleHap -d --stacktrace > build.log 2>&1

# 查看特定模块日志
hvigorw assembleHap -p module=entry -d
```

### 2. 查看配置信息

```bash
# 查看工程配置
hvigorw buildInfo

# 查看模块配置
hvigorw buildInfo -p module=entry

# JSON 格式输出
hvigorw buildInfo -p json

# 包含 buildOption
hvigorw buildInfo -p buildOption
```

### 3. 查看任务信息

```bash
# 所有任务
hvigorw tasks

# 任务依赖树
hvigorw taskTree

# 特定任务详情
hvigorw tasks --all
```

### 4. 检查环境

```bash
# 检查 Hvigor 版本
hvigorw -v

# 检查 Node.js 版本
node --version

# 检查 JDK 版本
java -version

# 检查环境变量
echo $HVIgor_HOME
echo $NODE_HOME
echo $JAVA_HOME
```

## 🛠️ 重置和清理

### 完全清理

```bash
#!/bin/bash
# complete_clean.sh

echo "清理构建产物..."
hvigorw clean

echo "清理缓存..."
hvigorw prune
rm -rf .hvigor

echo "清理依赖..."
rm -rf node_modules oh_modules

echo "清理测试结果..."
rm -rf entry/.test

echo "重新初始化..."
hvigorw init

echo "清理完成！"
```

### 重新构建

```bash
#!/bin/bash
# rebuild.sh

echo "完全清理..."
./complete_clean.sh

echo "重新构建..."
hvigorw assembleHap --no-incremental --stacktrace

echo "构建完成！"
```

## 📝 日志分析

### 常见日志模式

#### 1. 编译错误

```log
ERROR: Failed to compile: src/main/ets/pages/Index.ets(10,5)
```

**定位方法**:
```bash
# 查看源文件第 10 行
sed -n '10p' entry/src/main/ets/pages/Index.ets

# 查看上下文
sed -n '5,15p' entry/src/main/ets/pages/Index.ets
```

#### 2. 依赖错误

```log
ERROR: Cannot resolve dependency: @ohos/xxx@1.0.0
```

**解决方法**:
```bash
# 检查依赖配置
cat oh-package.json5 | grep @ohos/xxx

# 检查可用版本
npm view @ohos/xxx versions

# 更新依赖
# 在 oh-package.json5 中修改版本号
hvigorw init
```

#### 3. 资源错误

```log
ERROR: Resource not found: $media:icon
```

**解决方法**:
```bash
# 检查资源文件
find entry/src/main/resources -name "icon.*"

# 检查资源引用
grep -r "\$media:icon" entry/src/main/ets/
```

## 🔄 CI/CD 问题

### 1. CI 环境构建慢

**优化配置**:
```bash
# .gitlab-ci.yml 或 Jenkinsfile
variables:
  HVIgor_NO_DAEMON: "true"
  HVIgor_OPTS: "--optimization-strategy=performance --max-old-space-size=8192"

script:
  - hvigorw clean
  - hvigorw assembleApp --no-daemon --no-parallel -e
```

### 2. 缓存配置

**GitLab CI**:
```yaml
cache:
  paths:
    - .hvigor/
    - node_modules/
    - oh_modules/
```

**GitHub Actions**:
```yaml
- name: Cache Hvigor
  uses: actions/cache@v2
  with:
    path: |
      .hvigor
      node_modules
      oh_modules
    key: ${{ runner.os }}-hvigor-${{ hashFiles('**/oh-package.json5') }}
```

### 3. 并发构建

**避免冲突**:
```bash
# 使用不同的构建目录
hvigorw assembleHap -p buildDir=build-$(date +%s)

# 或使用锁文件
flock /tmp/hvigor.lock hvigorw assembleHap
```

## 📞 获取帮助

### 官方资源

1. **官方文档**:
   - [命令行工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-commandline)
   - [配置指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor)

2. **开发者社区**:
   - [HarmonyOS 论坛](https://developer.huawei.com/consumer/cn/forum/home)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/harmonyos)

3. **问题反馈**:
   - DevEco Studio: Help -> Submit Feedback
   - 官方 GitHub: 提交 Issue

### 收集诊断信息

```bash
#!/bin/bash
# collect_diagnostics.sh

echo "=== 系统信息 ===" > diagnostics.txt
uname -a >> diagnostics.txt

echo -e "\n=== Hvigor 版本 ===" >> diagnostics.txt
hvigorw -v >> diagnostics.txt 2>&1

echo -e "\n=== Node.js 版本 ===" >> diagnostics.txt
node --version >> diagnostics.txt 2>&1

echo -e "\n=== JDK 版本 ===" >> diagnostics.txt
java -version >> diagnostics.txt 2>&1

echo -e "\n=== 构建配置 ===" >> diagnostics.txt
hvigorw buildInfo >> diagnostics.txt 2>&1

echo -e "\n=== 最近错误日志 ===" >> diagnostics.txt
hvigorw assembleHap -d --stacktrace >> diagnostics.txt 2>&1

echo "诊断信息已保存到 diagnostics.txt"
```

## 🔧 环境配置

### 推荐配置

**开发环境** (hvigor-config.json5):
```json5
{
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

**CI/CD 环境** (hvigor-config.json5):
```json5
{
  "execution": {
    "daemon": false,
    "parallel": false,
    "incremental": true
  },
  "logging": {
    "level": "error"
  }
}
```

### 环境变量

```bash
# ~/.bashrc 或 ~/.zshrc

# Node.js
export NODE_HOME=/path/to/nodejs
export PATH=$NODE_HOME/bin:$PATH

# JDK
export JAVA_HOME=/path/to/jdk
export PATH=$JAVA_HOME/bin:$PATH

# Hvigor (可选)
export HVIgor_HOME=/path/to/hvigor
export PATH=$HVIgor_HOME/bin:$PATH

# CI 环境优化
export HVIgor_NO_DAEMON=true
```

---

**最后更新**: 2026-03-11 | **版本**: 1.0.0 | **维护**: HarmonyOS Development Team
