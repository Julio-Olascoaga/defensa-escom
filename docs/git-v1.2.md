# Git workflow for v1.2

v1.2 closes Block 8 (career map, level select and grades). It is delivered as a pull request, like the previous blocks.

## 1. Branch and commits

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.2-career-map
```

The work is split in small commits (save format, GameSession rules, placeholder art, Extraordinario, HUD, Victory, Game, career map and level select, Semestre aprobado, Ajustes and Créditos, version, docs).

## 2. Push and open the pull request

```bash
git push -u origin feature/v1.2-career-map
```

On GitHub: *Compare & pull request*, base `main`, title `v1.2: Block 8 - career map, level select and grades`. Details, node hierarchy and tests: `docs/tech-note-v1.2.md`.

## 3. After the review

Merge into `main` only after the team approves it, then tag it:

```bash
git checkout main
git pull origin main
git tag v1.2
git push origin v1.2
```
