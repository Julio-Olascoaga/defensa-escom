# Git workflow for v1.4

v1.4 closes Block 10 (cut-out animation and progressive damage) and fixes the two findings of the Block 9 review. It is delivered as a pull request, like the previous blocks.

## 1. Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.4-animation
```

Copy the contents of the delivered `defensa-escom/` folder over the root of the repository (it only has the files that go into the repo; `CHANGES-v1.4.txt` and `extra-screenshots/` are for the review and are not committed). Then open the project once in Godot 4.7 so it imports the new images.

## 2. Commits

Three commits: first the two v1.3 fixes, each on its own, then the block.

```bash
git add scripts/engine/tutorial.gd
git commit -m "v1.4: fix tutorial softlock when erasing Café"

git add scripts/ui/pause_hidden_layer.gd scripts/ui/pause_hidden_layer.gd.uid scenes/game/tutorial.tscn
git commit -m "v1.4: hide tutorial pointer under pause menu"

git add -A
git status   # check: no CHANGES-v1.4.txt, no extra-screenshots/, no .godot/
git commit -m "v1.4: Block 10 - cut-out animation and progressive damage"
```

## 3. Push and open the pull request

```bash
git push -u origin feature/v1.4-animation
```

On GitHub: *Compare & pull request*, base `main`, title `v1.4: Block 10 - cut-out animation and progressive damage` (the description is in `PR-v1.4.md` of the delivery). Details, node hierarchy, the cutting pipeline and tests: `docs/tech-note-v1.4.md`.

## 4. After the review

**Squash and merge** into `main` only after the team approves it, then tag it:

```bash
git checkout main
git pull origin main
git tag -a v1.4 -m "Block 10: cut-out animation and progressive damage"
git push origin v1.4
```

Android preset on each laptop: version/name `1.4`, version/code `5`.
