// [SOLARIS-ADD] - STOCK_MARKET
/// Эмитент биржи. Конкретные компании описаны подтипами в emitters.dm.
/datum/stock_company
	/// Биржевой тикер
	var/ticker = "???"
	var/name = "Unknown Holdings"
	/// Короткое описание для терминала и новостей
	var/blurb = ""
	/// Сектор рынка, константа STOCK_SECTOR_*
	var/sector = STOCK_SECTOR_INDUSTRIAL
	/// Фракция эмитента; игровые хуки двигают такие акции сильнее. Может быть null.
	var/faction_path = null

	/// Стартовый фундаментал до раундового рандома
	var/base_price = 100
	/// Базовая волатильность за тик (сигма доходности)
	var/volatility = 0.02
	/// Ёмкость рынка: сколько акций поглощается без резкого движения цены
	var/depth = 300
	/// Акций в обращении; ограничивает максимальную позицию счёта
	var/float_shares = 10000
	/// Ручные корреляции с другими тикерами (ticker -> коэффициент), поверх секторных
	var/list/correlations = list()

	// --- runtime ---
	/// Справедливая стоимость: двигают новости, события и игровой спрос
	var/fundamental = 100
	/// Рыночная цена
	var/price = 100
	/// Временный множитель волатильности от событий
	var/vol_mult = 1
	/// Тик, до которого действует vol_mult
	var/vol_until_tick = 0
	/// Торги приостановлены до этого тика
	var/halted_until_tick = 0
	/// История цен для графиков и отчётов
	var/list/history = list()

/datum/stock_company/New()
	..()
	fundamental = base_price
	price = base_price

/// Рандомная стартовая ситуация на раунд
/datum/stock_company/proc/randomize_round_start()
	fundamental *= rand(75, 130) / 100
	volatility *= rand(70, 140) / 100
	price = max(fundamental * (1 + gaussian(0, 1) * volatility * 2), 1)

/// Один тик торговли: шум + возврат к фундаменталу
/datum/stock_company/proc/tick(ticks_elapsed)
	if(vol_until_tick && ticks_elapsed > vol_until_tick)
		vol_mult = 1
		vol_until_tick = 0
	var/noise = gaussian(0, 1) * volatility * vol_mult
	price *= 1 + noise + SSstock_market.mean_reversion * ((fundamental - price) / max(fundamental, 1))
	price = max(round(price, 0.1), 1)
	history += price
	if(length(history) > STOCK_HISTORY_LENGTH)
		history.Cut(1, 2)

/// Котировки маркетмейкера; null - торги приостановлены
/datum/stock_company/proc/get_quotes()
	if(halted_until_tick > SSstock_market.ticks_elapsed)
		return null
	var/spread = STOCK_MM_SPREAD // дефолт на случай раннего вызова
	if(!isnull(SSstock_market?.mm_spread))
		spread = SSstock_market.mm_spread
	return list(
		"bid" = round(price * (1 - spread), 0.1),
		"ask" = round(price * (1 + spread), 0.1),
	)

/// Шок фундаментала в процентах. peer_spread - доля шока соседям:
/// всем компаниям того же сектора и тем, с кем есть ручная корреляция.
/datum/stock_company/proc/apply_fundamental_shock(percent, peer_spread = 0.4)
	fundamental = max(fundamental * (1 + percent / 100), 1)
	if(!peer_spread || !SSstock_market?.market_ready)
		return
	for(var/other_ticker in SSstock_market.companies)
		var/datum/stock_company/other = SSstock_market.companies[other_ticker]
		if(other == src)
			continue
		var/k = 0
		if(other.sector == sector)
			k = peer_spread
		else if(!isnull(correlations[other_ticker]))
			k = peer_spread * correlations[other_ticker]
		if(k)
			other.fundamental = max(other.fundamental * (1 + percent * k / 100), 1)

/// Откат части шока после затухания хайпа/паники (percent может быть отрицательным)
/datum/stock_company/proc/revert_fundamental(percent)
	fundamental = max(fundamental * (1 + percent / 100), 1)

/// Изменение цены за раунд, % (для отчётов)
/datum/stock_company/proc/round_change_percent()
	return round((price - base_price) / base_price * 100, 1)
// [/SOLARIS-ADD]
