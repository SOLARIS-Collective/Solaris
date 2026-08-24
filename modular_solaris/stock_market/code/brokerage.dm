// [SOLARIS-ADD] - STOCK_MARKET
/// Resting limit order. No escrow: funds and positions are re-checked at fill time.
/datum/stock_order
	/// Sequential id within the session
	var/id = 0
	/// STOCK_ORDER_BUY or STOCK_ORDER_SELL (order_type: `type` is reserved by DM)
	var/order_type = STOCK_ORDER_BUY
	var/ticker = ""
	var/count = 0
	/// Fills when the maker quote crosses this price
	var/limit_price = 0
	var/status = STOCK_FILL_RESTING
	var/created_tick = 0
	var/datum/brokerage_session/session

/datum/stock_order/New(datum/brokerage_session/session_ref, new_order_type, new_ticker, new_count, new_limit_price)
	..()
	session = session_ref
	order_type = new_order_type
	ticker = new_ticker
	count = new_count
	limit_price = new_limit_price
	created_tick = SSstock_market.ticks_elapsed
	session.order_seq += 1
	id = session.order_seq

/// One trader's brokerage account over a shift.
/// PERSONAL mode trades a real bank_account; FACTION mode trades a virtual faction pool.
/datum/brokerage_session
	var/mode = STOCK_MODE_PERSONAL
	/// PERSONAL mode only: source of real credits
	var/datum/weakref/account_ref
	/// FACTION mode only: issuer faction path owning the vault
	var/faction_path = null
	var/vault_balance = 0
	/// Snapshot for roundend reporting of the pool delta
	var/vault_start = 0
	/// Share of net P/L paid to (or recovered from) the trader at settlement
	var/trader_share = STOCK_TRADER_SHARE
	/// Realized P/L including fees; drives the roundend premium
	var/net_pl = 0
	var/turnover = 0
	var/trader_name = "Unknown"
	var/trader_ckey = null
	/// Where the premium lands (trader's personal account)
	var/datum/weakref/premium_account_ref
	/// ticker -> list("count" = n, "avg_cost" = x)
	var/list/positions = list()
	var/list/orders = list()
	var/order_seq = 0
	var/last_error = ""
	var/settled = FALSE

/// Resolves the backing bank account; null means it is gone.
/datum/brokerage_session/proc/get_account()
	var/datum/bank_account/account = account_ref?.resolve()
	return account

/datum/brokerage_session/proc/can_afford(amount)
	if(mode == STOCK_MODE_FACTION)
		return vault_balance >= amount
	var/datum/bank_account/account = get_account()
	return !isnull(account) && account.has_money(amount)

/// Takes credits out of the personal account or the faction vault.
/datum/brokerage_session/proc/debit(amount)
	if(mode == STOCK_MODE_FACTION)
		vault_balance -= amount
		return TRUE
	var/datum/bank_account/account = get_account()
	if(isnull(account))
		last_error = "Bank account unavailable."
		return FALSE
	if(!account.adjust_money(-amount, CREDIT_LOG_STOCK_BUY))
		last_error = "Insufficient funds."
		return FALSE
	return TRUE

/// Puts credits into the personal account or the faction vault.
/datum/brokerage_session/proc/credit(amount)
	if(mode == STOCK_MODE_FACTION)
		vault_balance += amount
		return TRUE
	var/datum/bank_account/account = get_account()
	if(isnull(account))
		last_error = "Bank account unavailable."
		return FALSE
	account.adjust_money(amount, CREDIT_LOG_STOCK_SELL)
	return TRUE

/datum/brokerage_session/proc/validate_trade(datum/stock_company/company, count)
	if(!company)
		last_error = "Unknown ticker."
		return FALSE
	if(count <= 0 || count != round(count))
		last_error = "Invalid share count."
		return FALSE
	return TRUE

/// Market buy at the maker ask plus broker fee.
/datum/brokerage_session/proc/buy(target_ticker, count)
	var/datum/stock_company/company = SSstock_market.companies[target_ticker]
	if(!validate_trade(company, count))
		return FALSE
	var/list/quotes = company.get_quotes()
	if(!quotes)
		last_error = "Trading halted for [target_ticker]."
		return FALSE
	return execute_buy(company, count, quotes["ask"])

/// Market sell at the maker bid minus broker fee.
/datum/brokerage_session/proc/sell(target_ticker, count)
	var/datum/stock_company/company = SSstock_market.companies[target_ticker]
	if(!validate_trade(company, count))
		return FALSE
	var/list/position = positions[target_ticker]
	if(!position || position["count"] < count)
		last_error = "Not enough shares of [target_ticker]."
		return FALSE
	var/list/quotes = company.get_quotes()
	if(!quotes)
		last_error = "Trading halted for [target_ticker]."
		return FALSE
	return execute_sell(company, count, quotes["bid"])

/datum/brokerage_session/proc/execute_buy(datum/stock_company/company, count, unit_price)
	var/max_count = floor(company.float_shares * STOCK_MAX_POSITION_SHARE)
	var/existing = 0
	if(positions[company.ticker])
		existing = positions[company.ticker]["count"]
	if(existing + count > max_count)
		last_error = "Position cap reached for [company.ticker]."
		return FALSE
	var/cost = round(unit_price * count, 1)
	var/fee = round(cost * STOCK_BROKER_FEE_PERCENT / 100, 1)
	if(!can_afford(cost + fee))
		last_error = "Insufficient funds."
		return FALSE
	if(!debit(cost + fee))
		return FALSE
	update_position_buy(company.ticker, count, cost)
	net_pl -= fee
	turnover += cost
	return TRUE

/datum/brokerage_session/proc/update_position_buy(target_ticker, count, cost)
	var/existing = 0
	var/basis = 0
	if(positions[target_ticker])
		existing = positions[target_ticker]["count"]
		basis = positions[target_ticker]["avg_cost"]
	positions[target_ticker] = list(
		"count" = existing + count,
		"avg_cost" = round((existing * basis + cost) / (existing + count), 0.1),
	)

/datum/brokerage_session/proc/execute_sell(datum/stock_company/company, count, unit_price)
	var/proceeds = round(unit_price * count, 1)
	var/fee = round(proceeds * STOCK_BROKER_FEE_PERCENT / 100, 1)
	var/basis = round(positions[company.ticker]["avg_cost"] * count, 1)
	if(!credit(proceeds - fee))
		return FALSE
	net_pl += proceeds - fee - basis
	turnover += proceeds
	reduce_position(company.ticker, count)
	return TRUE

/datum/brokerage_session/proc/reduce_position(target_ticker, count)
	var/list/position = positions[target_ticker]
	position["count"] -= count
	if(position["count"] <= 0)
		positions -= target_ticker

/// Places a limit order without escrow; validity is re-checked at fill time.
/datum/brokerage_session/proc/place_limit(new_order_type, target_ticker, count, limit_price)
	var/datum/stock_company/company = SSstock_market.companies[target_ticker]
	if(!validate_trade(company, count))
		return null
	if(limit_price <= 0)
		last_error = "Invalid limit price."
		return null
	if(new_order_type == STOCK_ORDER_BUY && positions[target_ticker])
		var/max_count = floor(company.float_shares * STOCK_MAX_POSITION_SHARE)
		if(positions[target_ticker]["count"] + count > max_count)
			last_error = "Position cap reached for [target_ticker]."
			return null
	if(length(orders) >= STOCK_MAX_ORDERS_PER_SESSION)
		last_error = "Too many resting orders."
		return null
	var/datum/stock_order/order = new(src, new_order_type, target_ticker, count, limit_price)
	orders += order
	return order

/datum/brokerage_session/proc/cancel_order(order_id)
	for(var/datum/stock_order/order in orders)
		if(order.id != order_id || order.status != STOCK_FILL_RESTING)
			continue
		order.status = STOCK_FILL_CANCELLED
		orders -= order
		return TRUE
	last_error = "Order not found."
	return FALSE

/// Called every market tick; fills resting orders whose limits are crossed.
/datum/brokerage_session/proc/process_orders()
	for(var/datum/stock_order/order in orders.Copy())
		try_fill_limit(order)

/datum/brokerage_session/proc/try_fill_limit(datum/stock_order/order)
	var/datum/stock_company/company = SSstock_market.companies[order.ticker]
	var/list/quotes = company?.get_quotes()
	if(!quotes)
		return
	var/unit_price = quotes["bid"]
	if(order.order_type == STOCK_ORDER_BUY)
		unit_price = quotes["ask"]
	var/fillable = unit_price >= order.limit_price
	if(order.order_type == STOCK_ORDER_BUY)
		fillable = unit_price <= order.limit_price
	if(!fillable)
		return
	var/filled = FALSE
	if(order.order_type == STOCK_ORDER_BUY)
		filled = execute_buy(company, order.count, unit_price)
	else
		filled = execute_sell(company, order.count, unit_price)
	if(filled)
		order.status = STOCK_FILL_FILLED
	else
		order.status = STOCK_FILL_CANCELLED
	orders -= order

/// Cancels everything still resting; used on settlement.
/datum/brokerage_session/proc/cancel_all_orders()
	for(var/datum/stock_order/order in orders.Copy())
		order.status = STOCK_FILL_CANCELLED
	orders.Cut()

/// Roundend premium split. Symmetric: losses are also shared, clamped so the
/// trader never ends up deeper in debt than their own balance allows.
/datum/brokerage_session/proc/settle_premium()
	if(settled || mode != STOCK_MODE_FACTION)
		settled = TRUE
		cancel_all_orders()
		return
	settled = TRUE
	cancel_all_orders()
	var/premium = floor(net_pl * trader_share)
	var/datum/bank_account/payout = premium_account_ref?.resolve()
	if(!premium || isnull(payout))
		return
	if(premium < 0)
		premium = max(premium, -payout.account_balance)
		if(!premium)
			return
	vault_balance -= premium
	payout.adjust_money(premium, CREDIT_LOG_STOCK_PREMIUM)

/// Cash plus open positions valued at maker bids.
/datum/brokerage_session/proc/net_worth()
	var/total = 0
	if(mode == STOCK_MODE_FACTION)
		total = vault_balance
	else
		var/datum/bank_account/account = get_account()
		total = account ? account.account_balance : 0
	for(var/target_ticker in positions)
		var/datum/stock_company/company = SSstock_market.companies[target_ticker]
		var/list/quotes = company.get_quotes()
		if(!quotes)
			continue
		total += quotes["bid"] * positions[target_ticker]["count"]
	return round(total, 1)

/// Pool gain over the shift, for roundend reporting.
/datum/brokerage_session/proc/vault_delta()
	return vault_balance - vault_start
// [/SOLARIS-ADD]
