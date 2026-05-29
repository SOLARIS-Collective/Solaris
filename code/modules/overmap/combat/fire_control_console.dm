/**
 * # Консоль управления огнем
 *
 * TGUI интерфейс для управления вооружением корабля
 */

/obj/machinery/computer/ship/fire_control
	name = "консоль управления огнем"
	desc = "Используется для управления вооружением корабля и захвата целей."
	icon_screen = "fire_control"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/ship/fire_control

	/// Ссылка на систему боя корабля
	var/datum/ship_combat_system/combat_system

	/// Список доступных целей в радиусе
	var/list/available_targets = list()

	/// Время последнего обновления списка целей
	var/last_target_scan = 0

	/// Интервал сканирования целей (в тиках)
	var/target_scan_interval = 5 SECONDS

	/// Выбранная цель в интерфейсе
	var/datum/overmap/ship/selected_target

	/// Активно ли сканирование целей
	var/scanning_active = FALSE

	/// Потребление энергии при сканировании
	var/scan_power_usage = 500

	/// Уровень навыка для использования консоли
	var/required_skill = SKILL_WEAPONS
	var/required_skill_level = SKILL_LEVEL_NOVICE

/obj/machinery/computer/ship/fire_control/Initialize()
	. = ..()
	// Автоматически ищем систему боя при инициализации
	addtimer(CALLBACK(src, PROC_REF(find_combat_system)), 1 SECONDS)

/obj/machinery/computer/ship/fire_control/Destroy()
	if(combat_system)
		combat_system.control_console = null
		combat_system = null
	available_targets.Cut()
	selected_target = null
	return ..()

/**
 * Поиск и привязка к системе боя корабля
 */
/obj/machinery/computer/ship/fire_control/proc/find_combat_system()
	var/area/A = get_area(src)
	if(istype(A, /area/ship))
		var/area/ship/ship_area = A
		if(ship_area.related_ship)
			var/datum/ship_combat_system/CS = get_ship_combat_system(ship_area.related_ship)
			if(CS)
				combat_system = CS
				CS.control_console = src
				update_available_targets()

/**
 * Обновление списка доступных целей
 */
/obj/machinery/computer/ship/fire_control/proc/update_available_targets()
	if(!combat_system || !combat_system.ship || !combat_system.ship.current_overmap)
		return

	available_targets.Cut()

	// Ищем все корабли в текущей системе овермапа
	for(var/datum/overmap/ship/other_ship in combat_system.ship.current_overmap.overmap_ships)
		// Пропускаем наш корабль и уничтоженные корабли
		if(other_ship == combat_system.ship || QDELETED(other_ship))
			continue

		// Проверяем расстояние
		var/distance = combat_system.get_overmap_distance(combat_system.ship, other_ship)
		if(distance <= combat_system.max_target_range)
			var/list/target_info = list(
				"ref" = REF(other_ship),
				"name" = other_ship.name,
				"distance" = distance,
				"type" = other_ship.get_ship_type(),
				"speed" = other_ship.get_speed(),
				"heading" = dir2text(other_ship.get_heading())
			)
			available_targets += list(target_info)

	last_target_scan = world.time

/**
 * Получение данных для интерфейса
 */
/obj/machinery/computer/ship/fire_control/proc/get_ui_data()
	var/list/data = list()

	// Основная информация
	data["active"] = !!combat_system
	data["scanning"] = scanning_active
	data["lastScan"] = last_target_scan
	data["scanInterval"] = target_scan_interval

	// Информация о нашем корабле
	if(combat_system && combat_system.ship)
		data["shipName"] = combat_system.ship.name
		data["shipSpeed"] = combat_system.ship.get_speed()
		data["shipHeading"] = dir2text(combat_system.ship.get_heading())

	// Информация о цели
	if(combat_system && combat_system.target)
		data["target"] = list(
			"ref" = REF(combat_system.target),
			"name" = combat_system.target.name,
			"lockStatus" = combat_system.target_lock_status,
			"lockProgress" = get_target_lock_progress(),
			"distance" = combat_system.get_overmap_distance(combat_system.ship, combat_system.target),
			"speed" = combat_system.target.get_speed(),
			"heading" = dir2text(combat_system.target.get_heading())
		)
	else
		data["target"] = null

	// Список доступных целей
	data["availableTargets"] = available_targets

	// Список вооружения
	data["weapons"] = list()
	if(combat_system)
		for(var/obj/machinery/ship_weapon/weapon in combat_system.weapons)
			data["weapons"] += list(weapon.get_ui_data())

	// Активные снаряды
	data["activeProjectiles"] = list()
	if(combat_system)
		for(var/obj/projectile/ship_projectile/projectile in combat_system.active_projectiles)
			var/list/proj_data = list(
				"ref" = REF(projectile),
				"weapon" = projectile.weapon?.name || "Неизвестно",
				"target" = projectile.target?.name || "Неизвестно",
				"flightProgress" = projectile.flight_progress * 100,
				"timeRemaining" = max(0, projectile.flight_timer - world.time),
				"hitChance" = projectile.hit_chance
			)
			data["activeProjectiles"] += list(proj_data)

	// Статистика боя
	data["combatStats"] = list(
		"damageMultiplier" = combat_system?.damage_multiplier || 1.0,
		"accuracyMultiplier" = combat_system?.accuracy_multiplier || 1.0,
		"rechargeMultiplier" = combat_system?.recharge_multiplier || 1.0
	)

	return data

/**
 * Получение прогресса захвата цели
 */
/obj/machinery/computer/ship/fire_control/proc/get_target_lock_progress()
	if(!combat_system || combat_system.target_lock_status != SHIP_TARGET_LOCK_ACQUIRING)
		return 0

	var/elapsed = world.time - combat_system.target_lock_start_time
	var/progress = (elapsed / combat_system.target_lock_time) * 100

	return clamp(progress, 0, 100)

/**
 * Обработка выстрела оружия
 */
/obj/machinery/computer/ship/fire_control/proc/on_weapon_fired(obj/machinery/ship_weapon/weapon, obj/projectile/ship_projectile/projectile, flight_time)
	if(!combat_system)
		return

	// Обновляем интерфейс
	updateUsrDialog()

	// Записываем в лог
	log_combat("[combat_system.ship.name] выстрелил из [weapon.name] по [combat_system.target.name]. Время полета: [flight_time/10]с")

/**
 * Обработка повреждения оружия
 */
/obj/machinery/computer/ship/fire_control/proc/on_weapon_damaged(obj/machinery/ship_weapon/weapon)
	if(!combat_system)
		return

	// Обновляем интерфейс
	updateUsrDialog()

	// Оповещаем оператора
	playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
	say("[weapon.name] повреждено! Требуется ремонт.")

/**
 * Обработка починки оружия
 */
/obj/machinery/computer/ship/fire_control/proc/on_weapon_repaired(obj/machinery/ship_weapon/weapon)
	if(!combat_system)
		return

	// Обновляем интерфейс
	updateUsrDialog()

	// Оповещаем оператора
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	say("[weapon.name] отремонтировано и готово к использованию.")

/**
 * Запуск сканирования целей
 */
/obj/machinery/computer/ship/fire_control/proc/start_scanning()
	if(scanning_active)
		return

	scanning_active = TRUE
	use_power = ACTIVE_POWER_USE

	// Запускаем процесс сканирования
	START_PROCESSING(SSmachines, src)

	playsound(src, 'sound/machines/terminal_on.ogg', 50, TRUE)
	say("Сканирование целей активировано.")

/**
 * Остановка сканирования целей
 */
/obj/machinery/computer/ship/fire_control/proc/stop_scanning()
	if(!scanning_active)
		return

	scanning_active = FALSE
	use_power = IDLE_POWER_USE

	STOP_PROCESSING(SSmachines, src)

	playsound(src, 'sound/machines/terminal_off.ogg', 50, TRUE)
	say("Сканирование целей деактивировано.")

/**
 * Процесс сканирования
 */
/obj/machinery/computer/ship/fire_control/process()
	if(!scanning_active || !combat_system)
		stop_scanning()
		return

	// Проверяем энергию
	if(stat & NOPOWER)
		stop_scanning()
		return

	// Обновляем цели с интервалом
	if(world.time - last_target_scan >= target_scan_interval)
		update_available_targets()
		updateUsrDialog()

// ==================== TGUI ИНТЕРФЕЙС ====================

/obj/machinery/computer/ship/fire_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FireControl", name)
		ui.open()

/obj/machinery/computer/ship/fire_control/ui_data(mob/user)
	return get_ui_data()

/obj/machinery/computer/ship/fire_control/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	// Проверка навыков
	if(!user.skills.getRating(required_skill) >= required_skill_level)
		to_chat(user, span_warning("У вас недостаточно навыков для использования этой консоли!"))
		return FALSE

	switch(action)
		if("toggle_scan")
			if(scanning_active)
				stop_scanning()
			else
				start_scanning()
			. = TRUE

		if("select_target")
			var/target_ref = params["target"]
			var/datum/overmap/ship/target_ship = locate(target_ref) in combat_system.ship.current_overmap.overmap_ships
			if(target_ship && combat_system.acquire_target(target_ship))
				selected_target = target_ship
				playsound(src, 'sound/machines/terminal_prompt.ogg', 50, TRUE)
				say("Захват цели: [target_ship.name]")
			. = TRUE

		if("clear_target")
			if(combat_system)
				combat_system.target = null
				combat_system.target_lock_status = SHIP_TARGET_LOCK_NONE
				selected_target = null
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
				say("Цель сброшена.")
			. = TRUE

		if("fire_weapon")
			var/weapon_ref = params["weapon"]
			var/obj/machinery/ship_weapon/weapon = locate(weapon_ref) in combat_system?.weapons
			if(weapon && combat_system.fire_weapon(weapon))
				playsound(src, 'sound/machines/terminal_prompt.ogg', 50, TRUE)
				say("[weapon.name] открыл огонь!")
			else
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
				say("Невозможно открыть огонь!")
			. = TRUE

		if("repair_weapon")
			var/weapon_ref = params["weapon"]
			var/obj/machinery/ship_weapon/weapon = locate(weapon_ref) in combat_system?.weapons
			if(weapon && weapon.damaged)
				weapon.repair_weapon()
				playsound(src, 'sound/items/welder.ogg', 50, TRUE)
				say("Ремонт [weapon.name] начат.")
			. = TRUE

		if("update_targets")
			update_available_targets()
			playsound(src, 'sound/machines/terminal_prompt.ogg', 50, TRUE)
			. = TRUE

	// Обновляем интерфейс после действий
	if(.)
		updateUsrDialog()

/obj/machinery/computer/ship/fire_control/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/ship/fire_control/ui_status(mob/user)
	if(!combat_system)
		return UI_CLOSE
	return ..()

// ==================== ПЛАШКА И ЦИФРОВАЯ ПЛАТА ====================

/obj/item/circuitboard/computer/ship/fire_control
	name = "Консоль управления огнем (Плата)"
	build_path = /obj/machinery/computer/ship/fire_control

// ==================== ЛОГИРОВАНИЕ ====================

/**
 * Логирование боевых действий
 */
/proc/log_combat(message)
	log_game("КОСМИЧЕСКИЙ БОЙ: [message]")
	message_admins("КОСМИЧЕСКИЙ БОЙ: [message]")
