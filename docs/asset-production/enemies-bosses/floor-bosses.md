# Five Floor Boss Specs

One unique boss per floor. Names build on the existing floor themes from
`arena_background.gd` (`set_floor_theme`) and keep Lord Malakar as the floor-5
capstone (his current identity, attacks, and enrage logic stay).

Shared contract: `character-model-spec.md` + clips `idle` (loop), `move` (loop),
`attack_1`, `attack_2`, `special`, `hurt`, `defeat`. Every boss gets one
signature emissive material used for its telegraphs so danger reads at mobile size.

| Floor | Theme (existing) | Boss | Identity | Signature attack to animate as `special` |
| --- | --- | --- | --- | --- |
| 1 | Abyssal Ruins | **Rustbone Warden** | Skeletal gatekeeper in corroded bronze, tattered banner-shroud | Slam that erupts a ring of gravestones (uses `nova_ring` VFX pattern) |
| 2 | Ember Catacombs | **Cinderpriest Malvor** | Dark mage, brazier-staff, cracked molten mask | Line dash leaving fire trail (maps to `abyssal_charge` telegraph) |
| 3 | Frostbound Crypt | **Queen Vessalyn** | Undead valkyrie, ice-feather mantle, frozen halberd | Cross-shaped ice spike volley (maps to `abyssal_cross` telegraph) |
| 4 | Blighted Sanctum | **Choirfather Ulgreth** | Bloated demon priest, incense censers for fists | Ground pools of blight (danger-disk pattern from `void_eruption`) |
| 5 | Crimson Throne | **Lord Malakar, the Abyssal Dread** (existing) | Existing design + unique 3D model | Keep all four current attacks + enrage at ≤50% HP |

Scale guidance: floors 1–3 bosses ≈ 1.6–1.9× hero height; 4 ≈ 2.1×;
Malakar ≈ 2.4×. Boss arenas reuse the floor's environment spec
(`environments/floor-specs.md`) — the arena needs clear space for each boss's
`special` pattern (ring ≥ 6 m diameter for floor 1, ≥ 14 m dash lane for floor 2,
cross span ≥ 10 m for floor 3, 3 pools ≥ 3 m for floor 4).

External generation note: these five models + animation sets are the main
candidate for an external AI 3D service; each needs one Blender cleanup pass
(scale/origin/clip names) against `character-model-spec.md` before integration.
