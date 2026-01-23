#!/usr/bin/bash
# Creates .claude/settings.local.json and .claude/CLAUDE.md if they do not exist.
# Args: target directory, setting file flag, prompt file flag
# Ex. cld-ini.sh "`pwd`" "1Wb" "0"
# Ex. cld-ini.sh "`pwd`" "1WrWb" "0"
# Ex. cld-ini.sh "`pwd`" "1WrWb" "1"
# Setting file flag: one of "0", "1", "1Wb", "1WrWb" ("0" means do not create).
# Prompt file flag: "0" or "1" ("0" means do not create). Currently always generates Python rules.
# Assumes prompt templates are stored under ~/.claude_templates/.
set -euo pipefail  # Fail fast on errors, undefined variables, and broken pipelines
[ "$#" -eq 3 ] || { echo "Usage: $0 <target dir> <setting file flag> <prompt file flag>" >&2; exit 1; }
[ -e "$1" ] || { echo "Error: not found: $1" >&2; exit 2; }

init() {
  local claude_dir="$1/.claude"
  local settings_file="$claude_dir/settings.local.json"
  local instructions_file="$claude_dir/CLAUDE.md"

  [ ! -d "$claude_dir" ] && mkdir -p "$claude_dir"

  if [ "$2" != "0" ] && [ ! -f "$settings_file" ]; then
    local allow='[]'
    [ "$2" = "1Wb" ] && allow='["WebSearch"]'
    [ "$2" = "1WrWb" ] && allow='["Write(./**)", "Edit(./**)", "WebSearch"]'
    local deny='["Bash(rm:*)", "Bash(curl:*)"]'
    echo '{"permissions": {"allow": '$allow', "deny": '$deny'}}' > "$settings_file"
  fi

  if [ "$3" != "0" ] && [ ! -f "$instructions_file" ]; then
    { cat ~/.claude_templates/CLAUDE.coding.md; } > "$instructions_file"
    { echo; cat ~/.claude_templates/CLAUDE.python-coding.md; } >> "$instructions_file"
  fi
}

init "$1" "$2" "$3"
