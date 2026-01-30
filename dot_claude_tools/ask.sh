#!/usr/bin/bash
input_file="$(pwd)/.claude/ask.input.md" # インプットファイル
if [ ! -f "$input_file" ] || [ ! -s "$input_file" ]; then
  # インプットファイルがないか空なら以下のメッセージで終わる
  printf '\n%s' "今は依頼はないです。"
  exit 0
fi

# 引数がただ一つで 1, 2, 3 のどれかならチェックポイントを付加
message=""
newline=$'\n'
if [ "$#" -eq 1 ] && { [ "$1" = "1" ] || [ "$1" = "2" ] || [ "$1" = "3" ]; }; then
  message="以下の変更を依頼したいです。"
  if [ "$1" = "1" ]; then
    message="${message}${newline}まずは変更方針だけを提示してください。"
  elif [ "$1" = "2" ]; then
    message="${message}${newline}まずはファイル差分だけを提示してください。"
  elif [ "$1" = "3" ]; then
    message="${message}${newline}ファイル差分を提示し、ファイルも変更してください。"
  fi
fi

# メッセージ出力
printf '\n'
if [ -n "$message" ]; then
  printf '%s\n\n' "$message"
fi
cat "$input_file"
