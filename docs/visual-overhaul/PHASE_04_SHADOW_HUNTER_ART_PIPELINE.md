# Phase 04 — Shadow Hunter Source-Art Pipeline

## Goal

Prepare a verifiable, production-oriented source-art package for the Shadow Hunter before any Skeleton2D rig is authored. This phase defines and validates the layered artwork contract; it does not pretend a flattened promotional render is rig-ready.

## Character art direction

- 2.5D stylized chibi, Archero-like readability and finish, original design.
- Hooded shadow assassin with white/silver hair, dark layered leather and cloth, restrained gold trim, and violet-energy dual daggers.
- Three-quarter angled top-down combat view. Keep the face, torso, boots, and weapon silhouettes readable at the 720x1280 portrait game's combat scale.
- Consistent light direction, material response, camera, character scale, and ground anchor across every layer.
- Transparent background; no UI, scenery, baked ground shadow, text, or weapon trails.

## Source package layout

Place the approved source package here:

`assets/art/characters/shadow_hunter/source/`

Each body part is a separate transparent PNG. All layers share one canvas size and coordinate system. The example manifest is `manifest.example.json`; copy it to `manifest.json` and update file names and pivots when source art is delivered.

Required layer identifiers:

- `back_cape`
- `rear_leg_upper`, `rear_leg_lower`, `rear_boot`
- `front_leg_upper`, `front_leg_lower`, `front_boot`
- `pelvis_torso`
- `rear_arm_upper`, `rear_arm_lower`, `rear_hand`
- `front_arm_upper`, `front_arm_lower`, `front_hand`
- `head_face`
- `hood_back`, `hood_front`
- `hair_back`, `hair_front`
- `left_dagger`, `right_dagger`

Layers must overlap beyond joints so rotations do not expose transparent gaps. Keep cape and hood depth layers separate. Hands and daggers must be independent. Do not bake a weapon into the hand or torso.

## Pivot and canvas rules

- Every PNG has identical width and height, with transparent pixels outside its painted part.
- The canvas origin and character ground anchor are shared by every layer.
- Each manifest pivot is expressed in pixels from the top-left of that shared canvas.
- Joint pivots must be aligned by the artist, not guessed later in the rig.
- Keep the character centered with enough transparent margin for cape and weapon motion.
- Export PNG RGBA at source resolution; do not downscale to the current 128x128 prototype.

## Validation tool

Run from the Godot project root:

```sh
godot --headless --script tools/validate_character_art_source.gd -- --manifest=res://assets/art/characters/shadow_hunter/source/manifest.json
```

The validator checks JSON structure, required layer names, unique names, image readability, shared canvas dimensions, alpha channels, and in-canvas pivots. It returns exit code 0 only when the package passes. This is a source-package check, not a substitute for visual review.

## Rig handoff (Phase 05)

Once the approved layered source package exists:

1. Build a reusable `ShadowHunterVisual.tscn` with Skeleton2D and Bone2D hierarchy.
2. Bind each body-part Sprite2D to the appropriate bone and set pivots from the manifest.
3. Add `WeaponSocket`, `LeftWeaponSocket`, and `RightWeaponSocket` as Node2D attachment points.
4. Author idle, eight-direction locomotion, three-stage attack, skill, dodge, hurt, defeat, and victory clips.
5. Validate the resulting scene with `CharacterVisualContract` and retain the legacy Sprite2D fallback until desktop and Android checks pass.

## Scope and status

- Added a manifest example and a headless source-art validator.
- No replacement character PNGs are included yet. The current repository does not contain the required separated Shadow Hunter source layers, and deriving fake limbs from the flattened prototype would produce poor cutout animation.
- No gameplay, collision, attack timing, damage, save data, or progression code is changed in this phase.
- Godot runtime execution is not available in this work session; the validator has not been run here.
