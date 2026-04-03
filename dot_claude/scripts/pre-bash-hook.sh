#!/usr/bin/bash
set -euo pipefail
json=$(cat)
command=$(printf '%s' "$json" | jq -r '.tool_input.command // ""')

pattern="^(uv run )?pytest$"
[[ "$command" =~ $pattern ]] && exit 0

pattern="^bash -c 'source ~/\.claude/scripts/ask\.sh'"
[[ "$command" =~ $pattern ]] && exit 0

pattern="^bash -c 'source ~/\.claude/scripts/post-proc\.sh'$"
[[ "$command" =~ $pattern ]] && exit 0

script="$(pwd)/pre-bash-hook.sh"
if [ -f "$script" ]; then
  bash "$script" "$command"
  exit $?
fi

script="$(pwd)/.claude/pre-bash-hook.sh"
if [ -f "$script" ]; then
  bash "$script" "$command"
  exit $?
fi

exit 2
