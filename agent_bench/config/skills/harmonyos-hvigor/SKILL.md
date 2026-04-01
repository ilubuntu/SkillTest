---
name: harmonyos-hvigor
description: 使用 DevEco Studio 内置工具链对 HarmonyOS 工程做 hvigor 编译检查。适用于修改代码后的可编译性自检，不用于修改签名配置或 build-profile.json5。
---

# HarmonyOS Hvigor 编译检查

这个 skill 只做一件事：
- 在当前 HarmonyOS 工程目录执行一次可靠的 hvigor 编译检查
- 如果失败，读取完整编译日志并据此继续修复

## 规则

- 不要修改签名配置
- 不要修改 `build-profile.json5`
- 不要依赖系统 `node`
- 必须使用 DevEco Studio 内置的 `node`、`hvigorw.js`、`sdk`、`java`

## 默认路径

```bash
DEVECO_PATH="/Applications/DevEco-Studio.app"
DEVECO_CONTENTS="$DEVECO_PATH/Contents"
NODE_BIN="$DEVECO_CONTENTS/tools/node/bin/node"
HVIGOR_JS="$DEVECO_CONTENTS/tools/hvigor/bin/hvigorw.js"
SDK_HOME="$DEVECO_CONTENTS/sdk"
JAVA_HOME="$DEVECO_CONTENTS/jbr/Contents/Home"
```

## 前置检查

```bash
if [ ! -f "build-profile.json5" ]; then
  echo "ERROR: 当前目录不是 HarmonyOS 工程根目录"
  exit 1
fi

if [ ! -x "$NODE_BIN" ]; then
  echo "ERROR: 未找到 DevEco 内置 node: $NODE_BIN"
  exit 1
fi

if [ ! -f "$HVIGOR_JS" ]; then
  echo "ERROR: 未找到 hvigorw.js: $HVIGOR_JS"
  exit 1
fi

if [ ! -d "$SDK_HOME/default" ]; then
  echo "ERROR: DevEco 内置 SDK 不完整: $SDK_HOME"
  exit 1
fi
```

## 必要环境变量

```bash
export DEVECO_SDK_HOME="$SDK_HOME"
export JAVA_HOME="$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$(dirname "$NODE_BIN"):$PATH"
unset NODE_HOME
unset HVIGOR_APP_HOME
```

说明：
- `NODE_HOME` 和 `HVIGOR_APP_HOME` 经常被错误配置，优先清掉
- 使用完整路径执行 `node hvigorw.js`，不要调用裸 `hvigorw`

## 编译命令

```bash
"$NODE_BIN" "$HVIGOR_JS" \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --no-daemon
```

## 编译后停止 daemon

无论成功失败，都执行：

```bash
"$NODE_BIN" "$HVIGOR_JS" --stop-daemon
```

## 成功判定

满足任一条件即可视为编译通过：
- 命令退出码为 `0`
- 工程下生成了 `*.hap`

常见产物位置：

```bash
entry/build/default/outputs/default/entry-default-unsigned.hap
```

## 失败处理

如果编译失败：
- 保留完整 stdout/stderr
- 不要只总结一句“编译失败”
- 优先根据日志修复以下问题：
  - `NODE_HOME is set to an invalid directory`
  - `Couldn't find hvigorw.js`
  - `ohpm ERROR: Run install command failed`
  - `SDK` 路径错误
  - `JAVA_HOME` 未设置

## 循环方式

每轮都按下面顺序执行：
1. 修改代码
2. 执行上面的 hvigor 编译检查
3. 如果失败，读取完整日志
4. 基于日志继续修复
5. 再次编译，直到通过或达到最大轮次
