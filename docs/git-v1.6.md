# Git workflow for v1.6

v1.6 closes Block 12 (World 1 with 6 levels and World 2). It is delivered as a pull request, like the previous blocks.

## 1. Branch and commits

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.6-world-2
```

Open the project once in Godot 4.7 so it imports the new pictures (it creates their `.import` and `.uid` files, which are committed too). The work is split in small commits:

| Commit | Content |
|---|---|
| `Add data fields for World 2 abilities` | `DefenderType.area_damage` / `trigger_delay`, `EnemyType.phase2_summon_type` / `phase2_text` |
| `Add InstantDefender for Ctrl+Z` | `instant_defender.gd` + `.tscn`, `Game` frees its cell |
| `Make shooter slow-down data-driven` | `ShooterDefender` / `Projectile` pass `slow_factor` and `slow_time`; `Enemy.apply_slow()` |
| `Add armor, split, jump and boss phase 2 summons` | `Enemy`: split through `summon_requested`, jump with a Tween, phase 2 summon; `Game`: instant cards, phase 2 banner |
| `Add placeholder art and puppets for World 2 characters` | `tools/art_src/make_world2_placeholders.py`, sheets, strips, 8 puppets |
| `Add World 2 cards, enemies and boss data` | `data/defenders/*.tres`, `data/enemies/*.tres` |
| `Add World 2 levels and dialogues` | `data/worlds/world_2/`, `data/dialogues/w2_*.tres` |
| `Show World 3 as coming soon after World 2` | `SemesterButton.State.COMING_SOON`, `GameSession.is_world_coming_soon()` |
| `Describe new abilities in the Expediente` | `expediente.gd` |
| `Tune World 2 balance (first pass)`, `Ease the World 2 boss level` | balance with the fast and slow bot (`docs/tech-note-v1.6.md`) |
| `List phase 2 summons in the Expediente catalog`, `Use neutral wording for the phase 2 summon in the Expediente` | review fixes |
| `Bump version to 1.6`, `Document Block 12`, `Add v1.6 screenshots` | `project.godot`, README, `docs/` |

```bash
git status   # check: no .godot/, no QA files, no builds
git push -u origin feature/v1.6-world-2
```

## 2. Pull request

On GitHub: *Compare & pull request*, base `main`, title `v1.6: Block 12 - expanded World 1 and World 2`. Details, balance results and tests: `docs/tech-note-v1.6.md`.

## 3. After the review

**Squash and merge** into `main` only after the team approves it, then tag it:

```bash
git checkout main
git pull origin main
git tag -a v1.6 -m "Block 12: World 1 with 6 levels and World 2"
git push origin v1.6
```

Android preset on each laptop: version/name `1.6`, version/code `7`, and the **Vibrate** permission turned on.
