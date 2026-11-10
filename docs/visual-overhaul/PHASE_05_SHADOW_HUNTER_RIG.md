# Phase 05 — Shadow Hunter Rig Generation

## Goal

Turn the approved layered source-art manifest into a reusable Node2D/Skeleton2D cutout rig with named weapon sockets and AnimationPlayer clips. The rig is built from actual separated PNG layers; it does not slice, infer, or fabricate limbs from a flattened image.

## Generator

`tools/build_shadow_hunter_rig.gd` builds:

- `ShadowHunterVisual` Node2D root, safe to install below the existing CharacterVisualRoot.
- `Skeleton2D` with a Root bone and a parented body/limb/head/cape hierarchy.
- One Sprite2D per manifest layer, using the layer pivot and shared ground anchor.
- `WeaponSocket`, `LeftWeaponSocket`, and `RightWeaponSocket` attachment nodes.
- AnimationPlayer clips: idle, run, attack_1, attack_2, attack_3, skill, hurt, dodge, defeat, victory.

The generated clips are initial motion blocking, not final animator polish. Review and refine joint arcs, overlap, timing, and silhouette in Godot after source artwork is supplied.

## Run

First place the approved source images and manifest in `assets/art/characters/shadow_hunter/source/`, then run:

```sh
godot --headless --script tools/validate_character_art_source.gd -- --manifest=res://assets/art/characters/shadow_hunter/source/manifest.json
godot --headless --script tools/build_shadow_hunter_rig.gd -- --manifest=res://assets/art/characters/shadow_hunter/source/manifest.json --output=res://scenes/characters/shadow_hunter_visual.tscn
```

The builder refuses to run until the source manifest and all required PNGs pass validation. It writes a PackedScene that can be installed with:

```gdscript
var rig := load("res://scenes/characters/shadow_hunter_visual.tscn") as PackedScene
install_authored_visual(rig)
```

## Rig hierarchy

- Root is the ground-anchor reference.
- Body is the pelvis/torso parent.
- Upper/lower leg and arm bones form joint chains.
- Head owns hood and hair layers.
- Cape is behind the body.
- Daggers are parented to the corresponding hand chains.
- Each PNG remains a full shared-canvas texture. Its Sprite2D offset is derived from its manifest pivot, so every part aligns before animation.

## Integration and validation

- The generated root satisfies the Phase 03 Node2D + AnimationPlayer + core clip contract.
- Existing player physics, collision, targeting, combo timers, damage, dodge logic, save data, and progression are untouched.
- Keep the legacy Sprite2D visible until the generated rig has passed visual review and Android GL Compatibility testing.
- The source art is still not present in the repository. Consequently no generated scene is committed yet and no in-engine animation playback test is claimed.
- Godot headless generation has not been executed in this work session.
