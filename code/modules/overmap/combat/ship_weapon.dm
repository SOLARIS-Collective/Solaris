/**
 * # Машинерия корабельного вооружения
 *
 * Физическое представление оружия на корабле
 */

/obj/machinery/ship_weapon
	name = "корабельное оружие"
	desc = "Базовая система вооружения для космического корабля."
	icon = 'code/modules/overmap/combat/system_weapons.dmi'
	icon_state = "laser"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 100
	active_power_usage = 1000

	/// Ссылка на систему боя корабля
	var/datum/ship_combat_system/combat_system

	/// Тип оружия (лазер, кинетическое, ракета и т.д.)
	var/weapon_type = SHIP_WEAPON_TYPE_KINETIC

	/// Текущее состояние оружия
	var/weapon_state = SHIP_WEAPON_STATE_READY

	/// Урон оружия
	var/damage = 25

	/// Тип урона (BRUTE, BURN, и т.д.)
	var/damage_type = BRUTE

	/// Пробитие брони (0-100%)
	var/armor_penetration = 0

	/// Множитель урона по щитам
	var/shield_damage_multiplier = 1.0

	/// Базовая точность (0-100)
	var/base_accuracy = 75

	/// Оптимальная дальность стрельбы
	var/optimal_range = 10

	/// Максимальная дальность стрельбы
	var/max_range = 30

	/// Скорость снаряда (тайлов в секунду)
	var/projectile_speed = 5

	/// Время перезарядки между выстрелами (в тиках)
	var/recharge_time = 10 SECONDS

	/// Таймер до следующего выстрела
	var/next_fire_time = 0

	/// Текущий заряд (для энергетического оружия)
	var/current_charge = 100

	/// Максимальный заряд
	var/max_charge = 100

	/// Скорость перезарядки (заряд в тик)
	var/recharge_rate = 1

	/// Потребление энергии за выстрел
	var/power_usage_per_shot = 300

	/// Тип создаваемого снаряда
	var/projectile_type = /obj/projectile/ship_projectile/kinetic

	/// Флаг, указывающий на повреждение оружия
	var/damaged = FALSE

	/// Вероятность осечки при повреждении (0-100)
	var/misfire_chance = 0

	/// Время починки при повреждении
	var/repair_time = 30 SECONDS

	/// Таймер починки
	var/repair_timer = 0

	/// Система искр для эффектов повреждения
	var/datum/effect_system/spark_spread/spark_system

/obj/machinery/ship_weapon/Initialize()
	. = ..()
	// Инициализация системы искр
	spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	// Автоматически ищем систему боя при инициализации
	addtimer(CALLBACK(src, PROC_REF(find_combat_system)), 1 SECONDS)

/obj/machinery/ship_weapon/Destroy()
	combat_system = null
	return ..()

/**
 * Поиск и привязка к системе боя корабля
 */
/obj/machinery/ship_weapon/proc/find_combat_system()
	var/area/ship/ship_area = get_area(src)
	if(!istype(ship_area))
		return
	if(ship_area.mobile_port?.current_ship)
		var/datum/ship_combat_system/CS = get_ship_combat_system(ship_area.mobile_port.current_ship)
		if(CS)
			combat_system = CS
			CS.weapons += src
			initialize_weapon()

/**
 * Инициализация оружия после привязки к системы
 */
/obj/machinery/ship_weapon/proc/initialize_weapon()
	// Сброс состояния
	weapon_state = SHIP_WEAPON_STATE_READY
	next_fire_time = 0
	current_charge = max_charge
	damaged = FALSE
	misfire_chance = 0

	update_icon()

/**
 * Обновление иконки в зависимости от состояния
 */
/obj/machinery/ship_weapon/update_icon()
	. = ..()

	var/mutable_appearance/status_overlay = mutable_appearance(icon, "[icon_state]_status")

	switch(weapon_state)
		if(SHIP_WEAPON_STATE_READY)
			status_overlay.color = SHIP_COLOR_GOOD
		if(SHIP_WEAPON_STATE_CHARGING)
			status_overlay.color = SHIP_COLOR_AVERAGE
		if(SHIP_WEAPON_STATE_FIRING)
			status_overlay.color = SHIP_COLOR_BAD
		if(SHIP_WEAPON_STATE_DAMAGED)
			status_overlay.color = "#800000" // Темно-красный
		if(SHIP_WEAPON_STATE_DISABLED)
			status_overlay.color = SHIP_COLOR_DISABLED

	add_overlay(status_overlay)

	// Индикатор заряда
	if(current_charge < max_charge)
		var/mutable_appearance/charge_overlay = mutable_appearance(icon, "[icon_state]_charge")
		var/charge_percent = current_charge / max_charge
		charge_overlay.alpha = 150 * charge_percent
		add_overlay(charge_overlay)

/**
 * Проверка возможности выстрела
 *
 * @return TRUE если можно стрелять, FALSE если нет
 */
/obj/machinery/ship_weapon/proc/can_fire()
	if(weapon_state != SHIP_WEAPON_STATE_READY)
		return FALSE

	if(world.time < next_fire_time)
		return FALSE

	if(current_charge < power_usage_per_shot)
		return FALSE

	if(damaged && prob(misfire_chance))
		return FALSE

	if(!combat_system || !combat_system.target)
		return FALSE

	// Проверка расстояния до цели
	var/distance = combat_system.get_overmap_distance(combat_system.ship, combat_system.target)
	if(distance > max_range)
		return FALSE

	return TRUE

/**
 * Процедура выстрела
 *
 * @return TRUE если выстрел произведен, FALSE если ошибка
 */
/obj/machinery/ship_weapon/proc/fire()
	if(!can_fire())
		return FALSE

	// Потребление энергии
	current_charge -= power_usage_per_shot
	if(current_charge < 0)
		current_charge = 0

	// Установка времени перезарядки
	next_fire_time = world.time + (recharge_time / combat_system.recharge_multiplier)

	// Изменение состояния
	weapon_state = SHIP_WEAPON_STATE_FIRING
	update_icon()

	// Эффекты выстрела
	create_fire_effects()

	// Звук выстрела
	playsound(src, get_fire_sound(), 50, TRUE)

	// Задержка перед возвратом в готовность
	addtimer(CALLBACK(src, PROC_REF(reset_to_ready)), 1 SECONDS)

	return TRUE

/**
 * Сброс состояния в готовность
 */
/obj/machinery/ship_weapon/proc/reset_to_ready()
	weapon_state = SHIP_WEAPON_STATE_READY
	update_icon()

/**
 * Создание визуальных эффектов выстрела
 */
/obj/machinery/ship_weapon/proc/create_fire_effects()
	// Вспышка
	var/obj/effect/temp_visual/muzzle_flash = new /obj/effect/temp_visual/muzzle_flash(get_turf(src))
	muzzle_flash.dir = dir

	// Дым
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(1, get_turf(src))
	smoke.start()

/**
 * Получение звука выстрела в зависимости от типа оружия
 */
/obj/machinery/ship_weapon/proc/get_fire_sound()
	switch(weapon_type)
		if(SHIP_WEAPON_TYPE_LASER)
			return 'sound/weapons/laser.ogg'
		if(SHIP_WEAPON_TYPE_KINETIC)
			return 'sound/weapons/gun/shotgun/shot.ogg'
		if(SHIP_WEAPON_TYPE_MISSILE)
			return 'sound/effects/explosion_large1.ogg'
		if(SHIP_WEAPON_TYPE_ENERGY)
			return 'sound/weapons/emitter.ogg'
	return 'sound/weapons/gun/rifle/skm_smg.ogg'

/**
 * Процесс п��резарядки и обслуживания
 * Вызывается каждый тик из системы боя
 */
/obj/machinery/ship_weapon/process()
	// Перезарядка
	if(current_charge < max_charge)
		current_charge = min(max_charge, current_charge + recharge_rate)
		if(current_charge == max_charge && weapon_state == SHIP_WEAPON_STATE_READY)
			update_icon()

	// Починка
	if(damaged && world.time >= repair_timer)
		repair_weapon()

/**
 * Получение повреждения
 *
 * @param severity - серьезность повреждения (1-100)
 */
/obj/machinery/ship_weapon/take_damage(severity = 25)
	if(damaged)
		return // Уже повреждено

	damaged = TRUE
	misfire_chance = min(100, severity)
	weapon_state = SHIP_WEAPON_STATE_DAMAGED

	// Время починки зависит от серьезности повреждения
	repair_timer = world.time + (repair_time * (severity / 100))

	// Эффекты повреждения
	spark_system.start()
	playsound(src, 'sound/effects/sparks2.ogg', 50, TRUE)

	update_icon()

	// Оповещение системы боя
	if(combat_system && combat_system.control_console)
		combat_system.control_console.on_weapon_damaged(src)

/**
 * Починка оружия
 */
/obj/machinery/ship_weapon/proc/repair_weapon()
	damaged = FALSE
	misfire_chance = 0
	weapon_state = SHIP_WEAPON_STATE_READY
	repair_timer = 0

	update_icon()

	// Оповещение системы боя
	if(combat_system && combat_system.control_console)
		combat_system.control_console.on_weapon_repaired(src)

/**
 * Получение информации о состоянии для интерфейса
 *
 * @return список с информацией об оружии
 */
/obj/machinery/ship_weapon/proc/get_ui_data()
	var/list/data = list()

	data["ref"] = REF(src)
	data["name"] = name
	data["type"] = weapon_type
	data["state"] = weapon_state
	data["damage"] = damage
	data["accuracy"] = base_accuracy
	data["charge"] = current_charge
	data["maxCharge"] = max_charge
	data["rechargeTime"] = max(0, next_fire_time - world.time)
	data["maxRechargeTime"] = recharge_time
	data["damaged"] = damaged
	data["misfireChance"] = misfire_chance
	data["canFire"] = can_fire()
	data["optimalRange"] = optimal_range
	data["maxRange"] = max_range

	// Информация о цели
	if(combat_system && combat_system.target)
		var/distance = combat_system.get_overmap_distance(combat_system.ship, combat_system.target)
		data["targetDistance"] = distance
		data["inRange"] = (distance <= max_range)
	else
		data["targetDistance"] = 0
		data["inRange"] = FALSE

	return data

// ==================== ПОДТИПЫ ОРУЖИЯ ====================

/obj/machinery/ship_weapon/kinetic
	name = "кинетическая пушка"
	desc = "Стандартное кинетическое оружие для космического боя. Стреляет твердыми снарядами."
	icon_state = "kinetic_cannon"
	weapon_type = SHIP_WEAPON_TYPE_KINETIC
	damage = 30
	damage_type = BRUTE
	armor_penetration = 20
	shield_damage_multiplier = 0.8
	base_accuracy = 70
	optimal_range = 8
	max_range = 25
	projectile_speed = 7
	recharge_time = 8 SECONDS
	power_usage_per_shot = 300

/obj/machinery/ship_weapon/laser
	name = "лазерная пушка"
	desc = "Энергетическое оружие, стреляющее сфокусированными лучами света."
	icon_state = "laser_cannon"
	weapon_type = SHIP_WEAPON_TYPE_LASER
	damage = 25
	damage_type = BURN
	armor_penetration = 5
	shield_damage_multiplier = 1.5
	base_accuracy = 85
	optimal_range = 12
	max_range = 35
	projectile_speed = 10 // Лазеры быстрее
	recharge_time = 6 SECONDS
	power_usage_per_shot = 400
	projectile_type = /obj/projectile/ship_projectile/laser

/obj/machinery/ship_weapon/missile
	name = "ракетная установка"
	desc = "Пусковая установка для управляемых ракет. Медленная перезарядка, но высокий урон."
	icon_state = "missile_launcher"
	weapon_type = SHIP_WEAPON_TYPE_MISSILE
	damage = 50
	damage_type = BRUTE
	armor_penetration = 40
	shield_damage_multiplier = 1.0
	base_accuracy = 90 // Ракеты имеют наведение
	optimal_range = 15
	max_range = 40
	projectile_speed = 4 // Ракеты медленнее
	recharge_time = 20 SECONDS
	power_usage_per_shot = 800
	projectile_type = /obj/projectile/ship_projectile/missile

/obj/machinery/ship_weapon/energy
	name = "энергетическая пушка"
	desc = "Мощное энергетическое оружие, потребляющее много энергии."
	icon_state = "energy_cannon"
	weapon_type = SHIP_WEAPON_TYPE_ENERGY
	damage = 40
	damage_type = BURN
	armor_penetration = 25
	shield_damage_multiplier = 1.2
	base_accuracy = 80
	optimal_range = 10
	max_range = 30
	projectile_speed = 8
	recharge_time = 15 SECONDS
	power_usage_per_shot = 1000
	projectile_type = /obj/projectile/ship_projectile/energy

// ==================== ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ====================

/obj/effect/temp_visual/muzzle_flash
	icon = 'icons/effects/effects.dmi'
	icon_state = "muzzle_flash"
	duration = 5
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/muzzle_flash/Initialize()
	. = ..()
	QDEL_IN(src, duration)
