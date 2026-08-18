Pre-generated planet layouts (seed bundles, .json) for fast planet loading.

Generated via the admin verb "Planet Pre-Generation" (Debug tab).

Each .json is a seed bundle: planet type, perlin noise seeds and generator
parameters (a few kilobytes). At encounter spawn the biome layout grid is
computed from the seed asynchronously (rust-g noise, world untouched); when
a ship docks, only turf materialization happens - no rust-g in the hot loop.

Files are scanned at roundstart by SSmapping and used instead of procedural
generation when a ship docks to a matching planet type.

Do not delete the .json files, they are required for the loader.
