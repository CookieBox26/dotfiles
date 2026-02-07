#!/usr/bin/bash
# 指定の作業ディレクトリに移動して Claude に質問し回答を回収場所に保存して戻ってきます
# これを何回分も予約しておくことができます
# 回答は回収ボックス内に YYYYMMDD-hhmmss.md という名前で保存されます
# フラグを指定した場合は回答内容から制限に達していたか確認し制限解除まで待って再質問します
set -euo pipefail  # Fail fast on errors, undefined variables, and broken pipelines
[ "$#" -eq 3 ] || { echo "Usage: $0 <target dir> <question> <check hit limit>" >&2; exit 1; }
[ -e "$1" ] || { echo "Error: not found: $1" >&2; exit 2; }
obsidian_dir=~/Dropbox/obsidian/Mercury/Claude/  # 回答マークダウンファイル回収場所


wait_until_limit_reset() {  # 引数: 制限中メッセージ
  # 制限中メッセージをパースし解除まで待機 (スリープ) します
  # メッセージ中に resets 5pm といった箇所があることを期待します
  local now=$(date +%s)
  local resets=$(echo "$1" | sed -n 's/.*resets \([0-9]\{1,2\}[ap]m\).*/\1/p')
  local target=$(($(date -d "today $resets" +%s) + 60))  # 安全のため 1 分足す
  [ "$target" -le "$now" ] && target=$(date -d "tomorrow $resets" +%s)
  echo "Rate limit hit. Waiting until $(date -d @$target +'%m/%d %H:%M')."
  sleep $((target - now))
}


ask() {  # 引数: 作業ディレクトリ, 質問文, 回答文から制限に達していたかを確認するか (true/false)
  # 作業ディレクトリに移動して Claude に質問し回答を回収場所に保存して戻ってきます
  local out="$obsidian_dir/$(date '+%Y%m%d-%H%M%S').md"
  pushd $1  # 作業ディレクトリに移動
  echo $1$'\n' > $out
  echo "$2" >> $out
  echo $'\n'$'\n'"---"$'\n'$'\n' >> $out
  local answer=$(claude --allowedTools=Write -p "$2")
  if "$3" && echo "$answer" | grep -q "You've hit your limit"; then
    # 制限中なら制限解除を待って再質問
    wait_until_limit_reset "$answer"
    answer=$(claude --allowedTools=Write -p "$2")
  fi
  echo "$answer" >> $out
  echo "Written to $out"
  popd  # 元のディレクトリに帰還
}


ask "$1" "$2" "$3"
exit

# 実行例
q=$(cat <<'EOF'
.claude/request_2026012003.md にあなたへの依頼を書きました。
この依頼を実施してください。
EOF
); cld-ask.sh ~/workspace/nazuna/ "$q" 0
