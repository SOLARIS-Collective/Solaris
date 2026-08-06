/// Компонент для отслеживания близости кораблей на овермапе.
/// Реагирует на COMSIG_OVERMAP_MOVED и вызывает check_proximity()
/// только при перемещении корабля, а не каждый тик подсистемы.
/datum/component/overmap_proximity
	/// Через сколько перемещений пересчитывать CPA (3 = каждый третий мув)
	var/scan_interval = 3
	/// Счётчик перемещений для прореживания
	var/scan_counter = 0

/datum/component/overmap_proximity/proc/on_ship_moved(source, old_x, old_y)
	SIGNAL_HANDLER
	var/datum/overmap/ship/ship_source = source
	scan_counter++
	if(scan_counter < scan_interval)
		return
	scan_counter = 0
	INVOKE_ASYNC(src, PROC_REF(do_proximity_scan), ship_source)

/// Выполняется асинхронно, не блокирует анимацию движения
/datum/component/overmap_proximity/proc/do_proximity_scan(source)
	var/datum/overmap/ship/ship_source = source
	ship_source.check_proximity()

/datum/component/overmap_proximity/Initialize(scan_interval = 3)
	. = ..()
	if(!istype(parent, /datum/overmap/ship))
		return COMPONENT_INCOMPATIBLE
	src.scan_interval = scan_interval
	RegisterSignal(parent, COMSIG_OVERMAP_MOVED, PROC_REF(on_ship_moved))
