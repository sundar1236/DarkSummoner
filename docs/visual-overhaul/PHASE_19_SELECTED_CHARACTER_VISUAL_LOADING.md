# Phase 19 — Selected Character Visual Scene Loading

## Goal

Connect the generated character rig scenes to the existing player controller so a selected hero automatically uses its authored visual when that scene is present. Keep the CharacterBody2D, collision, movement, targeting, attacks, and save systems independent from the replaceable art scene.

## Scene mapping

The player controller now checks these optional paths:

| Character ID | Scene path |
|---|---|
| `shadow_hunter` | `res://scenes/characters/shadow_hunter_visual.tscn` |
| `storm_reaper` | `res://scenes/characters/storm_reaper_visual.tscn` |
| `soul_binder` | `res://scenes/characters/soul_binder_visual.tscn` |

When the selected character's scene exists, it is loaded as a PackedScene and passed through the existing `install_authored_visual()` validation path. The selected character ID is recorded only after successful installation, preventing unnecessary repeated scene loads during stat refreshes.

## Safe fallback

- Missing optional scene: keep the existing character Sprite2D and animation fallback.
- Failed resource load: warn and keep the existing visual.
- Invalid rig or missing required core clips: the existing visual remains active because installation validation rejects the rig.
- CharacterBody2D, collision shape, health bar, pet container, weapon/projectile gameplay, and player input are not moved into the art scene.

## Production art status

This is runtime wiring, not a claim that final art is present. The generated Shadow Hunter scene still depends on the 21 approved transparent source layers and manifest. Storm Reaper and Soul Binder scenes must be produced separately using the approved rig contract before their paths can load anything.

## Validation

- Added regression assertions for the three character-to-scene mappings and unknown character handling.
- Source-reviewed the loader against the existing player setup and rig validation API.
- The Godot headless suite, resource import, scene instantiation, in-game character selection, animation playback, and Android testing have **not** been run in this work session.
