# Phase 12 — Enemy and Boss Action Animation Coverage

## Purpose
Ensure authored attack animations are requested consistently for every existing enemy and boss attack pattern, rather than only selected telegraphs.

## Changes
- Enemy close-range lunge attacks now request the authored `attack` clip.
- Lord Malakar's void eruption, abyssal charge, nova ring, and abyssal cross patterns all request the authored `attack` clip when their attack sequence begins.
- Existing telegraphs, hit feedback, one-shot state priority, and legacy Sprite2D fallback remain in place.
- The existing Phase 08 manifest contract already defines the generic `attack` clip, so no new art naming requirement is introduced.

## Gameplay compatibility
This phase changes presentation requests only. It does not change attack timing, cooldowns, damage, projectile counts, movement, hitboxes, collision, AI, rewards, progression, save data, or player controls.

## Validation status
Source-reviewed against the existing controller methods and manifest clip names. Godot editor/headless execution and Android device testing were not available in this environment. Production spritesheets are still required to validate the authored animations visually in-game.
