# Git workflow for v1.0

v1.0 closes Block 6 (final boss, art and polish). It is delivered as a pull request, like Blocks 2 to 5.

## 1. Branch and commits (already done on Raymundo's laptop)

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.0-final

git add art data scenes scripts project.godot
git commit -m "feat(v1.0): final art for defenders, enemies, board and home screen"

git add data scenes scripts
git commit -m "feat(v1.0): final boss, level 5 and wave warnings"

git add scenes scripts
git commit -m "feat(v1.0): hit flash, shake, walking sway, floating orb and sparks"

git add data
git commit -m "balance(v1.0): bigger final waves, easier starts in levels 4-5, test defender USB"

git add README.md docs project.godot scenes/ui/main_menu.tscn
git commit -m "docs(v1.0): technical note, README and version 1.0"
```

## 2. Push and open the pull request

```bash
git push -u origin feature/v1.0-final
```

(Or in GitHub Desktop: *Publish branch*.) On GitHub: *Compare & pull request*, base `main`.

**Title:** `v1.0: Block 6 – final boss, art and polish`

**Description:**

> Closes World 1: it can be played from Home to the final boss and ends with "¡Mundo 1 superado!".
>
> - **Art:** final images under `art/` for defenders, enemies, boss, orb, projectile, spark, game and home backgrounds, logo and app icon. Each texture lives in its `DefenderType` / `EnemyType`; without a texture the letter placeholder is still drawn.
> - **Final boss** `examen_final.tres`: same `enemy.tscn`, new `EnemyType` fields (`sprite_size`, `is_boss`, `summon_type`, `summon_interval`). Every 10 s it asks for two *Examen sorpresa* in the lanes above and below it (`Enemy.summon_requested`); `Game` creates them with `spawn_enemy()`. Boss health bar (`ProgressBar`) at the bottom.
> - **Level 5** *El examen final* added to `world_1.tres`.
> - **Wave warnings:** `WaveData.warning_text` + `WaveManager.wave_warning`, shown 2 s before each wave by `WaveBanner` (a second `Notice`).
> - **Feedback:** hit flash (0.1 s), defender shake, walking sway, floating orb (Tween) and spark bursts (`CPUParticles2D`, new `SparkBurst` scene in the `Effects` node).
> - **Balance (first pass):** bigger last waves in levels 3–5, more energy and calm at the start of levels 4–5, boss with 3000 health. Levels 1–2 and the Café economy are unchanged.
> - **Scalability test:** `data/defenders/usb.tres`, a fourth defender made only with a resource (not used by any level).
> - `application/config/version = "1.0"`.
>
> Details, node hierarchy and tests: `docs/tech-note-v1.0.md`.
>
> Pending outside this PR: tests with 3–5 students and the signed release APK.

## 3. Review and merge

A teammate reviews and approves it, then merges it into `main` (*Squash and merge*).

## 4. Update your local copy and tag the version

```bash
git checkout main
git pull origin main
git tag -a v1.0 -m "Block 6: final boss, art and polish"
git push origin v1.0
```

Only one person creates and pushes the tag. Optional cleanup of merged branches:

```bash
git branch -d feature/v1.0-final
git push origin --delete feature/v1.0-final
```
