# Hub Screen Navigation Contract

The persistent hub contains five root tabs in this order:

1. Shop
2. Hero Loadout
3. Campaign
4. Collectibles
5. Events

## Visibility invariant

Exactly one registered hub root screen may be visible at a time. `MainShellUI._set_active_tab_screen()` owns the visibility update for the complete tab list. A new tab must be added to this list and covered by the navigation test before it is considered integrated.

## Modal invariant

Energy, player profile, and blacksmith modals are mutually exclusive. Opening any modal closes the other modal roots. Switching hub tabs closes all modals before showing the selected root screen.

Invalid tab indexes are ignored and must not change the current tab or visible root screen.

The Phase 9 navigation regression coverage iterates through all five tabs, counts visible root screens, verifies modal cleanup after tab changes, and checks invalid-index handling.
