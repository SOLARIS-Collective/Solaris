GLOBAL_VAR_INIT(OOC_COLOR, null)//If this is null, use the CSS for OOC. Otherwise, use a custom colour.
GLOBAL_VAR_INIT(normal_ooc_colour, "#002eb8")

/client/verb/ooc(msg as text)
	set name = "OOC" //Gave this shit a shorter name so you only have to time out "ooc" rather than "ooc message" to use it --NeoFite
	set category = "OOC"

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	if(!mob)
		return

	if(!holder)
		if(!GLOB.ooc_allowed)
			to_chat(src, span_danger("OOC is globally muted."))
			return
		if(!GLOB.dooc_allowed && (mob.stat == DEAD))
			to_chat(usr, span_danger("OOC for dead mobs has been turned off."))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_danger("You cannot use OOC (muted)."))
			return
	if(is_banned_from(ckey, "OOC"))
		to_chat(src, span_danger("You have been banned from OOC."))
		return
	if(QDELETED(src))
		return

	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)
	var/raw_msg = msg

	if(!msg)
		return

	msg = emoji_parse(msg)

	if((msg[1] in list(".",";",":","#")) || findtext_char(msg, "say", 1, 5))
		if(alert("Your message \"[raw_msg]\" looks like it was meant for in game communication, say it in OOC?", "Meant for OOC?", "Yes", "No") != "Yes")
			return

	if(!holder)
		if(handle_spam_prevention(msg,MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in OOC: [msg]")
			return

	if(!(prefs.chat_toggles & CHAT_OOC))
		to_chat(src, span_danger("You have OOC muted."))
		return

	mob.log_talk(raw_msg, LOG_OOC)

	var/keyname = key
	if(prefs.unlock_content)
		if(prefs.toggles & MEMBER_PUBLIC)
			keyname = "<font color='[prefs.ooccolor ? prefs.ooccolor : GLOB.normal_ooc_colour]'>[icon2html('icons/member_content.dmi', world, "blag")][keyname]</font>"
	if(prefs.custom_ooc)
		keyname = "<font color='[prefs.ooccolor ? prefs.ooccolor : GLOB.normal_ooc_colour]'>[keyname]</font>"
	if(prefs.hearted)
		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/chat)
		keyname = "[sheet.icon_tag("emoji-heart")][keyname]"
	// [MANKIND-ADD] - MANKIND_DONATE / Значения GLOB.OOC_COLOR были заменены на COLOR_OOC для возможности замены цвета для donator_tier.
	var/COLOR_OOC = GLOB.OOC_COLOR
	if(donator.donator_tier > 0)
		var/icon/donator_icon = icon('modular_mankind/_storage_icons/icons/assets/vip/ooc_icon.png')
		keyname = "[icon2html(donator_icon, world)] " + "[keyname]"
	if(donator.donator_tier > 1)
		COLOR_OOC = "CC008C"
	// [/MANKIND-ADD]
	//The linkify span classes and linkify=TRUE below make ooc text get clickable chat href links if you pass in something resembling a url
	for(var/client/C in GLOB.clients)
		if(C.prefs.chat_toggles & CHAT_OOC)
			if(holder)
				if(!holder.fakekey || C.holder)
					if(check_rights_for(src, R_ADMIN))
						to_chat(C, "[span_adminooc("[CONFIG_GET(flag/allow_admin_ooccolor) && prefs.ooccolor ? "<font color=[prefs.ooccolor]>" :"" ]<span class='prefix'>OOC:")] <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[msg]</span></span></font>", MESSAGE_TYPE_OOC)
					else
						to_chat(C, span_adminobserverooc("[span_prefix("OOC:")] <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[msg]</span>"), MESSAGE_TYPE_OOC)
				else
					if(COLOR_OOC)
						to_chat(C, span_oocplain("<font color='[COLOR_OOC]'><b>[span_prefix("OOC:")] <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[msg]</span></b></font>"), MESSAGE_TYPE_OOC)
					else
						to_chat(C, span_ooc("[span_prefix("OOC:")] <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[msg]</span>"), MESSAGE_TYPE_OOC)

		else
			if(COLOR_OOC)
					if(check_mentor())
						to_chat(C, span_oocplain("<font color='["#00b40f"]'><b>[span_prefix("OOC:")] <EM>[keyname]:</EM> <span class='message linkify'>[msg]</span></b></font>"), MESSAGE_TYPE_OOC)
					else
						to_chat(C, span_oocplain("<font color='[COLOR_OOC]'><b>[span_prefix("OOC:")] <EM>[keyname]:</EM> <span class='message linkify'>[msg]</span></b></font>"), MESSAGE_TYPE_OOC)
				else
					to_chat(C, span_ooc("[span_prefix("OOC:")] <EM>[keyname]:</EM> <span class='message linkify'>[msg]</span>"), MESSAGE_TYPE_OOC)

/proc/toggle_ooc(toggle = null)
	if(toggle != null) //if we're specifically en/disabling ooc
		if(toggle != GLOB.ooc_allowed)
			GLOB.ooc_allowed = toggle
		else
			return
	else //otherwise just toggle it
		GLOB.ooc_allowed = !GLOB.ooc_allowed
	to_chat(world, "<B>The OOC channel has been globally [GLOB.ooc_allowed ? "enabled" : "disabled"].</B>")

/proc/toggle_dooc(toggle = null)
	if(toggle != null)
		if(toggle != GLOB.dooc_allowed)
			GLOB.dooc_allowed = toggle
		else
			return
	else
		GLOB.dooc_allowed = !GLOB.dooc_allowed
	to_chat(world, "<B>The Dead OOC channel has been globally [GLOB.dooc_allowed ? "enabled" : "disabled"].</B>")	// [MANKIND-ADD] - FIX_TOGGLE_DEAD_OOC

/client/proc/set_ooc(newColor as color)
	set name = "Set Player OOC Color"
	set desc = "Modifies player OOC Color"
	set category = "Server"
	GLOB.OOC_COLOR = sanitize_ooccolor(newColor)

/client/proc/reset_ooc()
	set name = "Reset Player OOC Color"
	set desc = "Returns player OOC Color to default"
	set category = "Server"
	GLOB.OOC_COLOR = null

/client/verb/colorooc()
	set name = "Set Your OOC Color"
	set category = "Preferences"

	if(!holder || !check_rights_for(src, R_ADMIN))
		if(!is_content_unlocked())
			return

	var/new_ooccolor = input(src, "Please select your OOC color.", "OOC color", prefs.ooccolor) as color|null
	if(new_ooccolor)
		prefs.ooccolor = sanitize_ooccolor(new_ooccolor)
		prefs.save_preferences()
	BLACKBOX_LOG_ADMIN_VERB("Set OOC Color")
	return

/client/verb/resetcolorooc()
	set name = "Reset Your OOC Color"
	set desc = "Returns your OOC Color to default"
	set category = "Preferences"

	if(!holder || !check_rights_for(src, R_ADMIN))
		if(!is_content_unlocked())
			return

	prefs.ooccolor = initial(prefs.ooccolor)
	prefs.save_preferences()

//Checks admin notice
/client/verb/admin_notice()
	set name = "Adminnotice"
	set category = "Admin"
	set desc ="Check the admin notice if it has been set"

	if(GLOB.admin_notice)
		to_chat(src, "[span_boldnotice("Admin Notice:")]\n \t [GLOB.admin_notice]")
	else
		to_chat(src, span_notice("There are no admin notices at the moment."))

/client/verb/motd()
	set name = "MOTD"
	set category = "OOC"
	set desc ="Check the Message of the Day"

	var/motd = global.config.motd
	if(motd)
		to_chat(src, "<div class=\"motd\">[motd]</div>", handle_whitespace=FALSE)
	else
		to_chat(src, span_notice("The Message of the Day has not been set."))

/client/proc/self_notes()
	set name = "View Admin Remarks"
	set category = "OOC"
	set desc = "View the notes that admins have written about you"

	if(!CONFIG_GET(flag/see_own_notes))
		to_chat(usr, span_notice("Sorry, that function is not enabled on this server."))
		return

	browse_messages(null, usr.ckey, null, TRUE)

/client/proc/self_playtime()
	set name = "View tracked playtime"
	set category = "OOC"
	set desc = "View the amount of playtime for roles the server has tracked."

	if(!CONFIG_GET(flag/use_exp_tracking))
		to_chat(usr, span_notice("Sorry, tracking is currently disabled."))
		return

	new /datum/job_report_menu(src, usr)

/client/proc/show_previous_roundend_report()
	set name = "Your Last Round"
	set category = "OOC"
	set desc = "View the last round end report you've seen"

	SSticker.show_roundend_report(src, report_type = PERSONAL_LAST_ROUND)

/client/proc/show_servers_last_roundend_report()
	set name = "Server's Last Round"
	set category = "OOC"
	set desc = "View the last round end report from this server"

	SSticker.show_roundend_report(src, report_type = SERVER_LAST_ROUND)

/client/verb/fit_viewport()
	set name = "Fit Viewport"
	set category = "Special Verbs" // [MANKIND-EDIT] - MANKIND_QOL - Очистка вкладки ООС, перенос части в Special Verbs
	set desc = "Fit the width of the map window to match the viewport"

	// Fetch aspect ratio
	var/view_size = getviewsize(view)
	var/aspect_ratio = view_size[1] / view_size[2]

	// Calculate desired pixel width using window size and aspect ratio
	var/sizes = params2list(winget(src, "mainwindow.split;mapwindow", "size"))
	var/map_size = splittext(sizes["mapwindow.size"], "x")
	var/height = text2num(map_size[2])
	var/desired_width = round(height * aspect_ratio)
	if (text2num(map_size[1]) == desired_width)
		// Nothing to do
		return

	var/split_size = splittext(sizes["mainwindow.split.size"], "x")
	var/split_width = text2num(split_size[1])

	// Calculate and apply a best estimate
	// +4 pixels are for the width of the splitter's handle
	var/pct = 100 * (desired_width + 4) / split_width
	winset(src, "mainwindow.split", "splitter=[pct]")

	// Apply an ever-lowering offset until we finish or fail
	var/delta
	for(var/safety in 1 to 10)
		var/after_size = winget(src, "mapwindow", "size")
		map_size = splittext(after_size, "x")
		var/got_width = text2num(map_size[1])

		if (got_width == desired_width)
			// success
			return
		else if (isnull(delta))
			// calculate a probable delta value based on the difference
			delta = 100 * (desired_width - got_width) / split_width
		else if ((delta > 0 && got_width > desired_width) || (delta < 0 && got_width < desired_width))
			// if we overshot, halve the delta and reverse direction
			delta = -delta/2

		pct += delta
		winset(src, "mainwindow.split", "splitter=[pct]")


/client/verb/policy()
	set name = "Show Policy"
	set desc = "Show special server rules related to your current character."
	// [MANKIND-REMOVE] - MANKIND_QOL - Очистка вкладки ООС, перенос части в Special Verbs
	set category = "OOC"
	// [/MANKIND-REMOVE]

	//Collect keywords
	var/list/keywords = mob.get_policy_keywords()
	var/header = get_policy(POLICY_VERB_HEADER)
	var/list/policytext = list(header)
	var/anything = FALSE
	for(var/keyword in keywords)
		var/p = get_policy(keyword)
		if(p)
			policytext += p
			policytext += "<hr>"
			anything = TRUE
	if(!anything)
		policytext += "No related rules found."

	var/datum/browser/browser = new(usr, "policy", "Server Policy", 600, 500)
	browser.set_content(policytext.Join(""))
	browser.open()

/client/verb/fix_stat_panel()
	set name = "Fix Stat Panel"
	set hidden = TRUE

	init_verbs()

/client/verb/speech_format_help()
	set name = "Speech Format Help"
	set category = "OOC"
	set desc = "Chat formatting help"

	var/message

	message += "[span_big("You can add emphasis to your text by surrounding words or sentences in certain characters.")]\n"
	message += "+bold+, _underline_, and |italics| are supported.\n\n"
	message += "[span_big("You can made custom saymods by doing <i>say 'screams*HELP IM DYING!'</i>. This works over the radio, and can be used to emote over the radio.")]\n"
	message += "Example: say ';laughs maniacally!*' >> \[Common] Joe Schmoe laughs maniacally!"

	to_chat(usr, span_notice("[message]"))
