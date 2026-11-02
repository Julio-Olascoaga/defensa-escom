# Git workflow for v0.5

Block 5 is delivered as a pull request, like Blocks 2 to 4.

## 1. Branch, copy the files and push

Start from an up-to-date `main` (v0.4) with no local changes:

```bash
git checkout main
git pull origin main
git checkout -b feature/v0.5-save
```

Copy the contents of the `defensa-escom/` folder of the delivery zip over the project folder (it only contains new and modified files, in their final paths), then:

```bash
git add .
git status            # check the list against CHANGES-v0.5.txt
git commit -m "feat(v0.5): save progress to user://progress.cfg, loading screen and error states"
git push -u origin feature/v0.5-save
```

Open the pull request on GitHub (*Compare & pull request*) with base `main`. The title and description are in `PR-v0.5.md` in the zip.

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
git tag -a v0.5 -m "Block 5: Save, load and error states"
git push origin v0.5
```
