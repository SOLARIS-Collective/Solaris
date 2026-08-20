/obj/effect/mob_spawn/human/elysium_outpost
	death = FALSE
	roundstart = FALSE
	random = FALSE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "cryopod"
	/// Whether this role should be replenished when player leaves via cryopod
	var/replenish_role = TRUE
	/// Reference to the cryopod that will handle respawning
	var/datum/weakref/linked_cryopod

// Cook

/obj/effect/mob_spawn/human/elysium_outpost/cook
	name = "Outpost Cook"
	id_job = "Cook"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Cook of Elysium"
	outfit = /datum/outfit/outpost/cook
	important_info = "Не покидайте свой аванпост собственнолично и без разрешения администрации! Как гражданин республики Элизиум, Вы должны проявлять свою гражданскую позицию!"
	short_desc = "Готовьте еду, выращивайте растения, держите в чистоту свою кухню, разговаривайте с посетителями, поднимайте настроение им своей стряпнёй."
	flavour_text = "Готовьте, растите различную еду. Вы должны обеспечить аванпост едой, свежими фруктами и овощами. Вам разрешается применять CQC только на кухне и в центральном баре. Вы не можете покидать аванпост без весомой причины, так как вы являетесь гражданином республики Элизиум. Если же вас заставили покинуть аванпост силой - выживайте, самообороняйтесь, и надейтесь, что кто-то сможет вам помочь. Не мешайте другим игрокам и обслуживающему персоналу аванпоста. Вы можете работать вместе, контактировать с капитанами и членами команд на аванпосту."

/obj/effect/mob_spawn/human/elysium_outpost/cook/Destroy()
	new /obj/machinery/cryopod/outpost/cook(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/cook/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Динамик в криокапсуле запиликал, извещая о том, что сон закончился. Пора вставать на работу, \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

// Bartender

/obj/effect/mob_spawn/human/elysium_outpost/bartender
	name = "Elysium Outpost Bartender"
	id_job = "Bartender"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Bartender of Elysium"
	outfit = /datum/outfit/outpost/bartender
	important_info = "Не покидайте свой аванпост собственнолично и без разрешения администрации! Как гражданин республики Элизиум, Вы должны проявлять свою гражданскую позицию!"
	short_desc = "Разливайте пиво, готовьте бахус самым отпетым капитанам, наводите порядок в своем баре, разговаривайте с поваром, если он есть, рассказывайте басни и слушайте истории капитанов."
	flavour_text = "Вы - главный разливщик напитков и коктелей на этом ледяном куске камня в космосе. Ваш бар - ваша территория. Можете зарабатывать продажей напитков, а можете предлагать всем свои зеленые листочки. Вам разрешено применять силу в виде двух дробовиков к особо буйным посетителям: не понимают с первого слова - поймут после заряда дроби. Не мешайте другим игрокам и обслуживающему персоналу аванпоста. Вы можете работать вместе, контактировать с капитанами и членами команд на аванпосту."

/obj/effect/mob_spawn/human/elysium_outpost/bartender/Destroy()
	new /obj/machinery/cryopod/outpost/bartender(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/bartender/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Динамик в криокапсуле запиликал, извещая о том, что сон закончился. Пора вставать на работу, \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

// Maid - Janitor

/obj/effect/mob_spawn/human/elysium_outpost/maid
	name = "Elysium Outpost Maid"
	id_job = "Maid"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Maid of Elysium"
	outfit = /datum/outfit/outpost/maid
	important_info = "Не покидайте свой аванпост собственнолично и без разрешения администрации! Как гражданин республики Элизиум, Вы должны проявлять свою гражданскую позицию!"
	short_desc = "Убирайте мусор, чистите полы, заигрывайте с посетителями, выносите мусор, вносите позитив своим откровенным нарядом."
	flavour_text = "Вы - горничная и по совместительству уборщица аванпоста. Ваша главная цель - поддерживать чистоту на аванпосту, в перерывах зависая на подиуме в баре. Если вас обидели, обратитесь к бармену или повару: эти ребята быстро поставят на место хулиганов! Не мешайте другим игрокам и обслуживающему персоналу аванпоста. Вы можете работать вместе, контактировать с капитанами и членами команд на аванпосту."

/obj/effect/mob_spawn/human/elysium_outpost/maid/Destroy()
	new /obj/machinery/cryopod/outpost/maid(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/maid/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Динамик в криокапсуле запиликал, извещая о том, что сон закончился. Пора вставать на работу, \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

// Artist

/obj/effect/mob_spawn/human/elysium_outpost/artist
	name = "Elysium Outpost Artist"
	id_job = "Artist"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Artist of Elysium"
	outfit = /datum/outfit/outpost/artist
	important_info = "Не покидайте свой аванпост собственнолично и без разрешения администрации! Как гражданин республики Элизиум, Вы должны проявлять свою гражданскую позицию!"
	short_desc = "Вы - известный (ну, или вы так думаете) артист! Ваша основная цель - это веселить народ вокруг вас! Устраивайте шоу, расказывайте анекдоты, делайте на этом деньги!"
	flavour_text = "В прошлом вы были клоуном, но сейчас настали другие времена. Ваш талант и заслуги артиста признали, и теперь вы гастролируете по разным уголках космоса! Не мешайте другим игрокам и обслуживающему персоналу аванпоста. Вы можете работать вместе, контактировать с капитанами и членами команд на аванпосту."

/obj/effect/mob_spawn/human/elysium_outpost/artist/Destroy()
	new /obj/machinery/cryopod/outpost/artist(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/artist/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Динамик в криокапсуле заиграл весёлой музыкой, извещая о том, что сон закончился. Пора вставать на работу и веселить народ, \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

// Wagabond - он же бомж

/obj/effect/mob_spawn/human/elysium_outpost/wagabond
	name = "Wagabond"
	id_job = "Wagabond"
	icon = 'icons/obj/objects.dmi'
	icon_state = "dirty_mattress"
	faction = FACTION_ELYSIUM
	assignedrole = "Wagabond"
	outfit = /datum/outfit/outpost/wagabond
	important_info = "Внимание! На данный момент эта роль не имеет конкретной цели! Придумайте её сами или обратитесь к администрации."
	short_desc = "Вы - бродяга. Ищите еду, пытайтесь выжить на этом куске металла в космосе, погрузитесь в мир нищеты (халявной еды и пива в бесплатных автоматах)"
	flavour_text = "Только вы знаете, как вы докатились до жизни такой. Было ли это подставой, или, быть может, вы не оплатили ипотеку на судно? Вне зависимости от причин, главное одно: нужно как-то прожить очередной день..."
	replenish_role = FALSE

/obj/effect/mob_spawn/human/elysium_outpost/wagabond/Destroy()
	new /obj/structure/bed/outpost/wagabond(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/wagabond/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Вы просыпаетесь в окружении собачьего холода и запаха тухлых носков. Ваше сознание смутно припоминает то, кем вы были раньше, но вы точно помните что вас зовут \the [A.name]. Пора прожить ещё один жалкий день в этом аду...", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

// Medic

/obj/effect/mob_spawn/human/elysium_outpost/medic
	name = "Elysium Outpost Medic"
	id_job = "Medic"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Medic of Elysium"
	outfit = /datum/outfit/outpost/medic
	important_info = "Не покидайте свой аванпост собственнолично и без разрешения администрации! Как гражданин республики Элизиум, Вы должны проявлять свою гражданскую позицию!"
	short_desc = "Лечите больных, оказывайте помощь в операциях, тайно вырезайте органы для дальнейшей перепродажи на черном рынке."
	flavour_text = "Вы - доктор и по совместительству хирург. Или гробовщик - как повезет. Вы явно проснулись для того, чтобы лечить пациентов. Вы также можете попросить доступ к химии и генетике СМО или администрацию аванпоста, но у Вас должна быть хорошая причина для этого."

/obj/effect/mob_spawn/human/elysium_outpost/medic/Destroy()
	new /obj/machinery/cryopod/outpost/medic(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/medic/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Вас вызывают, доктор \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

// Medic

/obj/effect/mob_spawn/human/elysium_outpost/medical_shield
	name = "Outpost Medical Shield"
	id_job = "Medic"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Medical Shield"
	outfit = /datum/outfit/outpost/medic/medical_shield
	important_info = "ВНИМАНИЕ! Это очень сложная роль, требующая опыта в ведении переговоров и, возможно, редких стычек. Вы можете покидать аванпост, только если наличие трупа на одной из планет подтверждено! Вы подчиняетесь только клятве гипократа и своей организации Медицинский Щит. Ваша задача - любой ценой спасти клиента!"
	short_desc = "Спасайте важных клиентов, сдирайте с них страховку под 80%!"
	flavour_text = "Вы не просто медик, вы - хорошо обученный специалист медицинского щита. Если на пути к цели у вас есть препятствия, которые не хотят вас слушать, вы вправе разобраться с ними, поспешив к клиенту!"

/obj/effect/mob_spawn/human/elysium_outpost/medical_shield/Destroy()
	new /obj/machinery/cryopod/outpost/medical_shield(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/medical_shield/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Поступило оповещение: клиент в опасности, \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

/obj/effect/mob_spawn/human/elysium_outpost/medical_shield/marine
	name = "Outpost Medical Shield Marine"
	id_job = "Medic"
	faction = FACTION_ELYSIUM
	assignedrole = "Outpost Medical Shield Marine"
	outfit = /datum/outfit/outpost/medic/medical_shield/marine
	important_info = "ВНИМАНИЕ! Это очень сложная роль, требующая опыта в ведении переговоров и, возможно, редких стычек. Вы можете покидать аванпост, только если наличие трупа на одной из планет подтверждено! Вы подчиняетесь только клятве гипократа и своей организации Медицинский Щит. Ваша задача - любой ценой спасти клиента!"
	short_desc = "Спасайте важных клиентов! Вы - хорошо оснащенный оперативник Мед Щита, Ваша цель - защищать свою группу огнём и прикрытием!"
	flavour_text = "Вы не просто медик, вы - хорошо обученный специалист медицинского щита. Если на пути к цели у вас есть препятствия, которые не хотят вас слушать, вы вправе разобраться с ними, поспешив к клиенту!"

/obj/effect/mob_spawn/human/elysium_outpost/medical_shield/marine/Destroy()
	new /obj/machinery/cryopod/outpost/medical_shield/marine(drop_location())
	return ..()

/obj/effect/mob_spawn/human/elysium_outpost/medical_shield/marine/Initialize()
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Поступило оповещение: клиент в опасности, \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)
