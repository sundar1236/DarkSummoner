# Hero Production Specs

Palettes below are extracted from `scripts/combat/character_rig_visual.gd`
(PALETTES) and stats from `scripts/characters/character_database.gd`. Use these
exact colors so 2D fallback and 3D model read as the same character.

Status column: **DONE** = generator exists and validated; **SPEC ONLY** = spec
ready, generator/model must be produced.

## shadow_hunter — Shadow Hunter, the Umbral Blade — DONE

- Unlock: default. Stats: 120 HP / 250 spd / 18 atk / 15% crit / 2.4 rate. Attack: `slashes`.
- Palette: main `#29223f`, light `#8060bb`, dark `#151321`, glow `#c69aff` (violet), metal `#b9a7d8`, skin `#d9c7e9`.
- Silhouette: hooded assassin, split hood tails, face mask, glowing violet eyes, oversized moonsteel dagger (`weapon` bone, right hand), layered cape.
- Model: `tools/blender/generate_shadow_hunter.py` → `assets/generated/shadow_hunter.glb`, 9-bone skeleton, 10 clips, 6 materials. Verified by `tools/ci/validate_generated_glb.gd` + `tools/ci/validate_character_render.gd`.
- `model_scale` 0.82 in combat visual scene, 1.0 in hub pedestal.

## storm_reaper — Storm Reaper, the Tempest Edge — SPEC ONLY

- Unlock: 40 shades, floor 2. Stats: 105 HP / 230 spd / 24 atk / 10% crit / 1.8 rate. Attack: `lightning_bolts`.
- Palette: main `#263b50`, light `#6598bd`, dark `#111d2b`, glow `#75eaff` (electric cyan), metal `#b7d8e8`, skin `#c4dce8`.
- Silhouette: segmented storm pauldrons, peaked crown/crest row across the hood, charged crescent blade with cyan arc trail (the 2D rig draws an animated arc around the blade — the 3D model should carry a crescent blade on `weapon` with an emissive edge).
- Model target: `tools/blender/generate_storm_reaper.py` → `assets/generated/storm_reaper.glb`. Clone the Shadow Hunter generator; change materials to the palette above, replace dagger with crescent blade, add pauldron crest. Same 10 clips.
- Registry: add `"storm_reaper"` to `CHARACTER_MODELS` in `glb_character_preview.gd`, create `scenes/characters/storm_reaper_visual.tscn` mounted from `PlayerController.AUTHORED_CHARACTER_SCENES` (path already wired: `res://scenes/characters/storm_reaper_visual.tscn` — the scene file must extend `CharacterRigVisual` with `character_id = "storm_reaper"`).

## soul_binder — Soul Binder, the Spirit Weaver — SPEC ONLY

- Unlock: 80 shades, floor 3. Stats: 140 HP / 210 spd / 15 atk / 8% crit / 1.6 rate. Attack: `soul_missiles`. Pet damage ×1.4 + lifesteal.
- Palette: main `#25483f`, light `#63a88b`, dark `#142923`, glow `#8dffd0` (spirit green), metal `#c3ead7`, skin `#e1d9c6`.
- Silhouette: robed weaver, antler-like crown, rune chains, floating focus orb (the 2D rig animates an orbiting diamond orb — model it as a separate emissive mesh parented to `spine`, animating orbit via clips or left to VFX).
- Model target: `tools/blender/generate_soul_binder.py` → `assets/generated/soul_binder.glb`. Same 10 clips.
- Registry: same three-step wiring as storm_reaper with `soul_binder` ids.

## frost_valkyrie — known gap, do not ship a model yet

`frost_valkyrie` exists in save data and UI art (`card_body_frost_valkyrie.png`)
but has **no entry in `character_database.gd`** — requesting it silently returns
Shadow Hunter. Decide first whether the hero becomes real; if yes, add the
database entry and a `CharacterRigVisual.PALETTES` entry (ice-blue palette to match
existing card art) before generating any GLB.
