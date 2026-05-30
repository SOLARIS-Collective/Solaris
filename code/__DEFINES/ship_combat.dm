/**
 * # Определения для системы космического боя
 * 
 * Отдельный файл определений для избежания конфликтов с существующим combat.dm
 */

// ==================== СЛОИ ОВЕРМАПА ====================

/// Слой для снарядов на овермапе
#define OVERMAP_LAYER_PROJECTILE 3.1

/// Слой для эффектов на овермапе
#define OVERMAP_LAYER_EFFECT 3.2

// ==================== ТИПЫ ВООРУЖЕНИЯ ====================

#define SHIP_WEAPON_TYPE_LASER "laser"
#define SHIP_WEAPON_TYPE_KINETIC "kinetic"
#define SHIP_WEAPON_TYPE_MISSILE "missile"
#define SHIP_WEAPON_TYPE_ENERGY "energy"

// ==================== СОСТОЯНИЯ ВООРУЖЕНИЯ ====================

#define SHIP_WEAPON_STATE_READY "ready"
#define SHIP_WEAPON_STATE_CHARGING "charging"
#define SHIP_WEAPON_STATE_FIRING "firing"
#define SHIP_WEAPON_STATE_DAMAGED "damaged"
#define SHIP_WEAPON_STATE_DISABLED "disabled"

// ==================== СТАТУСЫ ЗАХВАТА ЦЕЛИ ====================

#define SHIP_TARGET_LOCK_NONE "none"
#define SHIP_TARGET_LOCK_ACQUIRING "acquiring"
#define SHIP_TARGET_LOCK_LOCKED "locked"
#define SHIP_TARGET_LOCK_LOST "lost"

// ==================== КОНСТАНТЫ СИСТЕМЫ БОЯ ====================

/// Максимальная дальность захвата цели по умолчанию
#define SHIP_DEFAULT_MAX_TARGET_RANGE 20

/// Время захвата цели по умолчанию
#define SHIP_DEFAULT_TARGET_LOCK_TIME 5 SECONDS

/// Интервал сканирования целей по умолчанию
#define SHIP_DEFAULT_TARGET_SCAN_INTERVAL 5 SECONDS

// ==================== ТИПЫ УРОНА ДЛЯ КОРАБЛЕЙ ====================

/// Урон по корпусу
#define SHIP_DAMAGE_HULL "hull"

/// Урон по системам
#define SHIP_DAMAGE_SYSTEMS "systems"

/// Урон по щитам
#define SHIP_DAMAGE_SHIELDS "shields"

/// Урон по двигателям
#define SHIP_DAMAGE_ENGINES "engines"

// ==================== СИСТЕМЫ КОРАБЛЯ ====================

#define SHIP_SYSTEM_WEAPONS "weapons"
#define SHIP_SYSTEM_SHIELDS "shields"
#define SHIP_SYSTEM_ENGINES "engines"
#define SHIP_SYSTEM_POWER "power"
#define SHIP_SYSTEM_LIFE_SUPPORT "life_support"
#define SHIP_SYSTEM_COMMUNICATIONS "comms"
#define SHIP_SYSTEM_SENSORS "sensors"

// ==================== УРОВНИ ПОВРЕЖДЕНИЙ ====================

#define SHIP_DAMAGE_LEVEL_NONE 0
#define SHIP_DAMAGE_LEVEL_MINOR 1
#define SHIP_DAMAGE_LEVEL_MODERATE 2
#define SHIP_DAMAGE_LEVEL_SEVERE 3
#define SHIP_DAMAGE_LEVEL_CRITICAL 4
#define SHIP_DAMAGE_LEVEL_DESTROYED 5

// ==================== ЦВЕТА ДЛЯ ИНТЕРФЕЙСА ====================

#define SHIP_COLOR_GOOD "#00FF00"
#define SHIP_COLOR_AVERAGE "#FFFF00"
#define SHIP_COLOR_BAD "#FF0000"
#define SHIP_COLOR_DISABLED "#808080"

// ==================== ЗВУКИ ====================

#define SHIP_SOUND_LASER_FIRE 'sound/weapons/laser.ogg'
#define SHIP_SOUND_KINETIC_FIRE 'sound/weapons/gun/shotgun/shot.ogg'
#define SHIP_SOUND_MISSILE_FIRE 'sound/weapons/rocket.ogg'
#define SHIP_SOUND_ENERGY_FIRE 'sound/weapons/emitter.ogg'
#define SHIP_SOUND_IMPACT_EXPLOSION 'sound/effects/explosion1.ogg'
#define SHIP_SOUND_IMPACT_LASER 'sound/weapons/sear.ogg'
#define SHIP_SOUND_TARGET_LOCK 'sound/machines/terminal_prompt.ogg'
#define SHIP_SOUND_TARGET_LOST 'sound/machines/terminal_prompt_deny.ogg'
#define SHIP_SOUND_WEAPON_DAMAGED 'sound/machines/buzz-sigh.ogg'
#define SHIP_SOUND_WEAPON_REPAIRED 'sound/machines/ping.ogg'

// ==================== ПУТИ К ФАЙЛАМ ====================

#define SHIP_FIRE_CONTROL_TGUI "fire_control.tgui"

// ==================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====================

/// Глобальный список всех систем боя
GLOBAL_LIST_EMPTY(ship_combat_systems)

/// Глобальный список всех консолей управления огнем
GLOBAL_LIST_EMPTY(ship_fire_control_consoles)

// ==================== ВСПОМОГАТЕЛЬНЫЕ МАКРОСЫ ====================

/// Макрос для проверки возможности стрельбы
#define SHIP_CAN_FIRE(weapon) (weapon.can_fire() && weapon.combat_system?.target_lock_status == SHIP_TARGET_LOCK_LOCKED)

/// Макрос для расчета расстояния между кораблями
#define SHIP_OVERMAP_DISTANCE(ship1, ship2) (sqrt((ship1.x - ship2.x)**2 + (ship1.y - ship2.y)**2))

/// Макрос для проверки в радиусе действия
#define SHIP_IN_RANGE(weapon, distance) (distance <= weapon.max_range && distance >= weapon.optimal_range * 0.5)

/// Макрос для получения прогресса в процентах
#define SHIP_GET_PROGRESS(current, max) (max > 0 ? (current / max) * 100 : 0)

/// Макрос для форматирования времени
#define SHIP_FORMAT_TIME(ticks) ("[add_leading(num2text((ticks / 10) / 60), 2, "0")]:[add_leading(num2text((ticks / 10) % 60), 2, "0")]")

// ==================== ФЛАГИ ДЛЯ СНАРЯДОВ ====================

/// Снаряд может быть перехвачен
#define SHIP_PROJECTILE_FLAG_INTERCEPTABLE (1<<0)

/// Снаряд имеет наведение
#define SHIP_PROJECTILE_FLAG_HOMING (1<<1)

/// Снаряд взрывается при приближении
#define SHIP_PROJECTILE_FLAG_PROXIMITY (1<<2)

/// Снаряд пробивает щиты
#define SHIP_PROJECTILE_FLAG_SHIELD_PIERCING (1<<3)

// ==================== ТИПЫ КОРАБЛЕЙ ====================

#define SHIP_TYPE_FRIGATE "frigate"
#define SHIP_TYPE_DESTROYER "destroyer"
#define SHIP_TYPE_CRUISER "cruiser"
#define SHIP_TYPE_BATTLESHIP "battleship"
#define SHIP_TYPE_CARRIER "carrier"
#define SHIP_TYPE_TRANSPORT "transport"
#define SHIP_TYPE_MINING "mining"
#define SHIP_TYPE_SCIENCE "science"
#define SHIP_TYPE_PIRATE "pirate"

// ==================== ФРАКЦИИ ====================

#define SHIP_FACTION_NANOTRASEN "nanotrasen"
#define SHIP_FACTION_SYNDICATE "syndicate"
#define SHIP_FACTION_SOLGOV "solgov"
#define SHIP_FACTION_INDEPENDENT "independent"
#define SHIP_FACTION_PIRATE "pirate"
#define SHIP_FACTION_ALIEN "alien"

// ==================== СТАТУСЫ БОЯ ====================

#define SHIP_COMBAT_STATUS_PEACEFUL "peaceful"
#define SHIP_COMBAT_STATUS_ALERT "alert"
#define SHIP_COMBAT_STATUS_ENGAGED "engaged"
#define SHIP_COMBAT_STATUS_RETREATING "retreating"
#define SHIP_COMBAT_STATUS_DISABLED "disabled"

// ==================== НАВЫКИ ====================

/// Навык использования корабельного оружия
#define SKILL_SHIP_WEAPONS "ship_weapons"

// ==================== БАЛАНС ОРУЖИЯ ====================

// Кинетическое оружие
#define SHIP_KINETIC_DAMAGE 30
#define SHIP_KINETIC_ACCURACY 70
#define SHIP_KINETIC_RECHARGE 8 SECONDS
#define SHIP_KINETIC_RANGE 25
#define SHIP_KINETIC_OPTIMAL_RANGE 8

// Лазерное оружие
#define SHIP_LASER_DAMAGE 25
#define SHIP_LASER_ACCURACY 85
#define SHIP_LASER_RECHARGE 6 SECONDS
#define SHIP_LASER_RANGE 35
#define SHIP_LASER_OPTIMAL_RANGE 12

// Ракетное оружие
#define SHIP_MISSILE_DAMAGE 50
#define SHIP_MISSILE_ACCURACY 90
#define SHIP_MISSILE_RECHARGE 20 SECONDS
#define SHIP_MISSILE_RANGE 40
#define SHIP_MISSILE_OPTIMAL_RANGE 15

// Энергетическое оружие
#define SHIP_ENERGY_DAMAGE 40
#define SHIP_ENERGY_ACCURACY 80
#define SHIP_ENERGY_RECHARGE 15 SECONDS
#define SHIP_ENERGY_RANGE 30
#define SHIP_ENERGY_OPTIMAL_RANGE 10

// ==================== ХАРАКТЕРИСТИКИ КОРАБЛЕЙ ====================

// Фрегат
#define SHIP_FRIGATE_HEALTH 100
#define SHIP_FRIGATE_SHIELDS 50
#define SHIP_FRIGATE_SPEED 1.0

// Эсминец
#define SHIP_DESTROYER_HEALTH 150
#define SHIP_DESTROYER_SHIELDS 75
#define SHIP_DESTROYER_SPEED 0.9

// Крейсер
#define SHIP_CRUISER_HEALTH 200
#define SHIP_CRUISER_SHIELDS 100
#define SHIP_CRUISER_SPEED 0.8

// Линкор
#define SHIP_BATTLESHIP_HEALTH 300
#define SHIP_BATTLESHIP_SHIELDS 150
#define SHIP_BATTLESHIP_SPEED 0.7

// ==================== ПУТИ К ФАЙЛАМ СИСТЕМЫ ====================

#define SHIP_COMBAT_SYSTEM_PATH /datum/ship_combat_system
#define SHIP_WEAPON_PATH /obj/machinery/ship_weapon
#define SHIP_PROJECTILE_PATH /obj/projectile/ship_projectile
#define SHIP_FIRE_CONTROL_PATH /obj/machinery/computer/ship/fire_control

// ==================== ПРОЦЕДУРЫ ====================

/// Глобальная процедура для получения системы боя корабля
#define GET_SHIP_COMBAT_SYSTEM(ship) (ship.combat_system || new /datum/ship_combat_system(ship))

/// Глобальная процедура для логирования боевых действий
#define LOG_SHIP_COMBAT(message) log_game("КОСМИЧЕСКИЙ БОЙ: [message]"); message_admins("КОСМИЧЕСКИЙ БОЙ: [message]")


// ==================== VV ДЕФАЙНЫ ====================

#define VV_HK_VIEW_COMBAT_STATS "view_combat_stats"
#define VV_HK_UPDATE_COMBAT_STATS "update_combat_stats"
#define VV_HK_HEAL_SHIP "heal_ship"

// ==================== ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ ====================

/// Размер корабля по умолчанию (в тайлах)
#define SHIP_DEFAULT_SIZE 50

/// Здоровье корпуса по умолчанию (для неизвестных кораблей)
#define SHIP_DEFAULT_HULL_HEALTH 2500

/// Прочность щитов по умолчанию
#define SHIP_DEFAULT_SHIELD_STRENGTH 1500

/// Броня по умолчанию (%)
#define SHIP_DEFAULT_ARMOR 10
