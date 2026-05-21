#!/usr/bin/env bash
# QA Claude Skill — Installer
# Renders skills/* with config.json values and installs to ~/.claude/skills/

set -euo pipefail

# ---- Paths ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
CONFIG_FILE="$SCRIPT_DIR/config/config.json"
EXAMPLE_FILE="$SCRIPT_DIR/config/config.example.json"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.claude/skills.backup-$TIMESTAMP"

# ---- Colors ----
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RESET='\033[0m'

log()  { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[ERR ]${C_RESET} $*" >&2; }
ok()   { echo -e "${C_GREEN}[OK  ]${C_RESET} $*"; }

# ---- Pre-flight ----
if ! command -v jq >/dev/null 2>&1; then
  err "jq is required (brew install jq / apt install jq)"; exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  warn "config.json not found."
  read -r -p "Copy config.example.json → config.json now? [Y/n] " ans
  ans=${ans:-Y}
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    cp "$EXAMPLE_FILE" "$CONFIG_FILE"
    ok "Created $CONFIG_FILE"
    warn "Please edit it and re-run ./install.sh"
    exit 0
  else
    err "Aborted. Provide config/config.json first."; exit 1
  fi
fi

# ---- Validate config (delegated to scripts/validate-config.sh) ----
VALIDATOR="$SCRIPT_DIR/scripts/validate-config.sh"
if [[ -x "$VALIDATOR" ]]; then
  log "Validating config.json (delegating to scripts/validate-config.sh) ..."
  if ! "$VALIDATOR" "$CONFIG_FILE"; then
    err "Config validation failed. Fix the errors above and re-run."
    exit 1
  fi
  echo ""
else
  # Inline minimal check if scripts/validate-config.sh missing
  log "Validating config.json (inline minimal check) ..."
  REQUIRED_FIELDS=(
    ".jira.instance_url"
    ".jira.project_key"
    ".platforms.ios.default_device"
    ".platforms.android.default_device"
  )
  MISSING=0
  for f in "${REQUIRED_FIELDS[@]}"; do
    val=$(jq -r "$f // empty" "$CONFIG_FILE")
    if [[ -z "$val" ]]; then
      err "Missing required field: $f"
      MISSING=$((MISSING + 1))
    fi
  done
  [[ $MISSING -gt 0 ]] && { err "Fix config.json and re-run."; exit 1; }
  ok "config.json passes minimal check"
fi

# Warn about optional but commonly used fields
OPTIONAL_FIELDS=(
  ".jira.reviewer_account_id"
  ".slack.user_id"
  ".slack.bug_channel_id"
  ".google.qa_tc_folder_id"
)
EMPTY=()
for f in "${OPTIONAL_FIELDS[@]}"; do
  val=$(jq -r "$f // empty" "$CONFIG_FILE")
  [[ -z "$val" ]] && EMPTY+=("$f")
done
if (( ${#EMPTY[@]} > 0 )); then
  warn "These optional fields are empty — related skills will fall back to markdown-only behavior:"
  printf '       %s\n' "${EMPTY[@]}"
fi

# ---- Render variables ----
render_skill() {
  local src_dir="$1" dest_dir="$2"
  mkdir -p "$dest_dir"

  # Collect substitutions from config.json
  local subs
  subs=$(jq -r '
    [
      ["{{JIRA_PROJECT_KEY}}",            .jira.project_key],
      ["{{JIRA_INSTANCE_URL}}",           .jira.instance_url],
      ["{{JIRA_REVIEWER_ACCOUNT_ID}}",    (.jira.reviewer_account_id // "")],
      ["{{JIRA_REVIEWER_FIELD}}",         (.jira.reviewer_field // "customfield_10045")],
      ["{{JIRA_BUG_ISSUE_TYPE_ID}}",      (.jira.bug_issue_type_id // "10046")],
      ["{{SLACK_USER_ID}}",               (.slack.user_id // "")],
      ["{{SLACK_BUG_CHANNEL_ID}}",        (.slack.bug_channel_id // "")],
      ["{{SLACK_RELEASE_CHANNEL_ID}}",    (.slack.release_channel_id // "")],
      ["{{GSHEET_TC_TEMPLATE_ID}}",       (.google.tc_template_id // "")],
      ["{{GDRIVE_QA_FOLDER_ID}}",         (.google.qa_tc_folder_id // "")],
      ["{{GSHEET_RELEASE_SCHEDULE_ID}}",  (.google.release_schedule_id // "")],
      ["{{GSHEET_REGRESSION_TEMPLATE}}",  (.google.regression_template_id // "")],
      ["{{IOS_DEFAULT_DEVICE}}",          .platforms.ios.default_device],
      ["{{IOS_DEFAULT_VERSION}}",         .platforms.ios.default_os_version],
      ["{{MIN_IOS_VERSION}}",             (.platforms.ios.min_os_version // "")],
      ["{{IOS_REPO}}",                    (.platforms.ios.repo // "")],
      ["{{IOS_RELEASE_BRANCH_PATTERN}}",  (.platforms.ios.release_branch_pattern // "release/{version}")],
      ["{{IOS_VERSION_FILE_PATTERN}}",    (.platforms.ios.version_file // "**/*.xcconfig")],
      ["{{ANDROID_VERSION_FILE_PATTERN}}", (.platforms.android.version_file // "**/build.gradle")],
      ["{{ANDROID_DEFAULT_DEVICE}}",      .platforms.android.default_device],
      ["{{ANDROID_DEFAULT_VERSION}}",     .platforms.android.default_os_version],
      ["{{MIN_ANDROID_API}}",             (.platforms.android.min_api_level | tostring) // ""],
      ["{{ANDROID_REPO}}",                (.platforms.android.repo // "")],
      ["{{ANDROID_RELEASE_TAG_PATTERN}}", (.platforms.android.release_tag_pattern // "v{version}")],
      ["{{PYTEST_PROJECT_ROOT}}",         (.backend.pytest_project_root // "")],
      ["{{SPECKIT_REPO_ROOT}}",           (.speckit.repo_root // "")],
      ["{{PUBLISH_HTML_GENERATOR}}",      (.publish_regression.html_generator_script // "")],
      ["{{PUBLISH_INDEX_GENERATOR}}",     (.publish_regression.index_generator_script // "")],
      ["{{WEB_REPO}}",                    (.platforms.web.repo // "")],
      ["{{WEB_PRIMARY_FRAMEWORK}}",       (.platforms.web.frameworks.primary // "playwright")],
      ["{{WEB_DEFAULT_BROWSERS}}",        (.platforms.web.default_browsers // [] | join(", "))]
    ]
    | map(@tsv) | join("\n")
  ' "$CONFIG_FILE")

  # Walk source files
  while IFS= read -r src_file; do
    local rel="${src_file#$src_dir/}"
    local dest="$dest_dir/$rel"
    mkdir -p "$(dirname "$dest")"

    if [[ "$src_file" =~ \.(md|json|yaml|yml|txt)$ ]]; then
      # Render text
      local content
      content=$(cat "$src_file")
      while IFS=$'\t' read -r key val; do
        [[ -z "$key" ]] && continue
        content="${content//$key/$val}"
      done <<< "$subs"
      printf '%s' "$content" > "$dest"
    else
      cp "$src_file" "$dest"
    fi
  done < <(find "$src_dir" -type f)
}

# ---- Backup existing ----
mkdir -p "$CLAUDE_SKILLS_DIR"
SKILLS_TO_INSTALL=()
[[ -d "$SKILLS_SRC" ]] || { err "$SKILLS_SRC missing"; exit 1; }

while IFS= read -r -d '' d; do
  SKILLS_TO_INSTALL+=("$(basename "$d")")
done < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -print0)

if (( ${#SKILLS_TO_INSTALL[@]} == 0 )); then
  err "No skills found under $SKILLS_SRC"; exit 1
fi

log "Will install ${#SKILLS_TO_INSTALL[@]} skills: ${SKILLS_TO_INSTALL[*]}"

# Backup any conflicts
NEED_BACKUP=()
for s in "${SKILLS_TO_INSTALL[@]}"; do
  [[ -d "$CLAUDE_SKILLS_DIR/$s" ]] && NEED_BACKUP+=("$s")
done
if (( ${#NEED_BACKUP[@]} > 0 )); then
  log "Backing up existing skills to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  for s in "${NEED_BACKUP[@]}"; do
    mv "$CLAUDE_SKILLS_DIR/$s" "$BACKUP_DIR/$s"
  done
  ok "Backup complete"
fi

# ---- Install ----
for s in "${SKILLS_TO_INSTALL[@]}"; do
  log "Installing $s ..."
  render_skill "$SKILLS_SRC/$s" "$CLAUDE_SKILLS_DIR/$s"
done

ok "Installed ${#SKILLS_TO_INSTALL[@]} skills to $CLAUDE_SKILLS_DIR"
echo
echo "Next steps:"
echo "  1. Restart Claude Code (or run /reload-skills if available)"
echo "  2. Try a trigger phrase, e.g.: 'Generate test plan for feature X'"
echo "  3. To revert: ./uninstall.sh (restores from backup)"
