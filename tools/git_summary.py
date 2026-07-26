#!/usr/bin/env python3
"""
tools/git_summary.py — Формирует сводку изменений по коммитам между ветками.

Использование:
    python tools/git_summary.py
    python tools/git_summary.py --base beta-dev
    python tools/git_summary.py --base origin/master --output summary.md
    python tools/git_summary.py --base origin/master --no-color
"""

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime

# Маппинг префиксов коммитов -> категории (эмодзи + заголовок)
# Порядок важен: первое совпадение выигрывает
CATEGORY_PATTERNS = [
    (re.compile(r'^\[?FIX(?:ES)?\]?\s*', re.IGNORECASE),       'Исправления'),
    (re.compile(r'^\[?EMERGENCY\s+FIX\]?\s*', re.IGNORECASE),  'Срочные исправления'),
    (re.compile(r'^\[?ADD(?:S)?\]?\s*', re.IGNORECASE),        'Новое'),
    (re.compile(r'^\[?RSCADD\]?\s*', re.IGNORECASE),            'Новое'),
    (re.compile(r'^\[?DEL(?:S)?\]?\s*', re.IGNORECASE),        'Удалено'),
    (re.compile(r'^\[?RSCDEL\]?\s*', re.IGNORECASE),            'Удалено'),
    (re.compile(r'^\[?TWEAK(?:S)?\]?\s*', re.IGNORECASE),      'Доработки'),
    (re.compile(r'^\[?RSC:TWEAK\]?\s*', re.IGNORECASE),         'Доработки'),
    (re.compile(r'^\[?REFACTOR\]?\s*', re.IGNORECASE),          'Рефакторинг'),
    (re.compile(r'^\[?CODE(?:_?IMP)?\]?\s*', re.IGNORECASE),   'Код'),
    (re.compile(r'^\[?BALANCE\]?\s*', re.IGNORECASE),           'Баланс'),
    (re.compile(r'^\[?MAP\]?\s*', re.IGNORECASE),              'Карты'),
    (re.compile(r'^\[?QOL\]?\s*', re.IGNORECASE),              'Качество жизни'),
    (re.compile(r'^\[?SOUND(?:ADD|DEL)?\]?\s*', re.IGNORECASE),'Звук'),
    (re.compile(r'^\[?IMAGE(?:ADD|DEL)?\]?\s*', re.IGNORECASE),'Изображения'),
    (re.compile(r'^\[?CONFIG\]?\s*', re.IGNORECASE),            'Конфигурация'),
    (re.compile(r'^\[?ADMIN\]?\s*', re.IGNORECASE),            'Админ'),
    (re.compile(r'^\[?SERVER\]?\s*', re.IGNORECASE),           'Сервер'),
    (re.compile(r'^\[?CHERRYPICK\]?\s*', re.IGNORECASE),       'Cherry-pick'),
    (re.compile(r'^\[?SPELLCHECK\]?\s*', re.IGNORECASE),       'Опечатки'),
    (re.compile(r'^\[?TYPO\]?\s*', re.IGNORECASE),             'Опечатки'),
]

# Категория по умолчанию для нераспознанных
DEFAULT_CATEGORY = 'Прочее'


def run_git(*args):
    """Выполнить git-команду и вернуть stdout."""
    try:
        result = subprocess.run(
            ['git'] + list(args),
            capture_output=True, text=True, check=True,
            encoding='utf-8', errors='replace'
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Ошибка git: {e.stderr.strip()}", file=sys.stderr)
        sys.exit(1)


def get_commits(base, head):
    """Получить список коммитов: хеш, автор, дата, сообщение."""
    log_format = '%H|%an|%ai|%s'
    raw = run_git('log', '--no-merges', f'--format={log_format}', f'{base}..{head}')
    if not raw:
        return []
    commits = []
    for line in raw.split('\n'):
        parts = line.split('|', 3)
        if len(parts) == 4:
            commits.append({
                'hash': parts[0][:8],
                'author': parts[1],
                'date': parts[2],
                'message': parts[3],
            })
    return commits


def categorize_commit(message):
    """Определить категорию коммита по префиксу сообщения."""
    for pattern, title in CATEGORY_PATTERNS:
        if pattern.match(message):
            return title
    return DEFAULT_CATEGORY


def get_changed_files(base, head):
    """Получить список изменённых файлов."""
    raw = run_git('diff', '--name-only', f'{base}..{head}')
    if not raw:
        return []
    return raw.split('\n')


def get_diff_stats(base, head):
    """Получить статистику изменений (строк +/-, количество файлов)."""
    raw = run_git('diff', '--shortstat', f'{base}..{head}')
    match = re.search(r'(\d+)\s+insertion', raw)
    added = int(match.group(1)) if match else 0
    match = re.search(r'(\d+)\s+deletion', raw)
    removed = int(match.group(1)) if match else 0
    return added, removed


def format_markdown(commits, base, head, branch):
    """Сформировать Markdown-отчёт."""
    lines = []

    # --- Группировка по категориям ---
    by_category = defaultdict(list)
    for c in commits:
        cat = categorize_commit(c['message'])
        by_category[cat].append(c)

    lines.append("## Типы изменений")
    lines.append("")
    for cat, items in sorted(by_category.items(), key=lambda x: -len(x[1])):
        lines.append(f"### {cat} ({len(items)})")
        lines.append("")
        for c in items:
            lines.append(f"- `{c['hash']}` {c['message']} — {c['author']}")
        lines.append("")

    return '\n'.join(lines)


def format_console(commits, base, head, branch, color=True):
    """Сформировать цветной консольный вывод."""
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    RESET = '\033[0m' if color else ''

    lines = []
    sep = "=" * 50
    lines.append(f"{GREEN}{sep}{RESET}" if color else sep)
    lines.append(f"  Сводка изменений: {BOLD}{branch}{RESET} → {BOLD}{base}{RESET}")
    lines.append(f"{GREEN}{sep}{RESET}" if color else sep)
    lines.append("")

    if not commits:
        lines.append("Нет новых коммитов относительно {base}.")
        return '\n'.join(lines)

    lines.append("Коммиты (" + str(len(commits)) + "):")
    for c in commits:
        cat = categorize_commit(c['message'])
        lines.append(f"  [{YELLOW}{c['hash']}{RESET}] {c['message']}")
    lines.append("")

    # --- Группировка ---
    lines.append("Типы изменений:")
    by_category = defaultdict(list)
    for c in commits:
        cat = categorize_commit(c['message'])
        by_category[cat].append(c)
    for cat, items in sorted(by_category.items(), key=lambda x: -len(x[1])):
        lines.append(f"  • {cat}: {len(items)}")
    lines.append("")

    # --- Статистика ---
    files = get_changed_files(base, head)
    added, removed = get_diff_stats(base, head)
    authors = set(c['author'] for c in commits)
    lines.append("Статистика:")
    lines.append(f"  • Коммитов:  {len(commits)}")
    lines.append(f"  • Авторов:   {len(authors)}")
    lines.append(f"  • Файлов:    {len(files)}")
    lines.append(f"  • + строк:   {added}")
    lines.append(f"  • − строк:   {removed}")
    lines.append("")

    # --- Авторы ---
    lines.append("Авторы:")
    author_counts = defaultdict(int)
    for c in commits:
        author_counts[c['author']] += 1
    for author, count in sorted(author_counts.items(), key=lambda x: -x[1]):
        lines.append(f"  • {author} ({count})")
    lines.append("")

    # --- Файлы по модулям ---
    if files:
        lines.append("Файлы (по модулям):")
        by_module = defaultdict(int)
        for f in files:
            module = f.split('/')[0] if '/' in f else '(root)'
            by_module[module] += 1
        for module, count in sorted(by_module.items(), key=lambda x: -x[1]):
            lines.append(f"  [{CYAN}{module}{RESET}] {count} файлов")
        lines.append("")

    lines.append(f"{GREEN}{sep}{RESET}" if color else sep)
    lines.append(f"  Сводка сформирована {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append(f"{GREEN}{sep}{RESET}" if color else sep)
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='Формирует сводку изменений между ветками по коммитам.'
    )
    parser.add_argument(
        '--base', '-b',
        default='origin/master',
        help='Базовая ветка для сравнения (по умолчанию: origin/master)'
    )
    parser.add_argument(
        '--head', '-H',
        default='HEAD',
        help='Целевая ветка/коммит (по умолчанию: HEAD)'
    )
    parser.add_argument(
        '--output', '-o',
        default=None,
        help='Файл для сохранения отчёта (Markdown). Если не указан — вывод в консоль.'
    )
    parser.add_argument(
        '--no-color',
        action='store_true',
        help='Отключить цветной вывод в консоль'
    )
    args = parser.parse_args()

    # Определяем имя ветки
    branch = run_git('rev-parse', '--abbrev-ref', args.head)

    commits = get_commits(args.base, args.head)
    if not commits:
        print(f"Нет новых коммитов относительно {args.base}.")
        sys.exit(0)

    if args.output:
        # Markdown в файл
        report = format_markdown(commits, args.base, args.head, branch)
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        actual = os.path.abspath(args.output)
        print(f"Отчёт сохранён: {actual}")
    else:
        report = format_console(commits, args.base, args.head, branch, color=not args.no_color)
        print(report)


if __name__ == '__main__':
    import os
    main()