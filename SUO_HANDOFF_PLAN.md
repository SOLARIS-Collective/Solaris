# СУО — ХЭНДОФФ / ПЛАН (сессия 1)

## Цель
СУО (Система управления огнём, ship fire control) 3.0 для BYOND-кода Solaris.
Поток (вариант A): консоль + multitool + корабельное оружие. Игрок читает
`ship_weapon` мультитулом -> линкует к консоли `fire_control` -> оружие
инициализируется -> появляется UI -> цели -> огонь.

## Варианты боя
- **Вариант A (выбран первым):** FTL-style список целей + радиус + захват,
  урон броском/дайсом. Делаем его.
- **Вариант C (референс на потом):** локальная боевая карта, как в white-shiptest:
  `E:\GitRepo\___WHITE-SHIPTEST\white\valtos\code\exploration\super_cruise\weapons\`
  (shuttle_weapon.dm, weapon_controller.dm, weapons/{laser,missile,projectile,mapping}.dm,
  shuttle_projectile_spawner.dm, target_location_spell.dm, weapon_placer.dm).
  Там `map_view` камера, физические `obj/projectile`, клик по отсеку цели спеллом.

## ГИТ-состояние
- Ветка **`sys_ship_weapons`** была сломана (компиляция падала).
- Создана новая ветка **`sys_ship_weapons_v2` ОТ `master`** (master компилируется чисто, EXIT=0).
- Весь СУО-код перенесён на `sys_ship_weapons_v2` в **КОР-КОД** (НЕ в модульные папки).
- Файлы сейчас в git-индексе как `A` (staged, ещё НЕ закоммичены).

## Что перенесено на v2 (в кор-код)
- `code/modules/overmap/combat/`:
  - combat_system.dm
  - fire_control_console.dm
  - ship_weapon.dm
  - ship_projectile.dm
  - ship_damage_system.dm
  - ship_default_stats.dm
  - ship_integration.dm
  - examples.dm (admin-вербы; в .dme НЕ включён)
  - combat_event_manager.dm (рабочий event-менеджер; исправлен вызов через `call()`)
  - спрайты system_weapons.dmi, supercruise_weapons_long.dmi
  - доки README.md, IMPLEMENTATION_GUIDE.md, SPRITES_AND_ICONS.md
- `code/__DEFINES/ship_combat.dm` — все дефайны СУО. **Сюда же перенесены 9 макросов
  COMBAT_EVENT_* из модульного `~modular_mankind/combat_events.dm`** (тот удалён из git).
- `tgui/packages/tgui/interfaces/FireControl.tsx` — UI (ссылается на несуществующие
  поля connectionStatus/syncStatus/eventCount — надо починить/убрать).
- `update_ship_defines.py` — скрипт миграции defines (dev-инструмент).

## Скипнуто (НЕ СУО / сломано — не переносить)
- `modular_solaris/_omni_access` (сетка планет, SOLARIS_GRID) — отдельная сломанная подсистема.
- `modular_solaris/_public/__public.dm` + `modular_solaris/modular_solaris.dme` — дубль ic_autoemote.
- `misc_plating.dm`, `HelmConsole.js` — несвязанные косметические правки.

## Правки в .dme (уже сделаны на v2)
- `#include "code\__DEFINES\ship_combat.dm"` после `xyz\modular_defines.dm`.
- В секции overmap (после overmap_turf.dm) добавлен блок инклудов combat:
  combat_event_manager, combat_system, fire_control_console, ship_damage_system,
  ship_default_stats, ship_integration, ship_projectile, ship_weapon.
- `examples.dm` НЕ включён (как и в старой ветке).

## СТАТУС СБОРКИ
- **Билд компилируется: 0 ошибок (EXIT=0).**
- Единственная починка: в combat_event_manager.dm заменил `target.on_combat_event(event)`
  на `call(target, "on_combat_event")(event)` за `hascall`-гардом (BYOND: undefined proc).

## ИЗВЕСТНЫЕ БАГИ — ЧИНИТЬ (вариант A)
Из анализа перенесённого кода:
1. **`locate(weapon_ref)`** — `weapon_ref` это REF-строка типа `"#12345"`.
   Нужно `var/obj/machinery/ship_weapon/weapon = locate(text2num(weapon_ref)) in combat_system?.weapons`.
   Места: `fire_control_console.dm:393` и `:405`.
2. **`can_fire()`** в `ship_weapon.dm:168-191` — перезарядка и проверка дальности
   ЗАКОММЕНТИРОВАНЫ (тестовый режим). Вернуть: `if(world.time < next_fire_time) return FALSE`
   и проверку `distance > max_range`.
3. **Дубль `Initialize()`** для `/datum/overmap/ship` — в `ship_integration.dm` и
   `ship_default_stats.dm`. Проверить и убрать дубль (или объединить).
4. **Спам**: `message_admins` (fire_control_console.dm:153, :394), `LOG_SHIP_COMBAT`
   (в fire_control on_weapon_fired:263), `to_chat` DEBUG (fire_control_console.dm:352).
   Убрать/приглушить. Заголовок UI "СУО v2.1 [DEBUG]" -> нормальный.
5. **FireControl.tsx** — убрать фейковые поля connectionStatus/syncStatus/eventCount
   (нет StatusBridge/AutoUpdateController). Строить нормальный UI: вкладка
   "тактические цели" (отсеки), "оружие" (реальная перезарядка), журнал боя.

## ЧЕГО НЕ ХВАТАЕТ ДЛЯ ВАРИАНТА A (по замыслу пользователя)
- Сейчас `ship_weapon` и консоль **авто-линкуются** через `find_combat_system()`
  (поиск по `area/ship/mobile_port`). Пользователь хочет **ручной линк**: мультитул
  читает данные с `ship_weapon` -> игрок несёт данные -> крепит к консоли `fire_control`.
- Проверить, есть ли обработка `attackby` с мультитулом на `ship_weapon` (похоже НЕТ).
  Надо добавить: чтение данных (tech-инфо оружия) при использовании мультитула;
  механизм линковки к консоли (data_core / буфер консоли / target-reference).
- Docked/по planet/по outpost корабли НЕ должны быть целями; только overmap-видимые.
  (update_available_targets уже фильтрует по current_overmap и controlled_ships).

## Архитектура событий
- `combat_event_manager.dm` — pub/sub, подписчики с proc `on_combat_event(list)`.
  Сейчас подписчиков НЕТ (dead-ish). Сигнатуры notify_*/emit_event совпадают с вызовами
  в combat_system.dm. Решено ОСТАВИТЬ (компилируется, безвредно), но можно упростить
  в пользу вариант A, если мешает.

## Следующие шаги (вариант A)
1. Закоммитить перенесённое СУО на v2 (чистый коммит базы).
2. Починить баги 1-5 (см. выше).
3. Реализовать ручной линк: мультитул + ship_weapon + fire_control.
4. Реализовать полноценный variant A UI в FireControl.tsx.
5. Пересобрать и проверить.
6. Потом (отдельно) — вариант C по white-shiptest референсу.

## Команды
- Компиляция: `& "C:\Program Files (x86)\BYOND\bin\dm.exe" "shiptest.dme"`
  (ВНИМАНИЕ: компиляция ~2-4 мин; _compile_options предупреждает #warn про Build.cmd — это OK).
- Проверка веток/статуса: `git status --short`, `git branch`.
