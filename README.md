# Abyssal Altar — 2D Dark-Fantasy Action Roguelike

A 2D dark-fantasy action roguelike game built with **Godot Engine 4.3** and **GDScript**, targeted for **Android first** in portrait mode (720×1280 reference resolution) with complete desktop mouse/keyboard testing support.

---

## 1. Project Overview & Gameplay Architecture

The player controls a lone hunter ascending a perilous dark-fantasy tower. Between battles, the player organizes weapons, runes, monster cores, and relics on a mystical **Altar Grid** to trigger powerful item synergies and summon companions. In combat, the player moves, aims, and attacks manually, supported by autonomous companions and item-generated abilities.

### Core Gameplay Loop
1. **Prepare the Hunter & Organize the Altar**: Place, rotate, and merge equipment on the Altar Grid.
2. **Activate Synergies**: Adjacency bonuses (e.g. Fire Rune adjacent to Wolf Core creates an evolved Hellhound) and tag sets (Shadow, Lightning, Runic, Beast).
3. **Engage in Combat**: Dual-stick mobile controls — left joystick moves, right joystick aims and continuously fires basic attacks on hold. Dodge with invulnerability frames, trigger character active skills, and quaff healing potions.
4. **Autonomous Assistance**: Spectral companions and passive relics target and attack automatically.
5. **Claim Spoils**: Victory grants Run Gold, permanent Shades, and a choice of 3 relics/equipment.
6. **Visit the Bazaar**: Blacksmith, Potion Merchant, and Relic Merchant offer run upgrades.
7. **Ascend Floors**: 5 levels per floor. Level 5 is always the Floor Boss (Lord Malakar).
8. **Boss Victory & Defeat Rules**:
   - Defeating the boss unlocks the next floor at Level 1.
   - Defeat on the boss resets the player to **Level 1 of the same floor** (never sent back to Floor 1).
   - Permanent Shades currency and character progression are saved across all runs and defeats.

---

## 2. Directory Structure

```
AbyssalAltar/
├── project.godot                  # Godot 4.3 configuration (720x1280 portrait, touch emulation)
├── export_presets.cfg             # Android APK export preset (debug keystore, arm64/x86_64)
├── default_bus_layout.tres        # Audio bus layout (Master, Music, SFX, Ambience)
├── icon.svg                       # Dark-fantasy altar SVG icon
├── README.md                      # Complete game documentation & guide
├── assets/
│   └── sprites/
│       ├── characters/            # Player base sprite
│       ├── enemies/               # Swarmer, Cultist, and Elite Golem sprites
│       ├── bosses/                # Lord Malakar (Abyssal Dread) boss sprite
│       ├── pets/                  # Spectral Wolf, Hellhound, and Demon sprites
│       ├── projectiles/           # Slash, Lightning, Soul Orb, Fireball, Enemy Orb
│       └── ui/                    # Joystick base & knob, button frames, icons
├── scenes/
│   ├── main/
│   │   └── main.tscn              # Master scene coordinator
│   ├── menus/
│   │   └── main_menu.tscn         # Start menu (Enter Tower, Sanctuary, Settings, Quit)
│   ├── characters/
│   │   └── progression_view.tscn  # Character select & Shades permanent upgrades
│   ├── combat/
│   │   └── combat_arena.tscn      # Arena floor, boundaries, waves, HUD, boss
│   ├── inventory/
│   │   └── inventory_view.tscn    # Altar grid, reserve backpack, synergy panel
│   ├── shops/
│   │   └── shop_view.tscn         # Blacksmith, Potion Merchant, Relic Merchant
│   └── ui/
│       ├── reward_view.tscn       # 3-item choice reward modal
│       ├── game_over_view.tscn    # Defeat & same-floor Level 1 retry screen
│       └── settings_modal.tscn    # Audio volume sliders (Master, SFX, Music, Ambience)
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd        # Autoload: run state, floor/level, HP, currencies
│   │   ├── main_controller.gd     # Screen transitions and coordinator
│   │   └── texture_loader.gd      # Universal texture loader (ImageTexture fallback)
│   ├── combat/
│   │   ├── player_controller.gd   # Dual-stick controls, attacks, dodge, skills
│   │   ├── enemy_controller.gd    # Swarmer, Cultist, and Elite AI
│   │   ├── boss_controller.gd     # Lord Malakar: phases, telegraphed attacks
│   │   ├── projectile_controller.gd # Unified projectile physics & collisions
│   │   ├── pet_controller.gd      # Autonomous companion AI & auto-targeting
│   │   ├── combat_manager.gd      # Wave spawning and encounter management
│   │   ├── damage_number.gd       # Floating crit/hit indicators
│   │   └── arena_background.gd    # Procedural dark-fantasy rune floor
│   ├── inventory/
│   │   ├── grid_manager.gd        # 2D cell occupancy, bounds & adjacency logic
│   │   ├── item_synergy_manager.gd # Adjacency recipes & tag bonuses
│   │   ├── inventory_view.gd      # Drag-and-drop, rotate, merge UI
│   │   └── altar_board.gd         # Interactive grid renderer & touch events
│   ├── items/
│   │   ├── item_data.gd           # Resource: shape, stats, tier, tags, passives
│   │   ├── item_instance.gd       # Runtime item: position, 90-deg rotation
│   │   └── item_database.gd       # Weapons, runes, cores, relics registry
│   ├── characters/
│   │   ├── character_data.gd      # Resource: base stats, passives, active skills
│   │   ├── character_database.gd  # Shadow Hunter, Storm Reaper, Soul Binder
│   │   └── progression_view.gd    # Permanent upgrade tree logic
│   ├── shops/
│   │   └── shop_view.gd           # 3-tab shop stock, gold check, inventory add
│   ├── save/
│   │   └── save_manager.gd        # Autoload: JSON save file, Shades, upgrades
│   ├── audio/
│   │   ├── sound_generator.gd     # Procedural 16-bit PCM WAV synthesizer
│   │   └── audio_manager.gd       # Autoload: buses, volume controls, SFX pool
│   └── ui/
│       ├── virtual_joystick.gd    # Responsive touch & mouse joystick
│       ├── combat_hud.gd          # HP, cooldowns, buttons, boss bar
│       ├── reward_view.gd         # Choice cards, claim validation
│       ├── game_over_view.gd      # Defeat and retry dispatcher
│       └── settings_modal.gd      # Volume sliders & mute toggle
└── tests/
    ├── test_runner.gd             # Automated test suite (43 assertion checks)
    └── test_runner.tscn           # Test scene
```

---

## 3. How to Run & Test the Game

### Running on Desktop (Windows)
The game runs directly with the local portable Godot 4.3 executable:

```powershell
& "D:\work drive\tools\godot\Godot_v4.3-stable_win64_console.exe" --path "D:\work drive\AbyssalAltar"
```

To run the automated test suite verifying all 20 acceptance criteria:
```powershell
& "D:\work drive\tools\godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\work drive\AbyssalAltar" tests/test_runner.tscn
```

### Testing on Android
A pre-built, signed debug APK has been exported and verified at:
`D:\work drive\AbyssalAltar\export\AbyssalAltar-debug.apk`

To install on a connected Android phone via ADB:
```powershell
& "D:\work drive\tools\android-sdk\platform-tools\adb.exe" install -r "D:\work drive\AbyssalAltar\export\AbyssalAltar-debug.apk"
```

---

## 4. Player Controls

| Control | Mobile Touchscreen | Desktop Keyboard / Mouse |
| :--- | :--- | :--- |
| **Movement** | Drag Left Virtual Joystick | WASD or Arrow Keys |
| **Aim & Attack** | Drag & Hold Right Joystick | Left Click / Hold & Drag Mouse |
| **Dodge Dash** | Tap "DODGE" Button | Spacebar |
| **Active Skill** | Tap "SKILL" Button | E Key |
| **Healing Potion** | Tap "POTION" Button | Q Key |
| **Pause / Settings** | Tap "\|\|" Button | Escape Key |

*Note: Movement and aiming operate completely independently. The player can move left while aiming and firing right.*

---

## 5. Characters & Meta-Progression

1. **Shadow Hunter** *(Default Unlocked)*
   - Quick obsidian slashes, high critical chance.
   - **Active**: *Shadow Flurry* — fires an explosive 360° ring of 8 piercing blades.
   - **Passive**: *Flurry Instinct* — consecutive hits grant +25% attack speed and +10% crit chance.
2. **Storm Reaper** *(Unlock: 40 Shades / Floor 2)*
   - High-voltage lightning strikes and chain discharges.
   - **Active**: *Chain Lightning* — casts 5 piercing electric arcs forward.
   - **Passive**: *Static Discharge* — periodic electric shockwaves hit surrounding foes.
3. **Soul Binder** *(Unlock: 80 Shades / Floor 3)*
   - Commands familiars and homing souls.
   - **Active**: *Soul Swarm* — summons 6 seeking abyssal spirits.
   - **Passive**: *Necrotic Bond* — pets deal +40% damage and leech 15% health to the player.

### Permanent Upgrades (Shades Sanctuary)
- **Vitality**: +15 Max HP per tier (up to +75 HP)
- **Obsidian Might**: +8% Attack Damage per tier (up to +40%)
- **Shadow Stride**: +6% Movement Speed per tier (up to +30%)
- **Lethal Precision**: +4% Critical Strike Chance per tier (up to +20%)
- **Altar Expansion**: Expands grid (4×4 → 5×4 → 5×5 → 6×5 → 6×6)
- **Greed of the Depths**: +25 Starting Run Gold per tier
- **Crimson Nectar**: +12 HP restored per potion charge

---

## 6. Inventory & Synergies

- **Altar Grid (Active)**: Initial 4×4 size. Items contribute all base stats, passives, and adjacency bonuses. Locked during combat.
- **Reserve Backpack (Stored)**: Holds up to 10 inactive items. Items in backpack provide zero stats or synergies.
- **90° Rotation**: Multi-cell items can be rotated in 90-degree increments with bounds and overlap validation.
- **Item Merging**: Combining two matching items of the same tier (e.g. 2× Shadow Daggers) reforges them into the next tier (Shadow Blade, Abyssal Scythe).
- **Adjacency Examples**:
  - `Fire Rune` adjacent to `Wolf Core` → **Hellhound Evolution** (transforms wolf into fiery hellhound with explosive fireballs).
  - `Fire Rune` adjacent to `Weapon` → **Flame Blade** (+12 burn damage).
  - `Blood Chalice` adjacent to `Armor` → **Vampiric Aegis** (+35 HP and healing on kill).
- **Tag Set Bonuses**: 2+ Shadow items (+15% Crit), 2+ Runes (+20% ATK), 2+ Lightning items (Storm Conduit electric aura), 2+ Cores (Beast Master pet attack speed).

---

## 7. Audio Architecture

All sound effects, ambience loops, and music tracks are synthesised procedurally using high-resolution 16-bit PCM audio streams via `SoundGenerator.gd`:
- **Audio Buses**: Master, Music, SFX, Ambience with individual volume controls and mute option.
- **SFX Pooling**: 14 pre-allocated audio players prevent clipping and dropouts.
- **Complete Sound Coverage**: UI clicks, item drag/drop/rotation/merge, attacks, crits, enemy deaths, dodges, skills, potion heals, boss warning telegraph cues, boss hits, and boss defeat.
