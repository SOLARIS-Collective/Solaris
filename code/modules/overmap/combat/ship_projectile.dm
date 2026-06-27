/**
 * # Снаряды для космического боя
 *
 * Адаптация системы проектилей для боя между кораблями
 */

/obj/projectile/ship_projectile
	name = "космический снаряд"
	desc = "Снаряд, летящий через космическое пространство."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "ship_kinetic"
	speed = 1
	range = 1000 // Очень большая дальность для космоса

	/// Ссылка на корабль-стрелок
	var/datum/overmap/ship/firer_ship

	/// Ссылка на цель
	var/datum/overmap/ship/target

	/// Ссылка на оружие, из которого был произведен выстрел
	var/obj/machinery/ship_weapon/weapon

	/// Время полета до цели (в тиках)
	var/flight_time = 0

	/// Таймер полета
	var/flight_timer = 0

	/// Шанс попадания (0-100)
	var/hit_chance = 100

	/// Флаг, указывающий что снаряд в полете
	var/in_flight = FALSE

	/// Флаг, указывающий что снаряд попал
	var/hit_successful = FALSE

	/// Позиция на овермапе, откуда был запущен снаряд
	var/list/start_position = list("x" = 0, "y" = 0)

	/// Позиция цели на момент запуска
	var/list/target_start_position = list("x" = 0, "y" = 0)

	/// Текущая позиция на овермапе (для визуализации)
	var/list/current_position = list("x" = 0, "y" = 0)

	/// Прогресс полета (0-1)
	var/flight_progress = 0

	/// Визуальный объект на овермапе
	var/obj/overmap/projectile/overmap_token

/obj/projectile/ship_projectile/Initialize()
	. = ..()
	// Снаряды для космического боя не используют стандартную систему движения
	movement_type = PHASING
	SET_PLANE_EXPLICIT(src, PLANE_SPACE, src)

/obj/projectile/ship_projectile/Destroy()
	firer_ship = null
	target = null
	weapon = null
	if(overmap_token)
		QDEL_NULL(overmap_token)
	return ..()

/**
 * Настройка снаряда перед запуском
 *
 * @param firer - корабль-стрелок
 * @param target_ship - цель
 * @param firing_weapon - оружие
 * @param flight_duration - время полета
 * @param chance_to_hit - шанс попадания
 */
/obj/projectile/ship_projectile/proc/setup_projectile(datum/overmap/ship/firer, datum/overmap/ship/target_ship,
													  obj/machinery/ship_weapon/firing_weapon,
													  flight_duration, chance_to_hit)
	firer_ship = firer
	target = target_ship
	weapon = firing_weapon
	flight_time = flight_duration
	hit_chance = chance_to_hit

	// Сохраняем начальные позиции
	start_position["x"] = firer.x
	start_position["y"] = firer.y
	target_start_position["x"] = target.x
	target_start_position["y"] = target.y
	current_position = start_position.Copy()

	// Настраиваем внешний вид в зависимости от типа оружия
	setup_appearance()

	// Создаем визуальный объект на овермапе
	create_overmap_token()

	// Запускаем полет
	start_flight()

/**
 * Настройка внешнего вида снаряда
 */
/obj/projectile/ship_projectile/proc/setup_appearance()
	if(!weapon)
		return

	switch(weapon.weapon_type)
		if(SHIP_WEAPON_TYPE_LASER)
			icon_state = "ship_laser"
			color = COLOR_CYAN
			light_color = COLOR_CYAN
			light_range = 2
		if(SHIP_WEAPON_TYPE_KINETIC)
			icon_state = "ship_kinetic"
			color = COLOR_GRAY
			light_color = COLOR_WHITE
			light_range = 1
		if(SHIP_WEAPON_TYPE_MISSILE)
			icon_state = "ship_missile"
			color = COLOR_RED
			light_color = COLOR_RED
			light_range = 3
		if(SHIP_WEAPON_TYPE_ENERGY)
			icon_state = "ship_energy"
			color = COLOR_PURPLE
			light_color = COLOR_PURPLE
			light_range = 2

/**
 * Создание визуального объекта на овермапе
 */
/obj/projectile/ship_projectile/proc/create_overmap_token()
	if(!firer_ship || !firer_ship.current_overmap)
		return

	overmap_token = new /obj/overmap/projectile(firer_ship.current_overmap)
	overmap_token.setup_token(src)
	overmap_token.forceMove(firer_ship.current_overmap)
	overmap_token.x = start_position["x"]
	overmap_token.y = start_position["y"]

/**
 * Начало полета снаряда
 */
/obj/projectile/ship_projectile/proc/start_flight()
	in_flight = TRUE
	flight_timer = world.time + flight_time
	flight_progress = 0

	// Запускаем обработку полета
	START_PROCESSING(SSfastprocess, src)

	// Оповещаем о запуске
	broadcast_launch_notification()

/**
 * Оповещение о запуске снаряда
 */
/obj/projectile/ship_projectile/proc/broadcast_launch_notification()
	if(!firer_ship || !target)
		return

	// Оповещаем стреляющий корабль (если это управляемый корабль)
	if(istype(firer_ship, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/firing_ship = firer_ship
		if(firing_ship.shuttle_port)
			var/area/firer_area = get_area(firing_ship.shuttle_port)
			for(var/mob/living/L in firer_area)
				to_chat(L, span_notice("[icon2html(weapon, L)] [weapon.name] запущен! Время до попадания: [flight_time/10] секунд."))

	// Оповещаем цель (если это игрок)
	if(istype(target, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/target_ship = target
		if(target_ship.shuttle_port)
			var/area/target_area = get_area(target_ship.shuttle_port)
			for(var/mob/living/L in target_area)
				to_chat(L, span_warning("Обнаружен запуск снаряда с [firer_ship.name]! Время до попадания: [flight_time/10] секунд."))

/**
 * Обработка полета снаряда
 * Вызывается каждый тик
 */
/obj/projectile/ship_projectile/proc/process_flight()
	if(!in_flight || QDELETED(src))
		return

	if(QDELETED(firer_ship) || QDELETED(target))
		miss()
		return

	if(world.time >= flight_timer)
		// Время полета истекло - проверяем попадание
		check_hit()
		return

	// Обновляем прогресс полета
	var/elapsed = world.time - (flight_timer - flight_time)
	flight_progress = elapsed / flight_time

	// Обновляем позицию на овермапе
	update_position()

	// Обновляем визуальный объект
	if(overmap_token)
		overmap_token.update_position(current_position["x"], current_position["y"], flight_progress)

/**
 * Обновление позиции снаряда на овермапе
 */
/obj/projectile/ship_projectile/proc/update_position()
	if(QDELETED(target) || QDELETED(firer_ship))
		return

	// Линейная интерполяция между стартовой позицией и текущей позицией цели
	var/target_current_x = target.x
	var/target_current_y = target.y

	// Учитываем движение цели во время полета
	var/predicted_target_x = target_start_position["x"] + (target_current_x - target_start_position["x"]) * flight_progress
	var/predicted_target_y = target_start_position["y"] + (target_current_y - target_start_position["y"]) * flight_progress

	// Текущая позиция снаряда
	current_position["x"] = start_position["x"] + (predicted_target_x - start_position["x"]) * flight_progress
	current_position["y"] = start_position["y"] + (predicted_target_y - start_position["y"]) * flight_progress

/**
 * Проверка попадания по истечении времени полета
 */
/obj/projectile/ship_projectile/proc/check_hit()
	if(!in_flight)
		return

	in_flight = FALSE
	STOP_PROCESSING(SSfastprocess, src)

	// Проверяем, жива ли цель
	if(!target || QDELETED(target))
		miss()
		return

	// Проверяем расстояние до цели
	var/distance = calculate_final_distance()
	var/max_miss_distance = 3 // Максимальное расстояние для промаха

	if(distance <= max_miss_distance)
		// В зоне попадания - проверяем шанс
		if(prob(hit_chance))
			hit()
		else
			near_miss()
	else
		// Слишком далеко - промах
		miss()

/**
 * Расчет конечного расстояния до цели
 */
/obj/projectile/ship_projectile/proc/calculate_final_distance()
	if(!target)
		return INFINITY

	var/dx = current_position["x"] - target.x
	var/dy = current_position["y"] - target.y

	return sqrt(dx*dx + dy*dy)

/**
 * Обработка попадания
 */
/obj/projectile/ship_projectile/proc/hit()
	hit_successful = TRUE

	// Оповещаем систему боя
	if(firer_ship && firer_ship.combat_system)
		firer_ship.combat_system.process_hit(src, TRUE)

	// Визуальные эффекты попадания
	create_impact_effects()

	// Уничтожаем визуальный объект
	if(overmap_token)
		QDEL_NULL(overmap_token)

/**
 * Обработка близкого промаха
 */
/obj/projectile/ship_projectile/proc/near_miss()
	// Оповещаем систему боя о промахе
	if(firer_ship && firer_ship.combat_system)
		firer_ship.combat_system.process_hit(src, FALSE)

	// Визуальные эффекты промаха
	create_miss_effects()

	// Уничтожаем визуальный объект
	if(overmap_token)
		QDEL_NULL(overmap_token)

/**
 * Обработка полного промаха
 */
/obj/projectile/ship_projectile/proc/miss()
	// Оповещаем систему боя о промахе
	if(firer_ship && firer_ship.combat_system)
		firer_ship.combat_system.process_hit(src, FALSE)

	// Уничтожаем визуальный объект
	if(overmap_token)
		QDEL_NULL(overmap_token)

/**
 * Создание эффектов попадания
 */
/obj/projectile/ship_projectile/proc/create_impact_effects()
	// Создаем эффект на овермапе
	if(target && target.current_overmap)
		var/obj/effect/temp_visual/ship_impact/impact = new /obj/effect/temp_visual/ship_impact(target.current_overmap)
		impact.forceMove(target.current_overmap)
		impact.x = target.x
		impact.y = target.y

	// Звук попадания (если есть игроки в зоне)
	if(istype(target, /datum/overmap/ship/controlled))
		var/datum/overmap/ship/controlled/target_ship = target
		if(target_ship.shuttle_port)
			var/area/target_area = get_area(target_ship.shuttle_port)
			for(var/mob/living/L in target_area)
				playsound(L, get_impact_sound(), 50, TRUE)

/**
 * Создание эффектов промаха
 */
/obj/projectile/ship_projectile/proc/create_miss_effects()
	// Создаем эффект промаха на овермапе
	if(target && target.current_overmap)
		var/obj/effect/temp_visual/ship_miss/miss = new /obj/effect/temp_visual/ship_miss(target.current_overmap)
		miss.forceMove(target.current_overmap)
		miss.x = current_position["x"]
		miss.y = current_position["y"]

/**
 * Получение звука попадания
 */
/obj/projectile/ship_projectile/proc/get_impact_sound()
	if(!weapon)
		return 'sound/effects/explosion1.ogg'

	switch(weapon.weapon_type)
		if(SHIP_WEAPON_TYPE_LASER)
			return 'sound/weapons/sear.ogg'
		if(SHIP_WEAPON_TYPE_KINETIC)
			return 'sound/effects/explosion1.ogg'
		if(SHIP_WEAPON_TYPE_MISSILE)
			return 'sound/effects/explosion2.ogg'
		if(SHIP_WEAPON_TYPE_ENERGY)
			return 'sound/weapons/emitter2.ogg'

	return 'sound/effects/explosion1.ogg'

// ==================== ПОДТИПЫ СНАРЯДОВ ====================

/obj/projectile/ship_projectile/kinetic
	name = "кинетический снаряд"
	icon_state = "ship_kinetic"

/obj/projectile/ship_projectile/laser
	name = "лазерный луч"
	icon_state = "ship_laser"

/obj/projectile/ship_projectile/missile
	name = "ракета"
	icon_state = "ship_missile"

/obj/projectile/ship_projectile/energy
	name = "энергетический заряд"
	icon_state = "ship_energy"

// ==================== ВИЗУАЛЬНЫЕ ОБЪЕКТЫ НА ОВЕРМАПЕ ====================

/**
 * Визуальное представление снаряда на овермапе
 */
/obj/overmap/projectile
	name = "снаряд"
	icon = 'icons/obj/projectiles_tracer.dmi'
	icon_state = "bolt"
	layer = OVERMAP_LAYER_PROJECTILE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	/// Ссылка на снаряд
	var/obj/projectile/ship_projectile/projectile

	/// Текущий прогресс полета (для анимации)
	var/current_progress = 0

/obj/overmap/projectile/Initialize()
	. = ..()
	// Проектили на овермапе не должны быть интерактивными
	anchored = TRUE

/obj/overmap/projectile/Destroy()
	projectile = null
	return ..()

/**
 * Настройка визуального объекта
 */
/obj/overmap/projectile/proc/setup_token(obj/projectile/ship_projectile/proj)
	projectile = proj
	update_appearance()

/**
 * Обновление внешнего вида
 */
/obj/overmap/projectile/update_icon()
	. = ..()

	if(!projectile)
		return

	// Меняем иконку в зависимости от типа снаряда
	switch(projectile.weapon?.weapon_type)
		if(SHIP_WEAPON_TYPE_LASER)
			icon_state = "xray"
			color = COLOR_CYAN
		if(SHIP_WEAPON_TYPE_KINETIC)
			icon_state = "bolt"
			color = COLOR_GRAY
		if(SHIP_WEAPON_TYPE_MISSILE)
			icon_state = "big"
			color = COLOR_RED
		if(SHIP_WEAPON_TYPE_ENERGY)
			icon_state = "solar"
			color = COLOR_PURPLE
		else
			icon_state = "beam_omni"
			color = COLOR_WHITE

	// Прозрачность в зависимости от прогресса полета
	alpha = 150 + (current_progress * 105) // От 150 до 255

/**
 * Обновление позиции на овермапе
 */
/obj/overmap/projectile/proc/update_position(new_x, new_y, progress)
	x = new_x
	y = new_y
	current_progress = progress
	update_appearance()

// ==================== ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ====================

/obj/effect/temp_visual/ship_impact
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	duration = 10
	layer = OVERMAP_LAYER_EFFECT

/obj/effect/temp_visual/ship_impact/Initialize()
	. = ..()
	playsound(src, 'sound/effects/explosion1.ogg', 50, TRUE)
	QDEL_IN(src, duration)

/obj/effect/temp_visual/ship_miss
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	duration = 5
	layer = OVERMAP_LAYER_EFFECT

/obj/effect/temp_visual/ship_miss/Initialize()
	. = ..()
	playsound(src, 'sound/effects/sparks1.ogg', 30, TRUE)
	QDEL_IN(src, duration)
