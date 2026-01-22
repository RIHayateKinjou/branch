# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ブランチ運用を管理するためのGitHub Actionsを格納するリポジトリ。

## Repository Structure

```
.github/
  workflows/     # GitHub Actions workflow definitions
  actions/       # Reusable composite actions (if any)
```

## Development

### Testing Workflows Locally

GitHub Actionsのローカルテストには[act](https://github.com/nektos/act)を使用:

```bash
# ワークフローの一覧表示
act -l

# 特定のワークフローを実行
act -j <job-name>

# イベントを指定して実行
act push
act pull_request
```

### Workflow Syntax Validation

```bash
# actionlintでワークフロー構文をチェック
actionlint .github/workflows/*.yml
```

## Conventions

- ワークフローファイルは`.github/workflows/`に配置
- 再利用可能なアクションは`.github/actions/`に配置
- ワークフロー名はケバブケース（例: `branch-cleanup.yml`）

## Branch Workflow

### ブランチフロー

```
feature/issue-#* → staging-* → develop → main
                (マージ)    (マージ)  (マージ)
```

### ルール

- **マージのみ使用**: リベースはローカルのコミット整理のみ許可
- **PR必須**: 全てのブランチ統合はPR経由
- **レビュー必須**: 全PRに1人以上のレビュー

### レビュー観点

| PR | 観点 |
|----|------|
| feature → staging | コード品質、実装の正確性 |
| staging → develop | Issue/機能要件が正しく実装されているか |
| develop → main | リリース可否の判断 |

## Skills

### /feature

Issue番号を指定してfeatureブランチを作成する。

**使用方法**: `/feature <issue番号> [説明]`

**実行内容**:
1. developブランチから最新を取得
2. `feature/issue-#<issue番号>` または `feature/issue-#<issue番号>-<説明>` ブランチを作成
3. 新しいブランチにチェックアウト

**例**:
- `/feature 123` → `feature/issue-#123`
- `/feature 123 add-login` → `feature/issue-#123-add-login`

### /pr

現在のfeatureブランチからPRを作成する。

**使用方法**: `/pr [タイトル]`

**実行内容**:
1. 現在のブランチが `feature/issue-#*` 形式か確認
2. 変更をプッシュ
3. develop向けにPRを作成（GitHub Actionsがstagingブランチを自動作成しベースを変更）

**注意**: PRタイトルが省略された場合はブランチ名から生成

### /staging-pr

stagingブランチからdevelopへのPRを作成する。

**使用方法**: `/staging-pr <PR番号> [タイトル]`

**実行内容**:
1. `staging-<PR番号>` ブランチの存在を確認
2. develop向けにPRを作成

### /release-pr

developからmainへのリリースPRを作成する。

**使用方法**: `/release-pr [タイトル]`

**実行内容**:
1. developブランチの最新を確認
2. main向けにPRを作成

### /branch-status

現在のブランチ状況を表示する。

**使用方法**: `/branch-status`

**実行内容**:
1. 現在のブランチ名を表示
2. ローカルとリモートの差分を表示
3. 未コミットの変更を表示
4. ブランチフローにおける現在位置を表示
