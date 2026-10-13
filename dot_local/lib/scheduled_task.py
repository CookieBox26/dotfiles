"""
Python の schedule でタスクを定期実行するための便利クラス (遅刻・ダウンタイム・回数上限設定可)
このクラスの使い方: https://qiita.com/CookieBox26/items/9334a4d0e701ebbf0cdb
schedule ライブラリ: https://schedule.readthedocs.io/en/stable/index.html
"""
from abc import ABC, abstractmethod
import schedule
import time
import datetime


class Task(ABC):
    """
    スケジュール実行するタスクを管理するためのクラスです。
    これを継承して以下を実装してください。

    - [必須] task() にスケジュール実行するタスクを実装してください。
    - [必須] schedule() にスケジュールを指定してください。必要なら終了時刻も設定できます。
      https://schedule.readthedocs.io/en/stable/examples.html#run-a-job-until-a-certain-time
    """

    @abstractmethod
    def task(self) -> None:
        """
        定期実行するタスクを実装してください。
        """
        pass

    @abstractmethod
    def schedule(self) -> schedule.Job:
        """
        self.scheduler に実行スケジュールを設定し、その返却値 (Job オブジェクト) を返却ください。
        https://schedule.readthedocs.io/en/stable/examples.html#run-a-job-every-x-minute
        Ex. return self.scheduler.every().hour.at(':00')  # 毎時 0 分に実行
        Ex. return self.scheduler.every().day.at('09:15')  # 毎日 9:15 に実行
        """
        pass

    def __init__(self, task_name: str = 'タスク', max_count: int = 0, lateness_limit: int = 0):
        """
        - max_count : 正数を指定すると、この回数だけ定期実行したら終わります。
        - lateness_limit : 正数を指定すると、起動が遅刻してもその秒数以内なら実行します。
        """
        self.task_name = task_name  # 標準出力用
        self.max_count = max_count
        self.lateness_limit = lateness_limit
        self.scheduler = schedule.Scheduler()  # この定期実行タスクを実行するスケジューラさん
        self.job = None  # スケジューラさんに与えられた Job オブジェクト
        self.container = None  # このタスクのスケジューラを叩くコンテナ

    def downtime(self, now: datetime.datetime):
        """
        もし「この時間帯は/この日は/この曜日はタスクを実行したくない」というとき、
        ダウンタイムとしたい時間帯に True を返すようオーバーライドしてください。
        ダウンタイム中であっても schedule ライブラリは通常通り Task.run を呼びますが、
        「ダウンタイム中」とプリントするだけで task() に進まずに終わり、count も増えません。
        """
        return False

    def update_finish_flag(self):
        """
        終了フラグを更新します。
        デフォルトでは、実行回数が max_count に達したかを判定します。
        カスタムな終了条件にしたい場合はオーバーライドしてください。
        """
        if self.max_count <= 0:
            return
        if self.count >= self.max_count:
            self.finish_flag = True

    def _in_downtime(self, dt):
        if self.container and self.container.downtime(dt):
            return True
        return self.downtime(dt)

    def _print(self, *args):
        print('[Task]', f'[{self.task_name}]', *args)

    def _print_next_run(self, next_run):
        if self.finish_flag:
            return self._print('次回の実行予定はありません')
        downtime = self._in_downtime(next_run)
        self._print(
            '次回の実行予定:', next_run.strftime('%Y-%m-%d %H:%M:%S'),
            '(ダウンタイム中)' if downtime else '',
        )

    def run(self, msg=''):
        # 定期実行処理本体
        if self.finish_flag:
            return
        now = datetime.datetime.now()
        if self._in_downtime(now):
            self._print('ダウンタイム中:', now.strftime('%Y-%m-%d %H:%M:%S'))
        else:
            self.count += 1
            self._print(f'実行({self.count:4d}回目):', now.strftime('%Y-%m-%d %H:%M:%S'), msg)
            self.task()
            self.update_finish_flag()

    def _set_delta(self):
        # このタスクの実行スケジュールの周期のタイムデルタをセットします
        if self.job is None:
            self._print(f'[WARNING] ジョブが未登録なので実行周期を取得できません')
            return
        if self.job.unit == 'minutes':
            self.delta = datetime.timedelta(minutes=self.job.interval)
        elif self.job.unit == 'hours':
            self.delta = datetime.timedelta(hours=self.job.interval)
        elif self.job.unit == 'days':
            self.delta = datetime.timedelta(days=self.job.interval)
        else:
            self._print(f'[WARNING] 周期単位 {self.job.unit} は未対応です')
            self.delta = None

    def _get_lateness(self):
        # 「前回の実行時刻がいつのはずだったか」からの経過秒数を取得します
        if (self.job is None) or (self.delta is None):
            return -1
        last = self.job.next_run - self.delta
        now = datetime.datetime.now()
        return int((now - last).total_seconds())

    def _preprocess(self):
        if self.job is None:
            self._print(f'[WARNING] ジョブ未登録なので次回の実行予定を取得できません')
            return
        # 遅刻が許容されている場合、許容秒数内ならタスクを実行します
        if self.lateness_limit > 0:
            lateness = self._get_lateness()
            if 0 <= lateness < self.lateness_limit:
                self.run(f'({lateness} 秒遅刻)')

    def register(self):
        # スケジューラさんにジョブ (実行スケジュールと実行内容) を登録します
        self.scheduler.clear()  # 既にジョブがあったらクリア
        self.count = 0
        self.finish_flag = False
        self.job = self.schedule().do(self.run)  # 登録
        self._set_delta()
        self._preprocess()


class TaskContainer:
    """
    スケジュール実行するタスクのリストを実行するクラスです。
    何秒周期でタスク実行するかは適宜判断して period に渡してください。
    もし period をタスクのスケジュール周期より長くした場合、
    仮に前回実行から 3 回分のタスクが溜まっていても 1 回しか実行されません。
    Ex. https://schedule.readthedocs.io/en/stable/reference.html#schedule.Scheduler.run_pending
    """
    def __init__(self, tasks, period):
        self.tasks = tasks
        self.period = period

    def downtime(self, now: datetime.datetime):
        """
        もし「この時間帯は/この日は/この曜日はタスクを実行したくない」というとき、
        ダウンタイムとしたい時間帯に True を返すよう上書きしてください。
        ダウンタイムは個別のタスクごとに設定することもできます。
        """
        return False

    def on_iter(self):
        """
        ループの最初に必ずやる処理があれば上書きしてください。
        例えばダウンタイムを書いたモジュールを動的リロードして上書きしてください。
        """
        pass

    def _print_next_run(self):
        # 終了していないタスクのうち次回の実行予定が近い順に最大 3 件をプリントします
        tasks = [
            task for task in self.tasks
            if not task.finish_flag and task.scheduler.next_run is not None
        ]
        for task in sorted(tasks, key=lambda task: task.scheduler.next_run)[:3]:
            task._print_next_run(task.scheduler.next_run)

    def run(self):
        print('[TaskContainer] スケジュール実行を開始します')
        for task in self.tasks:
            task.container = self
            task.register()
        for task in sorted(self.tasks, key=lambda task: task.job.next_run):
            if task.count == 0:
                task._print_next_run(task.job.next_run)
        while True:
            self.on_iter()
            executed = False  # このループで少なくとも一つのタスクが実行されたか
            for task in self.tasks:
                count_before = task.count
                task.scheduler.run_pending()
                if task.count > count_before:
                    executed = True
            if executed:
                self._print_next_run()
            if all([task.finish_flag for task in self.tasks]):
                break
            time.sleep(self.period)
        print('[TaskContainer] すべてのスケジュール実行タスクが終了しました')
