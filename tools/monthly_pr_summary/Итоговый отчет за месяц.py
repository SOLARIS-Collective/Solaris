#!/usr/bin/env python3
"""
tools/monthly_pr_summary/Итоговый отчет за месяц.py

Формирует ежемесячную сводку коммитов, попавших в ветку master (или другую
указанную ветку). Коммиты группируются по дням, внутри дня — по категориям,
определяемым ключом в квадратных скобках в начале сообщения коммита
(например [FIX], [TWEAK]). Категории берутся из categories.yml.

Скрипт использует только стандартную библиотеку Python 3.9+ (никаких pip-
зависимостей): запросы к GitHub REST API выполняются через urllib.

Использование:
    python "tools/monthly_pr_summary/Итоговый отчет за месяц.py"
    python "tools/monthly_pr_summary/Итоговый отчет за месяц.py" --year 2026 --month 7
    python "tools/monthly_pr_summary/Итоговый отчет за месяц.py" --branch master --output-dir html/changelogs/monthly

Ожидаемые переменные окружения:
    GITHUB_REPOSITORY: "owner/repo"
    GITHUB_TOKEN:      токен с правами чтения репозитория (для приватных
                       репозиториев обязателен; для публичных можно опустить,
                       но действуют лимиты неавторизованных запросов)

Выходные файлы (в output-dir):
    YYYY-MM.yml  — структурированная сводка (для показа в игре)
    YYYY-MM.md   — человекочитаемая сводка
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict
from datetime import datetime, timezone

API_ROOT = "https://api.github.com"

# Ключ в квадратных скобках в начале сообщения коммита, например [FIX] или [EMERGENCY FIX].
# Разрешаем буквы, цифры, пробелы, подчёркивание и двоеточие внутри скобок.
KEY_RE = re.compile(r"^\s*\[([A-ZА-Я0-9_ :]+)\]\s*", re.IGNORECASE)

# Merge-коммиты ("Merge pull request #...", "Merge branch ...") не несут
# содержательной информации — по умолчанию исключаем их из сводки.
MERGE_MESSAGE_RE = re.compile(r"^Merge\s+", re.IGNORECASE)


# ---------------------------------------------------------------------------
# Мини-парсер YAML для конфига категорий.
#
# categories.yml использует простое подмножество YAML (плоский mapping +
# последовательность одноуровневых mapping'ов), поэтому обходимся без
# внешних библиотек. Строки в двойных кавычках поддерживают экранирование \" и \\.
# ---------------------------------------------------------------------------

def _yaml_strip_comment(line):
    """Убрать комментарий вне двойных кавычек."""
    in_quotes = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_quotes = not in_quotes
        elif ch == "#" and not in_quotes:
            return line[:i]
    return line


def _yaml_scalar(text):
    """Разобрать скаляр: строка в кавычках или голое слово."""
    text = text.strip()
    if text.startswith('"') and text.endswith('"') and len(text) >= 2:
        body = text[1:-1]
        return (
            body.replace('\\"', '"')
                .replace("\\\\", "\\")
        )
    return text


def _yaml_tokens(path):
    """Прочитать файл и вернуть список (отступ, содержимое) значимых строк."""
    tokens = []
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = _yaml_strip_comment(raw).rstrip()
            if not line.strip():
                continue
            indent = len(line) - len(line.lstrip(" "))
            tokens.append((indent, line.strip()))
    return tokens


def _yaml_parse_mapping(tokens, pos, indent):
    result = OrderedDict()
    while pos < len(tokens):
        tok_indent, text = tokens[pos]
        if tok_indent < indent or text.startswith("- "):
            break
        if tok_indent > indent:
            raise ValueError(f"Неожиданный отступ у строки: {text!r}")
        key_part, sep, value_part = text.partition(":")
        if not sep:
            raise ValueError(f"Ожидалось 'ключ: значение', получено: {text!r}")
        key = _yaml_scalar(key_part)
        value_part = value_part.strip()
        if value_part:
            result[key] = _yaml_scalar(value_part)
            pos += 1
        else:
            pos += 1
            if pos < len(tokens) and tokens[pos][1].startswith("- "):
                seq, pos = _yaml_parse_sequence(tokens, pos, tokens[pos][0])
                result[key] = seq
            elif pos < len(tokens) and tokens[pos][0] > indent:
                sub, pos = _yaml_parse_mapping(tokens, pos, tokens[pos][0])
                result[key] = sub
            else:
                result[key] = None
    return result, pos


def _yaml_parse_sequence(tokens, pos, indent):
    items = []
    while pos < len(tokens):
        tok_indent, text = tokens[pos]
        if tok_indent != indent or not text.startswith("- "):
            break
        item_text = text[2:].strip()
        key_part, sep, value_part = item_text.partition(":")
        if not sep:
            raise ValueError(f"Ожидался элемент 'ключ: значение', получено: {text!r}")
        item = OrderedDict()
        item[_yaml_scalar(key_part)] = _yaml_scalar(value_part.strip())
        pos += 1
        while pos < len(tokens) and tokens[pos][0] > indent and not tokens[pos][1].startswith("- "):
            sub, pos = _yaml_parse_mapping(tokens, pos, tokens[pos][0])
            item.update(sub)
        items.append(item)
    return items, pos


def load_categories(config_path):
    """Загрузить конфиг категорий и вернуть (key -> category, default_category)."""
    tokens = _yaml_tokens(config_path)
    data, _ = _yaml_parse_mapping(tokens, 0, tokens[0][0])

    default_category = data.get("default_category") or "Прочее"

    # key (в верхнем регистре) -> category, сохраняя порядок появления
    key_to_category = OrderedDict()
    for entry in data.get("categories") or []:
        key = str(entry["key"]).strip().upper()
        key_to_category.setdefault(key, entry["category"])

    return key_to_category, default_category


# ---------------------------------------------------------------------------
# GitHub REST API
# ---------------------------------------------------------------------------

def _github_get(url, token):
    request = urllib.request.Request(url)
    request.add_header("Accept", "application/vnd.github+json")
    request.add_header("X-GitHub-Api-Version", "2022-11-28")
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        hint = {
            401: "проверьте GITHUB_TOKEN",
            403: "возможно, исчерпан лимит запросов к API",
            404: "репозиторий не найден или нет доступа (для приватного репозитория нужен GITHUB_TOKEN)",
        }.get(exc.code, "")
        print(f"Ошибка HTTP {exc.code} при запросе {url}. {hint}\n{details}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as exc:
        print(f"Ошибка сети при запросе {url}: {exc.reason}", file=sys.stderr)
        sys.exit(1)


def month_range(year, month):
    """Вернуть (start, end) — datetime начала и конца месяца (end исключается), UTC."""
    start = datetime(year, month, 1, tzinfo=timezone.utc)
    if month == 12:
        end = datetime(year + 1, 1, 1, tzinfo=timezone.utc)
    else:
        end = datetime(year, month + 1, 1, tzinfo=timezone.utc)
    return start, end


def fetch_branch_commits(repo_name, branch, start, end, token, include_merges=False):
    """Вернуть коммиты ветки за период [start, end), старые первыми.

    Каждый коммит — dict из GitHub API (см. /repos/{owner}/{repo}/commits).
    """
    commits = []
    page = 1
    base_url = (
        f"{API_ROOT}/repos/{urllib.parse.quote(repo_name)}/commits"
        f"?sha={urllib.parse.quote(branch)}"
        f"&since={urllib.parse.quote(start.isoformat())}"
        f"&until={urllib.parse.quote(end.isoformat())}"
        f"&per_page=100"
    )
    while True:
        batch = _github_get(f"{base_url}&page={page}", token)
        if not batch:
            break
        commits.extend(batch)
        if len(batch) < 100:
            break
        page += 1

    result = [
        commit for commit in commits
        if include_merges or not MERGE_MESSAGE_RE.match(_commit_message(commit))
    ]
    result.sort(key=lambda commit: commit["commit"]["committer"]["date"])
    return result


def _commit_message(commit):
    return commit.get("commit", {}).get("message") or ""


def commit_title(commit):
    """Первая строка сообщения коммита."""
    lines = _commit_message(commit).splitlines()
    return lines[0].strip() if lines else ""


def commit_author(commit):
    """Логин GitHub-автора, при недоступности — git-имя автора."""
    login = (commit.get("author") or {}).get("login")
    if login:
        return login
    name = (commit.get("commit", {}).get("author") or {}).get("name")
    return name or "unknown"


# ---------------------------------------------------------------------------
# Формирование сводки
# ---------------------------------------------------------------------------

def categorize(title, key_to_category, default_category):
    """Вернуть (category, clean_title) для первой строки сообщения коммита.

    Берётся первый ключ в квадратных скобках слева направо. Если ключ не
    распознан или отсутствует — категория default_category.
    """
    match = KEY_RE.match(title)
    if not match:
        return default_category, title.strip()

    key = match.group(1).strip().upper()
    category = key_to_category.get(key, default_category)
    clean_title = title[match.end():].strip()
    return category, clean_title


def build_summary(commits, key_to_category, default_category):
    """Сгруппировать коммиты по дням, внутри дня — по категориям."""
    days = OrderedDict()
    for commit in commits:
        day = commit["commit"]["committer"]["date"][:10]
        category, clean_title = categorize(commit_title(commit), key_to_category, default_category)
        days.setdefault(day, OrderedDict()).setdefault(category, []).append({
            "sha": commit["sha"][:7],
            "title": clean_title,
            "author": commit_author(commit),
        })
    return days


def write_yaml(days, path):
    def q(value):
        # JSON-строки являются корректными скалярами YAML
        return json.dumps(value, ensure_ascii=False)

    lines = []
    for day, categories in days.items():
        lines.append(f"{q(day)}:")
        for category, items in categories.items():
            lines.append(f"  {q(category)}:")
            for item in items:
                lines.append(f"  - sha: {q(item['sha'])}")
                lines.append(f"    title: {q(item['title'])}")
                lines.append(f"    author: {q(item['author'])}")
    with open(path, "w", encoding="utf-8-sig") as f:
        f.write("\n".join(lines) + "\n")


def write_markdown(days, year, month, branch, path):
    total = sum(len(items) for categories in days.values() for items in categories.values())
    lines = [
        f"# Коммиты `{branch}` за {year:04d}-{month:02d}",
        "",
        f"Всего коммитов: {total}",
        "",
    ]
    for day, categories in days.items():
        day_total = sum(len(items) for items in categories.values())
        lines.append(f"## {day} ({day_total})")
        lines.append("")
        for category, items in categories.items():
            lines.append(f"### {category}")
            lines.append("")
            for item in items:
                lines.append(f"- `{item['sha']}` — {item['title']} (@{item['author']})")
            lines.append("")
    # utf-8-sig (с BOM) — чтобы кириллица корректно открывалась в Блокноте и PowerShell
    with open(path, "w", encoding="utf-8-sig") as f:
        f.write("\n".join(lines))


# ---------------------------------------------------------------------------
# Точка входа
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Ежемесячная сводка коммитов ветки по ключам в сообщениях")
    parser.add_argument("--year", type=int, default=None, help="Год (по умолчанию текущий)")
    parser.add_argument("--month", type=int, default=None, help="Месяц 1-12 (по умолчанию текущий)")
    parser.add_argument("--branch", default="master", help="Ветка для сканирования (по умолчанию master)")
    parser.add_argument("--include-merges", action="store_true",
                        help="Включать merge-коммиты в сводку")
    parser.add_argument("--output-dir", default="html/changelogs/monthly",
                        help="Каталог для выходных файлов")
    parser.add_argument("--config", default=os.path.join(os.path.dirname(__file__), "categories.yml"),
                        help="Путь к конфигу категорий")
    args = parser.parse_args()

    now = datetime.now(timezone.utc)
    year = args.year if args.year is not None else now.year
    month = args.month if args.month is not None else now.month

    if not 1 <= month <= 12:
        print(f"Ошибка: месяц должен быть в диапазоне 1-12, получено {month}", file=sys.stderr)
        sys.exit(1)

    repo_name = os.getenv("GITHUB_REPOSITORY")
    token = os.getenv("GITHUB_TOKEN")
    if not repo_name:
        print("Ошибка: требуется переменная окружения GITHUB_REPOSITORY",
              file=sys.stderr)
        sys.exit(1)
    if not token:
        print("Предупреждение: GITHUB_TOKEN не задан, запросы пойдут без авторизации "
              "(лимит 60 запросов/час; для приватного репозитория токен обязателен)",
              file=sys.stderr)

    key_to_category, default_category = load_categories(args.config)
    start, end = month_range(year, month)

    print(f"Собираю коммиты ветки {args.branch} за {year:04d}-{month:02d} из {repo_name}...")
    commits = fetch_branch_commits(repo_name, args.branch, start, end, token, args.include_merges)
    print(f"Найдено коммитов: {len(commits)}")

    days = build_summary(commits, key_to_category, default_category)

    os.makedirs(args.output_dir, exist_ok=True)
    yaml_path = os.path.join(args.output_dir, f"{year:04d}-{month:02d}.yml")
    md_path = os.path.join(args.output_dir, f"{year:04d}-{month:02d}.md")

    write_yaml(days, yaml_path)
    write_markdown(days, year, month, args.branch, md_path)

    print(f"Записано: {yaml_path}")
    print(f"Записано: {md_path}")


if __name__ == "__main__":
    main()
