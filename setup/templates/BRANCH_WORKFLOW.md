# Branch Workflow Guide

## Overview

This repository uses a **2-layer branch strategy** for organized development and clean release management.

```
feature/issue-#* → staging-#* → main
```

## Branch Types

| Branch | Purpose | Naming |
|--------|---------|--------|
| `main` | Production-ready code | Fixed name |
| `staging-#*` | Integration branch per issue | `staging-#123` |
| `feature/issue-#*` | Development work | `feature/issue-#123` |

## Workflow

### 1. Start Feature Development

```bash
git checkout main
git pull origin main
git checkout -b feature/issue-#123
```

### 2. Create Pull Request

When ready for review, create a PR from `feature/issue-#*` to `main`.

**Automatic Action**: GitHub Actions will automatically:
1. Create `staging-#123` branch from `main`
2. Change PR base from `main` to `staging-#123`
3. Post a comment explaining the change

### 3. Code Review on Staging Branch

- PR is reviewed on `staging-#*` branch
- Requires 1 approval (configurable)
- Use **Merge** (not squash) to preserve commit history

### 4. Merge to Main

After staging PR is merged:
1. Create new PR from `staging-#123` to `main`
2. Use **Squash and merge** for clean history
3. Staging branch is deleted automatically after merge

## Merge Strategy

| Merge Type | When | Method |
|------------|------|--------|
| feature → staging | After review approval | **Merge** (preserve history) |
| staging → main | After integration complete | **Squash** (clean history) |

## Branch Protection

### main branch
- Requires PR (no direct push)
- Requires status check: `validate-main`
- Only accepts PRs from `staging-#*` branches

### staging-#* branches
- Requires PR (no direct push)
- Requires 1 approval
- All review threads must be resolved

## Git Hooks

| Hook | Purpose |
|------|---------|
| `pre-commit` | Validate branch naming convention |
| `pre-push` | Prevent direct push to protected branches |
| `commit-msg` | Enforce commit message format |

### Enable Git Hooks

```bash
git config core.hooksPath .githooks
```

## GitHub Actions

| Workflow | Trigger | Action |
|----------|---------|--------|
| `create-staging-branch.yml` | PR to main from feature branch | Create staging branch, change PR base |
| `validate-pr-to-main.yml` | PR to main | Validate source is staging-#* branch |
| `cleanup-staging-branch.yml` | PR closed without merge | Delete orphaned staging branch |

## Quick Reference

```bash
# Start new feature
git checkout -b feature/issue-#123 main

# Push and create PR (PR will auto-redirect to staging branch)
git push -u origin feature/issue-#123
# Then create PR to main via GitHub UI

# After staging PR merged, create PR from staging-#123 to main
# Use "Squash and merge" for the final merge
```
