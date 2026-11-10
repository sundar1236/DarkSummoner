# Phase 02 — Code Foundation Progress

## Status

The first safe code-foundation change is committed. Production character artwork and authored animation clips are still pending.

## Implemented

- Added a dedicated `CharacterVisualRoot` Node2D under the existing PlayerController CharacterBody2D.
- Moved the player presentation nodes into that visual container: ground shadow, ground indicator, character Sprite2D, weapon socket and weapon sprite, CharacterAnimationController, aim indicator, and character-specific ambient effects.
- Kept the CollisionShape2D, movement, targeting, attack logic, health bar, combo label, pet container, and gameplay state on the existing player root.
- Added an AnimationPlayer adapter to CharacterAnimationController. It checks for authored clips and falls back to the existing procedural animation when a clip is absent.
- Added optional eight-direction clip resolution. The adapter checks names such as `run_n`, `run_ne`, `run_e` ... `run_nw`, then falls back to the base clip such as `run`.
- Directional locomotion clips now reselect when the player changes facing direction. One-shot actions capture their facing at trigger time so an attack does not switch direction halfway through its swing.
- Added a dedicated `AuthoredRigRoot` with its `AnimationPlayer` as a child. This gives future Skeleton2D/Bone2D or layered sprite scenes a clean animation root.
- Added `PlayerController.install_authored_visual(PackedScene, clip_names)`: it validates a Node2D scene root and a descendant AnimationPlayer, attaches the rig under `CharacterVisualRoot`, configures the AnimationPlayer root path, and safely retains the legacy sprite if the supplied scene is invalid.
- Authored attack combo and skill clips are explicitly restarted when retriggered, including repeated uses of the same clip name.
- The authored rig stays hidden until a valid clip is found; the legacy Sprite2D stays visible as fallback. When a valid authored clip is available, the legacy sprite is hidden to avoid drawing two characters over each other.
- Hurt flash, dodge fade, and defeat fade now target whichever visual representation is active, rather than accidentally modifying only the hidden fallback sprite.
- Kept the existing procedural animation as fallback. No replacement art or fake skeletal rig was introduced.

## Why this change

The CharacterBody2D remains the authoritative gameplay and physics object. The visual subtree can now be replaced or expanded with a Skeleton2D/Bone2D rig, AnimationPlayer, layered character parts, and animation-specific VFX without moving collision or changing combat ownership.

## Validation

- Source-level changes committed to `visual-overhaul/phase-02-code-foundation`.
- Direction changes, one-shot facing capture, authored rig installation checks, authored clip restart behavior, rig visibility, legacy sprite fallback, and hit/dodge/defeat feedback routing were reviewed in source. Godot editor/headless tests have not been run in this environment.
- The project should be opened in Godot 4.3 and checked for scene startup, player movement, collision, weapon/projectile origin, animation state changes, dodge, and character switching before merging.
- Existing procedural animation remains enabled until production animation assets are integrated.

## Remaining Phase 02 work

1. Supply or create production-ready Shadow Hunter layered artwork or a genuine sprite sheet.
2. Build the authored rig/animation scene, call `PlayerController.install_authored_visual()` with its PackedScene, and add clips using the adapter naming convention: `idle`, `run`, `attack_1`, `attack_2`, `attack_3`, `skill`, `hurt`, `dodge`, `defeat`, `victory`; optional directional variants append `_n`, `_ne`, `_e`, `_se`, `_s`, `_sw`, `_w`, or `_nw`.
3. Verify all movement directions, attack combo stages, skill, hurt, dodge, defeat, and victory.
4. Repeat validation on Android using the GL Compatibility renderer.
