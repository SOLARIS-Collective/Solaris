// auxcpu.dm - DM API for the auxcpu byondapi extension library
//
// auxcpu exposes the "raw" (deaveraged) per-tick CPU values that BYOND keeps
// internally as a 16-entry moving average. This lets us do much more accurate
// lag compensation for gliding than the approximation we can derive from
// world.cpu alone.
//
// To configure, create a `auxcpu.config.dm` and set:
//
// #define AUXCPU "path/to/auxcpu_byondapi"
// Override the .dll/.so detection logic with a fixed path or with detection
// logic of your own.
//
// If the library is not present at runtime, every proc here falls back to the
// best approximation available from world.cpu / world.map_cpu, so the game
// still works without the dependency.

#ifndef AUXCPU
// Default automatic AUXCPU detection.
// On Windows, looks for `auxcpu_byondapi.dll`.
// On Linux, looks in `.` and `~/.byond/bin` for `libauxcpu_byondapi.so`.
/var/__auxcpu

/proc/__detect_auxcpu()
	if (world.system_type == UNIX)
		if (fexists("./libauxcpu_byondapi.so"))
			return __auxcpu = "./libauxcpu_byondapi.so"
		else if (fexists("[world.GetConfig("env", "HOME")]/.byond/bin/libauxcpu_byondapi.so"))
			return __auxcpu = "[world.GetConfig("env", "HOME")]/.byond/bin/libauxcpu_byondapi.so"
		else
			return __auxcpu = "libauxcpu_byondapi.so"
	else
		return __auxcpu = "auxcpu_byondapi.dll"

#define AUXCPU (__auxcpu || __detect_auxcpu())
#endif

/// Whether the auxcpu library was successfully loaded and hooked this round.
GLOBAL_VAR_INIT(auxcpu_loaded, FALSE)

/// Loads the auxcpu library and hooks its signatures. Returns TRUE on success.
/world/proc/setup_external_cpu()
	. = FALSE
	if(!fexists(AUXCPU))
		// Library not present, fall back to world.cpu approximations.
		return FALSE
	if(!call_ext(AUXCPU, "byond:find_signatures")())
		// Library present but failed to hook, fall back to world.cpu approximations.
		return FALSE
	GLOB.auxcpu_loaded = TRUE
	return TRUE

/// Unloads/cleans up the auxcpu library. No-op for now.
/world/proc/cleanup_external_cpu()
	return

/// Returns the raw (deaveraged) CPU usage of the current tick.
/proc/current_true_cpu()
	if(!GLOB.auxcpu_loaded)
		return world.cpu
	return call_ext(AUXCPU, "byond:current_true_cpu")()

/// Returns the index (1..16) of the current tick in BYOND's internal CPU buffer.
/proc/current_cpu_index()
	if(!GLOB.auxcpu_loaded)
		return WRAP(world.time, 1, INTERNAL_CPU_SIZE + 1)
	var/actual_index = call_ext(AUXCPU, "byond:current_cpu_index")()
	return WRAP(actual_index + 1, 1, INTERNAL_CPU_SIZE + 1)

/// Returns the raw CPU value stored at the given index (1..16) of BYOND's buffer.
/proc/true_cpu_at_index(index)
	if(!GLOB.auxcpu_loaded)
		if(index == current_cpu_index())
			return current_true_cpu()
		return 0
	var/actual_index = WRAP(index - 1, 0, INTERNAL_CPU_SIZE)
	return call_ext(AUXCPU, "byond:true_cpu_at_index")(actual_index)

/// Returns a list of the raw CPU values for all 16 slots of BYOND's buffer.
/proc/cpu_values()
	if(!GLOB.auxcpu_loaded)
		var/list/values = list()
		for(var/i in 1 to INTERNAL_CPU_SIZE)
			values += true_cpu_at_index(i)
		return values
	return call_ext(AUXCPU, "byond:cpu_values")()