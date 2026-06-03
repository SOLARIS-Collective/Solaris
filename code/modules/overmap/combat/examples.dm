/**
 * # Примеры использования системы космического боя
 *
 * Демонстрация различных сценариев использования системы боя
 */

// ==================== ПРИМЕРЫ КОРАБЛЕЙ С ВООРУЖЕНИЕМ ====================

/**
 * Пример: Фрегат с базовым вооружением
 */
/obj/effect/map_helper/ship_setup/frigate_combat
	name = "Настройка фрегата (боевой)"
	desc = "Добавляет базовое вооружение на фрегат."

/obj/effect/map_helper/ship_setup/frigate_combat/initialize()
	. = ..()

	// Ищем зону корабля
	var/area/ship/ship_area = locate() in get_area(src)
	if(!ship_area || !ship_area.related_ship)
		return

	// Добавляем кинетические пушки
	var/turf/T = locate(x + 2, y, z)
	if(T)
		new /obj/machinery/ship_weapon/kinetic(T)
		T = locate(x + 3, y, z)
		new /obj/machinery/ship_weapon/kinetic(T)

	// Добавляем лазерную пушку
	T = locate(x + 4, y, z)
	if(T)
		new /obj/machinery/ship_weapon/laser(T)

	// Добавляем консоль управления огнем
	T = locate(x + 1, y + 1, z)
	if(T)
		new /obj/machinery/computer/ship/fire_control(T)

	qdel(src)

/**
 * Пример: Крейсер с продвинутым вооружением
 */
/obj/effect/map_helper/ship_setup/cruiser_combat
	name = "Настройка крейсера (боевой)"
	desc = "Добавляет продвинутое вооружение на крейсер."

/obj/effect/map_helper/ship_setup/cruiser_combat/initialize()
	. = ..()

	var/area/ship/ship_area = locate() in get_area(src)
	if(!ship_area || !ship_area.related_ship)
		return

	// Добавляем разнообразное вооружение
	var/turf/T = locate(x + 2, y, z)
	if(T)
		new /obj/machinery/ship_weapon/kinetic(T)
		T = locate(x + 3, y, z)
		new /obj/machinery/ship_weapon/laser(T)
		T = locate(x + 4, y, z)
		new /obj/machinery/ship_weapon/missile(T)
		T = locate(x + 5, y, z)
		new /obj/machinery/ship_weapon/energy(T)

	// Добавляем две консоли управления огнем
	T = locate(x + 1, y + 1, z)
	if(T)
		new /obj/machinery/computer/ship/fire_control(T)
	T = locate(x + 1, y + 2, z)
	if(T)
		new /obj/machinery/computer/ship/fire_control(T)

	qdel(src)

// ==================== ПРИМЕРЫ СЦЕНАРИЕВ БОЯ ====================

/**
 * Демонстрационный скрипт боя
 * Использование: Вызвать в консоли отладки
 */
/datum/combat_demo
	var/datum/overmap/ship/controlled/player_ship
	var/datum/overmap/ship/enemy_ship
	var/demo_active = FALSE

/datum/combat_demo/proc/start_demo()
	if(demo_active)
		return

	demo_active = TRUE

	// Создаем тестовые корабли
	create_test_ships()

	// Настраиваем вооружение
	setup_weapons()

	// Запускаем демонстрацию
	begin_combat_demo()

/datum/combat_demo/proc/create_test_ships()
	// Ищем текущий овермап
	var/datum/overmap/current_overmap = SSovermap.current_overmap
	if(!current_overmap)
		CRASH("Нет активного овермапа для демонстрации")

	// Создаем игровой корабль (используем существующий)
	player_ship = locate(/datum/overmap/ship/controlled) in current_overmap.overmap_ships
	if(!player_ship)
		// Создаем тестовый корабль игрока
		player_ship = new /datum/overmap/ship/controlled(list("x" = 5, "y" = 5), current_overmap)
		player_ship.name = "Демо-Корабль Игрока"
		player_ship.ship_type = SHIP_TYPE_FRIGATE

	// Создаем вражеский корабль
	enemy_ship = new /datum/overmap/ship(list("x" = 10, "y" = 10), current_overmap)
	enemy_ship.name = "Демо-Корабль Противника"
	enemy_ship.ship_type = SHIP_TYPE_FRIGATE
	enemy_ship.faction = SHIP_FACTION_PIRATE

	// Добавляем корабли на овермап
	current_overmap.add_ship(player_ship)
	current_overmap.add_ship(enemy_ship)

/datum/combat_demo/proc/setup_weapons()
	if(!player_ship.shuttle_port)
		return

	// Добавляем оружие на игровой корабль
	var/area/ship_area = get_area(player_ship.shuttle_port)
	var/turf/weapon_turf = locate(2, 2, ship_area.z)

	if(weapon_turf)
		// Кинетическая пушка
		new /obj/machinery/ship_weapon/kinetic(weapon_turf)

		// Лазерная пушка
		weapon_turf = locate(3, 2, ship_area.z)
		new /obj/machinery/ship_weapon/laser(weapon_turf)

		// Консоль управления огнем
		weapon_turf = locate(1, 1, ship_area.z)
		new /obj/machinery/computer/ship/fire_control(weapon_turf)

/datum/combat_demo/proc/begin_combat_demo()
	if(!player_ship || !enemy_ship)
		return

	// Шаг 1: Захват цели
	to_chat(world, span_boldnotice("=== ДЕМОНСТРАЦИЯ СИСТЕМЫ БОЯ ==="))
	to_chat(world, span_info("Шаг 1: Захват цели противника"))

	// Даем время для захвата
	addtimer(CALLBACK(src, PROC_REF(step2_fire_weapons)), 5 SECONDS)

/datum/combat_demo/proc/step2_fire_weapons()
	if(!player_ship.combat_system)
		return

	to_chat(world, span_info("Шаг 2: Открытие огня"))

	// Захватываем цель
	player_ship.combat_system.acquire_target(enemy_ship)

	// Ждем захвата
	addtimer(CALLBACK(src, PROC_REF(step3_process_hit)), 8 SECONDS)

/datum/combat_demo/proc/step3_process_hit()
	to_chat(world, span_info("Шаг 3: Обработка попадания"))

	// Имитируем попадание
	if(enemy_ship)
		enemy_ship.take_damage(25, BRUTE, player_ship)

	// Показываем урон
	addtimer(CALLBACK(src, PROC_REF(step4_show_damage)), 3 SECONDS)

/datum/combat_demo/proc/step4_show_damage()
	to_chat(world, span_info("Шаг 4: Отображение повреждений"))

	if(enemy_ship)
		to_chat(world, span_info("Здоровье противника: [enemy_ship.hull_health]/[enemy_ship.max_hull_health]"))
		to_chat(world, span_info("Щиты противника: [enemy_ship.shield_strength]/[enemy_ship.max_shield_strength]"))

	// Завершаем демонстрацию
	addtimer(CALLBACK(src, PROC_REF(end_demo)), 5 SECONDS)

/datum/combat_demo/proc/end_demo()
	to_chat(world, span_boldnotice("Демонстрация завершена!"))
	demo_active = FALSE

	// Очищаем тестовые корабли
	if(enemy_ship && enemy_ship.current_overmap)
		enemy_ship.current_overmap.remove_ship(enemy_ship)
		qdel(enemy_ship)

// ==================== КОМАНДЫ ОТЛАДКИ ====================

/**
 * Команда для запуска демонстрации
 */
/client/proc/start_combat_demo()
	set name = "Запустить демонстрацию боя"
	set category = "Debug"

	var/datum/combat_demo/demo = new()
	demo.start_demo()

	message_admins("[key_name_admin(usr)] запустил демонстрацию системы боя.")
	log_admin("[key_name(usr)] запустил демонстрацию системы боя.")

/**
 * Команда для создания тестового корабля
 */
/client/proc/create_test_combat_ship()
	set name = "Создать тестовый боевой корабль"
	set category = "Debug"

	var/datum/overmap/current_overmap = SSovermap.current_overmap
	if(!current_overmap)
		to_chat(usr, span_warning("Нет активного овермапа!"))
		return

	// Создаем корабль
	var/datum/overmap/ship/controlled/test_ship = new(list("x" = 5, "y" = 5), current_overmap)
	test_ship.name = "Тестовый Боевой Корабль"
	test_ship.ship_type = SHIP_TYPE_FRIGATE

	// Добавляем на овермап
	current_overmap.add_ship(test_ship)

	// Создаем зону корабля (упрощенно)
	var/area/ship/test_area = new /area/ship/test_combat()
	test_area.related_ship = test_ship

	to_chat(usr, span_notice("Создан тестовый боевой корабль: [test_ship.name]"))
	message_admins("[key_name_admin(usr)] создал тестовый боевой корабль.")
	log_admin("[key_name(usr)] создал тестовый боевой корабль.")

/**
 * Команда для добавления оружия на корабль
 */
/client/proc/add_weapons_to_ship()
	set name = "Добавить оружие на корабль"
	set category = "Debug"

	var/list/ship_list = list()
	for(var/datum/overmap/ship/controlled/S in SSovermap.controlled_ships)
		ship_list[S.name] = S

	if(!length(ship_list))
		to_chat(usr, span_warning("Нет управляемых кораблей!"))
		return

	var/ship_name = input(usr, "Выберите корабль:", "Добавление оружия") as null|anything in ship_list
	if(!ship_name)
		return

	var/datum/overmap/ship/controlled/target_ship = ship_list[ship_name]
	if(!target_ship || !target_ship.shuttle_port)
		to_chat(usr, span_warning("Корабль не найден или не имеет зоны!"))
		return

	// Добавляем оружие в зону корабля
	var/area/ship_area = get_area(target_ship.shuttle_port)
	var/turf/center_turf = locate(
		round((ship_area.x + ship_area.x2) / 2),
		round((ship_area.y + ship_area.y2) / 2),
		ship_area.z
	)

	if(center_turf)
		// Добавляем разные типы оружия
		new /obj/machinery/ship_weapon/kinetic(center_turf)
		new /obj/machinery/ship_weapon/laser(locate(center_turf.x + 1, center_turf.y, center_turf.z))
		new /obj/machinery/computer/ship/fire_control(locate(center_turf.x, center_turf.y + 1, center_turf.z))

		to_chat(usr, span_notice("Оружие добавлено на корабль [target_ship.name]!"))
		message_admins("[key_name_admin(usr)] добавил оружие на корабль [target_ship.name].")
		log_admin("[key_name(usr)] добавил оружие на корабль [target_ship.name].")

// ==================== ТЕСТОВЫЕ ЗОНЫ ====================

/area/ship/test_combat
	name = "Тестовый Боевой Корабль"
	icon_state = "bridge"
	requires_power = TRUE

// ==================== АДМИН-ВЕРБЫ ====================

/datum/admins/proc/toggle_combat_debug()
	set name = "Переключить отладку боя"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	// Здесь можно добавить переключение различных режимов отладки
	to_chat(usr, span_notice("Режим отладки боя переключен."))
	message_admins("[key_name_admin(usr)] переключил режим отладки боя.")

// ==================== ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ В КОДЕ ====================

/**
 * Пример использования системы боя в скрипте события
 */
/datum/overmap_event/pirate_attack
	name = "Пиратская атака"
	description = "Пиратский корабль атакует ваш корабль!"
	minimum_time = 10 MINUTES
	maximum_time = 30 MINUTES

	var/datum/overmap/ship/pirate_ship

/datum/overmap_event/pirate_attack/start()
	. = ..()

	// Создаем пиратский корабль
	var/datum/overmap/current_overmap = SSovermap.current_overmap
	if(!current_overmap)
		return

	pirate_ship = new /datum/overmap/ship(list("x" = rand(1, 20), "y" = rand(1, 20)), current_overmap)
	pirate_ship.name = "Пиратский Корабль"
	pirate_ship.ship_type = SHIP_TYPE_FRIGATE
	pirate_ship.faction = SHIP_FACTION_PIRATE

	current_overmap.add_ship(pirate_ship)

	// Настраиваем вооружение пиратов
	setup_pirate_weapons()

	// Начинаем атаку
	begin_attack()

/datum/overmap_event/pirate_attack/proc/setup_pirate_weapons()
	// В реальной реализации здесь бы создавалось оружие на пиратском корабле
	// Для примера просто устанавливаем параметры
	pirate_ship.max_hull_health = 80
	pirate_ship.hull_health = 80
	pirate_ship.max_shield_strength = 30
	pirate_ship.shield_strength = 30

/datum/overmap_event/pirate_attack/proc/begin_attack()
	// Ищем игровой корабль для атаки
	var/datum/overmap/ship/controlled/player_ship
	for(var/datum/overmap/ship/controlled/S in SSovermap.controlled_ships)
		if(S.current_overmap == pirate_ship.current_overmap)
			player_ship = S
			break

	if(!player_ship)
		return

	// Пираты атакуют игрока
	// В реальной реализации здесь бы была AI логика атаки
	to_chat(world, span_userdanger("Пиратский корабль атакует [player_ship.name]!"))

	// Запускаем периодические атаки
	START_PROCESSING(SSprocessing, src)

/datum/overmap_event/pirate_attack/process()
	if(!pirate_ship || pirate_ship.destroyed)
		stop()
		return

	// Ищем цель для атаки
	var/datum/overmap/ship/controlled/target
	for(var/datum/overmap/ship/controlled/S in SSovermap.controlled_ships)
		if(S.current_overmap == pirate_ship.current_overmap && !S.destroyed)
			target = S
			break

	if(!target)
		return

	// Имитируем атаку (в реальной реализации здесь бы была полноценная система боя)
	if(prob(30)) // 30% шанс атаки каждый тик
		var/damage = rand(10, 25)
		target.take_damage(damage, BRUTE, pirate_ship)

/datum/overmap_event/pirate_attack/stop()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

	if(pirate_ship && pirate_ship.current_overmap)
		pirate_ship.current_overmap.remove_ship(pirate_ship)
		qdel(pirate_ship)

	pirate_ship = null

	to_chat(world, span_green("Пиратская атака прекращена."))
