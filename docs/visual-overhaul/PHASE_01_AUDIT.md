# Dark Summoner Visual Overhaul — Phase 01 Audit

Date: 2026-11-10
Repository: https://github.com/sundar1236/DarkSummoner
Base branch: main
Working branch: visual-overhaul/phase-01-audit

## Scope and evidence

This is a source-level audit of the repository files inspected for the approved 2.5D visual overhaul. It is not a claim that the game was launched or tested in the Godot editor. The GitHub connector provides source-file access, but does not provide a Godot runtime, imported texture previews, Android device testing, or a complete binary asset inspection in this workflow.

Inspected:
- project.godot
- scripts/combat/player_controller.gd
- scripts/combat/character_animation_controller.gd
- scripts/combat/enemy_controller.gd
- scripts/combat/boss_controller.gd
- scripts/combat/combat_manager.gd
- tests/test_runner.gd
- tests/test_summoning_circle.gd
- README.md

## Confirmed project constraints

- Godot 4.3 project.
- Portrait reference viewport: 720 x 1280.
- GL Compatibility renderer is configured for desktop and mobile.
- Main player is a CharacterBody2D.
- Existing single-joystick movement and stationary nearest-enemy auto-attack are implemented in player_controller.gd.
- Existing gameplay systems include player/enemy/boss controllers, combat manager, projectile controller, pet controller, combat HUD, GameManager, SaveManager and AudioManager.
- Existing tests cover combat and Summoning Circle functionality. README documents 150 assertions, but this audit did not execute them.

## Key finding: animation is currently procedural sprite motion, not skeletal animation

The current CharacterAnimationController:
- Holds a Sprite2D reference, weapon Marker2D and optional weapon Sprite2D.
- Implements idle/run/attack/skill/hurt/dodge/defeat/victory states.
- Applies bobbing, squash/stretch, rotation and offsets directly to the single Sprite2D.
- Uses tweens for weapon movement, tint and dodge alpha.

The player controller creates a Sprite2D and loads one character texture per hero. The current source does not demonstrate a Skeleton2D/Bone2D rig, skinned mesh, AnimationPlayer clip library, or AnimationTree-driven skeletal blend. Therefore the current implementation must not be described as a completed skeletal animation pipeline. It is a useful procedural animation prototype and state controller foundation, but it does not meet the approved final visual target.

The enemy controller similarly creates a Sprite2D per enemy type and applies procedural movement/visual effects. The boss controller uses a Sprite2D with floating/bobbing, scaling and tint effects. These are not substitutes for authored locomotion and attack animation.

## Preserve these working systems

Do not replace or rewrite:
- CharacterBody2D movement and collision.
- Single virtual joystick.
- Stationary nearest-enemy targeting and auto-attacking.
- Attack cooldown and damage calculations.
- Dodge/invulnerability and active skill gameplay.
- Enemy AI, waves and boss encounter flow.
- Projectile and pet systems.
- GameManager and SaveManager state.
- Character identities, character progression and save compatibility.
- Existing inventory, Summoning Circle, rewards, shops and tests.

Animation must remain presentation-only. Damage, cooldowns, targeting, collision and progression remain owned by gameplay systems.

## Main visual gaps

1. Player artwork is presented through one Sprite2D texture per hero; a true rig/animation asset pipeline is not evidenced by the inspected controller.
2. Existing animation states rely heavily on transform changes to a single image.
3. Enemy locomotion and attacks need authored animation states and readable anticipation/recovery.
4. Boss presentation has procedural bobbing and tween effects, but no demonstrated authored multi-state boss animation pipeline.
5. Arena depth, perspective and lighting need a scene-level visual review before changing rendering or background architecture.
6. The actual PNG/texture contents, dimensions, transparency, frame layouts and art consistency have not yet been verified in this source-only audit.

## Recommended technical direction

Use a reusable visual-character scene while preserving the existing gameplay controllers.

Candidate presentation hierarchy (adapt to actual imported assets; do not blindly replace current nodes):

- CharacterBody2D (existing gameplay root)
  - GroundShadow (Sprite2D or generated soft shadow)
  - GroundEffects (Node2D)
  - CharacterVisualRoot (Node2D)
    - RigRoot (Skeleton2D/Bone2D with Polygon2D skin, if suitable layered art is available)
    - or AnimatedSprite2D (if production sprite sheets are supplied)
    - WeaponSocket (Marker2D)
    - CharacterVFX (Node2D/GPUParticles2D)
  - CollisionShape2D (existing gameplay collision)
  - Existing health/feedback UI nodes

Use AnimationPlayer for authored clips and AnimationTree only where blending/state transitions justify it. Do not introduce both systems redundantly. A sprite-sheet fallback is acceptable when layered artwork is unavailable, but a single static PNG with bob/scale/rotation is not production animation.

GL Compatibility is currently configured. Prefer compatible CanvasItem shaders, particles and 2D lighting; profile effects on target Android hardware before adding expensive glow or viewport effects.

## Phase 02 entry criteria

Before implementing a rig:
1. Inspect actual player character image files and their dimensions.
2. Determine whether each character is a single flattened image, a sprite sheet, or layered artwork.
3. If flattened, create/obtain separate body, head, arm, leg, hair/cloth and weapon layers with consistent pivots and transparent backgrounds.
4. Approve one Shadow Hunter rig and animation set before applying the pipeline to Storm Reaper and Soul Binder.
5. Keep the current Sprite2D controller as a temporary compatibility fallback until the new visual scene is validated.

Required Shadow Hunter clips:
- idle
- locomotion (prefer 8-direction support; use mirrored or directional variants only if art quality supports it)
- attack anticipation / active / recovery
- dodge
- hurt
- death
- victory
- character skill

## Validation still required

This source audit did not run Godot. Before merging implementation changes:
- Run the existing core test scene.
- Run the Summoning Circle test scene.
- Open the main scene and combat scene in Godot 4.3.
- Verify no missing resources or animation paths.
- Verify the one-stick movement/auto-attack behavior.
- Test on an Android device for frame pacing, touch behavior and memory use.

## Phase 01 status

- Source architecture review: completed for the files listed above.
- Existing gameplay preservation map: documented.
- Animation gap identified: confirmed.
- Actual texture-by-texture art audit: pending.
- Godot runtime/headless validation: pending.
- New animation system implementation: intentionally deferred until actual art assets are inspected.

This branch contains the audit only. No existing gameplay code or assets have been modified.
