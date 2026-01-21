### このリポジトリからローカルへの反映方法
```sh
# そのマシンへの初回の取得コマンドは以下
# chezmoi init git@github.com:CookieBox26/dotfiles.git

chezmoi git pull  # リポジトリの最新版をソースディレクトリにプル
chezmoi diff  # ソースディレクトリとローカルの差分確認
chezmoi apply -v  # ソースディレクトリからローカルへ反映
# ローカルに変更があって選択肢 diff/overwrite/all-overwrite/skip/quit が出たときは選択肢の頭文字を打つ
```

### ローカルからこのリポジトリへの反映方法
```sh
chezmoi diff ~/.claude/CLAUDE.md  # ソースディレクトリとローカルの差分確認
chezmoi add ~/.claude/CLAUDE.md  # ローカルの内容をソースディレクトリに登録
chezmoi cd
git status
git add dot_claude/CLAUDE.md  # ステージング
git commit -m "Update CLAUDE.md to require showing diffs before changes"  # コミット
git push  # プッシュ
exit
```

### 各スクリプトの使用方法

#### tools/bin/cld-ask.sh
```sh
cld-ask.sh ~/workspace/nazuna/ "$(cat <<'EOF'
X してください。
Y してください。
EOF
)" "true"
```
