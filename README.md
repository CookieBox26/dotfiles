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
chezmoi diff  # ソースディレクトリとローカルの差分確認 (chezdiff で 1 行表示)
chezmoi apply  # ソースディレクトリからローカルへ反映
chezmoi apply ~/.bashrc  # ソースディレクトリからローカルへ反映 (特定ファイルのみ)
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

pushd ~/.local/share/chezmoi/  # ソースディレクトリに移動 (chezcd)
# chezmoi cd コマンドもあるが Windows Git Bash でそれをやると bash でなくなってしまう
# このリポジトリから .bashrc 取得後であれば chezcd でエイリアスしている
git status
git add dot_claude/CLAUDE.md  # ステージング
git commit -m "Update CLAUDE.md to require showing diffs before changes"  # コミット
git push  # プッシュ
popd
```

### Tips
```sh
# 個人設定ファイルを移動 or 削除したときローカル側の旧ファイルは自分の責任で削除してください
# ソースディレクトリ側ではファイルのみ Git から削除しても空ディレクトリが残っていると
# chezmoi はローカルにも同ディレクトリの存在を要求してしまいます
# ソースディレクトリ以下の空ディレクトリを削除したいときの確認と削除コマンドは以下です
find ~/.local/share/chezmoi -path '*/.git' -prune -o -type d -empty -print
find ~/.local/share/chezmoi -path '*/.git' -prune -o -type d -empty -exec rmdir {} +
```

### Dotfiles overview
✅ このリポジトリに登録済  
💡 このリポジトリの運用で存在を前提とするファイル・ディレクトリ
```sh
~/
├─ .config/chezmoi/chezmoi.toml 🏠  # chezmoi 設定ファイル
├─ .local/
│    ├─ share/chezmoi/ 🏠  # chezmoi ソースディレクトリ (chezcd でここに pushd)
│    │
│    ├─ bin/
│    │    ├─ sync.py ✅  # ディレクトリ同期スクリプト
│    │    ├─ cld-ask.sh ✅  # Claude にワンショットの質問をして回答を保存
│    │    └─ cld-perm.sh ✅  # Claude のパーミッションを作成・変更
│    └─ lib/
│         ├─ __init__.py ✅
│         └─ scheduled_task.py ✅  # スケジュール実行タスク
├─ launcher.html ✅🧩
├─ .bashrc ✅
├─ .claude/
│    ├─ settings.json ✅  # ユーザスコープのパーミッション
│    ├─ CLAUDE.md ✅  # ユーザスコープのシステムプロンプト
│    ├─ commands/
│    │    ├─ ask.md ✅  # 変更依頼にレベルを付与するコマンド
│    │    └─ save.md ✅🧩  # 直前の質問と回答を保存するコマンド
│    └─ scripts/
│         ├─ ask.sh ✅  # 変更依頼にレベルを付与するコマンドの処理本体
│         ├─ pre-bash-hook.sh ✅  # 意図しない Bash コマンドを禁止するためのツール使用前フック
│         └─ post-proc.sh ✅  # 回答後フック (作業ディレクトリに post-proc.sh があれば呼び出し)
│
├─ workspace/ 💡🟣  # 日常作業ディレクトリ
│    ├─ post-proc.sh ✅🔒  # その時々の作業内容に応じた資料コンパイル・同期コマンド
│    ├─ CLAUDE.md ✅🔒  # 日常作業の上で Claude に伝えたい前提知識・ルール
│    ├─ ask.md 💡  # メインエージェントへの作業依頼
│    ├─ .claude/
│    │    ├─ settings.local.json ✅🧩
│    │    ├─ agents/  # サブエージェント
│    │    │     └─ zundamon.md ✅🧩
│    │    └─ agent-memory/  # サブエージェントの記憶
│    │          └─ zundamon/MEMORY.md
│    ├─ backyard/ 💡  # 資料作成場所
│    │    ├─ Draft/20260101suffix/
│    │    ├─ Mtg/20260101/
│    │    └─ *.pdf
│    ├─ project_0/  # 個別プロジェクト
│    │    └─ REPORT.md  # サブエージェントの作業報告
│    └─ project_1/  # 個別プロジェクト
│
└─ Dropbox/obsidian/Mercury/  🟣
     ├─ Claude/ 💡❗  # Claude 回答保存場所
     ├─ Backyard/ 💡  # 資料作成場所と同期
     └─ References/


# 暗号化ファイル 🔒 は変更したら再度暗号化します
chezmoi add --encrypt ~/workspace/post-proc.sh
chezmoi add --encrypt ~/workspace/CLAUDE.md
# テンプレートファイル 🧩 はテンプレート側を編集したほうがよいです
chezcd
sakura workspace/dot_claude/settings.local.json.tmpl
sakura workspace/dot_claude/agents/zundamon.md.tmpl
# ローカル側を編集してしまったら改めてテンプレートとして登録しくり抜いてください
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

#### .local/bin/sync.py
ディレクトリ同期スクリプトです (rsync の代替策です)。`--delete` 指定時は同期先の空サブディレクトリも削除するので必要なサブディレクトリは空にしておかないでください。
```sh
sync.py ~/workspace/backyard/ ~/Dropbox/obsidian/Mercury/Backyard/
sync.py ~/workspace/backyard/ ~/Dropbox/obsidian/Mercury/Backyard/ --apply --delete
sync.py ~/Dropbox/obsidian/Mercury/Backyard/ ~/workspace/backyard/
sync.py ~/Dropbox/obsidian/Mercury/Backyard/ ~/workspace/backyard/ --apply --delete
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
