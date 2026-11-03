# Git workflow for v0.5.1

v0.5.1 contains the fixes from the review of Block 5. It is delivered as a pull request, like Blocks 2 to 5.

## 1. Branch and commit (already done on Raymundo's laptop)

```bash
git checkout main
git pull origin main
git checkout -b feature/v0.5.1-fixes
git add -A
git commit -m "fix(v0.5.1): stale load warning, projectile hits on slow frames, back button on result panels"
```

## 2. Push and open the pull request

```bash
git push -u origin feature/v0.5.1-fixes
```

On GitHub: *Compare & pull request*, base `main`.

**Title:** `v0.5.1: Block 5 review fixes`

**Description:**

> Fixes found in the review of v0.5. No new screens or nodes.
>
> - Home no longer shows "No se pudo leer tu progreso guardado" after a later save has written good data (`ProgressRepository.save_progress()` resets `load_error`).
> - New `docs/.gdignore`: the screenshots are no longer imported or exported into the APK; the `docs/img/*.png.import` files are removed.
> - The Home version label is read from Project Settings (`application/config/version` = `0.5.1`).
> - Projectiles check the whole stretch flown in each frame, so a slow frame cannot skip an enemy.
> - Android back button on the Victory and Defeat panels works like "Volver al inicio".
> - Loading screen: if the background load fails, it tries once with a normal `load()` before showing the error.
>
> Details and tests: `docs/tech-note-v0.5.1.md`.

## 3. Review and merge

A teammate reviews and approves it, then merges it into `main` (*Squash and merge*).

## 4. Update your local copy and tag the version

```bash
git checkout main
git pull origin main
git tag -a v0.5.1 -m "Block 5 review fixes"
git push origin v0.5.1
```

Only one person creates and pushes the tag. Optional cleanup of merged branches:

```bash
git branch -d feature/v0.5.1-fixes
git push origin --delete feature/v0.5.1-fixes
```
