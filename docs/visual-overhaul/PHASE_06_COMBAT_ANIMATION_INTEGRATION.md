# Phase 06 — Combat Animation and Rig Socket Integration

## Goal

Connect the optional authored character rig to the existing combat presentation without changing gameplay rules. The rig remains an optional visual replacement; the current Sprite2D/procedural presentation remains the fallback.

## Changes

### Authored animation timing

- Added a shared clip resolver that prefers an eight-direction clip (for example, `attack_1_se`) and falls back to the base clip.
- Added `get_authored_clip_duration()` so gameplay presentation locks can respect the selected clip's actual duration.
- Attack recovery now waits for the selected combo clip rather than always ending after the fixed 0.20-second prototype timer.
- Skill, hurt, and dodge presentation locks now respect the authored clip duration, with their previous minimum durations retained.
- Missing clips still resolve to the existing procedural fallback and do not block combat.

### Weapon socket integration

- The active authored rig's `WeaponSocket` is aimed using the same target direction as the existing combat controller.
- Basic projectile muzzle position and slash VFX origin now use the authored `WeaponSocket` when a valid authored rig is active.
- If the authored rig or socket is unavailable, the existing `Marker2D` weapon socket and player origin remain the fallback.
- Extra spread projectiles share the same muzzle origin as the primary projectile.

## Gameplay compatibility

This phase does not change:

- Single movement joystick input.
- Stationary nearest-enemy auto-targeting and auto-attacks.
- Movement suppressing basic attacks.
- Attack rate, combo damage multiplier, critical chance, projectile speed, spread damage, status effects, or projectile limits.
- Dodge movement/invulnerability, skill effects, enemy damage, collisions, save data, inventory, or progression.

## Validation checklist

After the layered PNG package is supplied and the generated scene is installed in Godot:

1. Run the Phase 04 source-art validator.
2. Generate the rig using the Phase 05 builder.
3. Open the project in Godot and confirm the rig has no missing animation track paths.
4. Test all eight aim directions and verify the weapon socket follows the target.
5. Test all three combo stages and confirm each clip completes before returning to idle.
6. Test skill, hurt, and dodge clips for complete playback and correct interruption priority.
7. Confirm slash VFX and primary/spread projectile origins follow the authored socket.
8. Remove/disable the authored rig and confirm the legacy sprite and Marker2D fallback still work.
9. Test Android using the project's GL Compatibility renderer and reduced-motion setting.

## Limitations

- The repository still does not contain the 21 approved separated Shadow Hunter PNG layers or the production manifest. The Phase 05 builder therefore cannot yet generate the final authored scene.
- This phase adds runtime integration only; it does not fabricate character art or replace the current fallback visuals.
- Godot editor/headless execution and Android device testing were not available in this work session. The changes have been reviewed against the current GDScript source but are not claimed as runtime-tested.
