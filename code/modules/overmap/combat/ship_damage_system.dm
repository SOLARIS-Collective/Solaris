/*
 * # Реалистичная система повреждений кораблей
 *
 * Основана на:
 * 1. Размере корабля (чем больше, тем больше HP)
 * 2. Типе корабля (линкор прочнее фрегата)
 * 3. Броне (толщина обшивки)
 * 4. Разделении на отсеки
 */

// ==================== БАЗОВЫЕ РАСЧЕТЫ ====================

/*
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

/*
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

/*
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

/*
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
	var/area_type = null        // Тип зоны, на основе которой создан отсек (для отладки)

/*
 * Расчет количества отсеков на основе размера корабля
 *
 * @param ship_size - количество тайлов
 * @return количество отсеков
 */
/proc/calculate_compartment_count(ship_size)
	// Примерно 1 отсек на каждые 25 тайлов, но минимум 3
	return max(3, round(ship_size / 25))

/*
 * Получение названия отсека на основе типа зоны
 *
 * Словарь основан на всех типах зон из /code/game/area/ship_areas.dm
 * Обновлен 30 мая 2026 года для полного покрытия всех зон кораблей
 */
/proc/get_compartment_name_from_area(area_type)
	// Словарь для преобразования типов зон в названия отсеков
	var/static/list/area_to_compartment_name = list(
		// Основные зоны корабля
		/area/ship = "Основной отсек",
		/area/ship/bridge = "Командный отсек",

		// Командные и жилые зоны
		/area/ship/crew = "Жилой отсек",
		/area/ship/crew/crewtwo = "Каюты экипажа 2",
		/area/ship/crew/crewthree = "Каюты экипажа 3",
		/area/ship/crew/crewfour = "Каюты экипажа 4",
		/area/ship/crew/crewfive = "Каюты экипажа 5",
		/area/ship/crew/specialized = "Специализированные каюты",
		/area/ship/crew/specialized/medical = "Каюта медспециалиста",
		/area/ship/crew/specialized/security = "Каюта охранника",
		/area/ship/crew/specialized/engineering = "Каюта инженера",
		/area/ship/crew/specialized/cargo = "Каюта грузчика",
		/area/ship/crew/cryo = "Криокамеры",
		/area/ship/crew/dorm = "Общежитие",
		/area/ship/crew/dorm/dormtwo = "Общежитие 2",
		/area/ship/crew/dorm/dormthree = "Общежитие 3",
		/area/ship/crew/dorm/dormfour = "Общежитие 4",
		/area/ship/crew/dorm/dormfive = "Общежитие 5",
		/area/ship/crew/dorm/captain = "Каюта капитана",
		/area/ship/crew/dorm/commad = "Командные каюты",
		/area/ship/crew/toilet = "Туалет",
		/area/ship/crew/toilet/two = "Туалет 2",
		/area/ship/crew/toilet/three = "Туалет 3",
		/area/ship/crew/canteen = "Столовая",
		/area/ship/crew/canteen/kitchen = "Камбуз",
		/area/ship/crew/hydroponics = "Гидропоника",
		/area/ship/crew/chapel = "Часовня",
		/area/ship/crew/chapel/office = "Офис часовни",
		/area/ship/crew/library = "Библиотека",
		/area/ship/crew/law_office = "Юридический офис",
		/area/ship/crew/solgov = "Консульство СолГов",
		/area/ship/crew/office = "Офис",
		/area/ship/crew/office/lobby = "Лобби",
		/area/ship/crew/ccommons = "Общая зона",
		/area/ship/crew/janitor = "Кладовая уборщика",

		// Медицинские зоны
		/area/ship/medical = "Медблок",
		/area/ship/medical/surgery = "Хирургический блок",
		/area/ship/medical/morgue = "Морг",
		/area/ship/medical/psych = "Кабинет психолога",

		// Научные зоны
		/area/ship/science = "Научная лаборатория",
		/area/ship/science/xenobiology = "Ксено-лаборатория",
		/area/ship/science/storage = "Хранилище токсинов",
		/area/science/misc_lab = "Тестовая лаборатория",
		/area/ship/science/robotics = "Робототехника",
		/area/ship/science/ai_chamber = "Камера ИИ",
		/area/ship/science/workshop = "Мастерская",

		// Инженерные зоны
		/area/ship/engineering = "Инженерный отсек",
		/area/ship/engineering/engines = "Двигательный отсек",
		/area/ship/engineering/engines/port = "Порт двигатели",
		/area/ship/engineering/engines/starboard = "Старборд двигатели",
		/area/ship/engineering/atmospherics = "Атмосферный отсек",
		/area/ship/engineering/electrical = "Электрощитовая",
		/area/ship/engineering/communications = "Коммуникационный отсек",
		/area/ship/engineering/communications/room = "Комната связи",
		/area/ship/engineering/engine = "Машинное отделение",
		/area/ship/engineering/incinerator = "Инсинератор",

		// Охранные зоны
		/area/ship/security = "Охранный отсек",
		/area/ship/security/prison = "Тюремные камеры",
		/area/ship/security/range = "Стрельбище",
		/area/ship/security/armory = "Оружейная",
		/area/ship/security/dock = "Док безопасности",

		// Грузовые зоны
		/area/ship/cargo = "Грузовой отсек",
		/area/ship/cargo/office = "Офис грузчиков",
		/area/ship/cargo/port = "Порт грузовой отсек",
		/area/ship/cargo/starboard = "Старборд грузовой отсек",

		// Ангары
		/area/ship/hangar = "Ангар",
		/area/ship/hangar/port = "Порт ангар",
		/area/ship/hangar/starboard = "Старборд ангар",

		// Коридоры
		/area/ship/hallway = "Коридор",
		/area/ship/hallway/aft = "Кормовой коридор",
		/area/ship/hallway/fore = "Носовой коридор",
		/area/ship/hallway/starboard = "Старборд коридор",
		/area/ship/hallway/port = "Порт коридор",
		/area/ship/hallway/central = "Центральный коридор",

		// Технические зоны
		/area/ship/maintenance = "Технический отсек",
		/area/ship/maintenance/aft = "Кормовой техотсек",
		/area/ship/maintenance/fore = "Носовой техотсек",
		/area/ship/maintenance/starboard = "Старборд техотсек",
		/area/ship/maintenance/port = "Порт техотсек",
		/area/ship/maintenance/central = "Центральный техотсек",
		/area/ship/maintenance/external = "Внешний доступ к корпусу",

		// Строительные зоны
		/area/ship/construction = "Строительная зона",

		// Складские зоны
		/area/ship/storage = "Склад",
		/area/ship/storage/port = "Порт склад",
		/area/ship/storage/starboard = "Старборд склад",
		/area/ship/storage/eva = "Хранилище EVA",
		/area/ship/storage/equip = "Комната оборудования",

		// Внешние зоны
		/area/ship/external = "Внешняя зона"
	)

	// Ищем точное совпадение
	if(area_type in area_to_compartment_name)
		return area_to_compartment_name[area_type]

	// Ищем совпадение по родительскому типу
	for(var/area_parent in area_to_compartment_name)
		if(ispath(area_type, area_parent))
			return area_to_compartment_name[area_parent]

	// Если не нашли, используем название зоны
	var/area/area_instance = area_type
	return initial(area_instance.name) || "Неизвестный отсек"

// ==================== ОТЛАДОЧНЫЕ ФУНКЦИИ ====================

/*
 * Отладочная функция для вывода информации о зонах корабля
 * Игнорирует зоны /area/template_noop и тайлы /turf/template_noop
 */
/datum/overmap/ship/controlled/proc/debug_ship_areas()
	if(!shuttle_port)
		return "Корабль не имеет shuttle_port"

	var/list/areas = shuttle_port.shuttle_areas
	if(!length(areas))
		return "Корабль не имеет зон"

	var/result = "Информация о зонах корабля [name]:\n"
	var/total_tiles = 0
	var/ship_tiles = 0
	var/template_noop_tiles = 0
	var/list/unique_areas = list()

	for(var/area/shuttle_area in areas)
		// Игнорируем template_noop зоны
		if(istype(shuttle_area, /area/template_noop))
			continue

		var/area_tiles = 0
		var/area_template_noop_tiles = 0

		for(var/turf/T in shuttle_area)
			// Игнорируем template_noop тайлы
			if(istype(T, /turf/template_noop))
				area_template_noop_tiles++
				template_noop_tiles++
				continue

			area_tiles++
			total_tiles++

		// Проверяем, является ли зона частью корабля
		var/is_ship_area = istype(shuttle_area, /area/ship)

		if(is_ship_area)
			ship_tiles += area_tiles
			var/area_type = shuttle_area.type
			if(!(area_type in unique_areas))
				unique_areas += area_type

		result += "  [shuttle_area.type]: [area_tiles] тайлов"
		if(area_template_noop_tiles > 0)
			result += " (игнорировано [area_template_noop_tiles] template_noop тайлов)"
		if(is_ship_area)
			result += " (зона корабля)"
		result += "\n"

	// Добавляем информацию о template_noop зонах
	var/template_noop_zone_count = 0
	for(var/area/shuttle_area in areas)
		if(istype(shuttle_area, /area/template_noop))
			template_noop_zone_count++

	if(template_noop_zone_count > 0)
		result += "\nИгнорированные зоны template_noop: [template_noop_zone_count]\n"

	result += "\nИтого:\n"
	result += "  Всего тайлов (без template_noop): [total_tiles]\n"
	result += "  Тайлов корабля (ship зоны): [ship_tiles]\n"
	result += "  Игнорировано template_noop тайлов: [template_noop_tiles]\n"
	result += "  Уникальных зон корабля: [length(unique_areas)]\n"

	if(length(unique_areas) > 0)
		result += "  Уникальные зоны корабля:\n"
		for(var/area_type in unique_areas)
			var/area_name = get_compartment_name_from_area(area_type)
			result += "    - [area_type]: [area_name]\n"

	return result

// ==================== ИНТЕРФЕЙС ДЛЯ ИГРОКОВ ====================

/**
 * Получить информацию об отсеках корабля для отображения игрокам
 * Возвращает форматированный текст с информацией об отсеках
 */
/datum/overmap/ship/proc/get_compartments_info()
	if(!length(compartments))
		return "Информация об отсеках недоступна"

	var/info = "<div class='compartments-info'><h3>Отсеки корабля [name]</h3>"
	info += "<table class='compartments-table'>"
	info += "<tr><th>№</th><th>Отсек</th><th>Состояние</th><th>Риск пожара</th><th>Риск разгерметизации</th></tr>"

	for(var/i = 1 to length(compartments))
		var/datum/ship_compartment/compartment = compartments[i]
		var/health_percent = round((compartment.health / compartment.max_health) * 100)
		var/health_color = health_percent > 70 ? "green" : health_percent > 30 ? "orange" : "red"
		var/health_text = "<span style='color: [health_color]'>[health_percent]%</span>"

		info += "<tr>"
		info += "<td>[i]</td>"
		info += "<td><b>[compartment.name]</b></td>"
		info += "<td>[health_text]</td>"
		info += "<td>[compartment.fire_risk]%</td>"
		info += "<td>[compartment.breach_risk]%</td>"
		info += "</tr>"

	info += "</table>"
	info += "<p>Всего отсеков: [length(compartments)]</p>"
	info += "</div>"

	return info

/**
 * Показать информацию об отсеках в чат (для отладки или админов)
 */
/datum/overmap/ship/proc/show_compartments_to(mob/user)
	if(!user)
		return

	var/info = get_compartments_info()
	to_chat(user, boxed_message(info))

/**
 * Получить краткую сводку состояния отсеков
 */
/datum/overmap/ship/proc/get_compartments_summary()
	if(!length(compartments))
		return "Нет информации об отсеках"

	var/damaged_count = 0
	var/destroyed_count = 0
	var/total_health = 0
	var/total_max_health = 0

	for(var/datum/ship_compartment/compartment in compartments)
		total_health += compartment.health
		total_max_health += compartment.max_health
		if(compartment.damaged)
			damaged_count++
		if(compartment.destroyed)
			destroyed_count++

	var/overall_health = total_max_health > 0 ? round((total_health / total_max_health) * 100) : 0
	var/health_color = overall_health > 70 ? "green" : overall_health > 30 ? "orange" : "red"

	var/summary = "<span style='color: [health_color]'><b>Общее состояние отсеков: [overall_health]%</b></span>\n"
	summary += "Отсеков: [length(compartments)]"

	if(damaged_count > 0)
		summary += ", <span style='color: orange'>повреждено: [damaged_count]</span>"
	if(destroyed_count > 0)
		summary += ", <span style='color: red'>уничтожено: [destroyed_count]</span>"

	return summary

/**
 * Команда для отображения информации об отсеках в чат
 * Использование: say "!отсеки" или "!compartments"
 */
/datum/overmap/ship/controlled/proc/command_show_compartments(mob/user)
	if(!user || !user.client)
		return

	show_compartments_to(user)
	to_chat(user, span_notice("Информация об отсеках корабля [name] отображена."))

// ==================== ТЕСТОВЫЕ ФУНКЦИИ ====================

/*
 * Тестовая функция для проверки системы расчета размеров корабля
 */
/datum/overmap/ship/controlled/proc/test_ship_size_calculation()
	var/result = "=== Тест системы расчета размеров корабля ===\n"

	// 1. Получаем информацию о зонах
	result += debug_ship_areas()
	result += "\n\n"

	// 2. Рассчитываем размер корабля
	var/ship_size = calculate_ship_size()
	result += "Рассчитанный размер корабля: [ship_size] тайлов\n"

	// 3. Создаем отсеки (если еще не созданы)
	if(length(compartments) == 0)
		create_compartments(ship_size)

	// 4. Выводим информацию об отсеках
	result += "Количество отсеков: [length(compartments)]\n"
	if(length(compartments) > 0)
		result += "Отсеки корабля:\n"
		for(var/i = 1 to length(compartments))
			var/datum/ship_compartment/compartment = compartments[i]
			result += "  [i]. [compartment.name]"
			if(compartment.area_type)
				result += " (зона: [compartment.area_type])"
			result += " - здоровье: [compartment.health]/[compartment.max_health]"
			result += ", риски: пожар [compartment.fire_risk]%, разгерметизация [compartment.breach_risk]%\n"

	// 5. Рассчитываем характеристики корабля
	var/max_hull = calculate_max_hull_health(ship_size, ship_type)
	var/max_shields = calculate_max_shield_strength(ship_size, get_tech_level())
	var/armor = calculate_armor_value(ship_type, get_armor_type())

	result += "\nРассчитанные характеристики:\n"
	result += "  Макс. здоровье корпуса: [max_hull] HP\n"
	result += "  Макс. прочность щитов: [max_shields] SP\n"
	result += "  Броня: [armor]%\n"

	return result

// ==================== ПРИМЕРЫ ДЛЯ РАЗНЫХ КОРАБЛЕЙ ====================

/*
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
	armor_value = 10

/*
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

/*
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

/*
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

/*
 * Кинетическая пушка
 * Урон: 150 (бронебойный)
 * Пробитие: 30%
 * Против линкора: 60,000 HP / 150 = 400 попаданий (со щитами и броней ~150-200)
 */
/obj/machinery/ship_weapon/kinetic_cannon
	name = "Тяжелая кинетическая пушка"
	damage = 150
	armor_penetration = 30

/*
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

/*
 * Ракетная установка
 * Урон: 300 (высокий)
 * Пробитие: 50%
 * Медленная перезарядка
 */
/obj/machinery/ship_weapon/missile_launcher
	name = "Ракетная установка"
	damage = 300
	armor_penetration = 50

/*
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

/*
 * Создание отсеков корабля на основе реальных зон
 *
 * @param ship_size - размер корабля в тайлах
 */
/datum/overmap/ship/proc/create_compartments(ship_size)
	// Очищаем старые отсеки
	compartments.Cut()

	// Для контролируемых кораблей используем реальные зоны
	if(istype(src, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/controlled_ship = src

		// Если у нас есть информация об уникальных зонах, используем её
		if(controlled_ship.ship_unique_areas && length(controlled_ship.ship_unique_areas) > 0)
			return create_compartments_from_real_areas(controlled_ship)

	// Для остальных кораблей используем расчетный метод
	return create_compartments_calculated(ship_size)

/*
 * Создание отсеков на основе реальных зон корабля
 */
/datum/overmap/ship/proc/create_compartments_from_real_areas(datum/overmap/ship/controlled/controlled_ship)
	var/compartment_count = length(controlled_ship.ship_unique_areas)

	// Если нет уникальных зон, используем расчетный метод
	if(compartment_count == 0)
		return create_compartments_calculated(50)  // Используем размер по умолчанию

	for(var/area_type in controlled_ship.ship_unique_areas)
		var/datum/ship_compartment/compartment = new()

		// Определяем название отсека на основе типа зоны
		compartment.name = get_compartment_name_from_area(area_type)

		// Рассчитываем здоровье отсека на основе размера зоны
		// (это можно улучшить, если будем знать реальный размер каждой зоны)
		compartment.max_health = 100
		compartment.health = 100

		// Распределяем риски в зависимости от типа отсека
		assign_compartment_risks(compartment)

		// Добавляем информацию о типе зоны для отладки
		compartment.area_type = area_type

		compartments += compartment

	// Сортируем отсеки по важности (командный отсек первый и т.д.)
	sort_compartments_by_importance()

	return compartments

/*
 * Сортировка отсеков по важности
 */
/datum/overmap/ship/proc/sort_compartments_by_importance()
	if(length(compartments) <= 1)
		return

	// Определяем приоритеты отсеков
	var/list/compartment_priority = list(
		"Командный отсек" = 1,
		"Двигательный отсек" = 2,
		"Инженерный отсек" = 3,
		"Оружейный отсек" = 4,
		"Энергетический отсек" = 5,
		"Медицинский отсек" = 6,
		"Научный отсек" = 7,
		"Грузовой отсек" = 8,
		"Жилой отсек" = 9,
		"Коридор" = 10
	)

	// Сортируем отсеки
	compartments = sortTim(compartments, GLOBAL_PROC_REF(cmp_ship_compartments))

/*
 * Сравнение отсеков для сортировки
 */
/proc/cmp_ship_compartments(datum/ship_compartment/A, datum/ship_compartment/B)
	var/priority_A = get_compartment_priority(A.name)
	var/priority_B = get_compartment_priority(B.name)

	if(priority_A < priority_B)
		return -1
	else if(priority_A > priority_B)
		return 1
	else
		return 0

/*
 * Получение приоритета отсека
 */
/proc/get_compartment_priority(compartment_name)
	var/static/list/compartment_priority = list(
		// Критически важные отсеки (1-10)
		"Командный отсек" = 1,
		"Каюта капитана" = 2,
		"Командные каюты" = 3,
		"Камера ИИ" = 4,
		"ИИ-отсек" = 5,

		// Жизненно важные системы (11-20)
		"Двигательный отсек" = 11,
		"Машинное отделение" = 12,
		"Порт двигатели" = 13,
		"Старборд двигатели" = 14,
		"Инженерный отсек" = 15,
		"Электрощитовая" = 16,
		"Атмосферный отсек" = 17,
		"Коммуникационный отсек" = 18,
		"Комната связи" = 19,

		// Боевые системы (21-30)
		"Оружейный отсек" = 21,
		"Оружейная" = 22,
		"Охранный отсек" = 23,
		"Тюремные камеры" = 24,
		"Стрельбище" = 25,
		"Док безопасности" = 26,

		// Медицинские системы (31-40)
		"Медблок" = 31,
		"Хирургический блок" = 32,
		"Кабинет психолога" = 33,
		"Криокамеры" = 34,
		"Морг" = 35,

		// Научные системы (41-50)
		"Научная лаборатория" = 41,
		"Ксено-лаборатория" = 42,
		"Робототехника" = 43,
		"Мастерская" = 44,
		"Тестовая лаборатория" = 45,

		// Жилые зоны (51-60)
		"Жилой отсек" = 51,
		"Каюты экипажа" = 52,
		"Каюты экипажа 2" = 53,
		"Каюты экипажа 3" = 54,
		"Каюты экипажа 4" = 55,
		"Каюты экипажа 5" = 56,
		"Каюта медспециалиста" = 57,
		"Каюта охранника" = 58,
		"Каюта инженера" = 59,
		"Каюта грузчика" = 60,
		"Общежитие" = 61,
		"Общежитие 2" = 62,
		"Общежитие 3" = 63,
		"Общежитие 4" = 64,
		"Общежитие 5" = 65,

		// Грузовые и транспортные (71-80)
		"Грузовой отсек" = 71,
		"Порт грузовой отсек" = 72,
		"Старборд грузовой отсек" = 73,
		"Офис грузчиков" = 74,
		"Ангар" = 75,
		"Порт ангар" = 76,
		"Старборд ангар" = 77,

		// Складские (81-90)
		"Склад" = 81,
		"Порт склад" = 82,
		"Старборд склад" = 83,
		"Хранилище токсинов" = 84,
		"Хранилище EVA" = 85,
		"Комната оборудования" = 86,

		// Общественные зоны (91-100)
		"Столовая" = 91,
		"Камбуз" = 92,
		"Туалет" = 93,
		"Туалет 2" = 94,
		"Туалет 3" = 95,
		"Гидропоника" = 96,
		"Часовня" = 97,
		"Офис часовни" = 98,
		"Библиотека" = 99,
		"Юридический офис" = 100,
		"Консульство СолГов" = 101,
		"Офис" = 102,
		"Лобби" = 103,
		"Общая зона" = 104,
		"Кладовая уборщика" = 105,

		// Технические зоны (111-120)
		"Технический отсек" = 111,
		"Кормовой техотсек" = 112,
		"Носовой техотсек" = 113,
		"Старборд техотсек" = 114,
		"Порт техотсек" = 115,
		"Центральный техотсек" = 116,
		"Внешний доступ к корпусу" = 117,
		"Инсинератор" = 118,
		"Строительная зона" = 119,

		// Коридоры (121-130)
		"Коридор" = 121,
		"Кормовой коридор" = 122,
		"Носовой коридор" = 123,
		"Старборд коридор" = 124,
		"Порт коридор" = 125,
		"Центральный коридор" = 126,

		// Внешние зоны (131-140)
		"Внешняя зона" = 131,

		// Неизвестные отсеки (низкий приоритет)
		"Неизвестный отсек" = 999,
		"Основной отсек" = 998,
		"Специализированные каюты" = 997
	)

	if(compartment_name in compartment_priority)
		return compartment_priority[compartment_name]

	// Проверяем частичные совпадения
	for(var/key in compartment_priority)
		if(findtext(compartment_name, key))
			return compartment_priority[key]

	return 999  // Самый низкий приоритет

/*
 * Создание отсеков расчетным методом (для кораблей без реальных зон)
*/
/datum/overmap/ship/proc/create_compartments_calculated(ship_size)
	// Рассчитываем количество отсеков
	var/compartment_count = calculate_compartment_count(ship_size)

	// Создаем отсеки с разными названиями
	var/list/compartment_names = list(
		"Носовой отсек",
		"Центральный отсек",
		"Кормовой отсек",
		"Двигательный отсек",
		"Оружейный отсек",
		"Жилой отсек",
		"Складской отсек",
		"Медицинский отсек",
		"Командный отсек",
		"Энергетический отсек"
	)

	for(var/i = 1 to compartment_count)
		var/datum/ship_compartment/compartment = new()
		compartment.name = compartment_names[min(i, length(compartment_names))]
		compartment.max_health = 100
		compartment.health = 100

		// Распределяем риски в зависимости от типа отсека
		assign_compartment_risks(compartment)

		compartments += compartment

	return compartments

/*
 * Распределение рисков для отсека на основе его названия
 *
 * Риски основаны на типе отсека:
 * - Двигательные/инженерные: высокий риск пожара
 * - Внешние/бортовые: высокий риск разгерметизации
 * - Оружейные: средний риск пожара и разгерметизации
 * - Медицинские/командные: низкие риски
 * - Жилые/общественные: средние риски
 */
/datum/overmap/ship/proc/assign_compartment_risks(datum/ship_compartment/compartment)
	// Сброс рисков
	compartment.fire_risk = 0
	compartment.breach_risk = 0

	// Распределяем риски в зависимости от типа отсека

	// Высокий риск пожара: двигательные, энергетические, инженерные зоны
	if(findtext(compartment.name, "Двигательный") || findtext(compartment.name, "Энергетический") || findtext(compartment.name, "Инженерный") || findtext(compartment.name, "Машинное") || findtext(compartment.name, "Электрощитовая") || findtext(compartment.name, "Инсинератор"))
		compartment.fire_risk = 35
		compartment.breach_risk = 8

	// Оружейные и боевые зоны
	else if(findtext(compartment.name, "Оружейный") || findtext(compartment.name, "Арсенал") || findtext(compartment.name, "Боевой") || findtext(compartment.name, "Стрельбище"))
		compartment.fire_risk = 25
		compartment.breach_risk = 12

	// Внешние и бортовые зоны (высокий риск разгерметизации)
	else if(findtext(compartment.name, "Носовой") || findtext(compartment.name, "Кормовой") || findtext(compartment.name, "Бортовой") || findtext(compartment.name, "Внешний") || findtext(compartment.name, "Ангар") || findtext(compartment.name, "Док"))
		compartment.fire_risk = 12
		compartment.breach_risk = 20

	// Топливные и химические зоны
	else if(findtext(compartment.name, "Топливный") || findtext(compartment.name, "Горючее") || findtext(compartment.name, "Токсинов") || findtext(compartment.name, "Химический"))
		compartment.fire_risk = 45
		compartment.breach_risk = 15

	// Медицинские зоны (низкий риск)
	else if(findtext(compartment.name, "Медицинский") || findtext(compartment.name, "Медблок") || findtext(compartment.name, "Хирургический") || findtext(compartment.name, "Морг"))
		compartment.fire_risk = 8
		compartment.breach_risk = 6

	// Жилые зоны
	else if(findtext(compartment.name, "Жилой") || findtext(compartment.name, "Каюта") || findtext(compartment.name, "Общежитие") || findtext(compartment.name, "Спальня"))
		compartment.fire_risk = 15
		compartment.breach_risk = 10

	// Командные зоны (критически важные)
	else if(findtext(compartment.name, "Командный") || findtext(compartment.name, "Мостик") || findtext(compartment.name, "Капитан") || findtext(compartment.name, "ИИ"))
		compartment.fire_risk = 8
		compartment.breach_risk = 5

	// Научные зоны
	else if(findtext(compartment.name, "Научный") || findtext(compartment.name, "Лаборатория") || findtext(compartment.name, "Ксено") || findtext(compartment.name, "Робототехника"))
		compartment.fire_risk = 20
		compartment.breach_risk = 8

	// Грузовые и складские зоны
	else if(findtext(compartment.name, "Грузовой") || findtext(compartment.name, "Склад") || findtext(compartment.name, "Хранилище"))
		compartment.fire_risk = 18
		compartment.breach_risk = 7

	// Коммуникационные зоны
	else if(findtext(compartment.name, "Коммуникационный") || findtext(compartment.name, "Связь"))
		compartment.fire_risk = 12
		compartment.breach_risk = 6

	// Атмосферные зоны
	else if(findtext(compartment.name, "Атмосферный") || findtext(compartment.name, "Воздух"))
		compartment.fire_risk = 25
		compartment.breach_risk = 15

	// Технические и обслуживающие зоны
	else if(findtext(compartment.name, "Технический") || findtext(compartment.name, "Техотсек") || findtext(compartment.name, "Обслуживание") || findtext(compartment.name, "Уборщика"))
		compartment.fire_risk = 15
		compartment.breach_risk = 8

	// Коридоры и проходы
	else if(findtext(compartment.name, "Коридор") || findtext(compartment.name, "Проход") || findtext(compartment.name, "Холл"))
		compartment.fire_risk = 10
		compartment.breach_risk = 12

	// Общественные зоны (столовая, библиотека и т.д.)
	else if(findtext(compartment.name, "Столовая") || findtext(compartment.name, "Камбуз") || findtext(compartment.name, "Библиотека") || findtext(compartment.name, "Часовня") || findtext(compartment.name, "Офис") || findtext(compartment.name, "Лобби"))
		compartment.fire_risk = 12
		compartment.breach_risk = 7

	// Специализированные зоны
	else if(findtext(compartment.name, "Гидропоника") || findtext(compartment.name, "Сад"))
		compartment.fire_risk = 10
		compartment.breach_risk = 5

	else if(findtext(compartment.name, "Криокамеры"))
		compartment.fire_risk = 5
		compartment.breach_risk = 3

	else if(findtext(compartment.name, "Строительная"))
		compartment.fire_risk = 20
		compartment.breach_risk = 10

	// Стандартные риски для неизвестных отсеков
	else
		compartment.fire_risk = 12
		compartment.breach_risk = 8

/*
 * Расчет размера корабля на основе реальных данных карты
 * Подсчитывает все тайлы, принадлежащие зонам корабля (/area/ship/)
*/
/datum/overmap/ship/proc/calculate_ship_size()
	// Для управляемых кораблей используем реальные данные карты
	if(istype(src, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/controlled_ship = src

		// Если есть shuttle_port, анализируем его зоны
		if(controlled_ship.shuttle_port)
			return calculate_ship_size_from_shuttle_port(controlled_ship.shuttle_port)

		// Если есть source_template, используем его размер
		if(controlled_ship.source_template)
			// Используем размеры шаблона как приближение
			return controlled_ship.source_template.width * controlled_ship.source_template.height

	// По умолчанию - маленький корабль (50 тайлов)
	return 50

/*
 * Расчет размера корабля на основе зон шаттла
 * Подсчитывает все тайлы в зонах типа /area/ship/
 * Игнорирует зоны /area/template_noop (пустое пространство/космос)
*/
/datum/overmap/ship/proc/calculate_ship_size_from_shuttle_port(obj/docking_port/mobile/shuttle_port)
	if(!shuttle_port)
		return 50

	var/ship_tile_count = 0
	var/list/unique_ship_areas = list()

	// Получаем все зоны шаттла
	var/list/areas = shuttle_port.shuttle_areas
	if(!length(areas))
		return 50

	// Проходим по всем зонам шаттла
	for(var/area/shuttle_area in areas)
		// ИГНОРИРУЕМ зоны template_noop (пустое пространство/космос)
		if(istype(shuttle_area, /area/template_noop))
			continue

		// Проверяем, является ли зона частью корабля
		if(istype(shuttle_area, /area/ship))
			// Подсчитываем тайлы в этой зоне
			for(var/turf/T in shuttle_area)
				// Игнорируем template_noop тайлы
				if(istype(T, /turf/template_noop))
					continue
				ship_tile_count++

			// Запоминаем уникальную зону для подсчета отсеков
			var/area_type = shuttle_area.type
			if(!(area_type in unique_ship_areas))
				unique_ship_areas += area_type
		else
			// Для не-ship зон тоже подсчитываем тайлы (но не считаем их отсеками)
			// Это могут быть технические зоны, коридоры и т.д.
			for(var/turf/T in shuttle_area)
				if(istype(T, /turf/template_noop))
					continue
				ship_tile_count++

	// Если не нашли зон корабля, но есть другие зоны - используем их
	if(ship_tile_count == 0)
		// Альтернативный метод: подсчет всех тайлов во всех зонах шаттла (кроме template_noop)
		for(var/area/shuttle_area in areas)
			if(istype(shuttle_area, /area/template_noop))
				continue

			for(var/turf/T in shuttle_area)
				if(istype(T, /turf/template_noop))
					continue
				ship_tile_count++

	// Сохраняем информацию об уникальных зонах для использования в create_compartments
	if(istype(src, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/controlled_ship = src
		controlled_ship.ship_unique_areas = unique_ship_areas

	return max(10, ship_tile_count)  // Минимум 10 тайлов

// /*
//  * Получение технологического уровня корабля
// */
// /datum/overmap/ship/proc/get_tech_level()
// 	// Можно расширить для разных фракций
// 	switch(faction)
// 		if(SHIP_FACTION_NANOTRASEN)
// 			return 8  // Высокие технологии
// 		if(SHIP_FACTION_SYNDICATE)
// 			return 7  // Хорошие технологии
// 		if(SHIP_FACTION_SOLGOV)
// 			return 6  // Средние технологии
// 		if(SHIP_FACTION_PIRATE)
// 			return 4  // Низкие технологии
// 		else
// 			return 5  // Стандарт

// /*
//  * Получение типа брони
// */
// /datum/overmap/ship/proc/get_armor_type()
// 	// Можно настроить для разных кораблей
// 	return "medium" // По умолчанию средняя броня


