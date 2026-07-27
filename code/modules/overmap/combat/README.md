# Система космического боя для Solaris v2.0

## Обзор

Эта система добавляет тактический космический бой между кораблями в Solaris. Система учитывает ограничения движка BYOND и интегрируется с существующей архитектурой овермапа.

**Версия 2.0** - Полная переработка архитектуры с event-driven обновлениями, автоматической синхронизацией данных и оптимизированным процессингом.

## Архитектура v2.0

### Event-Driven Архитектура

Новая версия системы использует event-driven архитектуру для обеспечения мгновенного обновления интерфейса при изменениях состояния боя:

```
CombatSystem → EventManager → StatusBridge → AutoUpdateController → FireControlConsole → TGUI
```

### Основные компоненты v2.0

#### 1. Система боя корабля (`datum/ship_combat_system`)
- **Оптимизированный процессинг** с приоритезацией обновлений
- **Встроенный EventManager** для генерации событий
- **Кэширование данных** для снижения нагрузки
- **Адаптивные интервалы** обновления

#### 2. Менеджер событий (`datum/combat_event_manager`)
- **Подписка/отписка** на события
- **9 типов событий** для критических изменений
- **Статистика событий** для отладки
- **Автоматическая очистка** подписчиков

#### 3. Мост статуса (`datum/combat_status_bridge`)
- **Двусторонняя синхронизация** данных
- **Валидация и обработка ошибок**
- **Fallback режим** при проблемах
- **Кэширование статуса** для оптимизации

#### 4. Контроллер автоматических обновлений (`datum/combat_auto_update_controller`)
- **Адаптивные интервалы** обновления
- **Условные обновления** только при изменениях
- **Приоритезация** на основе активности
- **Статистика производительности**

#### 5. Консоль управления огнем (`obj/machinery/computer/ship/fire_control`)
- **Интеграция с EventManager**
- **Автоматические обновления** интерфейса
- **Обработка событий** в реальном времени
- **Fallback механизмы** при ошибках

#### 6. Обновленный TGUI интерфейс (`FireControl.tsx`)
- **Визуальные индикаторы** состояния соединения
- **Оптимизированный рендеринг** списков
- **Обработка динамических статусов**
- **Отслеживание качества соединения**

### Потоки данных

#### Поток событий:
```
CombatSystem (изменение состояния) 
    ↓
EventManager (генерация события)
    ↓
StatusBridge (фильтрация подписчиков)
    ↓
FireControlConsole (обработка события)
    ↓
AutoUpdateController (решение об обновлении)
    ↓
TGUI Interface (обновление UI)
```

#### Поток синхронизации:
```
CombatSystem.process() 
    ↓
StatusBridge.sync_status() 
    ↓
Проверка изменений (status_changed)
    ↓
AutoUpdateController.should_update() 
    ↓
FireControlConsole.updateUsrDialog()
    ↓
TGUI обновление
```

## Установка v2.0

### 1. Добавление файлов
Скопируйте все файлы из `code/modules/overmap/combat/` в соответствующую директорию вашего проекта.

**Новые файлы v2.0:**
- `combat_event_manager.dm` - Система событий
- `status_bridge.dm` - Мост синхронизации
- `auto_update_controller.dm` - Контроллер обновлений

### 2. Добавление определений
Включите файл определений в `code/__DEFINES/ship_combat.dm` в ваш проект.

**Новые определения v2.0:**
```dm
// Типы событий
#define COMBAT_EVENT_TARGET_LOCK_CHANGED "target_lock_changed"
#define COMBAT_EVENT_WEAPON_STATUS_CHANGED "weapon_status_changed"
#define COMBAT_EVENT_PROJECTILE_LAUNCHED "projectile_launched"
#define COMBAT_EVENT_PROJECTILE_HIT "projectile_hit"
#define COMBAT_EVENT_WEAPON_DAMAGED "weapon_damaged"
#define COMBAT_EVENT_WEAPON_REPAIRED "weapon_repaired"
#define COMBAT_EVENT_TARGET_ACQUIRED "target_acquired"
#define COMBAT_EVENT_TARGET_LOST "target_lost"
#define COMBAT_EVENT_COMBAT_STATUS_CHANGED "combat_status_changed"
```

### 3. Интеграция с существующим кодом
Добавьте в `code/modules/overmap/ships/ship_datum.dm`:
```dm
/// Система боя корабля
var/datum/ship_combat_system/combat_system
```

### 4. Обновление компиляции
Добавьте новые файлы в `tgui.bat` или соответствующий скрипт компиляции.

### 5. Миграция с v1.0

**Обратная совместимость:**
- Старый API полностью сохранен
- Новые компоненты активируются автоматически
- Fallback механизмы обеспечивают работу при ошибках

**Рекомендуемые изменения:**
1. Замените жесткие статусы на динамические (см. Исправление логики передачи статусов)
2. Используйте EventManager для оповещений
3. Интегрируйте AutoUpdateController для оптимизации

## Использование

### 1. Добавление оружия на корабль
```dm
// В карте корабля добавьте:
/obj/machinery/ship_weapon/kinetic
    name = "Кинетическая пушка"

/obj/machinery/ship_weapon/laser
    name = "Лазерная пушка"

/obj/machinery/computer/ship/fire_control
    name = "Консоль управления огнем"
```

### 2. Настройка корабля
```dm
// В датуме корабля установите параметры:
max_hull_health = 100      // Максимальное здоровье корпуса
max_shield_strength = 50   // Максимальная прочность щитов
ship_type = SHIP_TYPE_FRIGATE  // Тип корабля
faction = FACTION_NANOTRASEN   // Фракция
```

### 3. Использование в игре
1. Подойдите к консоли управления огнем
2. Запустите сканирование целей
3. Выберите цель из списка
4. Дождитесь захвата цели (индикатор прогресса)
5. Выберите оружие и нажмите "Огонь"
6. Следите за полетом снаряда и результатом попадания

## API для разработчиков v2.0

### Основные процедуры

#### Захват цели (с автоматическими событиями)
```dm
var/datum/ship_combat_system/CS = get_ship_combat_system(ship)
CS.acquire_target(target_ship)
// Автоматически генерирует COMBAT_EVENT_TARGET_ACQUIRED
```

#### Открытие огня (с событиями)
```dm
var/obj/machinery/ship_weapon/weapon = locate() in CS.weapons
CS.fire_weapon(weapon)
// Автоматически генерирует COMBAT_EVENT_PROJECTILE_LAUNCHED
```

#### Нанесение урона (с событиями)
```dm
target_ship.take_damage(25, BRUTE, attacker_ship, weapon)
// Автоматически генерирует COMBAT_EVENT_PROJECTILE_HIT
```

#### Проверка состояния
```dm
// Проверка здоровья
var/health_percent = ship.hull_health / ship.max_hull_health

// Проверка щитов
var/shields_active = ship.shields_active
var/shield_percent = ship.shield_strength / ship.max_shield_strength

// Проверка повреждений систем
var/engine_damage = ship.system_damage[SHIP_SYSTEM_ENGINES]
```

### EventManager API

#### Подписка на события
```dm
var/datum/combat_event_manager/event_manager = combat_system.event_manager

// Подписка на все события
event_manager.subscribe(console)

// Подписка на конкретные события
event_manager.subscribe(console, list(
    COMBAT_EVENT_TARGET_LOCK_CHANGED,
    COMBAT_EVENT_WEAPON_STATUS_CHANGED
))
```

#### Отписка от событий
```dm
event_manager.unsubscribe(console)
```

#### Генерация событий
```dm
// Изменение статуса захвата цели
event_manager.notify_target_lock_changed(old_status, new_status)

// Запуск снаряда
event_manager.notify_projectile_launched(projectile, weapon)

// Попадание снаряда
event_manager.notify_projectile_hit(projectile, actual_hit, damage)
```

### StatusBridge API

#### Создание моста
```dm
var/datum/combat_status_bridge/bridge = new(CombatSystem, FireControlConsole)
```

#### Синхронизация статуса
```dm
bridge.sync_status()
bridge.force_update() // Принудительное обновление
```

#### Получение статистики
```dm
var/list/stats = bridge.get_statistics()
// Возвращает: last_sync_time, error_count, fallback_mode и т.д.
```

### AutoUpdateController API

#### Создание контроллера
```dm
var/datum/combat_auto_update_controller/controller = new(FireControlConsole, StatusBridge)
```

#### Управление обновлениями
```dm
controller.force_update() // Принудительное обновление
controller.set_update_priority(8) // Высокий приоритет
controller.pause_updates() // Приостановить
controller.resume_updates() // Возобновить
```

#### Статистика производительности
```dm
var/list/stats = controller.get_statistics()
// Возвращает: total_updates, skipped_updates, average_update_time и т.д.
```

### События

#### Обработка событий в консоли
```dm
/obj/machinery/computer/ship/fire_control/proc/on_combat_event(list/event)
    var/event_type = event["type"]
    var/event_data = event["data"]
    
    switch(event_type)
        if(COMBAT_EVENT_TARGET_LOCK_CHANGED)
            // Обработка изменения захвата цели
        if(COMBAT_EVENT_WEAPON_STATUS_CHANGED)
            // Обработка изменения статуса оружия
```

#### Обработка попадания
```dm
/obj/projectile/ship_projectile/proc/on_hit()
    // Вызывается при попадании снаряда
```

#### Обработка повреждения системы
```dm
/datum/overmap/ship/proc/on_system_damaged(system, damage_level)
    // Вызывается при повреждении системы корабля
```

#### Обработка уничтожения
```dm
/datum/overmap/ship/proc/on_destroyed(attacker, weapon)
    // Вызывается при уничтожении корабля
```

#### Открытие огня
```dm
var/obj/machinery/ship_weapon/weapon = locate() in CS.weapons
CS.fire_weapon(weapon)
```

#### Нанесение урона
```dm
target_ship.take_damage(25, BRUTE, attacker_ship, weapon)
```

#### Проверка состояния
```dm
// Проверка здоровья
var/health_percent = ship.hull_health / ship.max_hull_health

// Проверка щитов
var/shields_active = ship.shields_active
var/shield_percent = ship.shield_strength / ship.max_shield_strength

// Проверка повреждений систем
var/engine_damage = ship.system_damage[SHIP_SYSTEM_ENGINES]
```

### События

#### Обработка попадания
```dm
/obj/projectile/ship_projectile/proc/on_hit()
    // Вызывается при попадании снаряда
```

#### Обработка повреждения системы
```dm
/datum/overmap/ship/proc/on_system_damaged(system, damage_level)
    // Вызывается при повреждении системы корабля
```

#### Обработка уничтожения
```dm
/datum/overmap/ship/proc/on_destroyed(attacker, weapon)
    // Вызывается при уничтожении корабля
```

## Настройка баланса

### Параметры оружия
```dm
/obj/machinery/ship_weapon/kinetic
    damage = 30            // Урон
    base_accuracy = 70     // Базовая точность (%)
    optimal_range = 8      // Оптимальная дальность
    max_range = 25         // Максимальная дальность
    recharge_time = 8 SECONDS  // Время перезарядки
    projectile_speed = 7   // Скорость снаряда
```

### Параметры корабля
```dm
/datum/overmap/ship
    max_hull_health = 100      // Здоровье корпуса
    max_shield_strength = 50   // Прочность щитов
    shield_recharge_rate = 1   // Скорость восстановления щитов
    shield_recharge_interval = 10 SECONDS  // Интервал восстановления
```

### Глобальные константы
```dm
// В code/__DEFINES/combat.dm
#define DEFAULT_MAX_TARGET_RANGE 20      // Максимальная дальность захвата
#define DEFAULT_TARGET_LOCK_TIME 5 SECONDS  // Время захвата цели
#define DEFAULT_TARGET_SCAN_INTERVAL 5 SECONDS  // Интервал сканирования
```

## Примеры использования v2.0

### Создание боевого корабля с новой архитектурой
```dm
/area/ship/combat_frigate
    name = "Боевой Фрегат"
    related_ship = /datum/overmap/ship/controlled/combat_frigate

/datum/overmap/ship/controlled/combat_frigate
    name = "Боевой Фрегат"
    ship_type = SHIP_TYPE_FRIGATE
    max_hull_health = 120
    max_shield_strength = 60

// В карте корабля:
/obj/machinery/ship_weapon/kinetic
    name = "Основная пушка"

/obj/machinery/ship_weapon/laser
    name = "Лазерная турель"

/obj/machinery/computer/ship/fire_control
    name = "Боевой мостик"
    // Автоматически инициализирует StatusBridge и AutoUpdateController
```

### Создание события с боем и автоматическими событиями
```dm
/datum/overmap_event/pirate_ambush
    name = "Пиратская засада"
    
    start()
        // Создаем пиратский корабль
        var/datum/overmap/ship/pirate = new(location, system)
        pirate.name = "Пиратский Корабль"
        pirate.faction = FACTION_PIRATE
        
        // Настраиваем вооружение
        pirate.max_hull_health = 80
        pirate.max_shield_strength = 40
        
        // Получаем систему боя (создаст EventManager автоматически)
        var/datum/ship_combat_system/cs = get_ship_combat_system(pirate)
        
        // Начинаем атаку (автоматически генерирует события)
        cs.acquire_target(player_ship)
        
        // Подписываем консоль на события
        if(cs.control_console && cs.event_manager)
            cs.event_manager.subscribe(cs.control_console)
```

### Использование EventManager для кастомных уведомлений
```dm
// Создаем свой обработчик событий
/datum/my_combat_observer
    var/datum/ship_combat_system/tracked_system

    New(datum/ship_combat_system/cs)
        tracked_system = cs
        if(cs.event_manager)
            cs.event_manager.subscribe(src, list(
                COMBAT_EVENT_TARGET_LOCK_CHANGED,
                COMBAT_EVENT_WEAPON_STATUS_CHANGED
            ))

    proc/on_combat_event(list/event)
        var/event_type = event["type"]
        switch(event_type)
            if(COMBAT_EVENT_TARGET_LOCK_CHANGED)
                var/old_status = event["data"]["old_status"]
                var/new_status = event["data"]["new_status"]
                to_chat(world, "Цель изменила статус: [old_status] -> [new_status]")
```

### Оптимизация процессинга для больших сражений
```dm
// Настройка приоритета процессинга
/datum/ship_combat_system/proc/setup_for_large_battle()
    process_priority = 8 // Высокий приоритет
    process_interval = 0.3 SECONDS // Более частые обновления
    
    // Настройка контроллера обновлений
    if(control_console?.auto_update_controller)
        control_console.auto_update_controller.set_update_priority(8)
```

### Мониторинг производительности
```dm
// Получение статистики системы
/proc/show_combat_statistics(datum/ship_combat_system/cs)
    if(!cs) return
    
    // Статистика событий
    var/list/event_stats = cs.event_manager?.get_statistics()
    to_chat(world, "Всего событий: [event_stats["total_events"]]")
    
    // Статистика моста
    var/list/bridge_stats = cs.control_console?.status_bridge?.get_statistics()
    to_chat(world, "Ошибок синхронизации: [bridge_stats["error_count"]]")
    
    // Статистика обновлений
    var/list/update_stats = cs.control_console?.auto_update_controller?.get_statistics()
    to_chat(world, "Обновлений: [update_stats["total_updates"]], Пропущено: [update_stats["skipped_updates"]]")
```
```

## Отладка

### Админ-команды
```dm
// Запуск демонстрации
/client/proc/start_combat_demo()

// Создание тестового корабля
/client/proc/create_test_combat_ship()

// Добавление оружия на корабль
/client/proc/add_weapons_to_ship()
```

### Логирование
Все боевые действия логируются с префиксом "КОСМИЧЕСКИЙ БОЙ":
```
КОСМИЧЕСКИЙ БОЙ: Демо-Корабль выстрелил из Кинетической пушки по Пиратскому Кораблю
КОСМИЧЕСКИЙ БОЙ: Пиратский Корабль уничтожен. Причина: уничтожен Демо-Корабль
```

## Ограничения и оптимизации v2.0

### Производительность
- **Оптимизированный процессинг** с приоритезацией обновлений
- **Адаптивные интервалы** для снижения нагрузки
- **Кэширование данных** для минимизации вычислений
- **Условные обновления** только при изменениях
- **Рекомендуется** ограничивать количество активных снарядов (< 50)

### Графика
- Используются простые спрайты для совместимости
- Эффекты оптимизированы для минимального влияния на производительность
- **Оптимизированный рендеринг** списков в TGUI

### Сетевой трафик
- **Event-driven обновления** снижают нагрузку
- **Интеллектуальная фильтрация** изменений
- **Адаптивная частота** обновлений интерфейса
- Данные передаются только при изменениях

### Память
- **Автоматическая очистка** подписчиков событий
- **Управление жизненным циклом** объектов
- **Оптимизированные структуры данных**

## Будущие улучшения v2.0

### Планируемые функции
1. **AI для NPC кораблей** - автоматическое управление боем с использованием EventManager
2. **Разные типы боеприпасов** - специализированные снаряды с событиями
3. **Системы противодействия** - помехи, ложные цели с event-driven архитектурой
4. **Тактические карты** - планирование боя с реальными обновлениями
5. **Эскадры и флоты** - групповые сражения с координацией через события
6. **Сетевой мультиплеер** - синхронизация боя между игроками

### Оптимизации
1. **Кэширование расчетов** - повторное использование результатов (уже внедрено)
2. **Предсказание движения** - улучшенная баллистика
3. **Пул объектов** - переиспользование снарядов
4. **Веб-сокеты** - альтернатива TGUI для реального времени
5. **Ленивая загрузка** - оптимизация памяти

### Расширения API
1. **Плагинная система** - модульные расширения боя
2. **Скриптовые события** - настраиваемые триггеры
3. **Статистика и аналитика** - детальная метрика боя
4. **Запись и воспроизведение** - система replays

## Поддержка и диагностика v2.0

### Диагностика проблем

#### Проверка EventManager
```dm
// Проверка активности менеджера событий
if(combat_system.event_manager)
    var/list/stats = combat_system.event_manager.get_statistics()
    to_chat(world, "Событий: [stats["total_events"]], Подписчиков: [stats["subscriber_count"]]")
else
    to_chat(world, "EventManager не инициализирован!")
```

#### Проверка StatusBridge
```dm
// Проверка состояния моста
if(console.status_bridge)
    var/list/stats = console.status_bridge.get_statistics()
    to_chat(world, "Синхронизация: [stats["fallback_mode"] ? "FALLBACK" : "Норма"]")
    to_chat(world, "Ошибок: [stats["error_count"]]/[stats["max_errors"]]")
else
    to_chat(world, "StatusBridge не инициализирован!")
```

#### Проверка AutoUpdateController
```dm
// Проверка производительности обновлений
if(console.auto_update_controller)
    var/list/stats = console.auto_update_controller.get_statistics()
    to_chat(world, "Обновлений: [stats["total_updates"]], Пропущено: [stats["skipped_updates"]]")
    to_chat(world, "Среднее время: [stats["average_update_time"]]мс")
else
    to_chat(world, "AutoUpdateController не инициализирован!")
```

### Известные проблемы
1. При высокой загрузке сервера возможны задержки в расчетах
2. Визуальные эффекты могут не отображаться при проблемах с клиентом
3. При одновременной атаке множества целей возможны конфликты
4. **Fallback режим** может активироваться при частых ошибках синхронизации

### Решение проблем

#### Не работает захват цели
- Проверьте расстояние и наличие LOS
- Убедитесь, что EventManager генерирует события
- Проверьте статус в combat_system.target_lock_status

#### Оружие не стреляет
- Проверьте заряд, перезарядку, повреждения
- Убедитесь, что статус захвата = "locked"
- Проверьте события COMBAT_EVENT_WEAPON_STATUS_CHANGED

#### Снаряды не попадают
- Проверьте шанс попадания и движение цели
- Убедитесь, что события COMBAT_EVENT_PROJECTILE_HIT генерируются
- Проверьте логирование боевых действий

#### Интерфейс не обновляется
- Проверьте подключение к системе боя
- Убедитесь, что StatusBridge активен
- Проверьте статистику AutoUpdateController
- Попробуйте принудительное обновление: `console.auto_update_controller.force_update()`

#### Проблемы с синхронизацией
- Проверьте количество ошибок в StatusBridge
- При большом количестве ошибок система перейдет в fallback режим
- Проверьте логирование событий для диагностики

### Логирование и отладка

#### Включение детального логирования
```dm
// В combat_system.dm
#define COMBAT_DEBUG_LOGGING 1

#ifdef COMBAT_DEBUG_LOGGING
#define COMBAT_LOG(msg) log_game("COMBAT_DEBUG: [msg]")
#else
#define COMBAT_LOG(msg)
#endif
```

#### Мониторинг событий в реальном времени
```dm
// Создаем монитор событий
/datum/comat_event_monitor
    proc/on_combat_event(list/event)
        var/timestamp = event["timestamp"]
        var/event_type = event["type"]
        log_game("EVENT: [timestamp] - [event_type]")
```

## Лицензия
Система распространяется под той же лицензией, что и основной проект Solaris.

## Авторы v2.0
- **Переработка архитектуры:** Event-driven система, оптимизация процессинга
- **EventManager:** Система событий для реального времени
- **StatusBridge:** Двусторонняя синхронизация данных
- **AutoUpdateController:** Оптимизация обновлений интерфейса
- **TGUI улучшения:** Визуальные индикаторы и оптимизация рендеринга

## Благодарности
- Команде Solaris за основу проекта
- Разработчикам BYOND за движок
- Сообществу SS13 за вдохновение
- Всем тестировщикам за обратную связь

## Версии

### v2.0 (Текущая версия)
- Полная переработка архитектуры
- Event-driven система обновлений
- Оптимизированный процессинг
- Автоматическая синхронизация данных
- Улучшенный TGUI интерфейс

### v1.0 (Предыдущая версия)
- Базовая система боя
- Простая обработка целей
- Фундаментальная архитектура

## Контакты и поддержка

Для сообщений о багах и предложений по улучшению:
- GitHub Issues: [ссылка на репозиторий]
- Discord: [ссылка на сервер]
- Форум: [ссылка на форум]

## Дополнительные ресурсы

- **Wiki:** [ссылка на документацию]
- **API Reference:** [ссылка на API]
- **Tutorial:** [ссылка на руководство]
- **Examples:** [ссылка на примеры]

---

**Последнее обновление:** 2026-07-02
**Версия документа:** 2.0
**Статус:** Стабильный релиз
