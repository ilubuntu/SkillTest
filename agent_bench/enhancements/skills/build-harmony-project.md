---
name: build-harmony-project
description: 在VSCode或其他非DevEco Studio环境中编译HarmonyOS Next应用。使用DevEco Studio内置的SDK和工具链进行编译，支持自定义DevEco Studio安装路径。自动检测设备连接和签名配置，编译成功后可选择推送到设备并运行。禁止修改签名配置和build-profile.json5文件。
---

## 触发条件
当用户需要在VSCode或其他非DevEco Studio环境中编译HarmonyOS Next应用时触发。

## 限制条件

**重要：以下文件禁止修改**

1. **签名配置文件**：不允许修改任何签名相关配置
2. **build-profile.json5**：不允许修改项目构建配置文件
3. **签名密钥文件**：不允许创建、修改或删除签名密钥文件

这些限制确保编译过程不会影响项目的原有配置和安全性。

## 执行步骤

### 步骤 1: 检查环境
```bash
# 默认DevEco Studio路径
DEVECO_PATH="/Applications/DevEco-Studio.app"

# 检查DevEco Studio是否安装
if [ ! -d "$DEVECO_PATH" ]; then
    echo "未找到DevEco Studio，请输入DevEco Studio安装路径："
    echo "示例：/Applications/DevEco-Studio.app"
    read -p "路径: " DEVECO_PATH

    # 验证用户输入的路径
    if [ ! -d "$DEVECO_PATH" ]; then
        echo "错误: 指定的路径不存在: $DEVECO_PATH"
        exit 1
    fi

    # 检查是否是有效的DevEco Studio路径
    if [ ! -d "$DEVECO_PATH/Contents/tools" ]; then
        echo "错误: 指定的路径不是有效的DevEco Studio安装目录"
        exit 1
    fi

    echo "已设置DevEco Studio路径: $DEVECO_PATH"
fi

# 检查是否在项目根目录
if [ ! -f "build-profile.json5" ]; then
    echo "错误: 当前目录不是HarmonyOS项目根目录"
    exit 1
fi

# 检查内置SDK是否存在
if [ ! -d "$DEVECO_PATH/Contents/sdk/default" ]; then
    echo "错误: DevEco Studio内置SDK不完整"
    exit 1
fi
```

### 步骤 2: 设置环境变量
```bash
# 设置SDK路径为DevEco Studio内置SDK
export DEVECO_SDK_HOME=$DEVECO_PATH/Contents/sdk

# 设置Java环境变量（打包HAP需要Java）
# 重要说明：
# 1. HAP打包工具 app_packing_tool.jar 需要 Java 运行时
# 2. hvigor 通过子 worker 进程调用 java -jar app_packing_tool.jar
# 3. 子进程会继承父进程的环境变量，因此必须在调用 hvigorw 之前设置
# 4. 如果不设置 JAVA_HOME，子进程将无法找到 java 命令，导致打包失败
export JAVA_HOME=$DEVECO_PATH/Contents/jbr/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
```

### 步骤 3: 执行编译
```bash
# 使用DevEco Studio内置的Node.js和hvigorw编译
$DEVECO_PATH/Contents/tools/node/bin/node \
  $DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon
```

### 步骤 4: 检查编译结果
```bash
# 正确获取 entry 模块路径的方法：
# 1. 遍历 build-profile.json5 中的 modules 数组
# 2. 找到有 targets 属性的模块（可构建模块）
# 3. 通过 srcPath 找到具体路径
# 4. 读取该路径下的 src/main/module.json5
# 5. 检查 type 是否为 "entry"

ENTRY_PATH=""

# 解析 build-profile.json5，找到所有有 targets 的模块
while IFS= read -r line; do
    # 提取 srcPath
    SRC_PATH=$(echo "$line" | grep -o '"srcPath"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$SRC_PATH" ]; then
        # 移除路径前的 ./
        SRC_PATH=${SRC_PATH#./}
        
        # 检查该模块的 module.json5 文件
        MODULE_JSON5="$SRC_PATH/src/main/module.json5"
        
        if [ -f "$MODULE_JSON5" ]; then
            # 检查 type 是否为 entry
            MODULE_TYPE=$(grep '"type"' "$MODULE_JSON5" | head -1 | cut -d'"' -f4)
            
            if [ "$MODULE_TYPE" = "entry" ]; then
                ENTRY_PATH="$SRC_PATH"
                echo "✅ 检测到 entry 模块路径: $ENTRY_PATH"
                break
            fi
        fi
    fi
done < <(grep -A 10 '"modules"' build-profile.json5 | grep -B 5 '"targets"')

# 如果没有找到，使用默认路径
if [ -z "$ENTRY_PATH" ]; then
    ENTRY_PATH="entry"
    echo "⚠️  未找到 entry 模块，使用默认路径: $ENTRY_PATH"
fi

# 检查HAP文件是否生成
if [ -f "$ENTRY_PATH/build/default/outputs/default/entry-default-unsigned.hap" ]; then
    echo "编译成功！"
    echo "HAP文件: $ENTRY_PATH/build/default/outputs/default/entry-default-unsigned.hap"
    ls -lh $ENTRY_PATH/build/default/outputs/default/*.hap
else
    echo "编译失败"
fi
# 注意：不管成功失败，都继续执行步骤4.5停止daemon
```

### 步骤 4.5: 停止 daemon 进程
```bash
# 停止hvigor daemon进程，避免与DevEco Studio的daemon进程冲突
# 重要说明：
# 1. DevEco Studio和命令行编译可能共享同一个daemon进程
# 2. 不停止daemon可能导致内存占用、文件锁冲突、缓存问题
# 3. 停止daemon可以释放资源，确保下次编译从干净状态开始
echo ">>> 停止 hvigor daemon 进程..."
$DEVECO_PATH/Contents/tools/node/bin/node \
  $DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js \
  --stop-daemon

if [ $? -eq 0 ]; then
    echo "✅ Daemon 已停止"
else
    echo "⚠️  警告: 停止 daemon 失败"
fi
```

### 步骤 5: 检查设备连接状态
```bash
# 检查hdc工具
HDC_PATH="$DEVECO_PATH/Contents/sdk/default/openharmony/toolchains/hdc"

if [ ! -f "$HDC_PATH" ]; then
    echo "警告: 未找到hdc工具，跳过设备检查"
    exit 0
fi

# 列出已连接的设备
DEVICE_LIST=$($HDC_PATH list targets 2>&1)

if [ -z "$DEVICE_LIST" ] || [[ "$DEVICE_LIST" == *"error"* ]]; then
    echo "未检测到已连接的设备"
    exit 0
fi

echo "检测到设备: $DEVICE_LIST"
```

### 步骤 6: 检查签名配置
```bash
# 检查build-profile.json5中的签名配置
if grep -q "signingConfigs" build-profile.json5; then
    echo "检测到签名配置"
    # 提取签名配置名称
    SIGNING_CONFIG=$(grep -A 2 "signingConfigs" build-profile.json5 | grep '"name"' | head -1 | cut -d'"' -f4)
    echo "签名配置名称: $SIGNING_CONFIG"
else
    echo "未检测到签名配置，将生成未签名的HAP包"
fi
```

### 步骤 7: 询问用户是否部署到设备
```bash
# 如果有设备连接且有签名配置，询问用户是否部署
if [ -n "$DEVICE_LIST" ] && [ -n "$SIGNING_CONFIG" ]; then
    echo "检测到设备已连接且项目已配置签名"
    echo "是否需要将签名后的HAP包推送到设备并运行？"
    # 等待用户确认
    # 如果用户确认，继续步骤8
fi
```

### 步骤 8: 安装HAP到设备
```bash
# 使用hdc安装HAP包
HAP_FILE="entry/build/default/outputs/default/entry-default-signed.hap"

if [ ! -f "$HAP_FILE" ]; then
    echo "错误: 未找到签名的HAP文件"
    exit 1
fi

echo "正在安装HAP到设备..."
$HDC_PATH install -r "$HAP_FILE"

if [ $? -eq 0 ]; then
    echo "HAP安装成功"
else
    echo "HAP安装失败"
    exit 1
fi
```

### 步骤 9: 启动应用
```bash
# 从build-profile.json5或module.json5中提取包名和Ability名称
# 默认使用EntryAbility
PACKAGE_NAME="com.example.myapplication"  # 需要从配置文件中读取
ABILITY_NAME="EntryAbility"

echo "正在启动应用..."
$HDC_PATH shell aa start -a $ABILITY_NAME -b $PACKAGE_NAME

if [ $? -eq 0 ]; then
    echo "应用启动成功"
else
    echo "应用启动失败"
    exit 1
fi
```

## 编译参数说明

| 参数 | 说明 |
|------|------|
| `--mode module` | 模块编译模式 |
| `-p product=default` | 指定产品配置为default |
| `assembleHap` | 编译任务：生成HAP包 |
| `--analyze=normal` | 正常分析级别 |
| `--parallel` | 并行编译 |
| `--incremental` | 增量编译 |
| `--daemon` | 使用daemon进程加速编译 |
| `--stop-daemon` | 编译完成后停止daemon进程，避免冲突 |

## 关键规则

| 规则 | 说明 |
|------|------|
| SDK路径 | 必须设置为DevEco Studio内置SDK路径：`$DEVECO_PATH/Contents/sdk` |
| Java路径 | 必须设置为DevEco Studio内置Java：`$DEVECO_PATH/Contents/jbr/Contents/Home` |
| Node.js路径 | 使用DevEco Studio内置的Node.js：`$DEVECO_PATH/Contents/tools/node/bin/node` |
| hvigorw路径 | 使用DevEco Studio内置的hvigorw：`$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js` |
| 项目目录 | 必须在包含`build-profile.json5`的项目根目录执行 |
| 签名配置 | 未配置签名时生成未签名的HAP包（`*-unsigned.hap`） |
| 路径输入 | 如果默认路径找不到DevEco Studio，提示用户输入自定义路径 |
| **禁止修改** | **不允许修改签名配置和build-profile.json5文件** |

## 常见错误处理

| 错误 | 解决 |
|------|------|
| `command not found: node` | 使用DevEco Studio内置的Node.js完整路径 |
| `Unable to locate a Java Runtime` | 设置JAVA_HOME环境变量：`export JAVA_HOME=$DEVECO_PATH/Contents/jbr/Contents/Home` |
| `Invalid value of 'DEVECO_SDK_HOME'` | 设置环境变量：`export DEVECO_SDK_HOME=$DEVECO_PATH/Contents/sdk` |
| `SDK component missing` | SDK路径错误，确保指向DevEco Studio内置SDK |
| `Configuration Error` | 检查`build-profile.json5`文件格式是否正确 |
| `Module not found` | 检查项目结构，确保entry模块存在 |
| `No signingConfigs profile is configured` | 警告：未配置签名，生成未签名的HAP包 |
| `指定的路径不存在` | 用户输入的DevEco Studio路径无效，请重新输入正确的路径 |
| `不是有效的DevEco Studio安装目录` | 输入的路径不是DevEco Studio安装目录，缺少Contents/tools目录 |
| `未找到hdc工具` | SDK不完整，缺少openharmony/toolchains/hdc |
| `未检测到已连接的设备` | 检查设备连接，确保USB调试已开启 |
| `install bundle failed` | 签名配置错误或设备未授权，检查签名文件和设备权限 |
| `start ability failed` | Ability名称或包名错误，检查module.json5配置 |
| `EPERM: operation not permitted, uv_cwd` | daemon进程缓存失效，已自动停止daemon，下次编译会正常 |
| `Error Code: 00308018` | daemon进程错误，已自动停止daemon，下次编译会正常 |

## 输出文件

编译成功后生成的文件：

```
<entry_path>/build/default/outputs/default/
├── entry-default-unsigned.hap    # 未签名的HAP包
├── entry-default-signed.hap      # 签名的HAP包（如果配置了签名）
└── (其他构建产物)
```

**注意**：`<entry_path>` 是从 `build-profile.json5` 中动态获取的 entry 模块路径，通过以下步骤确定：
1. 遍历 `modules` 数组，找到有 `targets` 属性的模块
2. 通过 `srcPath` 找到具体路径
3. 读取 `src/main/module.json5`，检查 `type` 是否为 `"entry"`

## 设备部署说明

当检测到设备连接且项目配置了签名时，会自动询问用户是否部署到设备：

1. **设备检查**：使用hdc工具检测已连接的设备
2. **签名检查**：检查build-profile.json5中的signingConfigs配置
3. **用户确认**：询问用户是否需要推送到设备并运行
4. **安装HAP**：使用`hdc install`命令安装签名的HAP包
5. **启动应用**：使用`hdc shell aa start`命令启动应用

## hdc工具路径

hdc工具位于DevEco Studio内置SDK中：
```
$DEVECO_PATH/Contents/sdk/default/openharmony/toolchains/hdc
```

## 常用hdc命令

| 命令 | 说明 |
|------|------|
| `hdc list targets` | 列出已连接的设备 |
| `hdc install -r <hap>` | 安装HAP包（-r表示覆盖安装） |
| `hdc shell aa start -a <ability> -b <package>` | 启动应用 |
| `hdc uninstall <package>` | 卸载应用 |
| `hdc shell ps -ef` | 查看设备进程 |

## 完整编译脚本示例

```bash
#!/bin/bash

# HarmonyOS Next 编译脚本

set -e  # 遇到错误立即退出

echo "=== 开始编译 HarmonyOS Next 项目 ==="

# 1. 检查环境
DEVECO_PATH="/Applications/DevEco-Studio.app"

if [ ! -d "$DEVECO_PATH" ]; then
    echo "未找到DevEco Studio，请输入DevEco Studio安装路径："
    echo "示例：/Applications/DevEco-Studio.app"
    read -p "路径: " DEVECO_PATH

    if [ ! -d "$DEVECO_PATH" ]; then
        echo "❌ 错误: 指定的路径不存在: $DEVECO_PATH"
        exit 1
    fi

    if [ ! -d "$DEVECO_PATH/Contents/tools" ]; then
        echo "❌ 错误: 指定的路径不是有效的DevEco Studio安装目录"
        exit 1
    fi

    echo "✅ 已设置DevEco Studio路径: $DEVECO_PATH"
fi

if [ ! -f "build-profile.json5" ]; then
    echo "❌ 错误: 当前目录不是HarmonyOS项目根目录"
    exit 1
fi

# 2. 设置环境变量
export DEVECO_SDK_HOME=$DEVECO_PATH/Contents/sdk
# 设置Java环境变量（子进程会继承，用于HAP打包工具）
export JAVA_HOME=$DEVECO_PATH/Contents/jbr/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 3. 执行编译
echo ">>> 开始编译..."
$DEVECO_PATH/Contents/tools/node/bin/node \
  $DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon

# 4. 检查结果
# 正确获取 entry 模块路径
ENTRY_PATH=""

while IFS= read -r line; do
    SRC_PATH=$(echo "$line" | grep -o '"srcPath"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$SRC_PATH" ]; then
        SRC_PATH=${SRC_PATH#./}
        MODULE_JSON5="$SRC_PATH/src/main/module.json5"
        
        if [ -f "$MODULE_JSON5" ]; then
            MODULE_TYPE=$(grep '"type"' "$MODULE_JSON5" | head -1 | cut -d'"' -f4)
            
            if [ "$MODULE_TYPE" = "entry" ]; then
                ENTRY_PATH="$SRC_PATH"
                echo "✅ 检测到 entry 模块路径: $ENTRY_PATH"
                break
            fi
        fi
    fi
done < <(grep -A 10 '"modules"' build-profile.json5 | grep -B 5 '"targets"')

if [ -z "$ENTRY_PATH" ]; then
    ENTRY_PATH="entry"
    echo "⚠️  未找到 entry 模块，使用默认路径: $ENTRY_PATH"
fi

if [ -f "$ENTRY_PATH/build/default/outputs/default/entry-default-unsigned.hap" ]; then
    echo "✅ 编译成功！"
    echo "HAP文件: $ENTRY_PATH/build/default/outputs/default/entry-default-unsigned.hap"
    ls -lh $ENTRY_PATH/build/default/outputs/default/*.hap
else
    echo "❌ 编译失败"
fi

# 4.5 停止 daemon 进程（不管编译成功失败，都执行）
echo ">>> 停止 hvigor daemon 进程..."
$DEVECO_PATH/Contents/tools/node/bin/node \
  $DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js \
  --stop-daemon

if [ $? -eq 0 ]; then
    echo "✅ Daemon 已停止"
else
    echo "⚠️  警告: 停止 daemon 失败"
fi
```

## 注意事项

1. **SDK路径**：DevEco Studio 6.0+版本将SDK内置在应用包内，路径为`$DEVECO_PATH/Contents/sdk`
2. **Java环境**：
   - 打包HAP需要Java运行时，使用DevEco Studio内置的JBR（JetBrains Runtime）
   - 路径为`$DEVECO_PATH/Contents/jbr/Contents/Home`
   - HAP打包工具 `app_packing_tool.jar` 通过 hvigor 的子 worker 进程调用
   - 子进程会继承父进程的环境变量，因此必须在调用 hvigorw 之前设置 JAVA_HOME
3. **环境变量**：必须设置`DEVECO_SDK_HOME`和`JAVA_HOME`环境变量，否则会报SDK组件缺失或Java找不到错误
4. **工具路径**：使用DevEco Studio内置的Node.js和hvigorw工具，确保版本兼容
5. **签名配置**：默认生成未签名的HAP包，如需签名请在`build-profile.json5`中配置`signingConfigs`（但本skill不允许修改）
6. **编译模式**：使用`--daemon`参数可以加速后续编译，使用`--incremental`支持增量编译
7. **daemon管理**：
   - 编译完成后必须停止daemon进程（使用`--stop-daemon`）
   - 避免与DevEco Studio的daemon进程冲突
   - 防止内存占用、文件锁冲突、缓存问题
   - 确保下次编译从干净状态开始
8. **项目目录**：必须在项目根目录（包含`build-profile.json5`的目录）执行编译命令
9. **自定义路径**：如果默认路径找不到DevEco Studio，脚本会提示用户输入自定义安装路径，并验证路径有效性
10. **文件保护**：编译过程中禁止修改签名配置和build-profile.json5文件，保持项目原有配置不变
11. **设备部署**：当检测到设备连接且项目配置了签名时，会自动询问是否部署到设备
12. **hdc工具**：设备部署需要hdc工具，位于`$DEVECO_PATH/Contents/sdk/default/openharmony/toolchains/hdc`
13. **应用启动**：需要正确的包名和Ability名称，默认使用EntryAbility，可从module.json5中读取