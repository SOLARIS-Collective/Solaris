/mob/dead/observer/Logout()
	if(observetarget)
		if(ismob(observetarget))
			var/mob/target = observetarget
			if(target.observers)
				LAZYREMOVE(target.observers, src)
			observetarget = null
	..()
	spawn(0)
		if(src && !key)	//we've transferred to another mob. This ghost should be deleted.
			qdel(src)
