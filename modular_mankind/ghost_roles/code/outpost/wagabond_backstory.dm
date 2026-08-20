// Генератор случайной предыстории для бродяги (Wagabond).
// Каждый блок (кем был / как скатился / чего хочет) тянется рандомно при спавне.
// Все фразы написаны под лор Solaris: Империя, Великое безумие,
// Разрастающаяся Мерзость, Артефакт, ковчег, красные глаза, ксеносы,
// гражданство за службу, НаноТрейзен, Синдикат, Солнечная Федерация и т.д.
// Некоторые фразы подставляют живые данные текущего раунда:
//   {FACTION}    - фракции кораблей, присутствующих в раунде
//   {SHIP}       - названия кораблей, присутствующих в раунде
//   {CHARACTER}  - имена персонажей живых игроков в раунде
//   {CAPTAIN}    - имена капитанов (владельцев) кораблей в раунде
// Плейсхолдеры в фигурных скобках (DM их не интерполирует), в рантайме они
// заменяются реальными данными через wagabond_replace_tokens.
// Результат выводится в чат тегами, сохраняется в память и выдаётся
// физической мятой запиской в рюкзаке, чтобы её можно было показывать другим.

GLOBAL_LIST_INIT(wagabond_former_entries, list(
	list("text" = "Вы отслужили свою десятилетнюю повинность в армии флота {FACTION}.", "tag" = "ВЕТЕРАН ФЛОТА {FACTION}"),
	list("text" = "Вы были пилотом имперского флота ещё до Великого безумия.", "tag" = "ПИЛОТ ИМПЕРСКОГО ФЛОТА"),
	list("text" = "Вы служили на пограничных рубежах, сдерживая порождения Мерзости.", "tag" = "СТРАЖ РУБЕЖЕЙ"),
	list("text" = "Вы были шахтёром на добыче плазмы для НаноТрейзен.", "tag" = "ШАХТЁР НАНОТРЕЙЗЕН"),
	list("text" = "Вы были учёным, изучавшим Артефакт до того, как он свёл вас с ума.", "tag" = "УЧЁНЫЙ АРТЕФАКТА"),
	list("text" = "Вы были фермером на колониальной планете, сожжённой Мерзостью.", "tag" = "КОЛОНИСТ-ФЕРМЕР"),
	list("text" = "Вы были техником на ковчеге во время Великого исхода.", "tag" = "ТЕХНИК КОВЧЕГА"),
	list("text" = "Вы служили в Христианской армии святого Георгия.", "tag" = "СОЛДАТ ХРИСТИАНСКОЙ АРМИИ"),
	list("text" = "Вы работали в разведке КСО до того, как она стала Синдикатом.", "tag" = "РАЗВЕДЧИК КСО"),
	list("text" = "Вы были инженером на буровых платформах добычи блюспейса.", "tag" = "ИНЖЕНЕР БЛЮСПЕЙСА"),
	list("text" = "Вы были охранником на станции-фабрике до Великой национализации.", "tag" = "ОХРАННИК ФАБРИКИ"),
	list("text" = "Вы были военным врачом в госпитале на фронте войны с Альянсом.", "tag" = "ВОЕНВРАЧ"),
	list("text" = "Вы были священником Церкви, пока не увидели красные глаза паствы.", "tag" = "СВЯЩЕННИК ЦЕРКВИ"),
	list("text" = "Вы возили ксенотехнологии через границы Империи контрабандой.", "tag" = "КОНТРАБАНДИСТ"),
	list("text" = "Вы командовали фрегатом {SHIP}, охраняя конвои флота {FACTION}.", "tag" = "КАПИТАН {SHIP}"),
	list("text" = "Вы писали хронику при дворе последнего Императора.", "tag" = "ИМПЕРСКИЙ ХРОНИКЁР"),
	list("text" = "Вы были эльфом из рода, бежавшего с павшей планеты.", "tag" = "БЕЖЕНЕЦ-ЭЛЬФ"),
	list("text" = "Вы были дворфом-кузнецом, ковавшим оружие против Нечто.", "tag" = "ДВОРФ-КУЗНЕЦ"),
	list("text" = "Вы слушали безумные сигналы из-за рубежа и сходили с ума вместе с астрологами.", "tag" = "АСТРОЛОГ"),
	list("text" = "Вы были инструктором по выживанию на мёртвых планетах.", "tag" = "ИНСТРУКТОР ПО ВЫЖИВАНИЮ"),
	list("text" = "Вы служили на флагмане {SHIP} до его гибели в бою.", "tag" = "ФЛАГМАНСКАЯ СЛУЖБА {SHIP}"),
	list("text" = "Вы были капитаном {SHIP}, пока не доверили штурвал {CHARACTER}.", "tag" = "БЫВШИЙ КАПИТАН {SHIP}"),
	list("text" = "Вы были бухгалтером в филиале компании {FACTION}, пока не «одолжили» казну.", "tag" = "БУХГАЛТЕР {FACTION}"),
	list("text" = "Вы были поваром в армейской столовой, где солдаты молились, чтобы не умереть с голоду.", "tag" = "АРМЕЙСКИЙ ПОВАР"),
	list("text" = "Вы были пилотом шаттла, возившим припасы на осаждённые колонии.", "tag" = "ПИЛОТ ШАТТЛА"),
	list("text" = "Вы были телохранителем важного чиновника Христианского ВП.", "tag" = "ТЕЛОХРАНИТЕЛЬ"),
	list("text" = "Вы были техником-плазменщиком, чинившим энергетические генераторы.", "tag" = "ПЛАЗМЕНЩИК"),
	list("text" = "Вы были картографом, наносившим на карты зоны заражения Мерзостью.", "tag" = "КАРТОГРАФ"),
	list("text" = "Вы были адвокатом, защищавшим тех, кого Церковь объявила еретиками.", "tag" = "АДВОКАТ ЕРЕТИКОВ"),
	list("text" = "Вы были горным инженером на рудниках Ареса, где царили законы Императора.", "tag" = "ИНЖЕНЕР АРЕСА"),
))

GLOBAL_LIST_INIT(wagabond_fall_entries, list(
	list("text" = "Мерзость поглотила ваш мир, и вы остались единственным выжившим.", "tag" = "ПОГЛОЩЁН МЕРЗОСТЬЮ"),
	list("text" = "Вы продали своё гражданство за бутылку дешёвого пойла.", "tag" = "ПРОДАЛ ГРАЖДАНСТВО"),
	list("text" = "Синдром красных глаз дал о себе знать, и вас списали с флота {FACTION}.", "tag" = "КРАСНЫЕ ГЛАЗА"),
	list("text" = "Вы проснулись из криосна на сотню лет позже, и никто вас не ждал.", "tag" = "ОПОЗДАЛ НА СТО ЛЕТ"),
	list("text" = "Вы проиграли корабль {SHIP} в карты в баре Элизиума.", "tag" = "ПРОИГРАЛ {SHIP}"),
	list("text" = "Церковь объявила вас еретиком, и вам пришлось бежать с Христианского ВП.", "tag" = "ЕРЕТИК"),
	list("text" = "Вы сбежали из армии {FACTION} перед решающей битвой.", "tag" = "ДЕЗЕРТИР {FACTION}"),
	list("text" = "Вы взяли ссуду у ростовщиков Синдиката и не смогли её вернуть.", "tag" = "ДОЛГ СИНДИКАТУ"),
	list("text" = "Вы потратили страховую выплату за сгоревшую колонию на выпивку.", "tag" = "СТРАХОВКА"),
	list("text" = "Вы взорвали склад плазмы и списали всё на диверсию.", "tag" = "ВЗРЫВ ПЛАЗМЫ"),
	list("text" = "Вас выгнали с ковчега за нарушение карантина после контакта с заражённым.", "tag" = "НАРУШИЛ КАРАНТИН"),
	list("text" = "Вы лжесвидетельствовали на трибунале против {CHARACTER}, но совесть догнала вас.", "tag" = "ЛЖЕСВИДЕТЕЛЬ"),
	list("text" = "Ваш корабль {SHIP} угнали вместе с вашей долей добычи.", "tag" = "УГНАЛИ {SHIP}"),
	list("text" = "Вы поспорили с {CHARACTER}, что переживёте ночь в зоне заражения, и проиграли.", "tag" = "СПОР С {CHARACTER}"),
	list("text" = "Наёмники Аккорда Макоссо-Варра ограбили вас на границе сектора.", "tag" = "ОГРАБЛЕН АККОРДОМ"),
	list("text" = "Вы потеряли руку на добыче блюспейса и получили компенсацию размером с банку тушёнки.", "tag" = "ТРАВМА НА ДОБЫЧЕ"),
	list("text" = "Вы сорвали голос, читая проповеди против Империи на площадях станций.", "tag" = "ПОТЕРЯЛ ГОЛОС"),
	list("text" = "Вас списали за пьянство прямо перед награждением за спасение колонии.", "tag" = "СПИСАН ЗА ПЬЯНСТВО"),
	list("text" = "Вы прикоснулись к Артефакту в надежде исцелиться и потеряли рассудок.", "tag" = "ТРОНУЛ АРТЕФАКТ"),
	list("text" = "Вы очнулись в чужой каюте без штанов и с бейджем дезертира на шее.", "tag" = "БЕЗ ШТАНОВ"),
	list("text" = "Ваш экипаж бросил вас на станции, когда флот {FACTION} начал эвакуацию.", "tag" = "БРОШЕН ЭКИПАЖЕМ"),
	list("text" = "Вы подставили {CHARACTER}, но вина оказалась тяжелее награды.", "tag" = "ПОДСТАВА {CHARACTER}"),
	list("text" = "Ваша колония сгорела, пока вы пили в баре на Элизиуме.", "tag" = "КОЛОНИЯ СГОРЕЛА"),
	list("text" = "Вы украли казну ковчега, но спрятали её не там и потеряли всё.", "tag" = "УКРАЛ КАЗНУ"),
	list("text" = "Вас разжаловали при всём экипаже {SHIP} за трусость в бою.", "tag" = "РАЗЖАЛОВАН НА {SHIP}"),
	list("text" = "Вы поспорили с {CHARACTER} и проиграли даже память о прошлом.", "tag" = "ПРОСПОРИЛ ПАМЯТЬ"),
	list("text" = "Вы попытались продать данные о ковчеге НаноТрейзен, но вас обманули.", "tag" = "ПРОДАЛ ДАННЫЕ"),
	list("text" = "Вы вступили в культ Артефакта, и культ забрал у вас всё.", "tag" = "КУЛЬТ АРТЕФАКТА"),
	list("text" = "Вы сбежали из тюрьмы фракции {FACTION} через выгребную шахту.", "tag" = "БЕГЛЕЦ ИЗ {FACTION}"),
	list("text" = "Ваш корабль {SHIP} разнесли порождения Мерзости, и вы чудом спаслись.", "tag" = "РАЗНЕСЁН МЕРЗОСТЬЮ"),
))

GLOBAL_LIST_INIT(wagabond_goal_entries, list(
	list("text" = "Вы хотите снова получить гражданство, отслужив ещё один срок.", "tag" = "ХОЧЕТ ГРАЖДАНСТВА"),
	list("text" = "Вы ищете ковчег, на который можно попасть до конца времён.", "tag" = "ИЩЕТ КОВЧЕГ"),
	list("text" = "Вы мечтаете найти {CHARACTER}, брошенного на павшей планете.", "tag" = "ИЩЕТ {CHARACTER}"),
	list("text" = "Вы хотите добыть блюспейс, чтобы расплатиться с долгами.", "tag" = "ИЩЕТ БЛЮСПЕЙС"),
	list("text" = "Вы мечтаете отомстить порождению Мерзости, сожравшему ваш дом.", "tag" = "ХОЧЕТ МЕСТИ"),
	list("text" = "Вы хотите завербоваться на борт {SHIP} и убраться из этого сектора.", "tag" = "ВЕРБУЕТСЯ НА {SHIP}"),
	list("text" = "Вы ищете лекарство от красных глаз, пока не поздно.", "tag" = "ИЩЕТ ЛЕКАРСТВО"),
	list("text" = "Вы мечтаете стать капитаном и собрать экипаж из таких же бродяг.", "tag" = "ХОЧЕТ СТАТЬ КАПИТАНОМ"),
	list("text" = "Вы хотите отыскать семью {CHARACTER}, разбросанную после бегства с Земли.", "tag" = "ИЩЕТ СЕМЬЮ {CHARACTER}"),
	list("text" = "Вы мечтаете, чтобы {FACTION} признала ваши заслуги перед Империей.", "tag" = "ЖДЁТ ПРИЗНАНИЯ {FACTION}"),
	list("text" = "Вы пишете хронику падения Империи, пока память не стёрлась окончательно.", "tag" = "ПИШЕТ ХРОНИКУ"),
	list("text" = "Вы ищете последнее убежище, где можно спокойно состариться.", "tag" = "ИЩЕТ ПРИСТАНИЩЕ"),
	list("text" = "Вы хотите найти {CAPTAIN} и спросить, почему вас бросили на станции.", "tag" = "ИЩЕТ КАПИТАНА {CAPTAIN}"),
	list("text" = "Вы мечтаете открыть таверну для выживших с фронтира.", "tag" = "ХОЧЕТ ТАВЕРНУ"),
	list("text" = "Вы хотите попасть на борт ковчега и заснуть до лучших времён.", "tag" = "ХОЧЕТ КРИОСНА"),
	list("text" = "Вы ищете свидетеля, который подтвердит, что вы не безумец.", "tag" = "ИЩЕТ СВИДЕТЕЛЯ"),
	list("text" = "Вы мечтаете отомстить {CHARACTER}, продавшему вас Синдикату.", "tag" = "МЕСТЬ {CHARACTER}"),
	list("text" = "Вы копите на собственный шаттл, чтобы вырваться из Элизиума.", "tag" = "КОПИТ НА ШАТТЛ"),
	list("text" = "Вы ищете следы Императора, чтобы узнать правду о его исчезновении.", "tag" = "ИЩЕТ ИМПЕРАТОРА"),
	list("text" = "Вы мечтаете умереть не от Мерзости, а своей смертью.", "tag" = "ХОЧЕТ СВОЕЙ СМЕРТИ"),
	list("text" = "Вы хотите найти груз, потерянный во время эвакуации колонии.", "tag" = "ИЩЕТ ГРУЗ"),
	list("text" = "Вы мечтаете, чтобы {CHARACTER} наконец признал, что был неправ.", "tag" = "ЖДЁТ ПРИЗНАНИЯ {CHARACTER}"),
	list("text" = "Вы хотите вступить в ополчение {FACTION} и защищать свой новый дом.", "tag" = "ВСТУПИТЬ В ОПОЛЧЕНИЕ {FACTION}"),
	list("text" = "Вы ищете карту рудников Ареса, где спрятали свою заначку.", "tag" = "ИЩЕТ ЗАНАЧКУ"),
	list("text" = "Вы мечтаете дожить до дня, когда сектор очистят от Мерзости.", "tag" = "ЖДЁТ ОЧИЩЕНИЯ"),
	list("text" = "Вы хотите разыскать {SHIP} и вернуть его себе.", "tag" = "ВЫКУПАЕТ {SHIP}"),
	list("text" = "Вы мечтаете стать легендой сопротивления, пусть даже посмертно.", "tag" = "ХОЧЕТ СЛАВЫ"),
	list("text" = "Вы ищете храм, где можно молиться за тех, кого не спасли.", "tag" = "ИЩЕТ ХРАМ"),
	list("text" = "Вы хотите выторговать у НаноТрейзен дешёвый билет с этого аванпоста.", "tag" = "ТОРГУЕТСЯ С НАНОТРЕЙЗЕН"),
	list("text" = "Вы мечтаете, чтобы ваш рассказ о войне кто-нибудь записал.", "tag" = "ИЩЕТ ЛЕТОПИСЦА"),
))

// Фолбэки на случай пустого раунда (нет кораблей или игроков)
GLOBAL_LIST_INIT(wagabond_faction_fallbacks, list(FACTION_SYNDICATE, FACTION_NT, FACTION_SOLCON, FACTION_INTEQ, FACTION_PIRATES, FACTION_ELYSIUM, FACTION_SRM, FACTION_CLIP, FACTION_FRONTIERSMEN, FACTION_PGF, FACTION_RAMZI, FACTION_INDEPENDENT))

GLOBAL_LIST_INIT(wagabond_ship_fallbacks, list("Ковчег «Вечность»", "СФВ «Клинок»", "НТСВ «Багровый Закат»", "ИОАВ «Освободитель»", "КСОВ «Тень»", "ХВП «Георгий»", "АВ «Рог Ориона»", "НПВ «Новый Рассвет»", "ФФ «Ржавый Фронтир»", "СФВ «Северный Ветер»", "РК «Пустынный Призрак»", "ПКА «Хамелеон»", "СФВ «Гордость Сектора»"))

/// Случайная фракция среди кораблей, присутствующих в раунде. При пустом раунде - фолбэк.
/proc/pick_round_faction_name(exclude_name)
	var/list/pool = list()
	for(var/datum/overmap/ship/controlled/ship as anything in SSovermap?.controlled_ships)
		var/faction_name = SSfactions?.faction_name(ship.get_faction())
		if(!faction_name || faction_name == "Unknown Faction" || faction_name == exclude_name)
			continue
		pool |= faction_name
	if(length(pool))
		return pick(pool)
	var/list/fallback = GLOB.wagabond_faction_fallbacks.Copy()
	fallback -= exclude_name
	return length(fallback) ? pick(fallback) : pick(GLOB.wagabond_faction_fallbacks)

/// Случайный корабль из присутствующих в раунде. При пустом раунде - фолбэк.
/proc/pick_round_ship_name(exclude_name)
	var/list/pool = list()
	for(var/datum/overmap/ship/controlled/ship as anything in SSovermap?.controlled_ships)
		if(!ship.name || ship.name == exclude_name)
			continue
		pool |= ship.name
	if(length(pool))
		return pick(pool)
	var/list/fallback = GLOB.wagabond_ship_fallbacks.Copy()
	fallback -= exclude_name
	return length(fallback) ? pick(fallback) : pick(GLOB.wagabond_ship_fallbacks)

/// Случайное имя персонажа живого игрока в раунде. При пустом раунде - случайное имя.
/proc/pick_round_character_name(mob/exclude_mob)
	var/list/pool = list()
	for(var/mob/living/carbon/human/H as anything in GLOB.player_list)
		if(H == exclude_mob || H.stat == DEAD || !H.real_name || H.real_name == "Unknown")
			continue
		pool |= H.real_name
	if(length(pool))
		return pick(pool)
	return random_unique_name(pick(MALE, FEMALE))

/// Случайное имя капитана корабля в раунде. При пустом раунде - случайное имя.
/proc/pick_round_captain_name(exclude_name)
	var/list/pool = list()
	for(var/datum/overmap/ship/controlled/ship as anything in SSovermap?.controlled_ships)
		var/mob/captain = ship.owner_mob || ship.get_best_owner_mob()
		if(captain?.real_name && captain.real_name != exclude_name)
			pool |= captain.real_name
	if(length(pool))
		return pick(pool)
	return random_unique_name(pick(MALE, FEMALE))

/// Подстановка живых данных раунда в текст. Токены без данных остаются как есть.
/proc/wagabond_replace_tokens(text, faction, faction2, ship, ship2, character, character2, captain, captain2)
	text = replacetext(text, "{CAPTAIN2}", captain2)
	text = replacetext(text, "{CAPTAIN}", captain)
	text = replacetext(text, "{FACTION2}", faction2)
	text = replacetext(text, "{FACTION}", faction)
	text = replacetext(text, "{SHIP2}", ship2)
	text = replacetext(text, "{SHIP}", ship)
	text = replacetext(text, "{CHARACTER2}", character2)
	text = replacetext(text, "{CHARACTER}", character)
	return text

/datum/wagabond_backstory
	/// Кем игрок был раньше
	var/former
	/// Как он скатился до жизни бродяги
	var/fall
	/// Чего он хочет добиться
	var/goal
	/// Тег для блока "кем был"
	var/former_tag
	/// Тег для блока "как скатился"
	var/fall_tag
	/// Тег для блока "чего хочет"
	var/goal_tag

/datum/wagabond_backstory/New(mob/exclude_mob)
	. = ..()
	var/list/former_entry = pick(GLOB.wagabond_former_entries)
	former = former_entry["text"]
	former_tag = former_entry["tag"]
	var/list/fall_entry = pick(GLOB.wagabond_fall_entries)
	fall = fall_entry["text"]
	fall_tag = fall_entry["tag"]
	var/list/goal_entry = pick(GLOB.wagabond_goal_entries)
	goal = goal_entry["text"]
	goal_tag = goal_entry["tag"]

	// Живые данные текущего раунда
	var/faction_name = pick_round_faction_name(null)
	var/faction_name_2 = pick_round_faction_name(faction_name)
	var/ship_name = pick_round_ship_name(null)
	var/ship_name_2 = pick_round_ship_name(ship_name)
	var/character_name = pick_round_character_name(exclude_mob)
	var/character_name_2 = pick_round_character_name(exclude_mob)
	var/captain_name = pick_round_captain_name(null)
	var/captain_name_2 = pick_round_captain_name(captain_name)

	former = wagabond_replace_tokens(former, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	fall = wagabond_replace_tokens(fall, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	goal = wagabond_replace_tokens(goal, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	former_tag = wagabond_replace_tokens(former_tag, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	fall_tag = wagabond_replace_tokens(fall_tag, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	goal_tag = wagabond_replace_tokens(goal_tag, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)

/// Строка тегов для быстрого взгляда: БЫВШИЙ ВРАЧ / ДОЛГИ / ИЩЕТ СЕМЬЮ
/datum/wagabond_backstory/proc/get_tags()
	return "[former_tag] / [fall_tag] / [goal_tag]"

/// Связный рассказ из трёх блоков
/datum/wagabond_backstory/proc/get_narrative()
	return "[former] [fall] [goal]"

/obj/item/paper/crumpled/wagabond_memory
	name = "мятая записка"
	desc = "Помятый клочок бумаги. Почерк ваш собственный, но вы не помните, когда писали это..."

/obj/effect/mob_spawn/human/elysium_outpost/wagabond/special(mob/living/carbon/human/new_spawn)
	if(!ishuman(new_spawn))
		return
	var/datum/wagabond_backstory/backstory = new(new_spawn)
	var/note_text = backstory.get_narrative()
	to_chat(new_spawn, "<span class='big bold'>В глубине сознания всплывают обрывки прошлой жизни...</span>")
	to_chat(new_spawn, span_notice(backstory.get_tags()))
	to_chat(new_spawn, span_notice(backstory.get_narrative()))
	new_spawn.mind?.store_memory("Вы - бродяга. Ваша предыстория: [note_text]")
	var/obj/item/paper/crumpled/wagabond_memory/note = new(new_spawn.loc)
	note.add_raw_text(note_text)
	new_spawn.equip_to_slot_or_del(note, ITEM_SLOT_BACKPACK)