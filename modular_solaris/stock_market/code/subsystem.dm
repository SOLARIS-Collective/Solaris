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

/datum/controller/subsystem/stock_market/Initialize(timeofday)
	. = ..()
	for(var/company_type in subtypesof(/datum/stock_company))
		var/datum/stock_company/company = new company_type()
		companies[company.ticker] = company
	generate_history()
	generate_opening_situation()
	next_event_tick = ticks_elapsed + rand(STOCK_EVENT_INTERVAL_MIN, STOCK_EVENT_INTERVAL_MAX)
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
	hyped.apply_fundamental_shock(rand(25, 45), 0.2)
	add_news("Pre-market speculation sends %TICKER% (%NAME%) surging", hyped)
	if(length(all_tickers) < 2)
		return
	var/datum/stock_company/crushed = companies[all_tickers[2]]
	crushed.apply_fundamental_shock(-rand(25, 40), 0.2)
	add_news("%TICKER% (%NAME%) slides ahead of the opening bell", crushed)

/datum/controller/subsystem/stock_market/fire(resumed)
	if(!market_ready)
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
		sector_demand[sector] *= STOCK_DEMAND_DECAY
		if(sector_demand[sector] < STOCK_DEMAND_THRESHOLD)
			continue
		fire_sector_demand_shock(sector)
		sector_demand[sector] = 0

/datum/controller/subsystem/stock_market/proc/fire_sector_demand_shock(sector)
	var/shock = sector_demand[sector] / STOCK_DEMAND_THRESHOLD * STOCK_DEMAND_SHOCK_MAX
	shock = min(STOCK_DEMAND_SHOCK_MAX, max(1, shock))
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company.sector == sector)
			company.fundamental = max(company.fundamental * (1 + shock / 100), 1)
	add_news("Unusual order flow lifts fundamentals across the [sector] sector")

/// Applies pending hype/panic reversions once their window expires.
/datum/controller/subsystem/stock_market/proc/process_event_expiries()
	for(var/list/effect in active_events)
		if(ticks_elapsed < effect["expiry"])
			continue
		var/datum/stock_company/company = effect["company"]
		company.revert_fundamental(effect["percent"])
		active_events -= effect

/datum/controller/subsystem/stock_market/proc/maybe_roll_event()
	if(ticks_elapsed < next_event_tick)
		return
	next_event_tick = ticks_elapsed + rand(STOCK_EVENT_INTERVAL_MIN, STOCK_EVENT_INTERVAL_MAX)
	var/list/weighted = list()
	for(var/event_type in subtypesof(/datum/stock_event))
		var/datum/stock_event/template = event_type
		if(template.gameplay_driven)
			continue
		weighted[event_type] = template.weight
	var/chosen_type = pick_weight(weighted)
	if(chosen_type)
		fire_event(new chosen_type())

/// Fires an ambient event on a random eligible target (or the whole market).
/datum/controller/subsystem/stock_market/proc/fire_event(datum/stock_event/event_datum)
	if(event_datum.gameplay_driven)
		return
	if(event_datum.market_wide)
		for(var/ticker in companies)
			apply_event_to(event_datum, companies[ticker])
		add_news(event_datum.headline)
		return
	var/list/candidates = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(!event_datum.valid_sectors || (company.sector in event_datum.valid_sectors))
			candidates += company
	if(!length(candidates))
		return
	var/datum/stock_company/target = pick(candidates)
	apply_event_to(event_datum, target)
	add_news(event_datum.headline, target)

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
/datum/controller/subsystem/stock_market/proc/add_news(headline, datum/stock_company/company = null)
	var/name_text = company ? company.name : "the market"
	var/ticker_text = company ? company.ticker : "MKT"
	var/text = replacetext(replacetext(headline, "%NAME%", name_text), "%TICKER%", ticker_text)
	news_feed.Insert(1, text)
	if(length(news_feed) > STOCK_NEWS_FEED_LENGTH)
		news_feed.Cut(STOCK_NEWS_FEED_LENGTH + 1)
	return text

/// Registers a brokerage session for a trader. Returns it or null on bad args.
/datum/controller/subsystem/stock_market/proc/create_session(mode, datum/bank_account/account, faction_path, trader_name, trader_ckey, datum/bank_account/premium_account)
	if(mode == STOCK_MODE_PERSONAL && !account)
		return null
	if(mode == STOCK_MODE_FACTION && !faction_path)
		return null
	var/datum/brokerage_session/session = new()
	session.mode = mode
	session.trader_name = trader_name || "Unknown"
	session.trader_ckey = trader_ckey
	if(account)
		session.account_ref = WEAKREF(account)
	if(premium_account)
		session.premium_account_ref = WEAKREF(premium_account)
	if(mode == STOCK_MODE_FACTION)
		session.faction_path = faction_path
		session.vault_balance = STOCK_FACTION_VAULT_START
		session.vault_start = STOCK_FACTION_VAULT_START
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
// [/SOLARIS-ADD]
