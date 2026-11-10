# Phase 14 — Floor Environment Art Pipeline

## Goal
Prepare the five existing floor themes for original Canva-generated 2.5D environment artwork without replacing the current procedural arena or changing combat.

## Art delivery contract
Each floor is delivered as four aligned PNG layers, all exactly **720 × 1280**:

1. `background.png` — distant architecture, walls, atmosphere and depth; may be opaque.
2. `floor.png` — playable stone/ground surface, cracks, tile detail and central floor motifs; transparent outside the ground artwork.
3. `props.png` — pillars, braziers, statues, rubble and side structures; transparent background.
4. `foreground.png` — optional-looking but required transparent foreground framing elements such as near-camera rubble, chains or broken steps. Keep the central combat area clear.

All layers must use the same camera angle, perspective, scale, lighting direction and canvas alignment. Do not bake characters, enemies, UI, text, health bars, attack effects or collision boundaries into the environment art. Keep the central combat space visually quiet and readable; large props must stay outside the main movement lanes. The art should read as an angled top-down 2.5D action-RPG arena, not a side-scrolling platform or a first-person scene.

## Floor identities
- **Floor 1 — Abyssal Ruins:** ancient black-violet stone, broken circular altar markings, eroded pillars, restrained violet runes.
- **Floor 2 — Ember Catacombs:** volcanic basalt, lava seams kept away from combat lanes, iron braziers, warm orange light.
- **Floor 3 — Frostbound Crypt:** blue-grey ice stone, frozen arches, frost crystals around the perimeter, cyan magical accents.
- **Floor 4 — Blighted Sanctum:** corrupted mossy stone, dead roots, diseased green pools at the edges, sickly green runes.
- **Floor 5 — Crimson Throne:** dark red-black royal stone, fractured throne dais at the far end, crimson banners and restrained blood-red magic.

## Validator
Run from the project root:

```sh
godot --headless --script tools/validate_floor_environment_art.gd -- --manifest=res://assets/art/environments/floors/manifest.json
```

The validator checks the manifest schema, unique floor IDs, the four required layer roles, file readability, exact canvas dimensions and alpha support for transparent layers. The example manifest intentionally points to not-yet-delivered art and will fail until real PNG files are supplied.

## Integration and compatibility
This phase adds an asset handoff and validation contract only. The existing `ArenaBackground` procedural renderer remains the active fallback. No placeholder textures are generated, no environment assets are fabricated, and no floor progression, combat, collision, spawn positions, save data, or UI behavior is changed. A later integration phase can load approved artwork while preserving the procedural fallback.

## Validation status
Source-reviewed only. Godot headless/editor and Android device tests were not run. Production floor PNG layers have not yet been supplied.
