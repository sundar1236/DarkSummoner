# Phase 03 — Authored Rig Validation & Attachment Contract

## Goal

Make the future layered/Skeleton2D character scene safe to install and give combat visuals a stable way to locate weapon/VFX attachment points. This phase does not fabricate character art or change combat behavior.

## Implemented

- Added `scripts/combat/character_visual_contract.gd` as the shared contract for authored character visual scenes.
- The contract requires a `Node2D` rig root, a descendant `AnimationPlayer`, and the core `idle`, `run`, and `attack_1` clips (clip names may be remapped through the existing dictionary).
- Optional clips are checked and reported as warnings; existing legacy fallback remains available for missing optional actions.
- Recognized optional attachment nodes: `WeaponSocket`, `LeftWeaponSocket`, and `RightWeaponSocket`. If present, each must inherit `Node2D`.
- `PlayerController.install_authored_visual()` now validates the scene before replacing the current rig. Invalid scenes are freed and rejected, leaving the current visual fallback intact.
- Added `PlayerController.get_authored_socket(socket_name)` to resolve a named Node2D attachment from the active authored rig. It returns null when the authored rig is not active or the socket is absent.

## Rig authoring contract

Recommended scene layout:

```text
ShadowHunterVisual (Node2D)
├── Skeleton2D (optional; use Bone2D children for layered parts)
├── CharacterParts (Node2D)
├── WeaponSocket (Node2D)
├── LeftWeaponSocket (Node2D, optional)
├── RightWeaponSocket (Node2D, optional)
└── AnimationPlayer
```

Core clips: `idle`, `run`, `attack_1`. Add `attack_2`, `attack_3`, `skill`, `hurt`, `dodge`, `defeat`, and `victory` as the art pipeline supplies them. Eight-way variants may append `_n`, `_ne`, `_e`, `_se`, `_s`, `_sw`, `_w`, or `_nw`.

Attachment points are optional in this phase so existing projectile origins and combat code remain unchanged. Future weapon/VFX migration can opt into the new socket API after a real rig is authored and visually checked.

## Validation status

- Source changes are committed on `visual-overhaul/phase-03-rig-validation`.
- Source-level inspection only. Godot 4.3 editor import, headless tests, animation playback, and Android GL Compatibility checks have not been run here.
- No rig scene is installed yet because the repository still lacks animation-ready layered Shadow Hunter artwork. The validator is infrastructure, not a claim that production art is complete.

## Next phase

Phase 04 should create and integrate the actual Shadow Hunter visual source: separate transparent body/limb/hood/cape/weapon layers with a consistent pivot manifest, then build a Skeleton2D/Bone2D rig and authored animation clips. Keep the current Sprite2D fallback until the new scene passes desktop and Android validation.
