// [SOLARIS-ADD] - STOCK_MARKET
/// Settles every session and publishes the shift leaderboard before the roundend report.
/datum/controller/subsystem/stock_market/proc/finalize_round()
	if(!market_ready)
		return
	for(var/datum/brokerage_session/session in sessions)
		session.settle_premium()
	var/list/report_lines = build_report_lines()
	to_chat(world, boxed_message(jointext(report_lines, "\n")))
	world.log << "STOCK MARKET SHIFT SUMMARY: [jointext(report_lines, " | ")]"

/datum/controller/subsystem/stock_market/proc/build_report_lines()
	. = list("<b>=== Frontier Stock Exchange — shift results ===</b>")
	. += trader_report_lines()
	. += faction_pool_lines()
	. += market_report_lines()

/// Top traders by realized P/L over the shift.
/datum/controller/subsystem/stock_market/proc/trader_report_lines()
	var/list/sorted = sortTim(sessions.Copy(), GLOBAL_PROC_REF(cmp_stock_session_pl_dsc))
	. = list()
	for(var/i in 1 to min(3, length(sorted)))
		var/datum/brokerage_session/session = sorted[i]
		. += "<b>[session.trader_name]</b> ([session.trader_ckey || "no ckey"]): net P/L <b>[session.net_pl] cr</b>"
	if(!length(.))
		. += "No traders registered this shift."

/// Faction pools ranked by vault gain over the shift.
/datum/controller/subsystem/stock_market/proc/faction_pool_lines()
	var/list/pools = list()
	for(var/datum/brokerage_session/session in sessions)
		if(session.mode == STOCK_MODE_FACTION)
			pools += session
	pools = sortTim(pools, GLOBAL_PROC_REF(cmp_stock_session_vault_dsc))
	. = list()
	for(var/i in 1 to min(3, length(pools)))
		var/datum/brokerage_session/session = pools[i]
		. += "Pool <b>[SSfactions.faction_name(session.faction_path)]</b>: vault delta <b>[session.vault_delta()] cr</b>"

/datum/controller/subsystem/stock_market/proc/market_report_lines()
	var/best_ticker = null
	var/worst_ticker = null
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(isnull(best_ticker) || company.round_change_percent() > companies[best_ticker].round_change_percent())
			best_ticker = ticker
		if(isnull(worst_ticker) || company.round_change_percent() < companies[worst_ticker].round_change_percent())
			worst_ticker = ticker
	var/datum/stock_company/best_company = companies[best_ticker]
	var/datum/stock_company/worst_company = companies[worst_ticker]
	. = list(
		"Best of the shift: <b>[best_ticker]</b> ([best_company?.round_change_percent()]%)",
		"Worst of the shift: <b>[worst_ticker]</b> ([worst_company?.round_change_percent()]%)",
		"Exchange turnover: <b>[turnover_total] cr</b> across [length(sessions)] session(s).",
	)

/proc/cmp_stock_session_pl_dsc(datum/brokerage_session/a, datum/brokerage_session/b)
	return b.net_pl - a.net_pl

/proc/cmp_stock_session_vault_dsc(datum/brokerage_session/a, datum/brokerage_session/b)
	return b.vault_delta() - a.vault_delta()
// [/SOLARIS-ADD]
