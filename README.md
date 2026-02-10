# dotfiles

[Pull from repository](#pull-from-repository)  
[Push to repository](#push-to-repository)  
[Dotfiles overview](#dotfiles-overview)  
[Dotfiles details](#dotfiles-details)  

### Pull from repository
```sh
# そのマシンへの初回の取得コマンドは以下
# chezmoi init git@github.com:CookieBox26/dotfiles.git

# そのマシンでの初回のファイル暗号化用鍵ペア作成は以下
# chezmoi age-keygen --output=~/.config/chezmoi/key.txt
# vi ~/.config/chezmoi/chezmoi.toml
# encryption = "age"
# [age]
# identity = "~/.config/chezmoi/key.txt"  # その PC の秘密鍵パス
# recipients = [
#   "age1...",  # PC1 公開鍵
#   "age1...",  # PC2 公開鍵
# ]

# ローカル注入変数がある場合は用意しておく
# vi ~/.config/chezmoi/chezmoi.toml
# [data]
# username = "Cookie"

chezmoi git pull  # リポジトリの最新版をソースディレクトリにプル
chezmoi diff  # ソースディレクトリとローカルの差分確認
chezmoi apply -v  # ソースディレクトリからローカルへ反映
# ローカルに変更があって選択肢 diff/overwrite/all-overwrite/skip/quit が出たときは選択肢の頭文字を打つ
```

### Push to repository
```sh
chezmoi diff ~/.claude/CLAUDE.md  # ソースディレクトリとローカルの差分確認

chezmoi add ~/.claude/CLAUDE.md  # ローカルの内容をソースディレクトリに登録

# 暗号化して登録する場合 (GitHub リポジトリにファイルの内容を公開したくないとき)
# chezmoi add --encrypt ~/himitsu.txt

# テンプレートとして登録する場合 (ローカルでファイルに変数を代入したいとき)
# chezmoi add --template ~/launcher.html  # テンプレートとして登録
# vi ~/.local/share/chezmoi/launcher.html.tmpl  # テンプレートをくり抜く
# vi ~/.config/chezmoi/chezmoi.toml  # 値を未設定の変数であれば値を設定

# ソースディレクトリに移動
# 公式には chezmoi cd だが Windows Git Bash で chezmoi cd すると bash でなくなるのでこう
pushd ~/.local/share/chezmoi/
git status
git add dot_claude/CLAUDE.md  # ステージング
git commit -m "Update CLAUDE.md to require showing diffs before changes"  # コミット
git push  # プッシュ
popd  # chezmoi cd で移動した場合は exit で元の場所に戻る
```

### Dotfiles overview
✅ このリポジトリに登録済  
🔄 このリポジトリに未登録  
💡 このリポジトリの設定で存在を前提とするファイル・ディレクトリ
```sh
~/
├─ .config/chezmoi/chezmoi.toml 🏠  # chezmoi 設定ファイル
├─ .local/
│    ├─ share/chezmoi/ 🏠  # chezmoi ソースディレクトリ
│    │
│    ├─ bin/
│    │    ├─ cld-ask.sh ✅  # Claude にワンショットの質問をして回答を保存
│    │    └─ cld-perm.sh ✅  # Claude のパーミッションを作成・変更
│    └─ lib/
│         ├─ __init__.py ✅
│         └─ scheduled_task.py ✅  # スケジュール実行タスク
│
├─ launcher.html ✅🧩  # ランチャー
│
├─ .claude/
│    ├─ settings.json ✅  # ユーザスコープのパーミッション
│    ├─ CLAUDE.md ✅  # ユーザスコープのシステムプロンプト
│    ├─ commands/
│    │    ├─ ask.md ✅  # 変更依頼にレベルを付与するラッパー
│    │    └─ save.md ✅🧩  # 直前の質問と回答を保存
│    └─ scripts/
│          ├─ ask.sh ✅  # 変更依頼にレベルを付与するラッパー
│          └─ post-proc.sh ✅  # 作業ディレクトリに post-proc.sh があれば繋ぐ
│
├─ workspace/ 💡  # 作業場所・Claude チャットセッション起動場所
│    ├─ post-proc.sh 💡  # その時の作業内容に応じたよく走らせるコマンド
│    ├─ drop.sh 🔄  # 資料作成場所の資料を DropBox に同期
│    ├─ CLAUDE.md 🔄🔒
│    ├─ .claude/
│    │    ├─ settings.local.json ✅🧩
│    │    ├─ rules/
│    │    │    └─ hoge.md 🔄  # 個別プロジェクト用システムプロンプト (paths 指定)
│    │    └─ ask.input.md 💡  # 変更依頼を書く
│    ├─ backyard/ 💡  # 資料作成場所
│    │    ├─ Manuscript/YYYYMMDD.suffix/
│    │    ├─ Mtg/YYYYMMDD/
│    │    └─ *.pdf
│    ├─ project_0/  # 個別プロジェクト
│    └─ project_1/  # 個別プロジェクト
│
└─ Dropbox/obsidian/Mercury/
     ├─ Claude/ 💡❗  # Claude 回答保存場所
     ├─ Backyard/ 💡  # 資料作成場所から同期
     └─ References/
```

### Dotfiles details

#### launcher.html
ランチャーです。これをブラウザのホームページに設定してブラウザのアカウント機能で他のマシンにも連携する場合、ユーザ名が異なるマシンではファイルパスが変わってしまうので、適宜ハードリンクを張ってください。  
```sh
# Ex. ホームページは file:///C:/Users/Cookie/launcher.html
mkdir ../Cookie  # ユーザ名が Cookie でないマシンでも Cookie ディレクトリを作成
cd ../Cookie
ln ../${USERNAME}/launcher.html launcher.html
```

#### .local/bin/cld-perm.sh
`<target dir>/.claude/settings.local.json` を作成または上書きします。  
```sh
# Usage: cld-perm.sh <target dir> -s[12]<flag>
cld-perm.sh "`pwd`" -s1  # 何も許可しない設定ファイルを作成 (まだなければ)
cld-perm.sh "`pwd`" -s2  # 何も許可しない設定ファイルを作成 (あっても上書き)
cld-perm.sh "`pwd`" -s2Wb,Wr  # Web検索とファイル書き込みを許可 (上書き)
cld-perm.sh "`pwd`" -s2Wb,Wr,Git  # Web検索とファイル書き込みと Git 操作を許可 (上書き)
```

#### .local/bin/cld-ask.sh
Claude に質問して回答を回収します。 
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

#### .local/lib/scheduled_task.py
タスクをスケジュール実行します。
```py
import pathlib
import sys
sys.path.append(pathlib.Path('~/.local/lib').expanduser().as_posix())
from scheduled_task import Task, TaskContainer

class MyTask(Task):
    task_name = 'テスト'
    def task(self):
        print('こんにちは')
    def schedule(self):
        # return self.scheduler.every().hour.at(':00')  # 毎時 0 分に実行
        # return self.scheduler.every().day.at('09:15')  # 毎日 9:15 に実行
        return self.scheduler.every().minutes.at(':00')

if __name__ == '__main__':
    TaskContainer([MyTask()], period=5).run()  # 5 秒ごとに判定
```
