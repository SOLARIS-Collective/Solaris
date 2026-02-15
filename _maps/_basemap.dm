//#define NOOVERMAP //uncomment this to load centcom and runtime station and thats it.
//#define MINIMAL //uncomment this to load a smaller centcomm and smaller runtime station, only works together with NOOVERMAP

#ifdef MINIMAL
#define NOOVERMAP
#endif

#ifdef ALL_MAPS
	#ifdef CIBUILDING
		#include "templates.dm"
	#endif
#endif

// [MANKIND-ADD] - MANKIND_CONFIGS_MAPS
#include "_modular_mankind\map_files\centcomm_ship.dmm"
// [/MANKIND-ADD]
