/**
 * # Реалистичная система повреждений кораблей
 *
 * Основана на:
 * 1. Размере корабля (чем больше, тем больше HP)
 * 2. Типе корабля (линкор прочнее фрегата)
 * 3. Броне (толщина обшивки)
 * 4. Разделении на отсеки
 */

// ==================== БАЗОВЫЕ РАСЧЕТЫ ====================

/**
 * Расчет максимального здоровья корпуса на основе размера корабля
 * 
 * @param ship_size - количество тайлов на карте корабля
 * @param ship_class - класс корабля (фрегат, крейсер, линкор)
 * @return максимальное здоровье корпуса
 */
/proc/calculate_max_hull_health(ship_size, ship_class)
	// Базовое здоровье: 50 HP за каждый тайл корабля
	var/base_health = ship_size * 50
	
	// Множитель в зависимости от класса корабля
	var/class_multiplier = 1.0
	switch(ship_class)
		if(SHIP_TYPE_FRIGATE)
			class_multiplier = 1.0      // Стандарт
		if(SHIP_TYPE_DESTROYER)
			class_multiplier = 1.5      // +50% прочности
		if(SHIP_TYPE_CRUISER)
			class_multiplier = 2.0      // +100% прочности
		if(SHIP_TYPE_BATTLESHIP)
			class_multiplier = 3.0      // +200% прочности
		if(SHIP_TYPE_CARRIER)
			class_multiplier = 2.5      // +150% прочности
		if(SHIP_TYPE_TRANSPORT)
			class_multiplier = 1.2      // +20% прочности (гражданские)
		if(SHIP_TYPE_PIRATE)
			class_multiplier = 1.3      // +30% прочности (модифицированные)
	
	return round(base_health * class_multiplier)

/**
 * Расчет максимальной прочности щитов
 * 
 * @param ship_size - размер корабля
 * @param tech_level - технологический уровень (1-10)
 * @return максимальная прочность щитов
 */
/proc/calculate_max_shield_strength(ship_size, tech_level)
	// Базовая прочность: 20 единиц за тайл
	var/base_shield = ship_size * 20
	
	// Множитель технологий (1.0 - примитивные, 2.0 - передовые)
	var/tech_multiplier = 0.5 + (tech_level * 0.15)
	
	return round(base_shield * tech_multiplier)

/**
 * Расчет значения брони
 * 
 * @param ship_class - класс корабля
 * @param armor_type - тип брони (light, medium, heavy)
 * @return процент поглощаемого урона (0-80%)
 */
/proc/calculate_armor_value(ship_class, armor_type = "medium")
	// Базовая броня по классу
	var/base_armor = 0
	switch(ship_class)
		if(SHIP_TYPE_FRIGATE)
			base_armor = 10    // 10% поглощения
		if(SHIP_TYPE_DESTROYER)
			base_armor = 20    // 20% поглощения
		if(SHIP_TYPE_CRUISER)
			base_armor = 30    // 30% поглощения
		if(SHIP_TYPE_BATTLESHIP)
			base_armor = 40    // 40% поглощения
		if(SHIP_TYPE_CARRIER)
			base_armor = 25    // 25% поглощения
		if(SHIP_TYPE_TRANSPORT)
			base_armor = 5     // 5% поглощения (гражданские)
		if(SHIP_TYPE_PIRATE)
			base_armor = 15    // 15% поглощения (самодельная)
	
	// Модификатор типа брони
	var/armor_modifier = 1.0
	switch(armor_type)
		if("light")
			armor_modifier = 0.7    // -30%
		if("medium")
			armor_modifier = 1.0    // Стандарт
		if("heavy")
			armor_modifier = 1.5    // +50%
	
	return min(80, round(base_armor * armor_modifier))  // Максимум 80%

// ==================== СИСТЕМА ОТСЕКОВ ====================

/**
 * Отсек корабля
 * Каждый отсек имеет свое здоровье и может быть уничтожен независимо
 */
/datum/ship_compartment
	var/name = "Отсек"
	var/health = 100
	var/max_health = 100
	var/fire_risk = 0           // Риск пожара
	var/breach_risk = 0         // Риск разгерметизации
	var/systems_integrity = 100 // Целостность систем
	var/damaged = FALSE
	var/destroyed = FALSE

/**
 * Расчет количества отсеков на основе размера корабля
 * 
 * @param ship_size - количество тайлов
 * @return количество отсеков
 */
/proc/calculate_compartment_count(ship_size)
	// Примерно 1 отсек на каждые 25 тайлов
	return max(3, round(ship_size / 25))

// ==================== ПРИМЕРЫ ДЛЯ РАЗНЫХ КОРАБЛЕЙ ====================

/**
 * Пример: Маленький фрегат (50 тайлов)
 * - Корпус: 50 * 50 * 1.0 = 2,500 HP
 * - Щиты: 50 * 20 * 1.5 = 1,500 SP (tech level 5)
 * - Броня: 10%
 * - Отсеков: 2
 * - Выживаемость: ~10-15 попаданий из кинетической пушки
 */
/datum/overmap/ship/example_frigate
	name = "Фрегат"
	ship_type = SHIP_TYPE_FRIGATE
	
	// Автоматический расчет при инициализации
	max_hull_health = 2500
	hull_health = 2500
	max_shield_strength = 1500
	shield_strength = 1500
	
	// Броня
	var/armor_value = 10

/**
 * Пример: Средний крейсер (150 тайлов)
 * - Корпус: 150 * 50 * 2.0 = 15,000 HP
 * - Щиты: 150 * 20 * 2.0 = 6,000 SP (tech level 10)
 * - Броня: 30%
 * - Отсеков: 6
 * - Выживаемость: ~40-50 попаданий
 */
/datum/overmap/ship/example_cruiser
	name = "Крейсер"
	ship_type = SHIP_TYPE_CRUISER
	
	max_hull_health = 15000
	hull_health = 15000
	max_shield_strength = 6000
	shield_strength = 6000
	
	armor_value = 30

/**
 * Пример: Огромный линкор (400 тайлов) - как Посейдон
 * - Корпус: 400 * 50 * 3.0 = 60,000 HP
 * - Щиты: 400 * 20 * 2.0 = 16,000 SP (tech level 10)
 * - Броня: 40%
 * - Отсеков: 16
 * - Выживаемость: ~150-200 попаданий
 */
/datum/overmap/ship/example_battleship
	name = "Линкор Посейдон"
	ship_type = SHIP_TYPE_BATTLESHIP
	
	max_hull_health = 60000
	hull_health = 60000
	max_shield_strength = 16000
	shield_strength = 16000
	
	armor_value = 40

// ==================== ПРИМЕНЕНИЕ УРОНА С УЧЕТОМ БРОНИ ====================

/**
 * Улучшенная система нанесения урона
 * 
 * @param damage - базовый урон оружия
 * @param damage_type - тип урона
 * @param armor_penetration - пробитие брони (0-100%)
 */
/datum/overmap/ship/proc/take_realistic_damage(damage, damage_type, armor_penetration = 0)
	if(destroyed)
		return
	
	// 1. Щиты поглощают часть урона
	if(shields_active && shield_strength > 0)
		var/shield_absorbtion = min(shield_strength, damage * 0.8) // Щиты поглощают 80%
		shield_strength -= shield_absorbtion
		damage -= shield_absorbtion
		
		if(shield_strength <= 0)
			shields_active = FALSE
			on_shields_down()
	
	// 2. Броня уменьшает урон
	var/effective_armor = max(0, armor_value - armor_penetration)
	var/armor_reduction = damage * (effective_armor / 100)
	damage -= armor_reduction
	
	// 3. Оставшийся урон идет по корпусу
	hull_health -= damage
	
	// 4. Проверка критического состояния
	if(hull_health <= max_hull_health * 0.3)
		on_critical_damage()
	
	// 5. Проверка уничтожения
	if(hull_health <= 0)
		destroy_ship()

// ==================== ПРИМЕРЫ ОРУЖИЯ С РЕАЛИСТИЧНЫМ УрОНОМ ====================

/**
 * Кинетическая пушка
 * Урон: 150 (бронебойный)
 * Пробитие: 30%
 * Против линкора: 60,000 HP / 150 = 400 попаданий (со щитами и броней ~150-200)
 */
/obj/machinery/ship_weapon/kinetic_cannon
	name = "Тяжелая кинетическая пушка"
	damage = 150
	armor_penetration = 30

/**
 * Лазерная пушка
 * Урон: 80 (эффективен против щитов)
 * Пробитие: 10%
 * Бонус против щитов: +50% урона
 */
/obj/machinery/ship_weapon/laser_cannon
	name = "Лазерная батарея"
	damage = 80
	armor_penetration = 10
	shield_damage_multiplier = 1.5

/**
 * Ракетная установка
 * Урон: 300 (высокий)
 * Пробитие: 50%
 * Медленная перезарядка
 */
/obj/machinery/ship_weapon/missile_launcher
	name = "Ракетная установка"
	damage = 300
	armor_penetration = 50

/**
 * Энергетическая пушка
 * Урон: 200
 * Пробитие: 40%
 * Высокое потребление энергии
 */
/obj/machinery/ship_weapon/energy_cannon
	name = "Энергетическая пушка"
	damage = 200
	armor_penetration = 40

// ==================== ТАБЛИЦА БАЛАНСА ====================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                    БАЛАНС СИСТЕМЫ ПОВРЕЖДЕНИЙ                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ КОРАБЛЬ          │ HP      │ Щиты   │ Броня │ Попаданий до уничтожения      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Фрегат (50 т)    │ 2,500   │ 1,500  │ 10%   │ 10-15 выстрелов               ║
║ Эсминец (100 т)  │ 7,500   │ 3,000  │ 20%   │ 20-30 выстрелов               ║
║ Крейсер (150 т)  │ 15,000  │ 6,000  │ 30%   │ 40-50 выстрелов               ║
║ Линкор (400 т)   │ 60,000  │ 16,000 │ 40%   │ 150-200 выстрелов             ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ОРУЖИЕ           │ Урон    │ Пробитие│ Эффективность против линкора         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Кинетическая     │ 150     │ 30%    │ ~200 попаданий                       ║
║ Лазерная         │ 80      │ 10%    │ ~400 попаданий (эффективен vs щиты)  ║
║ Ракетная         │ 300     │ 50%    │ ~100 попаданий                       ║
║ Энергетическая   │ 200     │ 40%    │ ~150 попаданий                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

Примечания:
1. Размер корабля = количество тайлов на карте
2. HP = размер * 50 * множитель_класса
3. Щиты = размер * 20 * уровень_технологий
4. Броня = базовая_броня_класса * модификатор_типа
5. Эффективное попадание = урон * (1 - броня + пробитие)
*/

// ==================== ИНТЕГРАЦИЯ С СУЩЕСТВУЮЩИМИ КОРАБЛЯМИ ====================

/**
 * Автоматический расчет характеристик при инициализации корабля
 */
/datum/overmap/ship/proc/initialize_combat_stats()
	// Определяем размер корабля (количество тайлов)
	var/ship_size = calculate_ship_size()
	
	// Рассчитываем характеристики
	max_hull_health = calculate_max_hull_health(ship_size, ship_type)
	hull_health = max_hull_health
	
	max_shield_strength = calculate_max_shield_strength(ship_size, get_tech_level())
	shield_strength = max_shield_strength
	
	armor_value = calculate_armor_value(ship_type, get_armor_type())
	
	// Создаем отсеки
	create_compartments(ship_size)

/**
 * Расчет размера корабля
 */
/datum/overmap/ship/proc/calculate_ship_size()
	if(!shuttle_port)
		return 50 // По умолчанию маленький корабль
	
	// Получаем границы зоны корабля
	var/area/ship_area = get_area(shuttle_port)
	if(!ship_area)
		return 50
	
	var/width = ship_area.x2 - ship_area.x
	var/height = ship_area.y2 - ship_area.y
	
	return width * height

/**
 * Получение технологического уровня корабля
 */
/datum/overmap/ship/proc/get_tech_level()
	// Можно расширить для разных фракций
	switch(faction)
		if(SHIP_FACTION_NANOTRASEN)
			return 8  // Высокие технологии
		if(SHIP_FACTION_SYNDICATE)
			return 7  // Хорошие технологии
		if(SHIP_FACTION_SOLGOV)
			return 6  // Средние технологии
		if(SHIP_FACTION_PIRATE)
			return 4  // Низкие технологии
		else
			return 5  // Стандарт

/**
 * Получение типа брони
 */
/datum/overmap/ship/proc/get_armor_type()
	// Можно настроить для разных кораблей
	return "medium" // По умолчанию средняя броня
