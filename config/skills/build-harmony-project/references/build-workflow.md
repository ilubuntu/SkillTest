# Build Workflow Reference

## Module Detection

Use this when the project is not a simple single-module layout.

1. Read `build-profile.json5`.
2. Inspect the `modules` array.
3. For each module with a `srcPath`, open `<srcPath>/src/main/module.json5`.
4. Use the `name` from `build-profile.json5` for `-p module=<name>@default`.
5. Use `module.type` to choose hvigor tasks.

Task mapping:

- `entry` or `feature`: `assembleHap`
- `har`: `assembleHar`
- `shared`: `assembleHsp`

For mixed projects, run all required tasks in one command, for example:

```bash
-p module=entry@default,commonlib@default,home@default assembleHap assembleHar
```

## Standard Build Command

### macOS

```bash
export DEVECO_SDK_HOME="$DEVECO_PATH/Contents/sdk"
export JAVA_HOME="$DEVECO_PATH/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
"$DEVECO_PATH/Contents/tools/node/bin/node" \
  "$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js" \
  --mode module \
  -p product=default \
  -p module=entry@default,commonlib@default \
  assembleHap assembleHar \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon
```

### Linux

```bash
export DEVECO_SDK_HOME="$DEVECO_PATH/sdk"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$DEVECO_PATH/tool/node/bin:$PATH"
"$DEVECO_PATH/tool/node/bin/node" \
  "$DEVECO_PATH/hvigor/bin/hvigorw.js" \
  --mode module \
  -p product=default \
  -p module=entry@default,commonlib@default \
  assembleHap assembleHar \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon
```

## Output Verification

Typical output paths:

- Unsigned: `<entry-module>/build/default/outputs/default/entry-default-unsigned.hap`
- Signed: `<entry-module>/build/default/outputs/default/entry-default-signed.hap`
- HAR: `<har-module>/build/default/outputs/default/*.har`
- HSP: `<shared-module>/build/default/outputs/default/*.hsp`

If the exact file name differs, inspect `<entry-module>/build/default/outputs/default/`.

## Daemon Shutdown

### macOS

```bash
"$DEVECO_PATH/Contents/tools/node/bin/node" \
  "$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js" \
  --stop-daemon
```

### Linux

```bash
"$DEVECO_PATH/tool/node/bin/node" \
  "$DEVECO_PATH/hvigor/bin/hvigorw.js" \
  --stop-daemon
```

## Device Checks

`hdc` is typically located at:

- macOS: `$DEVECO_PATH/Contents/sdk/default/openharmony/toolchains/hdc`
- Linux: `$DEVECO_PATH/sdk/default/openharmony/toolchains/hdc`

Useful checks:

```bash
"$HDC_PATH" list targets
```

Deploy only if:

- the user requested deployment,
- a device is connected,
- a signed HAP exists.

## Install And Launch

Install:

```bash
"$HDC_PATH" install -r "$HAP_FILE"
```

Launch requires bundle and ability names from project config. Read them from the module or app config instead of hardcoding.

Example form:

```bash
"$HDC_PATH" shell aa start -a "$ABILITY_NAME" -b "$BUNDLE_NAME"
```
