# Phase 18 — Authored Character Animation Fallbacks

## Goal

Keep the authored Skeleton2D character visible when an early or partial animation package contains the required core clips but does not yet contain every optional action. This avoids a visual pop back to the legacy flattened Sprite2D during combo stages, skills, hurt reactions, dodges, defeat, or victory.

## Changes

- Added a shared authored-clip lookup that checks the requested eight-direction clip first, then its base clip.
- Added safe fallback mappings for optional actions:
  - `attack_2` and `attack_3` use `attack_1`.
  - `skill`, `hurt`, `defeat`, and `victory` use `idle`.
  - `dodge` uses `run`.
- Character-specific clip-name overrides continue to work for both requested and fallback clips.
- `get_authored_clip_duration()` now returns the duration of the resolved fallback clip. Existing attack, skill, hurt, and dodge presentation locks therefore stay aligned with the animation that actually plays.
- The legacy Sprite2D remains the fallback only when there is no usable authored rig/core clip; a missing optional action no longer hides an otherwise valid rig.
- Added regression coverage to the core test runner for missing optional combo, skill, hurt, and dodge clips.

## Compatibility

- No player movement, single-joystick input, stationary nearest-enemy auto-attack, damage, combo progression, skill effects, dodge movement, collision, inventory, save data, or tower progression rules were changed.
- The rig contract still requires `idle`, `run`, and `attack_1`.
- This phase does not create production character artwork or a generated Shadow Hunter scene. The 21 layered transparent PNG source files and final manifest are still required before the authored rig can be generated and visually approved.

## Validation

- Reviewed the GDScript changes and test setup against the existing Godot 4.3 project structure.
- Added automated assertions to `tests/test_runner.gd`; they have **not** been executed in Godot in this work session.
- Godot editor/headless import, animation playback, visual review, and Android GL Compatibility testing remain required.
