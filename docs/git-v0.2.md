# Git workflow for v0.2

From Block 2 on, each block is delivered through a **pull request** that another team member reviews and approves before it reaches `main`.

## 1. Branch and pull request

Block 2 lives in the branch `feature/v0.2-defenders`, with one pull request into `main`:

```bash
git checkout -b feature/v0.2-defenders
git add .
git commit -m "feat(v0.2): defenders, energy economy and placement on the board"
git push -u origin feature/v0.2-defenders
```

Then open the pull request on GitHub (*Compare & pull request*) with base `main`.

## 2. Review and merge

A teammate reviews the code and approves it. Merge it with **Squash and merge** so `main` gets a single commit for the block:

```
feat(v0.2): defenders, energy economy and placement on the board
```

## 3. Update your local copy and tag the version

After the merge, every team member updates `main`:

```bash
git checkout main
git stash -u            # set aside local copies of the same files, if any
git pull origin main
git stash drop          # those copies are already in main
```

Only one person creates and pushes the version tag:

```bash
git tag -a v0.2 -m "Block 2: Defenders and energy economy"
git push origin v0.2
```

If `git status` lists v0.1 files as modified even though their content did not change, the cause is Windows line endings (CRLF). Fix it once with:

```bash
git config core.autocrlf true
```
