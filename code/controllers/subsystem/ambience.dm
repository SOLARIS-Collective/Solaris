/// The subsystem used to play ambience to users every now and then, makes them real excited.
SUBSYSTEM_DEF(ambience)
	name = "Ambience"
	flags = SS_BACKGROUND|SS_NO_INIT
	priority = FIRE_PRIORITY_AMBIENCE
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 1 SECONDS
	///Assoc list of listening client - next ambience time
	var/list/ambience_listening_clients = list()

/datum/controller/subsystem/ambience/fire(resumed)
	for(var/client/client_iterator as anything in ambience_listening_clients)

		//Check to see if the client exists and isn't held by a new player
		var/mob/client_mob = client_iterator?.mob

		if(isnull(client_iterator) || isnewplayer(client_iterator.mob))
			ambience_listening_clients -= client_iterator
			continue

		if(ambience_listening_clients[client_iterator] > world.time)
			continue //Not ready for the next sound

		var/area/current_area = get_area(client_iterator.mob)

		ambience_listening_clients[client_iterator] = world.time + current_area.play_ambience(client_mob)

///Attempts to play an ambient sound to a mob, returning the cooldown in deciseconds
/area/proc/play_ambience(mob/M, sound/override_sound, volume = 27)
	// [MANKIND-ADD] - FIXES_AMBIENT_NO_EARS
	// Check if the mob has ears to hear the ambience
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		if(!C.getorganslot(ORGAN_SLOT_EARS))
			// No ears, no ambience
			var/sound_file = override_sound ? override_sound.file : pick(ambientsounds)
			var/sound_length = ceil(SSsound_cache.get_sound_length(sound_file))
			return rand(min_ambience_cooldown + sound_length, max_ambience_cooldown + sound_length)
	// [/MANKIND-ADD]
	var/sound_file = override_sound ? override_sound.file : pick(ambientsounds)
	M.playsound_local(null, sound_file, 25, channel = CHANNEL_AMBIENCE, sound_flag = FS_AMBIENCE)

	var/sound_length = ceil(SSsound_cache.get_sound_length(sound_file))
	return rand(min_ambience_cooldown + sound_length, max_ambience_cooldown + sound_length)
