### このリポジトリからローカルへの反映方法
```
chezmoi init git@github.com:CookieBox26/dotfiles.git
chezmoi diff  # 差分確認
chezmoi apply -v  # 反映
```

### ローカルからこのリポジトリへの反映方法
```
chezmoi diff ~/.claude/CLAUDE.md  # ソースディレクトリとの差分確認
chezmoi add ~/.claude/CLAUDE.md  # ソースディレクトリに反映
chezmoi cd
git status
git add dot_claude/CLAUDE.md  # ステージング
git commit -m "Update CLAUDE.md to require showing diffs before changes"  # コミット
git push  # プッシュ
exit
```

### スクリプトの使用方法

#### tools/bin/cld-ask.sh
```
cld-ask.sh ~/workspace/nazuna/ "$(cat <<'EOF'
X してください。
Y してください。
EOF
)" "true"
```
