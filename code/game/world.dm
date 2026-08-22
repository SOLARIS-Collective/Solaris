#define RESTART_COUNTER_PATH "data/round_counter.txt"

GLOBAL_VAR(restart_counter)

// Tick control variables
/// Should we intentionally consume cpu time to try to keep SendMaps deltas constant?
GLOBAL_VAR_INIT(attempt_corrective_cpu, TRUE)
/// Should we use the corrective cpu threshold to calculate the mc's target cpu?
GLOBAL_VAR_INIT(use_dynamic_mc_limit, TRUE)

// MC dynamic autoaccounting variables
/// What value are we attempting to correct cpu TO (autoaccounts for lag, ideally)
GLOBAL_VAR_INIT(corrective_cpu_threshold, 0)
/// What cpu value are we trying to meet safely.
/// For reasons I do not yet understand 90 is too high for this on highpop. I think it has to do with
/// maptick being averaged/spikey? unsure.
GLOBAL_VAR_INIT(corrective_cpu_target, 85)
/// What cpu value we actually end up pinning ticks to, used for debug display
GLOBAL_VAR_INIT(corrective_cpu_cost, 0)
/// How far away from the average can we get before discarding a datapoint (threshold adjustment)
GLOBAL_VAR_INIT(corrective_cpu_ratio, 30)
/// How far away from the average can we get before discarding a datapoint (glide size)
GLOBAL_VAR_INIT(glide_threshold_ratio, 10)

// Debug tools, lets admins set artificial load to test the compensation system with
/// Lets us set the floor of cpu consumption
GLOBAL_VAR_INIT(floor_cpu, 0)
/// Lets us set a sometimes used floor for cpu consumption
GLOBAL_VAR_INIT(sustain_cpu, 0)
/// Sets the chance to use GLOB.sustain_cpu as a floor
GLOBAL_VAR_INIT(sustain_cpu_chance, 0)
/// Floors cpu to its value, then resets itself
GLOBAL_VAR_INIT(spike_cpu, 0)

/**
 * Here is where a round itself is actually begun and setup.
 * * db connection setup
 * * config loaded from files
 * * loads admins
 * * Sets up the dynamic menu system
 * * and most importantly, calls initialize on the master subsystem, starting the game loop that causes the rest of the game to begin processing and setting up
 *
 *
 * Nothing happens until something moves. ~Albert Einstein
 *
 * For clarity, this proc gets triggered later in the initialization pipeline, it is not the first thing to happen, as it might seem.
 *
 * Initialization Pipeline:
 *		Global vars are new()'ed, (including config, glob, and the master controller will also new and preinit all subsystems when it gets new()ed)
 *		Compiled in maps are loaded (mainly centcom). all areas/turfs/objs/mobs(ATOMs) in these maps will be new()ed
 *		world/New() (You are here)
 *		Once world/New() returns, client's can connect.
 *		1 second sleep
 *		Master Controller initialization.
 *		Subsystem initialization.
 *			Non-compiled-in maps are maploaded, all atoms are new()ed
 *			All atoms in both compiled and uncompiled maps are initialized()
 */
/world/New()
	log_world("World loaded at [time_stamp()]!")
	SSmetrics.world_init_time = REALTIMEOFDAY // Important

	// [SOLARIS] - Запас под крупные мап-боксы: мир расширяется до 208x208.
	// Новые турфы создаются как /turf/open/space/basic (задано в /world блоке).
	if(world.maxx < 208 || world.maxy < 208)
		world.maxx = max(world.maxx, 208)
		world.maxy = max(world.maxy, 208)

	make_datum_references_lists()	//initialises global lists for referencing frequently used datums (so that we only ever do it once)

	GLOB.config_error_log = GLOB.world_manifest_log = GLOB.world_pda_log = GLOB.world_job_debug_log = GLOB.sql_error_log = GLOB.world_href_log = GLOB.world_runtime_log = GLOB.world_attack_log = GLOB.world_game_log = GLOB.world_shuttle_log = GLOB.world_mankind_admin_log = "data/logs/config_error.[GUID()].log" //temporary file used to record errors with loading config, moved to log directory once logging is set bl

	GLOB.revdata = new

	InitTgs()

	config.Load(params[OVERRIDE_CONFIG_DIRECTORY_PARAMETER])

	// Load the auxcpu byondapi library if present and enabled, for accurate raw CPU
	// readings. Must run after config.Load so the LOAD_AUXCPU_LIBRARY gate is readable.
	setup_external_cpu()

	load_admins()
	load_mentors() //WS edit - Mentors

	//SetupLogs depends on the RoundID, so lets check
	//DB schema and set RoundID if we can
	SSdbcore.CheckSchemaVersion()
	SSdbcore.SetRoundID()
	SetupLogs()
	populate_gear_list() //WS edit - Loadouts
	load_poll_data()

#ifndef USE_CUSTOM_ERROR_HANDLER
	world.log = file("[GLOB.log_directory]/dd.log")
#else
	if (TgsAvailable())
		world.log = file("[GLOB.log_directory]/dd.log") //not all runtimes trigger world/Error, so this is the only way to ensure we can see all of them.
#endif

	LoadVerbs(/datum/verbs/menu)
	if(CONFIG_GET(flag/usewhitelist))
		load_whitelist()

	GLOB.timezoneOffset = text2num(time2text(0,"hh")) * 36000

	if(fexists(RESTART_COUNTER_PATH))
		GLOB.restart_counter = text2num(trim(file2text(RESTART_COUNTER_PATH)))
		fdel(RESTART_COUNTER_PATH)

	if(NO_INIT_PARAMETER in params)
		return

	// Init the debugger first so we can debug Master
	Debugger = new

	Master.Initialize(10, FALSE, TRUE)

	#ifdef UNIT_TESTS
	HandleTestRun()
	#endif

	#ifdef AUTOWIKI
	setup_autowiki()
	#endif

/world/Tick()
	// this is for next tick so don't display it yet yeah?
	var/datum/tick_holder/tick_info = ____tick_info
	var/current_index = TICK_INFO_INDEX()
	if(tick_info)
		tick_info.pre_tick_cpu_usage[current_index] = TICK_USAGE
		// MC sometimes yields and such
		if(!tick_info.mc_fired(world.time))
			tick_info.mc_start_usage[current_index] = 0
			tick_info.mc_finished_usage[current_index] = 0

	refresh_cpu_values()

	if(GLOB.floor_cpu)
		// avoids byond sleeping the loop and causing the MC to infinistall
		// Run first to set a floor for sustain to spike up to
		CONSUME_UNTIL(min(GLOB.floor_cpu, 500))

	if(GLOB.sustain_cpu && prob(GLOB.sustain_cpu_chance))
		CONSUME_UNTIL(min(GLOB.sustain_cpu, 500))

	if(GLOB.spike_cpu)
		CONSUME_UNTIL(min(GLOB.spike_cpu, 10000))
		GLOB.spike_cpu = 0

	// attempt to correct cpu overrun
	var/cpu_corrected = FALSE
	// If we're supposed to be correcting cpu, burn idle time to pin usage to a consistent level.
	// This keeps the period between SendMaps() calls consistent, which stops clients
	// from skipping frames (and thus stuttering), at the cost of burning idle cpu.
	// The MC cooperates by limiting itself to the same threshold (see TICK_LIMIT_RUNNING),
	// and update_cpu_compensation() lowers the threshold if passive overrun persists.
	if(GLOB.attempt_corrective_cpu && GLOB.corrective_cpu_threshold > TICK_USAGE)
		cpu_corrected = TRUE
		CONSUME_UNTIL(GLOB.corrective_cpu_threshold)
	// or if we HAVE already corrected cpu with the MC (roughly, hard to be exact about this stuff)
	else if(GLOB.use_dynamic_mc_limit && GLOB.corrective_cpu_threshold + GLOB.corrective_cpu_threshold * 0.05 > TICK_USAGE)
		cpu_corrected = TRUE
	if(tick_info)
		tick_info.corrected_ticks[current_index] = cpu_corrected

	GLOB.cpu_tracker.update_display()

	if(tick_info)
		tick_info.tick_cpu_usage[current_index] = TICK_USAGE

	// [SOLARIS] - per-tick cpu recording (see tick_control.dm)
	if(GLOB.cpu_recorder)
		GLOB.cpu_recorder.record_tick(tick_info, current_index)

/// Holds and tracks information about the past [TICK_INFO_SIZE] ticks
/// Global datum, so it survives MC restarts and is available before GLOB exists
/datum/tick_holder
	var/name = "Tick Holder"
	// All of these lists are TICK_INFO_SIZE rolling lists
	/// Deaveraged world.cpu values (it's normally a INTERNAL_CPU_SIZE index long rolling average)
	var/list/cpu_values = new /list(TICK_INFO_SIZE)
	/// If the mc fired this stores the tick it happen in to avoid issues with mc sleeps leading to old data sticking around.
	var/list/mc_fired = new /list(TICK_INFO_SIZE)
	/// world.tick_usage when the mc first woke up (Should be the cost of sleeping procs invoked before the mc)
	var/list/mc_start_usage = new /list(TICK_INFO_SIZE)
	/// world.tick_usage when the mc falls back asleep
	var/list/mc_finished_usage = new /list(TICK_INFO_SIZE)
	/// difference between mc_finished_usage and mc_start_usage, provided for convenience
	var/list/mc_usage = new /list(TICK_INFO_SIZE)
	/// difference between pre_tick_cpu_usage and mc_finished_usage, provided for convenience (Should be just sleeping procs invoked post mc)
	var/list/post_mc_usage = new /list(TICK_INFO_SIZE)
	/// world.tick_usage at the begining of Tick()
	var/list/pre_tick_cpu_usage = new /list(TICK_INFO_SIZE)
	/// world.tick_usage at the end of Tick()
	var/list/tick_cpu_usage = new /list(TICK_INFO_SIZE)
	/// difference between cpu_values and tick_cpu_usage, provided for convenience (Should be exclusively the deaveraged cost of maptick)
	var/list/maptick_usage = new /list(TICK_INFO_SIZE)
	/// total verb cost. Unused without verb tracking, kept zeroed so graphs render correctly
	var/list/verb_cost = new /list(TICK_INFO_SIZE)
	/// Parsed verb timing info. Unused without verb tracking
	var/list/verb_timings = new /list(TICK_INFO_SIZE)
	/// world.tick_usage we had when the last verb finished running. Unused without verb tracking
	var/list/last_verb_ran = new /list(TICK_INFO_SIZE)
	/// difference between our calculated world.cpu (from cpu_values) and the real one, for debugging
	var/list/cpu_error = new /list(TICK_INFO_SIZE)
	/// TRUE if we corrected the tick to try and target some threshold usage to avoid jitter, FALSE otherwise
	var/list/corrected_ticks = new /list(TICK_INFO_SIZE)
	/// Subsystems fired in the previous tick, paired with thier usage
	var/list/last_subsystem_usages = list()
	/// Subsystems fired in the previous tick, paired with thier tick allocations
	var/list/last_subsystem_allocations = list()
	/// tick info index for the LAST tick, so we can fill in data we'd otherwise be missing
	var/cpu_index = 1
	/// last world.time refresh_cpu_values was ran
	var/last_cpu_update = -1

/// If the mc fired in the passed in tick (assuming it's within [TICK_INFO_SIZE] of our current tick)
/datum/tick_holder/proc/mc_fired(tick_inspecting)
	if(mc_fired[TICK_INFO_TICK2INDEX(DS2TICKS(tick_inspecting))] == tick_inspecting)
		return TRUE
	return FALSE

// Not initialized, because we have to do that manually
GLOBAL_REAL(____tick_info, /datum/tick_holder)
GLOBAL_DATUM(tick_info, /datum/tick_holder)

/// Pushes information about cpu usage from the last tick into our /datum/tick_holder
/// Safe to call multiple times per tick, only the first call records.
/world/proc/refresh_cpu_values()
	if(!____tick_info)
		____tick_info = new()
	if(GLOB)
		GLOB.tick_info = ____tick_info

	var/datum/tick_holder/tick_info = ____tick_info
	if(tick_info.last_cpu_update == world.time)
		return
	tick_info.last_cpu_update = world.time

	// info about the last game tick so it should be logged as the last game tick
	var/cpu_index = TICK_INFO_TICK2INDEX(DS2TICKS(world.time) - 1)
	tick_info.cpu_index = cpu_index
	// cache for sonic speed
	var/list/cpu_values = tick_info.cpu_values

	// ok so world.cpu is a INTERNAL_CPU_SIZE entry wide moving average of the actual cpu value
	// because fuck you
	// I want the ACTUAL unrolled value, which our auxcpu helpers can give us when the library is present.
	// yes byond does average against a constant window size, it doesn't account for a lack of values initially
	// it just sorta assumes they exist.
	var/real_cpu = current_true_cpu()

	// Shit check our memhacking, compares our unrolled window against byond's own average
	var/calculated_avg = real_cpu
	for(var/i in 1 to INTERNAL_CPU_SIZE - 1)
		calculated_avg += cpu_values[WRAP(cpu_index - i, 1, TICK_INFO_SIZE + 1)]
	// (95.7994 * 16) - 1536.35 == -3.3
	// (a+b+c+d...) / 16 * 16 - (a+b+c+d...) == -g
	var/inbuilt_error = world.cpu * INTERNAL_CPU_SIZE - calculated_avg

	cpu_values[cpu_index] = real_cpu
	tick_info.mc_usage[cpu_index] = tick_info.mc_finished_usage[cpu_index] - tick_info.mc_start_usage[cpu_index]
	tick_info.post_mc_usage[cpu_index] = tick_info.pre_tick_cpu_usage[cpu_index] - tick_info.mc_finished_usage[cpu_index]
	// world.cpu is continuous cpu from tick start to right after maptick, so we can doooo this
	tick_info.maptick_usage[cpu_index] = cpu_values[cpu_index] - tick_info.tick_cpu_usage[cpu_index]
	tick_info.cpu_error[cpu_index] = inbuilt_error

/// Updates [GLOB.glide_size_multiplier] and [GLOB.corrective_cpu_threshold] to account for any persistent lag we may be experiencing
/proc/update_cpu_compensation()
	world.refresh_cpu_values()
	var/datum/tick_holder/tick_info = ____tick_info
	if(!tick_info)
		return
	var/list/cpu_values = tick_info.cpu_values
	var/list/corrected_ticks = tick_info.corrected_ticks

	// We've got a big ass list of cpu values from the last however many ticks
	// We want to know how much passive tick overrun we're experiencing, so we can:
	// A: Compensate clientside glide times to line up with how long we predict each tick to actually take
	// B: Pin cpu usage to a consistant value, so we can provide verbs time to execute and to ensure there is
	//   a consistent period of time between each map send to clients
	//   (since if things aren't consistent clients will have to jump frames, which leads to jitter)
	// In order to do this effectively we want to work out the average cpu cost, ignoring large spikes from uncontrolable parts of the codebase
	// We track capped (maxed out to 100) and corrected (touched by this system) usage seprately
	// capped is used for glide size, since we don't care if you're below 100% of the tick. we do for cpu pinning tho so we gotta do it differently
	var/capped_sum = 0
	var/non_zero = 0
	var/corrected_sum = 0
	var/non_zero_corrected = 0
	for(var/i in 1 to length(cpu_values))
		var/value = cpu_values[i]
		capped_sum += max(value, 100)
		if(corrected_ticks[i])
			corrected_sum += value
			if(value != 0)
				non_zero_corrected += 1
		if(value != 0)
			non_zero += 1

	var/first_capped_average = non_zero ? capped_sum / non_zero : 1
	var/trimmed_capped_sum = 0
	var/cap_used = 0
	var/first_corrected_average = non_zero_corrected ? corrected_sum / non_zero_corrected : 1
	var/trimmed_max_value = 0
	for(var/i in 1 to length(cpu_values))
		var/value = cpu_values[i]
		// If we're within glide_threshold_ratio% of the capped average, include us in the trimmed sum
		if(value && max(value, 100) / first_capped_average - 1 <= GLOB.glide_threshold_ratio / 100)
			trimmed_capped_sum += max(value, 100)
			cap_used += 1
		// If we deviate more then corrective_cpu_ratio% above the corrected average (a spike), skip us over
		if(corrected_ticks[i] && value && value / first_corrected_average - 1 <= GLOB.corrective_cpu_ratio / 100)
			trimmed_max_value = max(value, trimmed_max_value)

	var/final_capped_average = trimmed_capped_sum ? trimmed_capped_sum / cap_used : first_capped_average
	GLOB.glide_size_multiplier = min(100 / final_capped_average, 1)

	// Now account for passive overrun (mc + maptick eating past our target).
	// If it persists we lower the threshold, so the corrective burn leaves room for it instead of forcing overtime.
	var/final_corrected_value = trimmed_max_value ? trimmed_max_value : first_corrected_average
	if(final_corrected_value > GLOB.corrective_cpu_target)
		GLOB.corrective_cpu_threshold = GLOB.corrective_cpu_target - (final_corrected_value - GLOB.corrective_cpu_target)
		GLOB.corrective_cpu_cost = final_corrected_value
	else
		GLOB.corrective_cpu_threshold = GLOB.corrective_cpu_target
		GLOB.corrective_cpu_cost = 0

/world/proc/InitTgs()
	TgsNew(new /datum/tgs_event_handler/impl, TGS_SECURITY_TRUSTED)
	GLOB.revdata.load_tgs_info()

/world/proc/HandleTestRun()
	//trigger things to run the whole process
	Master.sleep_offline_after_initializations = FALSE
	SSticker.start_immediately = TRUE
	CONFIG_SET(number/round_end_countdown, 0)
	var/datum/callback/cb
#ifdef UNIT_TESTS
	cb = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(RunUnitTests))
#else
	cb = VARSET_CALLBACK(SSticker, force_ending, TRUE)
#endif
	SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_addtimer), cb, 10 SECONDS))


/world/proc/SetupLogs()
	var/override_dir = params[OVERRIDE_LOG_DIRECTORY_PARAMETER]
	if(!override_dir)
		var/realtime = world.realtime
		var/texttime = time2text(realtime, "YYYY/MM/DD")
		GLOB.log_directory = "data/logs/[texttime]/round-"
		GLOB.picture_logging_prefix = "L_[time2text(realtime, "YYYYMMDD")]_"
		GLOB.picture_log_directory = "data/picture_logs/[texttime]/round-"
		if(GLOB.round_id)
			GLOB.log_directory += "[GLOB.round_id]"
			GLOB.picture_logging_prefix += "R_[GLOB.round_id]_"
			GLOB.picture_log_directory += "[GLOB.round_id]"
		else
			var/timestamp = replacetext(time_stamp(), ":", ".")
			GLOB.log_directory += "[timestamp]"
			GLOB.picture_log_directory += "[timestamp]"
			GLOB.picture_logging_prefix += "T_[timestamp]_"
	else
		GLOB.log_directory = "data/logs/[override_dir]"
		GLOB.picture_logging_prefix = "O_[override_dir]_"
		GLOB.picture_log_directory = "data/picture_logs/[override_dir]"

	GLOB.world_game_log = "[GLOB.log_directory]/game.log"
	GLOB.world_mecha_log = "[GLOB.log_directory]/mecha.log"
	GLOB.world_virus_log = "[GLOB.log_directory]/virus.log"
	GLOB.world_cloning_log = "[GLOB.log_directory]/cloning.log"
	GLOB.world_asset_log = "[GLOB.log_directory]/asset.log"
	GLOB.world_attack_log = "[GLOB.log_directory]/attack.log"
	GLOB.world_pda_log = "[GLOB.log_directory]/pda.log"
	GLOB.world_telecomms_log = "[GLOB.log_directory]/telecomms.log"
	GLOB.world_manifest_log = "[GLOB.log_directory]/manifest.log"
	GLOB.world_href_log = "[GLOB.log_directory]/hrefs.log"
	GLOB.sql_error_log = "[GLOB.log_directory]/sql.log"
	GLOB.world_qdel_log = "[GLOB.log_directory]/qdel.log"
	GLOB.world_map_error_log = "[GLOB.log_directory]/map_errors.log"
	GLOB.world_runtime_log = "[GLOB.log_directory]/runtime.log"
	GLOB.query_debug_log = "[GLOB.log_directory]/query_debug.log"
	GLOB.world_job_debug_log = "[GLOB.log_directory]/job_debug.log"
	GLOB.world_paper_log = "[GLOB.log_directory]/paper.log"
	GLOB.tgui_log = "[GLOB.log_directory]/tgui.log"
	GLOB.world_shuttle_log = "[GLOB.log_directory]/shuttle.log"
	GLOB.world_mankind_economic_log = "[GLOB.log_directory]/world_mankind_economic.log" // [MANKIND-ADD] - MANKIND_COMPONENTS_LOGS
	GLOB.world_mankind_admin_log = "[GLOB.log_directory]/admin.log" // [MANKIND-ADD] - Добавляем логирование админских действий.
	GLOB.world_planets_log = "[GLOB.log_directory]/planets.txt" // [SOLARIS-ADD] - Логирование генерации/загрузки планет.

	GLOB.demo_log = "[GLOB.log_directory]/demo.log"

#ifdef UNIT_TESTS
	GLOB.test_log = "[GLOB.log_directory]/tests.log"
	start_log(GLOB.test_log)
#endif
#ifdef REFERENCE_DOING_IT_LIVE
	GLOB.harddel_log = "[GLOB.log_directory]/harddels.log"
#endif
	start_log(GLOB.world_game_log)
	start_log(GLOB.world_attack_log)
	start_log(GLOB.world_pda_log)
	start_log(GLOB.world_telecomms_log)
	start_log(GLOB.world_manifest_log)
	start_log(GLOB.world_href_log)
	start_log(GLOB.world_qdel_log)
	start_log(GLOB.world_runtime_log)
	start_log(GLOB.world_job_debug_log)
	start_log(GLOB.tgui_log)
	start_log(GLOB.world_shuttle_log)
	start_log(GLOB.world_mankind_economic_log) // [MANKIND-ADD] - MANKIND_COMPONENTS_LOGS
	start_log(GLOB.world_mankind_admin_log) // [MANKIND-ADD] - Добавляем логирование админских действий.
	start_log(GLOB.world_planets_log) // [SOLARIS-ADD] - Логирование генерации/загрузки планет.

	var/latest_changelog = file("[global.config.directory]/../html/changelogs/archive/" + time2text(world.timeofday, "YYYY-MM") + ".yml")
	GLOB.changelog_hash = fexists(latest_changelog) ? md5(latest_changelog) : 0 //for telling if the changelog has changed recently
	if(fexists(GLOB.config_error_log))
		fcopy(GLOB.config_error_log, "[GLOB.log_directory]/config_error.log")
		fdel(GLOB.config_error_log)

	if(GLOB.round_id)
		log_game("Round ID: [GLOB.round_id]")

	// This was printed early in startup to the world log and config_error.log,
	// but those are both private, so let's put the commit info in the runtime
	// log which is ultimately public.
	log_runtime(GLOB.revdata.get_log_message())

/world/Topic(T, addr, master, key)
	TGS_TOPIC	//redirect to server tools if necessary

	var/static/list/topic_handlers = TopicHandlers()

	var/list/input = params2list(T)
	var/datum/world_topic/handler
	for(var/I in topic_handlers)
		if(I in input)
			handler = topic_handlers[I]
			break

	if((!handler || initial(handler.log)) && config && CONFIG_GET(flag/log_world_topic))
		log_topic("\"[T]\", from:[addr], master:[master], key:[key]")

	if(!handler)
		return

	handler = new handler()
	return handler.TryRun(input)

/world/proc/AnnouncePR(announcement, list/payload)
	var/static/list/PRcounts = list()	//PR id -> number of times announced this round
	var/id = "[payload["pull_request"]["id"]]"
	if(!PRcounts[id])
		PRcounts[id] = 1
	else
		++PRcounts[id]
		if(PRcounts[id] > PR_ANNOUNCEMENTS_PER_ROUND)
			return

	var/final_composed = span_announce("PR: [announcement]")
	for(var/client/C in GLOB.clients)
		C.AnnouncePR(final_composed)

/world/proc/FinishTestRun()
	set waitfor = FALSE
	var/list/fail_reasons
	if(GLOB)
		if(GLOB.total_runtimes != 0)
			fail_reasons = list("Total runtimes: [GLOB.total_runtimes]")
#ifdef UNIT_TESTS
		if(GLOB.failed_any_test)
			LAZYADD(fail_reasons, "Unit Tests failed!")
#endif
		if(!GLOB.log_directory)
			LAZYADD(fail_reasons, "Missing GLOB.log_directory!")
	else
		fail_reasons = list("Missing GLOB!")
	if(!fail_reasons)
		text2file("Success!", "[GLOB.log_directory]/clean_run.lk")
	else
		log_world("Test run failed!\n[fail_reasons.Join("\n")]")
	sleep(0)	//yes, 0, this'll let Reboot finish and prevent byond memes
	qdel(src)	//shut it down

/world/Reboot(reason = 0, fast_track = FALSE)
	if (reason || fast_track) //special reboot, do none of the normal stuff
		if (usr)
			log_admin("[key_name(usr)] Has requested an immediate world restart via client side debugging tools")
			message_admins("[key_name_admin(usr)] Has requested an immediate world restart via client side debugging tools")
		to_chat(world, span_boldannounce("Rebooting World immediately due to host request."))
	else
		to_chat(world, span_boldannounce("Rebooting world..."))
		Master.Shutdown()	//run SS shutdowns

	TgsReboot()

#ifdef UNIT_TESTS
	FinishTestRun()
	return

#else
	if(TgsAvailable())
		var/do_hard_reboot
		// check the hard reboot counter
		var/ruhr = CONFIG_GET(number/rounds_until_hard_restart)
		switch(ruhr)
			if(-1)
				do_hard_reboot = FALSE
			if(0)
				do_hard_reboot = TRUE
			else
				if(GLOB.restart_counter >= ruhr)
					do_hard_reboot = TRUE
				else
					text2file("[++GLOB.restart_counter]", RESTART_COUNTER_PATH)
					do_hard_reboot = FALSE

		if(do_hard_reboot)
			log_world("World hard rebooted at [time_stamp()]")
			shutdown_logging() // See comment below.
			QDEL_NULL(Debugger)
			TgsEndProcess()

	log_world("World rebooted at [time_stamp()]")
	shutdown_logging() // Past this point, no logging procs can be used, at risk of data loss.
	..()

#endif //ifdef UNIT_TESTS

/world/proc/update_status()

	var/list/features = list()

	if(LAZYACCESS(SSlag_switch.measures, DISABLE_NON_OBSJOBS))
		features += "closed"

	var/s = ""
	var/hostedby
	if(config)
		var/server_name = CONFIG_GET(string/servername)
		if (server_name)
			s += "<b>[server_name]</b> &#8212; "
		features += "[CONFIG_GET(flag/norespawn) ? "no " : ""]respawn"
		hostedby = CONFIG_GET(string/hostedby)

	var/discord_url
	var/github_url
	if(isnull(config))
		discord_url = "https://shiptest.net/discord"
		github_url = "https://github.com/shiptest-ss13/Shiptest"
	else
		discord_url = CONFIG_GET(string/discordurl)
		github_url = CONFIG_GET(string/githuburl)

	s += "<b>[station_name()]</b>";
	s += " ("
	s += "<a href=\"[discord_url]\">" //Change this to wherever you want the hub to link to.
	s += "Discord"  //Replace this with something else. Or ever better, delete it and uncomment the game version.
	s += "</a>"
	s += ")"
	s += " ("
	s += "<a href=\"[github_url]\">"
	s += "Github"
	s += "</a>"
	s += ")"

	var/players = GLOB.clients.len

	var/popcaptext = ""
	var/popcap = max(CONFIG_GET(number/extreme_popcap), CONFIG_GET(number/hard_popcap), CONFIG_GET(number/soft_popcap))
	if (popcap)
		popcaptext = "/[popcap]"

	if (players > 1)
		features += "[players][popcaptext] players"
	else if (players > 0)
		features += "[players][popcaptext] player"

	game_state = (CONFIG_GET(number/extreme_popcap) && players >= CONFIG_GET(number/extreme_popcap)) //tells the hub if we are full

	if (!host && hostedby)
		features += "hosted by <b>[hostedby]</b>"

	if (features)
		s += ": [jointext(features, ", ")]"

	status = s

/world/proc/update_hub_visibility(new_visibility)
	if(new_visibility == GLOB.hub_visibility)
		return
	GLOB.hub_visibility = new_visibility
	if(GLOB.hub_visibility)
		hub_password = "kMZy3U5jJHSiBQjr"
	else
		hub_password = "SORRYNOPASSWORD"

/world/proc/incrementMaxZ()
	maxz++
	world.refresh_atmos_grid()

/world/proc/change_fps(new_value = 20)
	if(new_value <= 0)
		CRASH("change_fps() called with [new_value] new_value.")
	if(fps == new_value)
		return //No change required.

	fps = new_value
	on_tickrate_change()


/world/proc/change_tick_lag(new_value = 0.5)
	if(new_value <= 0)
		CRASH("change_tick_lag() called with [new_value] new_value.")
	if(tick_lag == new_value)
		return //No change required.

	tick_lag = new_value
	on_tickrate_change()


/world/proc/on_tickrate_change()
	SStimer?.reset_buckets()


/world/proc/refresh_atmos_grid()
