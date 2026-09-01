////////////////////////////////////////////////
//
//
// Переключатели чатиков. Да...
//
//
////////////////////////////////////////////////

/datum/chat_settings_panel/New(user)
	ui_interact(user)

/datum/chat_settings_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChatSettingsPanel")
		ui.open()

/datum/chat_settings_panel/ui_status(mob/user)
	return UI_INTERACTIVE

/datum/chat_settings_panel/ui_data(mob/user)
	. = list()
	.["ghost"] = list()
	for(var/key in GLOB.ghost_chat_settings_list_desc)
		.["ghost"] += list(list(
			"key" = GLOB.ghost_chat_settings_list_desc[key],
			"enabled" = !(user.client.prefs.chat_toggles & GLOB.ghost_chat_settings_list_desc[key]),
			"desc" = key,
			"type" = "chat"
		))
	for(var/key in GLOB.ghost_events_settings_list_desc)
		.["ghost"] += list(list(
			"key" = GLOB.ghost_events_settings_list_desc[key],
			"enabled" = (user.client.prefs.toggles & GLOB.ghost_events_settings_list_desc[key]),
			"desc" = key,
			"type" = "events"
		))
	.["chat"] = list()
	for(var/key in GLOB.chat_settings_list_desc)
		.["chat"] += list(list(
			"key" = GLOB.chat_settings_list_desc[key],
			"enabled" = !(user.client.prefs.chat_toggles & GLOB.chat_settings_list_desc[key]),
			"desc" = key,
			"type" = "chat"
		))

/datum/chat_settings_panel/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch (action)
		if ("chat")
			var/key = params["key"]
			if (key)
				usr.client.prefs.chat_toggles ^= key
		if ("events")
			var/key = params["key"]
			if (key)
				usr.client.prefs.toggles ^= key

	usr.client.prefs.save_preferences()
	. = TRUE

////////////////////////////////////////////////
//
//
//	Панелька для управления звуками в игре.
//
//
////////////////////////////////////////////////

/datum/sound_panel/New(user)
	ui_interact(user)

/datum/sound_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SoundPanelSettings")
		ui.open()

/datum/sound_panel/ui_status(mob/user)
	return UI_INTERACTIVE

/datum/sound_panel
	var/playing_flag = 0

/datum/sound_panel/ui_data(mob/user)
	if(!user?.client)
		return

	var/client/C = user.client
	var/list/data = list()

	data["sound_volume"] = list()
	for(var/flag in C.prefs.sound_volume)
		data["sound_volume"]["[flag]"] = C.prefs.sound_volume[flag]

	data["playing_flag"] = playing_flag

	return data

/datum/sound_panel/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(!usr?.client?.prefs)
		return

	var/client/C = usr.client

	switch(action)
		if("set_volume")
			var/flag = text2num(params["flag"])
			var/volume = clamp(text2num(params["volume"]), 0, 100)
			C.prefs.sound_volume[flag] = volume
			// [MANKIND-EDIT] - MANKIND_FIXES - Рескейл всех уже играющих каналов выбранной категории при изменении громкости
			C.update_category_volume(flag, volume)
			// [/MANKIND-EDIT]

		if("test_sound")
			var/flag = text2num(params["flag"])
			var/test_sound
			switch(flag)
				if(FS_GENERAL)
					test_sound = 'sound/misc/notice1.ogg'
				if(FS_LOBBY)
					test_sound = 'sound/ambience/title1.ogg'
				if(FS_AMBIENCE)
					test_sound = 'sound/ambience/ambigen1.ogg'
				if(FS_WEAPONS)
					test_sound = 'sound/weapons/gun/rifle/skm.ogg'
				if(FS_ANNOUNCEMENTS)
					test_sound = 'sound/misc/announce.ogg'
				if(FS_INSTRUMENTS)
					test_sound = 'sound/items/bikehorn.ogg'
				if(FS_JUKEBOX)
					test_sound = 'sound/ambience/title2.ogg'
				if(FS_RADIO)
					test_sound = 'sound/items/radiostatic.ogg'
				if(FS_PRAYERS)
					test_sound = 'sound/effects/bodyfall1.ogg'
				if(FS_ADMIN)
					test_sound = 'sound/misc/server-ready.ogg'
				if(FS_SHIP_AMBIENCE)
					test_sound = 'sound/ambience/shipambience.ogg'
				if(FS_ENDOFROUND)
					test_sound = 'sound/roundend/boowomp.ogg'
				if(FS_VOICES)
					test_sound = 'sound/effects/meow1.ogg'
			if(test_sound)
				var/sound/test_sound_to_play = sound(test_sound)
				test_sound_to_play.volume = round(100 * (C.prefs.sound_volume[flag] / 100))
				test_sound_to_play.channel = CHANNEL_ADMIN
				test_sound_to_play.wait = 0
				if(test_sound_to_play.volume > 0)
					SEND_SOUND(usr, test_sound_to_play)
				playing_flag = flag

		if("stop_sound")
			SEND_SOUND(usr, sound(null, repeat = 0, wait = 0, channel = CHANNEL_ADMIN))
			playing_flag = 0

	C.prefs.save_preferences()
	. = TRUE
