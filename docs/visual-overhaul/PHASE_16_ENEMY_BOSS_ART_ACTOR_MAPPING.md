# Phase 16 — Enemy and Boss Art Actor Mapping

## Goal
Connect gameplay enemy types to the actor IDs defined by the Phase 08 art manifest, and prevent an enemy sheet from being loaded as a boss (or vice versa).

## Gameplay-to-art mapping

| Gameplay enemy type | Manifest actor ID | Manifest role |
|---|---|---|
| `swarmer` | `swarmer` | `enemy` |
| `cultist` | `cultist` | `enemy` |
| `charger` | `charger` | `enemy` |
| `elite` | `elite_brute` | `enemy` |
| `mini_boss` | `abyssal_champion` | `enemy` |
| Floor boss | `lord_malakar` | `boss` |

The gameplay-facing type names and art package IDs are intentionally allowed to differ. The mapping is centralized in `EnemyController._resolve_authored_actor_id()`.

## Runtime safeguards
- `EnemyBossSpriteAnimation.setup_from_manifest()` accepts an optional expected role.
- EnemyController requests role `enemy`; BossController requests role `boss`.
- A role mismatch rejects the authored sheet before the animation is built. Existing Sprite2D visuals remain visible as the fallback.
- Existing required-clip, frame-grid, alpha-channel, and frame-index checks remain in place.
- Unknown gameplay enemy types retain their original ID lookup; if no matching valid actor exists, the existing legacy visual remains active.

## Artwork delivery
The production manifest remains `assets/art/enemies/source/manifest.json`, copied from the example contract and updated with actual original sprite sheets. This phase does not create placeholder or synthetic production artwork.

## Compatibility
No changes to enemy stats, AI, attack timing, movement, collision, damage, drops, boss patterns, progression, save data, or player controls.

## Validation status
The gameplay-to-manifest mapping and expected-role call sites were source-reviewed against the example manifest IDs. Godot headless/editor execution, in-game animation verification, and Android device testing were not run. Production sprite sheets are still required before authored animations can appear in-game.
