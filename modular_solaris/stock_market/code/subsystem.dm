// [SOLARIS-ADD] - STOCK_MARKET
SUBSYSTEM_DEF(stock_market)
	name = "Stock Market"
	wait = STOCK_MARKET_WAIT
	flags = SS_BACKGROUND
	init_order = INIT_ORDER_DEFAULT

	/// ticker -> /datum/stock_company
	var/list/companies = list()
	/// Active brokerage sessions this round
	var/list/datum/brokerage_session/sessions = list()
	/// Latest headlines first, capped at STOCK_NEWS_FEED_LENGTH
	var/list/news_feed = list()
	/// Accumulated gameplay demand per sector (STOCK_SECTOR_* -> credits)
	var/list/sector_demand = list()
	/// Running event effects awaiting reversion: list("company", "percent", "expiry")
	var/list/active_events = list()
	/// Market ticks since round start; history pre-fill counts towards it
	var/ticks_elapsed = 0
	var/next_event_tick = 0
	/// Total credits turned over on the exchange this round
	var/turnover_total = 0
	var/market_ready = FALSE

	// [SOLARIS-ADD] - STOCK_ADMIN_CONTROL - Рантайм-крутилки (админ-панель).
	// Полный контроль баланса и таймингов без рекомпиляции. Дефайны STOCK_* это
	// стартовые значения; правка тут действует сразу и на последующие тики.
	/// Пауза: при TRUE рынок не тикает (время заморожено)
	var/market_paused = FALSE
	/// Период тика рынка, в десекундах (STOCK_MARKET_WAIT == 300)
	var/market_wait = STOCK_MARKET_WAIT
	/// Комиссия брокера с каждой стороны сделки, %
	var/broker_fee_percent = STOCK_BROKER_FEE_PERCENT
	/// Спред маркетмейкера (доля цены)
	var/mm_spread = STOCK_MM_SPREAD
	/// Скорость возврата цены к фундаменталу за тик
	var/mean_reversion = STOCK_MEAN_REVERSION
	/// Кап позиции счёта, доля от float
	var/max_position_share = STOCK_MAX_POSITION_SHARE
	/// Стартовый баланс виртуального пула фракции
	var/faction_vault_start = STOCK_FACTION_VAULT_START
	/// Доля net_pl трейдеру пула по итогам смены
	var/trader_share = STOCK_TRADER_SHARE
	/// Порог спроса сектора, при котором срабатывает шок
	var/demand_threshold = STOCK_DEMAND_THRESHOLD
	/// Затухание спроса за тик
	var/demand_decay = STOCK_DEMAND_DECAY
	/// Макс. шок фундаментала от всплеска спроса, %
	var/demand_shock_max = STOCK_DEMAND_SHOCK_MAX
	/// Интервал случайных событий, в тиках
	var/event_interval_min = STOCK_EVENT_INTERVAL_MIN
	var/event_interval_max = STOCK_EVENT_INTERVAL_MAX
	/// Лимит активных лимитных ордеров на сессию
	var/max_orders_per_session = STOCK_MAX_ORDERS_PER_SESSION
	/// Сколько заголовков хранится в ленте новостей
	var/news_feed_length = STOCK_NEWS_FEED_LENGTH
	/// Кэш сессий терминалов: "ship:[REF]" / "personal:[REF]" -> session
	var/list/terminal_sessions = list()
	/// Рантайм-оверрайды характеристик событий: "event_type" -> list(field = value)
	var/list/event_overrides = list()

	// [SOLARIS-ADD] - STOCK_TRADE_TAPE - Публичная лента торгов и снимок рынка.
	/// Свежие сделки, первая — самая новая, кап STOCK_TRADE_LOG_LENGTH.
	/// Строка: list("tick", "actor", "ticker", "side", "count", "price")
	var/list/trade_log = list()
	/// Кэш публичного снимка: list("leaderboard", "pools", "holders", "trades")
	var/list/snapshot_cache = list()
	/// Тик, когда снимок собирался в последний раз
	var/snapshot_cache_tick = 0
	// [/SOLARIS-ADD] STOCK_TRADE_TAPE
	// [/SOLARIS-ADD]

/datum/controller/subsystem/stock_market/Initialize(timeofday)
	. = ..()
	wait = market_wait
	for(var/company_type in subtypesof(/datum/stock_company))
		var/datum/stock_company/company = new company_type()
		companies[company.ticker] = company
	generate_history()
	generate_opening_situation()
	next_event_tick = ticks_elapsed + rand(event_interval_min, event_interval_max)
	SSticker.OnRoundend(CALLBACK(src, PROC_REF(finalize_round)))
	market_ready = TRUE

/// Pre-fills the price tape so charts and reports start with plausible data.
/datum/controller/subsystem/stock_market/proc/generate_history()
	for(var/i in 1 to STOCK_HISTORY_LENGTH)
		ticks_elapsed += 1
		process_prices()

/// Round-start drama: one hyped issuer, one crushed issuer.
/datum/controller/subsystem/stock_market/proc/generate_opening_situation()
	var/list/all_tickers = list()
	for(var/ticker in companies)
		all_tickers += ticker
	all_tickers = shuffle(all_tickers)
	var/datum/stock_company/hyped = companies[all_tickers[1]]
	var/list/before_hyped = snapshot_fundamentals(null, hyped)
	hyped.apply_fundamental_shock(rand(25, 45), 0.2)
	add_news("До открытия биржи спекуляции разгоняют %TICKER% (%NAME%)", hyped, compute_impacts(before_hyped))
	if(length(all_tickers) < 2)
		return
	var/datum/stock_company/crushed = companies[all_tickers[2]]
	var/list/before_crushed = snapshot_fundamentals(null, crushed)
	crushed.apply_fundamental_shock(-rand(25, 40), 0.2)
	add_news("%TICKER% (%NAME%) падает перед открытием торгов", crushed, compute_impacts(before_crushed))

/datum/controller/subsystem/stock_market/fire(resumed)
	if(!market_ready || market_paused)
		return
	ticks_elapsed += 1
	process_prices()
	process_demand_decay()
	process_event_expiries()
	maybe_roll_event()
	process_sessions()

/datum/controller/subsystem/stock_market/proc/process_prices()
	for(var/ticker in companies)
		companies[ticker].tick(ticks_elapsed)

/datum/controller/subsystem/stock_market/proc/process_sessions()
	turnover_total = 0
	for(var/datum/brokerage_session/session in sessions)
		session.process_orders()
		turnover_total += session.turnover

/// Gameplay demand decays every tick; crossing the threshold shocks the sector.
/datum/controller/subsystem/stock_market/proc/process_demand_decay()
	for(var/sector in sector_demand)
		sector_demand[sector] *= demand_decay
		if(sector_demand[sector] < demand_threshold)
			continue
		fire_sector_demand_shock(sector)
		sector_demand[sector] = 0

/datum/controller/subsystem/stock_market/proc/fire_sector_demand_shock(sector)
	var/shock = sector_demand[sector] / demand_threshold * demand_shock_max
	shock = min(demand_shock_max, max(1, shock))
	var/list/before = snapshot_fundamentals(null, null, sector)
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company.sector == sector)
			company.fundamental = max(company.fundamental * (1 + shock / 100), 1)
	var/name_text = GLOB.stock_sector_names[sector] || sector
	add_news("Необычный поток заказов поднимает фундаментал сектора «[name_text]»", null, compute_impacts(before))

/// Applies pending hype/panic reversions once their window expires.
/datum/controller/subsystem/stock_market/proc/process_event_expiries()
	for(var/list/effect in active_events)
		if(ticks_elapsed < effect["expiry"])
			continue
		var/datum/stock_company/company = effect["company"]
		company.revert_fundamental(effect["percent"])
		active_events -= effect

/datum/controller/subsystem/stock_market/proc/maybe_roll_event(ignore_interval = FALSE)
	if(!ignore_interval && ticks_elapsed < next_event_tick)
		return
	next_event_tick = ticks_elapsed + rand(event_interval_min, event_interval_max)
	var/list/weighted = list()
	for(var/event_type in subtypesof(/datum/stock_event))
		var/datum/stock_event/template = event_type
		if(template.gameplay_driven)
			continue
		weighted[event_type] = template.weight
	var/chosen_type = pick_weight(weighted)
	if(chosen_type)
		var/datum/stock_event/chosen = new chosen_type()
		apply_event_overrides(chosen, chosen_type)
		fire_event(chosen)

/// Fires an ambient event on a random eligible target (or the whole market).
/datum/controller/subsystem/stock_market/proc/fire_event(datum/stock_event/event_datum)
	if(event_datum.gameplay_driven)
		return
	if(event_datum.market_wide)
		var/list/before = snapshot_fundamentals(event_datum)
		for(var/ticker in companies)
			apply_event_to(event_datum, companies[ticker])
		add_news(event_datum.headline, null, compute_impacts(before))
		return
	var/list/candidates = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(!event_datum.valid_sectors || (company.sector in event_datum.valid_sectors))
			candidates += company
	if(!length(candidates))
		return
	var/datum/stock_company/target = pick(candidates)
	var/list/before = snapshot_fundamentals(event_datum, target)
	apply_event_to(event_datum, target)
	add_news(event_datum.headline, target, compute_impacts(before))

/datum/controller/subsystem/stock_market/proc/apply_event_to(datum/stock_event/event_datum, datum/stock_company/company)
	var/shock = rand(event_datum.shock_min, event_datum.shock_max)
	if(!event_datum.market_wide)
		company.apply_fundamental_shock(shock, event_datum.peer_spread)
		if(event_datum.halt_ticks)
			company.halted_until_tick = ticks_elapsed + event_datum.halt_ticks
	else
		company.fundamental = max(company.fundamental * (1 + shock / 100), 1)
	if(!event_datum.market_wide && event_datum.rival_drag)
		apply_rival_drag(event_datum, company)
	if(event_datum.volatility_mult != 1)
		company.vol_mult = event_datum.volatility_mult
		company.vol_until_tick = ticks_elapsed + event_datum.duration_ticks
	if(event_datum.revert_share)
		register_reversion(company, shock * event_datum.revert_share, event_datum.duration_ticks)

/datum/controller/subsystem/stock_market/proc/apply_rival_drag(datum/stock_event/event_datum, datum/stock_company/company)
	for(var/ticker in companies)
		var/datum/stock_company/other = companies[ticker]
		if(other.sector == company.sector)
			continue
		other.fundamental = max(other.fundamental * (1 - event_datum.rival_drag / 100), 1)

/datum/controller/subsystem/stock_market/proc/register_reversion(datum/stock_company/company, percent, delay_ticks)
	active_events += list(list(
		"company" = company,
		"percent" = -percent,
		"expiry" = ticks_elapsed + delay_ticks,
	))

/// Pushes a headline into the feed; %NAME%/%TICKER% resolve from the issuer.
/// Лента статичная: заголовок сохраняется готовой русской строкой (без динамических
/// разборов в данных — по итогам живых тестов они ломались в транспортировке).
/datum/controller/subsystem/stock_market/proc/add_news(headline, datum/stock_company/company = null, impacts)
	var/name_text = company ? company.name : "the market"
	var/ticker_text = company ? company.ticker : "MKT"
	var/text = replacetext(replacetext(headline, "%NAME%", name_text), "%TICKER%", ticker_text)
	news_feed.Insert(1, text)
	if(length(news_feed) > news_feed_length)
		news_feed.Cut(news_feed_length + 1)
	return text

/// Какие тикеры попадают в разбор события: при market_wide — весь рынок,
/// иначе цель и её сектор-соседи (peer-эффект). Драг конкурентов не включаем.
/datum/controller/subsystem/stock_market/proc/fetch_impact_scope(datum/stock_event/event_datum, datum/stock_company/target)
	var/list/scope = list()
	if(event_datum.market_wide)
		for(var/ticker in companies)
			scope += ticker
		return scope
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company == target || (target && company.sector == target.sector))
			scope += ticker
	return scope

/// Снимок фундаментала по scope: fetch_impact_scope() если event_datum задан,
/// иначе — сектор sector либо соседей target (компания цели).
/datum/controller/subsystem/stock_market/proc/snapshot_fundamentals(datum/stock_event/event_datum = null, datum/stock_company/target = null, sector = null)
	var/list/scope = list()
	if(event_datum)
		scope = fetch_impact_scope(event_datum, target)
	else if(target)
		for(var/ticker in companies)
			var/datum/stock_company/company = companies[ticker]
			if(company == target || company.sector == target.sector)
				scope += ticker
	else if(sector)
		for(var/ticker in companies)
			if(companies[ticker].sector == sector)
				scope += ticker
	var/list/before = list()
	for(var/ticker in scope)
		before[ticker] = companies[ticker].fundamental
	return before

/// Считает движение фундаментала эмитентов после события и возвращает
/// отсортированный разбор: list(list("ticker", "name", "change")), топ по модулю.
/datum/controller/subsystem/stock_market/proc/compute_impacts(list/before)
	var/list/rows = list()
	for(var/ticker in before)
		var/datum/stock_company/company = companies[ticker]
		var/change = (company.fundamental / before[ticker] - 1) * 100
		if(abs(change) < STOCK_IMPACT_MIN_CHANGE)
			continue
		rows += list(list("ticker" = company.ticker, "name" = company.name, "change" = round(change * 10) / 10))
	sortTim(rows, /proc/cmp_stock_impact_abs_dsc)
	if(length(rows) > STOCK_IMPACT_MAX_ENTRIES)
		rows.Cut(STOCK_IMPACT_MAX_ENTRIES + 1)
	return rows

/proc/cmp_stock_impact_abs_dsc(list/a, list/b)
	return abs(b["change"]) - abs(a["change"])

/// Registers a brokerage session for a trader. Returns it or null on bad args.
/datum/controller/subsystem/stock_market/proc/create_session(mode, datum/bank_account/account, faction_path, trader_name, trader_ckey, datum/bank_account/premium_account)
	if(mode == STOCK_MODE_PERSONAL && !account)
		return null
	if(mode == STOCK_MODE_FACTION && !faction_path)
		return null
	var/datum/brokerage_session/session = new()
	session.mode = mode
	session.trader_name = html_decode(trader_name || "Unknown")
	session.trader_ckey = trader_ckey
	if(account)
		session.account_ref = WEAKREF(account)
	if(premium_account)
		session.premium_account_ref = WEAKREF(premium_account)
	if(mode == STOCK_MODE_FACTION)
		session.faction_path = faction_path
		session.vault_balance = faction_vault_start
		session.vault_start = faction_vault_start
		session.trader_share = trader_share
	sessions += session
	return session

/// Cargo hook: purchases accumulate demand in the matching market sector.
/datum/controller/subsystem/stock_market/proc/on_cargo_trade(mob/user, list/datum/supply_pack/packs)
	if(!market_ready || !length(packs))
		return
	for(var/datum/supply_pack/pack in packs)
		var/sector = category_to_sector(pack.category)
		if(sector)
			sector_demand[sector] += pack.cost

/// Mission hook: results of a faction's ships nudge its issuers by +-1..2%.
/datum/controller/subsystem/stock_market/proc/on_mission_result(datum/overmap/ship/controlled/ship, success)
	if(!market_ready || isnull(ship))
		return
	var/datum/faction/faction = ship.source_template?.faction
	if(!faction)
		return
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(!company.faction_path || SSfactions.factions[company.faction_path] != faction)
			continue
		if(success)
			company.apply_fundamental_shock(rand(1, 2), 0.2)
		else
			company.apply_fundamental_shock(-rand(1, 2), 0.2)

GLOBAL_LIST_INIT(stock_sector_names, list(
	STOCK_SECTOR_DEFENSE = "Оборона",
	STOCK_SECTOR_INDUSTRIAL = "Промышленность",
	STOCK_SECTOR_LOGISTICS = "Логистика",
	STOCK_SECTOR_MATERIALS = "Материалы",
	STOCK_SECTOR_ENERGY = "Энергетика",
	STOCK_SECTOR_AGRO = "Агросектор",
	STOCK_SECTOR_MEDICAL = "Медицина",
	STOCK_SECTOR_FINANCE = "Финансы",
))

GLOBAL_LIST_INIT(stock_category_keywords, list(
	STOCK_SECTOR_DEFENSE = list("ammunition", "gun", "armor", "security", "weapon", "magazine", "attachment", "modsuit", "exosuit"),
	STOCK_SECTOR_INDUSTRIAL = list("industrial", "machines", "hardware"),
	STOCK_SECTOR_LOGISTICS = list("emergency", "life support", "exploration", "telecommunications", "tools"),
	STOCK_SECTOR_MATERIALS = list("materials"),
	STOCK_SECTOR_ENERGY = list("canisters"),
	STOCK_SECTOR_AGRO = list("food", "agricultural", "fishing"),
	STOCK_SECTOR_MEDICAL = list("medical", "cybernetics", "chemistry"),
))

/datum/controller/subsystem/stock_market/proc/category_to_sector(category)
	var/normalized = lowertext(category)
	for(var/sector in GLOB.stock_category_keywords)
		for(var/keyword in GLOB.stock_category_keywords[sector])
			if(findtext(normalized, keyword))
				return sector
	return null

// [SOLARIS-ADD] - STOCK_ADMIN_CONTROL - Проки для админ-панели и терминалов.

/// Меняет глобальную крутилку баланса/таймингов. value уже валидирован панелью.
/datum/controller/subsystem/stock_market/proc/set_global_param(param, value)
	switch(param)
		if("market_wait")
			market_wait = value
			wait = value
		if("broker_fee_percent")
			broker_fee_percent = max(0, value)
		if("mm_spread")
			mm_spread = max(0, value)
		if("mean_reversion")
			mean_reversion = max(0, value)
		if("max_position_share")
			max_position_share = max(0, min(1, value))
		if("faction_vault_start")
			faction_vault_start = max(0, value)
		if("trader_share")
			trader_share = max(0, min(1, value))
		if("demand_threshold")
			demand_threshold = max(1, value)
		if("demand_decay")
			demand_decay = max(0, min(1, value))
		if("demand_shock_max")
			demand_shock_max = max(0, value)
		if("event_interval_min")
			event_interval_min = max(1, value)
		if("event_interval_max")
			event_interval_max = max(1, value)
		if("max_orders_per_session")
			max_orders_per_session = max(1, round(value))
		if("news_feed_length")
			news_feed_length = max(1, round(value))

/// Принудительный тик: работает только когда рынок не на паузе.
/datum/controller/subsystem/stock_market/proc/force_tick()
	if(!market_ready || market_paused)
		return FALSE
	fire()
	return TRUE

/// Немедленно прогоняет случайное событие (мимо интервала), с оверрайдами.
/datum/controller/subsystem/stock_market/proc/force_event()
	if(!market_ready)
		return null
	maybe_roll_event(ignore_interval = TRUE)

/// Запускает конкретное событие; target_ticker пинает конкуренту (или всему рынку).
/datum/controller/subsystem/stock_market/proc/fire_named_event(event_type, target_ticker = null)
	if(!market_ready)
		return null
	var/datum/stock_event/event_datum = new event_type()
	apply_event_overrides(event_datum, event_type)
	if(target_ticker && !event_datum.market_wide)
		var/datum/stock_company/company = companies[target_ticker]
		if(!company)
			return null
		var/list/before = snapshot_fundamentals(event_datum, company)
		apply_event_to(event_datum, company)
		return add_news(event_datum.headline, company, compute_impacts(before))
	fire_event(event_datum)
	return event_datum.headline

/// Эффективные оверрайды события для отображения в панели.
/datum/controller/subsystem/stock_market/proc/get_event_overrides(event_type)
	return event_overrides["[event_type]"]

/// Записывает рантайм-оверрайд поля события. Оверрайды применяются к новым инстансам.
/datum/controller/subsystem/stock_market/proc/set_event_override(event_type, field, value)
	var/key = "[event_type]"
	if(!event_overrides[key])
		event_overrides[key] = list()
	event_overrides[key][field] = value

/datum/controller/subsystem/stock_market/proc/clear_event_overrides(event_type)
	event_overrides -= "[event_type]"

/// Натягивает оверрайды на свежесозданный инстанс события.
/datum/controller/subsystem/stock_market/proc/apply_event_overrides(datum/stock_event/event_datum, event_type)
	var/list/overrides = event_overrides["[event_type]"]
	if(!overrides)
		return
	for(var/field in overrides)
		event_datum.vars[field] = overrides[field]

/// Меняет живое поле компании (работает мгновенно на последующие тики).
/datum/controller/subsystem/stock_market/proc/set_company_param(ticker, field, value)
	var/datum/stock_company/company = companies[ticker]
	if(!company || isnull(value))
		return FALSE
	company.vars[field] = value
	return TRUE

/// Ручной шок фундаментала эмитента для админов (с распространением по сектору).
/datum/controller/subsystem/stock_market/proc/admin_company_shock(ticker, percent)
	var/datum/stock_company/company = companies[ticker]
	if(!company)
		return FALSE
	company.apply_fundamental_shock(percent, 0.4)
	return TRUE

/// Халт/возобновление торгов по тикеру. halt_ticks = 0 возобновляет.
/datum/controller/subsystem/stock_market/proc/admin_toggle_halt(ticker, halt_ticks)
	var/datum/stock_company/company = companies[ticker]
	if(!company)
		return FALSE
	company.halted_until_tick = halt_ticks ? ticks_elapsed + halt_ticks : 0
	return TRUE

/// Постит кастомную новость от имени рынка.
/datum/controller/subsystem/stock_market/proc/admin_post_news(admin_name, text)
	if(!text || !length(trim(text)))
		return FALSE
	add_news("[admin_name]: [trim(text)]")
	return TRUE

/// Сессия терминала по ключу (ship:[REF] / personal:[REF]).
/datum/controller/subsystem/stock_market/proc/get_terminal_session(key)
	return terminal_sessions[key]

/datum/controller/subsystem/stock_market/proc/register_terminal_session(key, datum/brokerage_session/session)
	terminal_sessions[key] = session

/// Чистая наличность сессии (счёт или пул фракции).
/datum/controller/subsystem/stock_market/proc/stock_sector_demand_view()
	var/list/out = list()
	for(var/sector in sector_demand)
		out += list(list(
			"name" = sector,
			"demand" = round(sector_demand[sector]),
			"threshold" = demand_threshold,
		))
	return out
// [/SOLARIS-ADD] - STOCK_ADMIN_CONTROL

// [SOLARIS-ADD] - STOCK_TERMINAL_SHARED
// Общие хелперы терминала: используются и машиной stock_terminal, и
// устанавливаемым на ПДА приложением stock_terminal. Формат сессии:
//   STOCK_MODE_FACTION -> общий виртуальный пул фракции корабля
//   STOCK_MODE_PERSONAL -> личный счёт по банковской карте

/// Создаёт/подхватывает сессию терминала по карте игрока. Фракция берётся из
/// ship_access ID-карты игрока, а не из зоны установки терминала — терминал
/// может стоять хоть на аванпосте в нейтральной зоне. Возвращает list("session"/"error").
/datum/controller/subsystem/stock_market/proc/terminal_session(mob/living/user)
	if(!iscarbon(user))
		return list("session" = null, "error" = "Для работы с биржей нужна ID-карта с доступом к кораблю.")
	var/mob/living/carbon/carbon_user = user
	var/obj/item/card/id/id_card = carbon_user.get_idcard(FALSE)
	var/datum/overmap/ship/controlled/ship = id_card ? (locate(/datum/overmap/ship/controlled) in id_card.ship_access) : null
	var/datum/faction/faction = ship?.source_template?.faction
	var/use_personal = isnull(ship) || isnull(faction) || istype(faction, /datum/faction/pirate) || istype(faction, /datum/faction/independent)
	if(use_personal)
		var/datum/bank_account/account = carbon_user.get_bank_account()
		if(!account)
			return list("session" = null, "error" = "Для личного счёта нужна банковская карта.")
		var/key = "personal:[REF(account)]"
		var/datum/brokerage_session/session = get_terminal_session(key)
		if(session && session.get_account() != account)
			session = null
		if(!session)
			session = create_session(STOCK_MODE_PERSONAL, account, null, carbon_user.real_name, carbon_user.ckey)
			if(session)
				register_terminal_session(key, session)
		return list("session" = session)
	var/key = "ship:[REF(ship)]"
	var/datum/brokerage_session/session = get_terminal_session(key)
	if(!session)
		var/datum/bank_account/premium_account = carbon_user.get_bank_account()
		session = create_session(STOCK_MODE_FACTION, null, faction.type, ship.name, null, premium_account)
		if(session)
			register_terminal_session(key, session)
	return list("session" = session)

/// Полный набор данных интерфейса терминала (машина и ПДА используют одно и то же представление).
/datum/controller/subsystem/stock_market/proc/terminal_ui_data(datum/brokerage_session/session, last_error)
	var/list/data = list()
	var/list/snapshot = market_snapshot()
	data["market"] = list(
		"running" = !market_paused,
		"paused" = market_paused,
		"ticks" = ticks_elapsed,
		"turnover" = turnover_total,
		"sectors" = stock_sector_demand_view(),
		"news" = news_feed,
		"trades" = snapshot["trades"],
	)
	data["error"] = last_error
	data["leaderboard"] = snapshot["leaderboard"]
	data["pools"] = snapshot["pools"]
	data["holders"] = snapshot["holders"]
	if(session)
		var/session_error = session.last_error
		if(session_error && !last_error)
			data["error"] = session_error
		var/list/session_data = list(
			"mode" = session.mode,
			"faction_name" = "",
			"trader_name" = session.trader_name,
			"cash" = session.cash_balance(),
			"net_worth" = session.net_worth(),
			"net_pl" = session.net_pl,
			"positions" = list(),
			"orders" = list(),
		)
		if(session.mode == STOCK_MODE_FACTION && SSfactions?.factions[session.faction_path])
			session_data["faction_name"] = SSfactions.faction_name(session.faction_path)
		for(var/target_ticker in session.positions)
			var/list/position = session.positions[target_ticker]
			var/datum/stock_company/company = companies[target_ticker]
			var/list/quotes = company?.get_quotes()
			var/mark_price = quotes ? quotes["bid"] : (company?.price || 0)
			var/value = round(mark_price * position["count"], 1)
			var/pl = round(value - position["avg_cost"] * position["count"], 1)
			session_data["positions"] += list(list(
				"ticker" = target_ticker,
				"count" = position["count"],
				"avg_cost" = position["avg_cost"],
				"price" = mark_price,
				"value" = value,
				"pl" = pl,
			))
		for(var/datum/stock_order/order in session.orders)
			session_data["orders"] += list(list(
				"id" = order.id,
				"type" = order.order_type,
				"ticker" = order.ticker,
				"count" = order.count,
				"limit" = order.limit_price,
				"created_tick" = order.created_tick,
			))
		data["session"] = session_data

	var/list/companies_data = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		var/list/quotes = company.get_quotes()
		var/change = 0
		if(length(company.history) >= 2 && company.history[1])
			change = round((company.price - company.history[1]) / company.history[1] * 100, 1)
		var/list/company_data = list(
			"ticker" = company.ticker,
			"name" = company.name,
			"blurb" = company.blurb,
			"sector" = company.sector,
			"price" = company.price,
			"fundamental" = round(company.fundamental, 1),
			"volatility" = round(company.volatility * company.vol_mult * 100, 2),
			"change" = change,
			"halted" = company.halted_until_tick > ticks_elapsed,
			"depth" = company.depth,
			"float_shares" = company.float_shares,
			"bid" = quotes ? quotes["bid"] : 0,
			"ask" = quotes ? quotes["ask"] : 0,
			"history" = company.history,
		)
		companies_data += list(company_data)
	data["companies"] = companies_data
	return data

/// Обработка торговых действий интерфейса. Возвращает list("ok"/"error") или null для чужих экшенов.
/// На входе actions/buy/sell/place_limit/cancel_order — общие для машины и ПДА.
/datum/controller/subsystem/stock_market/proc/handle_terminal_act(action, list/params, datum/brokerage_session/session)
	if(!session)
		return null
	switch(action)
		if("buy")
			var/count = text2num(params["count"])
			if(!session.buy(params["ticker"], count))
				return list("ok" = FALSE, "error" = session.last_error)
		if("sell")
			var/count = text2num(params["count"])
			if(!session.sell(params["ticker"], count))
				return list("ok" = FALSE, "error" = session.last_error)
		if("place_limit")
			var/order_type = params["type"] == "sell" ? STOCK_ORDER_SELL : STOCK_ORDER_BUY
			var/count = text2num(params["count"])
			var/limit = text2num(params["price"])
			if(!session.place_limit(order_type, params["ticker"], count, limit))
				return list("ok" = FALSE, "error" = session.last_error)
		if("cancel_order")
			if(!session.cancel_order(text2num(params["id"])))
				return list("ok" = FALSE, "error" = session.last_error)
		else
			return null
	return list("ok" = TRUE, "error" = "")

/// Публичная сводка «Лидеры»: личные счёты по реализованному P/L (top 5).
/datum/controller/subsystem/stock_market/proc/trader_leaderboard()
	var/list/ranked = sortTim(sessions.Copy(), GLOBAL_PROC_REF(cmp_stock_session_pl_dsc))
	. = list()
	for(var/i in 1 to min(STOCK_LEADERBOARD_LIMIT, length(ranked)))
		. += leaderboard_session_entry(ranked[i])

/// Публичная сводка «Лидеры»: пулы фракций по дельте хранилища (top 5).
/datum/controller/subsystem/stock_market/proc/faction_pool_leaderboard()
	var/list/pools = list()
	for(var/datum/brokerage_session/session in sessions)
		if(session.mode == STOCK_MODE_FACTION)
			pools += session
	pools = sortTim(pools, GLOBAL_PROC_REF(cmp_stock_session_vault_dsc))
	. = list()
	for(var/i in 1 to min(STOCK_LEADERBOARD_LIMIT, length(pools)))
		. += leaderboard_session_entry(pools[i])

/// Крупнейшие держатели акций эмитента по сумме позиций всех сессий (top-3).
/datum/controller/subsystem/stock_market/proc/shareholder_snapshot(ticker)
	var/datum/stock_company/company = companies[ticker]
	if(!company)
		return list()
	var/list/agg = list()
	for(var/datum/brokerage_session/session in sessions)
		var/list/position = session.positions[ticker]
		if(!position || position["count"] <= 0)
			continue
		var/current = agg[session.trader_name]
		agg[session.trader_name] = (current || 0) + position["count"]
	var/list/rows = list()
	for(var/name in agg)
		rows += list(list(
			"name" = name,
			"count" = agg[name],
			"pct" = round(agg[name] / max(company.float_shares, 1) * 100, 1),
		))
	sortTim(rows, /proc/cmp_stock_holder_dsc)
	if(length(rows) > 3)
		rows.Cut(4)
	return rows

/proc/cmp_stock_holder_dsc(list/a, list/b)
	return b["count"] - a["count"]

/// Публичная лента торгов — свежие сделки всех сессий.
/datum/controller/subsystem/stock_market/proc/trade_tape_view()
	if(length(trade_log) > STOCK_TRADE_LOG_VIEW)
		return trade_log.Copy(1, STOCK_TRADE_LOG_VIEW + 1)
	return trade_log

/// Публичный снимок рынка для UI, собираемый не чаще раза в N тиков.
/datum/controller/subsystem/stock_market/proc/market_snapshot()
	if(length(snapshot_cache) && ticks_elapsed - snapshot_cache_tick < STOCK_SNAPSHOT_CACHE_TICKS)
		return snapshot_cache
	snapshot_cache = list(
		"leaderboard" = trader_leaderboard(),
		"pools" = faction_pool_leaderboard(),
		"holders" = collect_holders_snapshot(),
		"trades" = trade_tape_view(),
	)
	snapshot_cache_tick = ticks_elapsed
	return snapshot_cache

/// Держатели по всем эмитентам: ticker -> list(holder-строк).
/datum/controller/subsystem/stock_market/proc/collect_holders_snapshot()
	var/list/out = list()
	for(var/ticker in companies)
		out[ticker] = shareholder_snapshot(ticker)
	return out

/// Записывает исполненную сделку в публичную ленту.
/datum/controller/subsystem/stock_market/proc/log_trade(actor, ticker, side, count, price)
	var/display_name = html_decode(actor || "")
	if(!display_name || display_name == "Unknown")
		display_name = "Неизвестный"
	trade_log.Insert(1, list(
		"tick" = ticks_elapsed,
		"actor" = display_name,
		"ticker" = ticker,
		"side" = side == STOCK_ORDER_BUY ? "buy" : "sell",
		"count" = count,
		"price" = round(price, 1),
	))
	if(length(trade_log) > STOCK_TRADE_LOG_LENGTH)
		trade_log.Cut(STOCK_TRADE_LOG_LENGTH + 1)
	// Сделка двигает рынок — сбрасываю снимок, чтобы лидеры/держатели обновились сразу.
	snapshot_cache_tick = -STOCK_SNAPSHOT_CACHE_TICKS

/// Строка таблицы лидеров: имя, фракция, капитал, P/L и топ-3 позиции по стоимости.
/datum/controller/subsystem/stock_market/proc/leaderboard_session_entry(datum/brokerage_session/session)
	var/list/positions = list()
	for(var/target_ticker in session.positions)
		var/list/position = session.positions[target_ticker]
		var/datum/stock_company/company = companies[target_ticker]
		var/list/quotes = company?.get_quotes()
		var/mark_price = quotes ? quotes["bid"] : (company?.price || 0)
		positions += list(list(
			"ticker" = target_ticker,
			"count" = position["count"],
			"value" = round(mark_price * position["count"], 1),
		))
	sortTim(positions, GLOBAL_PROC_REF(cmp_stock_position_value_dsc))
	var/list/top_positions = list()
	for(var/i in 1 to min(3, length(positions)))
		top_positions += positions[i]
	var/faction_name = ""
	if(session.mode == STOCK_MODE_FACTION && SSfactions?.factions[session.faction_path])
		faction_name = SSfactions.faction_name(session.faction_path)
	return list(
		"name" = session.trader_name,
		"faction_name" = faction_name,
		"cash" = session.cash_balance(),
		"net_worth" = session.net_worth(),
		"net_pl" = session.net_pl,
		"positions" = top_positions,
	)

/proc/cmp_stock_position_value_dsc(list/a, list/b)
	return b["value"] - a["value"]
// [/SOLARIS-ADD] - STOCK_TERMINAL_SHARED
