#!/usr/bin/env bash
# Готовит скелет приватного модуля (_omni_access) для сборки БЕЗ сабмодуля (CI).
#
# Что делает:
#   1. Создаёт заглушку __private.dme.
#   2. Копирует публичных двойников по манифесту tools/ci/private_stubs.txt.
#   3. Проверяет, что все включения _omni_access в *.dme покрыты манифестом —
#      забыли строку => падение с явным сообщением.
#
# Если настоящий сабмодуль уже на месте (.git существует) — ничего не трогает.
#
# Новый приватный файл в shiptest.dme => добавьте строку в private_stubs.txt:
#   <путь внутри _omni_access>|<публичный оригинал от корня репо>

set -euo pipefail
cd "$(dirname "$0")/../.."

PRIVATE_DIR="modular_solaris/_omni_access"
MANIFEST="tools/ci/private_stubs.txt"

if [ -e "$PRIVATE_DIR/.git" ]; then
	echo "private_stubs: сабмодуль присутствует, скелет не нужен — пропуск."
	exit 0
fi

mkdir -p "$PRIVATE_DIR"
printf '// Приватный модуль исключён из CI-сборки\n' > "$PRIVATE_DIR/__private.dme"

while IFS='|' read -r private_path public_path; do
	private_path="$(echo "$private_path" | sed 's/[[:space:]]//g')"
	[ -z "$private_path" ] && continue
	case "$private_path" in '#'*) continue ;; esac
	public_path="$(echo "$public_path" | sed 's/[[:space:]]//g')"
	if [ ! -f "$public_path" ]; then
		echo "private_stubs: публичный двойник не найден: $public_path" >&2
		exit 1
	fi
	mkdir -p "$(dirname "$private_path")"
	cp "$public_path" "$private_path"
	echo "private_stubs: $public_path -> $private_path"
done < "$MANIFEST"

# Автопроверка: каждое включение _omni_access в *.dme должно быть __private.dme
# или присутствовать в манифесте.
uncovered=$(grep -rhoi '^[[:space:]]*#[[:space:]]*include[[:space:]]*"[^"]*_omni_access[^"]*"' --include='*.dme' . \
	| sed -E 's/.*"(.*)".*/\1/; s|\\|/|g' \
	| grep -v '__private\.dme$' \
	| sort -u \
	| while IFS= read -r inc; do
		case "$inc" in
			modular_solaris/_omni_access/*) ;;
			*) inc="modular_solaris/$inc" ;;
		esac
		cut -d'|' -f1 "$MANIFEST" | sed 's/[[:space:]]//g' | grep -v '^#' | grep -v '^$' | grep -Fxq "$inc" || echo "$inc"
	done)

if [ -n "$uncovered" ]; then
	echo "private_stubs: включения приватного модуля без строки в $MANIFEST:" >&2
	echo "$uncovered" >&2
	exit 1
fi

echo "private_stubs: OK"
