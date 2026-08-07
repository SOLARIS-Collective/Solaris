// SOLARIS-SPACEPOD: адаптация atom_defense.dm из PR 2039
// В билде уже есть кор-кодовые update_integrity()/atom_break()/take_damage(),
// поэтому вливаем только недостающий get_integrity_pod().

/// This mostly exists to keep atom_integrity private. Might be useful in the future.
/atom/proc/get_integrity_pod()
	SHOULD_BE_PURE(TRUE)
	return atom_integrity
