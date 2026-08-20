// Генератор случайной предыстории для бродяги (Wagabond).
// Каждый блок (кем был / как скатился / чего хочет) тянется рандомно при спавне.
// Все фразы написаны под лор Solaris: Империя, Великое безумие,
// Разрастающаяся Мерзость, Артефакт, ковчег, красные глаза, ксеносы,
// гражданство за службу, НаноТрейзен, Синдикат, Солнечная Федерация и т.д.
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
	list("text" = "Вы отслужили свою десятилетнюю повинность в армии флота {FACTION}.", "tag" = "ВЕТЕРАН ФЛОТА {FACTION}"),
	list("text" = "Вы были пилотом имперского флота ещё до Великого безумия.", "tag" = "ПИЛОТ ИМПЕРСКОГО ФЛОТА"),
	list("text" = "Вы служили на пограничных рубежах, сдерживая порождения Мерзости.", "tag" = "СТРАЖ РУБЕЖЕЙ"),
	list("text" = "Вы были шахтёром на добыче плазмы для НаноТрейзен.", "tag" = "ШАХТЁР НАНОТРЕЙЗЕН"),
	list("text" = "Вы были учёным, изучавшим Артефакт до того, как он свёл вас с ума.", "tag" = "УЧЁНЫЙ АРТЕФАКТА"),
	list("text" = "Вы были фермером на колониальной планете, сожжённой Мерзостью.", "tag" = "КОЛОНИСТ-ФЕРМЕР"),
	list("text" = "Вы были техником на ковчеге во время Великого исхода.", "tag" = "ТЕХНИК КОВЧЕГА"),
	list("text" = "Вы служили в Христианской армии святого Георгия.", "tag" = "СОЛДАТ ХРИСТИАНСКОЙ АРМИИ"),
	list("text" = "Вы работали в разведке КСО до того, как она стала Синдикатом.", "tag" = "РАЗВЕДЧИК КСО"),
	list("text" = "Вы были инженером на буровых платформах добычи блюспейса.", "tag" = "ИНЖЕНЕР БЛЮСПЕЙСА"),
	list("text" = "Вы были охранником на станции-фабрике до Великой национализации.", "tag" = "ОХРАННИК ФАБРИКИ"),
	list("text" = "Вы были военным врачом в госпитале на фронте войны с Альянсом.", "tag" = "ВОЕНВРАЧ"),
	list("text" = "Вы были священником Церкви, пока не увидели красные глаза паствы.", "tag" = "СВЯЩЕННИК ЦЕРКВИ"),
	list("text" = "Вы возили ксенотехнологии через границы Империи контрабандой.", "tag" = "КОНТРАБАНДИСТ"),
	list("text" = "Вы командовали фрегатом {SHIP}, охраняя конвои флота {FACTION}.", "tag" = "КАПИТАН {SHIP}"),
	list("text" = "Вы писали хронику при дворе последнего Императора.", "tag" = "ИМПЕРСКИЙ ХРОНИКЁР"),
	list("text" = "Вы были эльфом из рода, бежавшего с павшей планеты.", "tag" = "БЕЖЕНЕЦ-ЭЛЬФ"),
	list("text" = "Вы были дворфом-кузнецом, ковавшим оружие против Нечто.", "tag" = "ДВОРФ-КУЗНЕЦ"),
	list("text" = "Вы слушали безумные сигналы из-за рубежа и сходили с ума вместе с астрологами.", "tag" = "АСТРОЛОГ"),
	list("text" = "Вы были инструктором по выживанию на мёртвых планетах.", "tag" = "ИНСТРУКТОР ПО ВЫЖИВАНИЮ"),
	list("text" = "Вы служили на флагмане {SHIP} до его гибели в бою.", "tag" = "ФЛАГМАНСКАЯ СЛУЖБА {SHIP}"),
	list("text" = "Вы были капитаном {SHIP}, пока не доверили штурвал {CHARACTER}.", "tag" = "БЫВШИЙ КАПИТАН {SHIP}"),
	list("text" = "Вы были бухгалтером в филиале компании {FACTION}, пока не «одолжили» казну.", "tag" = "БУХГАЛТЕР {FACTION}"),
	list("text" = "Вы были поваром в армейской столовой, где солдаты молились, чтобы не умереть с голоду.", "tag" = "АРМЕЙСКИЙ ПОВАР"),
	list("text" = "Вы были пилотом шаттла, возившим припасы на осаждённые колонии.", "tag" = "ПИЛОТ ШАТТЛА"),
	list("text" = "Вы были телохранителем важного чиновника Христианского ВП.", "tag" = "ТЕЛОХРАНИТЕЛЬ"),
	list("text" = "Вы были техником-плазменщиком, чинившим энергетические генераторы.", "tag" = "ПЛАЗМЕНЩИК"),
	list("text" = "Вы были картографом, наносившим на карты зоны заражения Мерзостью.", "tag" = "КАРТОГРАФ"),
	list("text" = "Вы были адвокатом, защищавшим тех, кого Церковь объявила еретиками.", "tag" = "АДВОКАТ ЕРЕТИКОВ"),
	list("text" = "Вы были горным инженером на рудниках Ареса, где царили законы Императора.", "tag" = "ИНЖЕНЕР АРЕСА"),
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
	list("text" = "Мерзость поглотила ваш мир, и вы остались единственным выжившим.", "tag" = "ПОГЛОЩЁН МЕРЗОСТЬЮ"),
	list("text" = "Вы продали своё гражданство за бутылку дешёвого пойла.", "tag" = "ПРОДАЛ ГРАЖДАНСТВО"),
	list("text" = "Синдром красных глаз дал о себе знать, и вас списали с флота {FACTION}.", "tag" = "КРАСНЫЕ ГЛАЗА"),
	list("text" = "Вы проснулись из криосна на сотню лет позже, и никто вас не ждал.", "tag" = "ОПОЗДАЛ НА СТО ЛЕТ"),
	list("text" = "Вы проиграли корабль {SHIP} в карты в баре Элизиума.", "tag" = "ПРОИГРАЛ {SHIP}"),
	list("text" = "Церковь объявила вас еретиком, и вам пришлось бежать с Христианского ВП.", "tag" = "ЕРЕТИК"),
	list("text" = "Вы сбежали из армии {FACTION} перед решающей битвой.", "tag" = "ДЕЗЕРТИР {FACTION}"),
	list("text" = "Вы взяли ссуду у ростовщиков Синдиката и не смогли её вернуть.", "tag" = "ДОЛГ СИНДИКАТУ"),
	list("text" = "Вы потратили страховую выплату за сгоревшую колонию на выпивку.", "tag" = "СТРАХОВКА"),
	list("text" = "Вы взорвали склад плазмы и списали всё на диверсию.", "tag" = "ВЗРЫВ ПЛАЗМЫ"),
	list("text" = "Вас выгнали с ковчега за нарушение карантина после контакта с заражённым.", "tag" = "НАРУШИЛ КАРАНТИН"),
	list("text" = "Вы лжесвидетельствовали на трибунале против {CHARACTER}, но совесть догнала вас.", "tag" = "ЛЖЕСВИДЕТЕЛЬ"),
	list("text" = "Ваш корабль {SHIP} угнали вместе с вашей долей добычи.", "tag" = "УГНАЛИ {SHIP}"),
	list("text" = "Вы поспорили с {CHARACTER}, что переживёте ночь в зоне заражения, и проиграли.", "tag" = "СПОР С {CHARACTER}"),
	list("text" = "Наёмники Аккорда Макоссо-Варра ограбили вас на границе сектора.", "tag" = "ОГРАБЛЕН АККОРДОМ"),
	list("text" = "Вы потеряли руку на добыче блюспейса и получили компенсацию размером с банку тушёнки.", "tag" = "ТРАВМА НА ДОБЫЧЕ"),
	list("text" = "Вы сорвали голос, читая проповеди против Империи на площадях станций.", "tag" = "ПОТЕРЯЛ ГОЛОС"),
	list("text" = "Вас списали за пьянство прямо перед награждением за спасение колонии.", "tag" = "СПИСАН ЗА ПЬЯНСТВО"),
	list("text" = "Вы прикоснулись к Артефакту в надежде исцелиться и потеряли рассудок.", "tag" = "ТРОНУЛ АРТЕФАКТ"),
	list("text" = "Вы очнулись в чужой каюте без штанов и с бейджем дезертира на шее.", "tag" = "БЕЗ ШТАНОВ"),
	list("text" = "Ваш экипаж бросил вас на станции, когда флот {FACTION} начал эвакуацию.", "tag" = "БРОШЕН ЭКИПАЖЕМ"),
	list("text" = "Вы подставили {CHARACTER}, но вина оказалась тяжелее награды.", "tag" = "ПОДСТАВА {CHARACTER}"),
	list("text" = "Ваша колония сгорела, пока вы пили в баре на Элизиуме.", "tag" = "КОЛОНИЯ СГОРЕЛА"),
	list("text" = "Вы украли казну ковчега, но спрятали её не там и потеряли всё.", "tag" = "УКРАЛ КАЗНУ"),
	list("text" = "Вас разжаловали при всём экипаже {SHIP} за трусость в бою.", "tag" = "РАЗЖАЛОВАН НА {SHIP}"),
	list("text" = "Вы поспорили с {CHARACTER} и проиграли даже память о прошлом.", "tag" = "ПРОСПОРИЛ ПАМЯТЬ"),
	list("text" = "Вы попытались продать данные о ковчеге НаноТрейзен, но вас обманули.", "tag" = "ПРОДАЛ ДАННЫЕ"),
	list("text" = "Вы вступили в культ Артефакта, и культ забрал у вас всё.", "tag" = "КУЛЬТ АРТЕФАКТА"),
	list("text" = "Вы сбежали из тюрьмы фракции {FACTION} через выгребную шахту.", "tag" = "БЕГЛЕЦ ИЗ {FACTION}"),
	list("text" = "Ваш корабль {SHIP} разнесли порождения Мерзости, и вы чудом спаслись.", "tag" = "РАЗНЕСЁН МЕРЗОСТЬЮ"),
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
))

GLOBAL_LIST_INIT(wagabond_goal_entries, list(
	list("text" = "Вы хотите снова получить гражданство, отслужив ещё один срок.", "tag" = "ХОЧЕТ ГРАЖДАНСТВА"),
	list("text" = "Вы ищете ковчег, на который можно попасть до конца времён.", "tag" = "ИЩЕТ КОВЧЕГ"),
	list("text" = "Вы мечтаете найти {CHARACTER}, брошенного на павшей планете.", "tag" = "ИЩЕТ {CHARACTER}"),
	list("text" = "Вы хотите добыть блюспейс, чтобы расплатиться с долгами.", "tag" = "ИЩЕТ БЛЮСПЕЙС"),
	list("text" = "Вы мечтаете отомстить порождению Мерзости, сожравшему ваш дом.", "tag" = "ХОЧЕТ МЕСТИ"),
	list("text" = "Вы хотите завербоваться на борт {SHIP} и убраться из этого сектора.", "tag" = "ВЕРБУЕТСЯ НА {SHIP}"),
	list("text" = "Вы ищете лекарство от красных глаз, пока не поздно.", "tag" = "ИЩЕТ ЛЕКАРСТВО"),
	list("text" = "Вы мечтаете стать капитаном и собрать экипаж из таких же бродяг.", "tag" = "ХОЧЕТ СТАТЬ КАПИТАНОМ"),
	list("text" = "Вы хотите отыскать семью {CHARACTER}, разбросанную после бегства с Земли.", "tag" = "ИЩЕТ СЕМЬЮ {CHARACTER}"),
	list("text" = "Вы мечтаете, чтобы {FACTION} признала ваши заслуги перед Империей.", "tag" = "ЖДЁТ ПРИЗНАНИЯ {FACTION}"),
	list("text" = "Вы пишете хронику падения Империи, пока память не стёрлась окончательно.", "tag" = "ПИШЕТ ХРОНИКУ"),
	list("text" = "Вы ищете последнее убежище, где можно спокойно состариться.", "tag" = "ИЩЕТ ПРИСТАНИЩЕ"),
	list("text" = "Вы хотите найти {CAPTAIN} и спросить, почему вас бросили на станции.", "tag" = "ИЩЕТ КАПИТАНА {CAPTAIN}"),
	list("text" = "Вы мечтаете открыть таверну для выживших с фронтира.", "tag" = "ХОЧЕТ ТАВЕРНУ"),
	list("text" = "Вы хотите попасть на борт ковчега и заснуть до лучших времён.", "tag" = "ХОЧЕТ КРИОСНА"),
	list("text" = "Вы ищете свидетеля, который подтвердит, что вы не безумец.", "tag" = "ИЩЕТ СВИДЕТЕЛЯ"),
	list("text" = "Вы мечтаете отомстить {CHARACTER}, продавшему вас Синдикату.", "tag" = "МЕСТЬ {CHARACTER}"),
	list("text" = "Вы копите на собственный шаттл, чтобы вырваться из Элизиума.", "tag" = "КОПИТ НА ШАТТЛ"),
	list("text" = "Вы ищете следы Императора, чтобы узнать правду о его исчезновении.", "tag" = "ИЩЕТ ИМПЕРАТОРА"),
	list("text" = "Вы мечтаете умереть не от Мерзости, а своей смертью.", "tag" = "ХОЧЕТ СВОЕЙ СМЕРТИ"),
	list("text" = "Вы хотите найти груз, потерянный во время эвакуации колонии.", "tag" = "ИЩЕТ ГРУЗ"),
	list("text" = "Вы мечтаете, чтобы {CHARACTER} наконец признал, что был неправ.", "tag" = "ЖДЁТ ПРИЗНАНИЯ {CHARACTER}"),
	list("text" = "Вы хотите вступить в ополчение {FACTION} и защищать свой новый дом.", "tag" = "ВСТУПИТЬ В ОПОЛЧЕНИЕ {FACTION}"),
	list("text" = "Вы ищете карту рудников Ареса, где спрятали свою заначку.", "tag" = "ИЩЕТ ЗАНАЧКУ"),
	list("text" = "Вы мечтаете дожить до дня, когда сектор очистят от Мерзости.", "tag" = "ЖДЁТ ОЧИЩЕНИЯ"),
	list("text" = "Вы хотите разыскать {SHIP} и вернуть его себе.", "tag" = "ВЫКУПАЕТ {SHIP}"),
	list("text" = "Вы мечтаете стать легендой сопротивления, пусть даже посмертно.", "tag" = "ХОЧЕТ СЛАВЫ"),
	list("text" = "Вы ищете храм, где можно молиться за тех, кого не спасли.", "tag" = "ИЩЕТ ХРАМ"),
	list("text" = "Вы хотите выторговать у НаноТрейзен дешёвый билет с этого аванпоста.", "tag" = "ТОРГУЕТСЯ С НАНОТРЕЙЗЕН"),
	list("text" = "Вы мечтаете, чтобы ваш рассказ о войне кто-нибудь записал.", "tag" = "ИЩЕТ ЛЕТОПИСЦА"),
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

// Карта "сырой тег -> предметы". По смыслу предыстории бродяге кладутся
// близкие вещи в рюкзак при спавне. Ключи совпадают с тегами из списков выше
// (до подстановки токенов {FACTION}/{SHIP} и т.д.).
GLOBAL_LIST_INIT(wagabond_tag_loot, list(
	// === КЕМ БЫЛ ===
	"ВЕТЕРАН ФЛОТА {FACTION}" = list(/obj/item/clothing/shoes/jackboots, /obj/item/coin, /obj/item/spacecash/bundle/c100),
	"ПИЛОТ ИМПЕРСКОГО ФЛОТА" = list(/obj/item/clothing/head/beret/black, /obj/item/flashlight),
	"СТРАЖ РУБЕЖЕЙ" = list(/obj/item/melee/knife/survival, /obj/item/flashlight),
	"ШАХТЁР НАНОТРЕЙЗЕН" = list(/obj/item/crowbar, /obj/item/flashlight, /obj/item/stack/medical/gauze),
	"УЧЁНЫЙ АРТЕФАКТА" = list(/obj/item/book/manual, /obj/item/pen, /obj/item/reagent_containers/pill/mannitol),
	"КОЛОНИСТ-ФЕРМЕР" = list(/obj/item/kitchen/fork, /obj/item/reagent_containers/food/snacks/egg),
	"ТЕХНИК КОВЧЕГА" = list(/obj/item/wrench, /obj/item/crowbar),
	"СОЛДАТ ХРИСТИАНСКОЙ АРМИИ" = list(/obj/item/melee/knife/combat, /obj/item/reagent_containers/pill/stimulant),
	"РАЗВЕДЧИК КСО" = list(/obj/item/pen, /obj/item/coin, /obj/item/spacecash/bundle/c50),
	"ИНЖЕНЕР БЛЮСПЕЙСА" = list(/obj/item/wrench, /obj/item/crowbar, /obj/item/flashlight),
	"ОХРАННИК ФАБРИКИ" = list(/obj/item/melee/knife/switchblade, /obj/item/flashlight),
	"ВОЕНВРАЧ" = list(/obj/item/stack/medical/gauze, /obj/item/reagent_containers/pill/tramal),
	"СВЯЩЕННИК ЦЕРКВИ" = list(/obj/item/book/manual, /obj/item/match),
	"КОНТРАБАНДИСТ" = list(/obj/item/storage/fancy/cigarettes/cigpack_robust, /obj/item/lighter, /obj/item/spacecash/bundle/c500),
	"КАПИТАН {SHIP}" = list(/obj/item/clothing/head/beret/black, /obj/item/coin, /obj/item/spacecash/bundle/c500),
	"ИМПЕРСКИЙ ХРОНИКЁР" = list(/obj/item/pen, /obj/item/book/manual, /obj/item/paper),
	"БЕЖЕНЕЦ-ЭЛЬФ" = list(/obj/item/coin, /obj/item/kitchen/fork),
	"ДВОРФ-КУЗНЕЦ" = list(/obj/item/wrench, /obj/item/melee/knife/kitchen),
	"АСТРОЛОГ" = list(/obj/item/book/manual, /obj/item/pen),
	"ИНСТРУКТОР ПО ВЫЖИВАНИЮ" = list(/obj/item/melee/knife/survival, /obj/item/flashlight, /obj/item/stack/medical/bruise_pack),
	"ФЛАГМАНСКАЯ СЛУЖБА {SHIP}" = list(/obj/item/spacecash/bundle/c100, /obj/item/coin),
	"БЫВШИЙ КАПИТАН {SHIP}" = list(/obj/item/clothing/head/beret/black, /obj/item/spacecash/bundle/c1000),
	"БУХГАЛТЕР {FACTION}" = list(/obj/item/pen, /obj/item/spacecash/bundle/c500),
	"АРМЕЙСКИЙ ПОВАР" = list(/obj/item/kitchen/fork, /obj/item/reagent_containers/food/drinks/beer),
	"ПИЛОТ ШАТТЛА" = list(/obj/item/flashlight, /obj/item/spacecash/bundle/c100),
	"ТЕЛОХРАНИТЕЛЬ" = list(/obj/item/melee/knife/combat, /obj/item/coin),
	"ПЛАЗМЕНЩИК" = list(/obj/item/crowbar, /obj/item/wrench, /obj/item/flashlight),
	"КАРТОГРАФ" = list(/obj/item/pen, /obj/item/book/manual, /obj/item/flashlight),
	"АДВОКАТ ЕРЕТИКОВ" = list(/obj/item/pen, /obj/item/paper, /obj/item/spacecash/bundle/c100),
	"ИНЖЕНЕР АРЕСА" = list(/obj/item/wrench, /obj/item/crowbar, /obj/item/spacecash/bundle/c100),
	"ПРОДАВЕЦ ГАЗИРОВКИ" = list(/obj/item/reagent_containers/food/drinks/bottle/hcider),
	"РЕКЛАМНОЕ ЛИЦО" = list(/obj/item/coin, /obj/item/pen),
	"БЫВШИЙ ТАКСИСТ" = list(/obj/item/spacecash/bundle/c50, /obj/item/coin),
	"ДАНТИСТ" = list(/obj/item/pen, /obj/item/spacecash/bundle/c100),
	"АДВОКАТ" = list(/obj/item/pen, /obj/item/paper, /obj/item/spacecash/bundle/c50),
	"АСТРОГЕОЛОГ" = list(/obj/item/flashlight, /obj/item/crowbar),
	"БУХГАЛТЕР ФЛОТА {FACTION}" = list(/obj/item/pen, /obj/item/spacecash/bundle/c100),
	"СУДЬЯ БОЁВ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c50),
	"СМОТРИТЕЛЬ ЗООПАРКА" = list(/obj/item/kitchen/fork, /obj/item/coin),
	"НОЧНОЙ СТОРОЖ" = list(/obj/item/flashlight, /obj/item/coin),
	"ТРЕНЕР" = list(/obj/item/spacecash/bundle/c50, /obj/item/coin),
	"МЕТРДОТЕЛЬ" = list(/obj/item/kitchen/fork, /obj/item/coin),
	"ГИД" = list(/obj/item/flashlight, /obj/item/spacecash/bundle/c50),
	"АСТРОПСИХОЛОГ" = list(/obj/item/book/manual, /obj/item/pen, /obj/item/reagent_containers/pill/psicodine),
	"МЕХАНИК" = list(/obj/item/wrench, /obj/item/crowbar),
	"ПОВАР" = list(/obj/item/kitchen/fork, /obj/item/reagent_containers/food/drinks/bottle/whiskey),
	"СТРИПТИЗЁР" = list(/obj/item/spacecash/bundle/c50, /obj/item/lighter),
	"МАССАЖИСТ" = list(/obj/item/spacecash/bundle/c100, /obj/item/coin),
	"ОСОБЫЙ ПОЧТАЛЬОН" = list(/obj/item/pen, /obj/item/spacecash/bundle/c20),
	"ОФИЦИАНТ" = list(/obj/item/kitchen/fork, /obj/item/coin),
	"НОЧНАЯ ЗВЕЗДА" = list(/obj/item/lighter, /obj/item/coin),
	"КОНСУЛЬТАНТ" = list(/obj/item/spacecash/bundle/c100, /obj/item/lighter),
	"ТРЕНЕР ПО СОБЛАЗНЕНИЮ" = list(/obj/item/pen, /obj/item/coin, /obj/item/spacecash/bundle/c50),
	"МОДЕЛЬ" = list(/obj/item/coin, /obj/item/lighter),
	"АДМИНИСТРАТОР КУРОРТА" = list(/obj/item/spacecash/bundle/c500, /obj/item/pen),
	"ЛИЧНЫЙ ТРЕНЕР" = list(/obj/item/spacecash/bundle/c100, /obj/item/coin),
	"СВАДЕБНЫЙ ФОТОГРАФ" = list(/obj/item/pen, /obj/item/spacecash/bundle/c100),
	"САНИТАР" = list(/obj/item/stack/medical/gauze, /obj/item/stack/medical/bruise_pack),
	"ПЕВЕЦ" = list(/obj/item/coin, /obj/item/lighter),
	"ГУРУ" = list(/obj/item/book/manual, /obj/item/lighter, /obj/item/reagent_containers/pill/happinesspsych),
	// === КАК СКАТИЛСЯ ===
	"ПОГЛОЩЁН МЕРЗОСТЬЮ" = list(/obj/item/melee/knife/survival, /obj/item/stack/medical/gauze),
	"ПРОДАЛ ГРАЖДАНСТВО" = list(/obj/item/spacecash/bundle/c20, /obj/item/reagent_containers/food/drinks/bottle/vodka),
	"КРАСНЫЕ ГЛАЗА" = list(/obj/item/reagent_containers/pill/charcoal, /obj/item/coin),
	"ОПОЗДАЛ НА СТО ЛЕТ" = list(/obj/item/flashlight, /obj/item/reagent_containers/food/drinks/bottle/hcider),
	"ПРОИГРАЛ {SHIP}" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"ЕРЕТИК" = list(/obj/item/book/manual, /obj/item/lighter),
	"ДЕЗЕРТИР {FACTION}" = list(/obj/item/melee/knife/survival, /obj/item/spacecash/bundle/c20),
	"ДОЛГ СИНДИКАТУ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c20),
	"СТРАХОВКА" = list(/obj/item/reagent_containers/food/drinks/bottle/whiskey, /obj/item/reagent_containers/food/drinks/beer),
	"ВЗРЫВ ПЛАЗМЫ" = list(/obj/item/crowbar, /obj/item/stack/medical/bruise_pack),
	"НАРУШИЛ КАРАНТИН" = list(/obj/item/reagent_containers/pill/mutadone, /obj/item/coin),
	"ЛЖЕСВИДЕТЕЛЬ" = list(/obj/item/pen, /obj/item/coin),
	"УГНАЛИ {SHIP}" = list(/obj/item/spacecash/bundle/c20, /obj/item/coin),
	"СПОР С {CHARACTER}" = list(/obj/item/reagent_containers/food/drinks/beer, /obj/item/stack/medical/gauze),
	"ОГРАБЛЕН АККОРДОМ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"ТРАВМА НА ДОБЫЧЕ" = list(/obj/item/stack/medical/gauze, /obj/item/reagent_containers/pill/iron),
	"ПОТЕРЯЛ ГОЛОС" = list(/obj/item/pen, /obj/item/paper),
	"СПИСАН ЗА ПЬЯНСТВО" = list(/obj/item/reagent_containers/food/drinks/bottle/vodka, /obj/item/lighter),
	"ТРОНУЛ АРТЕФАКТ" = list(/obj/item/reagent_containers/pill/mannitol, /obj/item/flashlight),
	"БЕЗ ШТАНОВ" = list(/obj/item/spacecash/bundle/pocketchange, /obj/item/coin),
	"БРОШЕН ЭКИПАЖЕМ" = list(/obj/item/coin, /obj/item/stack/medical/bruise_pack),
	"ПОДСТАВА {CHARACTER}" = list(/obj/item/paper, /obj/item/pen),
	"КОЛОНИЯ СГОРЕЛА" = list(/obj/item/reagent_containers/food/drinks/bottle/whiskey, /obj/item/lighter),
	"УКРАЛ КАЗНУ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c100),
	"РАЗЖАЛОВАН НА {SHIP}" = list(/obj/item/clothing/head/beret/black, /obj/item/coin),
	"ПРОСПОРИЛ ПАМЯТЬ" = list(/obj/item/pen, /obj/item/paper),
	"ПРОДАЛ ДАННЫЕ" = list(/obj/item/storage/fancy/cigarettes/cigpack_syndicate, /obj/item/coin),
	"КУЛЬТ АРТЕФАКТА" = list(/obj/item/lighter, /obj/item/coin),
	"БЕГЛЕЦ ИЗ {FACTION}" = list(/obj/item/spacecash/bundle/pocketchange, /obj/item/melee/knife/survival),
	"РАЗНЕСЁН МЕРЗОСТЬЮ" = list(/obj/item/stack/medical/gauze, /obj/item/flashlight),
	"УДАРИЛ НАЧАЛЬНИКА" = list(/obj/item/reagent_containers/food/drinks/bottle/whiskey, /obj/item/spacecash/bundle/c10),
	"КАЗИНО" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"ЭКОНОМИЯ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"СТРАХОВКА {SHIP}" = list(/obj/item/reagent_containers/food/drinks/bottle/whiskey, /obj/item/coin),
	"ТАНЕЦ НА СТОЛЕ" = list(/obj/item/reagent_containers/food/drinks/beer, /obj/item/spacecash/bundle/c10),
	"ПРОДАЛ СЕКРЕТЫ" = list(/obj/item/storage/fancy/cigarettes/cigpack_syndicate, /obj/item/spacecash/bundle/c100),
	"ЗАСТУКАЛ {CAPTAIN}" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"ПРОСНУЛСЯ БЕЗ ШТАНОВ" = list(/obj/item/spacecash/bundle/pocketchange, /obj/item/coin),
	"НОМЕР С {CHARACTER}" = list(/obj/item/spacecash/bundle/pocketchange, /obj/item/coin),
	"СОБЛАЗНЯЛ {CHARACTER}" = list(/obj/item/reagent_containers/food/drinks/bottle/wine, /obj/item/coin),
	"НОЧНОЙ ЭФИР" = list(/obj/item/lighter, /obj/item/coin),
	"ЦВЕТЫ ДЛЯ {CHARACTER}" = list(/obj/item/pen, /obj/item/paper),
	"СЛОМАЛ ШЕСТ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"ЩЕДРЫЕ ЧАЕВЫЕ" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"ЭКСПЕРИМЕНТ" = list(/obj/item/reagent_containers/pill/mutadone, /obj/item/reagent_containers/pill/mannitol),
	"ФЛИРТ НА МОСТИКЕ" = list(/obj/item/pen, /obj/item/coin),
	"АУКЦИОН" = list(/obj/item/coin, /obj/item/spacecash/bundle/c20),
	"ЧАЙ С {CHARACTER}" = list(/obj/item/reagent_containers/food/drinks/bottle/wine, /obj/item/kitchen/fork),
	"ЧАСТНЫЕ УРОКИ" = list(/obj/item/spacecash/bundle/c50, /obj/item/pen),
	"ПОЦЕЛУЙ РУКИ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"ЖЕНИЛСЯ НА БУТЫЛКЕ" = list(/obj/item/reagent_containers/food/drinks/bottle/vodka, /obj/item/coin),
	"ВРАГ ФЛОТА {FACTION}" = list(/obj/item/melee/knife/survival, /obj/item/spacecash/bundle/c20),
	"СПИСАН ЗА АЛКОГОЛЬ" = list(/obj/item/reagent_containers/food/drinks/bottle/vodka, /obj/item/lighter),
	"БОЛЕЗНЬ" = list(/obj/item/reagent_containers/pill/iron, /obj/item/reagent_containers/pill/insulin),
	"ВОЙНА" = list(/obj/item/stack/medical/gauze, /obj/item/coin),
	"КОНФИСКАЦИЯ {SHIP}" = list(/obj/item/spacecash/bundle/c20, /obj/item/coin),
	"ПРОСПОРИЛ {CHARACTER}" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"РАЗЖАЛОВАН" = list(/obj/item/clothing/head/beret/black, /obj/item/coin),
	"ПОТЕРЯЛ СБЕРЕЖЕНИЯ" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"СПИСАН С {SHIP}" = list(/obj/item/spacecash/bundle/c20, /obj/item/coin),
	"ПРОДАЛ ПЕЧЕНЬ" = list(/obj/item/reagent_containers/pill/iron, /obj/item/spacecash/bundle/c20),
	"УВОЛЕН ЗА ПИВО" = list(/obj/item/reagent_containers/food/drinks/beer, /obj/item/coin),
	"БАНАНОВАЯ КОЖУРА" = list(/obj/item/spacecash/bundle/pocketchange, /obj/item/coin),
	"ЛОТЕРЕЯ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"СХЕМА {CHARACTER}" = list(/obj/item/pen, /obj/item/paper),
	"ШАРЛАТАН" = list(/obj/item/reagent_containers/pill/salbutamol, /obj/item/coin),
	"ВЗОРВАЛ СКЛАД" = list(/obj/item/crowbar, /obj/item/spacecash/bundle/c10),
	"УКРАЛ ОБЕД" = list(/obj/item/kitchen/fork, /obj/item/coin),
	"СКАЧКИ" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"ПОХМЕЛЬЕ С {CHARACTER}" = list(/obj/item/reagent_containers/food/drinks/ale, /obj/item/spacecash/bundle/c10),
	// === ЧЕГО ХОЧЕТ ===
	"ХОЧЕТ ГРАЖДАНСТВА" = list(/obj/item/pen, /obj/item/paper),
	"ИЩЕТ КОВЧЕГ" = list(/obj/item/coin, /obj/item/flashlight),
	"ИЩЕТ {CHARACTER}" = list(/obj/item/paper, /obj/item/pen, /obj/item/coin),
	"ИЩЕТ БЛЮСПЕЙС" = list(/obj/item/flashlight, /obj/item/coin),
	"ХОЧЕТ МЕСТИ" = list(/obj/item/melee/knife/combat, /obj/item/flashlight),
	"ВЕРБУЕТСЯ НА {SHIP}" = list(/obj/item/spacecash/bundle/c100, /obj/item/coin),
	"ИЩЕТ ЛЕКАРСТВО" = list(/obj/item/reagent_containers/pill/mannitol, /obj/item/storage/pill_bottle),
	"ХОЧЕТ СТАТЬ КАПИТАНОМ" = list(/obj/item/clothing/head/beret/black, /obj/item/coin),
	"ИЩЕТ СЕМЬЮ {CHARACTER}" = list(/obj/item/paper, /obj/item/coin),
	"ЖДЁТ ПРИЗНАНИЯ {FACTION}" = list(/obj/item/coin, /obj/item/pen),
	"ПИШЕТ ХРОНИКУ" = list(/obj/item/pen, /obj/item/paper, /obj/item/book/manual),
	"ИЩЕТ ПРИСТАНИЩЕ" = list(/obj/item/spacecash/bundle/c100, /obj/item/flashlight),
	"ИЩЕТ КАПИТАНА {CAPTAIN}" = list(/obj/item/coin, /obj/item/pen),
	"ХОЧЕТ ТАВЕРНУ" = list(/obj/item/reagent_containers/food/drinks/beer, /obj/item/kitchen/fork),
	"ХОЧЕТ КРИОСНА" = list(/obj/item/flashlight, /obj/item/spacecash/bundle/c100),
	"ИЩЕТ СВИДЕТЕЛЯ" = list(/obj/item/pen, /obj/item/paper),
	"МЕСТЬ {CHARACTER}" = list(/obj/item/melee/knife/switchblade, /obj/item/coin),
	"КОПИТ НА ШАТТЛ" = list(/obj/item/spacecash/bundle/c500, /obj/item/coin),
	"ИЩЕТ ИМПЕРАТОРА" = list(/obj/item/coin, /obj/item/book/manual),
	"ХОЧЕТ СВОЕЙ СМЕРТИ" = list(/obj/item/pen, /obj/item/paper),
	"ИЩЕТ ГРУЗ" = list(/obj/item/flashlight, /obj/item/crowbar),
	"ЖДЁТ ПРИЗНАНИЯ {CHARACTER}" = list(/obj/item/pen, /obj/item/paper),
	"ВСТУПИТЬ В ОПОЛЧЕНИЕ {FACTION}" = list(/obj/item/melee/knife/survival, /obj/item/spacecash/bundle/c100),
	"ИЩЕТ ЗАНАЧКУ" = list(/obj/item/coin, /obj/item/spacecash/bundle/pocketchange),
	"ЖДЁТ ОЧИЩЕНИЯ" = list(/obj/item/coin, /obj/item/lighter),
	"ВЫКУПАЕТ {SHIP}" = list(/obj/item/spacecash/bundle/c500, /obj/item/coin),
	"ХОЧЕТ СЛАВЫ" = list(/obj/item/pen, /obj/item/paper),
	"ИЩЕТ ХРАМ" = list(/obj/item/book/manual, /obj/item/lighter),
	"ТОРГУЕТСЯ С НАНОТРЕЙЗЕН" = list(/obj/item/spacecash/bundle/c100, /obj/item/coin),
	"ИЩЕТ ЛЕТОПИСЦА" = list(/obj/item/pen, /obj/item/paper, /obj/item/book/manual),
	"ИЩЕТ СПОНСОРА" = list(/obj/item/spacecash/bundle/c500, /obj/item/coin),
	"ПИШЕТ МЕМУАРЫ" = list(/obj/item/pen, /obj/item/paper, /obj/item/book/manual),
	"ТЯЖБА С {FACTION}" = list(/obj/item/pen, /obj/item/paper, /obj/item/spacecash/bundle/c50),
	"ИЩЕТ БУТЫЛКУ" = list(/obj/item/reagent_containers/food/drinks/bottle/whiskey, /obj/item/coin),
	"ХОЧЕТ ТЁПЛОЙ ПОСТЕЛИ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c50),
	"СКУЧАЕТ ПО {SHIP}" = list(/obj/item/coin, /obj/item/toy/plush/carpplushie),
	"ЖДЁТ ВОЗМЕЗДИЯ {CHARACTER}" = list(/obj/item/coin, /obj/item/melee/knife/switchblade),
	"ЖДЁТ ПЕНСИЮ" = list(/obj/item/spacecash/bundle/c100, /obj/item/coin),
	"ИЩЕТ ЛОТЕРЕЮ" = list(/obj/item/coin, /obj/item/spacecash/bundle/c10),
	"НАЙМЁТ {CHARACTER}" = list(/obj/item/spacecash/bundle/c500, /obj/item/pen),
	"ЧАЙ С {CHARACTER}" = list(/obj/item/reagent_containers/food/drinks/bottle/wine, /obj/item/kitchen/fork),
	"ХОЧЕТ ОТКРЫТЬ КЛУБ" = list(/obj/item/spacecash/bundle/c500, /obj/item/kitchen/fork),
	"ИЩЕТ {CAPTAIN}" = list(/obj/item/coin, /obj/item/pen),
	"ХОЧЕТ НА ОБЛОЖКУ" = list(/obj/item/coin, /obj/item/lighter),
	"НОЧНАЯ ЗВЕЗДА" = list(/obj/item/lighter, /obj/item/coin),
	"ИЩЕТ ПАРТНЁРА" = list(/obj/item/coin, /obj/item/spacecash/bundle/c50),
	"СОБЛАЗНИТЬ {CAPTAIN}" = list(/obj/item/reagent_containers/food/drinks/bottle/wine, /obj/item/coin),
	"ПИШЕТ КНИГУ" = list(/obj/item/pen, /obj/item/paper, /obj/item/book/manual),
	"ИЩЕТ КЛИНИКУ" = list(/obj/item/reagent_containers/pill/mannitol, /obj/item/stack/medical/gauze),
	"КУЛЬТУРА {FACTION}" = list(/obj/item/coin, /obj/item/lighter),
	"НАЙМЁТ МАССАЖИСТА" = list(/obj/item/spacecash/bundle/c500, /obj/item/coin),
	"ХОЧЕТ ТАНЦЕВАТЬ" = list(/obj/item/coin, /obj/item/lighter),
	"ХОЧЕТ КРАСИВОГО" = list(/obj/item/lighter, /obj/item/coin),
	"МОЛЧАНИЕ {CHARACTER}" = list(/obj/item/coin, /obj/item/spacecash/bundle/c50),
))

/// Возвращает копию списка предметов для тега предыстории.
/proc/wagabond_get_loot_for_tag(tag)
	var/list/loot = GLOB.wagabond_tag_loot[tag]
	return loot ? loot.Copy() : list()

// Фолбэки на случай пустого раунда (нет кораблей или игроков)
GLOBAL_LIST_INIT(wagabond_faction_fallbacks, list(FACTION_SYNDICATE, FACTION_NT, FACTION_SOLCON, FACTION_INTEQ, FACTION_PIRATES, FACTION_ELYSIUM, FACTION_SRM, FACTION_CLIP, FACTION_FRONTIERSMEN, FACTION_PGF, FACTION_RAMZI, FACTION_INDEPENDENT))

GLOBAL_LIST_INIT(wagabond_ship_fallbacks, list("Ковчег «Вечность»", "СФВ «Клинок»", "НТСВ «Багровый Закат»", "ИОАВ «Освободитель»", "КСОВ «Тень»", "ХВП «Георгий»", "АВ «Рог Ориона»", "НПВ «Новый Рассвет»", "ФФ «Ржавый Фронтир»", "СФВ «Северный Ветер»", "РК «Пустынный Призрак»", "ПКА «Хамелеон»", "СФВ «Гордость Сектора»"))

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
	/// Предметы по предыстории (пути типов, создаются при спавне)
	var/list/loot = list()

/datum/wagabond_backstory/New(mob/exclude_mob)
	. = ..()
	var/list/former_entry = pick(GLOB.wagabond_former_entries)
	former = former_entry["text"]
	former_tag = former_entry["tag"]
	loot += wagabond_get_loot_for_tag(former_tag)
	var/list/fall_entry = pick(GLOB.wagabond_fall_entries)
	fall = fall_entry["text"]
	fall_tag = fall_entry["tag"]
	loot += wagabond_get_loot_for_tag(fall_tag)
	var/list/goal_entry = pick(GLOB.wagabond_goal_entries)
	goal = goal_entry["text"]
	goal_tag = goal_entry["tag"]
	loot += wagabond_get_loot_for_tag(goal_tag)

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
	var/note_text = backstory.get_narrative()
	to_chat(new_spawn, "<span class='big bold'>В глубине сознания всплывают обрывки прошлой жизни...</span>")
	to_chat(new_spawn, span_notice(backstory.get_tags()))
	to_chat(new_spawn, span_notice(backstory.get_narrative()))
	new_spawn.mind?.store_memory("Вы - бродяга. Ваша предыстория: [note_text]")
	var/obj/item/paper/crumpled/wagabond_memory/note = new(new_spawn.loc)
	note.add_raw_text(note_text)
	new_spawn.equip_to_slot_or_del(note, ITEM_SLOT_BACKPACK)
	for(var/item_type in backstory.loot)
		new_spawn.equip_to_slot_or_del(new item_type(new_spawn.loc), ITEM_SLOT_BACKPACK)
