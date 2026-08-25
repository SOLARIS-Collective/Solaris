/obj/item/newspaper
	name = "newspaper"
	desc = "Выпуск газеты «Griffon», часто распространяемой на борту космических станций «Nanotrasen»."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "newspaper"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("bapped")
	resistance_flags = FLAMMABLE
	var/screen = 0
	var/pages = 0
	var/curr_page = 0
	var/list/datum/newscaster/feed_channel/news_content = list()
	var/scribble = ""
	var/scribble_page = null
	var/wantedAuthor
	var/wantedCriminal
	var/wantedBody
	var/wantedPhoto
	var/creationTime
	var/issue_number

/obj/item/newspaper/Initialize(mapload)
	. = ..()
	creationTime = GLOB.news_network.lastAction
	issue_number = rand(1000, 9999)

	for(var/datum/newscaster/feed_channel/iterated_feed_channel in GLOB.news_network.network_channels)
		news_content += iterated_feed_channel

	for(var/datum/newscaster/wanted_message/wanted in GLOB.news_network.wanted_issues)
		if(wanted.active)
			wantedAuthor = wanted.scannedUser
			wantedCriminal = wanted.criminal
			wantedBody = wanted.body
			if(wanted.img)
				wantedPhoto = wanted.img
			break

	if(!wantedCriminal && GLOB.news_network.wanted_issue.active)
		wantedAuthor = GLOB.news_network.wanted_issue.scannedUser
		wantedCriminal = GLOB.news_network.wanted_issue.criminal
		wantedBody = GLOB.news_network.wanted_issue.body
		if(GLOB.news_network.wanted_issue.img)
			wantedPhoto = GLOB.news_network.wanted_issue.img

/obj/item/newspaper/attack_self(mob/user)
	ui_interact(user)

/obj/item/newspaper/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Newspaper")
		ui.open()

/obj/item/newspaper/ui_data(mob/user)
	var/list/data = list()
	data["current_page"] = curr_page
	data["scribble_message"] = scribble
	data["wanted_criminal"] = wantedCriminal
	data["wanted_body"] = wantedBody
	data["wanted_photo"] = wantedPhoto
	data["issue_number"] = issue_number

	pages = news_content.len
	data["pages"] = pages

	var/list/channels_list = list()
	for(var/datum/newscaster/feed_channel/channel in news_content)
		var/message_count = 0
		for(var/datum/newscaster/feed_message/message in channel.messages)
			if(message.creationTime <= creationTime)
				message_count++
		channels_list += list(list(
			"name" = channel.channel_name,
			"author" = channel.author,
			"messages" = message_count
		))
	data["channels"] = channels_list

	var/list/channel_data = list()
	if(curr_page > 0 && curr_page <= pages)
		var/list/messages_list = list()

		if(curr_page <= news_content.len)
			var/datum/newscaster/feed_channel/current_channel = news_content[curr_page]
			if(current_channel)
				channel_data["name"] = current_channel.channel_name
				channel_data["author"] = current_channel.author
				channel_data["censored"] = current_channel.censored

				for(var/datum/newscaster/feed_message/message in current_channel.messages)
					if(message.creationTime <= creationTime)
						messages_list += list(list(
							"body" = message.returnBody(-1),
							"author" = message.returnAuthor(-1),
							"time" = message.time_stamp,
							"img" = message.img
						))

		channel_data["messages"] = messages_list
	data["channel_data"] = channel_data

	return data

/obj/item/newspaper/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("next_page")
			var/max_page = pages + 2
			if(wantedCriminal)
				max_page++
			if(curr_page < max_page)
				curr_page++
				playsound(loc, "pageturn", 50, TRUE)
				. = TRUE
		if("prev_page")
			if(curr_page > 0)
				curr_page--
				playsound(loc, "pageturn", 50, TRUE)
				. = TRUE

/obj/item/newspaper/attackby(obj/item/W, mob/living/user, params)
	if(istype(W, /obj/item/pen))
		if(!user.is_literate())
			to_chat(user, span_notice("Ты пишешь неразборчиво на [src]!"))
			return
		if(scribble_page == curr_page)
			to_chat(user, span_warning("На этой странице уже есть заметка... Не стоит делать все слишком загроможденным, не так ли?"))
		else
			var/s = stripped_input(user, "Напишите что-нибудь", "Газета")
			if (!s)
				return
			if(!user.canUseTopic(src, BE_CLOSE))
				return
			scribble_page = curr_page
			scribble = s
			to_chat(user, span_notice("Вы написали заметку на странице [curr_page + 1]."))
			add_fingerprint(user)
	else
		return ..()
