/**
 * # Интеграция системы боя с существующей системой кораблей
 */

// ==================== РАСШИРЕНИЕ ДАТУМА КОРАБЛЯ ====================

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

	/// Скорость восстановления щитов
	var/shield_recharge_rate = 1

	/// Время последнего восстановления щитов
	var/last_shield_recharge = 0

	/// Интервал восстановления щитов
	var/shield_recharge_interval = 10 SECONDS

	/// Флаг, указывающий что щиты активны
	var/shields_active = TRUE

	/// Уровень повреждения систем
	var/list/system_damage = list()

	/// Фракция корабля
	var/faction = SHIP_FACTION_INDEPENDENT

	/// Тип корабля
	var/ship_type = SHIP_TYPE_FRIGATE

	/// Размер корабля в тайлах
	var/ship_size = 50

	/// Боевой статус корабля
	var/combat_status = SHIP_COMBAT_STATUS_PEACEFUL

	/// Время последней атаки
	var/last_combat_time = 0

	/// Список недавних атакующих
	var/list/recent_attackers = list()

	/// Максимальное количество записей в списке атакующих
	var/max_attacker_records = 5

	/// Значение брони (процент поглощаемого урона)
	var/armor_value = 0

	/// Флаг, указывающий что корабль уничтожен
	var/destroyed = FALSE

	/// Время уничтожения
	var/destroyed_time = 0

	/// Кастомный технологический уровень (опционально)
	var/tech_level = null

	/// Кастомный тип брони (опционально)
	var/custom_armor_type = null

	/// Список отсеков корабля
	var/list/compartments = list()

	/// Список уникальных типов зон корабля (используется для создания отсеков)
	var/list/ship_unique_areas = list()

	/// Причина уничтожения
	var/destruction_cause = ""

/datum/overmap/ship/Initialize(location, system)
	. = ..()
	// Инициализация системы повреждений
	initialize_system_damage()

	// Создание системы боя для управляемых кораблей
	if(istype(src, /datum/overmap/ship/controlled))
		combat_system = new /datum/ship_combat_system(src)

/datum/overmap/ship/Destroy()
	if(combat_system)
		QDEL_NULL(combat_system)
	system_damage.Cut()
	recent_attackers.Cut()
	return ..()

/**
 * Инициализация системы повреждений
 */
/datum/overmap/ship/proc/initialize_system_damage()
	system_damage[SHIP_SYSTEM_WEAPONS] = SHIP_DAMAGE_LEVEL_NONE
	system_damage[SHIP_SYSTEM_SHIELDS] = SHIP_DAMAGE_LEVEL_NONE
	system_damage[SHIP_SYSTEM_ENGINES] = SHIP_DAMAGE_LEVEL_NONE
	system_damage[SHIP_SYSTEM_POWER] = SHIP_DAMAGE_LEVEL_NONE
	system_damage[SHIP_SYSTEM_LIFE_SUPPORT] = SHIP_DAMAGE_LEVEL_NONE
	system_damage[SHIP_SYSTEM_COMMUNICATIONS] = SHIP_DAMAGE_LEVEL_NONE
	system_damage[SHIP_SYSTEM_SENSORS] = SHIP_DAMAGE_LEVEL_NONE

/**
 * Получение урона
 *
 * @param damage - количество урона
 * @param damage_type - тип урона
 * @param attacker - атакующий корабль (опционально)
 * @param weapon - оружие (опционально)
 */
/datum/overmap/ship/proc/take_damage(damage, damage_type, datum/overmap/ship/attacker, obj/machinery/ship_weapon/weapon)
	if(destroyed)
		return FALSE

	// Обновляем боевой статус
	combat_status = SHIP_COMBAT_STATUS_ENGAGED
	last_combat_time = world.time

	// Записываем атакующего
	if(attacker)
		record_attacker(attacker, damage)

	var/actual_damage = damage
	var/damage_blocked = 0

	// Проверяем щиты
	if(shields_active && shield_strength > 0)
		// Применяем множитель урона по щитам, если оружие его имеет
		var/shield_damage = actual_damage
		if(weapon && weapon.shield_damage_multiplier)
			shield_damage = actual_damage * weapon.shield_damage_multiplier

		damage_blocked = min(shield_strength, shield_damage * 0.7) // Щиты блокируют 70% урона
		shield_strength -= damage_blocked
		actual_damage -= damage_blocked / (weapon?.shield_damage_multiplier || 1.0)

		// Если щиты опустились до 0, деактивируем их
		if(shield_strength <= 0)
			shield_strength = 0
			shields_active = FALSE
			on_shields_down()

	// Применяем броню и пробитие брони
	if(actual_damage > 0 && armor_value > 0)
		var/effective_armor = armor_value
		// Учитываем пробитие брони, если оружие его имеет
		if(weapon && weapon.armor_penetration)
			effective_armor = max(0, armor_value - weapon.armor_penetration)

		var/armor_reduction = actual_damage * (effective_armor / 100)
		actual_damage -= armor_reduction

	// Наносим урон корпусу
	if(actual_damage > 0)
		hull_health -= actual_damage

		// Проверяем повреждение систем
		if(prob(30)) // 30% шанс повредить случайную систему
			damage_random_system(actual_damage)

		// Проверяем уничтожение
		if(hull_health <= 0)
			destroy_ship(attacker, weapon)
			return TRUE

	// Оповещаем о получении урона
	on_damage_taken(actual_damage, damage_blocked, attacker, weapon)

	// Обновляем визуальное представление
	update_damage_effects()

	return TRUE

/**
 * Запись атакующего в историю
 */
/datum/overmap/ship/proc/record_attacker(datum/overmap/ship/attacker, damage)
	if(!attacker)
		return

	// Добавляем или обновляем запись
	var/attacker_ref = REF(attacker)
	if(recent_attackers[attacker_ref])
		recent_attackers[attacker_ref]["damage"] += damage
		recent_attackers[attacker_ref]["last_attack"] = world.time
	else
		recent_attackers[attacker_ref] = list(
			"name" = attacker.name,
			"damage" = damage,
			"last_attack" = world.time
		)

	// Ограничиваем размер списка
	if(length(recent_attackers) > max_attacker_records)
		// Удаляем самую старую запись
		var/oldest_ref
		var/oldest_time = INFINITY
		for(var/ref in recent_attackers)
			var/time = recent_attackers[ref]["last_attack"]
			if(time < oldest_time)
				oldest_time = time
				oldest_ref = ref
		if(oldest_ref)
			recent_attackers -= oldest_ref

/**
 * Повреждение случайной системы
 */
/datum/overmap/ship/proc/damage_random_system(damage_amount)
	if(destroyed)
		return

	var/list/available_systems = list()
	for(var/system in system_damage)
		if(system_damage[system] < SHIP_DAMAGE_LEVEL_DESTROYED)
			available_systems += system

	if(!length(available_systems))
		return

	var/system_to_damage = pick(available_systems)
	var/current_damage = system_damage[system_to_damage]
	var/new_damage = min(SHIP_DAMAGE_LEVEL_DESTROYED, current_damage + 1)

	system_damage[system_to_damage] = new_damage

	// Эффекты повреждения системы
	on_system_damaged(system_to_damage, new_damage)

	// Если это оружие, повреждаем случайное оружие на корабле
	if(system_to_damage == SHIP_SYSTEM_WEAPONS && combat_system)
		damage_random_weapon()

/**
 * Повреждение случайного оружия
 */
/datum/overmap/ship/proc/damage_random_weapon()
	if(!combat_system || !length(combat_system.weapons))
		return

	var/obj/machinery/ship_weapon/weapon = pick(combat_system.weapons)
	if(weapon && !weapon.damaged)
		var/severity = rand(25, 75)
		weapon.take_damage(severity)

/**
 * Уничтожение корабля
 */
/datum/overmap/ship/proc/destroy_ship(datum/overmap/ship/attacker, obj/machinery/ship_weapon/weapon)
	if(destroyed)
		return

	destroyed = TRUE
	destroyed_time = world.time
	combat_status = SHIP_COMBAT_STATUS_DISABLED

	// Определяем причину уничтожения
	if(attacker)
		destruction_cause = "уничтожен [attacker.name]"
		if(weapon)
			destruction_cause += " с помощью [weapon.name]"
	else
		destruction_cause = "уничтожен по неизвестной причине"

	// Эффекты уничтожения
	on_destroyed(attacker, weapon)

	// Логирование
	log_combat("[name] уничтожен. Причина: [destruction_cause]")

	// Уведомление игроков
	broadcast_destruction_notification(attacker)

	// Удаляем с овермапа через некоторое время
	// addtimer(CALLBACK(src, PROC_REF(remove_from_overmap)), 30 SECONDS)

/**
 * Удаление корабля с овермапа
 */
// /datum/overmap/ship/proc/remove_from_overmap()
// 	if(!current_overmap)
// 		return

// 	// Удаляем из овермапа
// 	current_overmap.remove_ship(src)

// 	// Уничтожаем датум
// 	qdel(src)

/**
 * Восстановление щитов
 */
/datum/overmap/ship/proc/recharge_shields()
	if(destroyed || !shields_active)
		return

	if(world.time - last_shield_recharge >= shield_recharge_interval)
		var/old_strength = shield_strength
		shield_strength = min(max_shield_strength, shield_strength + shield_recharge_rate)

		if(shield_strength > 0 && old_strength == 0)
			shields_active = TRUE
			on_shields_restored()

		last_shield_recharge = world.time

/**
 * Обработка отключения щитов
 */
/datum/overmap/ship/proc/on_shields_down()
	// Визуальные эффекты
	if(token)
		token.add_filter("shield_down", 1, list("type" = "outline", "color" = "#ff000080", "size" = 2))

	// Оповещение экипажа через консоль или общее оповещение
	// TODO: Добавить звуковой эффект когда файл будет доступен
	// playsound_global('sound/effects/shielddown.ogg', 50)

/**
 * Обработка восстановления щитов
 */
/datum/overmap/ship/proc/on_shields_restored()
	// Убираем визуальные эффекты
	if(token)
		token.remove_filter("shield_down")

	// Оповещение экипажа
	if(docked_to)
		var/area/ship_area = get_area(docked_to)
		for(var/mob/living/L in ship_area)
			to_chat(L, span_green("Щиты корабля восстановлены."))

/**
 * Обработка получения урона
 */
/datum/overmap/ship/proc/on_damage_taken(damage, blocked, attacker, weapon)
	// Визуальные эффекты
	if(token)
		var/hit_effect = "hit_[rand(1,3)]"
		token.icon_state = hit_effect
		addtimer(CALLBACK(token, TYPE_PROC_REF(/atom, update_icon)), 5)

	// Звуковой эффект
	playsound('sound/effects/explosion1.ogg', 30)

	// Оповещение экипажа
	if(docked_to)
		var/area/ship_area = get_area(docked_to)
		for(var/message in get_damage_messages(damage, blocked))
			for(var/mob/living/L in ship_area)
				to_chat(L, message)

/**
 * Обработка критического повреждения (здоровье корпуса ниже 30%)
 */
/datum/overmap/ship/proc/on_critical_damage()
	// Визуальные эффекты
	if(token)
		token.add_filter("critical_damage", 1, list("type" = "outline", "color" = "#ff000080", "size" = 3))

	// Звуковой эффект тревоги
	playsound('sound/effects/alert.ogg', 50)

	// Оповещение экипажа
	if(docked_to)
		var/area/ship_area = get_area(docked_to)
		for(var/mob/living/L in ship_area)
			to_chat(L, span_userdanger("КРИТИЧЕСКОЕ ПОВРЕЖДЕНИЕ КОРПУСА! Целостность: [round((hull_health / max_hull_health) * 100)]%"))

/**
 * Обработка повреждения системы
 */
/datum/overmap/ship/proc/on_system_damaged(system, damage_level)
	var/system_name = get_system_name(system)
	var/damage_text = get_damage_level_text(damage_level)

	// Оповещение экипажа
	if(docked_to)
		var/area/ship_area = get_area(docked_to)
		for(var/mob/living/L in ship_area)
			to_chat(L, span_danger("Система [system_name] повреждена! Уровень: [damage_text]"))

	// Эффекты в зависимости от системы
	switch(system)
		if(SHIP_SYSTEM_ENGINES)
			if(damage_level >= SHIP_DAMAGE_LEVEL_SEVERE)
				reduce_max_speed()
		if(SHIP_SYSTEM_POWER)
			if(damage_level >= SHIP_DAMAGE_LEVEL_MODERATE)
				reduce_power_output()

/**
 * Обработка уничтожения корабля
 */
/datum/overmap/ship/proc/on_destroyed(attacker, weapon)
	// Визуальные эффекты
	if(token)
		token.icon_state = "ship_destroyed"
		var/obj/effect/temp_visual/ship_explosion/explosion = new /obj/effect/temp_visual/ship_explosion(current_overmap)
		explosion.forceMove(current_overmap)
		explosion.x = x
		explosion.y = y

	// Звуковой эффект
	playsound('sound/effects/explosion2.ogg', 100)

	// Оповещение экипажа
	if(docked_to)
		var/area/ship_area = get_area(docked_to)
		for(var/mob/living/L in ship_area)
			to_chat(L, span_userdanger("КОРАБЛЬ УНИЧТОЖЕН! ПРИГОТОВЬТЕСЬ К ЭВАКУАЦИИ!"))

/**
 * Оповещение об уничтожении корабля
 */
/datum/overmap/ship/proc/broadcast_destruction_notification(attacker)
	if(!current_overmap)
		return

	// Оповещаем все корабли в системе
	for(var/datum/overmap/ship/controlled/other_ship in SSovermap.controlled_ships)
		if(other_ship == src || !other_ship.docked_to)
			continue

		var/area/other_area = get_area(other_ship.docked_to)
		for(var/mob/living/L in other_area)
			if(attacker)
				to_chat(L, span_boldnotice("[name] был уничтожен!"))
			else
				to_chat(L, span_boldnotice("[name] был уничтожен!"))

/**
 * Обновление визуальных эффектов повреждения
 */
/datum/overmap/ship/proc/update_damage_effects()
	if(!token || destroyed)
		return

	// Индикатор здоровья
	var/health_percent = hull_health / max_hull_health
	if(health_percent < 0.3)
		token.add_filter("damage_critical", 1, list("type" = "outline", "color" = "#ff0000", "size" = 3, "alpha" = 150))
	else if(health_percent < 0.6)
		token.add_filter("damage_moderate", 1, list("type" = "outline", "color" = "#ff9900", "size" = 2, "alpha" = 100))
	else
		token.remove_filter("damage_critical")
		token.remove_filter("damage_moderate")

	// Индикатор щитов
	if(shields_active && shield_strength > 0)
		var/shield_percent = shield_strength / max_shield_strength
		var/shield_color = shield_percent > 0.7 ? "#00ff00" : shield_percent > 0.3 ? "#ffff00" : "#ff0000"
		token.add_filter("shield_indicator", 1, list("type" = "outline", "color" = shield_color, "size" = 1, "alpha" = 200))
	else
		token.remove_filter("shield_indicator")

/**
 * Получение сообщений об уроне
 */
/datum/overmap/ship/proc/get_damage_messages(damage, blocked)
	var/list/messages = list()

	if(blocked > 0)
		messages += span_info("Щиты поглотили [blocked] урона.")

	if(damage > 0)
		messages += span_danger("Корпус получил [damage] урона! Целостность: [hull_health]/[max_hull_health]")

	if(hull_health < max_hull_health * 0.3)
		messages += span_userdanger("КРИТИЧЕСКИЕ ПОВРЕЖДЕНИЯ КОРПУСА!")

	return messages

/**
 * Получение названия системы
 */
/datum/overmap/ship/proc/get_system_name(system)
	switch(system)
		if(SHIP_SYSTEM_WEAPONS)
			return "Вооружение"
		if(SHIP_SYSTEM_SHIELDS)
			return "Щиты"
		if(SHIP_SYSTEM_ENGINES)
			return "Двигатели"
		if(SHIP_SYSTEM_POWER)
			return "Энергосистема"
		if(SHIP_SYSTEM_LIFE_SUPPORT)
			return "Системы жизнеобеспечения"
		if(SHIP_SYSTEM_COMMUNICATIONS)
			return "Связь"
		if(SHIP_SYSTEM_SENSORS)
			return "Сенсоры"
		else
			return "Неизвестная система"

/**
 * Получение текстового описания уровня повреждений
 */
/datum/overmap/ship/proc/get_damage_level_text(level)
	switch(level)
		if(SHIP_DAMAGE_LEVEL_NONE)
			return "Нет"
		if(SHIP_DAMAGE_LEVEL_MINOR)
			return "Незначительные"
		if(SHIP_DAMAGE_LEVEL_MODERATE)
			return "Средние"
		if(SHIP_DAMAGE_LEVEL_SEVERE)
			return "Серьезные"
		if(SHIP_DAMAGE_LEVEL_CRITICAL)
			return "Критические"
		if(SHIP_DAMAGE_LEVEL_DESTROYED)
			return "Уничтожено"
		else
			return "Неизвестно"

/**
 * Получение типа корабля для отображения
 */
/datum/overmap/ship/proc/get_ship_type()
	return ship_type

/**
 * Уменьшение максимальной скорости при повреждении двигателей
 */
/datum/overmap/ship/proc/reduce_max_speed()
	if(!istype(src, /datum/overmap/ship))
		return

	var/datum/overmap/ship/ship = src
	var/engine_damage = system_damage[SHIP_SYSTEM_ENGINES]
	var/speed_reduction = 1.0 - (engine_damage * 0.2) // 20% за каждый уровень повреждения

	ship.max_speed *= speed_reduction
	ship.acceleration_speed *= speed_reduction

/**
 * Уменьшение выработки энергии при повреждении энергосистемы
 */
/datum/overmap/ship/proc/reduce_power_output()
	if(!combat_system)
		return

	var/power_damage = system_damage[SHIP_SYSTEM_POWER]
	var/power_reduction = 1.0 - (power_damage * 0.15) // 15% за каждый уровень повреждения

	// Уменьшаем множители системы боя
	combat_system.damage_multiplier *= power_reduction
	combat_system.accuracy_multiplier *= power_reduction
	combat_system.recharge_multiplier *= power_reduction

// ==================== ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ====================

/obj/effect/temp_visual/ship_explosion
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	duration = 20
	layer = OVERMAP_LAYER_EFFECT

/obj/effect/temp_visual/ship_explosion/Initialize()
	. = ..()
	playsound(src, 'sound/effects/explosion2.ogg', 100, TRUE)
	QDEL_IN(src, duration)

// ==================== ГЛОБАЛЬНЫЕ ПРОЦЕДУРЫ ====================

/**
 * Глобальная процедура для обработки боя на овермапе
 */
/proc/process_overmap_combat()
	for(var/datum/overmap/ship/controlled/ship in SSovermap.controlled_ships)
		if(ship.destroyed)
			continue

		// Восстановление щитов
		ship.recharge_shields()

		// Обработка системы боя
		if(ship.combat_system)
			ship.combat_system.process()

		// Проверка выхода из боя
		if(ship.combat_status == SHIP_COMBAT_STATUS_ENGAGED && world.time - ship.last_combat_time > 1 MINUTES)
			ship.combat_status = SHIP_COMBAT_STATUS_PEACEFUL
			ship.update_damage_effects()
