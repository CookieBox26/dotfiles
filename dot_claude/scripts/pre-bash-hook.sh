#!/usr/bin/bash
set -euo pipefail

json=$(cat)
command=$(printf '%s' "$json" | jq -r '.tool_input.command // ""')
if echo "$command" | grep -qP '^pytest$'; then
  exit 0
fi
if [[ "$command" =~ ^bash\ -c\ \'source\ ~/.claude/scripts/ask\.sh\' ]]; then
  exit 0
fi

script="$(pwd)/pre-bash-hook.sh"
if [ -f "$script" ]; then
  bash "$script" "$command"
else
  exit 2
fi
