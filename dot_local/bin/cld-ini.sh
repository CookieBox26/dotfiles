#!/usr/bin/bash
# Creates .claude/settings.local.json and .claude/CLAUDE.md if they do not exist.
# Usage: cld-ini.sh <target dir> [-s<flag>] [-p<flag>]
# Ex. cld-ini.sh "`pwd`" -s1Wb
# Ex. cld-ini.sh "`pwd`" -s1WrWb
# Ex. cld-ini.sh "`pwd`" -s1WrWb -p1
# -s<flag>: Setting file flag, one of "1", "1Wb", "1WrWb" (omit to skip creation).
#           Use "2", "2Wb", "2WrWb" to overwrite existing file.
# -p<flag>: Prompt file flag, "1" to create (omit to skip). Currently always generates Python rules.
#           Use "2" to overwrite existing file.
# Assumes prompt templates are stored under ~/.claude_templates/.
set -euo pipefail  # Fail fast on errors, undefined variables, and broken pipelines
[ "$#" -ge 1 ] || { echo "Usage: $0 <target dir> [-s<flag>] [-p<flag>]" >&2; exit 1; }
[ -e "$1" ] || { echo "Error: not found: $1" >&2; exit 2; }

target_dir="$1"
shift

setting_flag="0"
prompt_flag="0"

while getopts "s:p:" opt; do
  case $opt in
    s) setting_flag="$OPTARG" ;;
    p) prompt_flag="$OPTARG" ;;
    *) echo "Usage: $0 <target dir> [-s<flag>] [-p<flag>]" >&2; exit 1 ;;
  esac
done
if [ "$setting_flag" = "0" ] && [ "$prompt_flag" = "0" ]; then
  echo "Error: At least one option (-s or -p) is required." >&2; exit 1;
fi

init_settings() {
  local claude_dir="$1/.claude"
  local settings_file="$claude_dir/settings.local.json"
  [ ! -d "$claude_dir" ] && mkdir -p "$claude_dir"
  local mode="${2:0:1}"
  local perm="${2:1}"
  if [ "$2" != "0" ] && { [ ! -f "$settings_file" ] || [ "$mode" = "2" ]; }; then
    local allow='[]'
    [ "$perm" = "Wb" ] && allow='["WebSearch"]'
    [ "$perm" = "WrWb" ] && allow='["Write(./**)", "Edit(./**)", "WebSearch"]'
    local deny='["Bash(rm:*)", "Bash(curl:*)"]'
    echo '{"permissions": {"allow": '$allow', "deny": '$deny'}}' > "$settings_file"
  fi
}

init_prompt() {
  local claude_dir="$1/.claude"
  local instructions_file="$claude_dir/CLAUDE.md"
  [ ! -d "$claude_dir" ] && mkdir -p "$claude_dir"
  local mode="${2:0:1}"
  if [ "$2" != "0" ] && { [ ! -f "$instructions_file" ] || [ "$mode" = "2" ]; }; then
    { cat ~/.claude_templates/CLAUDE.coding.md; } > "$instructions_file"
    { echo; cat ~/.claude_templates/CLAUDE.python-coding.md; } >> "$instructions_file"
  fi
}

init_settings "$target_dir" "$setting_flag"
init_prompt "$target_dir" "$prompt_flag"
