SUBSYSTEM_DEF(autotransfer)
	name = "Autotransfer Vote"
	flags = SS_KEEP_TIMING | SS_BACKGROUND
	wait = 1 MINUTES

	var/next_transfer_time = 0 // PENTEST START - World time when the next transfer vote should occur
	var/list/schedule_entries = list() // Parsed schedule entries
	var/extend_count = 0 // PENTEST END - Number of times the transfer has been extended (max 2)

/datum/controller/subsystem/autotransfer/Initialize(timeofday)
	load_schedule() // PENTEST CHANGE - Load schedule on subsystem initialization
	return ..()

/// PENTEST ADDITION START - Called when the config is reloaded
/datum/controller/subsystem/autotransfer/OnConfigLoad()
	load_schedule()
	message_admins("Autotransfer schedule has been reloaded from config.")

/// Loads the schedule from config and calculates next transfer time
/datum/controller/subsystem/autotransfer/proc/load_schedule()
	var/schedule_string = CONFIG_GET(string/vote_autotransfer_schedule)

	if(schedule_string)
		// Use scheduled system
		if(parse_schedule(schedule_string))
			calculate_next_transfer()
			// Log current time and schedule
			log_game("Current time: [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] (server local time)")
			for(var/list/entry in schedule_entries)
				var/day_name
				switch(entry["day"])
					if(0)
						day_name = "Sunday"
					if(1)
						day_name = "Monday"
					if(2)
						day_name = "Tuesday"
					if(3)
						day_name = "Wednesday"
					if(4)
						day_name = "Thursday"
					if(5)
						day_name = "Friday"
					if(6)
						day_name = "Saturday"
				log_game("Scheduled autotransfer: [day_name] at [entry["hours"]]:[entry["minutes"]]")
			// Invalidate stat panel cache so it updates immediately
			if(SSstatpanels)
				SSstatpanels.last_autotransfer_update = 0
		else
			log_config("ERROR: Invalid VOTE_AUTOTRANSFER_SCHEDULE format. Falling back to cooldown system.")
			// Fall back to cooldown system
			next_transfer_time = world.realtime + CONFIG_GET(number/vote_autotransfer_initial) // Both in deciseconds
			// Invalidate stat panel cache
			if(SSstatpanels)
				SSstatpanels.last_autotransfer_update = 0
	else
		// Use cooldown-based system (legacy)
		next_transfer_time = world.realtime + CONFIG_GET(number/vote_autotransfer_initial) // Both in deciseconds
		log_game("Autotransfer using legacy cooldown system.")
		// Invalidate stat panel cache
		if(SSstatpanels)
			SSstatpanels.last_autotransfer_update = 0

/// Parses the schedule string into a list of schedule entries
/// Returns TRUE if successful, FALSE if invalid format
/datum/controller/subsystem/autotransfer/proc/parse_schedule(schedule_string)
	if(!schedule_string)
		return FALSE

	schedule_entries = list()
	var/list/entries = splittext(schedule_string, ",")

	for(var/entry_text in entries)
		entry_text = trim(entry_text)
		if(!entry_text)
			continue

		var/list/parts = splittext(entry_text, ":")
		if(!parts.len || parts.len % 2 != 0)
			return FALSE

		for(var/i = 1; i <= parts.len; i += 2)
			var/day_name = trim(parts[i])
			var/time_string = trim(parts[i+1])

			// Convert day name to number (0 = Sunday, 6 = Saturday)
			var/day_num = -1
			switch(lowertext(day_name))
				if("sunday")
					day_num = 0
				if("monday")
					day_num = 1
				if("tuesday")
					day_num = 2
				if("wednesday")
					day_num = 3
				if("thursday")
					day_num = 4
				if("friday")
					day_num = 5
				if("saturday")
					day_num = 6

			if(day_num == -1)
				return FALSE

			// Parse time (HHMM format)
			if(length(time_string) != 4)
				return FALSE

			var/hours = text2num(copytext(time_string, 1, 3))
			var/minutes = text2num(copytext(time_string, 3, 5))

			if(isnull(hours) || isnull(minutes) || hours < 0 || hours > 23 || minutes < 0 || minutes > 59)
				return FALSE

			schedule_entries += list(list("day" = day_num, "hours" = hours, "minutes" = minutes))

	if(!schedule_entries.len)
		return FALSE

	return TRUE

/// Calculates the next transfer time based on the schedule
/datum/controller/subsystem/autotransfer/proc/calculate_next_transfer()
	extend_count = 0
	if(!schedule_entries.len)
		return

	// Get current real time
	var/current_time = world.realtime // world.realtime is in deciseconds in this environment
	var/current_year = text2num(time2text(current_time, "YYYY"))
	var/current_month = text2num(time2text(current_time, "MM"))
	var/current_day = text2num(time2text(current_time, "DD"))
	var/current_hour = text2num(time2text(current_time, "hh"))
	var/current_minute = text2num(time2text(current_time, "mm"))
	var/current_weekday = day_of_week(current_year, current_month, current_day)

	var/closest_time = null
	var/smallest_diff = INFINITY

	// Check all schedule entries for the next upcoming one
	for(var/list/entry in schedule_entries)
		var/target_weekday = entry["day"]
		var/target_hour = entry["hours"]
		var/target_minute = entry["minutes"]

		// Calculate day offset until this schedule entry
		var/day_offset = target_weekday - current_weekday
		if(day_offset < 0)
			day_offset += 7 // Next week
		else if(day_offset == 0)
			// Same day - check if time has passed
			if(target_hour < current_hour || (target_hour == current_hour && target_minute <= current_minute))
				day_offset = 7 // Next week

		// Calculate the exact time for this entry (in deciseconds from now)
		var/time_until_transfer = 0
		time_until_transfer += day_offset * 24 * 3600 * 10
		time_until_transfer += (target_hour - current_hour) * 3600 * 10
		time_until_transfer += (target_minute - current_minute) * 60 * 10

		if(time_until_transfer > 0 && time_until_transfer < smallest_diff)
			smallest_diff = time_until_transfer
			closest_time = current_time + time_until_transfer

	if(!isnull(closest_time))
		next_transfer_time = world.realtime + smallest_diff // Both in deciseconds
		// Log the next scheduled transfer
		var/next_time_text = time2text(closest_time, "DDD, MMM DD YYYY hh:mm")
		log_game("Next autotransfer vote scheduled for: [next_time_text] (server local time)")

/// Extends the next transfer by 30 minutes and increments extend counter
/datum/controller/subsystem/autotransfer/proc/extend_next_transfer()
	extend_count++
	next_transfer_time = world.realtime + 30 MINUTES // 30 minutes in deciseconds
	log_game("Autotransfer extended by 30 minutes due to player vote. (Extension [extend_count]/2)")
	to_chat(world, span_infoplain("<font color='purple'><b>Round extended by 30 minutes due to player vote. ([extend_count]/2 extensions used)</b></font>"))
	// Invalidate stat panel cache
	if(SSstatpanels)
		SSstatpanels.last_autotransfer_update = 0

/// Returns the day of week for a given date (0 = Sunday, 6 = Saturday)
/// Uses Zeller's Congruence algorithm
/datum/controller/subsystem/autotransfer/proc/day_of_week(year, month, day)
	if(month < 3)
		month += 12
		year--

	var/century = round(year / 100)
	year = year % 100

	var/weekday = (day + round((13 * (month + 1)) / 5) + year + round(year / 4) + round(century / 4) - 2 * century) % 7

	// Convert to 0 = Sunday format
	weekday = (weekday + 6) % 7

	return weekday
// PENTEST ADDITION END

/datum/controller/subsystem/autotransfer/fire()
	//PENTEST ADDITION - Check if schedule is enabled and if it's time for the next transfer vote
	var/schedule_string = CONFIG_GET(string/vote_autotransfer_schedule)

	if(schedule_string)
		// Scheduled system
		if(world.realtime >= next_transfer_time)
			// Delay the vote if there's already a vote in progress
			if(SSvote.current_vote)
				next_transfer_time = world.realtime + SSvote.current_vote.time_remaining + 10 SECONDS
			else
				if(extend_count >= 2)
					SSshuttle.request_jump()
					extend_count = 0
					calculate_next_transfer()
					// Invalidate stat panel cache
					if(SSstatpanels)
						SSstatpanels.last_autotransfer_update = 0
				else
					extend_count = 0
					SSvote.initiate_vote(/datum/vote/transfer_vote, "The Server", forced = TRUE)
					calculate_next_transfer()
					// Invalidate stat panel cache
					if(SSstatpanels)
						SSstatpanels.last_autotransfer_update = 0
	else
		// Legacy cooldown system
		if(world.realtime >= next_transfer_time)
			// Delay the vote if there's already a vote in progress
			if(SSvote.current_vote)
				next_transfer_time = world.realtime + SSvote.current_vote.time_remaining + 10 SECONDS
			else
				if(extend_count >= 2)
					SSshuttle.request_jump()
					extend_count = 0
					next_transfer_time = world.realtime + (CONFIG_GET(number/vote_autotransfer_interval) / 10)
					// Invalidate stat panel cache
					if(SSstatpanels)
						SSstatpanels.last_autotransfer_update = 0
				else
					extend_count = 0
					SSvote.initiate_vote(/datum/vote/transfer_vote, "The Server", forced = TRUE)
					next_transfer_time = world.realtime + (CONFIG_GET(number/vote_autotransfer_interval) / 10) // Use real time
					// Invalidate stat panel cache
					if(SSstatpanels)
						SSstatpanels.last_autotransfer_update = 0
// PENTEST END

/datum/controller/subsystem/autotransfer/Recover()
	// PENTEST ADDITION - Ensure that the subsystem's variables are up to date after a crash or reload
	next_transfer_time = SSautotransfer.next_transfer_time
	schedule_entries = SSautotransfer.schedule_entries
	extend_count = SSautotransfer.extend_count
	// PENTEST END
