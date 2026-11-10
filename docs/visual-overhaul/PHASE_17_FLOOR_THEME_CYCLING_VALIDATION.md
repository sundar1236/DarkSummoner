# Phase 17 — Floor Theme Cycling and Manifest Validation

## Goal
Ensure the five authored floor themes continue to be used throughout tower progression, and catch incomplete or ambiguous floor manifests before artwork is integrated.

## Runtime behavior
- The arena resolves the authored theme slot using the same five-theme cycle as the procedural theme selector.
- Floors 1–5 use their corresponding authored theme; floors 6–10 repeat themes 1–5, and the pattern continues.
- The runtime rejects unsupported manifest schema versions and keeps the procedural arena fallback.
- A missing theme package or any missing/invalid layer still falls back safely.

## Validator improvements
The floor art validator now checks:
- The manifest canvas declaration is 720 × 1280.
- Every floor has a non-empty display name.
- Each floor number is within 1–5 and appears only once.
- All five theme slots are represented.
- Existing unique floor IDs, required layer roles, image readability, image dimensions, and alpha-channel checks remain active.

## Artwork workflow
Keep one authored art package for each of the five themes in `assets/art/environments/floors/manifest.json`. The tower reuses these five themes as it progresses. Add new theme slots only as a deliberate future design change to both the theme selector and manifest contract.

## Compatibility
No changes to floor progression, enemy spawning, arena collision, movement, combat, rewards, save data, or HUD. Only environment presentation and asset validation are affected.

## Validation status
The example manifest was source-reviewed against the five theme slots and 720 × 1280 canvas declaration. Godot headless/editor execution, in-game verification across floors 1–10, and Android device testing were not run.
