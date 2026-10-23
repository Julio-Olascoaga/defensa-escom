# Git commands for v0.1

First time only (empty remote repository already created on GitHub):

```bash
cd defensa-escom
git init
git branch -M main
git remote add origin https://github.com/<user>/defensa-escom.git
```

Every block:

```bash
git add .
git commit -m "feat(v0.1): project setup, 5x9 board, cell tap detection and pause menu

- Godot 4.4 project with Compatibility renderer, 1280x720 landscape, canvas_items stretch
- Main menu with Play button and scene change to game.tscn
- Board node: draws 5x9 grid and safe zone, converts cells <-> pixels
- Tap/click to (lane, column) in _unhandled_input with touch-to-mouse emulation
- HUD top bar with Control nodes and placeholder data
- Pause menu using get_tree().paused and process_mode When Paused
- Auto-pause on app background, Android back toggles pause
- README and technical note v0.1"
git tag -a v0.1 -m "Block 1: Foundations and board"
git push -u origin main
git push origin v0.1
```
