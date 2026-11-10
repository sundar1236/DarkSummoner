# Phase 15 — Layered Floor Art Runtime Integration

## Goal
Connect the Phase 14 floor-art delivery contract to the existing combat arena while keeping the current procedural environment available as a fallback.

## Runtime behavior
- `ArenaBackground` looks for `res://assets/art/environments/floors/manifest.json`.
- It selects the entry whose `floor_number` matches the current GameManager floor.
- It requires exactly one each of `background`, `floor`, `props`, and `foreground`.
- Every texture must load and be exactly 720 × 1280 before any authored layer is attached.
- The four Sprite2D layers are centered at (360, 640) and ordered from distant background to foreground.
- If the manifest, selected floor, any required layer, or a texture is missing/invalid, the authored package is rejected and the existing procedural renderer is used.
- When the floor changes, previously attached authored layers are cleared before the new theme is attempted.

## Installing artwork
1. Copy `assets/art/environments/floors/manifest.example.json` to `assets/art/environments/floors/manifest.json`.
2. Export the four PNG layers for each floor using the paths already listed in that manifest.
3. Keep each image at 720 × 1280. The background may be opaque; floor, props and foreground should retain transparency.
4. Run the Phase 14 validator before launching the game:

```sh
godot --headless --script tools/validate_floor_environment_art.gd -- --manifest=res://assets/art/environments/floors/manifest.json
```

## Compatibility
No changes to player movement, joystick input, enemy spawning, collision geometry, arena boundaries, combat, rewards, floor progression, save data, or HUD. Art layers are visual-only. The current procedural floor remains the automatic fallback.

## Validation status
Source-reviewed and the example manifest contract is unchanged. Godot editor/headless execution, in-game visual verification, and Android device testing were not run. The runtime will continue showing the procedural arena until real PNG layers and the production manifest are added.
