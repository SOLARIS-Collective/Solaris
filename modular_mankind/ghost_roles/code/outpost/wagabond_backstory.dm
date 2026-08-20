// Генератор случайной предыстории для бродяги (Wagabond).
// Каждый блок (кем был / как скатился / чего хочет) тянется рандомно при спавне.
// Некоторые фразы подставляют живые данные текущего раунда:
//   {FACTION}    - фракции кораблей, присутствующих в раунде
//   {SHIP}       - названия кораблей, присутствующих в раунде
//   {CHARACTER}  - имена персонажей живых игроков в раунде
//   {CAPTAIN}    - имена капитанов (владельцев) кораблей в раунде
// Плейсхолдеры в фигурных скобках (DM их не интерполирует), в рантайме они
// заменяются реальными данными через wagabond_replace_tokens.
// Результат выводится в чат тегами, сохраняется в память и выдаётся
// физической мятой запиской в рюкзаке, чтобы её можно было показывать другим.

GLOBAL_LIST_INIT(wagabond_former_entries, list(
	list("text" = "Вы были врачом на флотском госпитале.", "tag" = "БЫВШИЙ ВРАЧ"),
	list("text" = "Вы были капитаном собственного грузового судна.", "tag" = "БЫВШИЙ КАПИТАН"),
	list("text" = "Вы были шахтёром на поясе астероидов.", "tag" = "БЫВШИЙ ШАХТЁР"),
	list("text" = "Вы были контрабандистом, летавшим между фракциями.", "tag" = "БЫВШИЙ КОНТРАБАНДИСТ"),
	list("text" = "Вы были музыкантом, чьи концерты собирали полные залы.", "tag" = "БЫВШИЙ МУЗЫКАНТ"),
	list("text" = "Вы были учёным-исследователем НаноТрейзен.", "tag" = "БЫВШИЙ УЧЁНЫЙ"),
	list("text" = "Вы были клоуном на развлекательной станции.", "tag" = "БЫВШИЙ КЛОУН"),
	list("text" = "Вы были бойцом флота {FACTION} в отставке.", "tag" = "ВЕТЕРАН ФЛОТА {FACTION}"),
	list("text" = "Вы были инженером на огромной станции.", "tag" = "БЫВШИЙ ИНЖЕНЕР"),
	list("text" = "Вы были журналистом, копавшимся в чужих секретах.", "tag" = "БЫВШИЙ ЖУРНАЛИСТ"),
	list("text" = "Вы были шеф-поваром, чьи блюда знал весь сектор.", "tag" = "БЫВШИЙ ПОВАР"),
	list("text" = "Вы были курьером, доставлявшим посылки между мирами.", "tag" = "БЫВШИЙ КУРЬЕР"),
	list("text" = "Вы служили на корабле {SHIP}.", "tag" = "СЛУЖИЛ НА {SHIP}"),
	list("text" = "Вы были офицером связи на корабле {SHIP}.", "tag" = "СВЯЗИСТ С {SHIP}"),
	list("text" = "Вы работали на флот {FACTION} младшим техником.", "tag" = "ТЕХНИК ФЛОТА {FACTION}"),
	list("text" = "Вы были корабельным врачом на {SHIP}.", "tag" = "ВРАЧ С {SHIP}"),
	list("text" = "Вы были барменом, знавшим на вкус пол-сектора.", "tag" = "БЫВШИЙ БАРМЕН"),
	list("text" = "Вы были пиратом, пока ваша шхуна не затонула.", "tag" = "БЫВШИЙ ПИРАТ"),
	list("text" = "Вы были наёмником, бравшим заказы где угодно.", "tag" = "БЫВШИЙ НАЁМНИК"),
	list("text" = "Вы были сотрудником безопасности аванпоста.", "tag" = "БЫВШИЙ ОХРАННИК"),
	list("text" = "Вы были фермером, чьи теплицы кормили колонию.", "tag" = "БЫВШИЙ ФЕРМЕР"),
	list("text" = "Вы были пилотом, возившим грузы через опасные сектора.", "tag" = "БЫВШИЙ ПИЛОТ"),
	list("text" = "Вы были ведущим дешёвого космического шоу.", "tag" = "БЫВШИЙ ВЕДУЩИЙ"),
	list("text" = "Вы были священником, потерявшим паству.", "tag" = "БЫВШИЙ СВЯЩЕННИК"),
	list("text" = "Вы были психологом, который не смог помочь даже себе.", "tag" = "БЫВШИЙ ПСИХОЛОГ"),
	list("text" = "Вы были уборщиком на переполненной станции.", "tag" = "БЫВШИЙ УБОРЩИК"),
	list("text" = "Вы были интендантом флота {FACTION}.", "tag" = "ИНТЕНДАНТ ФЛОТА {FACTION}"),
	list("text" = "Вы были старшим помощником капитана {CAPTAIN}.", "tag" = "ПОМОЩНИК КАПИТАНА {CAPTAIN}"),
	list("text" = "Вы были пилотом на корабле {SHIP}.", "tag" = "ПИЛОТ С {SHIP}"),
	list("text" = "Вы руководили филиалом компании {FACTION}.", "tag" = "МЕНЕДЖЕР {FACTION}"),
	list("text" = "Вы были продавцом газировки на станции, пока не выпили весь товар.", "tag" = "ПРОДАВЕЦ ГАЗИРОВКИ"),
	list("text" = "Вы были рекламным лицом шампуня, пока не облысели от стресса.", "tag" = "РЕКЛАМНОЕ ЛИЦО"),
	list("text" = "Вы были таксистом, развозившим пьяных космонавтов.", "tag" = "БЫВШИЙ ТАКСИСТ"),
	list("text" = "Вы были инструктором по выживанию, которого самого трижды спасали.", "tag" = "ИНСТРУКТОР ПО ВЫЖИВАНИЮ"),
	list("text" = "Вы были дантистом, чьи руки тряслись сильнее бормашины.", "tag" = "ДАНТИСТ"),
	list("text" = "Вы были адвокатом, не выигравшим ни одного дела.", "tag" = "АДВОКАТ"),
	list("text" = "Вы были астрогеологом, который находил только пустоту.", "tag" = "АСТРОГЕОЛОГ"),
	list("text" = "Вы были бухгалтером флота {FACTION}, пока не «одолжили» казну.", "tag" = "БУХГАЛТЕР ФЛОТА {FACTION}"),
	list("text" = "Вы были судьёй на боях без правил и споры проигрывали мордой в песок.", "tag" = "СУДЬЯ БОЁВ"),
	list("text" = "Вы были смотрителем зоопарка, где вымерли все животные.", "tag" = "СМОТРИТЕЛЬ ЗООПАРКА"),
	list("text" = "Вы были ночным сторожем, который спал лучше всех на станции.", "tag" = "НОЧНОЙ СТОРОЖ"),
	list("text" = "Вы были тренером, с чьих тренировок ученики сбегали на первом круге.", "tag" = "ТРЕНЕР"),
	list("text" = "Вы были метрдотелем, которого уволили за съеденный заказ.", "tag" = "МЕТРДОТЕЛЬ"),
	list("text" = "Вы были гидом, водившим туристов прямиком в засады.", "tag" = "ГИД"),
	list("text" = "Вы были астропсихологом, у которого сдали нервы все клиенты.", "tag" = "АСТРОПСИХОЛОГ"),
	list("text" = "Вы были механиком, чьи починки ломались на следующий день.", "tag" = "МЕХАНИК"),
	list("text" = "Вы были поваром с единственным фирменным блюдом - горелыми котлетами.", "tag" = "ПОВАР"),
	list("text" = "Вы были капитаном {SHIP}, пока не доверили штурвал {CHARACTER}.", "tag" = "БЫВШИЙ КАПИТАН {SHIP}"),
	list("text" = "Вы были стриптизёром, пока сцена не прогорела вместе с вашей карьерой.", "tag" = "СТРИПТИЗЁР"),
	list("text" = "Вы были мастером «лечебного» массажа с особым вниманием к деталям.", "tag" = "МАССАЖИСТ"),
	list("text" = "Вы были почтальоном, доставлявшим «особые» посылки в каюты экипажа.", "tag" = "ОСОБЫЙ ПОЧТАЛЬОН"),
	list("text" = "Вы были официантом в баре, где чаевые принимали не только деньгами.", "tag" = "ОФИЦИАНТ"),
	list("text" = "Вы были звездой «ночного» голоканала.", "tag" = "НОЧНАЯ ЗВЕЗДА"),
	list("text" = "Вы были консультантом в магазине «для взрослых» и опробовали половину товара лично.", "tag" = "КОНСУЛЬТАНТ"),
	list("text" = "Вы были тренером по искусству соблазнения, с чьих уроков ученики разбегались после первого же занятия.", "tag" = "ТРЕНЕР ПО СОБЛАЗНЕНИЮ"),
	list("text" = "Вы были моделью нижнего белья, пока заказчик не потребовал снять его.", "tag" = "МОДЕЛЬ"),
	list("text" = "Вы были администратором курорта для молодожёнов, где пары разводились к ужину.", "tag" = "АДМИНИСТРАТОР КУРОРТА"),
	list("text" = "Вы были «личным тренером» богатых клиентов, и тренировки подозрительно часто заканчивались рано.", "tag" = "ЛИЧНЫЙ ТРЕНЕР"),
	list("text" = "Вы были свадебным фотографом, у которого все снимки выходили чересчур откровенными.", "tag" = "СВАДЕБНЫЙ ФОТОГРАФ"),
	list("text" = "Вы были капитаном {SHIP}, и половина экипажа состояла из ваших бывших.", "tag" = "БЫВШИЙ КАПИТАН {SHIP}"),
	list("text" = "Вы были санитаром, которого пациентки вызывали «просто поговорить».", "tag" = "САНИТАР"),
	list("text" = "Вы были певцом в клубе, куда ходили исключительно ради вашего образа.", "tag" = "ПЕВЕЦ"),
	list("text" = "Вы были гуру «осознанности», чьи семинары почему-то заканчивались в спальных отсеках.", "tag" = "ГУРУ"),
))

GLOBAL_LIST_INIT(wagabond_fall_entries, list(
	list("text" = "Ваше судно разбилось, и в живых остались только вы.", "tag" = "КОРАБЛЕКРУШЕНИЕ"),
	list("text" = "Вы не выплатили ипотеку, и судно забрали вместе с вашими мечтами.", "tag" = "ИПОТЕКА"),
	list("text" = "Вы проиграли всё до последней монеты в казино Элизиума.", "tag" = "ПРОИГРЫШ"),
	list("text" = "Коллеги подставили вас и вышвырнули из экипажа.", "tag" = "ПРЕДАТЕЛЬСТВО"),
	list("text" = "Вы сгорели на работе и однажды просто не вышли на смену.", "tag" = "ВЫГОРАНИЕ"),
	list("text" = "Ваше имя числится в чёрных списках сектора за старые грехи.", "tag" = "РОЗЫСК"),
	list("text" = "Вы сбежали, когда коллекторы пришли за вашими долгами.", "tag" = "ДОЛГИ"),
	list("text" = "Мятеж на корабле, и вы оказались на проигравшей стороне.", "tag" = "МЯТЕЖ"),
	list("text" = "Вас ограбили до нитки и выбросили на этом аванпосте.", "tag" = "ОГРАБЛЕНИЕ"),
	list("text" = "Авария на руднике отняла у вас и здоровье, и работу.", "tag" = "АВАРИЯ"),
	list("text" = "Вы потеряли груз, за который отвечали головой, а с ним и всё остальное.", "tag" = "ПОТЕРЯННЫЙ ГРУЗ"),
	list("text" = "Слухи разрушили вашу репутацию, и ни одна команда больше не брала вас на борт.", "tag" = "РАЗРУШЕННАЯ РЕПУТАЦИЯ"),
	list("text" = "Ваш корабль {SHIP} сгорел в бою, а вас списали как бесполезного.", "tag" = "ПОТЕРЯЛ КОРАБЛЬ {SHIP}"),
	list("text" = "После гибели корабля {SHIP} вы остались ни с чем.", "tag" = "ПОТЕРЯЛ КОРАБЛЬ {SHIP}"),
	list("text" = "Вас вычеркнули из списков флота {FACTION} без объяснений.", "tag" = "ИЗГНАН ИЗ ФЛОТА {FACTION}"),
	list("text" = "Капитан {CAPTAIN} вышвырнул вас с корабля на первой же остановке.", "tag" = "ПРЕДАТЕЛЬСТВО {CAPTAIN}"),
	list("text" = "Одна бурная ночь с {CHARACTER} закончилась для вас аванпостом и пустым кошельком.", "tag" = "НОЧЬ С {CHARACTER}"),
	list("text" = "Вы проиграли собственный корабль {SHIP} в карты.", "tag" = "ПРОИГРАЛ {SHIP}"),
	list("text" = "{FACTION} объявила вас предателем, и теперь на вас охота.", "tag" = "ВРАГ ФЛОТА {FACTION}"),
	list("text" = "Вы сбежали из тюрьмы фракции {FACTION}.", "tag" = "БЕГЛЕЦ ИЗ {FACTION}"),
	list("text" = "Вас списали за постоянные пьянки на дежурстве.", "tag" = "СПИСАН ЗА АЛКОГОЛЬ"),
	list("text" = "Болезнь съела все сбережения и оставила вас на обочине.", "tag" = "БОЛЕЗНЬ"),
	list("text" = "Война отняла у вас дом, работу и почти всех близких.", "tag" = "ВОЙНА"),
	list("text" = "Ваше судно {SHIP} конфисковали за долги.", "tag" = "КОНФИСКАЦИЯ {SHIP}"),
	list("text" = "Вы поспорили с {CHARACTER} и проиграли всё до единого кредита.", "tag" = "ПРОСПОРИЛ {CHARACTER}"),
	list("text" = "Вас разжаловали при всём экипаже.", "tag" = "РАЗЖАЛОВАН"),
	list("text" = "Ваш экипаж сбежал вместе с корабельной кассой.", "tag" = "СБЕЖАВШИЙ ЭКИПАЖ"),
	list("text" = "Вас подставил {CHARACTER}, а вину приписали вам.", "tag" = "ПОДСТАВА {CHARACTER}"),
	list("text" = "Банк фракции {FACTION} заморозил счета, и вы остались без гроша.", "tag" = "ПОТЕРЯЛ СБЕРЕЖЕНИЯ"),
	list("text" = "Экипаж {SHIP} расформировали, и вы остались без места.", "tag" = "СПИСАН С {SHIP}"),
	list("text" = "Вы продали печень за долги, но кредиторы всё равно пришли за остальным.", "tag" = "ПРОДАЛ ПЕЧЕНЬ"),
	list("text" = "Вас уволили за то, что вы приносили холодильник с пивом на смену.", "tag" = "УВОЛЕН ЗА ПИВО"),
	list("text" = "Вы поскользнулись на банановой кожуре и пролежали в больнице, пока вас увольняли.", "tag" = "БАНАНОВАЯ КОЖУРА"),
	list("text" = "Вы выиграли в лотерею, но билет оказался поддельным.", "tag" = "ЛОТЕРЕЯ"),
	list("text" = "Вы вложили все сбережения в «гарантированную» схему {CHARACTER}.", "tag" = "СХЕМА {CHARACTER}"),
	list("text" = "Вас укусил заражённый грызун, и вы потратили всё на лечение у шарлатана.", "tag" = "ШАРЛАТАН"),
	list("text" = "Вы случайно взорвали склад, на котором проработали десять лет.", "tag" = "ВЗОРВАЛ СКЛАД"),
	list("text" = "Вы украли чужой обед и загремели в тюрьму на год.", "tag" = "УКРАЛ ОБЕД"),
	list("text" = "Ваш корабль {SHIP} угнали прямо во время вашего сна.", "tag" = "УГНАЛИ {SHIP}"),
	list("text" = "Вы проиграли годовую зарплату на станционных скачках.", "tag" = "СКАЧКИ"),
	list("text" = "Вы напились с {CHARACTER} и очнулись в скафандре на астероиде без запаса воздуха.", "tag" = "ПОХМЕЛЬЕ С {CHARACTER}"),
	list("text" = "Вы ударили начальника бутылкой по голове, и пришлось бежать.", "tag" = "УДАРИЛ НАЧАЛЬНИКА"),
	list("text" = "Вы зашли в казино «выиграть чуть-чуть» и вышли без штанов.", "tag" = "КАЗИНО"),
	list("text" = "Вы решили сэкономить на стоматологе, и экономия съела всё.", "tag" = "ЭКОНОМИЯ"),
	list("text" = "Вас призвали в армию {FACTION}, но вы сбежали с построения.", "tag" = "ДЕЗЕРТИР {FACTION}"),
	list("text" = "Вы застраховали {SHIP}, а потом «случайно» сожгли его.", "tag" = "СТРАХОВКА {SHIP}"),
	list("text" = "Вы станцевали на столе в баре Элизиума и лишились последней работы.", "tag" = "ТАНЕЦ НА СТОЛЕ"),
	list("text" = "Ваш бывший коллега {CHARACTER} продал ваши секреты фракции {FACTION}.", "tag" = "ПРОДАЛ СЕКРЕТЫ"),
	list("text" = "Вас застукали с супругой капитана {CAPTAIN} и высадили на астероид без скафандра.", "tag" = "ЗАСТУКАЛ {CAPTAIN}"),
	list("text" = "Вы проснулись в чужой каюте без штанов и с чужим бейджем на шее.", "tag" = "ПРОСНУЛСЯ БЕЗ ШТАНОВ"),
	list("text" = "Вы сняли номер с {CHARACTER} на двоих, а утром обнаружили себя на Элизиуме без гроша.", "tag" = "НОМЕР С {CHARACTER}"),
	list("text" = "Вы попытались соблазнить {CHARACTER}, но споткнулись и разнесли весь бар.", "tag" = "СОБЛАЗНЯЛ {CHARACTER}"),
	list("text" = "Ваша ночная жизнь попала в прямой эфир станции.", "tag" = "НОЧНОЙ ЭФИР"),
	list("text" = "Вы подарили {CHARACTER} цветы, а он продал их обратно вам же.", "tag" = "ЦВЕТЫ ДЛЯ {CHARACTER}"),
	list("text" = "Вы станцевали на шесте так рьяно, что шест сломался вместе с репутацией.", "tag" = "СЛОМАЛ ШЕСТ"),
	list("text" = "Вы оставили танцовщице чаевые на всю зарплату, а потом не смогли заплатить за выпивку.", "tag" = "ЩЕДРЫЕ ЧАЕВЫЕ"),
	list("text" = "Вы согласились на «эксперимент» в частной клинике и проснулись другим человеком.", "tag" = "ЭКСПЕРИМЕНТ"),
	list("text" = "Вы флиртовали с супругом {CAPTAIN} прямо на мостике {SHIP}.", "tag" = "ФЛИРТ НА МОСТИКЕ"),
	list("text" = "Вы проиграли последние кредиты на аукционе «вещей знаменитостей».", "tag" = "АУКЦИОН"),
	list("text" = "Вы пригласили {CHARACTER} «на чай», а очнулись в грузовом отсеке без нижнего белья.", "tag" = "ЧАЙ С {CHARACTER}"),
	list("text" = "Ваши «частные уроки» стали притчей во языцех всего флота {FACTION}.", "tag" = "ЧАСТНЫЕ УРОКИ"),
	list("text" = "Вы попытались поцеловать руку {CHARACTER}, и она укусила вас в ответ.", "tag" = "ПОЦЕЛУЙ РУКИ"),
	list("text" = "Вы слишком долго смотрели на бутылку и в итоге женились на ней.", "tag" = "ЖЕНИЛСЯ НА БУТЫЛКЕ"),
))

GLOBAL_LIST_INIT(wagabond_goal_entries, list(
	list("text" = "Единственная мечта - купить старую шхуну и убраться из этого сектора.", "tag" = "ХОЧЕТ УЛЕТЕТЬ"),
	list("text" = "Вы ищете семью {CHARACTER}, разбросанную по разным мирам.", "tag" = "ИЩЕТ СЕМЬЮ {CHARACTER}"),
	list("text" = "Вы хотите найти того, кто перевернул вашу жизнь, и свести счёты.", "tag" = "ХОЧЕТ ОТОМСТИТЬ"),
	list("text" = "Вы мечтаете очистить своё имя от позора.", "tag" = "ХОЧЕТ ОПРАВДАТЬСЯ"),
	list("text" = "Ваша цель - просто дожить до следующего дня.", "tag" = "ПРОСТО ВЫЖИТЬ"),
	list("text" = "Вы хотите разбогатеть на этом аванпосте и начать с нуля.", "tag" = "ХОЧЕТ РАЗБОГАТЕТЬ"),
	list("text" = "Вы ищете старую команду, чтобы собрать её заново.", "tag" = "ИЩЕТ КОМАНДУ"),
	list("text" = "Вы должны найти потерянный груз и вернуть долг чести.", "tag" = "ИЩЕТ ГРУЗ"),
	list("text" = "Вы хотите найти работу и начать честную жизнь.", "tag" = "ХОЧЕТ РАБОТАТЬ"),
	list("text" = "Вы ищете того, кого когда-то не смогли спасти.", "tag" = "ИЩЕТ ИСЦЕПЛЕНИЯ"),
	list("text" = "Вы копите на билет туда, где вас никто не знает.", "tag" = "КОПИТ НА БИЛЕТ"),
	list("text" = "Вы ждёте тот самый шанс, который изменит всё.", "tag" = "ЖДЁТ ШАНС"),
	list("text" = "Вы ищете команду корабля {SHIP}, с которым связаны тёмным прошлым.", "tag" = "СВЯЗАН С {SHIP}"),
	list("text" = "Вы хотите разыскать {CHARACTER} и забрать то, что вам должны.", "tag" = "ИЩЕТ {CHARACTER}"),
	list("text" = "Вы хотите завербоваться на борт {SHIP}, чего бы это ни стоило.", "tag" = "ВЕРБУЕТСЯ НА {SHIP}"),
	list("text" = "Вы ищете капитана {CAPTAIN}, чтобы спросить, за что вас бросили.", "tag" = "ИЩЕТ КАПИТАНА {CAPTAIN}"),
	list("text" = "Вы хотите вступить во флот {FACTION} и доказать, что чего-то стоите.", "tag" = "ВСТУПИТЬ ВО ФЛОТ {FACTION}"),
	list("text" = "Вы должны вернуть долг {CHARACTER}, прежде чем уйти.", "tag" = "ДОЛЖНИК {CHARACTER}"),
	list("text" = "Вы мечтаете стать капитаном собственного корабля.", "tag" = "ХОЧЕТ СТАТЬ КАПИТАНОМ"),
	list("text" = "Вы хотите отыскать {SHIP}, который, по слухам, всё ещё на ходу.", "tag" = "ИЩЕТ {SHIP}"),
	list("text" = "Вы хотите помириться с {CHARACTER}, если он ещё жив.", "tag" = "ХОЧЕТ МИРА С {CHARACTER}"),
	list("text" = "Вы ищете клад, карту к которому спрятали много лет назад.", "tag" = "ИЩЕТ КЛАД"),
	list("text" = "Вы мечтаете дожить до первой настоящей зарплаты.", "tag" = "ЖДЁТ ЗАРПЛАТУ"),
	list("text" = "Вы хотите устроить шоу и снова прославиться.", "tag" = "ХОЧЕТ СЛАВЫ"),
	list("text" = "Вы пишете книгу о падении фракции {FACTION}.", "tag" = "ПИШЕТ КНИГУ"),
	list("text" = "Вы расследуете правду о гибели корабля {SHIP}.", "tag" = "РАССЛЕДУЕТ ГИБЕЛЬ {SHIP}"),
	list("text" = "Вы копите, чтобы выкупить {SHIP} обратно.", "tag" = "ВЫКУПАЕТ {SHIP}"),
	list("text" = "Вы ищете новый смысл жизни после всего, что случилось.", "tag" = "ИЩЕТ СМЫСЛ"),
	list("text" = "Вы копите на спокойную старость вдали от тревог.", "tag" = "КОПИТ НА СТАРОСТЬ"),
	list("text" = "Вы хотите отблагодарить {CHARACTER}, который когда-то спас вам жизнь.", "tag" = "ХОЧЕТ ОТБЛАГОДАРИТЬ {CHARACTER}"),
	list("text" = "Вы хотите найти того, кто спрятал вашу заначку.", "tag" = "ИЩЕТ ЗАНАЧКУ"),
	list("text" = "Вы мечтаете открыть собственную забегаловку на Элизиуме.", "tag" = "ХОЧЕТ ОТКРЫТЬ БАР"),
	list("text" = "Вы хотите доказать {CHARACTER}, что вы не неудачник.", "tag" = "ХОЧЕТ ДОКАЗАТЬ {CHARACTER}"),
	list("text" = "Вы ищете спонсора на ремонт {SHIP}.", "tag" = "ИЩЕТ СПОНСОРА"),
	list("text" = "Вы пишете мемуары под названием «Как я всё просрал».", "tag" = "ПИШЕТ МЕМУАРЫ"),
	list("text" = "Вы мечтаете, чтобы {FACTION} выплатила вам компенсацию за моральный ущерб.", "tag" = "ТЯЖБА С {FACTION}"),
	list("text" = "Вы ищете ту самую бутылку, которая всё исправит.", "tag" = "ИЩЕТ БУТЫЛКУ"),
	list("text" = "Вы хотите найти {CAPTAIN} и попросить прощения, даже если виноват он.", "tag" = "ИЩЕТ КАПИТАНА {CAPTAIN}"),
	list("text" = "Вы мечтаете тихо умереть в тёплой постели, чего раньше никогда не случалось.", "tag" = "ХОЧЕТ ТЁПЛОЙ ПОСТЕЛИ"),
	list("text" = "Вы хотите снова увидеть {SHIP}, хотя бы одним глазом.", "tag" = "СКУЧАЕТ ПО {SHIP}"),
	list("text" = "Вы мечтаете, чтобы {CHARACTER} подавился тем, что вам должен.", "tag" = "ЖДЁТ ВОЗМЕЗДИЯ {CHARACTER}"),
	list("text" = "Вы хотите дожить до пенсии, чтобы узнать, существует ли она вообще.", "tag" = "ЖДЁТ ПЕНСИЮ"),
	list("text" = "Вы мечтаете стать легендой, пусть даже легендой о неудачнике.", "tag" = "ХОЧЕТ СЛАВЫ"),
	list("text" = "Вы ищете ту самую лотерею, где ваш билет настоящий.", "tag" = "ИЩЕТ ЛОТЕРЕЮ"),
	list("text" = "Вы хотите нанять {CHARACTER} в свою будущую команду.", "tag" = "НАЙМЁТ {CHARACTER}"),
	list("text" = "Вы мечтаете снова пригласить {CHARACTER} «на чай».", "tag" = "ЧАЙ С {CHARACTER}"),
	list("text" = "Вы хотите открыть элитный клуб с «особой» атмосферой.", "tag" = "ХОЧЕТ ОТКРЫТЬ КЛУБ"),
	list("text" = "Вы ищете того, кто увёл у вас {CAPTAIN}, чтобы лично поблагодарить.", "tag" = "ИЩЕТ {CAPTAIN}"),
	list("text" = "Вы мечтаете снова появиться на обложке нижнего белья.", "tag" = "ХОЧЕТ НА ОБЛОЖКУ"),
	list("text" = "Вы хотите стать звездой ночного эфира станции.", "tag" = "НОЧНАЯ ЗВЕЗДА"),
	list("text" = "Вы ищете партнёра для «совместного плавания» на {SHIP}.", "tag" = "ИЩЕТ ПАРТНЁРА"),
	list("text" = "Вы мечтаете соблазнить капитана {CAPTAIN} назло всей команде.", "tag" = "СОБЛАЗНИТЬ {CAPTAIN}"),
	list("text" = "Вы пишете книгу «Искусство провала в любви».", "tag" = "ПИШЕТ КНИГУ"),
	list("text" = "Вы ищете клинику, где вернут вашу прежнюю фигуру и репутацию.", "tag" = "ИЩЕТ КЛИНИКУ"),
	list("text" = "Вы мечтаете, чтобы {FACTION} официально признала ваш вклад в ночную культуру сектора.", "tag" = "КУЛЬТУРА {FACTION}"),
	list("text" = "Вы хотите нанять {CHARACTER} личным массажистом.", "tag" = "НАЙМЁТ МАССАЖИСТА"),
	list("text" = "Вы ищете вечного «спонсора», который поверит в вашу идею.", "tag" = "ИЩЕТ СПОНСОРА"),
	list("text" = "Вы мечтаете станцевать на самом высоком шесте сектора.", "tag" = "ХОЧЕТ ТАНЦЕВАТЬ"),
	list("text" = "Вы хотите умереть не от скуки, а красиво.", "tag" = "ХОЧЕТ КРАСИВОГО"),
	list("text" = "Вы мечтаете, чтобы {CHARACTER} наконец перестал рассказывать всем о той ночи.", "tag" = "МОЛЧАНИЕ {CHARACTER}"),
))

// Фолбэки на случай пустого раунда (нет кораблей или игроков)
GLOBAL_LIST_INIT(wagabond_faction_fallbacks, list(FACTION_SYNDICATE, FACTION_NT, FACTION_SOLCON, FACTION_INTEQ, FACTION_PIRATES, FACTION_ELYSIUM, FACTION_SRM, FACTION_CLIP, FACTION_FRONTIERSMEN, FACTION_PGF, FACTION_RAMZI, FACTION_INDEPENDENT))

GLOBAL_LIST_INIT(wagabond_ship_fallbacks, list("NTSV «Гроза»", "SEV «Полуночный Курьер»", "SFSV «Клинок»", "IRMV «Скорпион»", "ESV «Бродяга»", "RSV «Ржавый Рассвет»", "ISV «Чайка»", "SEV «Гордость Сектора»", "NTSV «Багровый Закат»", "IRMV «Стальная Волна»", "SFSV «Северный Ветер»", "SSV «Тень»", "PCAC «Хамелеон»"))

/// Случайная фракция среди кораблей, присутствующих в раунде. При пустом раунде - фолбэк.
/proc/pick_round_faction_name(exclude_name)
	var/list/pool = list()
	for(var/datum/overmap/ship/controlled/ship as anything in SSovermap?.controlled_ships)
		var/faction_name = SSfactions?.faction_name(ship.get_faction())
		if(!faction_name || faction_name == "Unknown Faction" || faction_name == exclude_name)
			continue
		pool |= faction_name
	if(length(pool))
		return pick(pool)
	var/list/fallback = GLOB.wagabond_faction_fallbacks.Copy()
	fallback -= exclude_name
	return length(fallback) ? pick(fallback) : pick(GLOB.wagabond_faction_fallbacks)

/// Случайный корабль из присутствующих в раунде. При пустом раунде - фолбэк.
/proc/pick_round_ship_name(exclude_name)
	var/list/pool = list()
	for(var/datum/overmap/ship/controlled/ship as anything in SSovermap?.controlled_ships)
		if(!ship.name || ship.name == exclude_name)
			continue
		pool |= ship.name
	if(length(pool))
		return pick(pool)
	var/list/fallback = GLOB.wagabond_ship_fallbacks.Copy()
	fallback -= exclude_name
	return length(fallback) ? pick(fallback) : pick(GLOB.wagabond_ship_fallbacks)

/// Случайное имя персонажа живого игрока в раунде. При пустом раунде - случайное имя.
/proc/pick_round_character_name(mob/exclude_mob)
	var/list/pool = list()
	for(var/mob/living/carbon/human/H as anything in GLOB.player_list)
		if(H == exclude_mob || H.stat == DEAD || !H.real_name || H.real_name == "Unknown")
			continue
		pool |= H.real_name
	if(length(pool))
		return pick(pool)
	return random_unique_name(pick(MALE, FEMALE))

/// Случайное имя капитана корабля в раунде. При пустом раунде - случайное имя.
/proc/pick_round_captain_name(exclude_name)
	var/list/pool = list()
	for(var/datum/overmap/ship/controlled/ship as anything in SSovermap?.controlled_ships)
		var/mob/captain = ship.owner_mob || ship.get_best_owner_mob()
		if(captain?.real_name && captain.real_name != exclude_name)
			pool |= captain.real_name
	if(length(pool))
		return pick(pool)
	return random_unique_name(pick(MALE, FEMALE))

/// Подстановка живых данных раунда в текст. Токены без данных остаются как есть.
/proc/wagabond_replace_tokens(text, faction, faction2, ship, ship2, character, character2, captain, captain2)
	text = replacetext(text, "{CAPTAIN2}", captain2)
	text = replacetext(text, "{CAPTAIN}", captain)
	text = replacetext(text, "{FACTION2}", faction2)
	text = replacetext(text, "{FACTION}", faction)
	text = replacetext(text, "{SHIP2}", ship2)
	text = replacetext(text, "{SHIP}", ship)
	text = replacetext(text, "{CHARACTER2}", character2)
	text = replacetext(text, "{CHARACTER}", character)
	return text

/datum/wagabond_backstory
	/// Кем игрок был раньше
	var/former
	/// Как он скатился до жизни бродяги
	var/fall
	/// Чего он хочет добиться
	var/goal
	/// Тег для блока "кем был"
	var/former_tag
	/// Тег для блока "как скатился"
	var/fall_tag
	/// Тег для блока "чего хочет"
	var/goal_tag

/datum/wagabond_backstory/New(mob/exclude_mob)
	. = ..()
	var/list/former_entry = pick(GLOB.wagabond_former_entries)
	former = former_entry["text"]
	former_tag = former_entry["tag"]
	var/list/fall_entry = pick(GLOB.wagabond_fall_entries)
	fall = fall_entry["text"]
	fall_tag = fall_entry["tag"]
	var/list/goal_entry = pick(GLOB.wagabond_goal_entries)
	goal = goal_entry["text"]
	goal_tag = goal_entry["tag"]

	// Живые данные текущего раунда
	var/faction_name = pick_round_faction_name(null)
	var/faction_name_2 = pick_round_faction_name(faction_name)
	var/ship_name = pick_round_ship_name(null)
	var/ship_name_2 = pick_round_ship_name(ship_name)
	var/character_name = pick_round_character_name(exclude_mob)
	var/character_name_2 = pick_round_character_name(exclude_mob)
	var/captain_name = pick_round_captain_name(null)
	var/captain_name_2 = pick_round_captain_name(captain_name)

	former = wagabond_replace_tokens(former, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	fall = wagabond_replace_tokens(fall, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	goal = wagabond_replace_tokens(goal, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	former_tag = wagabond_replace_tokens(former_tag, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	fall_tag = wagabond_replace_tokens(fall_tag, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)
	goal_tag = wagabond_replace_tokens(goal_tag, faction_name, faction_name_2, ship_name, ship_name_2, character_name, character_name_2, captain_name, captain_name_2)

/// Строка тегов для быстрого взгляда: БЫВШИЙ ВРАЧ / ДОЛГИ / ИЩЕТ СЕМЬЮ
/datum/wagabond_backstory/proc/get_tags()
	return "[former_tag] / [fall_tag] / [goal_tag]"

/// Связный рассказ из трёх блоков
/datum/wagabond_backstory/proc/get_narrative()
	return "[former] [fall] [goal]"

/obj/item/paper/crumpled/wagabond_memory
	name = "мятая записка"
	desc = "Помятый клочок бумаги. Почерк ваш собственный, но вы не помните, когда писали это..."

/obj/effect/mob_spawn/human/elysium_outpost/wagabond/special(mob/living/carbon/human/new_spawn)
	if(!ishuman(new_spawn))
		return
	var/datum/wagabond_backstory/backstory = new(new_spawn)
	var/note_text = "[backstory.get_tags()]\n\n[backstory.get_narrative()]"
	to_chat(new_spawn, "<span class='big bold'>В глубине сознания всплывают обрывки прошлой жизни...</span>")
	to_chat(new_spawn, span_notice(backstory.get_tags()))
	to_chat(new_spawn, span_notice(backstory.get_narrative()))
	new_spawn.mind?.store_memory("Вы - бродяга. Ваша предыстория: [note_text]")
	var/obj/item/paper/crumpled/wagabond_memory/note = new(new_spawn.loc)
	note.add_raw_text(note_text)
	new_spawn.equip_to_slot_or_del(note, ITEM_SLOT_BACKPACK)