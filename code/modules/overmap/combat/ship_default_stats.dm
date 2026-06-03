/**
 * # Параметры по умолчанию для кораблей
 *
 * Автоматически применяется ко всем кораблям, если не указано иное в конфигурации
 */

// ==================== СИСТЕМА АВТОМАТИЧЕСКОГО РАСЧЕТА ====================

/**
 * Автоматическая инициализация боевых параметров при создании корабля
 * Вызывается автоматически при создании любого корабля
 */
/datum/overmap/ship/proc/auto_initialize_combat_stats()
	// Определяем размер корабля
	var/ship_size = calculate_ship_size_from_map()

	// Определяем класс корабля на основе размера
	var/detected_class = detect_ship_class(ship_size)

	// Устанавливаем тип корабля, если не задан
	if(!ship_type)
		ship_type = detected_class

	// Устанавливаем фракцию, если не задана
	if(!faction)
		faction = SHIP_FACTION_INDEPENDENT

	// Рассчитываем боевые характеристики
	initialize_combat_stats(ship_size)

/**
 * Расчет размера корабля на основе карты
 */
/datum/overmap/ship/proc/calculate_ship_size_from_map()
	// Для управляемых кораблей используем shuttle_port или source_template
	if(istype(src, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/controlled_ship = src

		// Если есть shuttle_port, используем его зону
		if(controlled_ship.shuttle_port)
			// Получаем зону шаттла через shuttle_areas
			var/list/areas = controlled_ship.shuttle_port.shuttle_areas
			if(length(areas))
				var/area/ship_area = areas[1]
				// Рассчитываем размер зоны на основе содержимого
				var/min_x = INFINITY
				var/max_x = -INFINITY
				var/min_y = INFINITY
				var/max_y = -INFINITY
				var/tile_count = 0

				for(var/turf/T in ship_area.contents)
					tile_count++
					if(T.x < min_x)
						min_x = T.x
					if(T.x > max_x)
						max_x = T.x
					if(T.y < min_y)
						min_y = T.y
					if(T.y > max_y)
						max_y = T.y

				if(tile_count > 0)
					var/width = max_x - min_x + 1
					var/height = max_y - min_y + 1
					return width * height

		// Если есть source_template, используем его размер
		if(controlled_ship.source_template)
			// Используем размеры шаблона
			return controlled_ship.source_template.width * controlled_ship.source_template.height

	// По умолчанию - маленький корабль (50 тайлов)
	return 50  // SHIP_DEFAULT_SIZE

/**
 * Определение класса корабля по размеру
 */
/datum/overmap/ship/proc/detect_ship_class(ship_size)
	// Классификация по размеру
	if(ship_size <= 75)
		return SHIP_TYPE_FRIGATE      // Маленький
	else if(ship_size <= 150)
		return SHIP_TYPE_DESTROYER    // Средний
	else if(ship_size <= 300)
		return SHIP_TYPE_CRUISER      // Большой
	else if(ship_size <= 500)
		return SHIP_TYPE_BATTLESHIP   // Огромный
	else
		return SHIP_TYPE_CARRIER      // Гигантский

/**
 * Инициализация боевых характеристик
 */
/datum/overmap/ship/proc/initialize_combat_stats(ship_size)
	// === ЗДОРОВЬЕ КОРПУСА ===
	if(!max_hull_health)
		max_hull_health = calculate_max_hull_health(ship_size, ship_type)
	if(!hull_health)
		hull_health = max_hull_health

	// === ЩИТЫ ===
	if(!max_shield_strength)
		max_shield_strength = calculate_max_shield_strength(ship_size, get_tech_level())
	if(!shield_strength)
		shield_strength = max_shield_strength

	// === БРОНЯ ===
	if(!armor_value)
		armor_value = calculate_armor_value(ship_type, get_armor_type())

	// === СИСТЕМЫ ===
	initialize_system_damage()

	// === СИСТЕМА БОЯ ===
	// Создаем систему боя для управляемых кораблей
	if(istype(src, /datum/overmap/ship/controlled) && !combat_system)
		combat_system = new /datum/ship_combat_system(src)

	// Обновляем визуальные эффекты
	update_damage_effects()

// ==================== ПРИМЕНЕНИЕ ПРИ СОЗДАНИИ КОРАБЛЯ ====================

/**
 * Автоматическое применение при создании корабля
 */
/datum/overmap/ship/New(location, system)
	. = ..()

	// Автоматически инициализируем боевые параметры
	// Задержка нужна для того, чтобы shuttle_port успел инициализироваться
	addtimer(CALLBACK(src, PROC_REF(auto_initialize_combat_stats)), 1 SECONDS)

// ==================== ИНТЕГРАЦИЯ С СУЩЕСТВУЮЩИМИ СИСТЕМАМИ ====================

/**
 * Интеграция с системой создания кораблей из шаблонов
 */
/datum/overmap/ship/controlled/connect_new_shuttle_port(obj/docking_port/mobile/new_port)
	. = ..()

	// Переинициализируем боевые параметры при подключении нового порта
	if(new_port)
		addtimer(CALLBACK(src, PROC_REF(auto_initialize_combat_stats)), 1 SECONDS)

/**
 * Интеграция с системой Rename
 */
/datum/overmap/ship/controlled/Rename(new_name, force = FALSE)
	. = ..()

	// При переименовании обновляем визуальные эффекты
	update_damage_effects()

// ==================== ПАРАМЕТРЫ ДЛЯ РАЗНЫХ ФРАКЦИЙ ====================

/**
 * Получение технологического уровня в зависимости от фракции
 */
/datum/overmap/ship/proc/get_tech_level()
	// Проверяем, есть ли кастомный уровень технологий
	if(tech_level)
		return tech_level

	// Определяем по фракции
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
 * Получение типа брони в зависимости от класса корабля
 */
/datum/overmap/ship/proc/get_armor_type()
	// Проверяем, есть ли кастомный тип брони
	if(custom_armor_type)
		return custom_armor_type

	// Определяем по классу корабля
	switch(ship_type)
		if(SHIP_TYPE_FRIGATE, SHIP_TYPE_TRANSPORT, SHIP_TYPE_MINING, SHIP_TYPE_SCIENCE)
			return "light"    // Легкая броня
		if(SHIP_TYPE_DESTROYER, SHIP_TYPE_CRUISER, SHIP_TYPE_CARRIER)
			return "medium"   // Средняя броня
		if(SHIP_TYPE_BATTLESHIP, SHIP_TYPE_PIRATE)
			return "heavy"    // Тяжелая броня
		else
			return "medium"   // По умолчанию

// ==================== ПРИМЕРЫ ДЛЯ КОНФИГУРАЦИИ ====================

/*
 * Если вы хотите задать конкретные параметры в конфигурации корабля,
 * добавьте следующие поля в JSON файл:
 *
 * {
 *   "combat_stats": {
 *     "hull_health": 60000,           // Здоровье корпуса
 *     "shield_strength": 16000,       // Прочность щитов
 *     "armor_value": 40,              // Броня (%)
 *     "ship_class": "battleship",     // Класс корабля
 *     "tech_level": 8,                // Технологический уровень
 *     "armor_type": "heavy"           // Тип брони
 *   }
 * }
 *
 * Если поля не указаны, система автоматически рассчитает параметры
 * на основе размера корабля и его фракции.
 */

// ==================== СИСТЕМА ОБНОВЛЕНИЯ ====================

/**
 * Обновление боевых параметров при изменении размера корабля
 */
/datum/overmap/ship/proc/update_combat_stats()
	auto_initialize_combat_stats()

/**
 * Получение текущих боевых характеристик
 */
/datum/overmap/ship/proc/get_combat_stats()
	var/list/stats = list()

	stats["hull_health"] = hull_health
	stats["max_hull_health"] = max_hull_health
	stats["shield_strength"] = shield_strength
	stats["max_shield_strength"] = max_shield_strength
	stats["armor_value"] = armor_value
	stats["ship_type"] = ship_type
	stats["faction"] = faction
	stats["combat_status"] = combat_status
	stats["destroyed"] = destroyed

	if(combat_system)
		stats["weapons_count"] = length(combat_system.weapons)
		stats["active_projectiles"] = length(combat_system.active_projectiles)
		stats["target"] = combat_system.target ? combat_system.target.name : null
	else
		stats["weapons_count"] = 0
		stats["active_projectiles"] = 0
		stats["target"] = null

	return stats

// ==================== VV ПОДДЕРЖКА ====================

/datum/overmap/ship/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "--- Боевая система ---")
	VV_DROPDOWN_OPTION(VV_HK_VIEW_COMBAT_STATS, "Просмотреть боевые характеристики")
	VV_DROPDOWN_OPTION(VV_HK_UPDATE_COMBAT_STATS, "Обновить боевые характеристики")
	VV_DROPDOWN_OPTION(VV_HK_HEAL_SHIP, "Восстановить корабль")

/datum/overmap/ship/vv_do_topic(list/href_list)
	. = ..()

	if(href_list[VV_HK_VIEW_COMBAT_STATS])
		usr << browse(json_encode(get_combat_stats()), "window=combat_stats")

	if(href_list[VV_HK_UPDATE_COMBAT_STATS])
		update_combat_stats()
		to_chat(usr, span_notice("Боевые характеристики обновлены."))

	if(href_list[VV_HK_HEAL_SHIP])
		hull_health = max_hull_health
		shield_strength = max_shield_strength
		shields_active = TRUE
		destroyed = FALSE
		combat_status = SHIP_COMBAT_STATUS_PEACEFUL
		initialize_system_damage()
		update_damage_effects()
		to_chat(usr, span_notice("Корабль полностью восстановлен."))
