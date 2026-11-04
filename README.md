# Defensa ESCOM

A lane defense game for Android (and PC) with school humor from ESCOM (IPN), built with **Godot Engine 4.x** and **GDScript**.
The player places defenders (Café, Laptop, Firewall) on a 5×9 board to stop cartoon "teacher archetypes" before they reach the school, and faces the final boss *El examen final* at the end of World 1.

Course project for *Desarrollo de Aplicaciones Móviles Nativas* (group 7CV4, ESCOM-IPN).
Team: Cruz Villa Miguel Angel, Hernández Alonso Diego Raymundo, Martinez Martinez Carlos Daniel, Reyes Olascoaga Julio Cesar.

## Current version: v1.2 (Block 8: Career map, levels and grades)

Version 2.0 grows the game into a career of **8 semesters** (worlds) with 6 to 8 levels each, the Director as narrator, cut-out animation, IPN locations and a World 2. Block 8 lets the player choose the semester and the level, and grades every victory (see `docs/tech-note-v1.2.md`):

- **New flow:** Inicio (*Jugar*/*Continuar*, *Expediente* (Block 9, disabled), *Ajustes*, *Créditos*) → **Mapa de la carrera** → **Selección de nivel** → game → Victory → *Siguiente nivel* or *Selección de nivel*. Pause and Defeat exit to the level select. The Android back button goes back one screen everywhere and asks "¿Salir del juego?" on Inicio.
- **Career map:** the 8 semesters in a horizontal scroll joined by a path, built in code from `data/campaign.tres`: locked (padlock, *Próximamente* for unavailable worlds), available (pulses) or passed (shows the average). A world opens when the last level of the previous one is won.
- **Level select:** a 4 × 2 grid with the levels of the world (number, name, best grade or padlock). Tapping something locked says why.
- **Extraordinarios** (levels 2–6 of World 1, `LevelData.use_extraordinarios`): one per lane. The first enemy that reaches the school in a lane makes it run along the lane removing every enemy; the second one is a defeat.
- **Grade 6–10:** 10 minus one point per Extraordinario used. Shown with a stamp on Victory, saved only if better, shown on the level button; **Semestre aprobado** shows the average of the world (the progress is no longer reset after the last level).
- **Dar de baja:** eraser button in the top bar; tap a defender to remove it (no energy back).
- **Top bar for up to 6 cards** (compact top row; the left side stays free for the Extraordinarios).
- **Ajustes:** music and effects sliders (buses `Music` / `SFX`), vibration, *Borrar progreso* with confirmation, *Créditos*. Saved in `user://progress.cfg`.
- **Save format v3:** 1.0 and v1.1 saves are migrated; a player who finished World 1 in the 1.0 sees it as passed, and the levels won in the 1.0 get grade 6 (the 1.0 had no grades).

Block 7 (v1.1) foundations, still in place:

- **Campaign data:** `data/campaign.tres` (`CampaignData`) lists the 8 worlds in order. World 1 is **Primer semestre** (ESCOM) with **6 levels**: the new short level **Primer día** (future tutorial) and the five 1.0 levels. Worlds 2–8 already exist as `WorldData` files marked "Próximamente" (`available = false`).
- **Extended resources** with defaults that reproduce the 1.0: `WorldData`, `LevelData`, `DefenderType` and `EnemyType` gained the fields the next blocks need, and `DialogueData` / `DialogueLine` were added for the Director.
- **GameSession** Autoload: remembers the chosen world and level; Game, the loading screen and the home screen ask it what to play.
- **Save format** (`user://progress.cfg`, v2 in Block 7, v3 now): unlocked level, "Continuar" level, best grade per level, dialogues seen and settings. Older saves are **migrated automatically** and the progress is kept.
- **SceneTransition** Autoload: every screen change fades to black and back.
- **AudioManager** Autoload with the `Music` and `SFX` buses (sounds arrive in Block 11).
- **Android:** the back button pauses in a level and asks **"¿Salir del juego?"** on the home screen; minimizing pauses and saves; the screen stays on while playing; the top bar respects the notch.

Everything from v1.0 still works:

- **Final art** for every defender, enemy, the boss, the energy orb, the projectile, the game board background, the home screen, the logo and the app icon. Each image lives in its `DefenderType` / `EnemyType` resource; a resource without an image is drawn as a letter placeholder.
- **Final boss *El examen final*:** one more `EnemyType` file using the same enemy scene, drawn bigger, with 3000 health; every 10 s it summons two *Examen sorpresa* in the lanes above and below it. A **boss health bar** appears while it is alive. Defeating it completes the semester (**"¡Primer semestre aprobado!"** screen since v1.2).
- **Wave warnings** ("¡Se acerca una oleada!"), **visual feedback** (hit flash, shake, sway, floating orbs, sparks), **loading screen**, **save error notice** with *Reintentar* / *Ahora no*, and the **hidden debug option** (tap the logo 5 times, debug builds only).
- **Waves**, **defender cards** (Café 50, Laptop 100, Firewall 75), **energy orbs**, **three enemy archetypes**, **Victory**, **Defeat** and **Pause** panels, as in v1.0.

## Requirements

- Godot Engine 4.4 or newer (standard build, not .NET). Tested on Godot 4.7.
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
| Version | `application/config/version = "1.2"` (shown on the home screen). Android preset (not in the repo): version/name `1.2`, version/code `3`, permission *Vibrate* |
| Screen | `keep_screen_on = false`; the game screen keeps it on while playing |
| Audio buses | `default_bus_layout.tres`: `Music` and `SFX` |
| Autoloads | `GameSession`, `ProgressRepository`, `AudioManager`, `SceneTransition` (in this order) |
| Icon | `art/icon/icon.png` |

## Architecture

- **Nodes and scenes:** every screen and every game entity is a reusable scene.
- **Data separated from the engine:** each defender is a `DefenderType` Custom Resource (`data/defenders/*.tres`) with its name, cost, health, cooldown, image and the **behavior scene** it uses. Each enemy is an `EnemyType` resource (`data/enemies/*.tres`) read by the single `enemy.tscn` scene; the boss is one more `EnemyType` with `is_boss`, a bigger `sprite_size` and a summon ability. Each level is a `LevelData` resource (`data/worlds/world_N/levels/*.tres`, with a unique `id` such as `w1_l3`) whose waves are `WaveData` lists of `SpawnEvent`s. Each world is a `WorldData` (`data/worlds/world_N/world_N.tres`) with its ordered levels, and `data/campaign.tres` (`CampaignData`) holds the 8 worlds in order.
- **Session and progress:** the `GameSession` Autoload knows which world and level are being played, which worlds and levels are open and how a level is graded. The `ProgressRepository` Autoload is the only one that reads and writes in `user://` (save format v3, migration from 1.0 and v1.1).
- **Screens built from data:** the career map creates one `SemesterButton` per `WorldData` of the campaign and the level select one `LevelButton` per `LevelData` of the world, so new worlds and levels appear without touching scripts.
- **Screens and sound:** the `SceneTransition` Autoload makes every scene change (fade with a Tween). The `AudioManager` Autoload owns the music and effect players on the `Music` and `SFX` buses.
- **Behaviors by inheritance:** `Defender` (health, damage, shake, death) is the base script; `GeneratorDefender`, `ShooterDefender` and `BlockerDefender` inherit from it.
- **Cell-based logic:** game logic works in board cells (lane, column, with decimals like column 6.4). Only `Board.cell_to_pixel()` / `Board.pixel_to_cell()` convert to and from screen pixels. Enemy speed is in cells per second, and hits are distance checks in columns.
- **Signals:** nodes communicate through signals (`Board.cell_tapped`, `Hud.card_pressed`, `GeneratorDefender.orb_produced`, `EnergyOrb.collected`, `ShooterDefender.shot_fired`, `Enemy.reached_safe_zone`, `Enemy.damaged`, `Enemy.summon_requested`, `Defender.died`, `WaveManager.spawn_requested`, `WaveManager.wave_warning`, `WaveManager.all_waves_cleared`...). The `Game` node owns the energy and the phase of the match, applies the rules and creates every enemy, including the boss's summons.
- **Effects:** animations are Tweens created by each node (`create_tween()`), so they stop with the pause and disappear with their node. Sparks are one-shot `CPUParticles2D` (`SparkBurst`) added to the `Effects` node of the game scene.

### Adding a level (no scripts)

1. In the FileSystem dock, right-click `data/worlds/world_N/levels/` → *New Resource…* → `LevelData`.
2. In the Inspector, fill in a unique `id` (for example `w1_l7`), `display_name` and `start_energy`, drag the defenders from `data/defenders/` into `defenders` (6 at most: the limit of the card bar) and turn on `use_extraordinarios` if the lanes should have them.
3. In `waves`, add a *New WaveData* with its `start_delay` (and `warning_text` if it needs a special warning), and inside `events` add one *New SpawnEvent* per enemy (`time`, `lane`, `enemy_type` from `data/enemies/`).
4. Add the new file to `levels` in `data/worlds/world_N/world_N.tres`, in the position where it should be played. It appears in the level select of that world.

### Adding a world (no scripts)

1. Create `data/worlds/world_N/world_N.tres` (*New Resource…* → `WorldData`) with a unique `id` (`world_N`), `display_name`, `semester`, `location_name` and `available = true`.
2. Create its levels as above and add them to its `levels`.
3. Add the world to `worlds` in `data/campaign.tres`, in its position (worlds 2–8 are already there as "Próximamente").

### Adding a defender with an existing behavior

1. In the FileSystem dock, right-click `data/defenders/` → *New Resource…* → `DefenderType`.
2. Fill in the fields in the Inspector, set `behavior_scene` to one of the scenes in `scenes/entities/` and, optionally, a `texture`.
3. Add the new resource to the `defenders` list of the levels where it should be available. Its card appears automatically.

Example: `data/defenders/usb.tres` (*USB*, a cheap wall: `BlockerDefender`, cost 25, 600 health) was made this way without writing any script. No level uses it yet. The top bar fits up to 6 cards (with 4 or more they switch to a compact size).

### Adding an enemy or a boss

Create an `EnemyType` in `data/enemies/` with its health, speed, damage and texture. For a boss, enable `is_boss` (health bar), raise `sprite_size` and choose a `summon_type` and `summon_interval`. Then use it in the `SpawnEvent`s of a level.

## Folder structure

```
res://
├── art/
│   ├── defenders/   cafe, laptop, firewall (.png)
│   ├── enemies/     tarea_infinita, examen_sorpresa, diapositivas, examen_final (.png)
│   ├── items/       energy_orb, projectile (.png)
│   ├── fx/          spark.png
│   ├── backgrounds/ game_bg.jpg, menu_bg.jpg
│   ├── icon/        icon.png
│   └── ui/          logo.png; placeholders of v1.2: semester_locked/available/passed, padlock,
│                    grade_stamp, extraordinario, eraser (.png)
├── scenes/
│   ├── ui/          main_menu, career_map, level_select, world_complete, settings, credits,
│   │                loading_screen, hud, pause_menu, defender_card, notice,
│   │                defeat_panel, victory_panel, save_error_panel (.tscn), ui_theme.tres
│   ├── game/        game.tscn, board.tscn, extraordinario.tscn
│   ├── entities/    generator_defender, shooter_defender, blocker_defender, energy_orb,
│   │                enemy, projectile (.tscn)
│   └── fx/          spark_burst.tscn
├── scripts/
│   ├── engine/      game.gd, board.gd, wave_manager.gd, extraordinario.gd
│   ├── ui/          main_menu.gd, career_map.gd, semester_button.gd, level_select.gd,
│   │                level_button.gd, world_complete.gd, settings.gd, credits.gd,
│   │                loading_screen.gd, hud.gd, pause_menu.gd, defender_card.gd,
│   │                notice.gd, defeat_panel.gd, victory_panel.gd, save_error_panel.gd
│   ├── entities/    defender.gd, generator_defender.gd, shooter_defender.gd,
│   │                blocker_defender.gd, energy_orb.gd, enemy.gd, projectile.gd
│   ├── fx/          spark_burst.gd
│   ├── autoload/    game_session.gd, audio_manager.gd, scene_transition.gd
│   ├── data/        defender_type.gd, enemy_type.gd, spawn_event.gd, wave_data.gd,
│   │                level_data.gd, world_data.gd, campaign_data.gd,
│   │                dialogue_data.gd, dialogue_line.gd
│   └── save/        progress_repository.gd (Autoload)
├── data/
│   ├── defenders/   cafe.tres, laptop.tres, firewall.tres, usb.tres (test defender)
│   ├── enemies/     tarea_infinita.tres, examen_sorpresa.tres, diapositivas.tres, examen_final.tres
│   ├── campaign.tres  the 8 worlds in order
│   ├── dialogues/   conversations of the Director (Block 9)
│   └── worlds/      world_1/ (world_1.tres, levels/w1_l1.tres … w1_l6.tres), world_2/ … world_8/
├── default_bus_layout.tres  audio buses Music and SFX
└── docs/            technical notes and screenshots per block (.gdignore: not imported by Godot)
```

## Screenshots

![v1.2 career map](docs/img/v1.2-map.png)
![v1.2 level select](docs/img/v1.2-level-select.png)
![v1.2 victory with the grade](docs/img/v1.2-victory.png)
![v1.2 Semestre aprobado](docs/img/v1.2-world-complete.png)
![v1.2 Ajustes](docs/img/v1.2-settings.png)
![v1.1 home screen](docs/img/v1.1-home.png)
![v1.1 back button on the home screen](docs/img/v1.1-quit.png)
![v1.0 level 3](docs/img/v1.0-game.png)
![v1.0 final boss](docs/img/v1.0-boss.png)

## Roadmap

| Block | Version | Content | Status |
|---|---|---|---|
| 1 | v0.1 | Foundations, 5×9 board, input, pause | ✅ Done |
| 2 | v0.2 | Defenders and energy economy | ✅ Done |
| 3 | v0.3 | Enemies and combat | ✅ Done |
| 4 | v0.4 | Data-driven levels and world flow | ✅ Done |
| 5 | v0.5 | Save system and error states | ✅ Done |
| 5 | v0.5.1 | Review fixes for Block 5 | ✅ Done |
| 6 | v1.0 | Final boss, art and polish | ✅ Done |
| 7 | v1.1 | Foundations 2.0: campaign data, save v2, transitions, audio buses, Android behavior | ✅ Done (Play Console and signed AAB pending, in class) |
| 8 | v1.2 | Career map, level select, grades, Extraordinarios, settings | ✅ Done (placeholder art) |
| 9 | v1.3 | The Director: dialogues, tutorial, Expediente | Next |
| 10 | v1.4 | Cut-out animation and 3-stage damage | Planned |
| 11 | v1.5 | IPN locations and audio | Planned |
| 12 | v1.6 | World 1 with 6 levels and World 2 | Planned |
| 13 | v2.0 | Polish and closed testing | Planned |
