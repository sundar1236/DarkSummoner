# Phase 10 — Enemy and Boss Controller Animation Integration

## Goal
Connect the Phase 09 manifest-driven animator to enemy and boss presentation states without changing gameplay behavior. Existing sprites remain the fallback unless the production manifest and corresponding actor sheet can be loaded successfully.

## Changes
- Enemy controllers attempt to load their configured actor animation after the enemy type has been initialized.
- The boss controller attempts to load the `lord_malakar` actor.
- When a valid animation set is available, its AnimatedSprite2D becomes the visible character and the existing Sprite2D is hidden.
- Controllers request idle/move clips from current movement state and request attack, hurt, and death clips at the relevant presentation events.
- If the manifest, actor, sheet, or clips are unavailable, the existing Sprite2D and Phase 07 feedback continue to work.

## Compatibility boundaries
No changes are intended to AI decisions, movement, cooldowns, attack timings, damage, collision, drops, rewards, progression, saves, or player controls. Authored animations are optional presentation only. Clip names should align with the Phase 08 manifest; missing clip names are safely ignored by the Phase 09 animator.

## Content prerequisite
The example manifest references placeholder source sheets. The production art pack is still outstanding. This integration does not create finished enemy/boss art or activate animation until valid production files are supplied.

## Validation
Source-reviewed against the current Phase 08 manifest schema and Phase 09 animator API. Godot editor/headless execution and Android device testing were not available; runtime validation is not claimed.
