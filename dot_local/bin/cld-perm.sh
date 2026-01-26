#!/usr/bin/bash
# <target dir>/.claude/settings.local.json を作成します (上書きも可)
# Usage: cld-perm.sh <target dir> -s[12]<flag>
# Ex. cld-perm.sh "`pwd`" -s1  # 何も許可しない設定ファイルを作成 (まだなければ)
# Ex. cld-perm.sh "`pwd`" -s2  # 何も許可しない設定ファイルを作成 (あっても上書き)
# Ex. cld-perm.sh "`pwd`" -s2Wb,Wr  # Web検索とファイル書き込みを許可 (上書き)
# Ex. cld-perm.sh "`pwd`" -s2Wb,Wr,Git  # Web検索とファイル書き込みと Git 操作を許可 (上書き)
set -euo pipefail  # Fail fast on errors, undefined variables, and broken pipelines
usage='Usage: cld-perm.sh "`pwd`" -s2Wb,Wr,Git'
[ "$#" -eq 2 ] || { echo "$usage" >&2; exit 1; }
[ -e "$1" ] || { echo "Error: not found: $1" >&2; exit 2; }
target_dir="$1"
shift
setting_flag="0"
while getopts "s:" opt; do
  case $opt in
    s) setting_flag="$OPTARG" ;;
    *) echo "$usage" >&2; exit 1 ;;
  esac
done
[ "$setting_flag" != "0" ] || { echo "$usage" >&2; exit 1; }


in_array() {
  local -n arr="$2"
  local x
  for x in "${arr[@]}"; do
    [[ "$x" == "$1" ]] && return 0
  done
  return 1
}


init_settings() {  # Ex. init_settings "$target_dir" -s2Wb,Wr,Git
  local claude_dir="$1/.claude"
  local settings_file="$claude_dir/settings.local.json"
  [ ! -d "$claude_dir" ] && mkdir -p "$claude_dir"
  local mode="${2:0:1}"
  if [ "$2" != "0" ] && { [ ! -f "$settings_file" ] || [ "$mode" = "2" ]; }; then
    local indent="      "
    local newline=$'\n'
    local allow=""
    local deny="${newline}${indent}\"Bash(rm:*)\","
    deny="${deny}${newline}${indent}\"Bash(curl:*)\","
    deny="${deny}${newline}${indent}\"Bash(python:*)\","
    deny="${deny}${newline}${indent}\"Bash(pytest:*)\","

    local -a perms
    IFS=',' read -r -a perms <<< "${2:1}"
    if in_array "Wb" perms; then
      allow="${allow}${newline}${indent}\"WebSearch\","
    fi
    if in_array "Wr" perms; then
      allow="${allow}${newline}${indent}\"Write(./**)\","
      allow="${allow}${newline}${indent}\"Edit(./**)\","
    else
      deny="${deny}${newline}${indent}\"Write(./**)\","
      deny="${deny}${newline}${indent}\"Edit(./**)\","
    fi
    if in_array "Git" perms; then
      allow="${allow}${newline}${indent}\"Bash(git branch:*)\","
      allow="${allow}${newline}${indent}\"Bash(git add:*)\","
      allow="${allow}${newline}${indent}\"Bash(git commit:*)\","
      allow="${allow}${newline}${indent}\"Bash(git checkout:*)\","
    else
      deny="${deny}${newline}${indent}\"Bash(git:*)\","
    fi

    echo -e "{${newline}  \"permissions\": {" > "$settings_file"
    echo -e "    \"allow\": [${allow%,}" >> "$settings_file"
    echo -e "    ]," >> "$settings_file"
    echo -e "    \"deny\": [${deny%,}" >> "$settings_file"
    echo -e "    ]" >> "$settings_file"
    echo -e "  }${newline}}" >> "$settings_file"
  fi
}


init_settings "$target_dir" "$setting_flag"
