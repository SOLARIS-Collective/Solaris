/obj/item/robot_module/Initialize()
	. = ..()
	// [MANKIND-EDIT] Copy the type-level lists so we don't mutate the shared list
	// declared in the type definition (BYOND shares it between all instances).
	basic_modules = basic_modules.Copy()
	emag_modules = emag_modules.Copy()
	if(!(/obj/item/extinguisher in basic_modules))
		basic_modules += /obj/item/extinguisher/mini
	if(!(/obj/item/weldingtool in basic_modules))
		basic_modules += /obj/item/weldingtool/mini
	if(!(/obj/item/gps/cyborg in basic_modules))
		basic_modules += /obj/item/gps/cyborg
	// [MANKIND-FIX] Convert paths to instances WITHOUT mutating the list mid-iteration.
	// The old "+= I / -= i inside for-in" made the index-based iterator skip paths
	// and walk into freshly appended instances, causing
	// "new() called with an object ... instead of the type path itself".
	var/list/converted_basic = list()
	for(var/i in basic_modules)
		converted_basic += ispath(i) ? new i(src) : i
	basic_modules = converted_basic
	var/list/converted_emag = list()
	for(var/i in emag_modules)
		converted_emag += ispath(i) ? new i(src) : i
	emag_modules = converted_emag

/obj/item/gun/energy/kinetic_accelerator/cyborg
	name = "chassis_mounted kinetic accelerator"
	icon_state = "kineticgun_b"
	holds_charge = TRUE
	unique_frequency = TRUE
	max_mod_capacity = 100
