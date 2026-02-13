#!/usr/bin/bash
set -euo pipefail

# 引数からモードを取る (デフォルト 1 = 常に会話を抽出・保存)
# モード 0 なら会話履歴パスのダンプだけで終わる
# ただしモードに関わらず標準入力がなければサルベージ実行とみなして抽出・保存に進む
mode="${1:-1}" 

# Claude Code からの標準入力から会話履歴パスを取得
jsonl_file="$(pwd)/jsonl_path.txt"
read -t 0 && input_json="$(cat)" || input_json=""  # 標準入力にデータがあれば読む
# echo "$input_json" > "$(pwd)/debug.txt"  # 飛んできた標準入力を確認したい場合
if [ -n "$input_json" ] && echo "$input_json" | jq empty >/dev/null 2>&1; then
  # 有効な標準入力があれば会話履歴パスをパース
  jsonl_path="$(printf '%s' "$input_json" | jq -r '.transcript_path')"
  printf '%s\n' "$jsonl_path" > "$jsonl_file"  # 最新の会話履歴パスをダンプ
else
  # 有効な標準入力がなければ (直接呼ばれたとき) 既存ダンプから会話履歴パスを読みこむ
  [ -f "$jsonl_file" ] || { echo "Dump not found" >&2; exit 1; }
  jsonl_path="$(cat "$jsonl_file")"
  mode=1  # 直接呼ばれたなら必ず会話抽出に進む
fi
[ -n "$jsonl_path" ] && [ "$jsonl_path" != "null" ] || { echo "JSONL not found" >&2; exit 1; }
[ "$mode" = "0" ] && exit 0  # モード 0 ならここで終わる

# 会話履歴 JSONL から最後のユーザメッセージ、アシスタントの思考、アシスタントのメッセージを一括抽出
now_display="$(date '+%Y-%m-%d %H:%M:%S')"
now_file="$(date '+%Y%m%d')"
body="$(jq -rs '
  [.[] | select(.message != null)] | . as $all |

  # 最後の人間入力メッセージのインデックスを取得
  # content が文字列の場合のみ人間の入力として扱う（配列は tool_result）
  [to_entries[] | select(
    .value.message.role == "user" and
    (.value.message.content | type) == "string"
  )] | last | .key as $idx |

  # user_message を取得して assistant 側の応答を収集
  $all[$idx].message.content as $user |

  # それ以降の assistant 行から thinking / text を抽出（空白のみはスキップ）
  [$all[$idx + 1:][] | select(.message.role == "assistant")] |
  [.[] | .message.content[] | select(.type == "thinking") | .thinking | select(test("^\\s*$") | not)] as $thinkings |
  [.[] | .message.content[] | select(.type == "text") | .text | select(test("^\\s*$") | not)] as $texts |

  "## 👦\n\n" + $user + "\n\n\n" +
  ($thinkings | map("## 🐬💭\n\n" + . + "\n\n") | join("")) +
  ($texts | map("## 🐬💡\n\n" + . + "\n\n") | join(""))
' < "$jsonl_path")"

# マークダウンファイル出力 (作業ディレクトリと同名のサブディレクトリを切って配置)
target="$HOME/Dropbox/obsidian/Mercury/Claude/${PWD##*/}"
mkdir -p "$target"
printf '# %s\n\n%s\n' "$now_display" "$body" >> "${target}/${now_file}.md"
