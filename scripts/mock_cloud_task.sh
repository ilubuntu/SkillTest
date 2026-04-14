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
    category: 可靠性
    priority: P0
    check_method:
      type: custom_rule
      match_mode: all
      rules:
        - rule_id: HM-BUGFIX-001-01-R1
          target_file: entry/src/main/ets/pages/Index.ets
          match_type: regex_contains
          pattern: "router\\.getParams\\(\\)\\s+as\\s+DetailResultParams\\s*\\|\\s*undefined"
        - rule_id: HM-BUGFIX-001-01-R2
          target_file: entry/src/main/ets/pages/Index.ets
          match_type: regex_contains
          pattern: "findIndex\\(\\s*\\([^)]*\\)\\s*=>\\s*[^)]*\\.id\\s*===\\s*(?:targetId|returnedGoods\\.id)\\s*\\)"
        - rule_id: HM-BUGFIX-001-01-R3
          target_file: entry/src/main/ets/pages/Index.ets
          match_type: regex_contains
          pattern: "(?:dataSource\\.updateData\\(\\s*existingIndex\\s*,\\s*returnedGoods\\s*\\)|goodsList\\[\\s*existingIndex\\s*\\]\\s*=\\s*returnedGoods|goodsList\\.splice\\(\\s*existingIndex\\s*,\\s*1\\s*,\\s*returnedGoods\\s*\\))"
        - rule_id: HM-BUGFIX-001-01-R4
          target_file: entry/src/main/ets/pages/Index.ets
          match_type: regex_contains
          pattern: "(?:dataSource\\.addData\\(\\s*0\\s*,\\s*returnedGoods\\s*\\)|goodsList\\s*=\\s*\\[\\s*returnedGoods\\s*,\\s*\\.\\.\\.this\\.goodsList\\s*\\]|goodsList\\.unshift\\(\\s*returnedGoods\\s*\\))"
        - rule_id: HM-BUGFIX-001-01-R5
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "router\\.back\\(\\s*\\{\\s*url:\\s*['\"]pages/Index['\"]\\s*,\\s*params:\\s*[^}]+\\}\\s*\\)"
  - id: HM-BUGFIX-001-02
    name: 商品表单必须进行有效性校验
    description: 保存前必须校验商品名称非空且价格为大于0的有效数值，非法输入应阻断提交并给出明确提示。
    category: 组件规范
    priority: P2
    check_method:
      type: custom_rule
      match_mode: all
      rules:
        - rule_id: HM-BUGFIX-001-02-R1
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "(?:const|let)\\s+\\w+\\s*=\\s*this\\.editName\\.trim\\(\\)"
        - rule_id: HM-BUGFIX-001-02-R2
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "(?:const|let)\\s+\\w+\\s*=\\s*Number\\(\\s*this\\.editPrice\\s*\\)"
        - rule_id: HM-BUGFIX-001-02-R3
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "Number\\.isNaN\\(\\s*\\w+\\s*\\)"
        - rule_id: HM-BUGFIX-001-02-R4
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "\\w+\\s*<=\\s*0"
        - rule_id: HM-BUGFIX-001-02-R5
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: contains
          snippet: "promptAction.showToast("
  - id: HM-BUGFIX-001-03
    name: 异步保存失败必须恢复交互状态并提示
    description: 数据更新失败时必须结束保存态、恢复按钮可点击状态，并向用户展示失败原因，避免页面卡死或无反馈。
    category: 可靠性
    priority: P0
    check_method:
      type: custom_rule
      match_mode: all
      rules:
        - rule_id: HM-BUGFIX-001-03-R1
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "DB\\.(?:update|insert)\\(\\s*['\"]goods['\"]\\s*,\\s*savedGoods\\s*\\)"
        - rule_id: HM-BUGFIX-001-03-R2
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "(?:\\.catch\\s*\\(\\s*\\(\\s*\\w+(?::\\s*Error)?\\s*\\)\\s*=>|catch\\s*\\(\\s*\\w+(?::\\s*Error)?\\s*\\)\\s*\\{)"
        - rule_id: HM-BUGFIX-001-03-R3
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "this\\.isSaving\\s*=\\s*false"
        - rule_id: HM-BUGFIX-001-03-R4
          target_file: entry/src/main/ets/pages/DetailPage.ets
          match_type: regex_contains
          pattern: "(?:err|error)\\.message|String\\(\\s*(?:err|error)\\s*\\)"
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
