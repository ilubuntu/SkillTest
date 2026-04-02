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
- 在受限环境中，必须先把用户目录相关缓存重定向到当前工作区内的可写目录，再执行编译

## 核心原则

- 优先复用已有的 `DEVECO_SDK_HOME`、`HARMONYOS_SDK`、`JAVA_HOME` 等环境变量
- 如果运行器已经预置了 `AGENT_BENCH_NODE_BIN`、`AGENT_BENCH_HVIGOR_JS`、`AGENT_BENCH_SDK_ROOT`，直接复用这些值，不要再搜索 DevEco 安装目录
- 如果没有现成环境，再去定位 DevEco Studio 安装目录
- 所有编译缓存、用户目录缓存、临时目录都放到当前工程下的 `.agent_bench` 或 `.hvigor`
- 如果重定向 `HOME` / `USERPROFILE` 后 npm 或 corepack 丢失了原用户配置，必须显式恢复 `NPM_CONFIG_USERCONFIG`
- 如果日志里出现 `EPERM`、`EACCES`、`operation not permitted`，优先怀疑缓存目录写到了工作区之外
- 如果同一类 `SDK component missing`、`Configuration Error`、`build-profile.json5`、`hvigorfile.ts` 错误重复出现，不要继续反复改构建脚本；应尽快总结阻塞点

## Windows 推荐做法

在 Windows 下，先把编译环境固定到工作区，再调用 DevEco 内置工具链。

```powershell
$ProjectRoot = (Get-Location).Path
$BenchRoot = Join-Path $ProjectRoot ".agent_bench"
$HomeRoot = Join-Path $BenchRoot "hvigor-home"
$LocalAppDataRoot = Join-Path $HomeRoot "AppData\\Local"
$TempRoot = Join-Path $BenchRoot "tmp"

New-Item -ItemType Directory -Force -Path $BenchRoot, $HomeRoot, $LocalAppDataRoot, $TempRoot | Out-Null

$env:HOME = $HomeRoot
$env:USERPROFILE = $HomeRoot
$env:HOMEDRIVE = [System.IO.Path]::GetPathRoot($HomeRoot).TrimEnd('\')
$env:HOMEPATH = $HomeRoot.Substring($env:HOMEDRIVE.Length)
$env:LOCALAPPDATA = $LocalAppDataRoot
$env:TEMP = $TempRoot
$env:TMP = $TempRoot
$env:NPM_CONFIG_CACHE = Join-Path $LocalAppDataRoot "npm-cache"
$env:COREPACK_HOME = Join-Path $LocalAppDataRoot "corepack"
$env:NPM_CONFIG_OFFLINE = "false"
$env:NPM_CONFIG_PREFER_OFFLINE = "false"

New-Item -ItemType Directory -Force -Path $env:NPM_CONFIG_CACHE, $env:COREPACK_HOME | Out-Null

$OriginalUserProfile = if ($env:AGENT_BENCH_ORIGINAL_USERPROFILE) { $env:AGENT_BENCH_ORIGINAL_USERPROFILE } else { $null }
if ($OriginalUserProfile) {
  $UserNpmRc = Join-Path $OriginalUserProfile ".npmrc"
  if (Test-Path $UserNpmRc) {
    $env:NPM_CONFIG_USERCONFIG = $UserNpmRc
  }
}

Remove-Item Env:NODE_HOME -ErrorAction SilentlyContinue
Remove-Item Env:HVIGOR_APP_HOME -ErrorAction SilentlyContinue
```

如果机器上已经有可用环境变量，优先使用：

```powershell
$SdkHome = if ($env:DEVECO_SDK_HOME) { $env:DEVECO_SDK_HOME } elseif ($env:HARMONYOS_SDK) { $env:HARMONYOS_SDK } else { "D:\\deveco\\DevEco Studio\\sdk" }
$SdkHome = $SdkHome.TrimEnd('\')
$DevEcoRoot = if ($SdkHome -like '*\\sdk\\default') { Split-Path -Parent (Split-Path -Parent $SdkHome) } elseif ($SdkHome -like '*\\sdk') { Split-Path -Parent $SdkHome } else { Split-Path -Parent $SdkHome }
$NodeBin = Join-Path $DevEcoRoot "tools\\node\\node.exe"
$HvigorJs = Join-Path $DevEcoRoot "tools\\hvigor\\bin\\hvigorw.js"
$JavaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { Join-Path $DevEcoRoot "jbr" }

$env:DEVECO_SDK_HOME = $SdkHome
$env:JAVA_HOME = $JavaHome
$env:PATH = (Join-Path $JavaHome "bin") + ";" + (Split-Path -Parent $NodeBin) + ";" + $env:PATH
```

编译命令：

```powershell
& $NodeBin $HvigorJs `
  --mode module `
  -p product=default `
  assembleHap `
  --analyze=normal `
  --parallel `
  --incremental `
  --no-daemon
```

无论成功失败，最后都执行：

```powershell
& $NodeBin $HvigorJs --stop-daemon
```

## macOS 推荐做法

```bash
DEVECO_PATH="/Applications/DevEco-Studio.app"
DEVECO_CONTENTS="$DEVECO_PATH/Contents"
NODE_BIN="$DEVECO_CONTENTS/tools/node/bin/node"
HVIGOR_JS="$DEVECO_CONTENTS/tools/hvigor/bin/hvigorw.js"
SDK_HOME="$DEVECO_CONTENTS/sdk"
JAVA_HOME="$DEVECO_CONTENTS/jbr/Contents/Home"

PROJECT_ROOT="$(pwd)"
BENCH_ROOT="$PROJECT_ROOT/.agent_bench"
HOME_ROOT="$BENCH_ROOT/hvigor-home"
TMP_ROOT="$BENCH_ROOT/tmp"
mkdir -p "$HOME_ROOT" "$TMP_ROOT"

export HOME="$HOME_ROOT"
export TMPDIR="$TMP_ROOT"
export DEVECO_SDK_HOME="$SDK_HOME"
export JAVA_HOME="$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$(dirname "$NODE_BIN"):$PATH"
unset NODE_HOME
unset HVIGOR_APP_HOME
```

编译命令：

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

## 前置检查

- 当前目录必须包含 `build-profile.json5`
- `node`、`hvigorw.js`、`sdk`、`java` 必须来自 DevEco Studio
- 工作区内的缓存目录必须先创建好，再执行编译

## 成功判定

满足任一条件即可视为编译通过：
- 命令退出码为 `0`
- 工程下生成了 `*.hap`

常见产物位置：

```text
entry/build/default/outputs/default/entry-default-unsigned.hap
```

## 失败处理

如果编译失败：
- 保留完整 stdout/stderr
- 不要只总结一句“编译失败”
- 优先查看当前工作区下生成的日志，例如 `.hvigor/outputs/build-logs/build.log`、`.agent_bench/localappdata/npm-cache/_logs/...`
- 不要去 grep DevEco Studio 安装目录源码里的 `ERROR` 字符串；那些通常只是工具源码常量，不是当前工程的真实报错
- 优先根据日志修复以下问题：
  - `NODE_HOME is set to an invalid directory`
  - `Couldn't find hvigorw.js`
  - `ohpm ERROR: Run install command failed`
  - `SDK` 路径错误
  - `JAVA_HOME` 未设置
  - `EPERM: operation not permitted, mkdir ... .hvigor ...`
  - `npm install pnpm` 命中 `ENOTCACHED` 或 `only-if-cached`
- 如果连续两次仍是同一类环境/配置阻塞，不要继续大范围改工程结构，直接记录阻塞并结束本轮

如果看到类似下面的日志：

```text
EPERM: operation not permitted, mkdir 'C:\Users\<user>\.hvigor\...'
```

说明 hvigor 仍然在使用用户目录缓存。先把 `HOME`、`USERPROFILE`、`LOCALAPPDATA`、`TEMP`、`TMP` 都重定向到当前工作区，再重新编译。

如果看到类似下面的日志：

```text
request to https://registry.npmjs.org/pnpm failed: cache mode is 'only-if-cached' but no cached response is available.
```

说明 hvigor 在当前工作区下触发了 `npm install pnpm`，但重定向后的环境没有继承原用户 npm 配置，或者当前缓存里没有 pnpm。优先检查：
- `NPM_CONFIG_USERCONFIG` 是否指回原用户 `.npmrc`
- `NPM_CONFIG_CACHE` / `COREPACK_HOME` 是否落在当前工作区可写目录
- 代理和 registry 配置是否仍然可用

## 循环方式

每轮都按下面顺序执行：
1. 修改代码
2. 准备工作区内缓存目录并设置环境变量
3. 执行 hvigor 编译检查
4. 如果失败，读取完整日志
5. 基于日志继续修复
6. 再次编译，直到通过或达到最大轮次
