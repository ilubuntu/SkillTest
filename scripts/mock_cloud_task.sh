#!/bin/bash
set -euo pipefail

EXECUTION_ID="${EXECUTION_ID:-1001}"
AGENT_ID="${AGENT_ID:-}"
FILE_URL="${FILE_URL:-https://agc-storage-drcn.platform.dbankcloud.cn/v0/agent-bench-lpgvk/original_project.zip}"
INPUT_TEXT="${INPUT_TEXT:-这是一个商品管理工程，首页展示商品列表（Index.ets），点击添加进入修改添加商品页面（DetailPage.ets），当前添加商品后首页列表不更新,请修复，直接在当前工程中修改代码,并说明修改了哪些文件}"
BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
TOKEN="${TOKEN:-}"

EXPECTED_OUTPUT="${EXPECTED_OUTPUT:-}"

AUTH_ARGS=()
if [ -n "$TOKEN" ]; then
  AUTH_ARGS=(-H "Authorization: Bearer $TOKEN")
fi

PAYLOAD="$(EXECUTION_ID="$EXECUTION_ID" AGENT_ID="$AGENT_ID" INPUT_TEXT="$INPUT_TEXT" EXPECTED_OUTPUT="$EXPECTED_OUTPUT" FILE_URL="$FILE_URL" python3 - <<'PY'
import json
import os

payload = {
    "executionId": int(os.environ["EXECUTION_ID"]),
    "agentId": os.environ.get("AGENT_ID", ""),
    "testCase": {
        "input": os.environ["INPUT_TEXT"],
        "expectedOutput": os.environ["EXPECTED_OUTPUT"],
        "fileUrl": os.environ["FILE_URL"],
    },
}
print(json.dumps(payload, ensure_ascii=False))
PY
)"

CURL_ARGS=(
  -sS
  -X POST
  "$BASE_URL/api/cloud-api/baseline"
  -H "Content-Type: application/json"
  -d "$PAYLOAD"
)

if [ -n "$TOKEN" ]; then
  CURL_ARGS+=("${AUTH_ARGS[@]}")
fi

curl "${CURL_ARGS[@]}"

echo
