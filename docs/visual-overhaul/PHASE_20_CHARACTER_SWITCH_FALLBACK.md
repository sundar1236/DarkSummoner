# Phase 20 — Character Switch Visual Fallback

## Goal

Prevent a previously installed authored character rig from remaining visible after the selected character changes to one without a generated visual scene.

## Changes

- The selected-character loader now clears the active authored rig when the new character has no scene mapping, the scene resource cannot load, or rig validation fails.
- The animation controller exposes `clear_authored_animation()` to detach the previous AnimationPlayer and return visibility to the legacy Sprite2D.
- The current character's legacy sprite remains the visual fallback while gameplay continues on the existing CharacterBody2D.

## Compatibility

No changes are made to movement, joystick input, target selection, attacks, damage, collision, progression, or save data.

## Validation status

Source-level review only. Godot editor/headless execution, character switching in-game, and Android device testing remain required. Production authored scenes are still needed before the new rigs can be visually verified.
