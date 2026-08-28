import { toFixed } from 'common/math';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Chart,
  Flex,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const MODE_NAMES = {
  1: 'Личный счёт',
  2: 'Фракционный пул',
};

type CompanyData = {
  ticker: string;
  name: string;
  blurb: string;
  sector: string;
  price: number;
  fundamental: number;
  volatility: number;
  change: number;
  halted: boolean;
  depth: number;
  float_shares: number;
  bid: number;
  ask: number;
  history: number[];
};

type PositionData = {
  ticker: string;
  count: number;
  avg_cost: number;
  price: number;
  value: number;
  pl: number;
};

type OrderData = {
  id: number;
  type: number;
  ticker: string;
  count: number;
  limit: number;
};

type SessionData = {
  mode: number;
  faction_name: string;
  trader_name: string;
  cash: number;
  net_worth: number;
  net_pl: number;
  positions: PositionData[];
  orders: OrderData[];
};

type NewsEntry = {
  text?: string;
};

type TradeEntry = {
  tick: number;
  actor: string;
  ticker: string;
  side: 'buy' | 'sell';
  count: number;
  price: number;
};

type HolderEntry = {
  name: string;
  count: number;
  pct: number;
};

type Data = {
  market: {
    paused: boolean;
    ticks: number;
    turnover: number;
    sectors: { name: string; demand: number; threshold: number }[];
    news: NewsEntry[];
    trades: TradeEntry[];
  };
  session: SessionData | null;
  companies: CompanyData[];
  error: string;
  leaderboard: LeaderEntry[];
  pools: LeaderEntry[];
  holders: Record<string, HolderEntry[]>;
};

type LeaderPosition = {
  ticker: string;
  count: number;
  value: number;
};

type LeaderEntry = {
  name: string;
  faction_name: string;
  cash: number;
  net_worth: number;
  net_pl: number;
  positions: LeaderPosition[];
};

const Sparkline = (props) => {
  const { data = [] } = props;
  const points = data.map((value, i) => [i, value]);
  return (
    <Box position="relative" height="22px" color="transparent">
      <Chart.Line
        fillPositionedParent
        data={points}
        rangeX={[0, Math.max(points.length - 1, 1)]}
        strokeColor="rgba(120, 200, 120, 1)"
        fillColor="rgba(120, 200, 120, 0.15)"
        strokeWidth={1.5}
      />
    </Box>
  );
};

export const StockExchange = (props, context) => {
  return (
    <Window width={900} height={650} resizable>
      <Window.Content scrollable>
        <StockExchangeContent />
      </Window.Content>
    </Window>
  );
};

const EMPTY_MARKET = {
  paused: false,
  ticks: 0,
  turnover: 0,
  sectors: [],
  news: [],
  trades: [],
};

export const StockExchangeContent = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { market = EMPTY_MARKET, session = null, error } = data;
  const companies = Array.isArray(data.companies) ? data.companies : [];
  const [tab, setTab] = useLocalState(context, 'tab', 'market');
  const [ticker, setTicker] = useLocalState(context, 'ticker', null);
  const [amount, setAmount] = useLocalState(context, 'amount', 5);
  const [limitPrice, setLimitPrice] = useLocalState(context, 'limitPrice', 0);

  const selected =
    companies.find((company) => company.ticker === ticker) || null;

  return (
    <>
      <NoticeBox color={market.paused ? 'orange' : 'green'}>
          {market.paused
            ? 'Рынок заморожен (пауза администрейшена)'
            : `Рынок открыт · Тик ${market.ticks} · Оборот ${formatMoney(
                market.turnover
              )}`}
      </NoticeBox>
        {error ? <NoticeBox danger>{error}</NoticeBox> : null}
        {session ? (
          <Flex mb={1}>
            <Flex.Item grow>
              <Section title="Счёт">
                <LabeledList>
                  <LabeledList.Item label="Режим">
                    {MODE_NAMES[session.mode] || 'Неизвестный'}
                  </LabeledList.Item>
                  <LabeledList.Item label="Трейдер">
                    {session.trader_name}
                    {session.faction_name
                      ? ` (${session.faction_name})`
                      : ''}
                  </LabeledList.Item>
                  <LabeledList.Item label="Наличность">
                    {formatMoney(session.cash)}
                  </LabeledList.Item>
                  <LabeledList.Item label="Стоимость портфеля">
                    {formatMoney(session.net_worth)}
                  </LabeledList.Item>
                  <LabeledList.Item label="Реализованный P/L">
                    <Box
                      color={(session.net_pl || 0) >= 0 ? 'green' : 'red'}
                    >
                      {formatMoney(session.net_pl, true)}
                    </Box>
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Flex.Item>
            <Flex.Item width="250px">
              <Section title="Секторы">
                {market.sectors && market.sectors.length > 0 ? (
                  market.sectors.map((sector) => (
                    <Flex.Item key={sector.name}>
                      <Flex>
                        <Flex.Item grow>{sector.name}</Flex.Item>
                        <Flex.Item>
                          {formatMoney(sector.demand)} / порог{' '}
                          {formatMoney(sector.threshold)}
                        </Flex.Item>
                      </Flex>
                    </Flex.Item>
                  ))
                ) : (
                  <Box color="label">Нет накопленного спроса</Box>
                )}
              </Section>
            </Flex.Item>
          </Flex>
        ) : null}

        <Tabs>
          <Tabs.Tab
            selected={tab === 'market'}
            icon="chart-line"
            onClick={() => setTab('market')}
          >
            Рынок
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'company'}
            icon="chart-area"
            disabled={!selected}
            onClick={() => setTab('company')}
          >
            {selected ? `${selected.ticker} · ${formatMoney(selected.ask)}` : 'Компания'}
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'portfolio'}
            icon="briefcase"
            onClick={() => setTab('portfolio')}
          >
            Портфель
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'orders'}
            icon="clipboard-list"
            onClick={() => setTab('orders')}
          >
            Мои ордера
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'news'}
            icon="newspaper"
            onClick={() => setTab('news')}
          >
            Новости
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'trades'}
            icon="exchange-alt"
            onClick={() => setTab('trades')}
          >
            Сделки
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'leaders'}
            icon="trophy"
            onClick={() => setTab('leaders')}
          >
            Лидеры
          </Tabs.Tab>
        </Tabs>

        {tab === 'market' && (
          <MarketList
            companies={companies}
            selectedTicker={ticker}
            onSelect={(newTicker) => {
              setTicker(newTicker);
              setTab('company');
            }}
          />
        )}

        {tab === 'company' && selected && (
          <CompanyView
            company={selected}
            amount={amount}
            limitPrice={limitPrice}
            setAmount={setAmount}
            setLimitPrice={setLimitPrice}
          />
        )}

        {tab === 'portfolio' && <PortfolioView />}

        {tab === 'orders' && <OrdersView />}

        {tab === 'news' && <NewsView market={market} />}

        {tab === 'trades' && <TradesView />}

        {tab === 'leaders' && <LeadersView />}
    </>
  );
};

const MarketList = (props) => {
  const { companies, selectedTicker, onSelect } = props;
  const safeCompanies = Array.isArray(companies) ? companies : [];
  return (
    <Section title="Котировки">
      <Table>
        <Table.Row header>
          <Table.Cell collapsing>Тикер</Table.Cell>
          <Table.Cell>Эмитент</Table.Cell>
          <Table.Cell collapsing>Сектор</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Bid
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Ask
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Изм.
          </Table.Cell>
          <Table.Cell collapsing width="90px">
            График
          </Table.Cell>
        </Table.Row>
        {safeCompanies.map((company) => (
          <Table.Row
            key={company.ticker}
            onClick={() => onSelect(company.ticker)}
            style={{
              cursor: 'pointer',
              color: 'white',
              opacity: company.halted ? 0.5 : 1,
            }}
          >
            <Table.Cell collapsing>
              <b>{company.ticker}</b>
            </Table.Cell>
            <Table.Cell>{company.name}</Table.Cell>
            <Table.Cell collapsing color="label">
              {company.sector}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {company.halted ? '—' : formatMoney(company.bid)}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {company.halted ? '—' : formatMoney(company.ask)}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              <ChangeCell change={company.change} />
            </Table.Cell>
            <Table.Cell collapsing>
              <Sparkline data={company.history} />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const CompanyView = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const {
    company,
    amount,
    limitPrice,
    setAmount,
    setLimitPrice,
  } = props;
  const chartData = (company.history || []).map((value, i) => [i, value]);
  const holders = Array.isArray(data.holders?.[company.ticker])
    ? data.holders[company.ticker]
    : [];
  return (
    <>
      <Section
        title={`${company.ticker} — ${company.name}`}
        buttons={
          <Box>
            <b>{formatMoney(company.ask)}</b>
            <Button ml={1} icon="shopping-cart" color="green"
              disabled={company.halted}
              onClick={() => act('buy', { ticker: company.ticker, count: amount })}>
              Купить
            </Button>
            <Button icon="money-bill-alt" color="red"
              disabled={company.halted}
              onClick={() => act('sell', { ticker: company.ticker, count: amount })}>
              Продать
            </Button>
            <NumberInput
              ml={1}
              width="70px"
              value={amount}
              minValue={1}
              step={1}
              onChange={(_, value) => setAmount(value)}
            />
          </Box>
        }
      >
        <Flex>
          <Flex.Item grow>
            <LabeledList>
              <LabeledList.Item label="Цена">
                {formatMoney(company.price)}
              </LabeledList.Item>
              <LabeledList.Item label="Bid / Ask">
                {company.halted
                  ? 'Торги приостановлены'
                  : `${formatMoney(company.bid)} / ${formatMoney(company.ask)}`}
              </LabeledList.Item>
              <LabeledList.Item label="Изменение">
                <ChangeCell change={company.change} />
              </LabeledList.Item>
              <LabeledList.Item label="Фундаментал">
                {formatMoney(company.fundamental)}
              </LabeledList.Item>
              <LabeledList.Item label="Волатильность">
                {toFixed(company.volatility, 2)}%
              </LabeledList.Item>
              <LabeledList.Item label="Ёмкость / Акций">
                {company.depth} / {company.float_shares}
              </LabeledList.Item>
              <LabeledList.Item label={`Итого покупка (${amount} шт)`}>
                <Box color="green">
                  {formatMoney(amount * company.ask)} cr по ask + комиссия
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label={`Итого продажа (${amount} шт)`}>
                <Box color="red">
                  {formatMoney(amount * company.bid)} cr по bid − комиссия
                </Box>
              </LabeledList.Item>
            </LabeledList>
          </Flex.Item>
          <Flex.Item grow position="relative" height="180px">
            <Chart.Line
              fillPositionedParent
              data={chartData}
              rangeX={[0, Math.max(chartData.length - 1, 1)]}
              strokeColor="rgba(120, 200, 120, 1)"
              fillColor="rgba(120, 200, 120, 0.25)"
            />
          </Flex.Item>
        </Flex>
        <Box mt={1} color="label">
          {company.blurb}
        </Box>
      </Section>
      <Section title="Держатели акций">
        {holders.length === 0 ? (
          <Box color="label">
            Все акции в свободном обращении — крупных держателей нет.
          </Box>
        ) : (
          holders.map((holder) => (
            <Box key={holder.name} my={0.5}>
              <b>{holder.name}</b> — {holder.count} шт ({holder.pct}%
              обращения)
            </Box>
          ))
        )}
      </Section>
      <Section title="Лимитный ордер">
        <LabeledList>
          <LabeledList.Item label="Лимит / кол-во">
            <NumberInput
              width="80px"
              value={limitPrice}
              minValue={0}
              step={1}
              onChange={(_, value) => setLimitPrice(value)}
            />
            <NumberInput
              ml={1}
              width="70px"
              value={amount}
              minValue={1}
              step={1}
              onChange={(_, value) => setAmount(value)}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Действие">
            <Button
              icon="arrow-down"
              color="green"
              disabled={!limitPrice || company.halted}
              onClick={() =>
                act('place_limit', {
                  type: 'buy',
                  ticker: company.ticker,
                  count: amount,
                  price: limitPrice,
                })
              }
            >
              Покупка при снижении до {formatMoney(limitPrice)}
            </Button>
            <Button
              icon="arrow-up"
              color="red"
              disabled={!limitPrice || company.halted}
              onClick={() =>
                act('place_limit', {
                  type: 'sell',
                  ticker: company.ticker,
                  count: amount,
                  price: limitPrice,
                })
              }
            >
              Продажа при росте до {formatMoney(limitPrice)}
            </Button>
          </LabeledList.Item>
        </LabeledList>
      </Section>
    </>
  );
};

const PortfolioView = (props, context) => {
  const { data } = useBackend<Data>(context);
  const { session } = data;
  if (!session) {
    return <Section title="Портфель">Нет сессии.</Section>;
  }
  return (
    <Section title="Портфель">
      <Table>
        <Table.Row header>
          <Table.Cell collapsing>Тикер</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Кол-во
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Ср. цена
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Текущая
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Стоимость
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            P/L
          </Table.Cell>
        </Table.Row>
        {(session.positions || []).length === 0 ? (
          <Table.Row>
            <Table.Cell colSpan={6} color="label">
              Позиций нет
            </Table.Cell>
          </Table.Row>
        ) : (
          (session.positions || []).map((position) => (
            <Table.Row key={position.ticker}>
              <Table.Cell collapsing>
                <b>{position.ticker}</b>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {position.count}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {formatMoney(position.avg_cost)}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {formatMoney(position.price)}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {formatMoney(position.value)}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Box color={position.pl >= 0 ? 'green' : 'red'}>
                  {position.pl >= 0 ? '+' : '-'}
                  {formatMoney(Math.abs(position.pl))}
                </Box>
              </Table.Cell>
            </Table.Row>
          ))
        )}
      </Table>
    </Section>
  );
};

const OrdersView = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { session } = data;
  if (!session) {
    return <Section title="Мои ордера">Нет сессии.</Section>;
  }
  return (
    <Section title="Мои ордера">
      <Table>
        <Table.Row header>
          <Table.Cell collapsing>ID</Table.Cell>
          <Table.Cell collapsing>Тип</Table.Cell>
          <Table.Cell collapsing>Тикер</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Кол-во
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Лимит
          </Table.Cell>
          <Table.Cell collapsing>
            Действие
          </Table.Cell>
        </Table.Row>
        {(session.orders || []).length === 0 ? (
          <Table.Row>
            <Table.Cell colSpan={6} color="label">
              Нет активных ордеров
            </Table.Cell>
          </Table.Row>
        ) : (
          (session.orders || []).map((order) => (
            <Table.Row key={order.id}>
              <Table.Cell collapsing>#{order.id}</Table.Cell>
              <Table.Cell collapsing>
                {order.type === 1 ? 'Покупка' : 'Продажа'}
              </Table.Cell>
              <Table.Cell collapsing>
                <b>{order.ticker}</b>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {order.count}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {formatMoney(order.limit)}
              </Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="times"
                  color="red"
                  size="small"
                  onClick={() => act('cancel_order', { id: order.id })}
                >
                  Отменить
                </Button>
              </Table.Cell>
            </Table.Row>
          ))
        )}
      </Table>
    </Section>
  );
};

const NewsView = (props) => {
  const { market } = props;
  const news = Array.isArray(market?.news) ? market.news : [];
  return (
    <Section title="Лента новостей">
      {news.length === 0 ? (
        <Box color="label">Новостей пока нет.</Box>
      ) : (
        news.map((headline, index) => {
          const text =
            typeof headline === 'string'
              ? headline
              : headline?.text || undefined;
          if (!text) {
            return null;
          }
          return (
            <Box
              key={index}
              p={1}
              mb={1}
              backgroundColor="rgba(255,255,255,0.05)"
            >
              {text}
            </Box>
          );
        })
      )}
    </Section>
  );
};

const TradesView = (props, context) => {
  const { data } = useBackend<Data>(context);
  const rawTrades = Array.isArray(data.market?.trades) ? data.market.trades : [];
  const trades = rawTrades
    .map((entry) => {
      if (!entry || typeof entry !== 'object') {
        return null;
      }
      const isArray = Array.isArray(entry);
      let side: string | number | undefined = isArray ? entry[3] : entry.side;
      if (side === 0 || side === 'buy') {
        side = 'buy';
      } else if (side === 1 || side === 'sell') {
        side = 'sell';
      } else {
        side = undefined;
      }
      if (typeof side === 'undefined') {
        return null;
      }
      return {
        tick: isArray ? entry[0] : entry.tick,
        ticker: isArray ? entry[2] : entry.ticker,
        count: isArray ? entry[4] : entry.count,
        price: isArray ? entry[5] : entry.price,
        actor: isArray ? entry[1] : entry.actor,
        side,
      };
    })
    .filter((trade): trade is Exclude<typeof trade, null> => trade !== null);
  if (trades.length === 0) {
    return (
      <Section title="Лента сделок">
        <Box color="label">Сделок ещё не было — рынок ждёт первого трейдера.</Box>
      </Section>
    );
  }
  return (
    <Section title="Лента сделок">
      <Table>
        <Table.Row header>
          <Table.Cell collapsing>Тик</Table.Cell>
          <Table.Cell collapsing>Эмитент</Table.Cell>
          <Table.Cell>Действие</Table.Cell>
          <Table.Cell collapsing>Кол-во</Table.Cell>
          <Table.Cell collapsing>Цена</Table.Cell>
          <Table.Cell>Участник</Table.Cell>
        </Table.Row>
        {trades.map((trade, i) => (
          <Table.Row key={i}>
            <Table.Cell>{trade.tick ?? '—'}</Table.Cell>
            <Table.Cell>{trade.ticker ?? '—'}</Table.Cell>
            <Table.Cell>
              <Box color={trade.side === 'buy' ? 'green' : 'red'}>
                {trade.side === 'buy' ? 'Покупка' : 'Продажа'}
              </Box>
            </Table.Cell>
            <Table.Cell>{trade.count ?? '—'} шт</Table.Cell>
            <Table.Cell>{formatMoney(trade.price ?? 0)}</Table.Cell>
            <Table.Cell>{trade.actor || '—'}</Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const LeadersView = (props, context) => {
  const { data } = useBackend<Data>(context);
  const leaderboard = Array.isArray(data.leaderboard) ? data.leaderboard : [];
  const pools = Array.isArray(data.pools) ? data.pools : [];
  return (
    <>
      <Section title="Пул фракций">
        {pools.length === 0 ? (
          <Box color="label">Пулы фракций ещё не созданы.</Box>
        ) : (
          <LeadersTable entries={pools} />
        )}
      </Section>
      <Section title="Лидеры торговцев">
        {leaderboard.length === 0 ? (
          <Box color="label">Трейдеров ещё нет.</Box>
        ) : (
          <LeadersTable entries={leaderboard} />
        )}
      </Section>
    </>
  );
};

const LeadersTable = (props) => {
  const { entries } = props;
  const safeEntries = Array.isArray(entries) ? entries : [];
  return (
    <Table>
      <Table.Row header>
        <Table.Cell collapsing>Участник</Table.Cell>
        <Table.Cell collapsing textAlign="right">
          Наличность
        </Table.Cell>
        <Table.Cell collapsing textAlign="right">
          Капитал
        </Table.Cell>
        <Table.Cell collapsing textAlign="right">
          P/L
        </Table.Cell>
        <Table.Cell>Позиции</Table.Cell>
      </Table.Row>
      {safeEntries.map((entry) => {
        if (!entry || typeof entry !== 'object') {
          return null;
        }
        const positions = Array.isArray(entry.positions)
          ? entry.positions
          : [];
        return (
          <Table.Row key={entry.name}>
            <Table.Cell collapsing>
              <b>{entry.name}</b>
              {entry.faction_name ? ` (${entry.faction_name})` : ''}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {formatMoney(entry.cash)}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {formatMoney(entry.net_worth)}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              <Box color={entry.net_pl >= 0 ? 'green' : 'red'}>
                {entry.net_pl >= 0 ? '+' : '-'}
                {formatMoney(Math.abs(entry.net_pl))}
              </Box>
            </Table.Cell>
            <Table.Cell>
              {positions.length === 0 ? (
                <Box color="label">—</Box>
              ) : (
                positions.map((pos, index) => (
                  <Box
                    inline
                    key={pos.ticker}
                    mr={index < positions.length - 1 ? 1 : 0}
                  >
                    <b>{pos.ticker}</b> {pos.count} ({formatMoney(pos.value)})
                    {index < positions.length - 1 ? ',' : ''}
                  </Box>
                ))
              )}
            </Table.Cell>
          </Table.Row>
        );
      })}
    </Table>
  );
};

const ChangeCell = (props) => {
  const { change } = props;
  const sign = change > 0 ? '+' : change < 0 ? '-' : '';
  return (
    <Box color={change >= 0 ? 'green' : 'red'}>
      {sign}
      {toFixed(change, 1)}%
    </Box>
  );
};

const formatMoney = (value, signed = false) => {
  if (value === undefined || value === null) {
    return '—';
  }
  const formatted = Number(value).toLocaleString('ru-RU', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 1,
  });
  return signed && value >= 0 ? `+${formatted}` : formatted;
};