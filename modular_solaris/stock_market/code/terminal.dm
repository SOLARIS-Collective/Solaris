// [SOLARIS-ADD] - STOCK_TERMINAL
// Терминал Фронтир-биржи: игровой доступ к котировкам, графикам, торговле и
// новостям. Режим доступа по README:
//   - фракционные корабли -> общий виртуальный пул фракции (STOCK_MODE_FACTION)
//   - independent/пираты  -> личный счёт по банковской карте (STOCK_MODE_PERSONAL)

/obj/item/circuitboard/computer/stock_terminal
	name = "Stock Exchange Terminal (Computer Board)"
	icon_state = "command"
	build_path = /obj/machinery/computer/stock_terminal

/obj/machinery/computer/stock_terminal
	name = "stock exchange terminal"
	desc = "Терминал Фронтир-биржи: котировки, графики цен, торговля и новости рынка в одном окне."
	icon_screen = "command"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/stock_terminal
	light_color = "#33cc66"

	/// Активная сессия: фракционный пул корабля игрока или личный счёт игрока
	var/datum/brokerage_session/linked_session
	/// Последняя ошибка/сообщение для отображения в интерфейсе
	var/last_error = ""

/obj/machinery/computer/stock_terminal/Destroy()
	linked_session = null
	return ..()

/// Создаёт/подхватывает сессию терминала по карте игрока (SSstock_market.terminal_session).
/obj/machinery/computer/stock_terminal/proc/ensure_session(mob/user)
	last_error = ""
	var/list/res = SSstock_market.terminal_session(user)
	linked_session = res["session"]
	if(!linked_session)
		last_error = res["error"]
	return linked_session

/obj/machinery/computer/stock_terminal/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ensure_session(user)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StockExchange", name)
		ui.open()

/obj/machinery/computer/stock_terminal/ui_data(mob/user)
	return SSstock_market.terminal_ui_data(linked_session, last_error)

/obj/machinery/computer/stock_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
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
// [/SOLARIS-ADD]