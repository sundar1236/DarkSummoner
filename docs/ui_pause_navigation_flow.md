# Pause Inventory Navigation Contract

The combat pause flow keeps the arena paused while allowing the player to inspect and manage the altar inventory.

## Expected flow

1. The combat HUD pause action pauses the SceneTree and opens Settings.
2. Choosing **View Altar & Inventory** hides Settings and opens Inventory.
3. Inventory switches to `PROCESS_MODE_ALWAYS` for the duration of this pause-only view, so its controls remain usable while combat stays paused.
4. Closing Inventory hides that screen, restores its inherited process mode, and reopens Settings.
5. Combat remains paused until the player explicitly resumes or abandons the run.

Normal reward/shop inventory navigation continues to use inherited processing. The pause-specific process override must not remain active after the inventory view closes.

The Phase 8 navigation regression test verifies screen visibility, process mode restoration, settings restoration, and preservation of the paused SceneTree.
