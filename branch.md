# ブランチ運用ガイド

## 概要

本リポジトリでは、4層構造のブランチフローを採用しています。

```
feature/issue-#* → staging-#* → develop → main
```

## ブランチ構成

| ブランチ | 説明 | 作成元 | マージ先 |
|----------|------|--------|----------|
| `main` | 本番環境 | - | - |
| `develop` | 開発統合 | main | main |
| `staging` | プレースホルダー | develop | - |
| `staging-#{PR番号}` | 機能検証 | develop (自動) | develop |
| `feature/issue-#{issue番号}` | 機能開発 | develop | staging-#* |

## ブランチフロー図

```
main ─────────────────────────────────────────────────────▶
  │                                              ▲
  │                                              │ マージ
  ▼                                              │
develop ──────────────────────────────────────────┴───────▶
  │                              ▲
  │                              │ マージ
  ▼                              │
staging-#4 ──────────────────────┴────────────────────────▶
  │              ▲
  │              │ マージ
  ▼              │
feature/issue-#1 ┴────────────────────────────────────────▶
```

## 命名規則

### feature ブランチ

```
feature/issue-#{issue番号}
feature/issue-#{issue番号}-{説明}
```

**例**:
- `feature/issue-#123`
- `feature/issue-#456-add-login`

### staging ブランチ

```
staging-#{PR番号}
```

**例**:
- `staging-#4`
- `staging-#15`

> **注**: `staging` (番号なし) はプレースホルダーとして使用され、直接マージされることはありません。

## ワークフロー

### 1. 機能開発の開始

```bash
# develop から feature ブランチを作成
git fetch origin develop
git checkout -b feature/issue-#123 origin/develop

# 作業・コミット
git add .
git commit -m "feat: 機能の実装"

# プッシュ
git push -u origin feature/issue-#123
```

### 2. PR 作成 (feature → staging)

1. GitHub で PR を作成
2. **Base ブランチ**: `staging` (プレースホルダー) を選択
3. **Head ブランチ**: `feature/issue-#123` を選択
4. PR 作成後、GitHub Actions が自動で:
   - `staging-#{PR番号}` を develop から作成
   - PR のベースを `staging-#{PR番号}` に変更

### 3. コードレビュー・マージ (feature → staging)

**レビュー観点**:
- コード品質
- 実装の正確性
- テストの妥当性

```bash
# レビュー後、GitHub でマージ
# feature ブランチは削除可能
```

### 4. PR 作成 (staging → develop)

```bash
# staging-#4 から develop への PR を作成
gh pr create --base develop --head staging-#4 --title "Issue #1: 機能の統合"
```

**レビュー観点**:
- Issue/機能要件が正しく実装されているか
- 他の機能との整合性

### 5. PR 作成 (develop → main)

```bash
# develop から main への PR を作成
gh pr create --base main --head develop --title "Release 2025-01-22"
```

**レビュー観点**:
- リリース可否の判断
- 本番環境への影響確認
- リリースタイミングの妥当性

## 禁止事項

| 操作 | 理由 |
|------|------|
| `feature/*` → `develop` への直接 PR | staging での検証をスキップしてしまう |
| `feature/*` → `main` への直接 PR | develop での統合をスキップしてしまう |
| `staging-#*` → `main` への直接 PR | develop での統合をスキップしてしまう |
| 共有ブランチでのリベース | 履歴の改変により他の開発者に影響 |
| force push | 履歴の改変により他の開発者に影響 |

## マージ方式

| 統合 | 方式 | 理由 |
|------|------|------|
| feature → staging | マージ | 機能単位の履歴を保持 |
| staging → develop | マージ | 検証単位の履歴を保持 |
| develop → main | マージ | リリース単位の履歴を保持 |

> **リベースの使用**: ローカルでの未プッシュコミット整理のみ許可

## ブランチ保護ルール

### main

- PR 必須
- レビュー必須 (1人以上)
- ステータスチェック必須
- force push 禁止
- 削除禁止
- `develop` からのマージのみ許可

### develop

- PR 必須
- レビュー必須 (1人以上)
- ステータスチェック必須
- force push 禁止
- 削除禁止
- `staging-#*` からのマージのみ許可

### staging-#*

- PR 必須
- レビュー必須 (1人以上)
- ステータスチェック必須
- force push 禁止
- `feature/issue-#*` からのマージのみ許可

### staging (プレースホルダー)

- 直接プッシュ禁止
- PR 作成時のベースブランチとしてのみ使用
- マージされることはない

## GitHub Actions

### create-staging-branch.yml

- **トリガー**: `staging` へのPR作成時
- **動作**:
  1. ソースブランチが `feature/issue-#*` 形式か検証
  2. `staging-#{PR番号}` を develop から作成
  3. PR のベースブランチを変更

### validate-pr-to-main.yml

- **トリガー**: `main` へのPR
- **動作**: ソースが `develop` か検証

### validate-pr-to-develop.yml

- **トリガー**: `develop` へのPR
- **動作**: ソースが `staging-#*` か検証

### validate-pr-to-staging.yml

- **トリガー**: `staging-#*` へのPR
- **動作**: ソースが `feature/issue-#*` か検証

## Claude Code Skills

| コマンド | 説明 |
|----------|------|
| `/feature <issue番号> [説明]` | feature ブランチを作成 |
| `/pr [タイトル]` | feature → staging PR を作成 |
| `/staging-pr <PR番号> [タイトル]` | staging → develop PR を作成 |
| `/release-pr [タイトル]` | develop → main PR を作成 |
| `/branch-status` | 現在のブランチ状況を表示 |

## 複数 staging の運用

リリース時期が異なる機能を並行開発する場合、複数の staging ブランチを使用できます。

```
staging-#4  ← feature/issue-#1 (v1.1 リリース向け)
staging-#7  ← feature/issue-#5 (v1.2 リリース向け)
staging-#10 ← feature/issue-#8 (v1.2 リリース向け)
```

**マージ順序の例**:
1. `staging-#4` → `develop` → `main` (v1.1 リリース)
2. `staging-#7`, `staging-#10` → `develop` → `main` (v1.2 リリース)

## トラブルシューティング

### PR作成時に「staging ブランチが見つからない」

`staging` プレースホルダーブランチが存在するか確認してください。

```bash
git fetch origin
git branch -r | grep staging
```

### GitHub Actions が staging ブランチを作成しない

1. ソースブランチが `feature/issue-#*` 形式か確認
2. ターゲットブランチが `staging` (プレースホルダー) か確認
3. Actions のログを確認

### 間違ったブランチにマージしてしまった

1. マージコミットを特定
2. revert PR を作成
3. 正しいブランチに再度 PR を作成
