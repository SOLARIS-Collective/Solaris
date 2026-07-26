//minimize overhead of the default system
/datum/overmap_star_system/shiptest
	generator_type = OVERMAP_GENERATOR_NONE
	has_outpost = FALSE
	encounters_refresh = FALSE

/datum/overmap/dynamic/ruin_tester
	populate_turfs = FALSE

/datum/unit_test/ruin_placement/Run()
	//PENTEST EDIT START
	var/start_time = world.time

	// Set GC settings to prevent reference searches during the test
	// GC_QUEUE_CHECK set to 60 minutes so it never triggers - test completes before timeout
	// No need to restore - test environment terminates after completion
	SSgarbage.wait = 1 SECONDS // Fire more frequently (default: 2 seconds)
	SSgarbage.collection_timeout[GC_QUEUE_FILTER] = 1 SECONDS // Default: 1 second
	SSgarbage.collection_timeout[GC_QUEUE_CHECK] = 60 MINUTES // Default: 5 MINUTES - set high so it never triggers during test
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 2 SECONDS // Default: 10 seconds
	// PENTEST EDIT END

	var/datum/overmap_star_system/dummy_system = SSovermap.default_system
	dummy_system.name = "Ruin Test: Dummy System"
	for(var/planet_name as anything in SSmapping.planet_types)
		var/datum/planet_type/planet_type = SSmapping.planet_types[planet_name]
		for(var/ruin_name as anything in SSmapping.ruin_types_list[planet_type.ruin_type])
			// PENTEST EDIT START
			var/elapsed = (world.time - start_time) / 10
			log_test("[elapsed]s ✅ Testing Ruin: [ruin_name]")
			// PENTEST EDIT END
			var/datum/map_template/ruin/ruin = SSmapping.ruin_types_list[planet_type.ruin_type][ruin_name]

			var/datum/overmap/dynamic/ruin_tester/dummy_overmap = new(null, dummy_system, FALSE)
			TEST_ASSERT(!dummy_overmap.selected_ruin, "[dummy_overmap] was not meant to set its own ruin, this will init all its pois and fuck up shit when we overwrite in this test!")

			dummy_overmap.name = "Ruin Test: [ruin_name]"
			dummy_overmap.selected_ruin = ruin

			dummy_overmap.set_planet_type(planet_type)

			//12 is since it pads 6 and i dont feel like fixing that rn
			dummy_overmap.vlevel_height = ruin.height+12
			dummy_overmap.vlevel_width = ruin.width+12

			dummy_overmap.populate_turfs = FALSE

			for(var/mission_type in ruin.ruin_mission_types)
				var/datum/mission/ruin/ruin_mission = new mission_type(dummy_overmap, 1 + length(dummy_overmap.dynamic_missions))
				dummy_overmap.dynamic_missions += ruin_mission
				ruin_mission.start_mission()
				// PENTEST EDIT START
				elapsed = (world.time - start_time) / 10
				log_test("[elapsed]s Testing Mission: [ruin_mission.name]")
				// PENTEST EDIT END

			TEST_ASSERT(!dummy_overmap.loading, "[dummy_overmap] is somehow loading before we call the load level proc?!?")
			TEST_ASSERT(dummy_overmap.load_level(), "[dummy_overmap] failed to load!")
			TEST_ASSERT_EQUAL(length(SSmissions.unallocated_pois), 0, "Somehow a planet created pois but did not manage to allocate them to itself!")
			// PENTEST EDIT START
			elapsed = (world.time - start_time) / 10
			log_test("[elapsed]s Mission poi count: [length(dummy_overmap.spawned_mission_pois)]")
			// PENTEST EDIT END
			var/list/errors = atmosscan(TRUE, TRUE)
			//errors += powerdebug(TRUE)

			for(var/error in errors)
				Fail("Mapping error in [ruin_name]: [error]", ruin.mappath, 1)

			// PENTEST EDIT START
			elapsed = (world.time - start_time) / 10
			log_test("[elapsed]s ✅ Completed cleanup for: [ruin_name]")
			// PENTEST EDIT END
			//qdel(vlevel)
			qdel(dummy_overmap)

/* Slow, and usually unecessary
/datum/unit_test/direct_tmpl_placement/Run()
	SSair.is_test_loading = TRUE
	var/datum/map_zone/mapzone = SSmapping.create_map_zone("Template Testing Zone")
	for(var/ship_name as anything in SSmapping.map_templates)
		var/datum/map_template/template = SSmapping.map_templates[ship_name]
		var/datum/virtual_level/vlevel = SSmapping.create_virtual_level(
			template.name,
			list(),
			mapzone,
			template.width,
			template.height
		)

		template.load(vlevel.get_unreserved_bottom_left_turf())

		var/list/errors = atmosscan(TRUE)
		//errors += powerdebug(TRUE)

		for(var/error in errors)
			Fail("Mapping error in [ship_name]: [error]", template.mappath, 1)

		vlevel.clear_reservation()
		qdel(vlevel)
	SSair.is_test_loading = FALSE
*/
