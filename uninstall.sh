#!/usr/bin/env bash
# QA Claude Skill — Uninstaller
# Removes installed skills from ~/.claude/skills/ and optionally restores latest backup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'; C_RESET='\033[0m'
log()  { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[ERR ]${C_RESET} $*" >&2; }
ok()   { echo -e "${C_GREEN}[OK  ]${C_RESET} $*"; }

# List skills shipped with this repo
SKILLS=()
while IFS= read -r -d '' d; do
  SKILLS+=("$(basename "$d")")
done < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -print0)

log "Will remove from $CLAUDE_SKILLS_DIR: ${SKILLS[*]}"
read -r -p "Continue? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { warn "Aborted"; exit 0; }

REMOVED=0
for s in "${SKILLS[@]}"; do
  if [[ -d "$CLAUDE_SKILLS_DIR/$s" ]]; then
    rm -rf "$CLAUDE_SKILLS_DIR/$s"
    REMOVED=$((REMOVED + 1))
    ok "Removed $s"
  fi
done

# Offer restore from latest backup
LATEST_BACKUP=$(find "$HOME/.claude" -maxdepth 1 -type d -name 'skills.backup-*' 2>/dev/null | sort -r | head -n 1 || true)
if [[ -n "$LATEST_BACKUP" ]]; then
  echo
  log "Latest backup found: $LATEST_BACKUP"
  read -r -p "Restore skills from this backup? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    for s in "${SKILLS[@]}"; do
      if [[ -d "$LATEST_BACKUP/$s" ]]; then
        cp -R "$LATEST_BACKUP/$s" "$CLAUDE_SKILLS_DIR/$s"
        ok "Restored $s"
      fi
    done
  fi
fi

ok "Done. Removed $REMOVED skills."
