# Git workflow for v1.3

v1.3 closes Block 9 (the Director, the tutorial and the Expediente). It is delivered as a pull request, like the previous blocks.

## 1. Branch and commit

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.3-director
# ... work of the block ...
git add -A
git commit -m "v1.3: Block 9 - the Director, guided tutorial and Expediente"
```

## 2. Push and open the pull request

```bash
git push -u origin feature/v1.3-director
```

On GitHub: *Compare & pull request*, base `main`, title `v1.3: Block 9 - the Director, guided tutorial and Expediente`. Details, node hierarchy and tests: `docs/tech-note-v1.3.md`. The World 2 scripts are in `docs/dialogues-world-2.md` for the team review.

## 3. After the review

Squash and merge into `main` only after the team approves it, then tag it:

```bash
git checkout main
git pull origin main
git tag -a v1.3 -m "Block 9: the Director, tutorial and Expediente"
git push origin v1.3
```
