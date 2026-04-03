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

## Workflow

### 1. Confirm this is a HarmonyOS project

Check for root files such as `build-profile.json5`, `hvigorfile.ts`, `oh-package.json5`, and module folders like `entry/src/main/module.json5`.

### 2. Resolve the DevEco Studio installation

- Default to `/Applications/DevEco-Studio.app`.
- If that path does not exist, search common install locations.
- If the path still cannot be found, ask the user for the DevEco Studio installation path.
- Ensure these paths exist before building:
  - `Contents/tools/node/bin/node`
  - `Contents/tools/hvigor/bin/hvigorw.js`
  - `Contents/sdk/default`
  - `Contents/jbr/Contents/Home`

### 3. Build with the bundled toolchain

Run the build from the project root with environment derived from DevEco Studio:

```bash
export DEVECO_SDK_HOME="$DEVECO_PATH/Contents/sdk"
export JAVA_HOME="$DEVECO_PATH/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
"$DEVECO_PATH/Contents/tools/node/bin/node" \
  "$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js" \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon
```

If the build command fails because sandbox access is blocked, rerun it with escalation and explain that DevEco Studio toolchain access is required.

### 4. Stop the daemon after the build

Stop the hvigor daemon after the build attempt to reduce cross-session conflicts:

```bash
"$DEVECO_PATH/Contents/tools/node/bin/node" \
  "$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js" \
  --stop-daemon
```

Run this even after a failed build when possible.

### 5. Verify build output

- Detect the entry module by reading `build-profile.json5` modules and checking each module's `src/main/module.json5` for `"type": "entry"`.
- If entry detection is inconclusive, fall back to `entry`.
- Check for generated HAP files under:
  - `<entry-module>/build/default/outputs/default/*.hap`
- Report the exact generated file path and whether it is signed or unsigned.

For detailed entry-module detection and result checks, read [references/build-workflow.md](./references/build-workflow.md).

## Device Deployment

Only continue to deployment when the user explicitly asks to install or run the app on a device.

Before deployment:

- Check whether `hdc` exists under `Contents/sdk/default/openharmony/toolchains/hdc`.
- Detect connected devices.
- Inspect whether signing config exists, but do not modify it.
- If there is no signed HAP, report that deployment cannot proceed yet.

When deployment is requested, use the detailed guidance in [references/build-workflow.md](./references/build-workflow.md).

## Response Expectations

- When you actually use this skill for a build attempt, include the literal marker `[[BUILD_HARMONY_PROJECT_CALLED]]` in your final response summary.
- State the DevEco Studio path being used.
- Summarize whether the build succeeded.
- Provide the generated HAP path if present.
- If the build failed, report the concrete failing step and the relevant error, then suggest the narrowest next action.
