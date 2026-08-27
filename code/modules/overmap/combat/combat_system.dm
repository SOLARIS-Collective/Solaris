/**
 * # Космическая система боя для Solaris
 *
 * Реализует тактический бой между кораблями на овермапе
 * с учетом ограничений BYOND и существующей архитектуры
 */

// ==================== ДАТУМЫ ====================

/**
 * # Датум системы боя корабля
 *
 * Управляет всем вооружением и боевыми системами корабля
 */
/datum/ship_combat_system
	/// Ссылка на корабль
	var/datum/overmap/ship/controlled/ship

	/// Список установленного вооружения
	var/list/obj/machinery/ship_weapon/weapons = list()

	/// Текущая захваченная цель
	var/datum/overmap/ship/target

	/// Статус захвата цели
	var/target_lock_status = SHIP_TARGET_LOCK_NONE

	/// Время начала захвата цели
	var/target_lock_start_time = 0

	/// Время, необходимое для захвата цели (в тиках)
	var/target_lock_time = SHIP_DEFAULT_TARGET_LOCK_TIME

	/// Максимальная дальность захвата цели (в тайлах овермапа)
	var/max_target_range = SHIP_DEFAULT_MAX_TARGET_RANGE

	/// Активна ли система боя
	var/combat_active = FALSE

	/// Список активных снарядов в полете
	var/list/obj/projectile/ship_projectile/active_projectiles = list()

	/// Ссылка на консоль управления огнем
	var/obj/machinery/computer/ship/fire_control/control_console

	/// Множитель урона (зависит от навыков экипажа и улучшений)
	var/damage_multiplier = 1.0

	/// Множитель точности
	var/accuracy_multiplier = 1.0

	/// Множитель скорости перезарядки
	var/recharge_multiplier = 1.0

	/// Менеджер событий для оповещений
	var/datum/combat_event_manager/event_manager

	/// Время последнего процессинга
	var/last_process_time = 0

	/// Интервал процессинга (в тиках)
	var/process_interval = 1 SECONDS

	/// Приоритет процессинга (1-10, выше = чаще)
	var/process_priority = 5

	/// Счетчик процессингов для статистики
	var/process_counter = 0

	/// Флаг оптимизации процессинга
	var/optimized_processing = TRUE

	/// Кэшированные данные для оптимизации
	var/list/cached_data = list()

/datum/ship_combat_system/New(datum/overmap/ship/controlled/ship_ref)
	. = ..()
	ship = ship_ref
	// Задержка инициализации оружия, чтобы убедиться, что все пушки уже инициализированы
	addtimer(CALLBACK(src, PROC_REF(initialize_weapons)), 2 SECONDS)
	initialize_event_manager()
	initialize_optimized_processing()
	START_PROCESSING(SSprocessing, src)

/datum/ship_combat_system/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	cleanup_event_manager()
	weapons.Cut()
	target = null
	control_console = null
	active_projectiles.Cut()
	cached_data.Cut()
	return ..()

/**
 * Инициализация менеджера событий
 */
/datum/ship_combat_system/proc/initialize_event_manager()
	if(!event_manager)
		event_manager = new /datum/combat_event_manager(src)
		LOG_SHIP_COMBAT("CombatSystem: Менеджер событий инициализирован для [ship?.name || "неизвестный корабль"]")

/**
 * Очистка менеджера событий
 */
/datum/ship_combat_system/proc/cleanup_event_manager()
	if(event_manager)
		QDEL_NULL(event_manager)

/**
 * Инициализация оптимизированного процессинга
 */
/datum/ship_combat_system/proc/initialize_optimized_processing()
	last_process_time = world.time
	process_counter = 0
	cached_data = list(
		"last_target_check" = 0,
		"last_weapon_update" = 0,
		"last_projectile_update" = 0
	)

	// Адаптивный интервал на основе приоритета
	switch(process_priority)
		if(1 to 3)
			process_interval = 2 SECONDS
		if(4 to 7)
			process_interval = 1 SECONDS
		if(8 to 10)
			process_interval = 0.5 SECONDS

/**
 * Инициализация вооружения корабля
 * Ищет все машинерии вооружения на корабле
 */
/datum/ship_combat_system/proc/initialize_weapons()
	weapons.Cut()
	var/datum/overmap/ship/controlled/our_ship = ship
	if(!our_ship || !our_ship.shuttle_port)
		return

	var/obj/docking_port/mobile/our_port = our_ship.shuttle_port

	for(var/obj/machinery/ship_weapon/W in GLOB.machines)
		if(QDELETED(W) || !W.loc)
			continue
		var/area/ship/A = get_area(W)
		if(istype(A) && A.mobile_port == our_port)
			weapons |= W
			W.combat_system = src

/**
 * Поиск и захват цели
 *
 * @param target_ref - ссылка на цель (datum/overmap/ship)
 * @return TRUE если захват начат, FALSE если ошибка
 */
/datum/ship_combat_system/proc/acquire_target(datum/overmap/ship/target_ref)
	if(!target_ref)
		return FALSE

	if(target_ref == ship)
		return FALSE // Нельзя атаковать себя

	if(get_overmap_distance(ship, target_ref) > max_target_range)
		return FALSE // Цель слишком далеко

	if(target_lock_status == SHIP_TARGET_LOCK_LOCKED && target == target_ref)
		return TRUE // Цель уже захвачена

	target = target_ref
	target_lock_status = SHIP_TARGET_LOCK_LOCKED
	target_lock_start_time = world.time

	// Уведомляем о захвате цели
	if(event_manager)
		event_manager.notify_target_acquired(target_ref)

	return TRUE

/**
 * Проверка статуса захвата цели
 * Вызывается каждый тик
 */
/datum/ship_combat_system/proc/process_target_lock()
	if(target_lock_status != SHIP_TARGET_LOCK_ACQUIRING)
		return

	if(!target || QDELETED(target))
		target_lock_status = SHIP_TARGET_LOCK_LOST
		target = null
		return

	// Проверяем расстояние
	if(get_overmap_distance(ship, target) > max_target_range)
		target_lock_status = SHIP_TARGET_LOCK_LOST
		target = null
		return

	// Проверяем время захвата
	if(world.time - target_lock_start_time >= target_lock_time)
		target_lock_status = SHIP_TARGET_LOCK_LOCKED

/**
 * Расчет времени полета снаряда
 *
 * @param weapon - оружие, из которого ведется стрельба
 * @return время в тиках до попадания
 */
/datum/ship_combat_system/proc/calculate_flight_time(obj/machinery/ship_weapon/weapon)
	if(!target || !weapon)
		return 0

	var/distance = get_overmap_distance(ship, target)
	var/speed = weapon.projectile_speed
	var/time = (distance / speed) * 10 SECONDS // Конвертируем в тики

	// Учитываем скорость цели
	if(!target.is_still())
		var/target_speed = target.get_speed()
		time *= (1 + (target_speed / 100))

	return round(time)

/**
 * Расчет шанса попадания
 *
 * @param weapon - оружие
 * @return шанс попадания от 0 до 100
 */
/datum/ship_combat_system/proc/calculate_hit_chance(obj/machinery/ship_weapon/weapon)
	if(!target || !weapon)
		return 0

	var/base_chance = weapon.base_accuracy
	var/distance = get_overmap_distance(ship, target)

	// Модификатор расстояния
	var/distance_modifier = 1.0
	if(distance > weapon.optimal_range)
		distance_modifier = max(0.1, 1.0 - ((distance - weapon.optimal_range) / 100))

	// Модификатор скорости цели
	var/speed_modifier = 1.0
	if(!target.is_still())
		var/target_speed = target.get_speed()
		speed_modifier = max(0.3, 1.0 - (target_speed / 500))

	// Модификатор размера цели
	var/size_modifier = 1.0
	if(target.ship_size)
		size_modifier = clamp(target.ship_size / 100, 0.5, 1.5)

	var/final_chance = base_chance * distance_modifier * speed_modifier * size_modifier * accuracy_multiplier

	return clamp(final_chance, 0, 100)

/**
 * Запуск снаряда
 *
 * @param weapon - оружие для стрельбы
 * @return TRUE если выстрел произведен, FALSE если ошибка
 */
/datum/ship_combat_system/proc/fire_weapon(obj/machinery/ship_weapon/weapon)
	if(!weapon)
		return FALSE

	// Принудительно привязываем оружие, если оно потерялось
	if(weapon.combat_system != src)
		weapon.combat_system = src

	if(!weapon.can_fire())
		message_admins("FIRE_CONTROL: weapon.can_fire() returned FALSE")
		return FALSE

	/* [ТЕСТОВЫЙ РЕЖИМ] - Временно отключено
	if(target_lock_status != SHIP_TARGET_LOCK_LOCKED)
		return FALSE
	*/

	if(!target || QDELETED(target))
		message_admins("FIRE_CONTROL: target is NULL or QDELETED")
		return FALSE

	// Рассчитываем параметры выстрела
	var/flight_time = calculate_flight_time(weapon)
	var/hit_chance = calculate_hit_chance(weapon)

	// Создаем снаряд
	var/obj/projectile/ship_projectile/projectile = new weapon.projectile_type()
	projectile.setup_projectile(ship, target, weapon, flight_time, hit_chance)

	// Добавляем в список активных снарядов
	active_projectiles += projectile

	// Запускаем оружие
	weapon.fire()

	// Оповещаем через систему событий
	if(event_manager)
		event_manager.notify_projectile_launched(projectile, weapon)

	// Оповещаем консоль (для обратной совместимости)
	if(control_console)
		control_console.on_weapon_fired(weapon, projectile, flight_time)

	return TRUE

/**
 * Обработка попадания снаряда
 *
 * @param projectile - снаряд, который попал в цель
 * @param actual_hit - TRUE если реальное попадание, FALSE если промах
 */
/datum/ship_combat_system/proc/process_hit(obj/projectile/ship_projectile/projectile, actual_hit = TRUE)
	if(!projectile || !(projectile in active_projectiles))
		return

	// Удаляем из активных снарядов
	active_projectiles -= projectile

	var/damage = 0
	if(actual_hit && projectile.target && !QDELETED(projectile.target))
		// Наносим урон цели
		damage = projectile.weapon.damage * damage_multiplier
		projectile.target.take_damage(damage, projectile.weapon.damage_type)

		// Оповещаем о попадании
		broadcast_hit_notification(projectile, damage)

	// Оповещаем через систему событий
	if(event_manager)
		event_manager.notify_projectile_hit(projectile, actual_hit, damage)

	// Уничтожаем снаряд
	qdel(projectile)

/**
 * Оповещение о попадании
 */
/datum/ship_combat_system/proc/broadcast_hit_notification(obj/projectile/ship_projectile/projectile, damage)
	// Оповещаем наш корабль (если это управляемый корабль)
	if(istype(ship, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/firing_ship = ship
		if(firing_ship.shuttle_port)
			var/area/ship_area = get_area(firing_ship.shuttle_port)
			for(var/mob/living/L in ship_area)
				to_chat(L, span_danger("[icon2html(projectile.weapon, L)] [projectile.weapon.name] попадает в [projectile.target.name]! Нанесено урона: [damage]"))

	// Оповещаем цель (если это игрок)
	if(istype(projectile.target, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/target_ship = projectile.target
		if(target_ship.shuttle_port)
			var/area/target_area = get_area(target_ship.shuttle_port)
			for(var/mob/living/L in target_area)
				to_chat(L, span_userdanger("Наш корабль атакован! Получено урона: [damage] от [ship.name]"))

/**
 * Получение расстояния между двумя кораблями на овермапе
 */
/datum/ship_combat_system/proc/get_overmap_distance(datum/overmap/ship/ship1, datum/overmap/ship/ship2)
	if(!ship1 || !ship2)
		return INFINITY

	var/dx = ship1.x - ship2.x
	var/dy = ship1.y - ship2.y

	return sqrt(dx*dx + dy*dy)

/**
 * Основной процесс системы боя (оптимизированный)
 */
/datum/ship_combat_system/process()
	if(QDELETED(src) || QDELETED(ship))
		return

	process_counter++
	var/current_time = world.time

	// Проверка интервала процессинга
	if(current_time - last_process_time < process_interval)
		return

	last_process_time = current_time

	// Оптимизированная обработка с приоритетами
	var/updates_made = FALSE

	// ПРИОРИТЕТ 1: Критические изменения (захват цели, потеря цели)
	if(process_target_lock_optimized())
		updates_made = TRUE

	// ПРИОРИТЕТ 2: Обновление вооружения (с кэшированием)
	if(current_time - cached_data["last_weapon_update"] >= 0.5 SECONDS)
		if(process_weapons_optimized())
			updates_made = TRUE
		cached_data["last_weapon_update"] = current_time

	// ПРИОРИТЕТ 3: Обновление снарядов (с кэшированием)
	if(current_time - cached_data["last_projectile_update"] >= 0.3 SECONDS)
		if(process_projectiles_optimized())
			updates_made = TRUE
		cached_data["last_projectile_update"] = current_time

	// ПРИОРИТЕТ 4: Валидация и очистка (редко)
	if(process_counter % 10 == 0)
		optimized_cleanup()

	// Отправляем уведомления только при изменениях
	if(updates_made && event_manager)
		notify_system_update()

/**
 * Оптимизированная обработка захвата цели
 */
/datum/ship_combat_system/proc/process_target_lock_optimized()
	var/old_status = target_lock_status
	var/old_target = target

	// Обрабатываем только если есть изменения
	if(target_lock_status == SHIP_TARGET_LOCK_ACQUIRING)
		process_target_lock()

	// Проверяем изменения
	if(target_lock_status != old_status || target != old_target)
		if(event_manager)
			if(target_lock_status == SHIP_TARGET_LOCK_LOCKED && old_status != SHIP_TARGET_LOCK_LOCKED)
				event_manager.notify_target_acquired(target)
			else if(target_lock_status == SHIP_TARGET_LOCK_LOST)
				event_manager.notify_target_lost(old_target, "status_change")
			else
				event_manager.notify_target_lock_changed(old_status, target_lock_status)
		return TRUE

	return FALSE

/**
 * Оптимизированная обработка вооружения
 */
/datum/ship_combat_system/proc/process_weapons_optimized()
	var/updates_made = FALSE

	for(var/obj/machinery/ship_weapon/weapon in weapons)
		if(QDELETED(weapon))
			weapons -= weapon
			updates_made = TRUE
			continue

		var/old_state = weapon.weapon_state
		var/old_can_fire = weapon.can_fire()

		weapon.process()

		// Проверяем изменения состояния
		if(weapon.weapon_state != old_state || weapon.can_fire() != old_can_fire)
			if(event_manager)
				event_manager.notify_weapon_status_changed(weapon, old_state, weapon.weapon_state)
			updates_made = TRUE

	return updates_made

/**
 * Оптимизированная обработка снарядов
 */
/datum/ship_combat_system/proc/process_projectiles_optimized()
	var/updates_made = FALSE

	for(var/obj/projectile/ship_projectile/projectile in active_projectiles)
		if(QDELETED(projectile))
			active_projectiles -= projectile
			continue

		projectile.process_flight()

		// Проверяем завершение полета
		if(projectile.flight_progress >= 1.0 || QDELETED(projectile))
			updates_made = TRUE

	return updates_made

/**
 * Оптимизированная очистка ресурсов
 */
/datum/ship_combat_system/proc/optimized_cleanup()
	// Очистка удаленных объектов
	for(var/i = length(weapons) to 1 step -1)
		if(QDELETED(weapons[i]))
			weapons.Cut(i, i + 1)

	for(var/i = length(active_projectiles) to 1 step -1)
		if(QDELETED(active_projectiles[i]))
			active_projectiles.Cut(i, i + 1)

	// Валидация цели
	if(target && QDELETED(target))
		if(event_manager)
			event_manager.notify_target_lost(target, "deleted")
		target = null
		target_lock_status = SHIP_TARGET_LOCK_NONE

/**
 * Уведомление об обновлении системы
 */
/datum/ship_combat_system/proc/notify_system_update()
	if(!event_manager)
		return

	// Отправляем событие об общем обновлении системы
	event_manager.emit_event(COMBAT_EVENT_COMBAT_STATUS_CHANGED, list(
		"combat_active" = combat_active,
		"target_lock_status" = target_lock_status,
		"weapons_count" = length(weapons),
		"projectiles_count" = length(active_projectiles)
	))

// ==================== ВСПОМОГАТЕЛЬНЫЕ ПРОЦЕДУРЫ ====================

/**
 * Глобальная процедура для получения системы боя корабля
 */
/proc/get_ship_combat_system(datum/overmap/ship/controlled/ship)
	if(!ship)
		return null

	if(!ship.combat_system)
		ship.combat_system = new /datum/ship_combat_system(ship)

	return ship.combat_system
