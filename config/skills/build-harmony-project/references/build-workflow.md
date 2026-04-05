# Build Workflow Reference

## Entry Module Detection

Use this when the project is not a simple single-module layout.

1. Read `build-profile.json5`.
2. Inspect the `modules` array.
3. For each module with a `srcPath` and `targets`, open `<srcPath>/src/main/module.json5`.
4. Prefer the module whose `type` is `entry`.
5. If none is detected, fall back to `entry`.

## Standard Build Command

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

## Output Verification

Typical output paths:

- Unsigned: `<entry-module>/build/default/outputs/default/entry-default-unsigned.hap`
- Signed: `<entry-module>/build/default/outputs/default/entry-default-signed.hap`

If the exact file name differs, inspect `<entry-module>/build/default/outputs/default/`.

## Daemon Shutdown

Run after build:

```bash
"$DEVECO_PATH/Contents/tools/node/bin/node" \
  "$DEVECO_PATH/Contents/tools/hvigor/bin/hvigorw.js" \
  --stop-daemon
```

## Device Checks

`hdc` is typically located at:

```bash
"$DEVECO_PATH/Contents/sdk/default/openharmony/toolchains/hdc"
```

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
