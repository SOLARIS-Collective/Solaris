GLOBAL_VAR_INIT(security_level, SEC_LEVEL_GREEN)
//SEC_LEVEL_GREEN = code green
//SEC_LEVEL_BLUE = code blue
//SEC_LEVEL_RED = code red
//SEC_LEVEL_DELTA = code delta

//config.alert_desc_blue_downto

/proc/set_security_level(level)
	switch(level)
		if("green")
			level = SEC_LEVEL_GREEN
		if("blue")
			level = SEC_LEVEL_BLUE
		if("red")
			level = SEC_LEVEL_RED
		if("delta")
			level = SEC_LEVEL_DELTA

	//Will not be announced if you try to set to the same level as it already is
	if(level >= SEC_LEVEL_GREEN && level <= SEC_LEVEL_DELTA && level != GLOB.security_level)
		switch(level)
			if(SEC_LEVEL_GREEN)
				announce_security_level_change(SEC_LEVEL_GREEN, CONFIG_GET(string/alert_green), FALSE)
				GLOB.security_level = SEC_LEVEL_GREEN
			if(SEC_LEVEL_BLUE)
				if(GLOB.security_level < SEC_LEVEL_BLUE)
					announce_security_level_change(SEC_LEVEL_BLUE, CONFIG_GET(string/alert_blue_upto), TRUE)
				else
					announce_security_level_change(SEC_LEVEL_BLUE, CONFIG_GET(string/alert_blue_downto), FALSE)
				GLOB.security_level = SEC_LEVEL_BLUE
			if(SEC_LEVEL_RED)
				if(GLOB.security_level < SEC_LEVEL_RED)
					announce_security_level_change(SEC_LEVEL_RED, CONFIG_GET(string/alert_red_upto), TRUE)
				else
					announce_security_level_change(SEC_LEVEL_RED, CONFIG_GET(string/alert_red_downto), FALSE)
				GLOB.security_level = SEC_LEVEL_RED

			if(SEC_LEVEL_DELTA)
				announce_security_level_change(SEC_LEVEL_DELTA, CONFIG_GET(string/alert_delta), TRUE)
				GLOB.security_level = SEC_LEVEL_DELTA
		if(level >= SEC_LEVEL_RED)
			for(var/obj/machinery/door/D in GLOB.machines)
				if(D.red_alert_access)
					D.visible_message(span_notice("[D] whirrs as it automatically lifts access requirements!"))
					playsound(D, 'sound/machines/boltsup.ogg', 50, TRUE)
		SSblackbox.record_feedback("tally", "security_level_changes", 1, get_security_level())
	else
		return

/proc/get_security_level()
	switch(GLOB.security_level)
		if(SEC_LEVEL_GREEN)
			return "green"
		if(SEC_LEVEL_BLUE)
			return "blue"
		if(SEC_LEVEL_RED)
			return "red"
		if(SEC_LEVEL_DELTA)
			return "delta"

/proc/num2seclevel(num)
	switch(num)
		if(SEC_LEVEL_GREEN)
			return "green"
		if(SEC_LEVEL_BLUE)
			return "blue"
		if(SEC_LEVEL_RED)
			return "red"
		if(SEC_LEVEL_DELTA)
			return "delta"

/proc/seclevel2num(seclevel)
	switch(lowertext(seclevel))
		if("green")
			return SEC_LEVEL_GREEN
		if("blue")
			return SEC_LEVEL_BLUE
		if("red")
			return SEC_LEVEL_RED
		if("delta")
			return SEC_LEVEL_DELTA
