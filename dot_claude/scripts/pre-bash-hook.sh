#!/usr/bin/bash
set -euo pipefail
json=$(cat)
command=$(printf '%s' "$json" | jq -r '.tool_input.command // ""')
if echo "$command" | grep -qP '^pytest'; then
  exit 0
fi
exit 2
