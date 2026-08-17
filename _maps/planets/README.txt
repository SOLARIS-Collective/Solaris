Pre-generated planet surface maps (.dmm) for fast planet loading.

Generated via the admin verb "Planet Pre-Generation" (Debug tab).
Each .dmm is accompanied by a .json metadata file describing the
planet type used (planet_type field). Files are scanned at roundstart
by SSmapping and used instead of procedural generation when a ship
docks to a matching planet type.

Do not delete the .json files, they are required for the loader.
