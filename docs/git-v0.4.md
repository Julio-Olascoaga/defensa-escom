# Git workflow for v0.4

Block 4 is delivered as a pull request, like Blocks 2 and 3.

## 0. Tag v0.3 (if nobody has done it yet)

```bash
git checkout main
git pull origin main
git tag -a v0.3 -m "Block 3: Enemies and combat"
git push origin v0.3
```

## 1. Branch, copy the files and push

Start from an up-to-date `main` (v0.3) with no local changes:

```bash
git checkout main
git pull origin main
git checkout -b feature/v0.4-levels
```

Copy the contents of the `defensa-escom/` folder of the delivery zip over the project folder (it only contains new and modified files, in their final paths), then:

```bash
git add .
git status            # check the list against CHANGES-v0.4.txt
git commit -m "feat(v0.4): data-driven levels, WaveManager, ProgressRepository and victory panel"
git push -u origin feature/v0.4-levels
```

Open the pull request on GitHub (*Compare & pull request*) with base `main`.

## 2. Review and merge

A teammate reviews and approves it, then merges it into `main` (*Squash and merge*).

## 3. Update your local copy and tag the version

After the merge, every team member updates `main`:

```bash
git checkout main
git stash -u          # only if you have local changes
git pull origin main
git stash pop         # brings your changes back (never "drop" without checking)
```

Only one person creates and pushes the version tag:

```bash
git tag -a v0.4 -m "Block 4: Data-driven levels and world flow"
git push origin v0.4
```
