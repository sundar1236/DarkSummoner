# Phase 02 — Code Foundation Progress

## Status

The first safe code-foundation change is committed. Production character artwork and authored animation clips are still pending.

## Implemented

- Added a dedicated `CharacterVisualRoot` Node2D under the existing PlayerController CharacterBody2D.
- Moved the player presentation nodes into that visual container: ground shadow, ground indicator, character Sprite2D, weapon socket and weapon sprite, CharacterAnimationController, aim indicator, and character-specific ambient effects.
- Kept the CollisionShape2D, movement, targeting, attack logic, health bar, combo label, pet container, and gameplay state on the existing player root.
- Added an AnimationPlayer adapter to CharacterAnimationController. It checks for authored clips and falls back to the existing procedural animation when a clip is absent.
- Added optional eight-direction clip resolution. The adapter checks names such as `run_n`, `run_ne`, `run_e` ... `run_nw`, then falls back to the base clip such as `run`.
- Attached an empty AuthoredAnimationPlayer beneath CharacterVisualRoot so future rig animations can be added without changing gameplay state ownership.
- Kept the existing Sprite2D and procedural animation as the active fallback. No replacement art or fake skeletal rig was introduced.

## Why this change

The CharacterBody2D remains the authoritative gameplay and physics object. The visual subtree can now be replaced or expanded with a Skeleton2D/Bone2D rig, AnimationPlayer, layered character parts, and animation-specific VFX without moving collision or changing combat ownership.

## Validation

- Source-level change committed to `visual-overhaul/phase-02-code-foundation`.
- Godot editor/headless tests have not been run in this environment.
- The project should be opened in Godot 4.3 and checked for scene startup, player movement, collision, weapon/projectile origin, animation state changes, dodge, and character switching before merging.
- Existing procedural animation remains enabled until production animation assets are integrated.

## Remaining Phase 02 work

1. Supply or create production-ready Shadow Hunter layered artwork or a genuine sprite sheet.
2. Build the authored rig/animation scene and add clips using the adapter naming convention: `idle`, `run`, `attack_1`, `attack_2`, `attack_3`, `skill`, `hurt`, `dodge`, `defeat`, `victory`; optional directional variants append `_n`, `_ne`, `_e`, `_se`, `_s`, `_sw`, `_w`, or `_nw`.
3. Verify all movement directions, attack combo stages, skill, hurt, dodge, defeat, and victory.
4. Repeat validation on Android using the GL Compatibility renderer.
