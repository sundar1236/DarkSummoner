# DarkSummoner 3D Asset Production Pipeline

Working manual for producing, integrating, and validating 3D (GLB) and layered 2D
art for DarkSummoner. Read this before generating or dropping in any new asset.

## Contents

| Document | Purpose |
| --- | --- |
| `glb-integration-workflow.md` | End-to-end flow: generate/import/integrate/validate a character GLB |
| `character-model-spec.md` | Hard technical contract every character GLB must satisfy |
| `characters/*.md` | Per-hero production specs (scale, palette, animation clip list) |
| `enemies-bosses/*.md` | Enemy categories and the five floor-boss specs |
| `environments/*.md` | Per-floor arena environment specs (palette, layers, boss arena) |
| `android-performance-budget.md` | Mobile rendering/memory budgets and rules |
| `ASSET_VALIDATION_REPORT.md` | Current validation status of every tracked asset category |

## The single most important rule

**An asset that imports is not an asset that works.** Integration only counts when
the runtime validators pass (see `tools/validate_asset_pipeline.gd`) and, for the
player hero, when `tools/ci/validate_character_render.gd` proves the model is
actually visible on camera with all clips playable. Everything else is a fallback,
not a feature.

## How the existing fallback chain works (do not break this)

The game has a deliberate degradation ladder, and every new asset plugs into it:

1. **Validated GLB / authored rig** — contract-checked at runtime
   (`CharacterVisualContract.validate`). Any failure logs a warning and drops down.
2. **Authored 2D procedural rig** (`character_rig_visual.gd`) — hand-drawn vector
   chibi per hero with full animation clip set.
3. **Legacy sprite** — `assets/sprites/characters/player_<id>.png` with procedural
   squash/bob animation.

Enemies and bosses use a parallel ladder: manifest spritesheet
(`assets/art/enemies/source/manifest.json`) → tinted legacy sprite. Floors use
`assets/art/environments/floors/manifest.json` → fully procedural `_draw` arena.

All manifests currently exist only as `*.example.json`. Activating one is a
matter of copying it to `manifest.json` and filling in real PNGs — the runtime
code already validates and degrades safely.
