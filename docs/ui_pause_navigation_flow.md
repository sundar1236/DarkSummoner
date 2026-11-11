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


## Root-screen transition contract

`MainController._set_active_root_screen()` owns visibility for the top-level screens: intro, story intro, menu, hub, character selection, progression, inventory, shop, reward, and game over. A transition first hides every registered root screen and then reveals only the requested one. The settings modal remains a separate overlay and is hidden during root-screen changes.

The Phase 10 regression coverage verifies that navigating from the hub to inventory hides the hub rather than leaving both root screens active. Inventory's pause-specific processing override remains managed separately from visibility.


## Validated destination contract — Phase 11

`MainController._show_screen()` validates the requested destination before closing hub modals, hiding Settings, changing inventory processing, or toggling the arena. Unknown screen names and known-but-unavailable optional screens are ignored, preserving the current screen and overlays.

`combat` is an explicitly supported destination even though its visible root is the runtime arena rather than a `Control` screen. It hides registered UI roots and lets the arena visibility path take over. Regression coverage checks unknown destinations, missing optional screens, valid combat transitions, and preservation of the current UI when a transition is rejected.
