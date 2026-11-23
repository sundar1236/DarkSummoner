# Character Model Technical Specification

Hard contract for any GLB meant to appear in DarkSummoner as a player hero.
The runtime validates most of this automatically; items marked *(manual)* are
the producer's responsibility.

## Geometry

| Item | Requirement |
| --- | --- |
| Format | Binary glTF 2.0 (`.glb`), single file, textures embedded or none |
| Height | 2.2 chibi-proportioned heads tall; total height ≈ 2.3 world units at scale 1 |
| Origin | Feet on ground plane, XZ origin between feet, Y=0 at sole |
| Forward | Faces −Z after Godot import (Blender −Y export default achieves this) |
| Triangles | ≤ 8,000 tris per hero (mobile budget; see android-performance-budget.md) |
| Meshes | ≤ 20 draw-capable surfaces; named meaningfully (`Moonsteel_Dagger`, not `Cube.014`) |

## Skeleton

- Root armature named `<HeroName>_Skeleton`, object `<HeroName>_Rig`.
- Required bones (superset allowed): `root, pelvis, spine, head, arm.L, arm.R, leg.L, leg.R, weapon`.
- `weapon` bone is the attachment point for gameplay VFX and aim alignment.
- Single skeleton, ≤ 32 bones total (mobile skinning cost).

## Materials & textures

- Principled BSDF, named per surface (`Obsidian Armor`, `Aether Violet Glow`...).
- Emissive materials allowed for glow accents (eyes, gems, runes) — keep count ≤ 2.
- Textures: none required for the stylized flat-color look; if used, ≤ 1024×1024
  WebP/PNG, one atlas. *(manual)* Verify compression applies — see the note about
  `texture_loader.gd` in `android-performance-budget.md`.

## Animation clips

Required set (partial is acceptable for heroes — fallbacks map missing clips —
but every clip present must be real):

`idle` (loop), `run` (loop), `attack_1`, `attack_2`, `attack_3`, `skill`, `hurt`,
`dodge`, `defeat`, `victory`.

- Loop modes matter: only `idle` and `run` loop; one-shots must end on their final pose.
- Runtime retargeting: the wrapper `AnimationPlayer` in `character_rig_visual.gd`
  plays the same clip names and forwards them to the 3D model
  (`glb_character_visual._play_model_animation`). Names must match exactly.

## In-game mount points

The model is rendered inside a `SubViewport` (`GLBCharacterPreview`) with an
orthographic camera (`camera_orthographic_size` 3.1 default, size 3.1 world units
tall). Exported `model_scale` per hero tunes the fit; Shadow Hunter uses 0.82 in
combat and 1.0 in the hub. Ground anchor on screen: model feet should sit ≈ 62%
down the preview box (matches `hero_pedestal_view._update_preview_rect`).

## Collision

*(manual / N/A)* Gameplay collision is 2D (`CharacterBody2D`, layers documented in
the audit); the 3D model is presentation-only. Do not ship collision meshes in the
GLB — they waste budget. If Godot asks, disable generating physics for the import.
