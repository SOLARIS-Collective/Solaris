# STOCK MARKET — абстрактная фондовая биржа

Модпак `modular_solaris/stock_market`. Акции **не привязаны к предметам** — это лорные
эмитенты. Рынок живёт своей жизнью: тикающие цены, случайные новости, маркетмейкер
со спредом, лимитные ордера; геймплей (карго и миссии) влияет на фундаментал медленно,
каппированно и с затуханием.

## Архитектура

| Файл | Содержимое |
| --- | --- |
| `code/_defines.dm` | Все константы баланса и режимов |
| `code/company.dm` | `/datum/stock_company` — эмитент: фундаментал, цена, волатильность, halt, история |
| `code/emitters.dm` | Конкретные эмитенты (11 шт.) подтипами |
| `code/news_events.dm` | `/datum/stock_event` + 27 шаблонов событий/новостей |
| `code/brokerage.dm` | `/datum/brokerage_session` (счёт трейдера) и `/datum/stock_order` (лимитный ордер) |
| `code/subsystem.dm` | `SSstock_market`: тики цен, события, спрос секторов, игровые хуки |
| `code/roundend_report.dm` | Итоги смены через `SSticker.OnRoundend` |

## Как это работает

- **Тик рынка** раз в `STOCK_MARKET_WAIT` (30 сек): gauss-шум × волатильность +
  mean reversion к фундаменталу (`STOCK_MEAN_REVERSION`). История цен — 120 тиков.
- **Маркетмейкер**: bid = price×(1−4%), ask = price×(1+4%); комиссия брокера 2%
  с каждой стороны. При halt котировки недоступны.
- **События**: каждые 8–20 тиков взвешенный roll шаблона → шок фундаментала цели
  ± распространение по сектору/корреляциям, всплеск волатильности, возможен halt,
  опциональный откат части шока (revert_share) после затухания хайпа.
- **Старт раунда**: рандомизация фундаменталов/волатильностей, предыстория 120 тиков,
  один хайп (+25..45%) и один обвал (−25..40%).
- **Геймплей → рынок**: покупки карго копят спрос по секторам (маппинг категорий
  по ключевым словам); при пороге 25k — шок +1..3% всему сектору. Успех/провал миссий
  корабля фракции двигает эмитентов этой фракции на ±1..2%.
- **Брокерские сессии**: PERSONAL — торговля с реального `bank_account`;
  FACTION — виртуальный пул фракции (`STOCK_FACTION_VAULT_START`). Позиция ≤ 40% float.
- **Итог смены**: премия трейдеру пула = 20% чистого net_pl (считается ОДИН раз,
  анти-wash-trading), симметрично на убыток, кламп ≥ −баланс личника.
  Публичный отчёт: топ трейдеров, топ пулов, лучший/худший тикер, оборот.

## Как добавить эмитента

Подтип `/datum/stock_company` в `code/emitters.dm`:

```dm
/datum/stock_company/my_company
	ticker = "MYCO"            // уникальный тикер
	name = "My Company"
	blurb = "Короткое описание для терминала."
	sector = STOCK_SECTOR_INDUSTRIAL
	faction_path = /datum/faction/nt   // или null
	base_price = 100
	volatility = 0.02          // сигма доходности за тик
	depth = 300
	float_shares = 10000       // позиция счёта ≤ 40% от этого
	correlations = list("SHRP" = 0.5)  // ручные корреляции поверх секторных
```

## Как добавить событие

Подтип `/datum/stock_event` в `code/news_events.dm`. Ключевые поля: `weight`
(целое), `shock_min/shock_max` (%), `valid_sectors`, `peer_spread`, `revert_share`,
`halt_ticks`, `market_wide`, `rival_drag`, `headline` (%NAME%/%TICKER%).
Шаблоны с `gameplay_driven = TRUE` рандомом не выбираются — только из кода.

## API для будущих интерфейсов

```dm
SSstock_market.create_session(STOCK_MODE_PERSONAL, account, null, name, ckey)
SSstock_market.create_session(STOCK_MODE_FACTION, null, /datum/faction/nt, name, ckey, premium_account)
session.buy("SHRP", 10) / session.sell(...) / session.last_error
session.place_limit(STOCK_ORDER_BUY, "SHRP", 10, 95)
session.cancel_order(id) / session.positions / session.net_worth()
SSstock_market.companies["SHRP"].get_quotes()  // bid/ask или null при halt
SSstock_market.news_feed                       // лента заголовков
```

## Корневые правки ([SOLARIS-ADD] - STOCK_MARKET)

- `code/modules/cargo/market/market.dm`: `make_order()` → `SSstock_market.on_cargo_trade()`
- `code/modules/missions/mission.dm`: `turn_in()/give_up()` → `on_mission_result()`
- `code/modules/missions/outpost/_outpost.dm`: то же (у outpost-миссий нет вызова родителя)

## Таблица крутилок баланса

| Дефайн | Значение | Что делает |
| --- | --- | --- |
| `STOCK_MARKET_WAIT` | 30 сек | Период тика рынка |
| `STOCK_HISTORY_LENGTH` | 120 | Глубина истории цен |
| `STOCK_EVENT_INTERVAL_MIN/MAX` | 8..20 тиков | Частота случайных событий |
| `STOCK_BROKER_FEE_PERCENT` | 2 | Комиссия с каждой стороны |
| `STOCK_MM_SPREAD` | 0.04 | Спред маркетмейкера |
| `STOCK_MEAN_REVERSION` | 0.08 | Скорость возврата цены к фундаменталу |
| `STOCK_MAX_POSITION_SHARE` | 0.4 | Кап позиции от float |
| `STOCK_FACTION_VAULT_START` | 400000 | Стартовый баланс пула фракции |
| `STOCK_TRADER_SHARE` | 0.2 | Доля net_pl трейдеру премиумом |
| `STOCK_DEMAND_THRESHOLD` | 25000 | Порог спроса сектора |
| `STOCK_DEMAND_DECAY` | 0.97 | Затухание спроса за тик |
| `STOCK_DEMAND_SHOCK_MAX` | 3 | Макс. шок от спроса, % |
| `STOCK_MAX_ORDERS_PER_SESSION` | 10 | Лимит активных ордеров |

## Roadmap (после MVP)

- Терминал `obj/machinery/computer/stock_terminal` + tgui `StockExchange`
  (Рынок / Компания+стакан / Портфель / Мои ордера / Новости). Режим доступа:
  фракционные корабли — пул фракции, independent/пираты — личный счёт.
- PDA/радио уведомления об исполнении ордеров и крупных новостях.
- Эскроу лимитных ордеров; тикер на голоскрины.
- Кроссраундовая персистентность — осознанно отложена (каждый шифт рынок свежий).

Автор: MrCat15352
