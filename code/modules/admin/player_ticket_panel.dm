/// Player-facing ticket panel — shows ticket history transparently
/datum/player_ticket_panel
	var/datum/admin_help/ticket

/datum/player_ticket_panel/New(datum/admin_help/AH)
	ticket = AH

/// Opens the player ticket panel
/datum/player_ticket_panel/proc/show(mob/user)
	if(!ticket || !user?.client)
		return
	user << browse(generate_html(), "window=pticket[ticket.id];size=620x480")

/// Generates HTML with the full interaction log (no anonymization)
/datum/player_ticket_panel/proc/generate_html()
	var/list/dat = list()
	dat += "<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>"
	dat += "<title>Ticket #[ticket.id]</title></head><body>"
	dat += "<h4>Ticket #[ticket.id]</h4>"
	dat += "<b>Состояние: "
	switch(ticket.state)
		if(AHELP_ACTIVE)
			dat += "<font color='red'>Открыт</font>"
		if(AHELP_RESOLVED)
			dat += "<font color='green'>Решён</font>"
		if(AHELP_CLOSED)
			dat += "Закрыт"
	dat += "</b><br><br>"
	dat += "<b>Тема:</b> [ticket.name]<br><br>"
	var/handler_name = ticket.claimed_by ? ticket.claimed_by : "нет"
	dat += "<b>Взял:</b> [handler_name]<br><br>"
	dat += "<b>История:</b><br>"
	for(var/I in ticket._interactions)
		dat += "[I]<br>"
	dat += "</body></html>"
	return dat.Join()

/// Client verb: allows players to view their own ticket
/client/verb/view_my_ticket()
	set name = "Просмотр тикета"
	set category = "Admin"
	set desc = "Посмотреть свой тикет обращения к администрации"

	if(!mob || !current_ticket)
		to_chat(src, span_notice("У вас нет активного тикета."), confidential = TRUE)
		return

	if(holder)
		to_chat(src, span_notice("Используйте панель тикетов администратора."), confidential = TRUE)
		return

	var/datum/player_ticket_panel/panel = new(current_ticket)
	panel.show(mob)
