// [SOLARIS-ADD] - STOCK_MARKET
// Ambient market events. Add new templates as /datum/stock_event subtypes.
// The subsystem picks them by weight, applies the fundamental shock to a single
// issuer (or the whole market) and pushes the headline into the news feed.
/datum/stock_event
	/// Short internal name
	var/name = "market noise"
	/// Headline template; %NAME% and %TICKER% are replaced with issuer data
	var/headline = "%TICKER% (%NAME%) makes headlines on the frontier feeds"
	/// Integer weight for pick_weight
	var/weight = 10
	/// null = any sector, otherwise list of STOCK_SECTOR_* constants
	var/list/valid_sectors = null
	/// Fundamental shock range applied to the target, %
	var/shock_min = -3
	var/shock_max = 3
	/// Temporary volatility multiplier lasting duration_ticks
	var/volatility_mult = 1
	var/duration_ticks = 2
	/// Share of shock propagated to same-sector and correlated peers (0..1)
	var/peer_spread = 0.4
	/// Affects every listed company instead of one picked issuer
	var/market_wide = FALSE
	/// Fraction of the shock reverted once the hype dies out (0..1)
	var/revert_share = 0
	/// Trading halt on the target, in ticks
	var/halt_ticks = 0
	/// Mild drag on issuers outside the target sector (sector rotation), %
	var/rival_drag = 0
	/// Never picked by random rolls; fired from gameplay hooks only
	var/gameplay_driven = FALSE

/datum/stock_event/earnings_beat
	name = "earnings beat"
	headline = "%NAME% отчитался лучше квартальных прогнозов"
	weight = 12
	shock_min = 6
	shock_max = 14
	revert_share = 0.3

/datum/stock_event/earnings_miss
	name = "earnings miss"
	headline = "%NAME% отчитался хуже ожиданий рынка"
	weight = 12
	shock_min = -16
	shock_max = -8

/datum/stock_event/product_launch
	name = "product launch"
	headline = "%NAME% представил новую флагманскую линейку продукции"
	weight = 10
	shock_min = 5
	shock_max = 12
	volatility_mult = 1.5
	revert_share = 0.35

/datum/stock_event/product_recall
	name = "product recall"
	headline = "%NAME% отзывает последнюю партию продукции"
	weight = 9
	shock_min = -14
	shock_max = -6

/datum/stock_event/scandal
	name = "scandal"
	headline = "Коррупционный скандал сотрясает руководство %NAME%"
	weight = 7
	shock_min = -18
	shock_max = -8
	volatility_mult = 1.4

/datum/stock_event/ceo_change
	name = "ceo change"
	headline = "%NAME% объявляет о внезапной смене генерального директора"
	weight = 8
	shock_min = -5
	shock_max = 9
	volatility_mult = 1.4

/datum/stock_event/merger_rumor
	name = "merger rumor"
	headline = "Слух: %NAME% могут купить с премией к рынку"
	weight = 7
	shock_min = 10
	shock_max = 22
	volatility_mult = 2
	duration_ticks = 3
	revert_share = 0.5

/datum/stock_event/strike
	name = "strike"
	headline = "Рабочие на предприятиях %NAME% объявили забастовку"
	weight = 8
	shock_min = -12
	shock_max = -5

/datum/stock_event/gov_contract
	name = "gov contract"
	headline = "%NAME% выигрывает крупный государственный контракт"
	weight = 9
	valid_sectors = list(STOCK_SECTOR_DEFENSE, STOCK_SECTOR_LOGISTICS, STOCK_SECTOR_INDUSTRIAL)
	shock_min = 7
	shock_max = 15

/datum/stock_event/patent_dispute
	name = "patent dispute"
	headline = "%NAME% втянут в дорогостоящий патентный спор"
	weight = 7
	shock_min = -10
	shock_max = -4

/datum/stock_event/breakthrough
	name = "breakthrough"
	headline = "Лаборатории %NAME% сообщают о крупном прорыве"
	weight = 6
	valid_sectors = list(STOCK_SECTOR_MEDICAL, STOCK_SECTOR_ENERGY, STOCK_SECTOR_INDUSTRIAL)
	shock_min = 12
	shock_max = 25
	volatility_mult = 1.8
	revert_share = 0.4

/datum/stock_event/dividend_raise
	name = "dividend raise"
	headline = "%NAME% повышает дивидендные выплаты"
	weight = 8
	valid_sectors = list(STOCK_SECTOR_FINANCE, STOCK_SECTOR_MATERIALS, STOCK_SECTOR_AGRO)
	shock_min = 3
	shock_max = 7

/datum/stock_event/short_report
	name = "short report"
	headline = "Шорт-репорт обвиняет %NAME% в бухгалтерских махинациях"
	weight = 6
	shock_min = -20
	shock_max = -10
	volatility_mult = 2
	revert_share = 0.3

/datum/stock_event/meme_hype
	name = "meme hype"
	headline = "Трейдеры Фронтира разгоняют %TICKER% в спекулятивный ажиотаж"
	weight = 4
	shock_min = 30
	shock_max = 70
	volatility_mult = 2.5
	duration_ticks = 4
	peer_spread = 0.2
	revert_share = 0.8

/datum/stock_event/factory_expansion
	name = "factory expansion"
	headline = "%NAME% закладывает новые производственные мощности"
	weight = 8
	valid_sectors = list(STOCK_SECTOR_INDUSTRIAL, STOCK_SECTOR_MATERIALS, STOCK_SECTOR_AGRO)
	shock_min = 4
	shock_max = 9

/datum/stock_event/supply_chain_issue
	name = "supply chain issue"
	headline = "Проблемы с логистикой задерживают поставки %NAME%"
	weight = 8
	valid_sectors = list(STOCK_SECTOR_LOGISTICS, STOCK_SECTOR_INDUSTRIAL, STOCK_SECTOR_MATERIALS)
	shock_min = -11
	shock_max = -5

/datum/stock_event/regulatory_probe
	name = "regulatory probe"
	headline = "Регуляторы открывают антимонопольную проверку %NAME%"
	weight = 7
	valid_sectors = list(STOCK_SECTOR_FINANCE, STOCK_SECTOR_ENERGY, STOCK_SECTOR_MEDICAL)
	shock_min = -13
	shock_max = -6

/datum/stock_event/pirate_activity
	name = "pirate activity"
	headline = "Пиратские налёты нарушают маршруты снабжения %NAME%"
	weight = 8
	valid_sectors = list(STOCK_SECTOR_LOGISTICS, STOCK_SECTOR_AGRO)
	shock_min = -10
	shock_max = -4

/datum/stock_event/bumper_harvest
	name = "bumper harvest"
	headline = "%NAME% сообщает о рекордном урожайном сезоне"
	weight = 7
	valid_sectors = list(STOCK_SECTOR_AGRO)
	shock_min = 5
	shock_max = 10

/datum/stock_event/epidemic
	name = "epidemic"
	headline = "Вспышка на окраинах повышает спрос на продукцию %NAME%"
	weight = 6
	valid_sectors = list(STOCK_SECTOR_MEDICAL)
	shock_min = 8
	shock_max = 18

/datum/stock_event/trading_halt
	name = "trading halt"
	headline = "Биржа приостанавливает торги по %TICKER% до раскрытия информации"
	weight = 5
	shock_min = -1
	shock_max = 1
	halt_ticks = 3

/datum/stock_event/bull_run
	name = "bull run"
	headline = "Рынок растёт по всем фронтам — широкое ралли"
	weight = 5
	market_wide = TRUE
	shock_min = 6
	shock_max = 14

/datum/stock_event/panic_selloff
	name = "panic selloff"
	headline = "Инвесторы сбрасывают акции в панике по всему Фронтиру"
	weight = 5
	market_wide = TRUE
	shock_min = -18
	shock_max = -8
	volatility_mult = 1.5

/datum/stock_event/quiet_session
	name = "quiet session"
	headline = "На биржевую площадку опустилась тихая сессия"
	weight = 6
	market_wide = TRUE
	shock_min = 0
	shock_max = 0
	volatility_mult = 0.5
	duration_ticks = 4

/datum/stock_event/sector_rotation
	name = "sector rotation"
	headline = "Капитал перетекает в сектор %NAME%"
	weight = 6
	shock_min = 4
	shock_max = 10
	peer_spread = 0.8
	rival_drag = 1.5

/// Gameplay-driven template: fired by SSstock_market hooks, never rolled randomly.
/datum/stock_event/faction_success
	name = "faction success"
	headline = "Акции %NAME% растут после успешных операций аффилированных флотов"
	gameplay_driven = TRUE
	shock_min = 1
	shock_max = 2
	peer_spread = 0.2

/datum/stock_event/faction_failure
	name = "faction failure"
	headline = "Акции %NAME% падают после неудач аффилированных флотов"
	gameplay_driven = TRUE
	shock_min = -2
	shock_max = -1
	peer_spread = 0.2
// [/SOLARIS-ADD]
