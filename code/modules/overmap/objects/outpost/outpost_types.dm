/*
	Map templates
*/

/datum/map_template/outpost
	// Necessary to stop planetary outposts from having space underneath all their turfs.
	// They were being "placed on top", so instead of their baseturf, there was just space underneath.
	// (Interestingly, this is much less of a problem for ruins: PlaceOnTop ignores the top closed turf in the baseturfs stack
	// of the new tile, meaning that placing plating on top of a wall doesn't result in a wall underneath the plating.)
	should_place_on_top = FALSE
	// [SOLARIS-ADD] - SHIP_LOAD_LAG
	/// Cache parsed map for outposts - loaded once at roundstart, but hangars reuse the same pattern
	keep_cached_map = TRUE
	// [/SOLARIS-ADD]
	var/outpost_name = "Fallback Outpost"
	var/outpost_administrator = "Fallback Administration"

/datum/map_template/outpost/New()
	. = ..(path = "_maps/outpost/[name].dmm")


/datum/map_template/outpost/hangar
	// [SOLARIS-ADD] - SHIP_LOAD_LAG - Тут итак ангары а под ними космос
	should_place_on_top = TRUE
	var/dock_width
	var/dock_height

/datum/map_template/outpost/elevator_test
	name = "elevator_test"

/datum/map_template/outpost/elevator_indie
	name = "elevator_indie"

/datum/map_template/outpost/elevator_ice
	name = "elevator_ice"

/datum/map_template/outpost/elevator_rock
	name = "elevator_rock"

/datum/map_template/outpost/elevator_clip
	name = "elevator_clip"

/datum/map_template/outpost/elevator_cybersun
	name = "elevator_cybersun"

/*
	Independent Space Outpost //creative name!
*/
/datum/map_template/outpost/indie_space
	name = "indie_space"
	outpost_name = "Installation Trifuge"
	outpost_administrator = "Caldwell"

/datum/map_template/outpost/hangar/indie_space_20x20
	name = "hangar/indie_space_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_40x20
	name = "hangar/indie_space_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_40x40
	name = "hangar/indie_space_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/indie_space_56x20
	name = "hangar/indie_space_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_56x40
	name = "hangar/indie_space_56x40"
	dock_width = 56
	dock_height = 40

/*
	Nanotrasen Ice Planet
*/
/datum/map_template/outpost/nanotrasen_ice
	name = "nanotrasen_ice"
	outpost_name = "Yebiri Sipili"
	outpost_administrator = "Nanotrasen Authorities"

/datum/map_template/outpost/hangar/nt_ice_20x20
	name = "hangar/nt_ice_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/nt_ice_40x20
	name = "hangar/nt_ice_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/nt_ice_40x40
	name = "hangar/nt_ice_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/nt_ice_56x20
	name = "hangar/nt_ice_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/nt_ice_56x40
	name = "hangar/nt_ice_56x40"
	dock_width = 56
	dock_height = 40

/*
	Independent Rock Planet //ROCK AND STONE!
*/
/datum/map_template/outpost/ngr_rock
	name = "ngr_rock"
	outpost_name = "Agni Trading Post"
	outpost_administrator = "The NGR Bureau Of Development"

/datum/map_template/outpost/hangar/ngr_rock_20x20
	name = "hangar/ngr_rock_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/ngr_rock_40x20
	name = "hangar/ngr_rock_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/ngr_rock_40x40
	name = "hangar/ngr_rock_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/ngr_rock_56x20
	name = "hangar/ngr_rock_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/ngr_rock_56x40
	name = "hangar/ngr_rock_56x40"
	dock_width = 56
	dock_height = 40

/*
	CLIP Ocean outpost //I really hated ghost leviathans, man
*/
/datum/map_template/outpost/clip_ocean
	name = "clip_ocean"
	outpost_name = "Arrowsong Refueling Platform"
	outpost_administrator = "The Arrowsong Executive Council"

/datum/map_template/outpost/hangar/clip_ocean_20x20
	name = "hangar/clip_ocean_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/clip_ocean_40x20
	name = "hangar/clip_ocean_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/clip_ocean_40x40
	name = "hangar/clip_ocean_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/clip_ocean_56x20
	name = "hangar/clip_ocean_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/clip_ocean_56x40
	name = "hangar/clip_ocean_56x40"
	dock_width = 56
	dock_height = 40

//Cybersun Gas Giant
/datum/map_template/outpost/cybersun_gas_giant
	name = "cybersun_gas_giant"
	outpost_name = "Thousand Eyes Perch"
	outpost_administrator = "Cybersun Frontier Developments"

/datum/map_template/outpost/hangar/cybersun_gas_giant_20x20
	name = "hangar/cybersun_gas_giant_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/cybersun_gas_giant_40x20
	name = "hangar/cybersun_gas_giant_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/cybersun_gas_giant_40x40
	name = "hangar/cybersun_gas_giant_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/cybersun_gas_giant_56x20
	name = "hangar/cybersun_gas_giant_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/cybersun_gas_giant_56x40
	name = "hangar/cybersun_gas_giant_56x40"
	dock_width = 56
	dock_height = 40
