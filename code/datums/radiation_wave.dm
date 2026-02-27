/datum/radiation_wave
	/// The thing that spawned this radiation wave
	var/source
	/// The center of the wave
	var/turf/master_turf
	/// How far we've moved
	var/steps=0
	/// How strong it was originaly
	var/intensity
	/// How much contaminated material it still has
	var/remaining_contam
	/// Higher than 1 makes it drop off faster, 0.5 makes it drop off half etc
	var/range_modifier
	/// The direction of movement
	var/move_dir
	/// The directions to the side of the wave, stored for easy looping
	var/list/__dirs
	/// Whether or not this radiation wave can create contaminated objects
	var/can_contaminate

/datum/radiation_wave/New(atom/_source, dir, _intensity=0, _range_modifier=RAD_DISTANCE_COEFFICIENT, _can_contaminate=TRUE)

	source = "[_source] \[[REF(_source)]\]"

	master_turf = get_turf(_source)

	move_dir = dir
	__dirs = list()
	__dirs+=turn(dir, 90)
	__dirs+=turn(dir, -90)

	intensity = _intensity
	remaining_contam = intensity
	range_modifier = _range_modifier
	can_contaminate = _can_contaminate

	START_PROCESSING(SSradiation, src)

/datum/radiation_wave/Destroy()
	. = QDEL_HINT_IWILLGC
	STOP_PROCESSING(SSradiation, src)
	..()

// When somebody figured out how to harness the power of the sun for infinite fusion rads,
// we had problems with radiation waves travelling across virtual zs. If a radiation wave
// strikes a null turf (i.e. a z-level edge) or a rad_fullblocker turf (typically a virtual z edge)
// propagation in that direction is stopped.
/datum/radiation_wave/proc/is_valid_rad_turf(turf/r_turf)
	return r_turf && !r_turf.rad_fullblocker

/datum/radiation_wave/process(seconds_per_tick)
	master_turf = get_step(master_turf, move_dir)
	if(!is_valid_rad_turf(master_turf))
		qdel(src)
		return
	steps += seconds_per_tick

	var/strength
	if(steps>1)
		strength = INVERSE_SQUARE(intensity, max(range_modifier*steps, 1), 1)
	else
		strength = intensity

	if(strength<RAD_BACKGROUND_RADIATION)
		qdel(src)
		return

	// PENTEST ADDITION - RADIATION REFACTOR - START
	var/width = steps
	var/cmove_dir = move_dir
	if(cmove_dir == NORTH || cmove_dir == SOUTH)
		width--
	width = 1+(2*width)

	var/list/atoms_and_insulation = get_rad_atoms(width)
	var/list/atoms = atoms_and_insulation[1]

	if(radiate(atoms, FLOOR(min(strength,remaining_contam), 1)))
		//oof ow ouch
		remaining_contam = max(0,remaining_contam-((min(strength,remaining_contam)-RAD_MINIMUM_CONTAMINATION) * RAD_CONTAMINATION_STR_COEFFICIENT))

	var/insulation_tally = atoms_and_insulation[2]
	if(insulation_tally)
		var/insulation_total = atoms_and_insulation[3]
		var/average_insulation = insulation_total / insulation_tally
		// Determines how much the width dilutes the obstacle's effect.
		// Using the square root of width (width ** 0.5) prevents the obstacles from becoming irrelevant at long distances.
		var/spread_factor = max(1, width ** 0.5)

		// The exponent calculates the effective "thickness" of the wall relative to the wave size.
		var/obstacle_density = insulation_tally / spread_factor

		// Apply the reduction.
		intensity *= (average_insulation ** obstacle_density)

/datum/radiation_wave/proc/get_rad_atoms(width = 1)
	var/list/atoms = list()
	var/distance = steps
	var/cmove_dir = move_dir
	var/cmaster_turf = master_turf
	var/insulation_total = 0
	var/insulation_tally = 0

	if(cmove_dir == NORTH || cmove_dir == SOUTH)
		distance-- //otherwise corners overlap

	var/list/master_turf_contents = get_rad_insulation_contents(cmaster_turf, src, width)
	atoms += master_turf_contents[1]
	var/best_insulation = master_turf_contents[2]
	if(best_insulation != RAD_NO_INSULATION)
		insulation_total += best_insulation
		insulation_tally++

	var/turf/place
	var/list/place_turf_contents
	for(var/dir in __dirs) //There should be just 2 dirs in here, left and right of the direction of movement
		place = cmaster_turf
		for(var/i in 1 to distance)
			place = get_step(place, dir)
			if(!is_valid_rad_turf(place))
				break // the break here is important. if a rad wave was travelling parallel to a virtual z edge, and the loop didn't break, it could "clip through"
			place_turf_contents = get_rad_insulation_contents(place, src, width)
			atoms += place_turf_contents[1]
			best_insulation = place_turf_contents[2]
			if(best_insulation != RAD_NO_INSULATION)
				insulation_total += place_turf_contents[2]
				insulation_tally++

	return list(atoms, insulation_tally, insulation_total)
	// PENTEST RADIATION REFACTOR - END

/datum/radiation_wave/proc/radiate(list/atoms, strength)
	var/can_contam = strength >= RAD_MINIMUM_CONTAMINATION
	var/contamination_strength = (strength-RAD_MINIMUM_CONTAMINATION) * RAD_CONTAMINATION_STR_COEFFICIENT
	contamination_strength = max(contamination_strength, RAD_BACKGROUND_RADIATION)
	var/list/contam_atoms = list()
	for(var/k in 1 to atoms.len)
		var/atom/thing = atoms[k]
		if(!thing)
			continue
		thing.rad_act(strength)

		// This list should only be for types which don't get contaminated but you want to look in their contents
		// If you don't want to look in their contents and you don't want to rad_act them:
		// modify the ignored_things list in __HELPERS/radiation.dm instead
		var/static/list/blacklisted = typecacheof(list(
			/turf,
			/obj/structure/cable,
			/obj/machinery/atmospherics,
			/obj/item/ammo_casing,
			/obj/item/implant,
			/obj/singularity
			))
		if(!can_contaminate || !can_contam || blacklisted[thing.type])
			continue
		if(thing.flags_1 & RAD_NO_CONTAMINATE_1 || SEND_SIGNAL(thing, COMSIG_ATOM_RAD_CONTAMINATING, strength) & COMPONENT_BLOCK_CONTAMINATION)
			continue

		if(contamination_strength > remaining_contam)
			contamination_strength = remaining_contam
		if(SEND_SIGNAL(thing, COMSIG_ATOM_RAD_CONTAMINATING, strength) & COMPONENT_BLOCK_CONTAMINATION)
			continue
		if(thing.flags_1 & RAD_NO_CONTAMINATE_1 || SEND_SIGNAL(thing, COMSIG_ATOM_RAD_CONTAMINATING, strength) & COMPONENT_BLOCK_CONTAMINATION)
			continue
		contam_atoms += thing
	var/did_contam = 0
	if(can_contam)
		var/num_targets = contam_atoms.len		//WS Edit Begin - Fix radiation runtime
		if(num_targets)			// Check that theres something to contaminate
			var/rad_strength = ((strength-RAD_MINIMUM_CONTAMINATION) * RAD_CONTAMINATION_STR_COEFFICIENT)/ num_targets
			for(var/k in 1 to num_targets)
				var/atom/thing = contam_atoms[k]
				thing.AddComponent(/datum/component/radioactive, rad_strength, source)
				did_contam = 1			//WS Edit End
	return did_contam
