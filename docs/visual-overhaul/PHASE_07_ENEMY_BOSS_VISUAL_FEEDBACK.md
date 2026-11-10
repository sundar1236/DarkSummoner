# Phase 07 — Enemy and Boss Visual Feedback

## Goal

Make enemy and boss combat feedback more consistent and readable while keeping every gameplay and physics decision on the existing CharacterBody2D controllers.

## Changes

### Shared visual feedback helper

Added `scripts/combat/combat_sprite_feedback.gd` with reusable presentation-only helpers:

- `play_hit()`: brief bright hit flash, directional recoil lean, and squash recovery.
- `play_telegraph()`: anticipation lean and squash/stretch pulse before an attack.
- `play_death()`: configurable defeat pop and dissolve.
- New feedback tweens replace the previous feedback tween on the same visual wrapper, preventing overlapping hit/telegraph/death tweens from fighting over transforms.

### Enemy and mini-boss integration

- Added a `VisualRoot` Node2D wrapper around the enemy Sprite2D.
- Swarm, cultist, charger, elite, and mini-boss movement/AI remain in the existing controller.
- Cultist cast, charger windup, and mini-boss slam now animate the visual wrapper.
- Hit reactions recoil away from the player when a player reference is available.
- Enemy defeat dissolve runs on the visual wrapper; reward drops, mission progress, signals, and queue-free timing remain unchanged.

### Lord Malakar integration

- Added the same visual wrapper to the floor boss.
- Charge and cross attack windups use the shared anticipation animation.
- Boss hit reactions use the shared feedback while preserving the enrage tint on the boss sprite.
- Boss defeat keeps its larger pop before dissolving.

## Gameplay and compatibility

This phase does not change:

- Enemy/boss movement speeds, AI decisions, attack cooldowns, telegraph durations, attack patterns, damage, projectile counts, or collision shapes.
- Boss enrage threshold, phase behaviour, rewards, mission/achievement progress, or level completion.
- Player controls, combat targeting, player damage, save data, inventory, or progression.

The wrapper is a visual-only Node2D child. CharacterBody2D remains the physics and gameplay root; collision shapes and health bars are not reparented into the animated wrapper.

## Validation checklist

1. Run the existing core gameplay and Summoning Circle Godot test scenes.
2. Spawn each enemy type and verify its sprite stays aligned with its ground shadow and collision body.
3. Confirm hit reactions recover correctly after repeated hits and while a telegraph is active.
4. Confirm cultist, charger, and mini-boss warning cues complete before their existing attack actions.
5. Confirm Lord Malakar's four attack patterns, enrage tint, and defeat reward flow are unchanged.
6. Test with reduced-motion settings and on Android using GL Compatibility.

## Limitations

- The existing flattened enemy and boss PNG assets remain unchanged; this phase improves motion/feedback around those assets and does not create new character artwork or frame-based sprite sheets.
- Godot editor/headless execution and Android device testing were not available in this work session. Changes were reviewed against source; runtime tests are not claimed.
