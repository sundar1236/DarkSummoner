# Phase 09 — Enemy and Boss Animation Runtime

## Purpose
Provide a runtime path from the approved Phase 08 JSON manifest and original transparent spritesheets to Godot `AnimatedSprite2D` animation clips, while retaining the current sprite feedback and gameplay controllers.

## Implementation
- `scripts/combat/enemy_boss_sprite_animation.gd` parses a manifest at runtime, locates an actor by ID, slices its declared fixed-cell spritesheet with `AtlasTexture`, and builds a `SpriteFrames` resource in memory.
- The helper exposes safe `play()` and `is_ready_for_animation()` methods. Unknown clips are ignored; missing manifests/sheets return false, allowing the existing art to remain the fallback.
- This stage is a runtime integration utility, not a claim that production enemy/boss art has been delivered or activated.

## Example use
Create the helper as a child of a visual wrapper and call:
```gdscript
var animator := EnemyBossSpriteAnimation.new()
visual_root.add_child(animator)
var loaded := animator.setup_from_manifest(
  "res://assets/art/enemies/source/manifest.json",
  "swarmer"
)
if loaded:
  animator.play("move")
```

Use the manifest's actor IDs and the art pipeline validator before shipping. The current example manifest is not production content.

## Safety / compatibility
This utility does not change combat AI, timing, damage, hit boxes, movement, drops, saves, or scene structure. It is intentionally not wired to existing controllers yet: until actual sheets are provided, switching sprites at runtime would hide the current art without a meaningful animation replacement. The next integration step should connect controller state transitions after the art pack is validated.

## Validation status
Reviewed for API consistency with the Phase 08 manifest format. Godot execution and Android testing were not available; runtime tests are not claimed.
