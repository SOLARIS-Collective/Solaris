#!/usr/bin/env python3
"""
tools/monthly_pr_summary/generate_monthly_summary.py

Формирует ежемесячную сводку смерженных PR по ключам в квадратных скобках
в названиях PR (например [FIXES], [TWEAK]).

Использование:
    python tools/monthly_pr_summary/generate_monthly_summary.py
    python tools/monthly_pr_summary/generate_monthly_summary.py --year 2026 --month 4
    python tools/monthly_pr_summary/generate_monthly_summary.py --output-dir html/changelogs/monthly

Ожидаемые переменные окружения:
    GITHUB_REPOSITORY: "owner/repo" (Action provided)
    GITHUB_TOKEN:      токен с правами чтения PR (Action provided)

Выходные файлы (в output-dir):
    YYYY-MM.yml  — структурированная сводка (для показа в игре)
    YYYY-MM.md   — человекочитаемая сводка
"""

import argparse
import calendar
import os
import re
import sys
from collections import OrderedDict
from datetime import datetime

import yaml
from github import Github

# Ключ в квадратных скобках в начале названия PR, например [FIXES] или [EMERGENCY FIX].
# Разрешаем буквы, цифры, пробелы, подчёркивание и двоеточие внутри скобок.
KEY_RE = re.compile(r"^\s*\[([A-ZА-Я0-9_ :]+)\]\s*", re.IGNORECASE)


def load_categories(config_path):
    """Загрузить конфиг категорий и вернуть (список категорий, default_category)."""
    with open(config_path, encoding="utf-8") as f:
        data = yaml.safe_load(f)

    default_category = data.get("default_category", "Прочее")

    # key (в верхнем регистре) -> category, сохраняя порядок появления
    key_to_category = OrderedDict()
    for entry in data.get("categories", []):
        key = str(entry["key"]).strip().upper()
        key_to_category.setdefault(key, entry["category"])

    return key_to_category, default_category


def categorize(title, key_to_category, default_category):
    """Вернуть (category, clean_title) для названия PR.

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


def month_range(year, month):
    """Вернуть (start, end) — datetime начала и конца месяца (end исключается)."""
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    return start, end


def fetch_merged_prs(repo, start, end):
    """Вернуть список смерженных PR за период [start, end)."""
    prs = []
    for pr in repo.get_pulls(state="closed", sort="updated", direction="desc"):
        if pr.merged_at is None:
            continue
        merged = pr.merged_at.replace(tzinfo=None)
        if merged < start:
            # PR отсортированы по updated по убыванию; merged_at близок к updated,
            # поэтому при выходе за нижнюю границу можно остановиться.
            break
        if start <= merged < end:
            prs.append(pr)
    return prs


def build_summary(prs, key_to_category, default_category):
    """Сгруппировать PR по категориям в порядке появления в конфиге."""
    grouped = OrderedDict()
    for pr in prs:
        category, clean_title = categorize(pr.title, key_to_category, default_category)
        grouped.setdefault(category, []).append({
            "number": pr.number,
            "title": clean_title,
            "author": pr.user.login if pr.user else "unknown",
            "merged_at": pr.merged_at.strftime("%Y-%m-%d") if pr.merged_at else "",
        })
    return grouped


def write_yaml(grouped, path):
    # safe_dump не умеет сериализовать OrderedDict, поэтому конвертируем в обычный dict
    plain = {category: items for category, items in grouped.items()}
    with open(path, "w", encoding="utf-8") as f:
        yaml.safe_dump(plain, f, allow_unicode=True, sort_keys=False, default_flow_style=False)


def write_markdown(grouped, year, month, path):
    lines = [
        f"# Сводка PR за {year:04d}-{month:02d}",
        "",
    ]
    total = sum(len(items) for items in grouped.values())
    lines.append(f"Всего PR: {total}")
    lines.append("")
    for category, items in grouped.items():
        lines.append(f"## {category} ({len(items)})")
        lines.append("")
        for item in items:
            lines.append(f"- #{item['number']} — {item['title']} (@{item['author']})")
        lines.append("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description="Ежемесячная сводка PR по ключам в названиях")
    parser.add_argument("--year", type=int, default=None, help="Год (по умолчанию текущий)")
    parser.add_argument("--month", type=int, default=None, help="Месяц 1-12 (по умолчанию текущий)")
    parser.add_argument("--output-dir", default="html/changelogs/monthly",
                        help="Каталог для выходных файлов")
    parser.add_argument("--config", default=os.path.join(os.path.dirname(__file__), "categories.yml"),
                        help="Путь к конфигу категорий")
    args = parser.parse_args()

    now = datetime.now()
    year = args.year if args.year is not None else now.year
    month = args.month if args.month is not None else now.month

    if not 1 <= month <= 12:
        print(f"Ошибка: месяц должен быть в диапазоне 1-12, получено {month}", file=sys.stderr)
        sys.exit(1)

    repo_name = os.getenv("GITHUB_REPOSITORY")
    token = os.getenv("GITHUB_TOKEN")
    if not repo_name or not token:
        print("Ошибка: требуются переменные окружения GITHUB_REPOSITORY и GITHUB_TOKEN",
              file=sys.stderr)
        sys.exit(1)

    key_to_category, default_category = load_categories(args.config)
    start, end = month_range(year, month)

    print(f"Собираю смерженные PR за {year:04d}-{month:02d} из {repo_name}...")
    gh = Github(token)
    repo = gh.get_repo(repo_name)
    prs = fetch_merged_prs(repo, start, end)
    print(f"Найдено PR: {len(prs)}")

    grouped = build_summary(prs, key_to_category, default_category)

    os.makedirs(args.output_dir, exist_ok=True)
    yaml_path = os.path.join(args.output_dir, f"{year:04d}-{month:02d}.yml")
    md_path = os.path.join(args.output_dir, f"{year:04d}-{month:02d}.md")

    write_yaml(grouped, yaml_path)
    write_markdown(grouped, year, month, md_path)

    print(f"Записано: {yaml_path}")
    print(f"Записано: {md_path}")


if __name__ == "__main__":
    main()
