// [SOLARIS-ADD] - STOCK_PDA
// Устанавливаемое ПО Фронтир-биржи для ПДА (NTOS): те же котировки, графики и
// торговля, что и у терминала, но прямо с планшета. Скачивается из NTNet-каталога
// (available_on_ntnet) и предустановлено на планшеты. Логика сессий и данных
// общая с машиной stock_terminal (SSstock_market.terminal_session/terminal_ui_data).

/datum/computer_file/program/stock_terminal
	filename = "stockmarket"
	filedesc = "Frontier Exchange Terminal"
	extended_desc = "Портативный клиент Фронтир-биржи: котировки, графики цен, портфель и торговля прямо с планшета. Для личного счёта нужна вставленная в кард-слот банковская карта."
	program_icon = "chart-line"
	size = 6
	requires_ntnet = FALSE
	available_on_ntnet = TRUE
	usage_flags = PROGRAM_ALL
	tgui_id = "NtosStockTerminal"

	/// Активная сессия: фракционный пул корабля игрока или личный счёт игрока
	var/datum/brokerage_session/linked_session
	/// Последняя ошибка/сообщение для отображения в интерфейсе
	var/last_error = ""

/// Создаёт/подхватывает сессию по карте игрока (SSstock_market.terminal_session):
/// фракция берётся из ship_access ID-карты, а не из зоны, где держат планшет.
/datum/computer_file/program/stock_terminal/proc/ensure_session(mob/user)
	last_error = ""
	var/list/res = SSstock_market.terminal_session(user)
	linked_session = res["session"]
	if(!linked_session)
		last_error = res["error"]
	return linked_session

/datum/computer_file/program/stock_terminal/ui_interact(mob/user, datum/tgui/ui)
	ensure_session(user)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui && tgui_id)
		ui = new(user, src, tgui_id, filedesc)
		if(ui.open())
			ui.send_asset(get_asset_datum(/datum/asset/simple/headers))

/datum/computer_file/program/stock_terminal/ui_data(mob/user)
	ensure_session(user)
	var/list/data = get_header_data()
	var/list/market_data = SSstock_market.terminal_ui_data(linked_session, last_error)
	for(var/key in market_data)
		data[key] = market_data[key]
	return data

/datum/computer_file/program/stock_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(!linked_session)
		return
	var/list/res = SSstock_market.handle_terminal_act(action, params, linked_session)
	if(isnull(res))
		return
	if(!res["ok"])
		last_error = res["error"]
	else
		last_error = ""
	. = TRUE

/// Предустановка на планшеты (в т.ч. пресеты: HDD появляется после install_component,
/// поэтому ловим его отложенно, на следующий тик после Initialize).
/obj/item/modular_computer/tablet/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(preinstall_stock_terminal)), 0)

/obj/item/modular_computer/tablet/proc/preinstall_stock_terminal()
	var/obj/item/computer_hardware/hard_drive/hdd = all_components[MC_HDD]
	if(hdd && !hdd.find_file_by_name("stockmarket"))
		hdd.store_file(new /datum/computer_file/program/stock_terminal(src))
// [/SOLARIS-ADD] - STOCK_PDA