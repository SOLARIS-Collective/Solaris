// auxcpu.dm - DM API for the auxcpu byondapi extension library
//
// auxcpu exposes the "raw" (deaveraged) per-tick CPU values that BYOND keeps
// internally as a 16-entry moving average. This lets us do much more accurate
// lag compensation for gliding and cpu stabilization than what we can derive
// from world.cpu alone.
//
// The library is loaded at runtime if present:
// - On Windows, `auxcpu_byondapi.dll` next to the executable (repo root).
// - On Linux, `libauxcpu_byondapi.so` in the working directory (TGS deployment
//   root) or in `~/.byond/bin/`.
//
// If the library is not present at runtime, every proc here falls back to the
// best approximation available from world.cpu, so the game still works without
// the dependency (glide compensation just gets less precise).

/// Macro for getting the auxcpu library file
#define AUXCPU_DLL (world.system_type == MS_WINDOWS ? "auxcpu_byondapi.dll" : __detect_auxcpu())

/proc/__detect_auxcpu()
	if(IsAdminAdvancedProcCall())
		return "libauxcpu_byondapi.so"
	if (fexists("./libauxcpu_byondapi.so"))
		return "./libauxcpu_byondapi.so"
	else if (fexists("[world.GetConfig("env", "HOME")]/.byond/bin/libauxcpu_byondapi.so"))
		return "[world.GetConfig("env", "HOME")]/.byond/bin/libauxcpu_byondapi.so"
	else
		return "libauxcpu_byondapi.so"

/// Whether the auxcpu library was successfully loaded and hooked this round.
GLOBAL_VAR_INIT(auxcpu_loaded, FALSE)

// [SOLARIS-ADD] - Current boot/load phase label for auxcp_rec.log attribution
GLOBAL_VAR_INIT(auxcpu_phase, "")

#ifdef OPENDREAM

// OpenDream cannot load byondapi libraries, always use approximations.

/world/proc/setup_external_cpu()
	return FALSE

/world/proc/cleanup_external_cpu()
	return

/proc/current_true_cpu()
	return world.cpu

/proc/current_cpu_index()
	return WRAP(world.time, 1, INTERNAL_CPU_SIZE + 1)

/proc/true_cpu_at_index(index)
	if(index == current_cpu_index())
		return current_true_cpu()
	return 0

/proc/cpu_values()
	var/list/values = list()
	for(var/i in 1 to INTERNAL_CPU_SIZE)
		values += true_cpu_at_index(i)
	return values

#else

/// Loads the auxcpu library and hooks its signatures. Returns TRUE on success.
/world/proc/setup_external_cpu()
	. = FALSE
	if(!CONFIG_GET(flag/load_auxcpu_library))
		log_world("auxcpu: disabled by config (LOAD_AUXCPU_LIBRARY), using world.cpu averaging")
		return FALSE
	if(!fexists(AUXCPU_DLL))
		log_world("auxcpu: library not found, falling back to world.cpu averaging")
		return FALSE
	if(!call_ext(AUXCPU_DLL, "byond:find_signatures")())
		log_world("auxcpu: failed to find signatures, falling back to world.cpu averaging")
		return FALSE
	GLOB.auxcpu_loaded = TRUE
	log_world("auxcpu: signatures found, raw CPU tracking enabled")
	return TRUE

/// Unloads/cleans up the auxcpu library. No-op for now, kept for API parity.
/world/proc/cleanup_external_cpu()
	return

/// Returns the raw (deaveraged) CPU usage of the current tick.
/proc/current_true_cpu()
	if(!GLOB.auxcpu_loaded)
		return world.cpu
	var/static/__current_true_cpu
	__current_true_cpu ||= load_ext(AUXCPU_DLL, "byond:current_true_cpu")
	return call_ext(__current_true_cpu)()

/// Returns the index (1..[INTERNAL_CPU_SIZE]) of the current tick in BYOND's internal CPU buffer.
/proc/current_cpu_index()
	if(!GLOB.auxcpu_loaded)
		return WRAP(world.time, 1, INTERNAL_CPU_SIZE + 1)
	var/static/__current_cpu_index
	__current_cpu_index ||= load_ext(AUXCPU_DLL, "byond:current_cpu_index")
	var/actual_index = call_ext(__current_cpu_index)()
	return WRAP(actual_index + 1, 1, INTERNAL_CPU_SIZE + 1)

/// Returns the raw CPU value stored at the given index (1..[INTERNAL_CPU_SIZE]) of BYOND's buffer.
/proc/true_cpu_at_index(index)
	var/actual_index = WRAP(index - 1, 0, INTERNAL_CPU_SIZE)
	if(!GLOB.auxcpu_loaded)
		if(index == current_cpu_index())
			return current_true_cpu()
		return 0
	var/static/__true_cpu_at_index
	__true_cpu_at_index ||= load_ext(AUXCPU_DLL, "byond:true_cpu_at_index")
	return call_ext(__true_cpu_at_index)(actual_index)

/// Returns a list of the raw CPU values for all [INTERNAL_CPU_SIZE] slots of BYOND's buffer.
/proc/cpu_values()
	if(!GLOB.auxcpu_loaded)
		var/list/values = list()
		for(var/i in 1 to INTERNAL_CPU_SIZE)
			values += true_cpu_at_index(i)
		return values
	var/static/__cpu_values
	__cpu_values ||= load_ext(AUXCPU_DLL, "byond:cpu_values")
	return call_ext(__cpu_values)()

#endif
