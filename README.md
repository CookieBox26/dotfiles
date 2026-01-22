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

### 各スクリプトの使用例

#### tools/bin/cld-ask.sh

Claude に質問し、回答を回収するスクリプトです。  
PATH に `tools/bin/` を追加しておくとどこからでも使用できます。    

````sh
q="$(cat <<'EOF'
### 依頼内容

このリポジトリは時系列予測モデルを分析するためのリポジトリです。
作業手順にしたがって、以下の変更を実装してください。 

1. nazuna/models/simple_average.py に、中身が未実装のクラス SimpleAverageVariableDecayChannelwise があります。
   実装済みの SimpleAverageVariableDecay を参考に、SimpleAverageVariableDecayChannelwise を実装してください。
   SimpleAverageVariableDecay クラスは全系列共通の decay_rate を学習しますが、
   SimpleAverageVariableDecayChannelwise クラスでは系列ごとに decay_rate を学習します。
   decay_rate のサイズは (系列数,) になると思います。
2. 1. で実装したクラスの単体テストを tests/models/test_simple_average.py に追加してください。
3. 1. で実装したクラスを利用する例 nazuna/examples/train_savdc_jma_daily.toml を追加してください。
   既にある例 nazuna/examples/train_savd_jma_daily.toml と、
   これを動かす nazuna/task_runner.py の run_tasks() を参考にしてください。
   例を追加したら tests/test_examples.py と docs/index.md の他の例があるところに追記してください。

### 作業手順
- ブランチ feature/xxxxxx を切ってください。 
  ただし、xxxxxx は英数アンダースコアからなる文字列にしてください。 
- ブランチに依頼内容をコミットしてください。 
- コミットをプッシュ＆プルリクエスト (PR) するための .claude/run.sh を作成してください。 
  .claude/run.sh はコミットしないでください。また、.claude/run.sh を実行しないでください。 
- 以下の内容を画面に標準出力して私を呼んでください。
  - .claude/run.sh に書いた「英語による PR タイトル」と「英語による PR 説明」の内容
  - 日本語による PR の説明や補足

```sh:.claude/run.sh
git push origin feature/xxxxxx
gh pr create --base main --head feature/xxxxxx --title '英語による PR タイトル' --body '英語による PR 説明'

# Post-merge cleanup command
# git branch -d feature/xxxxxx
```

### 注意事項
- この依頼については PR から変更内容を確認します。作業手順完了前に変更内容を私に確認することはしないでください。
- あなたには python, pytest の実行は許可していません。実行しないでください。

EOF
)"
echo "$q"
cld-ask.sh ~/workspace/nazuna/ "$q" "true"
````
