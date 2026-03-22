from pathlib import Path
import os
import difflib
from colorama import Fore


new = '''
      "WebFetch(domain:ar5iv.labs.arxiv.org)",
      "WebFetch(domain:arxiv.org)",
'''


def color_diff(diff):
    color = {'@': Fore.CYAN + '@'}
    for line in diff:
        yield color.get(line[0], line[0]) + line[1:] + Fore.RESET
        if line[0] == '@':
            color.update({'-': Fore.RED + '-', '+': Fore.GREEN + '+'})


if __name__ == '__main__':
    os.chdir(os.path.expanduser('~/.claude'))
    settings = Path('settings.json').read_text(encoding='utf8').splitlines()
    current = [line for line in settings if 'WebFetch(domain:' in line]
    for line in current:
        print(line)
    new = [line for line in new.splitlines() if line]
    new = sorted(list(set(current + new)))
    for line in color_diff(difflib.unified_diff(
        current, new, fromfile='current', tofile='new', lineterm='',
    )):
        print(line)
    print('---------------')
    for line in new:
        print(line)
