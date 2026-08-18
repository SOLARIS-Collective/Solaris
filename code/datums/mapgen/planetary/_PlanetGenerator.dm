//the random offset applied to square coordinates, causes intermingling at biome borders
#define BIOME_RANDOM_SQUARE_DRIFT 1

/datum/map_generator/planet_generator
	/// Higher values of this variable result in larger biomes.
	var/perlin_zoom = 65

	/// If a turf's perlin-calculated "height" is above this value, a cave biome will be used to generate it.
	/// For best results, avoid values around 0.5; basic perlin noise can create noticeable straight-line artifacts
	/// around the midpoint value. A value of 1 or greater disables caves entirely.
	var/mountain_height = 0.85

	/// Chance for a cell in the cavegen cellular automaton to start closed
	var/initial_closed_chance = 45
	/// # of steps that the cellular automaton is run for
	var/smoothing_iterations = 20
	/// If an open (dead) cell has greater than this many neighbors, it become closed (alive).
	var/birth_limit = 4
	/// If a closed (alive) cell has fewer than this many neighbors, it will become open (dead).
	var/death_limit = 3

	/// The type of the area that will be used for all non-cave biomes.
	var/area/primary_area_type
	/// The area instance that will be used for all non-cave biomes.
	var/area/primary_area

	/// The type of the area that will be used for all cave biomes.
	var/area/cave_area_type = /area/overmap_encounter/planetoid/cave
	/// The area instance that will be used for all cave biomes.
	var/area/cave_area

	/// Effectively a 2D array of biomes, organized by heat categories, then humidity.
	/// Note that the heat categories are NOT all equal-size.
	var/list/biome_table

	/// A 2D array of "cave" biomes that generate at "heights" above the mountain_height variable.
	/// Like normal biomes, they are organized by heat, then humidity; however, they do NOT
	/// use the same heat categories as the normal biome table does.
	var/list/cave_biome_table

	// temporary internal vars for the perlin noise
	var/height_seed
	var/humidity_seed
	var/heat_seed

	// temporary internal var used during planet generation to store the output of the cave-automaton
	var/string_gen

	// temporary internal lists, storing created features / mobs to speedup spawning
	// it takes too long to look at nearby turfs, so we just store them and then
	// iterate through the list when we want to see if there is anything nearby.
	// yes, this does mean that creatures / features can spawn adjacent to ones mapped into ruins
	// this is unfortunate, but mostly irrelevant
	var/list/created_features
	var/list/created_mobs

	// Temporary associative list matching generated turfs to biomes. Used to get
	// a turf's biome for populating it without having to recalculate (which is impossible, due to drift)
	var/list/turf_biome_cache

	// [MANKIND-ADD] - MANKIND_OPT_PREGEN_SEEDS - Пред-посчитанная раскладка биомов.
	// Плоский список индексов (y-1)*grid_width+x по относительным координатам 1..grid_width x 1..grid_height.
	// Считается отдельной фазой (можно заранее, до стыковки), чтобы материализация турфов
	// не дёргала rust-g и rand() на каждый тайл.
	var/list/precomputed_grid
	/// Смещение сетки (левый нижний угол блока генерации) для индексации по турфу
	var/grid_offset_x = 0
	var/grid_offset_y = 0
	/// Ширина сетки в клетках
	var/grid_width = 0
	// [/MANKIND-ADD]


/datum/map_generator/planet_generator/New(...)
	// initialize the perlin seeds
	height_seed = rand(0, 50000)
	humidity_seed = rand(0, 50000)
	heat_seed = rand(0, 50000)
	if(mountain_height < 1)
		//Generate the raw CA data
		// This generates a CA for the entire game map, which is sort of inefficient, but not too big a deal.
		string_gen = rustg_cnoise_generate("[initial_closed_chance]", "[smoothing_iterations]", "[birth_limit]", "[death_limit]", "[world.maxx]", "[world.maxy]")

	primary_area = GLOB.areas_by_type[primary_area_type] || new primary_area_type
	cave_area = GLOB.areas_by_type[cave_area_type] || new cave_area_type

	turf_biome_cache = list()
	return ..()

/datum/map_generator/planet_generator/generate_turf(turf/gen_turf, changeturf_flags)
	var/area/A = get_area(gen_turf)
	if(!(A.area_flags & CAVES_ALLOWED))
		return

	var/datum/biome/turf_biome = get_biome(gen_turf)

	// using istype() here suuuuucks, i'm sorry.
	var/area/used_area = istype(turf_biome, /datum/biome/cave) ? cave_area : primary_area
	turf_biome.generate_turf(gen_turf, used_area, changeturf_flags, string_gen)

/datum/map_generator/planet_generator/populate_turfs()
	created_features = list()
	created_mobs = list()
	. = ..()
	// clear the lists, so we don't get harddels
	created_features = null
	created_mobs = null

/datum/map_generator/planet_generator/populate_turf(turf/gen_turf)
	var/area/A = gen_turf.loc
	if(!(A.area_flags & CAVES_ALLOWED))
		return

	var/datum/biome/turf_biome = get_biome(gen_turf)
	turf_biome.populate_turf(gen_turf, created_features, created_mobs)

/// Checks the turf biome cache for the biome of the passed turf; if none is found, it is generated.
/datum/map_generator/planet_generator/proc/get_biome(turf/a_turf)
	// if it's in the turf biome cache, just return that
	if(turf_biome_cache[a_turf])
		return turf_biome_cache[a_turf]

	// [MANKIND-ADD] - MANKIND_OPT_PREGEN_SEEDS - если раскладка пред-посчитана, читаем из сетки
	if(length(precomputed_grid))
		var/grid_x = a_turf.x - grid_offset_x + 1
		var/grid_y = a_turf.y - grid_offset_y + 1
		if(grid_x >= 1 && grid_x <= grid_width && grid_y >= 1 && grid_y <= length(precomputed_grid) / grid_width)
			var/datum/biome/grid_biome = precomputed_grid[(grid_y - 1) * grid_width + grid_x]
			turf_biome_cache[a_turf] = grid_biome
			return grid_biome
	// [/MANKIND-ADD]

	turf_biome_cache[a_turf] = compute_biome_at(a_turf.x, a_turf.y)
	return turf_biome_cache[a_turf]

/// Вычисляет биом для координаты (x, y).
/// * deterministic_drift - TRUE для пред-посчитанной сетки: дрифт границ считается хэшем
/// координат (детерминированно), чтобы сетка воспроизводилась из сида. Иначе rand() как раньше.
/datum/map_generator/planet_generator/proc/compute_biome_at(x, y, deterministic_drift = FALSE)
	// random offset coordinates to fuzz biome borders.
	// not actually huge on this for several reasons but it works alright to cover up small perlin artifacts
	var/drift_x
	var/drift_y
	if(deterministic_drift)
		var/hash_1 = (x * 73856093) ^ (y * 19349663)
		var/hash_2 = (x * 83492791) ^ (y * 1299709)
		drift_x = (x + (hash_1 % 3) - 1) / perlin_zoom
		drift_y = (y + (hash_2 % 3) - 1) / perlin_zoom
	else
		drift_x = (x + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / perlin_zoom
		drift_y = (y + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / perlin_zoom

	var/heat_level
	var/humidity_level

	var/datum/biome/sel_biome

	// gets humidity
	switch(text2num(rustg_noise_get_at_coordinates("[humidity_seed]", "[drift_x]", "[drift_y]")))
		if(0 to 0.20)
			humidity_level = BIOME_LOWEST_HUMIDITY
		if(0.20 to 0.40)
			humidity_level = BIOME_LOW_HUMIDITY
		if(0.40 to 0.60)
			humidity_level = BIOME_MEDIUM_HUMIDITY
		if(0.60 to 0.80)
			humidity_level = BIOME_HIGH_HUMIDITY
		if(0.80 to 1)
			humidity_level = BIOME_HIGHEST_HUMIDITY

	// gets heat. we index the biome lists with heat first, but the one we use depends on the height
	// so we do the humidity first 'cause it's easier that way
	var/heat = text2num(rustg_noise_get_at_coordinates("[heat_seed]", "[drift_x]", "[drift_y]"))

	// gets height
	if(text2num(rustg_noise_get_at_coordinates("[height_seed]", "[drift_x]", "[drift_y]")) <= mountain_height)
		switch(heat)
			if(0 to 0.20)
				heat_level = BIOME_COLDEST
			if(0.20 to 0.40)
				heat_level = BIOME_COLD
			if(0.40 to 0.60)
				heat_level = BIOME_WARM
			if(0.60 to 0.65)
				heat_level = BIOME_TEMPERATE
			if(0.65 to 0.80)
				heat_level = BIOME_HOT
			if(0.80 to 1)
				heat_level = BIOME_HOTTEST

		sel_biome = SSmapping.biomes[biome_table[heat_level][humidity_level]]
	else
		switch(heat)
			if(0 to 0.25)
				heat_level = BIOME_COLDEST_CAVE
			if(0.25 to 0.5)
				heat_level = BIOME_COLD_CAVE
			if(0.5 to 0.75)
				heat_level = BIOME_WARM_CAVE
			if(0.75 to 1)
				heat_level = BIOME_HOT_CAVE

		sel_biome = SSmapping.biomes[cave_biome_table[heat_level][humidity_level]]

	return sel_biome

/// Считает раскладку биомов для блока width x height (относительные координаты 1..w, 1..h)
/// без обращения к турфам. Возвращает плоский список индексов (y-1)*width+x.
/// Тяжёлая часть (rust-g шум) выносится сюда - эту фазу можно запускать заранее.
/datum/map_generator/planet_generator/proc/precompute_biome_grid(width, height)
	precomputed_grid = new /list(width * height)
	var/start_time = REALTIMEOFDAY
	for(var/y in 1 to height)
		for(var/x in 1 to width)
			precomputed_grid[(y - 1) * width + x] = compute_biome_at(x, y, TRUE)
		CHECK_TICK
	var/message = "MAPGEN: MAPGEN REF [REF(src)] ([type]) PRECOMPUTED GRID [width]x[height] IN [(REALTIMEOFDAY - start_time)/10]s"
	log_shuttle(message)
	log_world(message)
	return precomputed_grid

/// Привязывает пред-посчитанную сетку к блоку генерации по абсолютным координатам.
/datum/map_generator/planet_generator/proc/set_precomputed_grid(list/grid, offset_x, offset_y, new_grid_width)
	precomputed_grid = grid
	grid_offset_x = offset_x
	grid_offset_y = offset_y
	grid_width = new_grid_width

#undef BIOME_RANDOM_SQUARE_DRIFT


/datum/map_generator/planet_generator/post_generation(list/turf/turfs)
	var/start_time = REALTIMEOFDAY
	var/message = "MAPGEN: MAPGEN REF [REF(src)] ([type]) STARTING POST GEN"
	log_shuttle(message)
	log_world(message)

	for(var/turf/check_turf as anything in turfs)

		var/obj/effect/greeble_spawner/our_greeble = locate(/obj/effect/greeble_spawner) in check_turf
		if(our_greeble)
			our_greeble.start_load()

		CHECK_TICK

	for(var/turf/gen_turf as anything in turfs)
		gen_turf.AfterChange(CHANGETURF_IGNORE_AIR)

		QUEUE_SMOOTH(gen_turf)
		QUEUE_SMOOTH_NEIGHBORS(gen_turf)

		for(var/turf/open/space/adj in RANGE_TURFS(1, gen_turf))
			adj.check_starlight(gen_turf)

		// CHECK_TICK here is fine -- we are assuming that the turfs we're generating are staying relatively constant
		CHECK_TICK

	message = "MAPGEN: MAPGEN REF [REF(src)] ([type]) HAS FINISHED POST GEN IN [(REALTIMEOFDAY - start_time)/10]s"
	log_shuttle(message)
	log_world(message)
	return
