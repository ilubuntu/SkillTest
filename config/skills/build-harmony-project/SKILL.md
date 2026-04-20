---
name: build-harmony-project
description: Build HarmonyOS NEXT projects from the terminal by using the local DevEco Studio toolchain instead of DevEco Studio UI. Use when the user asks to compile, build, package, or verify a HarmonyOS project in VS Code or another CLI workflow, especially when the project contains `build-profile.json5`, `hvigorfile.ts`, or Harmony module structure. Do not modify signing files, signing keys, or `build-profile.json5` while using this skill.
---

# Build Harmony Project

## Overview

Use this skill to compile a HarmonyOS project from the CLI with the machine's installed DevEco Studio toolchain. Prefer it when working outside DevEco Studio and the task is to build or validate an existing HarmonyOS project without altering signing or build configuration.

## Rules

- Never modify signing configuration, signing key files, or `build-profile.json5`.
- Treat build failures as environment, SDK, signing, or source issues to diagnose, not as permission to rewrite protected configuration.
- Prefer read-only inspection of project config before building.
- If a required toolchain path is outside the sandbox, request escalation rather than working around it.
- When `AGENT_BENCH_*` environment variables exist, use them directly. Do not re-detect platform paths in that case.

## Workflow

### 1. Confirm this is a HarmonyOS project

Check for root files such as `build-profile.json5`, `hvigorfile.ts`, `oh-package.json5`, and module folders like `entry/src/main/module.json5`.

### 2. Resolve the toolchain

Use the following priority:

1. `AGENT_BENCH_*` environment variables injected by the executor
2. Local platform fallback detection only when `AGENT_BENCH_*` is absent

Required executor-injected variables:

- `AGENT_BENCH_NODE_BIN`
- `AGENT_BENCH_HVIGOR_JS`
- `AGENT_BENCH_HARMONYOS_SDK`
- `AGENT_BENCH_JAVA_HOME`

Only when the above variables are missing should you fall back to local platform detection:

**macOS:**
- Default to `/Applications/DevEco-Studio.app/Contents`.
- Ensure these paths exist before building:
  - `tools/node/bin/node`
  - `tools/hvigor/bin/hvigorw.js`
  - `sdk`
  - `jbr/Contents/Home`

**Linux (command-line-tools):**
- Default to `/home/work/hmsdk/command-line-tools`.
- Ensure these paths exist before building:
  - `tool/node/bin/node` or `tools/node/bin/node`
  - `hvigor/bin/hvigorw.js` or `tools/hvigor/bin/hvigorw.js`
  - `sdk`
  - system `JAVA_HOME`

**Windows:**
- Default to `C:\Program Files\Huawei\DevEco Studio`.
- Ensure these paths exist before building:
  - `tools\node\node.exe`
  - `tools\hvigor\bin\hvigorw.js`
  - `sdk`
  - `jbr`

### 3. Install dependencies first

Before the build command, first run one dependency installation round in the current project:

```bash
"/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm" install --all
```

When `AGENT_BENCH_*` is available, infer the sibling `ohpm` path from the injected DevEco toolchain root and run:

```bash
"$DETECTED_OHPM" install --all
```

Do not force `--registry` unless the environment already requires a specific mirror.

### 4. Build

When `AGENT_BENCH_*` is available, use this command directly:

```bash
export DEVECO_SDK_HOME="$AGENT_BENCH_HARMONYOS_SDK"
export HARMONYOS_SDK="$AGENT_BENCH_HARMONYOS_SDK"
export JAVA_HOME="$AGENT_BENCH_JAVA_HOME"
export PATH="$JAVA_HOME/bin:$(dirname "$AGENT_BENCH_NODE_BIN"):$PATH"
"$AGENT_BENCH_NODE_BIN" \
  "$AGENT_BENCH_HVIGOR_JS" \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon
```

If `AGENT_BENCH_*` is absent, resolve local platform paths first, then run the same command shape:

```bash
export DEVECO_SDK_HOME="$DETECTED_SDK"
export HARMONYOS_SDK="$DETECTED_SDK"
export JAVA_HOME="$DETECTED_JAVA_HOME"
export PATH="$JAVA_HOME/bin:$(dirname "$DETECTED_NODE"):$PATH"
"$DETECTED_NODE" \
  "$DETECTED_HVIGOR" \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon
```

If the build command fails because sandbox access is blocked, rerun it with escalation and explain that DevEco Studio toolchain access is required.

### 5. Stop the daemon after the build

When `AGENT_BENCH_*` is available, use:

```bash
"$AGENT_BENCH_NODE_BIN" \
  "$AGENT_BENCH_HVIGOR_JS" \
  --stop-daemon
```

Stop the hvigor daemon after the build attempt to reduce cross-session conflicts:

If `AGENT_BENCH_*` is absent, use the detected local paths:

```bash
"$DETECTED_NODE" \
  "$DETECTED_HVIGOR" \
  --stop-daemon
```

Run this even after a failed build when possible.

### 6. Verify build output

- Detect the entry module by reading `build-profile.json5` modules and checking each module's `src/main/module.json5` for `"type": "entry"`.
- If entry detection is inconclusive, fall back to `entry`.
- Check for generated HAP files under:
  - `<entry-module>/build/default/outputs/default/*.hap`
- Report the exact generated file path and whether it is signed or unsigned.

For detailed entry-module detection and result checks, read [references/build-workflow.md](./references/build-workflow.md).

## Device Deployment

Only continue to deployment when the user explicitly asks to install or run the app on a device.

Before deployment:
- Check whether `hdc` exists under `sdk/default/openharmony/toolchains/hdc` (relative to DEVECO_PATH on Linux, or `Contents/sdk/default/openharmony/toolchains/hdc` on macOS).
- Detect connected devices.
- Inspect whether signing config exists, but do not modify it.
- If there is no signed HAP, report that deployment cannot proceed yet.

When deployment is requested, use the detailed guidance in [references/build-workflow.md](./references/build-workflow.md).

## Response Expectations

- When you actually use this skill for a build attempt, include the literal marker `[[BUILD_HARMONY_PROJECT_CALLED]]` in your final response summary.
- State the exact toolchain paths being used:
  - `node`
  - `hvigor`
  - `harmonyos_sdk`
  - `java_home`
- Summarize whether the build succeeded.
- Provide the generated HAP path if present.
- If the build failed, report the concrete failing step and the relevant error, then suggest the narrowest next action.
