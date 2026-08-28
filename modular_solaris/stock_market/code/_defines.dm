// [SOLARIS-ADD] - STOCK_MARKET
/// Причины транзакций для log_econ / adjust_money
#define CREDIT_LOG_STOCK_BUY "stock_buy"
#define CREDIT_LOG_STOCK_SELL "stock_sell"
#define CREDIT_LOG_STOCK_PREMIUM "stock_premium"

/// Период тика рынка
#define STOCK_MARKET_WAIT (30 SECONDS)
/// Сколько тиков хранится в истории цен (графики/отчёты)
#define STOCK_HISTORY_LENGTH 120
/// Интервал между случайными событиями рынка, в тиках
#define STOCK_EVENT_INTERVAL_MIN 8
#define STOCK_EVENT_INTERVAL_MAX 20

/// Комиссия брокера с каждой стороны сделки, %
#define STOCK_BROKER_FEE_PERCENT 2
/// Максимум активных лимитных ордеров на одну сессию
#define STOCK_MAX_ORDERS_PER_SESSION 10

/// Спред маркетмейкера вокруг рыночной цены (доля)
#define STOCK_MM_SPREAD 0.04
/// Доля разрыва цена/фундаментал, закрываемая за один тик
#define STOCK_MEAN_REVERSION 0.08
/// Максимум позиций одного счёта, доля от float компании
#define STOCK_MAX_POSITION_SHARE 0.4

/// Стартовый баланс виртуального пула фракции
#define STOCK_FACTION_VAULT_START 400000
/// Доля прибыли/убытка пула, идущая трейдеру премией по итогам смены
#define STOCK_TRADER_SHARE 0.2

/// Накопленный игровой спрос сектора, при котором фундаментал получает толчок
#define STOCK_DEMAND_THRESHOLD 25000
/// Множитель затухания спроса за тик
#define STOCK_DEMAND_DECAY 0.97
/// Максимальный шок фундаментала от всплеска спроса, %
#define STOCK_DEMAND_SHOCK_MAX 3

/// Сектора рынка
#define STOCK_SECTOR_DEFENSE "Defense"
#define STOCK_SECTOR_INDUSTRIAL "Industrial"
#define STOCK_SECTOR_LOGISTICS "Logistics"
#define STOCK_SECTOR_MATERIALS "Materials"
#define STOCK_SECTOR_ENERGY "Energy"
#define STOCK_SECTOR_AGRO "Agriculture"
#define STOCK_SECTOR_MEDICAL "Medical"
#define STOCK_SECTOR_FINANCE "Finance"

/// Режимы брокерского счёта
#define STOCK_MODE_PERSONAL 1
#define STOCK_MODE_FACTION 2

/// Типы лимитных ордеров
#define STOCK_ORDER_BUY 1
#define STOCK_ORDER_SELL 2

/// Результат попытки исполнения лимитного ордера
#define STOCK_FILL_RESTING 0
#define STOCK_FILL_FILLED 1
#define STOCK_FILL_CANCELLED 2

/// Сколько заголовков хранится в ленте новостей
#define STOCK_NEWS_FEED_LENGTH 30

/// Порог изменения фундаментала эмитента (%), с которого он попадает в разбор новости
#define STOCK_IMPACT_MIN_CHANGE 1
/// Максимум эмитентов в разборе одной новости (движение +/-)
#define STOCK_IMPACT_MAX_ENTRIES 6

/// Сколько последних сделок хранится в публичной ленте торгов
#define STOCK_TRADE_LOG_LENGTH 60
/// Сколько сделок отдаётся клиенту за раз
#define STOCK_TRADE_LOG_VIEW 40
/// Сколько строк показывать в таблицах лидеров и держателей
#define STOCK_LEADERBOARD_LIMIT 10
/// Как часто пересобирается публичный снимок рынка (лидеры/держатели/лента), в тиках
#define STOCK_SNAPSHOT_CACHE_TICKS 10
// [/SOLARIS-ADD]
