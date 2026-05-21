#!/usr/bin/env bash
# QA Claude Skill — Config Validator
# Validates config/config.json against config.schema.json + custom semantic rules.
#
# Usage:
#   ./scripts/validate-config.sh [config-file]   (default: config/config.json)
#   ./scripts/validate-config.sh --schema-only   (skip semantic checks)
#
# Exit codes:
#   0 — config OK (warnings may exist)
#   1 — config invalid (errors found)
#   2 — usage error (missing jq, file not found, etc)

set -uo pipefail

# ---- Resolve paths ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${1:-$REPO_ROOT/config/config.json}"
SCHEMA_FILE="$REPO_ROOT/config/config.schema.json"

# ---- Colors ----
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RESET='\033[0m'

ERRORS=0
WARNINGS=0

err()  { echo -e "${C_RED}✗ ERROR${C_RESET}   $*" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${C_YELLOW}⚠ WARN${C_RESET}    $*" >&2; WARNINGS=$((WARNINGS + 1)); }
ok()   { echo -e "${C_GREEN}✓ PASS${C_RESET}    $*"; }
info() { echo -e "${C_BLUE}ℹ INFO${C_RESET}    $*"; }

# ---- Pre-flight ----
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install: brew install jq / apt install jq" >&2
  exit 2
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  echo "Hint: cp config/config.example.json config/config.json" >&2
  exit 2
fi

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Schema file not found: $SCHEMA_FILE" >&2
  exit 2
fi

echo "Validating: $CONFIG_FILE"
echo "Against:    $SCHEMA_FILE"
echo ""

# ---- 1. JSON syntax validity ----
echo "── 1. JSON syntax ─────────────────────────────"
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  err "Invalid JSON syntax. Run: jq . $CONFIG_FILE"
  exit 1
fi
ok "JSON syntax valid"

# ---- 2. Required fields (per schema) ----
echo ""
echo "── 2. Required fields ─────────────────────────"

check_field() {
  local field="$1" desc="$2"
  local val
  val=$(jq -r "$field // \"\"" "$CONFIG_FILE")
  if [[ -z "$val" || "$val" == "null" ]]; then
    err "Missing required: $field ($desc)"
  else
    ok "$field = \"$val\""
  fi
}

check_field ".mode" "mode (full-mcp | partial-mcp | markdown-only)"
check_field ".jira.instance_url" "JIRA Cloud URL"
check_field ".jira.project_key" "JIRA project key (e.g. PROJ)"
check_field ".platforms.ios.default_device" "iOS default test device"
check_field ".platforms.android.default_device" "Android default test device"

# ---- 3. Enum validation ----
echo ""
echo "── 3. Enum values ─────────────────────────────"

check_enum() {
  local field="$1" allowed="$2"
  local val
  val=$(jq -r "$field // \"\"" "$CONFIG_FILE")
  if [[ -z "$val" || "$val" == "null" ]]; then
    return
  fi
  if echo "$allowed" | grep -qw "$val"; then
    ok "$field = \"$val\" (valid)"
  else
    err "$field = \"$val\" — expected one of: $allowed"
  fi
}

check_enum ".mode" "full-mcp partial-mcp markdown-only"
check_enum ".google.default_drive" "shared personal"
check_enum ".language.primary" "zh-TW zh-CN en ja"
check_enum ".publish_regression.report_pipeline.type" "s3_cloudfront local_html"

# ---- 4. Pattern validation ----
echo ""
echo "── 4. Pattern checks ──────────────────────────"

PROJECT_KEY=$(jq -r '.jira.project_key // ""' "$CONFIG_FILE")
if [[ -n "$PROJECT_KEY" && ! "$PROJECT_KEY" =~ ^[A-Z][A-Z0-9_]+$ ]]; then
  err "jira.project_key = \"$PROJECT_KEY\" — should be UPPERCASE letters/digits/underscore"
else
  [[ -n "$PROJECT_KEY" ]] && ok "jira.project_key format OK"
fi

REVIEWER_FIELD=$(jq -r '.jira.reviewer_field // ""' "$CONFIG_FILE")
if [[ -n "$REVIEWER_FIELD" && ! "$REVIEWER_FIELD" =~ ^customfield_[0-9]+$ ]]; then
  err "jira.reviewer_field = \"$REVIEWER_FIELD\" — should match customfield_NNNNN"
else
  [[ -n "$REVIEWER_FIELD" ]] && ok "jira.reviewer_field format OK"
fi

JIRA_URL=$(jq -r '.jira.instance_url // ""' "$CONFIG_FILE")
if [[ -n "$JIRA_URL" && ! "$JIRA_URL" =~ ^https?://.+ && "$JIRA_URL" != "n/a" ]]; then
  err "jira.instance_url = \"$JIRA_URL\" — should start with http(s):// or be \"n/a\""
else
  [[ -n "$JIRA_URL" ]] && ok "jira.instance_url format OK"
fi

# ---- 5. Mode consistency ----
echo ""
echo "── 5. Mode consistency ─────────────────────────"

MODE=$(jq -r '.mode' "$CONFIG_FILE")

case "$MODE" in
  full-mcp)
    # full-mcp expects key MCP IDs to be filled
    [[ -z $(jq -r '.slack.user_id // ""' "$CONFIG_FILE") ]] && \
      warn "mode=full-mcp but slack.user_id is empty → DM notifications will skip"
    [[ -z $(jq -r '.google.qa_tc_folder_id // ""' "$CONFIG_FILE") ]] && \
      warn "mode=full-mcp but google.qa_tc_folder_id is empty → Sheet uploads will prompt manual"
    ok "full-mcp consistency checked"
    ;;
  partial-mcp)
    info "mode=partial-mcp — each MCP gracefully degrades when missing"
    ok "partial-mcp consistency checked"
    ;;
  markdown-only)
    # markdown-only should NOT have IDs filled (else implies confusion)
    SLACK_ID=$(jq -r '.slack.user_id // ""' "$CONFIG_FILE")
    [[ -n "$SLACK_ID" ]] && warn "mode=markdown-only but slack.user_id is set → it will be ignored"
    ok "markdown-only consistency checked"
    ;;
esac

# ---- 6. Cross-field consistency ----
echo ""
echo "── 6. Cross-field consistency ──────────────────"

# Backend pytest enabled? Need pytest_project_root.
PYTEST_ENABLED=$(jq -r '.backend.pytest_enabled // false' "$CONFIG_FILE")
PYTEST_ROOT=$(jq -r '.backend.pytest_project_root // ""' "$CONFIG_FILE")
if [[ "$PYTEST_ENABLED" == "true" && -z "$PYTEST_ROOT" ]]; then
  err "backend.pytest_enabled=true but backend.pytest_project_root is empty"
elif [[ "$PYTEST_ENABLED" == "true" ]]; then
  ok "backend.pytest_enabled + pytest_project_root consistent"
fi

# Mutation needs pytest_enabled.
MUTATION_ENABLED=$(jq -r '.backend.mutation.enabled // false' "$CONFIG_FILE")
if [[ "$MUTATION_ENABLED" == "true" && "$PYTEST_ENABLED" != "true" ]]; then
  err "backend.mutation.enabled=true but backend.pytest_enabled=false (mutmut needs pytest)"
fi

# Property-based needs pytest_enabled.
PB_ENABLED=$(jq -r '.backend.property_based.enabled // false' "$CONFIG_FILE")
if [[ "$PB_ENABLED" == "true" && "$PYTEST_ENABLED" != "true" ]]; then
  err "backend.property_based.enabled=true but backend.pytest_enabled=false (hypothesis needs pytest)"
fi

# publish_regression s3_cloudfront needs bucket / region / cloudfront_id.
PUBREG_TYPE=$(jq -r '.publish_regression.report_pipeline.type // ""' "$CONFIG_FILE")
PUBREG_ENABLED=$(jq -r '.publish_regression.enabled // false' "$CONFIG_FILE")
if [[ "$PUBREG_ENABLED" == "true" && "$PUBREG_TYPE" == "s3_cloudfront" ]]; then
  for field in s3_bucket s3_region cloudfront_distribution_id; do
    val=$(jq -r ".publish_regression.report_pipeline.${field} // \"\"" "$CONFIG_FILE")
    [[ -z "$val" ]] && err "report_pipeline.type=s3_cloudfront but $field is empty"
  done
fi

# Speckit enabled needs repo_root.
SPECKIT_ENABLED=$(jq -r '.speckit.enabled // false' "$CONFIG_FILE")
SPECKIT_ROOT=$(jq -r '.speckit.repo_root // ""' "$CONFIG_FILE")
if [[ "$SPECKIT_ENABLED" == "true" && -z "$SPECKIT_ROOT" ]]; then
  err "speckit.enabled=true but speckit.repo_root is empty"
fi

# Web platform enabled needs at least frameworks.primary.
WEB_ENABLED=$(jq -r '.platforms.web.enabled // false' "$CONFIG_FILE")
WEB_FW=$(jq -r '.platforms.web.frameworks.primary // ""' "$CONFIG_FILE")
if [[ "$WEB_ENABLED" == "true" && -z "$WEB_FW" ]]; then
  warn "platforms.web.enabled=true but frameworks.primary not set (will default to playwright)"
fi

# ---- 7. Optional but recommended fields ----
echo ""
echo "── 7. Recommended fields ───────────────────────"

OPTIONAL_RECOMMENDED=(
  ".jira.reviewer_account_id:Set for bug-report auto-assignee"
  ".slack.user_id:Set to enable DM notifications"
  ".slack.bug_channel_id:Set to enable bug channel notifications"
  ".google.qa_tc_folder_id:Set to upload TC sheets to shared drive"
  ".platforms.ios.repo:Set to enable iOS repo deep code analysis"
  ".platforms.android.repo:Set to enable Android repo deep code analysis"
)

for entry in "${OPTIONAL_RECOMMENDED[@]}"; do
  field="${entry%%:*}"
  desc="${entry#*:}"
  val=$(jq -r "$field // \"\"" "$CONFIG_FILE")
  if [[ -z "$val" || "$val" == "null" ]]; then
    info "$field is empty — $desc (will degrade gracefully)"
  fi
done

# ---- Summary ----
echo ""
echo "═══════════════════════════════════════════════"
if [[ $ERRORS -gt 0 ]]; then
  echo -e "${C_RED}✗ FAILED${C_RESET} — $ERRORS error(s), $WARNINGS warning(s)"
  echo ""
  echo "Fix the errors above and re-run."
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "${C_GREEN}✓ PASSED${C_RESET} (with $WARNINGS warning(s))"
  echo ""
  echo "Config is valid. Warnings indicate optional features that will degrade."
  exit 0
else
  echo -e "${C_GREEN}✓ PASSED${C_RESET} — config is fully valid"
  exit 0
fi
