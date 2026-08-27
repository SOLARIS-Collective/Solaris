/**
 * The game's world.icon_size. \
 * Ideally divisible by 16. \
 * Ideally a number, but it
 * can be a string ("32x32"), so more exotic coders
 * will be sad if you use this in math.
 */
#define ICON_SIZE_ALL 32
/// The X/Width dimension of ICON_SIZE. This will more than likely be the bigger axis.
#define ICON_SIZE_X 32
/// The Y/Height dimension of ICON_SIZE. This will more than likely be the smaller axis.
#define ICON_SIZE_Y 32

// [SOLARIS-ADD] - Current phase label written into every auxcp_rec.log row ("ph").
// Set at the entry of boot/load hot paths so freeze rows (raw >> 100%) can be attributed.
// Runtime-gated by the AUXCP_PHASE_LABELS game option (config/game_options.txt, off by default):
// when disabled these cost one bool check and write nothing. Recording itself stays manual (REC button).
// NOTE: expands to a braced if — do NOT place a call directly before an `else`.
#define AUXCPU_PHASE(phase_label) if(GLOB.auxcp_phases_enabled) { GLOB.auxcpu_phase = phase_label; }
#define AUXCPU_PHASE_END if(GLOB.auxcp_phases_enabled) { GLOB.auxcpu_phase = ""; }
