#define ANNOUNCEMENT_DISTRESS "Distress"
#define ANNOUNCEMENT_CAPTAIN "Captain"
#define ANNOUNCEMENT_PRIORITY "Priority"

/proc/priority_announcement_style(title = "", type, sender_override)
	var/list/data = list(
		"theme" = "centcom",
		"badge" = "CENTCOM",
		"header" = "[command_name()] Update",
		"subtitle" = title,
	)

	switch(type)
		if("Priority")
			data["theme"] = "priority"
			data["badge"] = "PRIORITY"
			data["header"] = "Priority Announcement"
		if("Captain", "CommunicationsConsole")
			data["theme"] = "communications"
			data["badge"] = "COMMS"
			data["header"] = "Communications Console"
		if("RequestsConsole")
			data["theme"] = "requests"
			data["badge"] = "REQUESTS"
			data["header"] = "Requests Console"
		if("Syndicate")
			data["theme"] = "syndicate"
			data["badge"] = "SYNDICATE"
			data["header"] = "Syndicate Announcement"
		if("AI", "Silicon")
			data["theme"] = "silicon"
			data["badge"] = "SILICON"
			data["header"] = "Silicon Announcement"
		// [MANKIND-ADD] - HAIL_ANNOUNCE - Свой стиль анонса для Hail: тот же кастомный, но с бейджем HAIL вместо NOTICE.
		if("Hail")
			data["theme"] = "custom"
			data["badge"] = "HAIL"
			data["header"] = sender_override
		// [/MANKIND-ADD]
		else
			if(sender_override)
				var/sender_lower = lowertext("[sender_override]")
				var/command_lower = lowertext(command_name())
				data["theme"] = "custom"
				data["badge"] = "NOTICE"
				data["header"] = sender_override

				if(findtext(sender_lower, "central command") || findtext(sender_lower, "centcom") || findtext(sender_lower, command_lower))
					data["theme"] = "centcom"
					data["badge"] = "CENTCOM"

	return data

/proc/build_priority_announcement(text, title = "", type, sender_override, has_important_message)
	var/list/style = priority_announcement_style(title, type, sender_override)
	var/theme = style["theme"]
	var/header_text = style["header"]
	var/subtitle_text = style["subtitle"]
	var/badge_text = style["badge"]
	var/list/classes = list(
		"priority_announcement",
		"priority_announcement--[theme]",
	)

	if(has_important_message)
		classes += "priority_announcement--important"

	var/class_string = jointext(classes, " ")
	var/header = html_encode(header_text)
	var/subtitle = html_encode(subtitle_text)
	var/badge = html_encode(badge_text)
	var/body

	body = "<span class='priority_announcement__body'>[html_encode(text)]</span>"

	var/announcement = "<span class='[class_string]'>"
	announcement += "<span class='priority_announcement__badge'>[badge]</span>"
	announcement += "<span class='priority_announcement__header'>"
	announcement += "<span class='priority_announcement__source'>[header]</span>"

	if(length(subtitle_text))
		announcement += "<span class='priority_announcement__title'>[subtitle]</span>"

	announcement += "</span>"
	announcement += body
	announcement += "</span>"

	return announcement

/proc/priority_announce(text, title = "", sound = 'sound/ai/attention.ogg', type, sender_override, auth_id, zlevel, has_important_message)
	if(!text)
		return

	var/announcement

	if(!sound)
		sound = 'sound/ai/attention.ogg'

	if(type == "Captain" || type == "CommunicationsConsole")
		if(!length(title))
			title = "Station Announcement"
		GLOB.news_network.SubmitArticle(html_encode(text), title, "Station Announcements", null)
	else if(type == "Syndicate")
		GLOB.news_network.SubmitArticle(html_encode(text), "Syndicate Announcement", "Station Announcements", null)
	else if(type != "Priority" && type != "RequestsConsole" && type != "AI" && type != "Silicon")
		if(!sender_override)
			if(title == "")
				GLOB.news_network.SubmitArticle(text, "Central Command Update", "Station Announcements", null)
			else
				GLOB.news_network.SubmitArticle(title + "<br><br>" + text, "Central Command Update", "Station Announcements", null)

	announcement = build_priority_announcement(text, title, type, sender_override, has_important_message)

	if(auth_id) //WS Edit - Make cap's announcement use logged-in name
		announcement += "[span_alert("-[auth_id]")]<br>" //WS Edit - Make cap's announcement use logged-in name

	var/sound/S = sound(sound)
	S.environment = SOUND_ENVIRONMENT_CONCERT_HALL
	for(var/mob/M in GLOB.player_list)
		if(isnewplayer(M) || !M.can_hear())
			continue

		if(zlevel && (M.virtual_z() != zlevel)) // If a z-level is specified and the mob's z does not equal it
			continue

		to_chat(M, announcement)
		if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
			// [MANKIND-EDIT] - MANKIND_FIXES - Применяем масштабирование громкости по категории Announcements
			M.send_sound_scaled(S, FS_ANNOUNCEMENTS)
			// [/MANKIND-EDIT]

/proc/print_command_report(text = "", title = null, announce=TRUE)
	if(!title)
		title = "Classified [command_name()] Update"

	if(announce)
		priority_announce("A report has been downloaded and printed out at all communications consoles.", "Incoming Classified Message", 'sound/ai/commandreport.ogg', has_important_message = TRUE)

	var/datum/comm_message/M  = new
	M.title = title
	M.content =  text

	SScommunications.send_message(M)

/proc/minor_announce(message, title = "Attention:", alert, mob/from, zlevel)
	if(!message)
		return

	var/sound/S = sound(alert ? 'sound/misc/notice1.ogg' : 'sound/misc/notice2.ogg')
	S.environment = SOUND_ENVIRONMENT_CONCERT_HALL
	for(var/mob/M in GLOB.player_list)
		if(isnewplayer(M) || !M.can_hear())
			continue

		if(zlevel && (M.virtual_z() != zlevel)) // If a z-level is specified and the mob's z does not equal it
			continue

		to_chat(M, "[span_minorannounce("<font color = red>[title]</font color><BR>[message]")]<BR>[from ? "[span_alert("-[from.name] ([from.job])")]" : null]")
		if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
			SEND_SOUND(M, S)

/proc/create_distress_beacon(datum/overmap/ship/ship, distress_message)
	if(!ship)
		return
	var/text = "A distress beacon has been launched by [ship.name], at sector '[ship.current_overmap]' co-ordinates [ship.x || ship.docked_to.x]/[ship.y || ship.docked_to.y]. [distress_message ? "Message is as follows:" : "No further information available."]"
	priority_announce(text, distress_message, 'sound/effects/distress.ogg', ANNOUNCEMENT_DISTRESS, zlevel = 0)

/proc/build_system_notice(title, body, theme = "notice", label = null, focus = null)
	var/list/classes = list(
		"system_notice",
		"system_notice--[theme]",
	)
	var/class_string = jointext(classes, " ")
	var/announcement = "<span class='[class_string]'>"

	if(label)
		announcement += "<span class='system_notice__label'>[html_encode(label)]</span>"

	announcement += "<span class='system_notice__title'>[html_encode(title)]</span>"

	if(focus)
		announcement += "<span class='system_notice__focus'>[html_encode(focus)]</span>"

	announcement += "<span class='system_notice__body'>[html_encode(body)]</span>"
	announcement += "</span>"

	return announcement

/proc/get_security_level_notice_theme(level)
	if(!isnum(level))
		level = seclevel2num(level)

	switch(level)
		if(SEC_LEVEL_GREEN)
			return "code-green"
		if(SEC_LEVEL_BLUE)
			return "code-blue"
		if(SEC_LEVEL_RED)
			return "code-red"
		if(SEC_LEVEL_DELTA)
			return "code-delta"
		else
			return "code-amber"

/proc/get_security_level_notice_name(level)
	if(!isnum(level))
		level = seclevel2num(level)

	switch(level)
		if(SEC_LEVEL_GREEN)
			return "GREEN"
		if(SEC_LEVEL_BLUE)
			return "BLUE"
		if(SEC_LEVEL_RED)
			return "RED"
		if(SEC_LEVEL_DELTA)
			return "DELTA"
		else
			return "UNKNOWN"

/proc/announce_security_level_change(level, message, raised = TRUE)
	var/state_text = raised ? "SECURITY LEVEL ELEVATED" : "SECURITY LEVEL CHANGED"
	var/focus = ">> [get_security_level_notice_name(level)] <<"
	var/theme = get_security_level_notice_theme(level)
	var/html = build_system_notice(state_text, message, theme, "SECURITY LEVEL", focus)

	for(var/mob/M in GLOB.player_list)
		if(!isnewplayer(M) && M.can_hear())
			to_chat(M, html)
			if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
				if(raised)
					SEND_SOUND(M, sound('sound/misc/notice1.ogg'))
				else
					SEND_SOUND(M, sound('sound/misc/notice2.ogg'))

/proc/announce_captain_arrival(displayed_rank, captain_name)
	if(!displayed_rank)
		displayed_rank = "Captain"

	var/focus = captain_name ? ">> [displayed_rank] [captain_name] <<" : ">> [displayed_rank] <<"
	var/html = build_system_notice("COMMAND ARRIVAL", "Arrival at [station_name()] confirmed. Bridge awaiting command handover.", "captain-arrival", "COMMAND", focus)

	for(var/mob/M in GLOB.player_list)
		if(!isnewplayer(M) && M.can_hear())
			to_chat(M, html)
			if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
				SEND_SOUND(M, sound('sound/misc/notice2.ogg'))

/proc/build_ai_upload_notice(remote_access_restored = FALSE)
	if(remote_access_restored)
		return build_system_notice("UPLOAD CONNECTED", "You have been uploaded to a stationary terminal. Remote device connection restored.", "ai-upload", "AI UPLOAD", ">> ACCESS RESTORED <<")

	return build_system_notice("UPLOAD CONNECTED", "You have been uploaded to a stationary terminal. Remote access to devices from this terminal is unavailable.", "ai-upload", "AI UPLOAD", ">> LOCAL MODE <<")
