# СУО — сессия 2: статус, заметки совы, хендофф по бэкенду

> Этот документ — продолжение `SUO_HANDOFF_PLAN.md` (сессия 1). Здесь: что сделано во 2-й
> сессии, что работает/не работает/сломано, оставшиеся задачи и **полный хендофф по каждому
> сомнительному месту в бэкенде корабельного боя с овермапом**, чтобы можно было писать
> интерфейс/бехенд без поштучного гайда.

---

## 1. ОБЩИЙ СТАТУС

- Ветка: **`sys_ship_weapons_v2`** (форк Solaris, SS13/Shiptest).
- Сборка: `dm.exe -max_errors 50 shiptest.dme` → **0 ошибок**.
- tgui: `yarn tgui:build` в `tgui/` → **успешно** (webpack). Команд `yarn tgui:typecheck`/`yarn tsp` НЕТ.
- ОС/шелл: win32, PowerShell 5.1. `&&` не работает — использовать `; if ($?) { ... }`.
- Всё сосредоточено в `code/modules/overmap/combat/*` + `code/__DEFINES/ship_combat.dm` + UI `tgui/.../FireControl.tsx`.

### ГИТ-состояние (важно!)
- Папка `code/modules/overmap/combat/*` **в `.gitignore`** (строка 213: `/code/modules/overmap/combat/*`)
  → файлы **untracked, НЕ коммитятся**. Чтобы закоммитить — надо временно убрать/закомментировать
  эту строку или `git add -f`.
- `tgui/packages/tgui/interfaces/FireControl.tsx` — `??` (untracked, ещё не в индексе).
- `SUO_HANDOFF_PLAN.md`, `fire_control_console.dm`, `ship_combat.dm` — untracked.
- Много `.dme`/прочих файлов в `M` (модифицированы/переведены на CRLF или другим пользователем) — НЕ трогать без задачи.

---

## 2. ЧТО СДЕЛАНО ЗА СЕССИЮ 2 (в хронологии)

### 2.1 Починка «пустой ARPA» (список целей)
- Переписан `update_available_targets()` и `select_target_manual()`: **раньше итерировали только
  `SSovermap.controlled_ships`** → корабли, которых нет в этом списке (NPC-шипы и т.п.), не
  появлялись. Теперь итерируют **все `/datum/overmap/ship`** через скан `overmap_container`.
- Добавлен общий хелпер `get_nearby_ships()` (один источник истины для списка и карты).
- `find_ship_by_ref()` тоже переведён на `get_nearby_ships()`.
- Добавлена обфускация имён через `get_known_ship_name()` («Неизвестный корабль»).

### 2.2 Починка «невозможно открыть огонь»
- `locate(text2num(weapon_ref))` возвращал null → исправлено на `locate(weapon_ref)`
  (в `fire_weapon`/`repair_weapon`-обработчиках и везде где был этот паттерн).

### 2.3 Починка «пушки не заряжаются»
- Сигнатуры `process()` не принимали `seconds_per_tick` → исправлено у
  `combat_system`, `ship_weapon`, `fire_control_console` (DM кидает ошибку, если тип
  подписан на SS-процесс не с той сигнатурой).

### 2.4 Auto-reopen UI bug
- Причина: у FCS не было `obj_flags |= USES_TGUI`, поэтому `updateUsrDialog()` переоткрывала
  закрытое окно при сканировании каждые N секунд.
- Фикс: `USES_TGUI` в `Initialize()` + замена `updateUsrDialog()` на `SStgui.update_uis(src)`.

### 2.5 Гистерезис захвата (A2)
- `get_engagement_range()` вертает `default_sensor_range` (small: 2-8, дефолт 4). Мгновенный
  дроп при выходе за границу → добавлены vars `out_of_range_since`/`lock_loss_range_cooldown`
  (3 сек) в `combat_system.dm`; `process_target_lock()` дропает захват только после непрерывного
  out-of-range 3 сек, иначе сбрасывает счётчик.

### 2.6 «Снаряд промахивается и исчезает мгновенно»
- `near_miss()`/`miss()` → `process_hit(src, FALSE)` → мгновенный `qdel`.
- Исправлено: режим **overshoot** (полёт мимо цели ~1.5 сек, потом исчезновение).
- В `ship_projectile.dm`: vars `overshooting`, `overshoot_finish_time`, `overshoot_duration`,
  `overshoot_vel_x/y`; `check_hit()` для промахов → `begin_overshoot()`; `process_flight()` в
  overshoot-режиме двигает мимо цели и по таймауту зовёт `resolve_miss()`. Клиент: `p` clamp до 1.4.

### 2.7 UI-правки
- Убраны «узлы» (knots) из отображения скорости.
- Тактическая карта увеличена (W 940→960, H 260→470, P 34→48, DOT 26→34).
- Свой корабль по центру: `sy = H * 0.72` → `H / 2`.
- Имена кораблей на карте обфусцированы через `get_known_ship_name()`.
- Кинетическая пушка замедлена в 10×: `projectile_speed = 0.5` (было унаследовано 5).

### 2.8 Сессия 2 финал (последний запрос пользователя)
1. **Тактическая карта рисуется ВСЕГДА** (уберён ранний `return` при отсутствии цели).
2. **Список захвата = все `/datum/overmap/ship`** через `get_nearby_ships()` (не только controlled).
3. **Сетка → радиальные кольца** (`RING_FRACTIONS` + крест прицела), `radarR` от реального радиуса.
4. **Автообновление списка**: `target_scan_interval` 5→2 сек; `select_target`/`lock_target` переведены
   с `/datum/overmap/ship/controlled` на `/datum/overmap/ship` (иначе NPC-цель = рантайм типизации).
5. **Корабли на карте = серые квадратики** (`ship`/`npc_ship` → `markerVisual` gray square).
6. **Фон монотонный тёмно-синий** `rgba(6,18,40,0.95)`.
7. **Раскладка**: вооружение списком СБОКУ от тактической схемы (grow3/grow2, окно 1200×880);
   блок «Время полёта снарядов» перенесён ВО ВНУТРЬ секции «Вооружение»; отдельный `ProjectilesSection` удалён.

---

## 3. ЧТО РАБОТАЕТ / НЕ РАБОТАЕТ / СЛОМАНО (по состоянию на конец сессии 2)

### Работает (проверено компиляцией + логикой, НЕ на живом сервере)
- DM-компиляция 0 ошибок, tgui build успешно.
- Формирование списка целей из всех шипов в радиусе (сканирование `overmap_container`).
- Поиск цели по ref; `locate(ref)`-резолв оружия.
- Сигнатуры `process(seconds_per_tick)` — корректны (без рантайма подписки).
- Гистерезис захвата (не теряется мгновенно на границе радиуса).
- Overshoot-режим снарядов (промах ≠ мгновенное исчезновение).
- Тактическая карта: рисуется всегда, радиальные кольца, серые квадратики кораблей, dark-blue фон.
- Раскладка: вооружение сбоку, время полёта внутри вооружения.

### НЕ проверено на живом сервере (надо прогнать руками)
- Поведение самого захвата (`acquire_target` → `process_target_lock` → `SHIP_TARGET_LOCK_LOCKED`).
- Стрельбы реальные (урон, попадания по отсекам).
- Живое обновление ARPA-списка в окне (зависит от tgui-пуша; теоретически работает через
  `process()` каждые 2 сек + `get_ui_data()` на каждом запросе).

### Сломанные / сомнительные места (см. раздел 6 — разбор каждого)
1. **DM-сборка в песочнице падает по env**: `BUG: shiptest.rsc is locked up!` +
   `icemoon.dm:5:error: '.../snow.dmi' cannot find file`. Файл `snow.dmi` ЕСТЬ на диске
   (`Test-Path`=True), ошибка из-за блокировки `shiptest.rsc` средой (AV/фоновый процесс), НЕ из-за
   кода. `dm.exe` заново выдаёт блокировку при первой компиляции. Это **не баг кода**.
2. **Несколько мест кастуют `target`/`projectile.target` в `/datum/overmap/ship/controlled`**
   (combat_system.dm:204,220,446; ship_projectile.dm:195,395) — если цель NPC (не controlled),
   будет рантайм. Гарды-`istype` местами есть, местами нет.
3. **`get_known_ship_name()` ожидает controlled-цель** — в коде обфускация контролируется
   `istype(.../controlled)`, но бэкенд для NPC может падать в ряде proc.
4. **`combatSystem.target`** используется в `get_ui_data()`/weapons-инфо без проверки типа.

---

## 4. АРХИТЕКТУРА ОВЕРМАПА (база для доверия к бэкенду)

### 4.1 Овермап-модель
- Базовый `/datum/overmap` в `code/modules/overmap/_overmap_datum.dm`. Поля:
  `x`, `y` (целые, 1..system.size), `name`, `token_icon_state`, `current_overmap`,
  `overmap_container`, `contents` (пристыкованные), `get_nearby_overmap_objects()`.
- Подтипы (все подтверждены grep'ом):
  - `/datum/overmap/star`
  - `/datum/overmap/ship` (и его `/datum/overmap/ship/controlled`)
  - `/datum/overmap/static_object`
  - `/datum/overmap/dynamic`
  - `/datum/overmap/event`
  - `/datum/overmap/jump_point`
  - `/datum/overmap/outpost`
- Система: `current_overmap` = `/datum/overmap_star_system` с полями `size`, `overmap_container`.
- Сетка: `system.overmap_container[x][y]` — ячейка = `null` / одиночный `/datum/overmap` / `list` из них.
- Иконка токена = `token_icon_state` (обычно `"signal_none"`), но **tgui рисует DOM/CSS, не .dmi**:
  клиент классифицирует тип маркера через `type` из бэкенда и рисует CSS-фигуры.

### 4.2 Скан сетки — ПАТТЕРН, который надо знать
`get_nearby_overmap_objects()` и `check_proximity()` (ship_datum.dm:154) сканируют квадрат
радиуса `default_sensor_range` с **заворачиванием по краям сетки** и проходом по `.contents`
пристыкованных. Этот же паттерн скопирован в:
- `get_tactical_map_data()` (маркеры карты),
- `get_nearby_ships()` (список захвата).

**Важно про проход по клеткам:**
```dm
var/check_x = ((our_ship.x + dx - 1) % size) + 1
if(check_x < 1) check_x += size   // заворот по краю
var/cell = container[check_x][check_y]
var/list/queue = list()
if(islist(cell)) queue += cell
else if(istype(cell, /datum/overmap)) queue += cell
while(length(queue))
    var/datum/overmap/O = queue[length(queue)]
    queue.len--
    if(QDELETED(O) || O == our_ship || seen[REF(O)]) continue
    seen[REF(O)] = TRUE
    ... фильтры ...
    if(length(O.contents)) queue += O.contents
```
- **Каждая ячейка** = либо одиночный объект, либо лист (несколько объектов на клетке). Всегда
  обрабатывай `islist`-случай.
- Скан квадратный → углы дальше по евклиду, чем по радиусу. Поэтому после скан-фильтра по сетке
  нужен дополнительный евклидов фильтр `get_overmap_distance(...) <= radius`.

### 4.3 Расстояние/время полёта
- `get_overmap_distance(ship, target)` — евклидово по `x/y`.
- `get_engagement_range()` = `default_sensor_range` (small 2-8, дефолт 4). Основа для ARPA и карты.
- `calculate_flight_time = (distance / projectile_speed) * 1 SECONDS`, затем `* (1 + target_speed/100)`
  если цель движется. (combat_system.dm:293-306)

### 4.4 escalation/связь консоли и системы боя
- `fire_control_console` (FCS) → `combat_system` (datum/ship_combat_system).
- Линк: `find_combat_system()` (по `ship_name_override` или по `area.mobile_port`).
- `combat_system.ship` = `/datum/overmap/ship/controlled` (наш корабль).
- Оружие: `combat_system.weapons` (лист `/obj/machinery/ship_weapon`); `initialize_weapons()`.
- Снаряды: `combat_system.active_projectiles` (лист `/obj/projectile/ship_projectile`).

---

## 5. ОСТАВШИЕСЯ ЗАДАЧИ (TODO)

### 5.1 По UI (FireControl.tsx) — доделать/проверить
- Логику `CombatStatsSection` — компонент есть, но НЕ подключён в раскладку (dead-code).
- Проверить, что «Время полёта снарядов» внутри вооружения выглядит ок на узком экране.
- При желании добавить клиентский poll, если живой tgui не пушит сам.
- `ProjectileData`-поля `weapon`/`target` используются (проверить интерфейс).

### 5.2 По бэкенду
- [ ] Прогнать на живом сервере: захват/стрельба/урон/ARPA-обновление.
- [ ] Устранить рантайм-риски типизации: касты `.../controlled` там, где цель может быть NPC
      (combat_system.dm:204,220,446; ship_projectile.dm:195,395; примеры см. раздел 6.2).
- [ ] Разобраться с блокировкой `shiptest.rsc` (env, не код) — для CI/локальной сборки.
- [ ] Решить вопрос коммита gitignored-файлов combat (см. раздел 1).

### 5.3 Прогресс по изначальному плану session 1
- Ручной линк (мультитул → ship_weapon → fire_control) — НЕ реализован (авто-линк есть).
- Вариант C (white-shiptest боевая карта) — отложен, не делали.

---

## 6. ХЕНДОФФ ПО КАЖДОМУ СОМНИТЕЛЬНОМУ МЕСТУ

### 6.1 НЕ восстанавливать `locate(text2num(...))`
- Ранний «фикс» `locate(text2num(params[...]))` ЛОМАЛ резолв. Правильно: `locate(ref_string)`.
- `REF(x)` даёт строку `"#1234567"`; `locate("ИМЕННО_ЭТА_СТРОКА")` находит объект.
  `text2num` превращал её в число → null.

### 6.2 Каст `target` / `projectile.target` в `/datum/overmap/ship/controlled`
- Проблема: `var/datum/overmap/ship/controlled/T = something_ship` — если `something_ship` НЕ controlled,
  BYOND это строки не проверяет на компиляции, но на рантайме читает поля, которых у NPC может не
  быть (`.shuttle_port`, `get_area(...)` и т.п.) → runtime.
- Где искать: `combat_system.dm` (строки ~204, 220, 446), `ship_projectile.dm` (~195, 395),
  `ship_weapon.dm` (авто-цель). Если цель НЕ controlled — добавлять `if(!istype(.../controlled)) return/сkip`.
- UI-часть уже починена: `select_target`/`lock_target` теперь `/datum/overmap/ship`.

### 6.3 `get_known_ship_name(target)` — только для controlled
- Сигнатура ожидает `/datum/overmap/ship/controlled`. Для NPC-целей надо сначала
  `istype(.../controlled)`, иначе подставлять просто `target.name`.

### 6.4 Блокировка `shiptest.rsc` + `snow.dmi` — env-проблема
- `BUG: shiptest.rsc is locked up!` + `icemoon.dm:5: ... snow.dmi cannot find file`.
- `snow.dmi` физически есть (проверено `Test-Path`). Ошибка возникает из-за того, что среда
  или AV блокирует файл ресурсов. Удаление `shiptest.rsc`/`.dmb` не помогло (лочится снова
  при следующей компиляции). Это НЕ связано с правками кода — до блокировки компиляция давала 0 ошибок.

### 6.5 `updateUsrDialog()` vs `SStgui.update_uis()`
- У консоли `USES_TGUI` → `updateUsrDialog()` = no-op (иначе закрытое окно переоткрывается).
- Для живого обновления открытого окна использовать `SStgui.update_uis(src)`.
- В tgui клиент обновляется только когда сервер пушит (в этой ветке, без клиентского poll).

### 6.6 `get_engagement_range()` маленький (дефолт 4)
- Сенсоры small-кораблей сверхмаленькие. Если цели не видны — проверь `default_sensor_range` на
  корабле (`controlled_ship_datum.dm`, ~строка 16) и настрой баланс.

### 6.7 `available_targets`/`mapObjects` — обновление через `get_ui_data()`
- `get_ui_data()` ВСЕГДА пересчитывает `update_available_targets()` и `get_tactical_map_data()`
  перед возвратом. Т.е. свежесть данных = свежесть вызова `ui_data` (открытие, ui_act, SStgui.update_uis).
- `process()` зовёт `update_available_targets()`+`SStgui.update_uis` каждые `target_scan_interval` (2 сек).

### 6.8 Овермап-модель / токены
- Клиент рисует DOM/CSS, а НЕ `.dmi`: тип маркера приходит в поле `type` из
  `get_overmap_marker_type()` (ship / npc_ship / star / outpost / jump / static / dynamic / event / unknown).
- `get_nearby_overmap_objects()` — только та же клетка; для радиуса использовать паттерн
  `check_proximity()`/`get_nearby_ships()`/`get_tactical_map_data()`.

### 6.9 `CombatStatsSection` — dead code в UI
- Компонент объявлен, но в раскладку не подключён. Либо подключить, либо удалить.

---

## 7. КОМАНДЫ / ПАМЯТКА

```powershell
# Компиляция DM (2-4 мин; может ловиться env-блокировка .rsc — см. 6.4)
& "C:\Program Files (x86)\BYOND\bin\dm.exe" -max_errors 50 shiptest.dme
# можно отфильтровать: ... 2>&1 | Select-String -Pattern "error|\.dmb"

# Сборка tgui
yarn tgui:build    # (в каталоге tgui; успех = "webpack ... compiled successfully")

# Статус/ветки
git status --short
git branch --show-current
```

---

## 8. ОЦЕНКА ДОВЕРИЯ К БЭКЕНДУ (что знать, чтобы писать без гайда)

1. **Овермап = сетка `overmap_container[x][y]`**, ячейки могут быть `list`. Всегда обрабатывай
   `islist`, заворачивай по краям, добавляй евклидов фильтр после квадратного скана.
2. **`REF(x)`/`locate(ref_str)`** — правильный резолв; НЕ `text2num`.
3. **Типы**: `/datum/overmap` (база) → `/datum/overmap/ship` → `/datum/overmap/ship/controlled`.
   `controlled` = игровые корабли (имеют `shuttle_port`, `destroyed`, `get_known_ship_name` и др.).
   NPC-шипы — `/datum/overmap/ship`, НО не controlled: не все поля/proc доступны.
4. **Паттерн скана** (квадрат + contents + заворот) — переиспользуй `get_nearby_ships()` /
   `get_tactical_map_data()` как источник.
5. **Обновление UI** — только через серверный push (`SStgui.update_uis`) + `get_ui_data()` на fetch;
   в этой ветке клиент сам не поллит.
6. **Снаряды** — `/obj/projectile/ship_projectile`, живут в `combat_system.active_projectiles`;
   промах уходит в overshoot (~1.5 сек), потом `resolve_miss()`.

Это база. Писать бэкенд корабельного боя можно, опираясь на указанные файлы и паттерны выше.
