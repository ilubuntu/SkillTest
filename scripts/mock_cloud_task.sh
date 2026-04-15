#!/bin/bash
set -euo pipefail

EXECUTION_ID="${EXECUTION_ID:-1001}"
AGENT_ID="${AGENT_ID:-}"
FILE_URL="${FILE_URL:-https://agc-storage-drcn.platform.dbankcloud.cn/v0/agent-bench-lpgvk/original_project.zip}"
INPUT_TEXT="${INPUT_TEXT:-这是一个商品管理工程，首页展示商品列表（Index.ets），点击添加进入修改添加商品页面（DetailPage.ets），当前添加商品后首页列表不更新,请修复，直接在当前工程中修改代码,并说明修改了哪些文件}"
BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
TOKEN="${TOKEN:-}"

if [ -z "${EXPECTED_OUTPUT+x}" ]; then
  EXPECTED_OUTPUT="$(cat <<'EOF'
constraints:
  - id: HM-BUGFIX-001-01
    name: 新增或编辑后必须同步刷新商品列表
    description: 保存成功后必须将商品变更结果回传首页，并按商品ID执行新增或更新，避免列表展示旧数据或出现重复数据。
    priority: P0
    type: semantic_rule
    rule: goods_list_refresh_after_save
    params:
      index_file: entry/src/main/ets/pages/Index.ets
      detail_file: entry/src/main/ets/pages/DetailPage.ets
  - id: HM-BUGFIX-001-02
    name: 商品表单必须进行有效性校验
    description: 保存前必须校验商品名称非空且价格为大于0的有效数值，非法输入应阻断提交并给出明确提示。
    priority: P2
    type: semantic_rule
    rule: goods_form_validation
    params:
      file: entry/src/main/ets/pages/DetailPage.ets
  - id: HM-BUGFIX-001-03
    name: 异步保存失败必须恢复交互状态并提示
    description: 数据更新失败时必须结束保存态、恢复按钮可点击状态，并向用户展示失败原因，避免页面卡死或无反馈。
    priority: P0
    type: semantic_rule
    rule: goods_save_error_recovery
    params:
      file: entry/src/main/ets/pages/DetailPage.ets
  - id: HM-BUGFIX-001-04
    name: 编辑态必须正确回填商品详情
    description: 进入详情编辑页时必须依据商品ID加载已有数据并回填表单，避免编辑页展示默认值或覆盖原始数据。
    priority: P0
    type: semantic_rule
    rule: goods_edit_data_prefill
    params:
      file: entry/src/main/ets/pages/DetailPage.ets
EOF
)"
fi

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
