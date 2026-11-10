# Phase 11 — Authored Animation State Priority

## Purpose
Keep non-looping enemy and boss action clips visible for their authored duration instead of immediately replacing them with idle/move clips on the next physics update.

## Changes
- Added animator queries for clip availability and active non-looping playback.
- Enemy and boss controllers track the currently locked authored clip.
- Locomotion animation resumes after the active one-shot clip finishes.
- The requested death clip falls back to the manifest's `defeat` clip when `death` is not present.
- Missing clips remain no-ops, preserving the current Sprite2D fallback.

## Compatibility
This is presentation-state handling only. It does not alter combat timing, AI, damage, movement, hitboxes, cooldowns, rewards, progression, saves, or player controls. The existing manifest example uses `attack`, `hurt`, and `defeat` names; this phase aligns controller requests with that naming contract.

## Validation status
Source-reviewed against the Phase 08 manifest example and Phase 09 animation helper. Godot editor/headless execution and Android testing were not available. Production spritesheets remain a prerequisite for visual runtime validation.
