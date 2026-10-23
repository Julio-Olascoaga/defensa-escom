# Technical Note — v0.1 (Block 1: Foundations and Board)

## Goal

Run the project on PC and phone with scene navigation, a 5×9 board that detects taps, and a working pause system.

## Node hierarchy

### `scenes/ui/main_menu.tscn` (main scene)

```
MainMenu (Control, full rect)            main_menu.gd
├── Center (CenterContainer)
│   └── Content (VBoxContainer)
│       ├── Title (Label)                "Defensa ESCOM"
│       ├── Subtitle (Label)             "Mundo 1"
│       └── %PlayButton (Button)         "Jugar"
└── VersionLabel (Label)                 "v0.1"
```

### `scenes/game/game.tscn`

```
Game (Node2D)                            game.gd
├── Board (instance of board.tscn)       position (80, 110)
└── UI (CanvasLayer)
    ├── HUD (instance of hud.tscn)
    └── PauseMenu (instance of pause_menu.tscn, hidden)
```

### `scenes/game/board.tscn`

```
Board (Node2D)                           board.gd  (draws the grid in _draw())
└── SafeZoneLabel (Label, rotated -90°)  "ZONA SEGURA"
```

### `scenes/ui/hud.tscn`

```
HUD (PanelContainer, top wide, 100 px)   hud.gd
└── Row (HBoxContainer)
    ├── %PauseButton (Button)            "II"
    ├── EnergyLabel (Label)              fixed "Energía 50"
    ├── CafeCard / LaptopCard / FirewallCard (Button)   fixed placeholders
    ├── Spacer (Control, expand)
    └── WaveBox (VBoxContainer)
        ├── WaveLabel (Label)            fixed "Oleada 1 de 2"
        ├── WaveBar (ProgressBar)
        └── %TimeLabel (Label)           play timer
```

### `scenes/ui/pause_menu.tscn`

```
PauseMenu (Control, full rect, process_mode = When Paused)   pause_menu.gd
├── Dim (ColorRect, black 60%)
└── Center (CenterContainer)
    └── Panel (PanelContainer)
        └── Buttons (VBoxContainer)
            ├── Title (Label)            "Pausa"
            ├── %ResumeButton            "Reanudar"
            ├── %RestartButton           "Reiniciar nivel"
            └── %ExitButton              "Salir al inicio"
```

## Scripts

| Script | Class | Responsibility |
|---|---|---|
| `scripts/engine/board.gd` | `Board` | Grid constants (5 lanes, 9 columns, 120 px cells). `cell_to_pixel()` and `pixel_to_cell()` are the only cell↔pixel conversions. Detects taps in `_unhandled_input()` and emits `cell_tapped(lane, column)`. Draws cells, safe zone, entry line and highlight. |
| `scripts/engine/game.gd` | — | Root of the game scene. Connects signals, counts `elapsed_time` in `_process(delta)`, highlights the tapped cell, and owns pause/resume/restart/exit. Auto-pauses when the app goes to background; Android back toggles pause. |
| `scripts/ui/hud.gd` | `Hud` | Emits `pause_pressed`; `set_time()` updates the timer label. |
| `scripts/ui/pause_menu.gd` | `PauseMenu` | Emits `resume_requested`, `restart_requested`, `exit_requested`. It never changes the pause state itself. |
| `scripts/ui/main_menu.gd` | — | Play button → `change_scene_to_file("res://scenes/game/game.tscn")`. Android back quits. |

## Key decisions

- **Board by math, not TileMap:** a cell is `CELL_SIZE` pixels; position = cell × size. No tileset to configure.
- **Input:** finger taps arrive as left mouse clicks because *Emulate Mouse From Touch* is on. UI buttons consume their clicks first, so the board only receives taps that land on it.
- **Pause:** `get_tree().paused = true` stops every node in *Pausable* mode (Game timer and Board input). PauseMenu uses *When Paused*, so it is the only thing that responds. The tree is always unpaused before reloading or changing scenes.
- **Signals flow up, calls flow down:** children emit signals; `Game` reacts and calls methods on its children.

## Project settings changed

Renderer Compatibility (desktop and mobile), viewport 1280×720, stretch `canvas_items` / `keep`, landscape orientation, Emulate Mouse From Touch on, `quit_on_go_back = false`, clear color `#14102B`, custom theme `ui_theme.tres` (default font size 26).

## Verification

Automated run on Godot 4.4.1: tap at cell (lane 2, column 4) highlights that cell; taps on the HUD or the safe zone are ignored; while paused the timer is frozen and taps on the board do nothing; Resume continues the timer; Restart reloads unpaused with a fresh timer; Exit returns to the home screen unpaused.

Pending manual check: Android export and APK install on a physical phone.
