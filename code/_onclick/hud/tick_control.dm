INITIALIZE_IMMEDIATE(/atom/movable/screen/usage_display)
GLOBAL_DATUM_INIT(cpu_tracker, /atom/movable/screen/usage_display, new())
// [SOLARIS] - per-tick cpu recorder for offline test analysis
GLOBAL_DATUM_INIT(cpu_recorder, /datum/cpu_recorder, new())

/// How often (in ticks) the per-subsystem breakdown is written into the record.
/// Core metrics are written every tick; ss is the bulk of the size.
#define RECORDER_SS_INTERVAL 10

/// Writes one JSON object per tick while enabled, into the current round's log dir
/// (data/logs/.../round-*/auxcp_rec.log), falling back to repo root before logs init.
/// Format: JSONL - one compact json_encode()'d object per line, # comment lines mark sessions.
/// Subsystem costs ("ss") are sampled every [RECORDER_SS_INTERVAL] ticks to keep the file small;
/// gaps in "time" values == server stalls/freezes.
/// Uses rustg async logging - writes are flushed from a Rust thread, zero tick blocking.
/// Appends across sessions, numbered per round.
/// [SOLARIS]
/datum/cpu_recorder
	var/recording = FALSE
	var/ticks_logged = 0
	var/sessions_started = 0
	var/recording_path

/datum/cpu_recorder/proc/start_recording()
	if(recording)
		return FALSE
	recording_path = "[GLOB?.log_directory ? "[GLOB.log_directory]/" : ""]auxcp_rec.log"
	sessions_started++
	recording = TRUE
	ticks_logged = 0
	var/session_stamp = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")
	WRITE_LOG_NO_FORMAT(recording_path, "# session #[sessions_started] start=[session_stamp] time=[world.time] tick_lag=[world.tick_lag] \
		compensation=[GLOB.attempt_corrective_cpu] mc_limit=[GLOB.use_dynamic_mc_limit] target=[GLOB.corrective_cpu_target] \
		ratio=[GLOB.corrective_cpu_ratio] glide_ratio=[GLOB.glide_threshold_ratio] auxcpu=[GLOB.auxcpu_loaded] ss_interval=[RECORDER_SS_INTERVAL]\n")
	return TRUE

/datum/cpu_recorder/proc/stop_recording()
	if(!recording)
		return
	recording = FALSE
	var/stop_stamp = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")
	WRITE_LOG_NO_FORMAT(recording_path, "# stopped=[stop_stamp] time=[world.time] ticks=[ticks_logged]\n")

/datum/cpu_recorder/proc/record_tick(datum/tick_holder/tick_info, index)
	if(!recording || !recording_path || !tick_info)
		return
	var/list/entry = list(
		"stamp" = time2text(world.realtime, "hh:mm:ss"),
		"time" = world.time,
		"raw" = tick_info.cpu_values[index],
		"start" = tick_info.pre_tick_cpu_usage[index],
		"sleep" = tick_info.mc_start_usage[index],
		"mc" = tick_info.mc_usage[index],
		"post" = tick_info.post_mc_usage[index],
		"map" = tick_info.maptick_usage[index],
		"end" = tick_info.tick_cpu_usage[index],
		"corr" = tick_info.corrected_ticks[index],
		"thr" = GLOB.corrective_cpu_threshold,
		"glide" = GLOB.glide_size_multiplier,
	)
	if((ticks_logged % RECORDER_SS_INTERVAL) == 0)
		var/list/subsystems = list()
		for(var/subsystem_path in tick_info.last_subsystem_usages)
			subsystems["[replacetext("[subsystem_path]", "/datum/controller/subsystem/", "")]"] = tick_info.last_subsystem_usages[subsystem_path]
		entry["ss"] = subsystems
	WRITE_LOG_NO_FORMAT(recording_path, json_encode(entry) + "\n")
	ticks_logged++

/// Holds graphing/maptext stuff that displays/debugs cpu usage information
/atom/movable/screen/usage_display
	screen_loc = "LEFT:8, CENTER-6"
	plane = GRAPHING_PLANE
	layer = CPU_DISPLAY_LAYER
	maptext_width = 512
	maptext_height = 512
	alpha = 220
	// how many people are looking at us right now?
	var/viewer_count = 0
	/// What modes CAN the graph display?
	// [SOLARIS] - USAGE_DISPLAY_VERBS / USAGE_DISPLAY_VERB_TIMING removed: no verb tracking ported
	var/list/graph_options = list(
		USAGE_DISPLAY_EARLY_SLEEPERS,
		USAGE_DISPLAY_MC,
		USAGE_DISPLAY_LATE_SLEEPERS,
		USAGE_DISPLAY_SLEEPERS,
		USAGE_DISPLAY_PRE_TICK,
		USAGE_DISPLAY_MAPTICK,
		USAGE_DISPLAY_PRE_VERBS,
		USAGE_DISPLAY_COMPLETE_CPU,
	)
	var/atom/movable/screen/graph_display/bars/cpu_display/graph_display
	var/atom/movable/screen/usage_display_controls/controls
	var/display_graph = TRUE

/client
	var/displaying_cpu_debug = FALSE

/atom/movable/screen/usage_display/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	controls = new(null, null)
	controls.parent = src
	graph_display = new(null, null)
	graph_display.setup()
	graph_display.set_display_mode(USAGE_DISPLAY_COMPLETE_CPU)

/atom/movable/screen/usage_display/Destroy()
	QDEL_NULL(controls)
	QDEL_NULL(graph_display)
	return ..()

/atom/movable/screen/usage_display/proc/update_display()
	if(viewer_count <= 0)
		return
	graph_display.refresh_thresholds()

	var/data_bad_text = GLOB.auxcpu_loaded ? "" : " (INACCURATE)"
	var/datum/tick_holder/tick_info = GLOB.tick_info
	if(!tick_info)
		return
	var/list/cpu_values = tick_info.cpu_values
	var/list/mc_start_usage = tick_info.mc_start_usage
	var/list/mc_usage = tick_info.mc_usage
	var/list/post_mc_usage = tick_info.post_mc_usage
	var/list/pre_tick_cpu_usage = tick_info.pre_tick_cpu_usage
	var/list/tick_cpu_usage = tick_info.tick_cpu_usage
	var/list/maptick_usage = tick_info.maptick_usage
	var/list/verb_cost = tick_info.verb_cost
	var/list/last_verb_ran = tick_info.last_verb_ran
	var/last_index = TICK_INFO_TICK2INDEX(DS2TICKS(world.time) - 1)
	var/full_time = TICKS2DS(TICK_INFO_SIZE) / 10 // convert from ticks to seconds
	var/focused_mc_entry = "[graph_display.focused_mc_entry]" || "None"
	focused_mc_entry = replacetext(focused_mc_entry, "/datum/controller/subsystem/", "")

	controls.maptext = "<div style=\"background-color:#FFFFFF; color:#000000;\">\
		Toggles: \
			<a href='byond://?src=[REF(src)];act=toggle_compensation'>CPU Compensation [GLOB.attempt_corrective_cpu]</a> \
			<a href='byond://?src=[REF(src)];act=toggle_mc_limit'>Dynamic MC Limit [GLOB.use_dynamic_mc_limit]</a> \
			<a href='byond://?src=[REF(src)];act=toggle_graph'>CPU Graphing [display_graph]</a> \
			<span style=\"color:[GLOB.cpu_recorder.recording ? "#FF0000" : "#000000"];\">\
				<a href='byond://?src=[REF(src)];act=toggle_recording'>REC [GLOB.cpu_recorder.recording ? "ON [GLOB.cpu_recorder.ticks_logged]" : "OFF"]</a></span>\n\
		Glide: ([GLOB.glide_size_multiplier])\n\
		Graph: \
			Displaying \[<a href='byond://?src=[REF(src)];act=set_graph_mode'>[graph_display.display_mode]</a>\] \
			<a href='byond://?src=[REF(src)];act=freeze_graph'>[graph_display.frozen ? "Thaw" : "Freeze"]</a> \
			Max Displayable Value \[<a href='byond://?src=[REF(src)];act=set_graph_scale'>[graph_display.max_displayable_cpu]</a>\]\
			[graph_display.display_mode == USAGE_DISPLAY_MC ? " Focused MC Entry \[<a href='byond://?src=[REF(src)];act=focus_mc'>[focused_mc_entry]</a>\]" : ""]\
	</div>"
	maptext = "<div style=\"background-color:#FFFFFF; color:#000000;\">\
		Tick: [FORMAT_CPU(world.time / world.tick_lag)]\n\
		Floor: <a href='byond://?src=[REF(src)];act=set_floor'>[GLOB.floor_cpu]</a>\n\
		Sustain: <a href='byond://?src=[REF(src)];act=set_sustain_cpu'>[GLOB.sustain_cpu]</a> \
			<a href='byond://?src=[REF(src)];act=set_sustain_chance'>[GLOB.sustain_cpu_chance]%</a>\n\
		Spike: <a href='byond://?src=[REF(src)];act=set_spike'>[GLOB.spike_cpu]</a>\n\
		Glide Ratio: <a href='byond://?src=[REF(src)];act=set_glide_ratio'>[GLOB.glide_threshold_ratio]</a>%\n\
		Correction Ideal: <a href='byond://?src=[REF(src)];act=set_corrective_target'>[FORMAT_CPU(GLOB.corrective_cpu_target)]</a>\n\
		Correction Ratio: <a href='byond://?src=[REF(src)];act=set_corrective_ratio'>[GLOB.corrective_cpu_ratio]</a>%\n\
		Correction Target: [FORMAT_CPU(GLOB.corrective_cpu_threshold)]\n\
		Correction Distance: [FORMAT_CPU(GLOB.corrective_cpu_target - cpu_values[last_index])]\n\
		Correction Cost: [FORMAT_CPU(GLOB.corrective_cpu_cost)]\n\
		Frame Behind CPU[data_bad_text]: [FORMAT_CPU(cpu_values[last_index])]\n\
		Frame Behind Sleep: [FORMAT_CPU(mc_start_usage[last_index])]\n\
		Frame Behind MC: [FORMAT_CPU(max(mc_usage))]\n\
		Frame Behind Post MC: [FORMAT_CPU(max(post_mc_usage))]\n\
		Frame Behind Pre Tick: [FORMAT_CPU(pre_tick_cpu_usage[last_index])]\n\
		Frame Behind Tick: [FORMAT_CPU(tick_cpu_usage[last_index])]\n\
		Frame Behind Maptick[data_bad_text]: [FORMAT_CPU(maptick_usage[last_index])]\n\
		Frame Behind Verb: [FORMAT_CPU(verb_cost[last_index])]\n\
		Frame Behind Last Ran Verb: [FORMAT_CPU(last_verb_ran[last_index])]\n\
		<div style=\"color:#FF0000;\">\
			Max CPU[data_bad_text] [full_time]s: [FORMAT_CPU(max(cpu_values))]\n\
			Max Sleep [full_time]s: [FORMAT_CPU(max(mc_start_usage))]\n\
			Max MC [full_time]s: [FORMAT_CPU(max(mc_usage))]\n\
			Max Post MC [full_time]s: [FORMAT_CPU(max(post_mc_usage))]\n\
			Max Pre Tick [full_time]s: [FORMAT_CPU(max(pre_tick_cpu_usage))]\n\
			Max Tick [full_time]s: [FORMAT_CPU(max(tick_cpu_usage))]\n\
			Max Map[data_bad_text] [full_time]s: [FORMAT_CPU(max(maptick_usage))]\n\
			Max Verb [full_time]s: [FORMAT_CPU(max(verb_cost))]\n\
			Max Last Ran Verb [full_time]s: [FORMAT_CPU(max(last_verb_ran))]\n\
		</div>\
		<div style=\"color:#0096FF;\">\
			Min CPU[data_bad_text] [full_time]s: [FORMAT_CPU(min(cpu_values))]\n\
			Min Sleep [full_time]s: [FORMAT_CPU(min(mc_start_usage))]\n\
			Min MC [full_time]s: [FORMAT_CPU(min(mc_usage))]\n\
			Min Post MC [full_time]s: [FORMAT_CPU(min(post_mc_usage))]\n\
			Min Pre Tick [full_time]: [FORMAT_CPU(min(pre_tick_cpu_usage))]\n\
			Min Tick [full_time]s: [FORMAT_CPU(min(tick_cpu_usage))]\n\
			Min Map[data_bad_text] [full_time]s: [FORMAT_CPU(min(maptick_usage))]\n\
			Min Verb [full_time]s: [FORMAT_CPU(min(verb_cost))]\n\
			Min Last Ran Verb [full_time]s: [FORMAT_CPU(min(last_verb_ran))]\
		</div>\
	</div>"

/atom/movable/screen/usage_display/proc/toggle_cpu_debug(client/modify)
	if(!modify)
		return
	if(modify.displaying_cpu_debug) // I am lazy and this is a cold path
		viewer_count -= 1
		modify.screen -= src
		modify.screen -= graph_display
		modify.screen -= controls
		UnregisterSignal(modify, COMSIG_QDELETING)
		modify.displaying_cpu_debug = FALSE
	else
		viewer_count += 1
		modify.screen += src
		modify.screen += graph_display
		modify.screen += controls
		RegisterSignal(modify, COMSIG_QDELETING, PROC_REF(client_disconnected))
		modify.displaying_cpu_debug = TRUE
		if(viewer_count == 1)
			graph_display.clear_values()

	// Sync our graphing plane master's visibility with the client's debug state
	var/datum/hud/debug_hud = modify.mob?.hud_used
	var/atom/movable/screen/plane_master/graphing/pm = debug_hud?.plane_masters["[GRAPHING_PLANE]"]
	pm?.backdrop(modify.mob)

/atom/movable/screen/usage_display/proc/client_disconnected(client/disconnected)
	SIGNAL_HANDLER
	toggle_cpu_debug(disconnected)

/atom/movable/screen/usage_display_controls
	screen_loc = "LEFT+4:16, TOP:-8"
	plane = GRAPHING_PLANE
	layer = CPU_DISPLAY_LAYER
	maptext_width = 512
	maptext_height = 512
	alpha = 220
	var/atom/movable/screen/usage_display/parent

/atom/movable/screen/usage_display_controls/Destroy()
	parent = null
	return ..()

/atom/movable/screen/usage_display_controls/Topic(href, list/href_list)
	parent.Topic(href, href_list)

/atom/movable/screen/usage_display/Topic(href, list/href_list)
	if(!check_rights(R_DEBUG) || !check_rights(R_SERVER))
		return FALSE
	switch(href_list["act"])
		if("toggle_compensation")
			GLOB.attempt_corrective_cpu = !GLOB.attempt_corrective_cpu
			return TRUE
		if("toggle_mc_limit")
			GLOB.use_dynamic_mc_limit = !GLOB.use_dynamic_mc_limit
			return TRUE
		if("toggle_graph")
			display_graph = !display_graph
			if(display_graph)
				graph_display.alpha = 255
			else
				graph_display.alpha = 0
			return TRUE
		if("toggle_recording")
			// [SOLARIS] - per-tick cpu recording to the round's log dir
			if(GLOB.cpu_recorder.recording)
				GLOB.cpu_recorder.stop_recording()
				to_chat(usr, span_notice("CPU recording stopped: [GLOB.cpu_recorder.ticks_logged] ticks written to [GLOB.cpu_recorder.recording_path]"))
			else
				if(GLOB.cpu_recorder.start_recording())
					to_chat(usr, span_notice("CPU recording started, appending to [GLOB.cpu_recorder.recording_path]"))
				else
					to_chat(usr, span_warning("CPU recording failed to start"))
			return TRUE
		if("set_graph_mode")
			var/mode = tgui_input_list(usr, "What kind of info should we graph?", "Graph Mode?", graph_options)
			if(!(mode in graph_options))
				return
			graph_display.set_display_mode(mode)
			return TRUE
		if("set_graph_scale")
			var/current_value = graph_display.max_displayable_cpu
			// [SOLARIS] - native input, NumberInputModal is missing from this base's tgui bundle
			var/max_cpu = input(usr, "What should be the highest displayable cpu value?", "Max CPU", current_value) as null|num
			if(!isnum(max_cpu) || max_cpu < 1)
				return TRUE
			graph_display.set_max_display(max_cpu)
			return TRUE
		if("freeze_graph")
			graph_display.set_frozen(!graph_display.frozen)
			return TRUE
		if("focus_mc")
			var/list/mc_options = list()
			mc_options += "None in particular"
			mc_options += "Internal"
			for(var/datum/controller/subsystem/subsystem_path as anything in sortTim(subtypesof(/datum/controller/subsystem), GLOBAL_PROC_REF(cmp_text_asc)))
				if(subsystem_path::flags & SS_NO_FIRE)
					continue
				mc_options += subsystem_path
			var/focused_entry = tgui_input_list(usr, "What part of the MC do you want to focus on?", "Focused Entry?", mc_options)
			if(!(focused_entry in mc_options))
				return TRUE
			if(focused_entry == "None in particular")
				graph_display.set_focused_mc(null)
				return TRUE
			graph_display.set_focused_mc(focused_entry)
			return TRUE
		if("set_corrective_target")
			// [SOLARIS] - native input, NumberInputModal is missing from this base's tgui bundle
			var/target_cpu = input(usr, "What should we attempt to correct up to?", "Correct CPU", GLOB.corrective_cpu_target) as null|num
			if(isnull(target_cpu))
				return TRUE
			GLOB.corrective_cpu_target = max(target_cpu, 0)
			return TRUE
		if("set_corrective_ratio")
			var/target_ratio = input(usr, "How tolerant of distance from the average should we be?", "Correct CPU Ratio", GLOB.corrective_cpu_ratio) as null|num
			if(isnull(target_ratio))
				return TRUE
			GLOB.corrective_cpu_ratio = max(target_ratio, 0)
			return TRUE
		if("set_glide_ratio")
			var/target_ratio = input(usr, "How tolerant of distance from the average should we be?", "Glide Ratio", GLOB.glide_threshold_ratio) as null|num
			if(isnull(target_ratio))
				return TRUE
			GLOB.glide_threshold_ratio = max(target_ratio, 0)
			return TRUE
		if("set_floor")
			var/floor_cpu = input(usr, "How low should we allow the cpu to go?", "Floor CPU", 0) as null|num
			if(isnull(floor_cpu))
				return TRUE
			GLOB.floor_cpu = max(floor_cpu, 0)
			return TRUE
		if("set_sustain_cpu")
			var/sustain_cpu = input(usr, "What should we randomly set our cpu to?", "Sustain CPU", 0) as null|num
			if(isnull(sustain_cpu))
				return TRUE
			GLOB.sustain_cpu = max(sustain_cpu, 0)
			return TRUE
		if("set_sustain_chance")
			var/sustain_cpu_chance = input(usr, "What % of the time should we floor at Sustain CPU", "Sustain CPU %", 0) as null|num
			if(isnull(sustain_cpu_chance))
				return TRUE
			GLOB.sustain_cpu_chance = clamp(sustain_cpu_chance, 0, 100)
			return TRUE
		if("set_spike")
			var/spike_cpu = input(usr, "How high should we spike cpu usage", "Spike CPU", 0) as null|num
			if(isnull(spike_cpu))
				return TRUE
			GLOB.spike_cpu = max(spike_cpu, 0)
			return TRUE
