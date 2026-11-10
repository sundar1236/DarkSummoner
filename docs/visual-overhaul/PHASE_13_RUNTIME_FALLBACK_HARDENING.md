# Phase 13 — Authored Animation Runtime Fallback Hardening

## Purpose
Prevent incomplete or malformed enemy/boss animation packages from being accepted by the runtime and hiding the existing working sprite visuals.

## Changes
- Runtime loader now requires the complete controller contract: `idle`, `move`, `attack`, `hurt`, and `defeat`.
- Rejects invalid frame dimensions, non-positive FPS, duplicate/empty clip names, missing loop declarations, empty frame lists, and out-of-range frame indices.
- Rejects sheets without an alpha channel or with dimensions that do not match the declared grid.
- Builds and attaches the AnimatedSprite2D only after the entire package passes validation, allowing controllers to retain the legacy Sprite2D fallback on failure.

## Compatibility
No changes to enemy/boss AI, combat timing, damage, movement, collision, drops, rewards, progression, save data, or player controls. Valid existing art packages using the Phase 08 manifest contract remain supported.

## Validation status
The example manifest was checked for the required five clips and in-range frame indices across all declared actors. Godot editor/headless execution and Android device testing were not run. Production spritesheets are still needed for visual runtime validation.
