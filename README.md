# Defensa ESCOM

A lane defense game for Android (and PC) with school humor from ESCOM (IPN), built with **Godot Engine 4.x** and **GDScript**.
The player places defenders (Café, Laptop, Firewall) on a 5×9 board to stop cartoon "teacher archetypes" before they reach the safe zone.

Course project for *Desarrollo de Aplicaciones Móviles Nativas* (group 7CV4, ESCOM-IPN).
Team: Cruz Villa Miguel Angel, Hernández Alonso Diego Raymundo, Martinez Martinez Carlos Daniel, Reyes Olascoaga Julio Cesar.

## Current version: v0.1 (Block 1: Foundations and board)

What works now:

- Home screen with a **Play** button that opens the game scene (`change_scene_to_file()`).
- A 5×9 board drawn by the `Board` node, with a safe zone on the left and the enemy entry line on the right.
- Tapping or clicking a cell highlights it. The tap is converted to a (lane, column) cell in `_unhandled_input()`; the same code works with mouse on PC and touch on mobile.
- Top bar built with Control nodes, showing fixed placeholder data (energy, defender cards, wave progress) and a play timer.
- Pause menu (Resume, Restart level, Exit to home) using `get_tree().paused` and `process_mode = When Paused`. The timer freezes while paused and continues from the same point.
- The game pauses automatically when the app goes to the background, and the Android back button opens/closes the pause menu.

## Requirements

- Godot Engine 4.4 or newer (standard build, not .NET).
- For Android builds: Android export templates, OpenJDK 17 and the Android SDK configured in *Editor Settings → Export → Android*.

## How to run

1. Open Godot, choose **Import**, and select `project.godot`.
2. Press **F5** (Run Project). The game starts on the home screen.

## Project settings

| Setting | Value |
|---|---|
| Renderer | Compatibility (best support on low-end phones) |
| Base resolution | 1280×720, landscape |
| Stretch | `canvas_items`, aspect `keep` |
| Touch | *Emulate Mouse From Touch* enabled |
| Back button | `quit_on_go_back = false` (handled by the game) |

## Architecture

- **Nodes and scenes:** every screen and every game entity is a reusable scene.
- **Data separated from the engine:** defenders, enemies, levels and worlds will be Custom Resources (`DefenderType`, `EnemyType`, `LevelData`, `WorldData`) from Block 2 on.
- **Cell-based logic:** game logic works in board cells (lane, column, with decimals like column 6.4). Only `Board.cell_to_pixel()` / `Board.pixel_to_cell()` convert to and from screen pixels.
- **Signals:** nodes communicate through signals (`Board.cell_tapped`, `Hud.pause_pressed`, `PauseMenu.resume_requested`...). The `Game` node connects them.

## Folder structure

```
res://
├── scenes/
│   ├── ui/          main_menu.tscn, hud.tscn, pause_menu.tscn, ui_theme.tres
│   ├── game/        game.tscn, board.tscn
│   └── entities/    (Block 2+)
├── scripts/
│   ├── engine/      game.gd, board.gd
│   ├── ui/          main_menu.gd, hud.gd, pause_menu.gd
│   ├── entities/    (Block 2+)
│   ├── data/        (Block 2+)
│   └── save/        (Block 4-5)
├── data/            defenders/, enemies/, worlds/levels/ (Block 2+)
├── art/             (Block 6)
└── docs/            technical notes per block
```

## Roadmap

| Block | Version | Content | Status |
|---|---|---|---|
| 1 | v0.1 | Foundations, 5×9 board, input, pause | ✅ Done |
| 2 | v0.2 | Defenders and energy economy | Pending |
| 3 | v0.3 | Enemies and combat | Pending |
| 4 | v0.4 | Data-driven levels and world flow | Pending |
| 5 | v0.5 | Save system and error states | Pending |
| 6 | v1.0 | Final boss, art and polish | Pending |
