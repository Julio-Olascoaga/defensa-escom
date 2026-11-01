# Git workflow for v0.3

Block 3 is delivered as a pull request, like Block 2.

## 1. Branch, copy the files and push

Start from an up-to-date `main` (v0.2) with no local changes:

```bash
git checkout main
git pull origin main
git checkout -b feature/v0.3-enemies
```

Copy the contents of the delivery zip over the project folder (it only contains new and modified files, in their final paths), then:

```bash
git add .
git status            # check the list against CHANGES-v0.3.txt
git commit -m "feat(v0.3): enemies, combat, test wave and defeat panel"
git push -u origin feature/v0.3-enemies
```

Open the pull request on GitHub (*Compare & pull request*) with base `main`.

## 2. Review and merge

A teammate reviews and approves it, then merges it into `main`.

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
git tag -a v0.3 -m "Block 3: Enemies and combat"
git push origin v0.3
```
