/*
* Transponder - 'going dark' mechanics.
* When enabled and powered, the transponder projects a jamming field over the ship,
* hiding it from other vessels' Radar and ARPA. The field consumes power.
*/
/obj/machinery/computer/transponder
	name = "Transponder"
	desc = "Projects a jamming field over the ship that blocks scanning waves. Consumes a lot of power while active."
	icon = 'icons/obj/machines/transponder.dmi'
	icon_state = "transponder"
	icon_screen = "transponder-screen"
	icon_keyboard = null
	circuit = /obj/item/circuitboard/computer/shuttle
	light_color = LIGHT_COLOR_GREEN
	clicksound = null

	/// The ship we reside on for ease of access
	var/datum/overmap/ship/controlled/current_ship

	/// Whether the jamming field is currently projected.
	/// The field only works while the machine is powered.
	var/enabled = TRUE

	/// Power draw while the field is active. (Watts)
	active_power_usage = ACTIVE_DRAW_EXTREME

/obj/machinery/computer/transponder/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	current_ship = port.current_ship
	if(current_ship)
		current_ship.ship_modules[SHIPMODULE_TRANSPONDER] = src
		current_ship.refresh_transponder_state()

/obj/machinery/computer/transponder/Destroy()
	if(current_ship)
		LAZYREMOVE(current_ship.ship_modules, src)
		current_ship.refresh_transponder_state()
		current_ship = null
	return ..()

/obj/machinery/computer/transponder/process()
	if(!current_ship)
		return PROCESS_KILL
	// Re-evaluate the field whenever power state changes.
	current_ship.refresh_transponder_state()

/obj/machinery/computer/transponder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Transponder", name)
		ui.open()

/obj/machinery/computer/transponder/ui_data(mob/user)
	. = list(
		"enabled" = enabled,
		"powered" = powered(),
		"active" = current_ship ? current_ship.transponder_active : FALSE,
		"power_usage" = active_power_usage,
	)

/obj/machinery/computer/transponder/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			enabled = !enabled
			current_ship?.refresh_transponder_state()
			return TRUE
		if("reconnect")
			current_ship?.refresh_transponder_state()
			return TRUE