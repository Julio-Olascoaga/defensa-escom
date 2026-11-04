# Git workflow for v1.1

v1.1 closes Block 7 (foundations 2.0). It is delivered as a pull request, like the 1.0 blocks.

## 1. Branch and commit (already done on Raymundo's laptop)

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.1-foundations

git add -A .gitignore default_bus_layout.tres project.godot data scenes scripts README.md docs
git commit -m "v1.1: Block 7 - campaign data, save format v2, scene transitions and Android back button"
```

The level files were moved with `git mv`, so GitHub shows them as renames (`level_1.tres → w1_l2.tres`) and keeps their history.

## 2. Push and open the pull request

```bash
git push -u origin feature/v1.1-foundations
```

(Or in GitHub Desktop: *Publish branch*.) On GitHub: *Compare & pull request*, base `main`.

**Title:** `v1.1: Block 7 – foundations 2.0`

**Description:**

> Lays the foundations of version 2.0 without changing the rules, cards, enemies or balance of the 1.0.
>
> - **Campaign data:** new `CampaignData` (`data/campaign.tres`) with the 8 semesters. World 1 is now *Primer semestre* with 6 levels: new short level *Primer día* (`w1_l1`, future tutorial) + the five 1.0 levels, moved to `data/worlds/world_1/levels/w1_l2…w1_l6.tres`. Worlds 2–8 exist as "Próximamente" (`available = false`).
> - **Extended resources** (`WorldData`, `LevelData`, `DefenderType`, `EnemyType`) and new `DialogueData` / `DialogueLine`. Every new field defaults to the 1.0 behavior.
> - **GameSession** Autoload: chosen world and level. Game, the loading screen and Home ask it instead of ProgressRepository.
> - **ProgressRepository v2:** `[meta] version=2`, unlocked level, best grade per level, dialogues seen, settings; automatic migration of 1.0 saves (+1 level because of *Primer día*); saves when the app goes to the background.
> - **SceneTransition** Autoload (fade to black on every scene change) and **AudioManager** Autoload with the `Music` and `SFX` buses (`default_bus_layout.tres`).
> - **Android:** back button asks "¿Salir del juego?" on Home; screen kept on only while playing; top bar respects the notch.
> - `application/config/version = "1.1"`, `*.jks` in `.gitignore`.
>
> Details, node hierarchy and tests: `docs/tech-note-v1.1.md`.
>
> Pending outside this PR (done in class): Play Console, signed AAB and closed testing.

## 3. Review and merge

A teammate reviews and approves it, then merges it into `main` (*Squash and merge*). Block 7 is the only block the others depend on: after the merge, every front runs `git pull origin main` in its own branch.

## 4. Update your local copy and tag the version

```bash
git checkout main
git pull origin main
git tag -a v1.1 -m "Block 7: foundations 2.0"
git push origin v1.1
```

Only one person creates and pushes the tag. Optional cleanup:

```bash
git branch -d feature/v1.1-foundations
git push origin --delete feature/v1.1-foundations
```
