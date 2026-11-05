# Git workflow for v1.5

v1.5 closes Block 11 (IPN locations and audio). It is delivered as a pull request, like the previous blocks.

## 1. Branch and commit

```bash
git checkout main
git pull origin main
git checkout -b feature/v1.5-scenery-audio
```

Open the project once in Godot 4.7 so it imports the new audio, font and pictures (it creates their `.import` and `.uid` files, which are committed too). Then:

```bash
git add audio art/backgrounds art/fonts art/map art/scenery data docs project.godot \
        scenes scripts tools README.md
git status   # check: no "Claude outputs/", no .godot/
git commit -m "v1.5: Block 11 - IPN locations and audio"
```

## 2. Push and open the pull request

```bash
git push -u origin feature/v1.5-scenery-audio
```

On GitHub: *Compare & pull request*, base `main`, title `v1.5: Block 11 - IPN locations and audio`. Details, node hierarchy, the background pipeline and tests: `docs/tech-note-v1.5.md`.

## 3. After the review

**Squash and merge** into `main` only after the team approves it, then tag it:

```bash
git checkout main
git pull origin main
git tag -a v1.5 -m "Block 11: IPN locations and audio"
git push origin v1.5
```

Android preset on each laptop: version/name `1.5`, version/code `6`, and the **Vibrate** permission turned on.
