GLOBAL_DATUM_INIT(news_network, /datum/newscaster/feed_network, new)
GLOBAL_LIST_EMPTY(allCasters)

/datum/newscaster/feed_comment
	var/author = ""
	var/body = ""
	var/time_stamp = ""

/datum/newscaster/feed_message
	var/author = ""
	var/body = ""
	var/list/authorCensorTime = list()
	var/list/bodyCensorTime = list()
	var/is_admin_message = 0
	var/icon/img = null
	var/time_stamp = ""
	var/list/datum/newscaster/feed_comment/comments = list()
	var/locked = FALSE
	var/caption = ""
	var/creationTime
	var/authorCensor
	var/author_censor = FALSE
	var/bodyCensor
	var/body_censor = FALSE
	var/photo_file
	var/parent_ID
	var/message_ID
	var/list/likes = list()
	var/list/dislikes = list()

/datum/newscaster/feed_message/proc/returnAuthor(censor)
	if(censor == -1)
		censor = authorCensor
	var/txt = "[GLOB.news_network.redactedText]"
	if(!censor)
		txt = author
	return txt

/datum/newscaster/feed_message/proc/returnBody(censor)
	if(censor == -1)
		censor = bodyCensor
	var/txt = "[GLOB.news_network.redactedText]"
	if(!censor)
		txt = body
	return txt

/datum/newscaster/feed_message/proc/toggleCensorAuthor()
	if(authorCensor)
		authorCensorTime.Add(GLOB.news_network.lastAction*-1)
	else
		authorCensorTime.Add(GLOB.news_network.lastAction)
	authorCensor = !authorCensor
	GLOB.news_network.lastAction++

/datum/newscaster/feed_message/proc/toggleCensorBody()
	if(bodyCensor)
		bodyCensorTime.Add(GLOB.news_network.lastAction*-1)
	else
		bodyCensorTime.Add(GLOB.news_network.lastAction)
	bodyCensor = !bodyCensor
	GLOB.news_network.lastAction++

/datum/newscaster/feed_channel
	var/channel_name = ""
	var/channel_desc = ""
	var/list/datum/newscaster/feed_message/messages = list()
	var/locked = FALSE
	var/author = ""
	var/censored = 0
	var/list/authorCensorTime = list()
	var/list/DclassCensorTime = list()
	var/authorCensor
	var/author_censor = FALSE
	var/is_admin_channel = 0
	var/channel_ID

/datum/newscaster/feed_channel/New()
	. = ..()
	channel_ID = ++GLOB.news_network.channel_count

/datum/newscaster/feed_channel/proc/returnAuthor(censor)
	if(censor == -1)
		censor = authorCensor
	var/txt = "[GLOB.news_network.redactedText]"
	if(!censor)
		txt = author
	return txt

/datum/newscaster/feed_channel/proc/toggleCensorDclass()
	if(censored)
		DclassCensorTime.Add(GLOB.news_network.lastAction*-1)
	else
		DclassCensorTime.Add(GLOB.news_network.lastAction)
	censored = !censored
	GLOB.news_network.lastAction++

/datum/newscaster/feed_channel/proc/toggleCensorAuthor()
	if(authorCensor)
		authorCensorTime.Add(GLOB.news_network.lastAction*-1)
	else
		authorCensorTime.Add(GLOB.news_network.lastAction)
	authorCensor = !authorCensor
	GLOB.news_network.lastAction++

/datum/newscaster/wanted_message
	var/active
	var/criminal
	var/body
	var/scannedUser
	var/isAdminMsg
	var/icon/img
	var/photo_file
	var/wanted_ID

/datum/newscaster/feed_network
	var/list/datum/newscaster/feed_channel/network_channels = list()
	var/datum/newscaster/wanted_message/wanted_issue
	var/lastAction
	var/redactedText = "\[REDACTED\]"
	var/channel_count = 0
	var/message_count = 0
	var/wanted_count = 0
	var/list/datum/newscaster/wanted_message/wanted_issues = list()

/datum/newscaster/feed_network/New()
	CreateFeedChannel("Колониальная сеть объявлений", "SS13", 1)
	wanted_issue = new /datum/newscaster/wanted_message

/datum/newscaster/feed_network/proc/CreateFeedChannel(channel_name, author, locked, adminChannel = 0, channel_desc = "")
	var/datum/newscaster/feed_channel/newChannel = new /datum/newscaster/feed_channel
	newChannel.channel_name = channel_name
	newChannel.author = author
	newChannel.locked = locked
	newChannel.is_admin_channel = adminChannel
	newChannel.channel_desc = channel_desc
	network_channels += newChannel

/datum/newscaster/feed_network/proc/SubmitArticle(msg, author, channel_name, datum/picture/picture, adminMessage = 0, allow_comments = 1)
	var/datum/newscaster/feed_message/newMsg = new /datum/newscaster/feed_message
	newMsg.author = author
	newMsg.body = msg
	newMsg.time_stamp = "[station_time_timestamp()]"
	newMsg.is_admin_message = adminMessage
	newMsg.locked = !allow_comments
	if(picture)
		newMsg.img = picture.picture_image
		newMsg.caption = picture.caption
		newMsg.photo_file = save_photo(picture.picture_image)
	for(var/datum/newscaster/feed_channel/FC in network_channels)
		if(FC.channel_name == channel_name)
			FC.messages += newMsg
			newMsg.parent_ID = FC.channel_ID
			break
	for(var/obj/machinery/newscaster/NEWSCASTER in GLOB.allCasters)
		NEWSCASTER.newsAlert(channel_name)
	lastAction++
	newMsg.creationTime = lastAction
	message_count++
	newMsg.message_ID = message_count

/datum/newscaster/feed_network/proc/submitWanted(criminal, body, scanned_user, datum/picture/picture, adminMsg = 0, newMessage = 0)
	wanted_issue.active = 1
	wanted_issue.criminal = criminal
	wanted_issue.body = body
	wanted_issue.scannedUser = scanned_user
	wanted_issue.isAdminMsg = adminMsg
	if(picture)
		wanted_issue.img = picture.picture_image
		wanted_issue.photo_file = save_photo(picture.picture_image)

	var/datum/newscaster/wanted_message/new_wanted = new /datum/newscaster/wanted_message
	new_wanted.active = 1
	new_wanted.criminal = criminal
	new_wanted.body = body
	new_wanted.scannedUser = scanned_user
	new_wanted.isAdminMsg = adminMsg
	new_wanted.wanted_ID = ++wanted_count
	if(picture)
		new_wanted.img = picture.picture_image
		new_wanted.photo_file = save_photo(picture.picture_image)
	wanted_issues += new_wanted

	if(newMessage)
		for(var/obj/machinery/newscaster/N in GLOB.allCasters)
			N.newsAlert()
			N.update_appearance()
	return new_wanted.wanted_ID

/datum/newscaster/feed_network/proc/deleteWanted()
	wanted_issue.active = 0
	wanted_issue.criminal = null
	wanted_issue.body = null
	wanted_issue.scannedUser = null
	wanted_issue.img = null
	wanted_issues.Cut()
	for(var/obj/machinery/newscaster/NEWSCASTER in GLOB.allCasters)
		NEWSCASTER.update_appearance()

/datum/newscaster/feed_network/proc/deleteWantedById(wanted_id)
	for(var/datum/newscaster/wanted_message/wanted in wanted_issues)
		if(wanted.wanted_ID == wanted_id)
			wanted.active = 0
			var/has_active = FALSE
			for(var/datum/newscaster/wanted_message/check_wanted in wanted_issues)
				if(check_wanted.active)
					has_active = TRUE
					break
			if(!has_active)
				wanted_issue.active = 0
				wanted_issue.criminal = null
				wanted_issue.body = null
			for(var/obj/machinery/newscaster/updated_newscaster in GLOB.allCasters)
				updated_newscaster.update_appearance()
			return TRUE
	return FALSE

/datum/newscaster/feed_network/proc/save_photo(icon/photo)
	var/photo_file = copytext_char(md5("\icon[photo]"), 1, 6)
	if(!fexists("[GLOB.log_directory]/photos/[photo_file].png"))
		var/icon/clean = new /icon()
		clean.Insert(photo, "", SOUTH, 1, 0)
		fcopy(clean, "[GLOB.log_directory]/photos/[photo_file].png")
	return photo_file
