# Phase 08 — Enemy and Boss Animation-Ready Art Pipeline

## Goal

Prepare the enemy roster and Lord Malakar for original frame-based 2D animation. Phase 07 improved presentation around the existing flattened sprites; this phase defines and validates the actual artwork handoff without fabricating production art or changing combat.

## What is included

- `tools/validate_enemy_boss_art_source.gd` validates a JSON source manifest and each referenced PNG spritesheet.
- `assets/art/enemies/source/manifest.example.json` records the expected art package for the current enemy roster and floor boss.
- The manifest contract defines frame dimensions, sheet grid, animation frame indices, FPS, and looping behaviour.
- Required baseline clips are `idle`, `move`, `attack`, `hurt`, and `defeat`. Lord Malakar additionally has `telegraph` and `enrage` examples.
- Validation checks unique actor/clip IDs, valid roles, readable alpha PNGs, exact sheet dimensions, positive frame rates, in-range frame indices, explicit loop flags, and required clips.

## Artwork handoff

Supply one transparent PNG spritesheet per actor. Keep every frame on the declared fixed-size cell grid, with consistent ground contact, camera angle, scale, lighting direction, and silhouette. Do not bake shadows, health bars, warning decals, hit flashes, or floor backgrounds into the character sheet; those remain runtime layers/effects.

Recommended art direction:
- **Swarmer:** small fast melee creature; readable silhouette at mobile scale.
- **Cultist:** hooded ranged caster; staff/hand casting pose must read clearly.
- **Charger:** low forward-leaning beast with a distinct wind-up and charge silhouette.
- **Elite Brute:** heavy armored enemy with strong mass and deliberate attack poses.
- **Abyssal Champion:** mini-boss silhouette, clearly larger and more ornate than regular enemies.
- **Lord Malakar:** imposing multi-phase floor boss with distinct telegraph and enrage poses.

Use original designs. The dimensions in the example are starting targets, not an instruction to stretch existing art. If an artist needs a different grid, update the manifest to match the delivered source rather than resizing artwork destructively.

## Validate

From the Godot project root:

```sh
godot --headless --script tools/validate_enemy_boss_art_source.gd -- --manifest=res://assets/art/enemies/source/manifest.json
```

Copy the example manifest and update its source paths only after the PNG files are delivered. The example intentionally references not-yet-delivered artwork and is not expected to pass as-is.

## Compatibility

This phase adds an offline art-package validator and documentation only. It does not modify enemy/boss controllers, attack timing, AI, movement, collision, damage, rewards, save data, or scene wiring. Phase 07's VisualRoot feedback remains compatible with a future AnimatedSprite2D or AnimationPlayer-based visual replacement.

## Validation status and limitations

- Source was reviewed for manifest/validator consistency.
- Godot headless/editor execution and Android device testing were not available in this work session; runtime tests are not claimed.
- Production enemy/boss spritesheets have not been added. The next artwork task is to create the original sheets and a production manifest, then integrate them behind the existing visual wrappers.
