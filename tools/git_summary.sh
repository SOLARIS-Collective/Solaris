#!/bin/bash
# tools/git_summary.sh
# Формирует краткую сводку по изменениям в ветке относительно master.
# Запускать из корня репозитория: bash tools/git_summary.sh
# Опционально: bash tools/git_summary.sh origin/beta-dev  (сравнить с другой веткой)

set -euo pipefail

BASE="${1:-origin/master}"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

echo "============================================"
echo "  Сводка изменений: $BRANCH → $BASE"
echo "============================================"
echo ""

# --- Список коммитов ---
COMMITS=$(git log --oneline --no-merges "$BASE..HEAD" 2>/dev/null)
if [ -z "$COMMITS" ]; then
    echo "❌ Нет новых коммитов относительно $BASE (или ветка не отличается)."
    exit 0
fi

echo "📋 Коммиты ($(echo "$COMMITS" | wc -l)):"
echo "$COMMITS" | while read -r line; do
    echo "  • $line"
done
echo ""

# --- Статистика ---
echo "📊 Статистика:"
echo "  Коммитов:  $(echo "$COMMITS" | wc -l)"
echo "  Авторов:   $(git shortlog -sn --no-merges "$BASE..HEAD" 2>/dev/null | wc -l)"
echo "  Файлов:    $(git diff --name-only "$BASE..HEAD" 2>/dev/null | wc -l)"
echo "  + строк:   $(git diff --shortstat "$BASE..HEAD" 2>/dev/null | grep -oP '\d+(?= insertion)' || echo 0)"
echo "  - строк:   $(git diff --shortstat "$BASE..HEAD" 2>/dev/null | grep -oP '\d+(?= deletion)'  || echo 0)"
echo ""

# --- Авторы ---
echo "👤 Авторы:"
git shortlog -sn --no-merges "$BASE..HEAD" 2>/dev/null | while read -r count author; do
    echo "  • $author ($count коммитов)"
done
echo ""

# --- Файлы по модулям ---
echo "📁 Изменённые файлы (по модулям):"
if git diff --name-only "$BASE..HEAD" 2>/dev/null | sort > /tmp/_summary_files_$$.txt; then
    awk -F/ '{print $1}' /tmp/_summary_files_$$.txt | sort | uniq -c | sort -rn | while read -r count module; do
        echo "  [$module] $count файлов"
    done
    echo ""
    echo "  Полный список:"
    while read -r f; do
        MODULE=$(echo "$f" | cut -d/ -f1)
        echo "    [$MODULE] $f"
    done < /tmp/_summary_files_$$.txt
    rm -f /tmp/_summary_files_$$.txt
fi
echo ""

# --- Типы изменений (по префиксам коммитов) ---
echo "🏷️  Типы изменений:"
if git log --format="%s" --no-merges "$BASE..HEAD" 2>/dev/null > /tmp/_summary_msgs_$$.txt; then
    declare -A types=(
        ["^[Ff][Ii][Xx]"]="🐛 Исправления"
        ["^[Aa][Dd][Dd]"]="➕ Новое"
        ["^[Tt][Ww][Ee][Aa][Kk]"]="🔧 Доработки"
        ["^[Rr][Ee][Ff][Aa][Cc][Tt][Oo][Rr]"]="♻️ Рефакторинг"
        ["^[Bb][Aa][Ll][Aa][Nn][Cc][Ee]"]="⚖️ Баланс"
        ["^[Mm][Aa][Pp]"]="🗺️ Карты"
        ["^[Qq][Oo][Ll]"]="✨ QoL"
        ["^[Cc][Oo][Nn][Ff][Ii][Gg]"]="⚙️ Конфиг"
        ["^[Ss][Oo][Uu][Nn][Dd]"]="🔊 Звук"
        ["^[Ii][Mm][Aa][Gg][Ee]"]="🖼️ Изображения"
        ["^[Aa][Dd][Mm][Ii][Nn]"]="🛠️ Админ"
        ["^[Ss][Ee][Rr][Vv][Ee][Rr]"]="🖥️ Сервер"
        ["^[Cc][Hh][Ee][Rr][Rr][Yy][Pp][Ii][Cc][Kk]"]="🍒 Cherry-pick"
    )
    for pattern in "${!types[@]}"; do
        count=$(grep -ciE "$pattern" /tmp/_summary_msgs_$$.txt 2>/dev/null || echo 0)
        if [ "$count" -gt 0 ]; then
            echo "  ${types[$pattern]}: $count"
        fi
    done
    rm -f /tmp/_summary_msgs_$$.txt
fi
echo ""

echo "============================================"
echo "  Сводка сформирована $(date '+%Y-%m-%d %H:%M')"
echo "============================================"