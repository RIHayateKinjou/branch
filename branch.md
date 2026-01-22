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

## Git Hooks (ローカル検証)

コミット・プッシュ時にブランチ運用ルールをローカルで検証するGit Hooksを提供しています。

### セットアップ

```bash
# hooks ディレクトリを設定
git config core.hooksPath .githooks
```

### 提供されるHooks

| Hook | タイミング | チェック内容 | 動作 |
|------|-----------|-------------|------|
| pre-commit | コミット前 | ブランチ名の命名規則 | 警告 |
| pre-commit | コミット前 | 保護ブランチへの直接コミット | 警告 |
| commit-msg | コミット後 | Conventional Commits形式 | 警告 |
| commit-msg | コミット後 | 1行目が72文字以内 | 警告 |
| pre-push | プッシュ前 | ブランチ名の命名規則 | **エラー** |
| pre-push | プッシュ前 | featureがdevelopから遅れている | 警告 |
| pre-push | プッシュ前 | 保護ブランチへの直接プッシュ | 警告 |
| pre-push | プッシュ前 | stagingプレースホルダーへのプッシュ | **エラー** |

### Conventional Commits

推奨されるコミットメッセージ形式:

```
<type>(<scope>): <description>
```

| タイプ | 説明 |
|--------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更 |
| `refactor` | バグ修正や機能追加ではないコード変更 |
| `perf` | パフォーマンス改善 |
| `test` | テストの追加・修正 |
| `build` | ビルドシステムや外部依存の変更 |
| `ci` | CI設定ファイルやスクリプトの変更 |
| `chore` | その他の変更 |

**例**:
- `feat: ログイン機能を追加`
- `fix(auth): トークン検証のバグを修正`

### Hooksのスキップ

一時的にHooksを無効にする場合:

```bash
# 特定のコミットでスキップ
git commit --no-verify -m "message"

# 特定のプッシュでスキップ
git push --no-verify
```

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

### Git Hooks が動作しない

1. hooks パスが設定されているか確認:
   ```bash
   git config core.hooksPath
   # .githooks と表示されればOK
   ```

2. 設定されていない場合:
   ```bash
   git config core.hooksPath .githooks
   ```

3. 実行権限を確認:
   ```bash
   ls -la .githooks/
   # -rwxr-xr-x と表示されればOK
   ```

4. 実行権限がない場合:
   ```bash
   chmod +x .githooks/*
   ```

### プッシュ時に「ブランチ名が命名規則に従っていません」エラー

ブランチ名を正しい形式に変更してください:

```bash
# 現在のブランチ名を変更
git branch -m old-branch-name feature/issue-#123

# リモートの古いブランチを削除して新しい名前でプッシュ
git push origin --delete old-branch-name
git push -u origin feature/issue-#123
```

## ブランチ戦略の比較

本リポジトリの4層ブランチ戦略と、世界で広く使われている他のブランチ戦略を比較します。

### 主要なブランチ戦略

#### 1. Trunk-Based Development (トランクベース開発)

**採用企業**: Google, Facebook (Meta), Microsoft

```
main (trunk) ←── feature (短命)
```

| 項目 | 内容 |
|------|------|
| 特徴 | 単一の永続ブランチ、短命なfeatureブランチ |
| メリット | マージ競合が少ない、CI/CDとの親和性が高い |
| デメリット | 高度なCI/CD基盤と経験豊富なチームが必要 |
| 適用 | 大規模組織、継続的デプロイ、モノレポ |

> Googleは1日40,000以上のコミットを単一トランクで管理

#### 2. GitHub Flow

**採用企業**: GitHub, 多くのスタートアップ

```
main ←── feature
```

| 項目 | 内容 |
|------|------|
| 特徴 | シンプル、mainへの直接マージ |
| メリット | 学習コストが低い、高速なリリース |
| デメリット | 複数バージョンの並行管理が困難 |
| 適用 | 小規模チーム、SaaS、継続的デリバリー |

#### 3. GitFlow

**提唱者**: Vincent Driessen (2010年)

```
main ←── release ←── develop ←── feature
                              ←── hotfix
```

| 項目 | 内容 |
|------|------|
| 特徴 | 複数の永続ブランチ、明確な役割分担 |
| メリット | 複数バージョンの並行管理、明確なリリース管理 |
| デメリット | 複雑、CI/CDとの親和性が低い |
| 適用 | 大規模チーム、計画的リリース、規制産業 |

> 2020年、提唱者自身がGitHub Flowを推奨するようになった

#### 4. GitLab Flow

```
main ←── staging ←── feature
     ←── production
```

| 項目 | 内容 |
|------|------|
| 特徴 | 環境ブランチ、upstream first ポリシー |
| メリット | GitFlowより簡潔、環境との対応が明確 |
| デメリット | 環境ブランチのアンチパターン問題 |
| 適用 | 中規模チーム、環境ごとのデプロイ |

#### 5. 本リポジトリの4層戦略

```
main ←── develop ←── staging-#* ←── feature/issue-#*
```

| 項目 | 内容 |
|------|------|
| 特徴 | PR番号付きstagingブランチ、自動作成 |
| メリット | 並行検証が可能、Issue追跡が明確 |
| デメリット | 独自戦略のため学習コスト |
| 適用 | 中規模チーム、レビュー重視、並行開発 |

### 戦略比較マトリクス

| 戦略 | ブランチ数 | 複雑度 | CI/CD適性 | 並行開発 | リリース管理 |
|------|-----------|--------|-----------|----------|--------------|
| Trunk-Based | 1 (+ 短命) | 低 | ◎ | △ | Feature Flag |
| GitHub Flow | 1 (+ 短命) | 低 | ◎ | △ | 継続的 |
| GitFlow | 5+ | 高 | △ | ◎ | 計画的 |
| GitLab Flow | 2-3 | 中 | ○ | ○ | 環境連動 |
| **本戦略** | 3 (+ 動的) | 中 | ○ | ◎ | 段階的 |

### 環境ブランチのアンチパターン

近年、環境ごとにブランチを分ける戦略（dev/staging/prod）は**アンチパターン**として指摘されています。

**問題点**:
- 同一コードが各環境で異なるバイナリになるリスク
- Cherry-pickによる複雑なマージ管理
- 環境固有のコードによる構成ドリフト

**本戦略での対応**:
- `staging-#*` は**環境ブランチではなくレビューブランチ**
- 同一コードがそのままdevelop → mainへ流れる
- staging-#*は検証完了後に削除される短命ブランチ

### 業界トレンド (2024-2025)

1. **Trunk-Based Development の台頭**
   - GitFlowの人気は低下傾向
   - Google, Facebook, Microsoftなど大企業が採用

2. **Feature Flag の普及**
   - ブランチではなくフラグでリリース制御
   - LaunchDarkly, Flagsmith などのツール

3. **モノレポの増加**
   - 複数プロジェクトを単一リポジトリで管理
   - Bazel, Pants, Buck などのビルドツール

### 本戦略の位置づけ

```
シンプル ◀──────────────────────────────────▶ 複雑
         GitHub Flow    本戦略    GitFlow
              │            │          │
              ▼            ▼          ▼
         継続的         段階的      計画的
         デリバリー     レビュー    リリース
```

**本戦略の特徴**:
- GitFlowほど複雑ではないが、GitHub Flowより段階的なレビューが可能
- PR番号に紐づくstagingブランチで並行検証をサポート
- 環境ブランチのアンチパターンを回避（staging-#*は短命）

### 戦略選択のガイドライン

| チーム状況 | 推奨戦略 |
|-----------|----------|
| 経験豊富 + 高度なCI/CD | Trunk-Based |
| 小規模 + 高速リリース | GitHub Flow |
| 大規模 + 規制産業 | GitFlow |
| 中規模 + レビュー重視 | **本戦略** または GitLab Flow |

### 参考資料

- [Atlassian Git Tutorials - Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Trunk Based Development](https://trunkbaseddevelopment.com/)
- [GitLab Flow Best Practices](https://about.gitlab.com/topics/version-control/what-are-gitlab-flow-best-practices/)
- [Martin Fowler - Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html)
- [Stop Using Branches for Deploying to Different GitOps Environments](https://codefresh.io/blog/stop-using-branches-deploying-different-gitops-environments/)
