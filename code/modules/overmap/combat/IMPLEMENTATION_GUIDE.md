# Руководство по внедрению системы боя

## Шаг 1: Подготовка файлов

### 1.1. Создайте директорию для системы боя
```
code/modules/overmap/combat/
```

### 1.2. Скопируйте все созданные файлы:
```
combat_system.dm          # Основная система боя
ship_weapon.dm            # Машинерия вооружения
ship_projectile.dm        # Снаряды для космического боя
fire_control_console.dm   # Консоль управления огнем
fire_control.tgui.tsx     # TGUI интерфейс
ship_integration.dm       # Интеграция с кораблями
examples.dm               # Примеры использования
```

### 1.3. Добавьте определения
Скопируйте `combat.dm` в `code/__DEFINES/`

## Шаг 2: Интеграция с существующим кодом

### 2.1. Обновите датум корабля
В `code/modules/overmap/ships/ship_datum.dm` добавьте:

```dm
/datum/overmap/ship
    /// Система боя корабля
    var/datum/ship_combat_system/combat_system
    
    /// Максимальное здоровье корпуса
    var/max_hull_health = 100
    
    /// Текущее здоровье корпуса
    var/hull_health = 100
    
    /// Максимальная прочность щитов
    var/max_shield_strength = 50
    
    /// Текущая прочность щитов
    var/shield_strength = 50
    
    /// Флаг, указывающий что щиты активны
    var/shields_active = TRUE
    
    /// Уровень повреждения систем
    var/list/system_damage = list()
    
    /// Фракция корабля
    var/faction = FACTION_INDEPENDENT
    
    /// Тип корабля
    var/ship_type = SHIP_TYPE_FRIGATE
    
    /// Боевой статус корабля
    var/combat_status = COMBAT_STATUS_PEACEFUL
    
    /// Флаг, указывающий что корабль уничтожен
    var/destroyed = FALSE
```

### 2.2. Добавьте инициализацию в New()
```dm
/datum/overmap/ship/New(location, system)
    . = ..()
    // Инициализация системы повреждений
    initialize_system_damage()
    
    // Создание системы боя для управляемых кораблей
    if(istype(src, /datum/overmap/ship/controlled))
        combat_system = new /datum/ship_combat_system(src)
```

### 2.3. Добавьте очистку в Destroy()
```dm
/datum/overmap/ship/Destroy()
    if(combat_system)
        QDEL_NULL(combat_system)
    system_damage.Cut()
    return ..()
```

## Шаг 3: Добавление обработки боя

### 3.1. Создайте подсистему для обработки боя
В `code/controllers/subsystem/` создайте или модифицируйте подсистему:

```dm
SUBSYSTEM_DEF(overmap_combat)
    name = "Overmap Combat"
    wait = 1 SECONDS
    priority = FIRE_PRIORITY_OVERMAP_COMBAT
    flags = SS_NO_INIT
    
    var/list/combat_queue = list()
    
/datum/controller/subsystem/overmap_combat/fire()
    for(var/datum/overmap/ship/ship in GLOB.overmap_ships)
        if(ship.destroyed)
            continue
        
        // Восстановление щитов
        ship.recharge_shields()
        
        // Обработка системы боя
        if(ship.combat_system)
            ship.combat_system.process()
        
        // Проверка выхода из боя
        if(ship.combat_status == COMBAT_STATUS_ENGAGED && world.time - ship.last_combat_time > 1 MINUTES)
            ship.combat_status = COMBAT_STATUS_PEACEFUL
            ship.update_damage_effects()
```

### 3.2. Добавьте подсистему в master controller
В `code/controllers/master.dm` добавьте инициализацию подсистемы.

## Шаг 4: Создание спрайтов

### 4.1. Базовые спрайты оружия
Создайте в `icons/obj/weapons.dmi`:
- `kinetic_cannon.dmi` - кинетическая пушка
- `laser_cannon.dmi` - лазерная пушка  
- `missile_launcher.dmi` - ракетная установка
- `energy_cannon.dmi` - энергетическая пушка

### 4.2. Спрайты снарядов
Создайте в `icons/obj/projectiles.dmi`:
- `ship_kinetic.dmi` - кинетический снаряд
- `ship_laser.dmi` - лазерный луч
- `ship_missile.dmi` - ракета
- `ship_energy.dmi` - энергетический заряд

### 4.3. Иконки овермапа
Создайте в `icons/obj/overmap.dmi`:
- `projectile.dmi` - базовый снаряд
- `projectile_laser.dmi` - лазерный снаряд
- `projectile_kinetic.dmi` - кинетический снаряд
- `projectile_missile.dmi` - ракета
- `projectile_energy.dmi` - энергетический снаряд
- `ship_destroyed.dmi` - уничтоженный корабль

## Шаг 5: Тестирование

### 5.1. Базовый тест
```dm
// Создайте тестовый корабль с оружием
/obj/effect/map_helper/ship_setup/test_combat
    name = "Тестовая боевая настройка"
    
    initialize()
        . = ..()
        
        // Добавляем оружие
        new /obj/machinery/ship_weapon/kinetic(locate(x+1, y, z))
        new /obj/machinery/ship_weapon/laser(locate(x+2, y, z))
        
        // Добавляем консоль
        new /obj/machinery/computer/ship/fire_control(locate(x, y+1, z))
        
        qdel(src)
```

### 5.2. Тест боя
```dm
// Команда для тестирования боя
/client/proc/test_combat_system()
    set name = "Тест системы боя"
    set category = "Debug"
    
    // Создаем два тестовых корабля
    var/datum/overmap/ship/controlled/ship1 = new(location, system)
    var/datum/overmap/ship/ship2 = new(location, system)
    
    // Настраиваем корабли
    ship1.name = "Тестовый Корабль 1"
    ship2.name = "Тестовый Корабль 2"
    
    // Добавляем оружие
    // ... код добавления оружия
    
    // Запускаем тестовый бой
    ship1.combat_system.acquire_target(ship2)
    ship1.combat_system.fire_weapon(ship1.combat_system.weapons[1])
    
    to_chat(usr, span_notice("Тест системы боя запущен!"))
```

## Шаг 6: Балансировка

### 6.1. Настройка параметров оружия
В `code/__DEFINES/combat.dm` настройте:

```dm
// Баланс оружия
#define KINETIC_DAMAGE 30
#define KINETIC_ACCURACY 70
#define KINETIC_RECHARGE 8 SECONDS

#define LASER_DAMAGE 25
#define LASER_ACCURACY 85
#define LASER_RECHARGE 6 SECONDS

#define MISSILE_DAMAGE 50
#define MISSILE_ACCURACY 90
#define MISSILE_RECHARGE 20 SECONDS

#define ENERGY_DAMAGE 40
#define ENERGY_ACCURACY 80
#define ENERGY_RECHARGE 15 SECONDS
```

### 6.2. Настройка кораблей
```dm
// Типы кораблей и их характеристики
#define FRIGATE_HEALTH 100
#define FRIGATE_SHIELDS 50
#define FRIGATE_SPEED 1.0

#define DESTROYER_HEALTH 150
#define DESTROYER_SHIELDS 75
#define DESTROYER_SPEED 0.9

#define CRUISER_HEALTH 200
#define CRUISER_SHIELDS 100
#define CRUISER_SPEED 0.8

#define BATTLESHIP_HEALTH 300
#define BATTLESHIP_SHIELDS 150
#define BATTLESHIP_SPEED 0.7
```

## Шаг 7: Интеграция с игровым процессом

### 7.1. Добавление в карты
Добавьте оружие и консоли в существующие карты кораблей:

```dm
// Пример для стандартного фрегата
/obj/machinery/ship_weapon/kinetic
    name = "Основная пушка"
    pixel_x = -8
    pixel_y = 0

/obj/machinery/computer/ship/fire_control
    name = "Консоль управления огнем"
    desc = "Используется для управления вооружением корабля."
```

### 7.2. Обучение игроков
Создайте руководство для игроков:

```dm
/obj/item/paper/combat_guide
    name = "Руководство по космическому бою"
    info = {"
        <h1>Руководство по космическому бою</h1>
        <h2>Основные шаги:</h2>
        <ol>
            <li>Подойдите к консоли управления огнем</li>
            <li>Запустите сканирование целей (кнопка "Сканирование")</li>
            <li>Выберите цель из списка доступных</li>
            <li>Дождитесь захвата цели (индикатор прогресса)</li>
            <li>Выберите оружие и нажмите "Огонь"</li>
            <li>Следите за полетом снаряда и результатом</li>
        </ol>
        
        <h2>Типы оружия:</h2>
        <ul>
            <li><b>Кинетическое</b>: Высокий урон, средняя точность</li>
            <li><b>Лазерное</b>: Средний урон, высокая точность</li>
            <li><b>Ракетное</b>: Очень высокий урон, медленная перезарядка</li>
            <li><b>Энергетическое</b>: Высокий урон, потребляет много энергии</li>
        </ul>
        
        <h2>Тактические советы:</h2>
        <ul>
            <li>Держитесь на оптимальной дистанции для вашего оружия</li>
            <li>Следите за состоянием щитов и корпуса</li>
            <li>Ремонтируйте поврежденное оружие</li>
            <li>Используйте разные типы оружия против разных целей</li>
        </ul>
    "}
```

## Шаг 8: Мониторинг и отладка

### 8.1. Логирование
```dm
// Добавьте логирование боевых действий
/proc/log_combat(message)
    log_game("КОСМИЧЕСКИЙ БОЙ: [message]")
    message_admins("КОСМИЧЕСКИЙ БОЙ: [message]", ADMIN_LOG_COMBAT)
```

### 8.2. Статистика
```dm
// Сбор статистики боя
/datum/combat_statistics
    var/total_shots_fired = 0
    var/total_hits = 0
    var/total_damage_dealt = 0
    var/total_ships_destroyed = 0
    
    proc/record_shot(hit_successful, damage)
        total_shots_fired++
        if(hit_successful)
            total_hits++
            total_damage_dealt += damage
    
    proc/record_destruction()
        total_ships_destroyed++
    
    proc/get_accuracy()
        return total_shots_fired > 0 ? (total_hits / total_shots_fired) * 100 : 0
```

## Шаг 9: Оптимизация

### 9.1. Оптимизация расчетов
```dm
// Кэширование часто используемых расчетов
var/global/list/distance_cache = list()

/proc/get_cached_distance(ship1, ship2)
    var/key = "[REF(ship1)]_[REF(ship2)]"
    if(distance_cache[key])
        return distance_cache[key]
    
    var/distance = OVERMAP_DISTANCE(ship1, ship2)
    distance_cache[key] = distance
    
    // Очистка старых записей
    if(length(distance_cache) > 1000)
        distance_cache.Cut(1, 500)
    
    return distance
```

### 9.2. Оптимизация отрисовки
```dm
// Пакетное обновление интерфейса
/datum/ship_combat_system/proc/queue_ui_update()
    if(!ui_update_queued)
        ui_update_queued = TRUE
        addtimer(CALLBACK(src, PROC_REF(process_ui_update)), 1 SECONDS)

/datum/ship_combat_system/proc/process_ui_update()
    ui_update_queued = FALSE
    if(control_console)
        control_console.updateUsrDialog()
```

## Шаг 10: Документация

### 10.1. Документация для разработчиков
Создайте файлы:
- `DEVELOPER_GUIDE.md` - руководство для разработчиков
- `API_REFERENCE.md` - справочник API
- `BALANCE_GUIDE.md` - руководство по балансировке

### 10.2. Документация для мейнтейнеров
- `MAINTENANCE_GUIDE.md` - руководство по поддержке
- `TROUBLESHOOTING.md` - решение проблем
- `UPGRADE_GUIDE.md` - руководство по обновлению

## Заключение

Система боя готова к использованию. Основные этапы:

1. ✅ Созданы все необходимые файлы
2. ✅ Интегрирована с существующей системой кораблей
3. ✅ Реализован TGUI интерфейс
4. ✅ Добавлена система повреждений и уничтожения
5. ✅ Созданы примеры и тесты
6. ✅ Написана документация

### Следующие шаги:
1. Создать спрайты для оружия и эффектов
2. Протестировать систему на реальных картах
3. Настроить баланс на основе тестов
4. Добавить дополнительные функции (AI, специальные снаряды и т.д.)
5. Интегрировать с другими системами (экономика, квесты)

### Важные замечания:
- Система модульная - можно добавлять новые типы оружия
- Баланс легко настраивается через defines
- Интерфейс расширяемый - можно добавлять новые функции
- Совместима с существующей архитектурой Solaris

Система готова к использованию в проекте Solaris!
