# GLB Integration Workflow

From generation to on-screen validation, for any character model.

## Step 1 — Generate or obtain the GLB

Two supported paths:

**A. Procedural generator (current CI path).** Headless Blender script under
`tools/blender/`. The Shadow Hunter generator (`generate_shadow_hunter.py`) is the
reference implementation: builds an armature, binds primitive-built meshes,
authors 10 named actions, exports GLB with skins. Run it the way CI does:

```bash
mkdir -p assets/generated
DARK_SUMMONER_GLB_OUT="$PWD/assets/generated/shadow_hunter.glb" \
  blender --background --factory-startup --python tools/blender/generate_shadow_hunter.py
```

**B. External AI / DCC generation.** Produce a GLB that satisfies
`character-model-spec.md` (skeleton naming, clip names, scale, orientation),
then import into Blender once to fix scale/origin if needed and re-export.
Do not commit raw un-validated vendor files to `assets/generated/`.

## Step 2 — Where files live

- Character models: `assets/generated/<actor_id>.glb`
  (gitignored — rebuilt by CI; local runs reproduce them with the command above).
- Any model that ships in the repo permanently instead lives under
  `assets/models/<actor_id>.glb` and must be added to git (not gitignored).

`glb_character_preview.gd` resolves models through
`ResourceLoader.exists("res://assets/generated/<id>.glb")` — missing file means
the 2D fallback renders instead, silently and safely.

## Step 3 — Engine import

Godot imports GLB automatically on scan. Headless import pass (same as CI):

```bash
godot --headless --editor --path . --import --quit
```

Verify no `SCRIPT ERROR:` / `Parse Error:` lines appear. A GLB that imports as a
`PackedScene` with an `AnimationPlayer` is loadable; that alone proves nothing
about visuals — go to Step 5.

## Step 4 — Wire the actor

**Player hero:** the model is picked up by the existing authored-visual scene
(`scenes/characters/<hero>_visual.tscn` extends `CharacterRigVisual`, which mounts
a `GLBCharacterPreview`). No scene edits needed if the file name matches the
`CHARACTER_MODELS` table in `glb_character_preview.gd` — add the entry there for
new heroes.

**Validation gate (mandatory):** every rig passes
`CharacterVisualContract.validate(rig_root, animation_player, clip_names)` inside
`PlayerController.install_authored_visual`. Rejections are logged as
`Authored character visual rejected: ...` and the hero falls back to 2D.

## Step 5 — Validate

```bash
# Rig + clips present and importable:
godot --headless --path . --script tools/ci/validate_generated_glb.gd

# Actually visible on camera, clips playable, previews work (needs display or Xvfb):
xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 godot --path . \
  --rendering-method gl_compatibility --script tools/ci/validate_character_render.gd

# Whole-pipeline asset audit (meshes, materials, textures, manifests, floor art):
godot --headless --path . --script tools/validate_asset_pipeline.gd
```

Success criteria: renderer test reports the model ready with ≥1 visible mesh,
camera aim dot ≥ 0.98, all 10 clips playable, and ≥100 non-empty rendered pixels.
The pipeline audit prints a per-category report; treat any FAIL as a blocker.

## Step 6 — Regression check

Run the existing suites — the visual-swap path is covered by them:

```bash
bash tools/ci/run_godot_test.sh res://tests/test_runner.tscn "ALL ACCEPTANCE TESTS PASSED SUCCESSFULLY!"
bash tools/ci/run_godot_test.sh res://tests/test_character_animation_and_combat.tscn "Phase 3 Test Results:"
```

## Naming conventions (enforced downstream)

- Clip names: `idle, run, attack_1, attack_2, attack_3, skill, hurt, dodge, defeat, victory`
  (players/bosses) and `idle, move, attack, hurt, death` (enemies). Partial sets are
  legal for players — `character_animation_controller.gd` maps missing clips to
  authored fallbacks (`AUTHORED_CLIP_FALLBACKS`) — but never invent new names.
- Skeleton root bone: `<Name>_Skeleton`; armature object `<Name>_Rig`.
- Materials get real names in the GLB (`Moonsteel`, not `Material.001`).
- Forward axis: model faces +Y in Blender export terms so that after Godot import
  the character faces down-screen toward the camera; verify via the render test.
