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
	if(QDELETED(src))
		return

	var/area/ship/ship_area = get_area(src)
	if(!istype(ship_area))
		return

	if(ship_area.mobile_port?.current_ship)
		var/datum/ship_combat_system/CS = get_ship_combat_system(ship_area.mobile_port.current_ship)
		if(CS)
			combat_system = CS
			CS.control_console = src
			update_available_targets()
			// Принудительная инициализация оружия при подключении консоли
			CS.initialize_weapons()
	else
		// Если корабль еще не инициализирован, попробуем снова через 5 секунд
		addtimer(CALLBACK(src, PROC_REF(find_combat_system)), 5 SECONDS)

/**
 * Обновление списка доступных целей
 */
/obj/machinery/computer/ship/fire_control/proc/update_available_targets()
	if(!combat_system || !combat_system.ship || !combat_system.ship.current_overmap)
		return

	available_targets = list()

	for(var/datum/overmap/ship/controlled/other_ship in SSovermap.controlled_ships)
		if(other_ship == combat_system.ship || QDELETED(other_ship) || other_ship.destroyed)
			continue
		if(other_ship.current_overmap != combat_system.ship.current_overmap)
			continue

		var/distance = combat_system.get_overmap_distance(combat_system.ship, other_ship)
		if(distance <= combat_system.max_target_range)
			var/list/target_info = list(
				ref = REF(other_ship),
				name = other_ship.name,
				distance = distance,
				type = other_ship.ship_type || "Неизвестно",
				speed = other_ship.get_speed(),
				heading = dir2text(other_ship.get_heading())
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

		// Информация об отсеках корабля
		var/datum/overmap/ship/ship = combat_system.ship
		if(ship.compartments && length(ship.compartments) > 0)
			data["compartmentsCount"] = length(ship.compartments)

			// Рассчитываем общее состояние отсеков
			var/total_health = 0
			var/total_max_health = 0
			var/damaged_count = 0
			var/destroyed_count = 0

			for(var/datum/ship_compartment/compartment in ship.compartments)
				total_health += compartment.health
				total_max_health += compartment.max_health
				if(compartment.damaged)
					damaged_count++
				if(compartment.destroyed)
					destroyed_count++

			var/overall_health = total_max_health > 0 ? round((total_health / total_max_health) * 100) : 0
			data["compartmentsHealth"] = overall_health
			data["compartmentsDamaged"] = damaged_count
			data["compartmentsDestroyed"] = destroyed_count

			// Информация о критических отсеках
			var/list/critical_compartments = list()
			for(var/datum/ship_compartment/compartment in ship.compartments)
				if(compartment.health < compartment.max_health * 0.5) // Менее 50% здоровья
					critical_compartments += compartment.name

			if(length(critical_compartments) > 0)
				data["criticalCompartments"] = jointext(critical_compartments, ", ")

	// Информация о цели
	if(combat_system && combat_system.target)
		message_admins("FIRE_CONTROL: Target [combat_system.target.name] status: [combat_system.target_lock_status]")
		data["target"] = list(
			"ref" = REF(combat_system.target),
			"name" = combat_system.target.name,
			"lockStatus" = get_lock_status_text(combat_system.target_lock_status),
			"lockProgress" = get_target_lock_progress(),
			"distance" = combat_system.get_overmap_distance(combat_system.ship, combat_system.target),
			"speed" = combat_system.target.get_speed(),
			"heading" = dir2text(combat_system.target.get_heading())
		)
	else
		data["target"] = null

	// Список доступных целей
	var/list/targets_list = list()
	if(combat_system && combat_system.ship && combat_system.ship.current_overmap)
		for(var/datum/overmap/ship/controlled/other_ship in SSovermap.controlled_ships)
			if(other_ship == combat_system.ship || QDELETED(other_ship) || other_ship.destroyed)
				continue
			if(other_ship.current_overmap != combat_system.ship.current_overmap)
				continue

			var/distance = combat_system.get_overmap_distance(combat_system.ship, other_ship)
			if(distance <= combat_system.max_target_range)
				var/list/target_info = list(
					ref = REF(other_ship),
					name = other_ship.name,
					distance = distance,
					type = other_ship.ship_type || "Неизвестно",
					speed = other_ship.get_speed(),
					heading = dir2text(other_ship.get_heading())
				)
				targets_list[++targets_list.len] = target_info
	data["availableTargets"] = targets_list

	// Список вооружения
	var/list/weapons_list = list()
	if(combat_system)
		for(var/obj/machinery/ship_weapon/weapon in combat_system.weapons)
			if(QDELETED(weapon))
				continue
			var/list/W = list(
				ref = REF(weapon),
				name = weapon.name,
				type = weapon.weapon_type,
				state = weapon.weapon_state,
				damage = weapon.damage,
				accuracy = weapon.base_accuracy,
				charge = weapon.current_charge,
				maxCharge = weapon.max_charge,
				rechargeTime = max(0, weapon.next_fire_time - world.time),
				maxRechargeTime = weapon.recharge_time,
				damaged = weapon.damaged,
				misfireChance = weapon.misfire_chance,
				canFire = 1,
				optimalRange = weapon.optimal_range,
				maxRange = weapon.max_range,
				targetDistance = (combat_system.target ? combat_system.get_overmap_distance(combat_system.ship, combat_system.target) : 0),
				inRange = (combat_system.target ? (combat_system.get_overmap_distance(combat_system.ship, combat_system.target) <= weapon.max_range) : FALSE)
			)
			weapons_list += list(W)
	data["weapons"] = weapons_list

	// Активные снаряды
	var/list/projectiles_list = list()
	if(combat_system)
		for(var/obj/projectile/ship_projectile/projectile in combat_system.active_projectiles)
			var/list/P = list(
				ref = REF(projectile),
				weapon = projectile.weapon?.name || "Неизвестно",
				target = projectile.target?.name || "Неизвестно",
				flightProgress = projectile.flight_progress * 100,
				timeRemaining = max(0, projectile.flight_timer - world.time),
				hitChance = projectile.hit_chance
			)
			projectiles_list += list(P)
	data["activeProjectiles"] = projectiles_list

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
	LOG_SHIP_COMBAT("[combat_system.ship.name] выстрелил из [weapon.name] по [combat_system.target.name]. Время полета: [flight_time/10]с")

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
	if(machine_stat & NOPOWER)
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
		ui = new(user, src, "FireControl", "СУО v2.1 [DEBUG]")
		ui.open()

/obj/machinery/computer/ship/fire_control/ui_data(mob/user)
	var/list/data = get_ui_data()
	to_chat(user, span_notice("DEBUG: Sending [length(data["weapons"])] weapons and [length(data["availableTargets"])] targets"))
	return data

/obj/machinery/computer/ship/fire_control/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle_scan")
			if(scanning_active)
				stop_scanning()
			else
				start_scanning()
			. = TRUE

		if("select_target")
			var/target_ref = params["target"]
			// Ищем цель в той же системе (как в update_available_targets)
			var/datum/overmap/ship/controlled/target_ship
			for(var/datum/overmap/ship/controlled/S in SSovermap.controlled_ships)
				if(REF(S) == target_ref && S.current_overmap == combat_system.ship.current_overmap)
					target_ship = S
					break
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
			message_admins("FIRE_CONTROL: Attempting to fire weapon [weapon_ref]. Found: [weapon ? weapon.name : "NULL"]")
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

		if("select_target_manual")
			var/list/targets = list()
			for(var/datum/overmap/ship/controlled/S in SSovermap.controlled_ships)
				if(S == combat_system.ship || QDELETED(S) || S.destroyed)
					continue
				if(S.current_overmap != combat_system.ship.current_overmap)
					continue
				var/distance = combat_system.get_overmap_distance(combat_system.ship, S)
				if(distance <= combat_system.max_target_range)
					targets[S.name] = S

			if(!length(targets))
				to_chat(usr, span_warning("Цели не обнаружены."))
				return

			var/selected = tgui_input_list(usr, "Выберите цель для захвата", "СУО", targets)
			if(selected && targets[selected])
				var/datum/overmap/ship/target_ship = targets[selected]
				if(combat_system.acquire_target(target_ship))
					selected_target = target_ship
					playsound(src, 'sound/machines/terminal_prompt.ogg', 50, TRUE)
					say("Захват цели: [target_ship.name]")
			. = TRUE

		if("refresh_weapons")
			// Сначала пытаемся найти систему боя
			find_combat_system()
			if(combat_system)
				combat_system.initialize_weapons()
				update_available_targets()
				playsound(src, 'sound/machines/terminal_prompt.ogg', 50, TRUE)
				say("Система обновлена.")
			else
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
				say("Система боя не найдена.")
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

/obj/machinery/computer/ship/fire_control/proc/get_lock_status_text(status)
	switch(status)
		if(SHIP_TARGET_LOCK_NONE)
			return "none"
		if(SHIP_TARGET_LOCK_ACQUIRING)
			return "acquiring"
		if(SHIP_TARGET_LOCK_LOCKED)
			return "locked"
		if(SHIP_TARGET_LOCK_LOST)
			return "lost"
	return "none"

// ==================== ПЛАШКА И ЦИФРОВАЯ ПЛАТА ====================

/obj/item/circuitboard/computer/ship/fire_control
	name = "Консоль управления огнем (Плата)"
	build_path = /obj/machinery/computer/ship/fire_control

// ==================== КОНСОЛЬ МОНИТОРИНГА ОТСЕКОВ ====================

/**
 * Консоль мониторинга состояния отсеков корабля
 */
/obj/machinery/computer/ship/compartments_monitor
	name = "консоль мониторинга отсеков"
	desc = "Отображает состояние всех отсеков корабля и их уязвимости."
	icon_screen = "engine"
	icon_keyboard = "tech_key"

	/// Ссылка на корабль
	var/datum/overmap/ship/controlled/linked_ship

/obj/machinery/computer/ship/compartments_monitor/Initialize()
	. = ..()
	// Автоматически ищем корабль при инициализации
	addtimer(CALLBACK(src, PROC_REF(find_ship)), 1 SECONDS)

/obj/machinery/computer/ship/compartments_monitor/Destroy()
	linked_ship = null
	return ..()

/**
 * Поиск и привязка к кораблю
 */
/obj/machinery/computer/ship/compartments_monitor/proc/find_ship()
	var/area/ship/ship_area = get_area(src)
	if(!istype(ship_area))
		return

	if(ship_area.mobile_port)
		linked_ship = ship_area.mobile_port.current_ship

/**
 * Получение данных для интерфейса
 */
/obj/machinery/computer/ship/compartments_monitor/proc/get_ui_data()
	var/list/data = list()

	data["active"] = !!linked_ship

	if(linked_ship)
		data["shipName"] = linked_ship.name
		data["shipType"] = linked_ship.ship_type
		data["shipSize"] = linked_ship.calculate_ship_size()

		// Информация об отсеках
		if(linked_ship.compartments && length(linked_ship.compartments) > 0)
			data["compartments"] = list()

			for(var/i = 1 to length(linked_ship.compartments))
				var/datum/ship_compartment/compartment = linked_ship.compartments[i]
				var/health_percent = round((compartment.health / compartment.max_health) * 100)

				var/list/compartment_data = list(
					"id" = i,
					"name" = compartment.name,
					"health" = health_percent,
					"fireRisk" = compartment.fire_risk,
					"breachRisk" = compartment.breach_risk,
					"damaged" = compartment.damaged,
					"destroyed" = compartment.destroyed,
					"status" = compartment.destroyed ? "destroyed" : compartment.damaged ? "damaged" : health_percent > 70 ? "good" : health_percent > 30 ? "warning" : "critical"
				)

				data["compartments"] += list(compartment_data)

			data["totalCompartments"] = length(linked_ship.compartments)

			// Статистика
			var/total_health = 0
			var/total_max_health = 0
			var/damaged_count = 0
			var/destroyed_count = 0
			var/high_fire_risk = 0
			var/high_breach_risk = 0

			for(var/datum/ship_compartment/compartment in linked_ship.compartments)
				total_health += compartment.health
				total_max_health += compartment.max_health
				if(compartment.damaged)
					damaged_count++
				if(compartment.destroyed)
					destroyed_count++
				if(compartment.fire_risk >= 30)
					high_fire_risk++
				if(compartment.breach_risk >= 15)
					high_breach_risk++

			var/overall_health = total_max_health > 0 ? round((total_health / total_max_health) * 100) : 0
			data["overallHealth"] = overall_health
			data["damagedCount"] = damaged_count
			data["destroyedCount"] = destroyed_count
			data["highFireRisk"] = high_fire_risk
			data["highBreachRisk"] = high_breach_risk

	return data

// ==================== TGUI ИНТЕРФЕЙС ====================

/obj/machinery/computer/ship/compartments_monitor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ShipCompartmentsMonitor", "Мониторинг отсеков")
		ui.open()

/obj/machinery/computer/ship/compartments_monitor/ui_data(mob/user)
	return get_ui_data()

/obj/machinery/computer/ship/compartments_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("refresh")
			find_ship()
			updateUsrDialog()
			return TRUE

/obj/machinery/computer/ship/compartments_monitor/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/ship/compartments_monitor/ui_status(mob/user)
	if(!linked_ship)
		return UI_CLOSE
	return ..()

/**
 * Плата для консоли мониторинга отсеков
 */
/obj/item/circuitboard/computer/ship/compartments_monitor
	name = "Консоль мониторинга отсеков (Плата)"
	build_path = /obj/machinery/computer/ship/compartments_monitor

// ==================== ЛОГИРОВАНИЕ ====================

// Используйте макрос LOG_SHIP_COMBAT из __DEFINES/ship_combat.dm
// #define LOG_SHIP_COMBAT(message) log_game("КОСМИЧЕСКИЙ БОЙ: [message]"); message_admins("КОСМИЧЕСКИЙ БОЙ: [message]")
