# Enemy & Boss Asset Production Specs

Two production tracks exist. Read both before making enemy art.

## Track A — Sprite-sheet animation (current live path for enemies/bosses)

Contract: `assets/art/enemies/source/manifest.example.json` (copy to
`manifest.json` to activate). Validated at runtime by
`enemy_boss_sprite_animation.gd` (rejects the whole actor if any required clip or
frame index is bad) and offline by `tools/validate_enemy_boss_art_source.gd`.

- Sheets: 6 columns × 5 rows, frame size per actor (swarmer 128 → boss 224 px).
- Clips: `idle, move, attack, hurt, defeat` — frame-index lists + fps + loop.
- Actor ids fixed by code: `swarmer, cultist, charger, elite_brute, abyssal_champion, lord_malakar`.

### Required enemy set (fixes today's tinted-sprite reuse)

| Actor | Today | Production target |
| --- | --- | --- |
| swarmer | `enemy_swarmer.png` | keep; refresh sheet first |
| cultist | `enemy_cultist.png` | keep; refresh sheet first |
| charger | tinted swarmer sprite (`enemy_controller.gd` ~line 210) | **unique sheet**: armored hound/beetle silhouette, ember-red accents |
| elite_brute | `enemy_elite.png` | **unique sheet**: hulking undead brute, slab shield |
| abyssal_champion | manifest path only | **unique sheet**: mini-boss knight, boss-grade 224 px frames |

### Boss: lord_malakar

Single boss (`BossController`, "Lord Malakar, the Abyssal Dread") scaled per floor.
If keeping one-boss design, produce his 224 px sheet with the four telegraphed
attacks in mind (`void_eruption`, `abyssal_charge`, `nova_ring`, `abyssal_cross`) —
the `attack` clip should read as a cast, while VFX sells each attack type.

## Track B — Per-floor unique bosses (3D GLB path)

Design decision recorded in the audit: the game currently reuses one boss model
for all five floors. The production target is one unique GLB boss per floor,
each with its own clips. Specs in `enemies-bosses/floor-bosses.md`. Each boss GLB
must satisfy `character-model-spec.md` with clips `idle, move, attack_1, attack_2,
special, hurt, defeat` (loop: idle, move). Scale: bosses 1.6–2.4× hero height
(set `model_scale` on the boss preview, do not bake huge meshes).

Wire-up for a future 3D boss: extend `boss_controller.gd` the way
`player_controller.gd` does — try GLB, fall back to
`EnemyBossSpriteAnimation`, fall back to tinted sprite. Do not remove the
existing sprite path; it is the headless-CI and low-end-device path.

## Pets (small but visible)

`demon` pet reuses the hellhound texture (`pet_controller.gd` ~line 38). One
additional 256 px sheet or a tiny GLB closes the gap; keep ≤ 300 tris if 3D.
