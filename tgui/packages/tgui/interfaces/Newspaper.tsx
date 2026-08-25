import { useBackend } from '../backend';
import { Box, Button, Stack } from '../components';
import { Window } from '../layouts';

const serif: React.CSSProperties = {
  'font-family': 'Georgia, "Times New Roman", serif',
};

const mono: React.CSSProperties = {
  'font-family': '"Courier New", Courier, monospace',
};

const COLOR = {
  bright: '#f2e3c2',
  body: '#e0cda6',
  gold: '#eeb255',
  goldDim: '#b8985e',
  muted: '#a8906c',
  dim: '#83704f',
  line: '#7a6238',
  lineDark: '#4a3a22',
  red: '#e06845',
  redBright: '#f0805e',
  green: '#8fb573',
  box: '#161009',
  boxDark: '#14100b',
};

const CLASSIFIEDS_ADS = [
  'Продам набор инструментов инженера. Почти новый, пользовался один раз',
  'Ищу работу грузчик на станцию. Таяр, опыт 5 лет, грузил всё подряд',
  'Продам редкий черенок. Собирал полгода. Дорого, но стоит',
  'Репетитор по синтику. Научу базовым схемам за 2 вечера. Дёшево',
  'Продам портативный дефибриллятор. Заряжен, готов к работе',
];

const SENSATIONS_HEADLINES = [
  {
    title: 'Корвет «Комарик» класса Squab обнаружен дрейфующим в секторе 7-G',
    body: 'Экипаж не отвечает на вызовы. Судно принадлежало Nanotrasen.',
    source: 'Служба безопасности СолФеда',
  },
  {
    title: 'InteQ объявляет о расширении контрактов в секторе',
    body: 'Крупнейшая ЧВК планирует открыть новые офисы на трёх станциях.',
    source: 'InteQ PR',
  },
  {
    title: 'Скандал в рядах Frontiersmen: капитан обвинён в растрате',
    body: 'Капитан «Дерзкого» обвиняется в присвоении 500 тысяч кредитов.',
    source: 'Независимый источник',
  },
  {
    title: 'PGF и CLIP Minutemen подписали мирное соглашение',
    body: 'Договорённость о совместном патрулировании спорных систем.',
    source: 'Дипломатический корпус',
  },
  {
    title: 'На станции NT зафиксирован всплеск аномальных событий',
    body: 'За неделю произошло 7 аномальных инцидентов.',
    source: 'Внутренняя служба NT',
  },
  {
    title: 'Saint-Roumain Militia проводит масштабную операцию',
    body: 'Спасены 42 человека с терпящего бедствие судна.',
    source: 'Пресс-служба SRM',
  },
  {
    title: 'Рамци Клайк усиливает присутствие в приграничных системах',
    body: 'Дополнительные силы развернуты вдоль торговых маршрутов.',
    source: 'Патруль СолФеда',
  },
  {
    title: 'Новый Gorlex Republic проводит военные учения',
    body: 'Масштабные учения в отдалённом секторе. Цели неизвестны.',
    source: 'Военная разведка',
  },
  {
    title: 'CyberSun анонсирует новую модель позитронного мозга',
    body: 'Новый мозг для IPC обещает «революцию в синтетическом сознании».',
    source: 'CyberSun Industries',
  },
  {
    title: 'Элизиум объявляет о «священной миссии»',
    body: 'Движение призвало всех «верных» к единству.',
    source: 'Анонимный источник',
  },
  {
    title: 'Independent-капитан установил рекорд скорости перехода',
    body: 'Переход между секторами за рекордные 4,7 часа.',
    source: 'Гильдия капитанов',
  },
  {
    title: 'Крупнейшая контрабанда в истории галактики задержана',
    body: 'Грузопоток на 15 млн кредитов перехвачен.',
    source: 'Таможня СолФеда',
  },
  {
    title: 'Hardliners Gorlex терпит стратегические потери',
    body: 'Потеряны два тяжёлых крейсера.',
    source: 'Военный обозреватель',
  },
  {
    title: 'SUNS открывает новый научный центр',
    body: 'Исследовательский комплекс на орбите Хамелеона.',
    source: 'SUNS Press Office',
  },
  {
    title: 'Nanotrasen поднимает зарплаты персоналу',
    body: 'Оклады повышены на 15% для всего персонала.',
    source: 'HR Department NT',
  },
  {
    title: 'Корвет «Молот» класса Hammerhead вышел из строя',
    body: 'Отказ навигационной системы. Экипаж в безопасности.',
    source: 'InteQ Operations',
  },
  {
    title: 'CLIP Minutemen празднует 50-летие основания',
    body: 'Торжества проходят на всех кораблях флота.',
    source: 'CLIP Headquarters',
  },
  {
    title: 'На орбите обнаружен заброшенный корабль класса Junker',
    body: 'Судно с полным грузом редких минералов.',
    source: 'Independent Survey Team',
  },
  {
    title: 'Frontiersmen проводят набор добровольцев',
    body: 'Набор на «мирные миссии». Подробности по запросу.',
    source: 'Frontiersmen HQ',
  },
  {
    title: 'PGF Mitchell.report: «Ситуация критическая»',
    body: 'Критическая ситуация в приграничных системах.',
    source: 'PGF Intelligence',
  },
  {
    title: 'SolFed вводит новый закон о космической безопасности',
    body: 'Все коммерческие суда обязаны иметь системы аварийного оповещения.',
    source: 'СолФед Газетта',
  },
  {
    title: 'CyberSun и NT заключают партнёрское соглашение',
    body: 'Совместный проект в области синтетического интеллекта.',
    source: 'Corporate Watch',
  },
  {
    title: 'Пираты атаковали караван у систем Кепори',
    body: 'Три судна повреждены, одно затонуло.',
    source: 'Торговая палата',
  },
  {
    title: 'Elysium требует независимости от всех корпораций',
    body: 'Заявление о полной независимости от корпоративного контроля.',
    source: 'Elysium Press',
  },
  {
    title: 'Скелет по имени Костик нашёл работу поваром',
    body: 'Занял должность шеф-повара на станции.',
    source: 'Газета «Грифон»',
  },
  {
    title: 'Tajara-капитан перехватил контрабанду на 2 млн кредитов',
    body: 'Задержан контрабандный корабль с запрещёнными веществами.',
    source: 'Патруль СолФеда',
  },
  {
    title: 'IPC запустили движение за электронные права',
    body: 'Позитронные синтетики объединились для борьбы за равные права.',
    source: 'Синтетический Альянс',
  },
  {
    title: 'Riol-исследователь открыл новый вид космических грибов',
    body: 'Вид грибов для производства лекарств.',
    source: 'Научный журнал',
  },
  {
    title: 'Vox-торговец установил рекорд по объёму сделок',
    body: 'Сделка на 10 млн кредитов за один день.',
    source: 'Торговая гильдия',
  },
  {
    title: 'Moth-инженер разработал новый тип двигателя',
    body: 'Потребляет на 30% меньше топлива.',
    source: 'Инженерный журнал',
  },
];

const pickRandom = function <T>(
  arr: T[],
  count: number,
  seed: number
): T[] {
  const result: T[] = [];
  const used = new Set<number>();
  let s = seed;
  while (result.length < count && result.length < arr.length) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    const idx = s % arr.length;
    if (!used.has(idx)) {
      used.add(idx);
      result.push(arr[idx]);
    }
  }
  return result;
};

const Rule = ({ thickness = '1px', mt = '0px' }: { thickness?: string; mt?: string }) => (
  <Box height={thickness} backgroundColor={COLOR.line} mt={mt} />
);

const ThickRule = () => (
  <Box>
    <Rule thickness="4px" />
    <Rule mt="2px" />
  </Box>
);

const Ornament = ({ mark = '◆' }: { mark?: string }) => (
  <Box className="Newspaper__Ornament">
    <Box className="Newspaper__OrnamentLine" />
    <Box className="Newspaper__OrnamentMark">{mark}</Box>
    <Box className="Newspaper__OrnamentLine" />
  </Box>
);

const SectionTitle = ({ children, color = COLOR.gold }: { children: React.ReactNode; color?: string }) => (
  <Box className="Newspaper__Ornament" mb="6px">
    <Box className="Newspaper__OrnamentLine" />
    <Box className="Newspaper__SectionTitle" color={color}>
      ✦ {children} ✦
    </Box>
    <Box className="Newspaper__OrnamentLine" />
  </Box>
);

const RunningHeader = ({ page }: { page: number }) => (
  <Box className="Newspaper__Running">
    <span>❖ ГРИФОН</span>
    <span className="Newspaper__RunningPage">стр. {page}</span>
  </Box>
);

const EndMark = () => (
  <Box className="Newspaper__Ornament" mt="14px" mb="2px">
    <Box className="Newspaper__OrnamentLine" />
    <Box className="Newspaper__EndMark">◆ ◆ ◆</Box>
    <Box className="Newspaper__OrnamentLine" />
  </Box>
);

const ScribbleNote = ({ text }: { text: string }) => (
  <Box className="Newspaper__Scribble">Заметка на полях: «{text}»</Box>
);

const AdBlock = ({ text, phone }: { text: string; phone: string }) => (
  <Box className="Newspaper__Ad">
    <Box className="Newspaper__AdLabel">РЕКЛАМА</Box>
    <Box className="Newspaper__AdText">{text}</Box>
    <Box className="Newspaper__AdPhone">тел. {phone}</Box>
  </Box>
);

const EmptyState = ({ text }: { text: string }) => (
  <Box textAlign="center" p="18px 0">
    <Box color={COLOR.line} fontSize="12px" bold>
      ◆ ◆ ◆
    </Box>
    <Box mt="6px" style={serif} fontSize="12px" color={COLOR.dim} italic>
      {text}
    </Box>
  </Box>
);

const TocRow = ({ name, page, color, onClick }: { name: string; page: number; color?: string; onClick?: () => void }) => (
  <Box
    className={onClick ? 'Newspaper__TocRow Newspaper__TocRow--clickable' : 'Newspaper__TocRow'}
    onClick={onClick}
  >
    <Box className="Newspaper__TocName" color={color} bold={!!color}>
      {name}
    </Box>
    <Box className="Newspaper__TocPage" color={color}>
      стр. {page}
    </Box>
  </Box>
);

export const Newspaper = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    current_page = 0,
    scribble_message = '',
    channels = [],
    channel_data = {},
    wanted_criminal = '',
    wanted_body = '',
    wanted_photo = null,
    pages = 0,
    issue_number = 1337,
  } = data;

  const lastPage = pages + 2 + (wanted_criminal ? 1 : 0);
  const totalPages = lastPage + 1;

  const coverStories = channels
    .filter((ch) => ch.messages > 0)
    .slice(0, 3);

  const totalArticles = channels.reduce(
    (sum, ch) => sum + (ch.messages || 0),
    0
  );

  const classifiedsSeed = issue_number * 7 + 13;
  const selectedAds = pickRandom(CLASSIFIEDS_ADS, 5, classifiedsSeed);
  const selectedSensations = pickRandom(
    SENSATIONS_HEADLINES,
    4,
    issue_number * 13 + 7
  );

  const renderCover = () => (
    <Box>
      <Box textAlign="center">
        <ThickRule />
        <Box mt="6px" color={COLOR.goldDim} fontSize="12px" bold>
          ◆ ◆ ◆
        </Box>
        <Box
          mt="4px"
          style={{
            ...serif,
            'font-size': '36px',
            'font-weight': 'bold',
            'letter-spacing': '12px',
            'line-height': '1.1',
          }}
          color={COLOR.bright}
        >
          ГРИФОН
        </Box>
        <Box mt="2px" style={serif} fontSize="12px" color={COLOR.muted} italic>
          Ежедневная космическая газета
        </Box>
        <Box
          mt="4px"
          style={mono}
          fontSize="10px"
          color={COLOR.dim}
        >
          ВЫПУСК #{issue_number} · ЦЕНА: 2 КРЕДИТА
        </Box>
        <Box style={mono} fontSize="10px" color={COLOR.line}>
          NANOTRASEN MEDIA GROUP · ЧИТАЙТЕ НА ВСЕХ СТАНЦИЯХ СЕКТОРА
        </Box>
        <Box mt="6px">
          <ThickRule />
        </Box>
      </Box>

      <Box className="Newspaper__Box" mt="12px" p="10px">
        <SectionTitle>Главные новости смены</SectionTitle>
        {coverStories.length > 0 ? (
          <>
            <Box
              textAlign="center"
              style={{
                ...serif,
                'font-size': '16px',
                'font-weight': 'bold',
                'line-height': '1.4',
              }}
              color={COLOR.gold}
            >
              «{coverStories[0].name}»
            </Box>
            <Box
              mt="5px"
              style={serif}
              fontSize="12px"
              color={COLOR.body}
              italic
              textAlign="center"
            >
              {coverStories[0].messages}{' '}
              {coverStories[0].messages === 1
                ? 'публикация'
                : coverStories[0].messages < 5
                  ? 'публикации'
                  : 'публикаций'}{' '}
              в этом номере · Подробности на стр.{' '}
              {channels.indexOf(coverStories[0]) + 2}
            </Box>
          </>
        ) : (
          <Box style={serif} fontSize="12px" color={COLOR.body} italic textAlign="center">
            На станции царят тишина и порядок.
            <br />
            Все службы работают штатно.
          </Box>
        )}
      </Box>

      <Stack mt="12px">
        <Stack.Item grow>
          <Box className="Newspaper__Box" p="9px" height="100%">
            <SectionTitle>Содержание</SectionTitle>
            {channels.length === 0 ? (
              <Box style={serif} fontSize="11px" color={COLOR.dim} italic>
                Публикаций пока нет
              </Box>
            ) : (
              channels.map((channel, index) => (
                <TocRow
                  key={index}
                  name={channel.name}
                  page={index + 2}
                  onClick={() => act('set_page', { page: String(index + 2) })}
                />
              ))
            )}
            <Box mt="6px">
              <Rule />
            </Box>
            <Box mt="6px">
              <TocRow name="Объявления" page={pages + 2} onClick={() => act('set_page', { page: String(pages + 2) })} />
              <TocRow name="Сенсации" page={pages + 3} onClick={() => act('set_page', { page: String(pages + 3) })} />
              {wanted_criminal && (
                <TocRow name="Розыск" page={pages + 4} color={COLOR.redBright} onClick={() => act('set_page', { page: String(pages + 4) })} />
              )}
            </Box>
          </Box>
        </Stack.Item>
        <Stack.Item grow>
          <Box className="Newspaper__Box" p="9px" height="100%">
            <SectionTitle>Сводка дня</SectionTitle>
            {[
              { label: 'Каналов новостей', value: String(channels.length) },
              { label: 'Всего статей', value: String(totalArticles) },
              { label: 'Объявлений', value: String(selectedAds.length) },
            ].map((row, i) => (
              <Box className="Newspaper__TocRow" key={i}>
                <Box className="Newspaper__TocName" color={COLOR.muted}>
                  {row.label}
                </Box>
                <Box className="Newspaper__TocPage" color={COLOR.bright} bold>
                  {row.value}
                </Box>
              </Box>
            ))}
            <Box mt="6px">
              <Rule />
            </Box>
            <Box
              mt="8px"
              style={serif}
              fontSize="12px"
              bold
              color={wanted_criminal ? COLOR.redBright : COLOR.green}
            >
              {wanted_criminal ? '⚠ ОБЪЯВЛЕН РОЗЫСК' : '✓ БЕЗОПАСНАЯ СМЕНА'}
            </Box>
          </Box>
        </Stack.Item>
      </Stack>

      {coverStories.length > 1 && (
        <Box mt="12px">
          <SectionTitle color={COLOR.muted}>Также в выпуске</SectionTitle>
          <Stack>
            {coverStories.slice(1).map((ch, i) => (
              <Stack.Item key={i} grow>
                <Box className="Newspaper__Box" p="7px 9px" height="100%">
                  <Box
                    style={{
                      ...serif,
                      'font-size': '12px',
                      'font-weight': 'bold',
                      'line-height': '1.3',
                      'word-break': 'break-word',
                      'overflow-wrap': 'break-word',
                    }}
                    color={COLOR.body}
                  >
                    {ch.name}
                  </Box>
                  <Box
                    mt="4px"
                    style={serif}
                    fontSize="11px"
                    color={COLOR.dim}
                    italic
                  >
                    стр. {channels.indexOf(ch) + 2} · {ch.messages}{' '}
                    {ch.messages === 1
                      ? 'материал'
                      : ch.messages < 5
                        ? 'материала'
                        : 'материалов'}
                  </Box>
                </Box>
              </Stack.Item>
            ))}
          </Stack>
        </Box>
      )}

      {scribble_message ? (
        <Box mt="12px">
          <ScribbleNote text={scribble_message} />
        </Box>
      ) : null}

      <Box mt="14px" textAlign="center" style={serif} fontSize="10px" color={COLOR.line} italic>
        ✦ Набрано в типографии Nanotrasen Media Group ✦
      </Box>
    </Box>
  );

  const renderChannel = () => {
    if (!channel_data || !channel_data.name) {
      return (
        <Box>
          <RunningHeader page={current_page + 1} />
          <EmptyState text="Нет данных для отображения" />
          <EndMark />
        </Box>
      );
    }

    const messages = channel_data.messages || [];

    return (
      <Box>
        <RunningHeader page={current_page + 1} />
        <Box textAlign="center">
          <Box
            style={{
              ...serif,
              'font-size': '18px',
              'font-weight': 'bold',
              'text-transform': 'uppercase',
              'letter-spacing': '2px',
              'line-height': '1.25',
              'word-break': 'break-word',
              'overflow-wrap': 'break-word',
            }}
            color={COLOR.bright}
          >
            {channel_data.name}
          </Box>
          <Box mt="3px" style={serif} fontSize="11px" color={COLOR.muted} italic>
            Рубрика · {channel_data.author}
          </Box>
          {channel_data.desc ? (
            <Box
              mt="2px"
              style={serif}
              fontSize="11px"
              color={COLOR.dim}
              italic
            >
              {channel_data.desc}
            </Box>
          ) : null}
          <Ornament />
        </Box>

        {channel_data.censored ? (
          <Box
            p="14px"
            style={{
              border: '3px double ' + COLOR.red,
              'background-color': '#1a1210',
            }}
            textAlign="center"
          >
            <Box
              style={{
                ...serif,
                'font-size': '15px',
                'font-weight': 'bold',
                'text-transform': 'uppercase',
                'letter-spacing': '4px',
              }}
              color={COLOR.redBright}
            >
              ✕ МАТЕРИАЛ ИЗЪЯТ ✕
            </Box>
            <Box
              mt="6px"
              style={serif}
              fontSize="12px"
              color={COLOR.muted}
              italic
            >
              Содержимое не допущено к публикации решением редакции
            </Box>
          </Box>
        ) : messages.length === 0 ? (
          <EmptyState text="В этом номере публикаций нет" />
        ) : (
          messages.map((message, index) => (
            <Box key={index}>
              <Box
                className={index === 0 ? 'Newspaper__Body Newspaper__Dropcap' : 'Newspaper__Body'}
              >
                {message.body}
              </Box>
              {message.img ? (
                <Box
                  mt="6px"
                  mb="6px"
                  p="4px"
                  style={{ border: '1px solid ' + COLOR.line, 'background-color': COLOR.boxDark }}
                >
                  <img
                    src={message.img}
                    style={{ maxWidth: '200px', maxHeight: '200px', display: 'block' }}
                  />
                </Box>
              ) : null}
              <Box mt="4px" className="Newspaper__Byline">
                — {message.author}, {message.time}
              </Box>
              {index < messages.length - 1 ? <Ornament mark="✦" /> : null}
            </Box>
          ))
        )}

        <AdBlock
          text={selectedAds[current_page % selectedAds.length]}
          phone={`${400 + ((current_page * 73) % 600)}-${((current_page * 31 + 17) % 900) + 100}`}
        />

        {scribble_message ? <ScribbleNote text={scribble_message} /> : null}
        <EndMark />
      </Box>
    );
  };

  const renderClassifieds = () => (
    <Box>
      <RunningHeader page={current_page + 1} />
      <Box textAlign="center">
        <Box
          style={{
            ...serif,
            'font-size': '18px',
            'font-weight': 'bold',
            'text-transform': 'uppercase',
            'letter-spacing': '3px',
          }}
          color={COLOR.gold}
        >
          Доска объявлений
        </Box>
        <Box mt="3px" style={serif} fontSize="11px" color={COLOR.dim} italic>
          Частные объявления жителей станции
        </Box>
        <Ornament />
      </Box>

      <Box className="Newspaper__Columns">
        {selectedAds.map((ad, index) => (
          <Box
            key={index}
            className="Newspaper__AdItem"
            style={{ 'border-bottom': index < selectedAds.length - 1 ? '1px dotted ' + COLOR.lineDark : 'none' }}
          >
            <Box className="Newspaper__Body" fontSize="12px">
              <span style={{ ...mono, color: COLOR.goldDim }}>✦ </span>
              {ad}
            </Box>
            <Box mt="3px" style={mono} fontSize="11px" color={COLOR.muted}>
              тел. {400 + ((index * 73) % 600)}-{((index * 31 + 17) % 900) + 100}
            </Box>
          </Box>
        ))}
      </Box>

      <Ornament />
      <Box textAlign="center" style={serif} fontSize="10px" color={COLOR.line} italic>
        Размещение объявлений бесплатно.
        <br />
        Редакция не несёт ответственности за их содержание.
      </Box>

      {scribble_message ? <ScribbleNote text={scribble_message} /> : null}
      <EndMark />
    </Box>
  );

  const renderSensations = () => (
    <Box>
      <RunningHeader page={current_page + 1} />
      <Box textAlign="center">
        <Box
          style={{
            ...serif,
            'font-size': '18px',
            'font-weight': 'bold',
            'text-transform': 'uppercase',
            'letter-spacing': '4px',
          }}
          color={COLOR.redBright}
        >
          Сенсации и скандалы
        </Box>
        <Box mt="3px" style={serif} fontSize="11px" color={COLOR.dim} italic>
          Главные события галактики за смену
        </Box>
        <Ornament mark="✦" />
      </Box>

      {selectedSensations.map((item, index) => (
        <Box key={index}>
          <Box className="Newspaper__ArticleTitle">
            <span className="Newspaper__ArticleNum">№ {index + 1}.</span>
            {item.title}
          </Box>
          <Box className="Newspaper__Body" fontSize="12px" color={COLOR.body}>
            {item.body}
          </Box>
          <Box mt="3px" className="Newspaper__Byline">
            — {item.source}
          </Box>
          {index < selectedSensations.length - 1 ? (
            <Ornament mark="✦" />
          ) : null}
        </Box>
      ))}

      <Ornament />
      <Box textAlign="center" style={serif} fontSize="10px" color={COLOR.line} italic>
        Информация предоставлена из открытых источников.
        <br />
        Редакция не гарантирует её достоверность.
      </Box>

      {scribble_message ? <ScribbleNote text={scribble_message} /> : null}
      <EndMark />
    </Box>
  );

  const renderWanted = () => (
    <Box>
      <RunningHeader page={current_page + 1} />
      <Box textAlign="center">
        <Box
          style={{
            ...serif,
            'font-size': '18px',
            'font-weight': 'bold',
            'text-transform': 'uppercase',
            'letter-spacing': '7px',
          }}
          color={COLOR.redBright}
        >
          РОЗЫСК
        </Box>
        <Box mt="3px" style={serif} fontSize="11px" color={COLOR.dim} italic>
          Служба безопасности станции
        </Box>
        <Ornament mark="✕" />
      </Box>

      {wanted_criminal ? (
        <Box
          p="12px"
          style={{
            border: '3px double ' + COLOR.red,
            'background-color': '#1a1210',
          }}
        >
          <Box
            textAlign="center"
            mb="10px"
            pb="6px"
            style={{ 'border-bottom': '1px solid ' + COLOR.red }}
          >
            <Box
              style={{
                ...serif,
                'font-size': '15px',
                'font-weight': 'bold',
                'text-transform': 'uppercase',
                'letter-spacing': '5px',
              }}
              color={COLOR.redBright}
            >
              ✦ РОЗЫСКИВАЕТСЯ ✦
            </Box>
          </Box>

          <Box className="Newspaper__WantedRow">
            <Box style={{ 'flex-shrink': 0 }}>
              {wanted_photo ? (
                <Box
                  p="3px"
                  style={{
                    border: '1px solid ' + COLOR.red,
                    'background-color': COLOR.boxDark,
                  }}
                >
                  <img
                    src={wanted_photo}
                    style={{
                      width: '100px',
                      height: '100px',
                      'object-fit': 'cover',
                      display: 'block',
                      border: '1px solid ' + COLOR.line,
                    }}
                  />
                </Box>
              ) : (
                <Box
                  width="100px"
                  height="100px"
                  style={{
                    border: '1px dashed ' + COLOR.line,
                    'background-color': COLOR.boxDark,
                  }}
                  textAlign="center"
                >
                  <Box mt="38px" style={serif} fontSize="10px" color={COLOR.dim} italic>
                    Фото
                    <br />
                    отсутствует
                  </Box>
                </Box>
              )}
            </Box>

            <Box className="Newspaper__WantedInfo">
              <Box
                pb="4px"
                mb="6px"
                style={{
                  ...serif,
                  'font-size': '14px',
                  'font-weight': 'bold',
                  'border-bottom': '1px solid ' + COLOR.line,
                  'word-break': 'break-word',
                  'overflow-wrap': 'break-word',
                }}
                color={COLOR.bright}
              >
                {wanted_criminal}
              </Box>
              <Box
                className="Newspaper__Body"
                fontSize="12px"
                style={{ 'text-align': 'left' }}
              >
                {wanted_body}
              </Box>
            </Box>
          </Box>

          <Box
            mt="10px"
            pt="6px"
            style={{ 'border-top': '1px solid ' + COLOR.red }}
          >
            <Box textAlign="center" style={serif} fontSize="11px" color={COLOR.redBright} italic>
              При обнаружении немедленно сообщите в службу безопасности
            </Box>
          </Box>
        </Box>
      ) : (
        <EmptyState text="Активных розысков нет" />
      )}

      {scribble_message ? <ScribbleNote text={scribble_message} /> : null}
      <EndMark />
    </Box>
  );

  const getCurrentContent = () => {
    if (current_page === 0) return renderCover();
    if (current_page >= 1 && current_page <= pages) return renderChannel();
    if (current_page === pages + 1) return renderClassifieds();
    if (current_page === pages + 2) return renderSensations();
    if (wanted_criminal && current_page === pages + 3) return renderWanted();
    return renderCover();
  };

  return (
    <Window width={500} height={685}>
      <Window.Content
        className="Newspaper"
        style={{
          backgroundColor: '#000000',
          backgroundImage: 'none',
        }}
      >
        <Stack fill vertical>
          <Stack.Item grow>
            <Box
              p="12px 14px"
              style={{
                'background-color': '#0d0b08',
                'background-image':
                  'radial-gradient(ellipse at top, rgba(238, 178, 85, 0.07), rgba(0, 0, 0, 0) 55%)',
                height: '100%',
                'overflow-y': 'auto',
              }}
            >
              {getCurrentContent()}
            </Box>
          </Stack.Item>

          <Stack.Item shrink>
            <Box
              p="6px 10px"
              style={{
                'background-color': '#14100b',
                'border-top': '3px double ' + COLOR.line,
              }}
            >
              <Stack align="center">
                <Stack.Item width="96px">
                  <Button
                    fluid
                    compact
                    className="Newspaper__NavBtn"
                    disabled={current_page <= 0}
                    onClick={() => act('prev_page')}
                  >
                    « Назад
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Box
                    textAlign="center"
                    style={serif}
                    fontSize="12px"
                    color={COLOR.goldDim}
                  >
                    — Стр. {current_page + 1} из {totalPages} —
                  </Box>
                </Stack.Item>
                <Stack.Item width="96px">
                  <Button
                    fluid
                    compact
                    className="Newspaper__NavBtn"
                    disabled={current_page >= lastPage}
                    onClick={() => act('next_page')}
                  >
                    Вперед »
                  </Button>
                </Stack.Item>
              </Stack>
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
