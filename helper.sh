#!/usr/bin/bash
while IFS= read -r line; do
  filename="${line:2}"
  echo "----- ローカルとソースディレクトリに差分があります -----"
  echo "${HOME}/${filename}"
  chezmoi diff "${HOME}/${filename}"

  tmpl=0
  encrypt=0
  count=$(chezmoi managed --include=templates "${HOME}/${filename}" | wc -l)
  [ "$count" -gt 0 ] && { tmpl=1; echo "※ テンプレート化されて登録されています"; }
  count=$(chezmoi managed --include=encrypted "${HOME}/${filename}" | wc -l)
  [ "$count" -gt 0 ] && { encrypt=1; echo "※ 暗号化されて登録されています"; }

  echo "${HOME}/${filename} への操作を選択してください"
  read -p "l=ローカルを登録, s=ソースを適用, n=何もしない, q=終了 > " key < /dev/tty
  if [ "$tmpl" -eq 1 ] && [ "$key" == "l" ]; then
    echo "[ERROR] テンプレートファイルはローカルから登録できません"
    exit 0
  fi
  if [ "$key" == "s" ]; then
    echo "本当にソースを適用してローカルを上書きしてよいですか？"
    echo "(サブ機への同期、テンプレートでソース編集したときのみ想定される操作)"
    read -p "l=ローカルを登録, s=ソースを適用, n=何もしない, q=終了 > " key < /dev/tty
  fi
  case "$key" in
    q) exit 0 ;;
    l)
      echo "ローカルを登録します"
      [ "$encrypt" -eq 0 ] && chezmoi add "${HOME}/${filename}"
      [ "$encrypt" -eq 1 ] && chezmoi add --encrypt "${HOME}/${filename}"
      ;;
    s)
      echo "ソースを適用します"
      chezmoi apply "${HOME}/${filename}"
      ;;
  esac
done < <(chezmoi diff | grep "^diff " | awk "{print \$3}")

echo
git status -s
