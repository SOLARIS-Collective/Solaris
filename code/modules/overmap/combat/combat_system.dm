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

/datum/ship_combat_system/New(datum/overmap/ship/controlled/ship_ref)
	. = ..()
	ship = ship_ref
	initialize_weapons()
	START_PROCESSING(SSprocessing, src)

/datum/ship_combat_system/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	weapons.Cut()
	target = null
	control_console = null
	active_projectiles.Cut()
	return ..()

/**
 * Инициализация вооружения корабля
 * Ищет все машинерии вооружения на корабле
 */
/datum/ship_combat_system/proc/initialize_weapons()
	return

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
	target_lock_status = SHIP_TARGET_LOCK_ACQUIRING
	target_lock_start_time = world.time

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
	if(!weapon || !weapon.can_fire())
		return FALSE

	if(target_lock_status != SHIP_TARGET_LOCK_LOCKED)
		return FALSE

	if(!target || QDELETED(target))
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

	// Оповещаем консоль
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

	if(actual_hit && projectile.target && !QDELETED(projectile.target))
		// Наносим урон цели
		var/damage = projectile.weapon.damage * damage_multiplier
		projectile.target.take_damage(damage, projectile.weapon.damage_type)

		// Оповещаем о попадании
		broadcast_hit_notification(projectile, damage)

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
 * Основной процесс системы боя
 */
/datum/ship_combat_system/process()
	if(QDELETED(src) || QDELETED(ship))
		return

	// Обрабатываем захват цели
	process_target_lock()

	// Обновляем статус вооружения
	for(var/obj/machinery/ship_weapon/weapon in weapons)
		if(QDELETED(weapon))
			weapons -= weapon
			continue
		weapon.process()

	// Проверяем активные снаряды
	for(var/obj/projectile/ship_projectile/projectile in active_projectiles)
		if(QDELETED(projectile))
			active_projectiles -= projectile
			continue
		projectile.process_flight()

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
