/obj/machinery/newscaster
	name = "newscaster"
	desc = "Стандартный обработчик новостной ленты. Все новости, которые вам совершенно не нужны, в одном месте!"
	icon = 'icons/obj/terminals.dmi'
	icon_state = "newscaster"
	base_icon_state = "newscaster"
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	armor = list("melee" = 50, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 30)
	max_integrity = 200
	integrity_failure = 0.25

	var/paper_remaining = 15
	var/securityCaster = FALSE
	var/unit_no = 0
	var/alert_delay = 500
	var/alert = FALSE
	var/scanned_user = "Unknown"
	var/selected_channel = null

	FASTDMM_PROP(\
		set_instance_vars(\
			pixel_x = dir == EAST ? 30 : (dir == WEST ? -30 : INSTANCE_VAR_DEFAULT),\
			pixel_y = dir == NORTH ? 30 : (dir == SOUTH ? -30 : INSTANCE_VAR_DEFAULT)\
		),\
		dir_amount = 4\
	)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/newscaster, 30)

/obj/machinery/newscaster/security_unit
	name = "security newscaster"
	securityCaster = TRUE

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/newscaster/security_unit, 30)

/obj/machinery/newscaster/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -32 : 32)
		pixel_y = (dir & 3)? (dir ==1 ? -32 : 32) : 0

	GLOB.allCasters += src
	unit_no = GLOB.allCasters.len
	update_appearance()

/obj/machinery/newscaster/Destroy()
	GLOB.allCasters -= src
	return ..()

/obj/machinery/newscaster/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	if(machine_stat & BROKEN)
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_broken", layer, plane, dir)
		return

	if(machine_stat & NOPOWER)
		return

	if(GLOB.news_network.wanted_issue.active)
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_wanted", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_wanted", layer, EMISSIVE_PLANE, dir)
	else if(alert)
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_alert", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_alert", layer, EMISSIVE_PLANE, dir)
	else
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_normal", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "[base_icon_state]_normal", layer, EMISSIVE_PLANE, dir)

/obj/machinery/newscaster/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	update_appearance()

/obj/machinery/newscaster/proc/scan_user(mob/living/user)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		if(human_user.wear_id)
			if(istype(human_user.wear_id, /obj/item/pda))
				var/obj/item/pda/P = human_user.wear_id
				if(P.id)
					scanned_user = "[P.id.registered_name]"
				else
					scanned_user = "Unknown"
			else if(istype(human_user.wear_id, /obj/item/card/id))
				var/obj/item/card/id/ID = human_user.wear_id
				scanned_user = "[ID.registered_name]"
			else if(istype(human_user.wear_id, /obj/item/storage/wallet))
				var/obj/item/storage/wallet/our_wallet = human_user.wear_id
				if(our_wallet.front_id)
					var/obj/item/card/id/ID = our_wallet.GetID()
					scanned_user = "[ID.registered_name]"
				else
					scanned_user = "Unknown"
			else
				scanned_user = "Unknown"
		else
			scanned_user = "Unknown"
	else if(issilicon(user))
		var/mob/living/silicon/ai_user = user
		scanned_user = "[ai_user.name] ([ai_user.job])"
	else
		CRASH("Invalid user for this proc")

/obj/machinery/newscaster/proc/remove_alert()
	alert = FALSE
	update_appearance()

/obj/machinery/newscaster/proc/news_alert(channel, update_alert = TRUE)
	if(channel && update_alert)
		say("Новые новости от канала: [channel]!")
		alert = TRUE
		update_appearance()
		addtimer(CALLBACK(src, PROC_REF(remove_alert)), alert_delay, TIMER_UNIQUE|TIMER_OVERRIDE)
		playsound(loc, 'sound/machines/twobeep_high.ogg', 75, TRUE)
	else if(!channel)
		say("Внимание! Объявлен новый розыск!")
		playsound(loc, 'sound/machines/warning-buzzer.ogg', 75, TRUE)

/obj/machinery/newscaster/proc/newsAlert(channel, update_alert = TRUE)
	news_alert(channel, update_alert)

/obj/machinery/newscaster/proc/create_virtual_channels()
	var/list/to_remove = list()
	for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
		if(channel.author == "Виртуальный канал")
			to_remove += channel

	for(var/datum/newscaster/feed_channel/channel in to_remove)
		GLOB.news_network.network_channels -= channel
		qdel(channel)

	if(GLOB.news_network.network_channels.len < 4)
		var/list/templates = list(
			list("channel" = "Новости смены", "title" = "Сводка дня", "body" = "Сегодня на станции было относительно спокойно. Отдел инженерии сообщает о стабильной работе всех систем.", "author" = "Корреспондент Грифона"),
			list("channel" = "Медицинские новости", "title" = "Напоминание о здоровье", "body" = "Медбай напоминает всем сотрудникам о необходимости прохождения плановых медосмотров. Помните: здоровье - это ваше богатство!", "author" = "Главврач станции"),
			list("channel" = "Отдел снабжения", "title" = "Новые поставки", "body" = "На складе появились новые поставки оборудования. Квартирмейстер просит всех ответственно относиться к имуществу компании.", "author" = "Отдел снабжения"),
			list("channel" = "Развлечения", "title" = "Спортивные новости", "body" = "В рекреационной зоне состоялся турнир по настольному теннису. Победитель получил почетный кубок и дополнительные выходные.", "author" = "Спортобозреватель")
		)

		var/channels_to_add = min(4 - GLOB.news_network.network_channels.len, templates.len)
		for(var/i in 1 to channels_to_add)
			var/list/template = templates[i]

			var/datum/newscaster/feed_channel/virtual_channel = new /datum/newscaster/feed_channel
			virtual_channel.channel_name = template["channel"]
			virtual_channel.author = "Виртуальный канал"
			virtual_channel.channel_desc = "Автоматически сгенерированный контент"
			virtual_channel.locked = TRUE

			var/datum/newscaster/feed_message/virtual_message = new /datum/newscaster/feed_message
			virtual_message.author = template["author"]
			virtual_message.body = template["body"]
			virtual_message.time_stamp = station_time_timestamp()
			virtual_message.creationTime = GLOB.news_network.lastAction
			virtual_message.message_ID = ++GLOB.news_network.message_count

			virtual_channel.messages += virtual_message
			GLOB.news_network.network_channels += virtual_channel

/obj/machinery/newscaster/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(ishuman(user) || issilicon(user))
		var/mob/living/human_or_robot_user = user
		scan_user(human_or_robot_user)
		ui = SStgui.try_update_ui(user, src, ui)
		if(!ui)
			ui = new(user, src, "PhysicalNewscaster")
			ui.open()

/obj/machinery/newscaster/ui_data(mob/user, list/params)
	var/list/data = list()
	data["scanned_user"] = scanned_user
	data["security_mode"] = securityCaster
	data["paper"] = paper_remaining
	data["user"] = list("name" = scanned_user)

	if(!selected_channel && GLOB.news_network.network_channels.len > 0)
		var/datum/newscaster/feed_channel/default_channel = GLOB.news_network.network_channels[1]
		selected_channel = default_channel.channel_ID

	var/list/channels_data = list()
	for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
		channels_data += list(list(
			"name" = channel.channel_name,
			"author" = channel.author,
			"desc" = channel.channel_desc,
			"locked" = channel.locked,
			"censored" = channel.censored,
			"ID" = channel.channel_ID
		))
	data["channels"] = channels_data

	var/list/messages_data = list()
	for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
		for(var/datum/newscaster/feed_message/message in channel.messages)
			messages_data += list(list(
				"title" = "Новость от [channel.channel_name]",
				"body" = message.body,
				"author" = message.author,
				"time" = message.time_stamp
			))
	data["messages"] = messages_data

	var/list/wanted_data = list()
	for(var/datum/newscaster/wanted_message/wanted in GLOB.news_network.wanted_issues)
		if(securityCaster || wanted.active)
			wanted_data += list(list(
				"active" = wanted.active,
				"criminal" = wanted.criminal,
				"crime" = wanted.body,
				"author" = wanted.scannedUser,
				"ID" = wanted.wanted_ID
			))
	if(!wanted_data.len)
		wanted_data += list(list("active" = FALSE))
	data["wanted"] = wanted_data

	var/current_channel_id = selected_channel
	var/list/current_channel_data = list()
	var/list/channel_messages = list()

	if(current_channel_id)
		for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
			if(channel.channel_ID == current_channel_id)
				current_channel_data = list(
					"name" = channel.channel_name,
					"desc" = channel.channel_desc,
					"author" = channel.author,
					"locked" = channel.locked,
					"censored" = channel.censored,
					"ID" = channel.channel_ID
				)
				for(var/datum/newscaster/feed_message/message in channel.messages)
					var/list/comments_data = list()
					for(var/datum/newscaster/feed_comment/comment in message.comments)
						comments_data += list(list(
							"author" = comment.author,
							"body" = comment.body,
							"time" = comment.time_stamp
						))
					channel_messages += list(list(
						"ID" = message.message_ID,
						"author" = message.author,
						"body" = message.body,
						"time" = message.time_stamp,
						"comments" = comments_data,
						"locked" = message.locked,
						"likes" = message.likes ? message.likes.len : 0,
						"dislikes" = message.dislikes ? message.dislikes.len : 0,
						"user_liked" = message.likes ? (scanned_user in message.likes) : FALSE,
						"user_disliked" = message.dislikes ? (scanned_user in message.dislikes) : FALSE
					))
				break

	data["current_channel"] = current_channel_data
	data["channel_messages"] = channel_messages
	data["viewing_channel"] = current_channel_id
	return data

/obj/machinery/newscaster/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("print_newspaper")
			if(paper_remaining > 0)
				paper_remaining--
				create_virtual_channels()
				var/mob/living/M = usr
				var/obj/item/newspaper/NP = new(get_turf(M))
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					H.put_in_hands(NP)
				NP.add_fingerprint(M)
				. = TRUE

		if("create_channel")
			var/channel_name = input(usr, "Введите название канала:", "Создание канала") as text
			if(!channel_name || length(channel_name) < 3)
				to_chat(usr, span_warning("Название канала слишком короткое!"))
				return
			var/channel_desc = input(usr, "Введите описание канала:", "Описание") as message
			if(!channel_desc)
				channel_desc = "Обычный новостной канал"
			var/locked = alert(usr, "Сделать канал приватным?", "Настройки", "Да", "Нет") == "Да"
			GLOB.news_network.CreateFeedChannel(channel_name, scanned_user, locked, 0, channel_desc)
			to_chat(usr, span_notice("Канал '[channel_name]' создан!"))
			. = TRUE

		if("create_wanted")
			if(!securityCaster)
				to_chat(usr, span_warning("Только служба безопасности может объявлять в розыск!"))
				return
			var/criminal_name = input(usr, "Введите имя преступника:", "Розыск") as text
			if(!criminal_name)
				return
			var/crime_desc = input(usr, "Опишите преступление:", "Преступление") as message
			if(!crime_desc)
				crime_desc = "Неизвестное преступление"
			var/datum/picture/picture_to_use = null
			var/attach_photo = alert(usr, "Прикрепить фото преступника?", "Розыск", "Да", "Нет") == "Да"
			if(attach_photo && ishuman(usr))
				var/mob/living/carbon/human/H = usr
				var/obj/item/held = H.get_active_held_item()
				if(istype(held, /obj/item/photo))
					var/obj/item/photo/P = held
					picture_to_use = P.picture
				else
					held = H.get_inactive_held_item()
					if(istype(held, /obj/item/photo))
						var/obj/item/photo/P = held
						picture_to_use = P.picture
					else
						to_chat(usr, span_warning("В руке нет фото. Розыск будет без фотографии."))
			GLOB.news_network.submitWanted(criminal_name, crime_desc, scanned_user, picture_to_use, 0, 1)
			to_chat(usr, span_notice("Объявлен розыск: [criminal_name][picture_to_use ? " (с фото)" : ""]"))
			. = TRUE

		if("clear_wanted")
			if(!securityCaster)
				return
			var/wanted_id = text2num(params["wanted_id"])
			if(wanted_id && GLOB.news_network.deleteWantedById(wanted_id))
				to_chat(usr, span_notice("Розыск отменен."))
			else
				GLOB.news_network.deleteWanted()
				to_chat(usr, span_notice("Все розыски отменены."))
			. = TRUE

		if("select_channel")
			var/channel_param = params["current_channel"]
			if(channel_param == "wanted")
				selected_channel = "wanted"
			else
				var/channel_id = text2num(channel_param)
				if(channel_id)
					selected_channel = channel_id
			. = TRUE

		if("add_comment")
			var/message_id = text2num(params["message_id"])
			var/comment_text = input(usr, "Введите комментарий:", "Комментарий") as message
			if(!comment_text || length(comment_text) < 1)
				return

			for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
				for(var/datum/newscaster/feed_message/message in channel.messages)
					if(message.message_ID == message_id)
						if(message.locked)
							to_chat(usr, span_warning("Комментарии к этому сообщению заблокированы."))
							return
						var/datum/newscaster/feed_comment/new_comment = new /datum/newscaster/feed_comment
						new_comment.author = scanned_user
						new_comment.body = comment_text
						new_comment.time_stamp = station_time_timestamp()
						message.comments += new_comment
						to_chat(usr, span_notice("Комментарий добавлен!"))
						. = TRUE
						return

		if("create_story")
			var/channel_id = text2num(params["channel_id"])
			if(!channel_id)
				channel_id = selected_channel
			if(!channel_id)
				to_chat(usr, span_warning("Выберите канал для публикации новости!"))
				return

			var/datum/newscaster/feed_channel/target_channel = null
			for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
				if(channel.channel_ID == channel_id)
					target_channel = channel
					break

			if(!target_channel)
				to_chat(usr, span_warning("Канал не найден!"))
				return

			if(target_channel.locked && target_channel.author != scanned_user)
				to_chat(usr, span_warning("Этот канал приватный. Только автор может публиковать новости!"))
				return

			if(target_channel.censored)
				to_chat(usr, span_warning("Этот канал заблокирован!"))
				return

			var/story_text = input(usr, "Введите текст новости:", "Новая новость") as message
			if(!story_text || length(story_text) < 10)
				to_chat(usr, span_warning("Текст новости слишком короткий!"))
				return

			GLOB.news_network.SubmitArticle(story_text, scanned_user, target_channel.channel_name, null, 0, 1)
			to_chat(usr, span_notice("Новость опубликована в канале '[target_channel.channel_name]'!"))
			. = TRUE

		if("like_message")
			var/message_id = text2num(params["message_id"])
			for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
				for(var/datum/newscaster/feed_message/message in channel.messages)
					if(message.message_ID == message_id)
						if(!message.likes)
							message.likes = list()
						if(!message.dislikes)
							message.dislikes = list()

						if(scanned_user in message.likes)
							message.likes -= scanned_user
						else
							if(scanned_user in message.dislikes)
								message.dislikes -= scanned_user
							message.likes += scanned_user
						. = TRUE
						return

		if("dislike_message")
			var/message_id = text2num(params["message_id"])
			for(var/datum/newscaster/feed_channel/channel in GLOB.news_network.network_channels)
				for(var/datum/newscaster/feed_message/message in channel.messages)
					if(message.message_ID == message_id)
						if(!message.likes)
							message.likes = list()
						if(!message.dislikes)
							message.dislikes = list()

						if(scanned_user in message.dislikes)
							message.dislikes -= scanned_user
						else
							if(scanned_user in message.likes)
								message.likes -= scanned_user
							message.dislikes += scanned_user
						. = TRUE
						return

/obj/machinery/newscaster/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		to_chat(user, span_notice("You start [anchored ? "un" : ""]securing [name]..."))
		I.play_tool_sound(src)
		if(I.use_tool(src, user, 60))
			playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
			if(machine_stat & BROKEN)
				to_chat(user, span_warning("The broken remains of [src] fall on the ground."))
				new /obj/item/stack/sheet/metal(loc, 5)
				new /obj/item/shard(loc)
				new /obj/item/shard(loc)
			else
				to_chat(user, span_notice("You [anchored ? "un" : ""]secure [name]."))
				new /obj/item/wallframe/newscaster(loc)
			qdel(src)
	else if(I.tool_behaviour == TOOL_WELDER && user.a_intent != INTENT_HARM)
		if(machine_stat & BROKEN)
			if(!I.tool_start_check(user, amount=0))
				return
			user.visible_message(span_notice("[user] ремонтирует [src]."), \
							span_notice("Вы начинаете ремонт [src]..."), \
							span_hear("Вы слышите сварку."))
			if(I.use_tool(src, user, 40, volume=50))
				if(!(machine_stat & BROKEN))
					return
				to_chat(user, span_notice("Вы ремонтируете [src]."))
				atom_integrity = max_integrity
				set_machine_stat(machine_stat & ~BROKEN)
				update_appearance()
		else
			to_chat(user, span_notice("[src] не требует ремонта."))
	else
		return ..()

/obj/machinery/newscaster/play_attack_sound(damage, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(machine_stat & BROKEN)
				playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 100, TRUE)
			else
				playsound(loc, 'sound/effects/glasshit.ogg', 90, TRUE)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, TRUE)

/obj/machinery/newscaster/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 2)
		new /obj/item/shard(loc)
		new /obj/item/shard(loc)
	qdel(src)

/obj/machinery/newscaster/attack_paw(mob/user)
	if(user.a_intent != INTENT_HARM)
		to_chat(user, span_warning("Управление этой штукой выглядит слишком сложно для вашего крошечного мозга!"))
	else
		take_damage(5, BRUTE, "melee")

/obj/item/wallframe/newscaster
	name = "newscaster frame"
	desc = "Используется для создания newscasters, просто крепится к стене."
	icon_state = "newscaster"
	custom_materials = list(/datum/material/iron=14000, /datum/material/glass=8000)
	result_path = /obj/machinery/newscaster
	inverse_pixel_shift = TRUE
	pixel_shift = 30
