import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type GlobalData = {
  paused: boolean;
  ready: boolean;
  ticks: number;
  next_event_tick: number;
  turnover: number;
  market_wait: number;
  broker_fee_percent: number;
  mm_spread: number;
  mean_reversion: number;
  max_position_share: number;
  faction_vault_start: number;
  trader_share: number;
  demand_threshold: number;
  demand_decay: number;
  demand_shock_max: number;
  event_interval_min: number;
  event_interval_max: number;
  max_orders_per_session: number;
  news_feed_length: number;
  history_length: number;
};

type SectorData = { name: string; demand: number; threshold: number };

type CompanyData = {
  ticker: string;
  name: string;
  blurb: string;
  sector: string;
  faction: string;
  base_price: number;
  volatility: number;
  depth: number;
  float_shares: number;
  fundamental: number;
  price: number;
  halted: boolean;
  halt_until: number;
  bid: number;
  ask: number;
};

type EventData = {
  type: string;
  script: string;
  name: string;
  headline: string;
  weight: number;
  valid_sectors?: string[];
  shock_min: number;
  shock_max: number;
  volatility_mult: number;
  duration_ticks: number;
  peer_spread: number;
  revert_share: number;
  halt_ticks: number;
  rival_drag: number;
  market_wide: boolean;
  gameplay_driven: boolean;
};

type SessionData = {
  mode: number;
  trader_name: string;
  faction_name: string;
  cash: number;
  net_pl: number;
  open_positions: number;
  open_orders: number;
};

type NewsEntry = {
  text?: string;
};

type AdminData = {
  global: GlobalData;
  sectors: SectorData[];
  news: NewsEntry[];
  companies: CompanyData[];
  events: EventData[];
  sessions: SessionData[];
};

const GLOBAL_PARAMS: { key: keyof GlobalData; label: string; unit: string; note?: string }[] = [
  {
    key: 'market_wait',
    label: 'Период тика, сек',
    unit: 'с',
    note: 'Время движется только по тикам рынка; пауза останавливает его полностью.',
  },
  { key: 'broker_fee_percent', label: 'Комиссия брокера', unit: '%' },
  { key: 'mm_spread', label: 'Спред маркетмейкера', unit: '' },
  { key: 'mean_reversion', label: 'Возврат к фундаменталу', unit: '' },
  { key: 'max_position_share', label: 'Кап позиции (0..1)', unit: '' },
  { key: 'faction_vault_start', label: 'Старт пула фракции', unit: 'cr' },
  { key: 'trader_share', label: 'Доля трейдера (0..1)', unit: '' },
  { key: 'demand_threshold', label: 'Порог спроса сектора', unit: '' },
  { key: 'demand_decay', label: 'Затухание спроса (0..1)', unit: '' },
  { key: 'demand_shock_max', label: 'Макс. шок сектора', unit: '%' },
  { key: 'event_interval_min', label: 'Интервал событий, мин', unit: 'тик' },
  { key: 'event_interval_max', label: 'Интервал событий, макс', unit: 'тик' },
  { key: 'max_orders_per_session', label: 'Лимит ордеров на сессию', unit: '' },
  { key: 'news_feed_length', label: 'Длина ленты новостей', unit: '' },
];

const EVENT_FIELDS: { key: keyof Omit<EventData, 'type' | 'script' | 'valid_sectors' | 'market_wide' | 'gameplay_driven'>; label: string; numeric: boolean }[] = [
  { key: 'name', label: 'Название', numeric: false },
  { key: 'headline', label: 'Заголовок', numeric: false },
  { key: 'weight', label: 'Вес (шанс)', numeric: true },
  { key: 'shock_min', label: 'Шок, мин %', numeric: true },
  { key: 'shock_max', label: 'Шок, макс %', numeric: true },
  { key: 'volatility_mult', label: 'Множитель волатильности', numeric: true },
  { key: 'duration_ticks', label: 'Длительность, тиков', numeric: true },
  { key: 'peer_spread', label: 'Распространение по сектору', numeric: true },
  { key: 'revert_share', label: 'Откат шока (0..1)', numeric: true },
  { key: 'halt_ticks', label: 'Халт торгов, тиков', numeric: true },
  { key: 'rival_drag', label: 'Давление на другие секторы', numeric: true },
];

export const StockAdmin = (props, context) => {
  const { data } = useBackend<AdminData>(context);
  const [tab, setTab] = useLocalState(context, 'adminTab', 'global');

  return (
    <Window width={980} height={700} resizable>
      <Window.Content scrollable>
        <NoticeBox>
          {data.global.paused
            ? 'Рынок ЗАМОРОЖЕН — время остановлено. Снимите паузу, чтобы продолжить.'
            : `Рынок активен · Тик ${data.global.ticks} · Следующий тик ${
                data.global.next_event_tick
              }`}
        </NoticeBox>
        <Tabs>
          <Tabs.Tab
            selected={tab === 'global'}
            icon="tachometer-alt"
            onClick={() => setTab('global')}
          >
            Общее
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'companies'}
            icon="building"
            onClick={() => setTab('companies')}
          >
            Эмитенты ({data.companies.length})
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'events'}
            icon="random"
            onClick={() => setTab('events')}
          >
            События ({data.events.length})
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'news'}
            icon="newspaper"
            onClick={() => setTab('news')}
          >
            Новости
          </Tabs.Tab>
        </Tabs>

        {tab === 'global' && <GlobalTab context={context} />}
        {tab === 'companies' && <CompaniesTab context={context} />}
        {tab === 'events' && <EventsTab context={context} />}
        {tab === 'news' && <NewsTab context={context} />}
      </Window.Content>
    </Window>
  );
};

const GlobalTab = (props, context) => {
  const { act, data } = useBackend<AdminData>(props.context);
  const { global, sectors, sessions = [] } = data;
  return (
    <>
      <Section
        title="Ход рынка"
        buttons={
          <Flex>
            <Flex.Item>
              <Button
                icon="pause"
                color={global.paused ? 'green' : 'orange'}
                onClick={() => act('toggle_pause')}
              >
                {global.paused ? 'Снять паузу' : 'Пауза (заморозить время)'}
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="forward"
                ml={1}
                disabled={global.paused}
                onClick={() => act('force_tick')}
              >
                Тик сейчас
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="dice"
                ml={1}
                disabled={global.paused}
                onClick={() => act('force_event')}
              >
                Случайное событие
              </Button>
            </Flex.Item>
          </Flex>
        }
      >
        <LabeledList>
          <LabeledList.Item label="Тиков сыграно">{global.ticks}</LabeledList.Item>
          <LabeledList.Item label="Оборот">
            {formatMoney(global.turnover)}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Параметры рынка">
        <LabeledList>
          {GLOBAL_PARAMS.map((entry) => (
            <EditableRow
              key={entry.key}
              context={props.context}
              label={entry.label}
              param={entry.key}
              value={global[entry.key]}
              unit={entry.unit}
              note={entry.note}
            />
          ))}
        </LabeledList>
      </Section>

      <Section title="Спрос секторов">
        {sectors.length === 0 ? (
          <Box color="label">Нет накопленного спроса.</Box>
        ) : (
          <LabeledList>
            {sectors.map((sector) => (
              <EditableRow
                key={sector.name}
                context={props.context}
                label={sector.name}
                param="demand"
                sectorKey={sector.name}
                value={formatMoney(sector.demand)}
                unit={`(порог ${formatMoney(sector.threshold)})`}
                action="set_sector_demand"
              />
            ))}
          </LabeledList>
        )}
      </Section>

      <Section title="Сессии (не завершённые)">
        {sessions.length === 0 ? (
          <Box color="label">Нет активных сессий.</Box>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Трейдер</Table.Cell>
              <Table.Cell>Режим</Table.Cell>
              <Table.Cell textAlign="right">Наличность</Table.Cell>
              <Table.Cell textAlign="right">Реализованный P/L</Table.Cell>
              <Table.Cell textAlign="right">Позиции</Table.Cell>
              <Table.Cell textAlign="right">Ордера</Table.Cell>
            </Table.Row>
            {sessions.map((session, index) => (
              <Table.Row key={index}>
                <Table.Cell>{session.trader_name}</Table.Cell>
                <Table.Cell>
                  {session.faction_name || (session.mode === 1 ? 'Личный' : 'Пул')}
                </Table.Cell>
                <Table.Cell textAlign="right">
                  {formatMoney(session.cash)}
                </Table.Cell>
                <Table.Cell textAlign="right">
                  <Box color={session.net_pl >= 0 ? 'green' : 'red'}>
                    {formatMoney(session.net_pl, true)}
                  </Box>
                </Table.Cell>
                <Table.Cell textAlign="right">
                  {session.open_positions}
                </Table.Cell>
                <Table.Cell textAlign="right">
                  {session.open_orders}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </Section>
    </>
  );
};

const CompaniesTab = (props, context) => {
  const { act, data } = useBackend<AdminData>(props.context);
  const { companies, sectors } = data;
  const [ticker, setTicker] = useLocalState(
    props.context,
    'adminCompany',
    companies[0] ? companies[0].ticker : null
  );
  const company = companies.find((item) => item.ticker === ticker) || null;
  return (
    <Section title="Эмитент">
      <Dropdown
        width="250px"
        options={companies.map((item) => item.ticker)}
        selected={ticker}
        onSelected={(value) => setTicker(value)}
      />
      {company && (
        <Box mt={2}>
          <NoticeBox color={company.halted ? 'orange' : 'green'}>
            {company.halted
              ? `Торги приостановлены до тика ${company.halt_until}`
              : 'Торги открыты'}
          </NoticeBox>
          <LabeledList>
            <CompanyEditor
              context={props.context}
              company={company}
              sectors={sectors}
            />
            <LabeledList.Item label="Bid / Ask">
              {formatMoney(company.bid)} / {formatMoney(company.ask)}
                {' · '}
                <Button
                  icon="pencil-alt"
                  size="small"
                  ml={1}
                  onClick={() =>
                    act('company_halt', {
                      ticker: company.ticker,
                      halt: company.halted ? 0 : 3,
                    })
                  }
                >
                  {company.halted ? 'Возобновить' : 'Халт (3 тика)'}
                </Button>
            </LabeledList.Item>
              <LabeledList.Item label="Ручной шок фундаментала">
                <Flex>
                  <Flex.Item>
                    <Button
                      icon="arrow-up"
                      color="green"
                      onClick={() =>
                        act('company_shock', {
                          ticker: company.ticker,
                          percent: 10,
                        })
                      }
                    >
                      +10%
                    </Button>
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      icon="arrow-down"
                      color="red"
                      ml={1}
                      onClick={() =>
                        act('company_shock', {
                          ticker: company.ticker,
                          percent: -10,
                        })
                      }
                    >
                      −10%
                    </Button>
                  </Flex.Item>
                </Flex>
              </LabeledList.Item>
          </LabeledList>
        </Box>
        )}
    </Section>
  );
};

const CompanyEditor = (props) => {
  const { company, sectors } = props;
  return (
    <>
      <EditableRow
        context={props.context}
        label="Название"
        param="name"
        ticker={company.ticker}
        value={company.name}
        action="set_company"
      />
      <EditableRow
        context={props.context}
        label="Тикер"
        param="ticker"
        ticker={company.ticker}
        value={company.ticker}
        action="set_company"
        disabled
      />
      <EditableRow
        context={props.context}
        label="Описание"
        param="blurb"
        ticker={company.ticker}
        value={company.blurb}
        action="set_company"
      />
      <SectorEditor
        context={props.context}
        company={company}
        sectors={sectors}
      />
      <EditableRow
        context={props.context}
        label="Фракция"
        param="faction_path"
        ticker={company.ticker}
        value={company.faction}
        action="set_company"
        disabled
      />
      <EditableRow
        context={props.context}
        label="Базовая цена"
        param="base_price"
        ticker={company.ticker}
        value={company.base_price}
        action="set_company"
      />
      <EditableRow
        context={props.context}
        label="Цена (текущая)"
        param="price"
        ticker={company.ticker}
        value={company.price}
        action="set_company"
      />
      <EditableRow
        context={props.context}
        label="Фундаментал"
        param="fundamental"
        ticker={company.ticker}
        value={company.fundamental}
        action="set_company"
      />
      <EditableRow
        context={props.context}
        label="Волатильность"
        param="volatility"
        ticker={company.ticker}
        value={company.volatility}
        action="set_company"
      />
      <EditableRow
        context={props.context}
        label="Ёмкость (depth)"
        param="depth"
        ticker={company.ticker}
        value={company.depth}
        action="set_company"
      />
      <EditableRow
        context={props.context}
        label="Акций в обращении"
        param="float_shares"
        ticker={company.ticker}
        value={company.float_shares}
        action="set_company"
      />
    </>
  );
};

const SectorEditor = (props) => {
  const { act } = useBackend(props.context);
  const { company, sectors } = props;
  return (
    <LabeledList.Item label="Сектор">
      <Dropdown
        width="250px"
        options={sectors}
        selected={company.sector}
        onSelected={(value) =>
          act('set_company', {
            ticker: company.ticker,
            field: 'sector',
            value,
          })
        }
      />
    </LabeledList.Item>
  );
};

const EventsTab = (props, context) => {
  const { act, data } = useBackend<AdminData>(props.context);
  const { events } = data;
  const [eventType, setEventType] = useLocalState(
    props.context,
    'adminEvent',
    events[0] ? events[0].type : null
  );
  const event = events.find((item) => item.type === eventType) || null;
  return (
    <Section
      title="События рынка"
      buttons={
        <Dropdown
          width="320px"
          options={events.map((item) => item.script)}
          selected={event && event.script}
          onSelected={(value) => {
            const found = events.find((item) => item.script === value);
            setEventType(found ? found.type : null);
          }}
        />
      }
    >
      {event ? (
        <>
          <NoticeBox>{event.headline}</NoticeBox>
          <LabeledList>
            {EVENT_FIELDS.map((entry) => (
              <EditableRow
                key={entry.key}
                context={props.context}
                label={entry.label}
                param={entry.key}
                eventType={event.type}
                value={event[entry.key]}
                action="set_event"
              />
            ))}
            <LabeledList.Item label="По всему рынку">
              <Button.Checkbox
                checked={event.market_wide}
                onClick={() =>
                  act('set_event', {
                    event_type: event.type,
                    field: 'market_wide',
                    value: event.market_wide ? 0 : 1,
                  })
                }
              >
                Широкий рынок
              </Button.Checkbox>
            </LabeledList.Item>
            <LabeledList.Item label="Сектора">
              {event.valid_sectors && event.valid_sectors.length
                ? event.valid_sectors.join(', ')
                : 'любые'}
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1}>
            <Button
              icon="random"
              color="blue"
              onClick={() =>
                act('fire_event', { event_type: event.type })
              }
            >
              Запустить сейчас
            </Button>
            <Button
              icon="undo"
              ml={1}
              onClick={() => act('clear_event', { event_type: event.type })}
            >
              Сбросить оверрайды
            </Button>
          </Box>
        </>
      ) : (
        <Box color="label">Нет событий.</Box>
      )}
    </Section>
  );
};

const NewsTab = (props, context) => {
  const { act, data } = useBackend<AdminData>(props.context);
  const news = Array.isArray(data.news) ? data.news : [];
  const [text, setText] = useLocalState(props.context, 'newsText', '');
  return (
    <Section
      title="Лента новостей"
      buttons={
        <Button
          icon="code"
          fontSize="1.1em"
          onClick={() => act('dump_json')}
          tooltip="Вывести в чат сырые JSON новостей и ленты сделок (для диагностики)"
        >
          JSON
        </Button>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Отправить новость">
          <Flex>
            <Flex.Item grow>
              <Input
                width="100%"
                value={text}
                onChange={(_, value) => setText(value)}
              />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="paper-plane"
                color="blue"
                ml={1}
                disabled={!text}
                onClick={() => {
                  act('post_news', { text });
                  setText('');
                }}
              >
                Отправить
              </Button>
            </Flex.Item>
          </Flex>
        </LabeledList.Item>
      </LabeledList>
      {news.length === 0 ? (
        <Box color="label">Лента пуста.</Box>
      ) : (
        news.map((headline, index) => {
          const line = typeof headline === 'string' ? headline : headline?.text;
          if (!line) {
            return null;
          }
          return (
            <Box
              key={index}
              p={1}
              mb={1}
              backgroundColor="rgba(255,255,255,0.05)"
            >
              {line}
            </Box>
          );
        })
      )}
    </Section>
  );
};

const EditableRow = (props, context) => {
  const { act } = useBackend(props.context);
  const { value, param, label, unit = '', note = '' } = props;
  const [next, setNext] = useLocalState(
    props.context,
    `next_${param}_${props.ticker || props.sectorKey || props.eventType || 'g'}`,
    String(value)
  );
  return (
    <LabeledList.Item label={label}>
      <Flex>
        <Flex.Item grow>
          <Input
            width="100%"
            value={next}
            disabled={props.disabled}
            onChange={(_, nextValue) => setNext(nextValue)}
          />
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="check"
            color="good"
            ml={1}
            disabled={props.disabled}
            onClick={() =>
              actSetCommand(act, props, param, next)
            }
          >
            {String(value)} {unit}
          </Button>
        </Flex.Item>
      </Flex>
      {note ? (
        <Box fontSize="0.75em" color="label" mt={0.2}>
          {note}
        </Box>
      ) : null}
    </LabeledList.Item>
  );
};

const actSetCommand = (act, props, param, rawValue) => {
  const base = {
    field: param,
    value: rawValue,
  };
  if (props.ticker) {
    act(props.action || 'set_company', {
      ...base,
      ticker: props.ticker,
    });
  } else if (props.sectorKey) {
    act('set_sector_demand', {
      sector: props.sectorKey,
      value: rawValue,
    });
  } else if (props.eventType) {
    act(props.action || 'set_event', {
      ...base,
      event_type: props.eventType,
    });
  } else {
    act('set_global', {
      param,
      value: rawValue,
    });
  }
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