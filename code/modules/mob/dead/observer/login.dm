/mob/dead/observer/Login()
	. = ..()
	if(!. || !client)
		return FALSE

	if(isAdminGhostAI(src))
		has_unlimited_silicon_privilege = 1

	if(client.prefs?.unlock_content)
		ghost_orbit = client.prefs.ghost_orbit
