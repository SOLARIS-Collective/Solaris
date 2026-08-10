/// Player-facing ticket panel — styled interface with refresh support
/datum/player_ticket_panel
	var/datum/admin_help/ticket
	var/mob/owner

/datum/player_ticket_panel/New(datum/admin_help/AH, mob/user)
	ticket = AH
	owner = user

/// Opens the player ticket panel
/datum/player_ticket_panel/proc/show()
	if(!ticket || !owner?.client)
		return
	owner << browse(generate_html(), "window=pticket[ticket.id];size=620x520")

/// Generates styled HTML page
/datum/player_ticket_panel/proc/generate_html()
	var/list/dat = list()
	dat += {"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>
<meta http-equiv='pragma' content='no-cache'>
<meta http-equiv='refresh' content='5'>
<title>Ticket #[ticket.id]</title>
<style>
	body {
		background: #1a1a2e;
		color: #e0e0e0;
		font-family: 'Segoe UI', 'Roboto', sans-serif;
		font-size: 13px;
		margin: 0;
		padding: 12px;
	}
	.header {
		background: #16213e;
		border: 1px solid #0f3460;
		border-radius: 8px;
		padding: 10px 14px;
		margin-bottom: 10px;
	}
	.header h3 {
		margin: 0 0 6px 0;
		color: #e94560;
		font-size: 16px;
	}
	.header .meta {
		color: #a0a0b0;
		font-size: 12px;
	}
	.header .meta b {
		color: #c0c0d0;
	}
	.state-open { color: #e94560; font-weight: bold; }
	.state-resolved { color: #4ecca3; font-weight: bold; }
	.state-closed { color: #888; }
	.log {
		background: #0f3460;
		border-radius: 8px;
		padding: 10px;
		max-height: 280px;
		overflow-y: auto;
		margin-bottom: 10px;
		font-size: 12px;
		line-height: 1.5;
	}
	.log .admin-msg { color: #7ec8e3; }
	.log .player-msg { color: #ff9f43; }
	.log .system-msg { color: #888; font-style: italic; }
	.toolbar {
		text-align: center;
		margin-top: 6px;
	}
	.toolbar a {
		color: #7ec8e3;
		font-size: 12px;
		text-decoration: none;
		background: #16213e;
		border: 1px solid #0f3460;
		border-radius: 4px;
		padding: 4px 12px;
	}
	.toolbar a:hover {
		background: #0f3460;
		border-color: #e94560;
	}
</style>
</head>
<body>
<div class="header">
	<h3>Ticket #[ticket.id]</h3>
	<div class="meta">
		<b>State:</b> <span class="state-"}
	switch(ticket.state)
		if(AHELP_ACTIVE)
			dat += "open\">Open</span>"
		if(AHELP_RESOLVED)
			dat += "resolved\">Resolved</span>"
		if(AHELP_CLOSED)
			dat += "closed\">Closed</span>"
	dat += "<br>"
	dat += "<b>Topic:</b> [ticket.name]<br>"
	var/handler_name = ticket.claimed_by ? ticket.claimed_by : "nobody"
	dat += "<b>Handler:</b> [handler_name]"
	dat += "</div></div>"

	dat += "<div class=\"log\">"
	for(var/I in ticket._interactions)
		var/msg_class = "system-msg"
		if(findtext(I, "color='red'") || findtext(I, "color=\"red\"") || findtext(I, "color='#ff9f43'"))
			msg_class = "player-msg"
		else if(findtext(I, "color='blue'") || findtext(I, "color=\"blue\"") || findtext(I, "color='green'") || findtext(I, "color=\"green\"") || findtext(I, "color='purple'"))
			msg_class = "admin-msg"
		// Strip inline font tags so CSS classes take effect
		var/clean_msg = replacetext(I, "<font color='red'>", "")
		clean_msg = replacetext(clean_msg, "<font color=\"red\">", "")
		clean_msg = replacetext(clean_msg, "<font color='blue'>", "")
		clean_msg = replacetext(clean_msg, "<font color=\"blue\">", "")
		clean_msg = replacetext(clean_msg, "<font color='green'>", "")
		clean_msg = replacetext(clean_msg, "<font color=\"green\">", "")
		clean_msg = replacetext(clean_msg, "<font color='purple'>", "")
		clean_msg = replacetext(clean_msg, "<font color=\"purple\">", "")
		clean_msg = replacetext(clean_msg, "<font color='#ff9f43'>", "")
		clean_msg = replacetext(clean_msg, "<font color=\"#ff9f43\">", "")
		clean_msg = replacetext(clean_msg, "</font>", "")
		dat += "<div class=\"[msg_class]\">[clean_msg]</div>"
	dat += "</div>"

	dat += "<div class=\"toolbar\">"
	dat += "<a href='byond://?src=[REF(owner.client)];action=player_ticket_refresh;ticket_id=[ticket.id]'>Refresh</a>"
	dat += "</div>"

	dat += "</body></html>"
	return dat.Join()

/// Client verb: allows players to view their own ticket
/client/verb/view_my_ticket()
	set name = "View Ticket"
	set category = "Admin"
	set desc = "View your current admin help ticket"

	if(!mob || !current_ticket)
		to_chat(src, span_notice("You have no active ticket."), confidential = TRUE)
		return

	if(holder)
		to_chat(src, span_notice("Use the admin ticket panel instead."), confidential = TRUE)
		return

	var/datum/player_ticket_panel/panel = new(current_ticket, mob)
	panel.show()