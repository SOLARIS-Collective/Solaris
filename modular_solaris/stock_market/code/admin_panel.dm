// [SOLARIS-ADD] - STOCK_ADMIN_CONTROL
// Админ-панель биржи: полный runtime-контроль параметров, эмитентов, событий,
// новостей и паузы рынка. Верб добавлен в admin_verbs_admin (ядро, admin_verbs.dm).

/client/proc/stock_market_control()
	set name = "Фондовая биржа: контроль"
	set category = "Admin.Game"

	if(!check_rights(R_ADMIN))
		return
	var/datum/stock_market_admin/panel = new(usr)
	panel.ui_interact(usr)

/// Datum-интерфейс админ-панели биржи (доступ только с R_ADMIN).
/datum/stock_market_admin
	var/mob/owner

/datum/stock_market_admin/New(mob/user)
	owner = user

/datum/stock_market_admin/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StockAdmin", "Фондовая биржа: контроль")
		ui.open()

/datum/stock_market_admin/ui_state(mob/user)
	return GLOB.admin_state

/datum/stock_market_admin/ui_static_data(mob/user)
	return list(
		"sectors" = list(
			STOCK_SECTOR_DEFENSE,
			STOCK_SECTOR_INDUSTRIAL,
			STOCK_SECTOR_LOGISTICS,
			STOCK_SECTOR_MATERIALS,
			STOCK_SECTOR_ENERGY,
			STOCK_SECTOR_AGRO,
			STOCK_SECTOR_MEDICAL,
			STOCK_SECTOR_FINANCE,
		),
		"modes" = list("Личный счёт" = STOCK_MODE_PERSONAL, "Фракционный пул" = STOCK_MODE_FACTION),
	)

/datum/stock_market_admin/ui_data(mob/user)
	var/list/data = list()
	var/datum/controller/subsystem/stock_market/ss = SSstock_market

	data["global"] = list(
		"paused" = ss.market_paused,
		"ready" = ss.market_ready,
		"ticks" = ss.ticks_elapsed,
		"next_event_tick" = ss.next_event_tick,
		"turnover" = ss.turnover_total,
		"market_wait" = ss.market_wait / 10,
		"broker_fee_percent" = ss.broker_fee_percent,
		"mm_spread" = ss.mm_spread,
		"mean_reversion" = ss.mean_reversion,
		"max_position_share" = ss.max_position_share,
		"faction_vault_start" = ss.faction_vault_start,
		"trader_share" = ss.trader_share,
		"demand_threshold" = ss.demand_threshold,
		"demand_decay" = ss.demand_decay,
		"demand_shock_max" = ss.demand_shock_max,
		"event_interval_min" = ss.event_interval_min,
		"event_interval_max" = ss.event_interval_max,
		"max_orders_per_session" = ss.max_orders_per_session,
		"news_feed_length" = ss.news_feed_length,
		"history_length" = STOCK_HISTORY_LENGTH,
	)
	data["sectors"] = ss.stock_sector_demand_view()
	data["news"] = ss.news_feed

	var/list/companies_data = list()
	for(var/ticker in ss.companies)
		var/datum/stock_company/company = ss.companies[ticker]
		var/list/quotes = company.get_quotes()
		companies_data += list(list(
			"ticker" = company.ticker,
			"name" = company.name,
			"blurb" = company.blurb,
			"sector" = company.sector,
			"faction" = company.faction_path ? SSfactions.faction_name(company.faction_path) : "",
			"base_price" = company.base_price,
			"volatility" = company.volatility,
			"depth" = company.depth,
			"float_shares" = company.float_shares,
			"fundamental" = round(company.fundamental, 1),
			"price" = company.price,
			"halted" = company.halted_until_tick > ss.ticks_elapsed,
			"halt_until" = company.halted_until_tick,
			"bid" = quotes ? quotes["bid"] : 0,
			"ask" = quotes ? quotes["ask"] : 0,
		))
	data["companies"] = companies_data

	var/list/events_data = list()
	for(var/event_type in subtypesof(/datum/stock_event))
		var/datum/stock_event/template = event_type
		var/list/overrides = ss.get_event_overrides(event_type)
		var/list/entry = list(
			"type" = "[event_type]",
			"script" = "[event_type]",
			"name" = template.name,
			"headline" = template.headline,
			"weight" = template.weight,
			"valid_sectors" = template.valid_sectors,
			"shock_min" = template.shock_min,
			"shock_max" = template.shock_max,
			"volatility_mult" = template.volatility_mult,
			"duration_ticks" = template.duration_ticks,
			"peer_spread" = template.peer_spread,
			"revert_share" = template.revert_share,
			"halt_ticks" = template.halt_ticks,
			"rival_drag" = template.rival_drag,
			"market_wide" = template.market_wide ? 1 : 0,
			"gameplay_driven" = template.gameplay_driven ? 1 : 0,
		)
		if(overrides)
			for(var/field in overrides)
				entry[field] = overrides[field]
				if(field == "market_wide")
					entry["market_wide"] = overrides[field] ? 1 : 0
		events_data += list(entry)
	data["events"] = events_data

	data["sessions"] = list()
	for(var/datum/brokerage_session/session in ss.sessions)
		if(session.settled)
			continue
		var/list/session_data = list(
			"mode" = session.mode,
			"trader_name" = session.trader_name,
			"faction_name" = session.mode == STOCK_MODE_FACTION ? SSfactions.faction_name(session.faction_path) : "",
			"cash" = session.cash_balance(),
			"net_pl" = round(session.net_pl, 1),
			"open_positions" = 0,
			"open_orders" = length(session.orders),
		)
		for(var/ticker in session.positions)
			session_data["open_positions"] += 1
		data["sessions"] += list(session_data)
	return data

/datum/stock_market_admin/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights(R_ADMIN))
		return
	var/datum/controller/subsystem/stock_market/ss = SSstock_market

	switch(action)
		if("toggle_pause")
			ss.market_paused = !ss.market_paused
		if("force_tick")
			if(ss.market_paused)
				to_chat(usr, span_warning("Рынок на паузе — снимите паузу, чтобы прогнать тик."))
			else
				ss.force_tick()
		if("force_event")
			ss.force_event()
		if("set_global")
			ss.set_global_param(params["param"], text2num(params["value"]))
		if("set_sector_demand")
			var/sector = params["sector"]
			var/value = max(0, text2num(params["value"]))
			if(value)
				ss.sector_demand[sector] = value
			else
				ss.sector_demand -= sector
		if("set_company")
			var/ticker = params["ticker"]
			var/field = params["field"]
			var/value = params["value"]
			var/datum/stock_company/company = ss.companies[ticker]
			if(!company)
				return
			switch(field)
				if("name", "blurb", "sector")
					ss.set_company_param(ticker, field, value)
				else
					ss.set_company_param(ticker, field, text2num(value))
					if(field == "price" && length(company.history))
						company.history[company.history.len] = company.price
		if("company_shock")
			ss.admin_company_shock(params["ticker"], text2num(params["percent"]))
		if("company_halt")
			ss.admin_toggle_halt(params["ticker"], text2num(params["halt"]))
		if("fire_event")
			var/event_type = text2path(params["event_type"])
			if(event_type)
				ss.fire_named_event(event_type, params["ticker"])
		if("set_event")
			var/event_type = text2path(params["event_type"])
			if(!event_type)
				return
			var/field = params["field"]
			var/value = params["value"]
			switch(field)
				if("name", "headline", "valid_sectors")
					ss.set_event_override(event_type, field, value)
				else
					var/num_value = text2num(value)
					if(field == "market_wide")
						ss.set_event_override(event_type, field, num_value ? TRUE : FALSE)
					else
						ss.set_event_override(event_type, field, num_value)
		if("clear_event")
			var/event_type = text2path(params["event_type"])
			if(event_type)
				ss.clear_event_overrides(event_type)
		if("dump_json")
			to_chat(usr, span_adminnotice("=== NEWS (первые 5, как ушли в клиент) ==="))
			for(var/i in 1 to min(5, length(ss.news_feed)))
				to_chat(usr, "[json_encode(ss.news_feed[i])]")
			to_chat(usr, span_adminnotice("=== TRADE LOG ==="))
			to_chat(usr, "[json_encode(ss.trade_log)]")
		if("post_news")
			var/text = sanitize_text(params["text"])
			if(!text)
				return
			ss.admin_post_news(isnull(owner) ? "Администратор" : owner.key, text)
		else
			return
	. = TRUE
// [/SOLARIS-ADD]