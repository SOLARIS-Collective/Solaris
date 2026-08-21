/// Percentage of tick to leave for master controller to run
#define MAPTICK_MC_MIN_RESERVE 70
//internal_tick_usage is updated every tick
#if DM_VERSION > 513
#define MAPTICK_LAST_INTERNAL_TICK_USAGE world.map_cpu
#else
#define MAPTICK_LAST_INTERNAL_TICK_USAGE 50
#endif
// Tick limit while running normally
#define TICK_BYOND_RESERVE 2
#define TICK_VERB_RESERVE 4
#define TICK_EXPECTED_SAFE_MAX (100 - TICK_BYOND_RESERVE - TICK_VERB_RESERVE - MAPTICK_LAST_INTERNAL_TICK_USAGE)
/// Tick limit while running normally.
/// With dynamic MC limiting enabled we limit ourselves to the corrective cpu threshold
/// (see code/game/world.dm), so the corrective burn in /world/Tick can pin usage to a
/// consistent level without fighting the MC for tick time.
#define TICK_LIMIT_RUNNING (max(GLOB.use_dynamic_mc_limit ? GLOB.corrective_cpu_threshold : TICK_EXPECTED_SAFE_MAX, MAPTICK_MC_MIN_RESERVE))
/// Tick limit used to resume things in stoplag
#define TICK_LIMIT_TO_RUN 70
/// Tick limit for MC while running
#define TICK_LIMIT_MC 70

/// Size of the moving average BYOND stores {map_)cpu values in
#define INTERNAL_CPU_SIZE 16
/// How many ticks worth of raw cpu samples we keep around for compensation math
#define CPU_COMPENSATION_WINDOW 30

/// Consumes spare tick cpu until TICK_USAGE reaches the target percentage.
/// Used to pin tick usage to a consistent level so the gap between SendMaps() calls
/// stays constant (clients skip frames when it varies, which reads as stutter).
#define CONSUME_UNTIL(target_usage) while(TICK_USAGE < (target_usage)) ;

/// for general usage of tick_usage
#define TICK_USAGE world.tick_usage
/// to be used where the result isn't checked
#define TICK_USAGE_REAL world.tick_usage

/// Returns true if tick_usage is above the limit
#define TICK_CHECK (TICK_USAGE > Master.current_ticklimit)
/// runs stoplag if tick_usage is above the limit
#define CHECK_TICK (TICK_CHECK ? stoplag() : 0)

/// Returns true if tick usage is above 95, for high priority usage
#define TICK_CHECK_HIGH_PRIORITY (TICK_USAGE > 95)
/// runs stoplag if tick_usage is above 95, for high priority usage
#define CHECK_TICK_HIGH_PRIORITY (TICK_CHECK_HIGH_PRIORITY? stoplag() : 0)
