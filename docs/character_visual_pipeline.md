# Character visual pipeline

Dark Summoner keeps character presentation separate from the gameplay `CharacterBody2D`.
The player controller owns movement, collision, health and combat. A character scene owns
only the visible hero, its animation player and named attachment points.

## Current authored scenes

- `scenes/characters/shadow_hunter_visual.tscn`
- `scenes/characters/storm_reaper_visual.tscn`
- `scenes/characters/soul_binder_visual.tscn`

Each scene uses `scripts/combat/character_rig_visual.gd`. The renderer currently draws a
distinct procedural chibi silhouette and palette for each hero and builds its animation
library at runtime. This is an integrated visual baseline, not a claim that final hand-painted
sprite sheets or a bone-authored Skeleton2D package have been delivered.

## Required animation clips

Every authored scene must expose:

- `idle`
- `run`
- `attack_1`

The current rig also provides `attack_2`, `attack_3`, `skill`, `hurt`, `dodge`,
`defeat` and `victory`. The animation controller can fall back to the required core clips
when optional actions are absent.

## Attachment points

- `WeaponSocket`: primary weapon / projectile origin
- `LeftWeaponSocket`: left-hand attachment
- `RightWeaponSocket`: right-hand attachment

These are Node2D markers beneath the visual root. Do not put collision, health or gameplay
state inside a character visual scene.

## Replacing the procedural baseline with final art

A final art pass can replace the drawing implementation with layered Sprite2D nodes or a
Skeleton2D rig while preserving the scene paths, clip names and socket names. Keep the
character root as Node2D and ensure an AnimationPlayer is available beneath it. The player
controller validates the contract before making the authored visual active; invalid scenes
fall back to the legacy sprite rather than breaking combat.

## Validation

Run the existing `test_character_animation_and_combat.tscn` test scene. It checks that all
three scenes load, expose the complete animation library, pass the visual contract and
provide a weapon socket. Also verify hero switching and combat animations in a live run.


## Combat-facing attachment synchronization

The player controller updates all three attachment markers from the current aim vector.
The primary `WeaponSocket` therefore follows the target direction rather than remaining
fixed on one side of the hero. The left/right hand markers are offset along the perpendicular
axis and rotate with the same aim direction. Projectile and slash spawn positions resolve
from the primary authored socket when the authored rig is active, and use the legacy marker
when the fallback sprite is active.

The integration test exercises all eight compass directions and checks that the primary
socket changes its vertical placement for upward/downward aiming.


## Phase 5: layered combat presentation

The procedural renderer now adds a second detail pass over the base chibi forms: engraved chest trim, belt hardware, shoulder rivets, and hero-specific finishing elements. Shadow Hunter uses split hood tails and paired wrist blades; Storm Reaper uses segmented storm armor and a charged crescent weapon accent; Soul Binder uses rune-chain details and a floating diamond focus.

The action_pose property is animated by the existing clips. Attack stages use different positive/reverse pose values, while skill, dodge, hurt, defeat, and victory have their own pose accents. The draw pass uses this value to move arm/weapon details and render a restrained directional action arc. This is still a procedural 2D presentation layer; it is not a hand-painted sprite sheet or a bone-based Skeleton2D rig.

The character animation test checks that all ten clips animate action_pose, that the first two combo clips have distinct swing directions, and that the three hero palettes remain distinct.


## Phase 6: interruption-safe combat actions

Timed skill and dodge callbacks carry an action token and expected animation state. Starting a
new attack, skill, hurt, dodge, defeat, or victory invalidates older callbacks. A stale timer
therefore cannot unlock the player or switch a newer hurt/defeat state back to idle. Authored
skill clips own their scale animation; the legacy procedural scale tween runs only when the
authored rig is not active.

The combat test covers skill-to-hurt and dodge-to-hurt interruptions, including lock preservation
and recovery through the hurt timer.


## Phase 7: projectile hit validation

Player projectiles now validate that a collision target is a living enemy before applying
damage or hit effects. Each projectile records enemy instance IDs it has already hit, so
duplicate body/area collision notifications cannot apply repeated damage to the same enemy.
Piercing remains supported: a projectile may still hit different living enemies until its
pierce count is exhausted. Dead or invalid targets do not consume pierce count or trigger
impact effects.
