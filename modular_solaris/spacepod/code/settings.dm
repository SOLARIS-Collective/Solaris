// SOLARIS-SPACEPOD: адаптация settings.dm из PR 2039
// Пути иконок переведены с mod_celadon/_storge_icons на modular_solaris/_storage_icons

/mob
	///List of datums that this has which make use of MouseMove()
	var/list/mousemove_intercept_objects

//Please don't roast me too hard
/client/MouseMove(object, location, control, params)
	mouseParams = params
	mouse_location_ref = WEAKREF(location)
	mouse_object_ref = WEAKREF(object)
	mouseControlObject = control
	if(mob && LAZYLEN(mob.mousemove_intercept_objects))
		for(var/datum/D in mob.mousemove_intercept_objects)
			D.onMouseMove(object, location, control, params)
	..()

/datum/proc/onMouseMove(object, location, control, params)
	return
