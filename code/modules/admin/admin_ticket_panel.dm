/// Admin ticket panel helpers
/// Provides follow-proc shortcuts for admin ticket interactions

/// Generates a follow link in admin ticket panel log entries
/datum/admin_help/proc/get_admin_ticket_flw(mob/living/M)
	if(!M)
		return ""
	return ADMIN_FLW(M)