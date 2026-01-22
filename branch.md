# ブランチ運用ガイド

## 概要

本リポジトリでは、シンプルな2層構造のブランチフローを採用しています。

```
feature/issue-#* → staging-#* → main
```

## ブランチ構成

| ブランチ | 説明 | 作成元 | マージ先 |
|----------|------|--------|----------|
| `main` | 本番環境 | - | - |
| `staging-#{PR番号}` | 機能検証 | main (自動) | main |
| `feature/issue-#{issue番号}` | 機能開発 | main | staging-#* |

## ブランチフロー図

```
main ─────────────────────────────────────────────────────▶
  │                                              ▲
  │                                              │ squash マージ
  ▼                                              │
staging-#4 ──────────────────────────────────────┴────────▶
  │                              ▲
  │                              │ マージ
  ▼                              │
feature/issue-#1 ────────────────┴────────────────────────▶
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

## ワークフロー

### 1. 機能開発の開始

```bash
# main から feature ブランチを作成
git fetch origin main
git checkout -b feature/issue-#123 origin/main

# 作業・コミット
git add .
git commit -m "feat: 機能の実装"

# プッシュ
git push -u origin feature/issue-#123
```

### 2. PR 作成 (feature → main)

1. GitHub で PR を作成
2. **Base ブランチ**: `main` を選択
3. **Head ブランチ**: `feature/issue-#123` を選択
4. PR 作成後、GitHub Actions が自動で:
   - `staging-#{PR番号}` を main から作成
   - PR のベースを `staging-#{PR番号}` に変更

### 3. コードレビュー・マージ (feature → staging)

**レビュー観点**:
- コード品質
- 実装の正確性
- テストの妥当性

```bash
# レビュー後、GitHub でマージ（通常のマージ）
# feature ブランチは削除可能
```

### 4. PR 作成・マージ (staging → main)

```bash
# staging-#4 から main への PR を作成
gh pr create --base main --head staging-#4 --title "Issue #1: 機能の統合"
```

**レビュー観点**:
- Issue/機能要件が正しく実装されているか
- リリース可否の判断
- 本番環境への影響確認

**マージ時**: **squash マージ**を使用し、staging の複数コミットを単一コミットに圧縮

## マージ方式

| 統合 | 方式 | 理由 |
|------|------|------|
| feature → staging | **マージ** | 機能開発の履歴を保持（デバッグ時に有用） |
| staging → main | **squash マージ** | mainの履歴をクリーンに保つ（1機能 = 1コミット） |

> **この独自戦略のメリット**:
> - staging-#* では詳細な開発履歴を参照可能
> - main では機能単位のクリーンな履歴を維持
> - 両方の利点を活かしたハイブリッドアプローチ

## リリース管理

バージョン管理はリリースタグで行います。

```bash
# リリースタグの作成
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### セマンティックバージョニング

| バージョン | 説明 |
|-----------|------|
| `v1.0.0` → `v1.0.1` | パッチ（バグ修正） |
| `v1.0.0` → `v1.1.0` | マイナー（新機能、後方互換） |
| `v1.0.0` → `v2.0.0` | メジャー（破壊的変更） |

## 禁止事項

| 操作 | 理由 |
|------|------|
| `feature/*` → `main` への直接マージ | staging での検証をスキップしてしまう |
| 共有ブランチでのリベース | 履歴の改変により他の開発者に影響 |
| force push | 履歴の改変により他の開発者に影響 |

## ブランチ保護ルール

### main

- PR 必須
- レビュー必須 (1人以上)
- ステータスチェック必須
- force push 禁止
- 削除禁止
- `staging-#*` からのマージのみ許可

### staging-#*

- PR 必須
- レビュー必須 (1人以上)
- force push 禁止
- `feature/issue-#*` からのマージのみ許可

## GitHub Actions

### create-staging-branch.yml

- **トリガー**: `main` へのPR作成時
- **条件**: ソースブランチが `feature/issue-#*` 形式の場合のみ
- **動作**:
  1. ソースブランチが `feature/issue-#*` 形式か検証
  2. `staging-#{PR番号}` を main から作成
  3. PR のベースブランチを変更

### validate-pr-to-main.yml

- **トリガー**: `main` へのPR（featureブランチからの場合はスキップ）
- **動作**: ソースが `staging-#*` か検証

### cleanup-staging-branch.yml

- **トリガー**: `staging-#*` へのPRがクローズされた時
- **条件**: マージされずにクローズされた場合のみ
- **動作**: 不要になった `staging-#*` ブランチを自動削除

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
| pre-commit | コミット前 | mainへの直接コミット | 警告 |
| commit-msg | コミット後 | Conventional Commits形式 | 警告 |
| commit-msg | コミット後 | 1行目が72文字以内 | 警告 |
| pre-push | プッシュ前 | ブランチ名の命名規則 | **エラー** |
| pre-push | プッシュ前 | featureがmainから遅れている | 警告 |
| pre-push | プッシュ前 | mainへの直接プッシュ | 警告 |

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

## 複数 staging の並行運用

リリース時期が異なる機能を並行開発する場合、複数の staging ブランチを使用できます。

```
staging-#4  ← feature/issue-#1 (v1.1 リリース向け)
staging-#7  ← feature/issue-#5 (v1.2 リリース向け)
staging-#10 ← feature/issue-#8 (v1.2 リリース向け)
```

**マージ順序の例**:
1. `staging-#4` → `main` (v1.1 リリース、タグ: v1.1.0)
2. `staging-#7`, `staging-#10` → `main` (v1.2 リリース、タグ: v1.2.0)

## トラブルシューティング

### PR作成時に staging ブランチが自動作成されない

1. ソースブランチが `feature/issue-#*` 形式か確認
2. ターゲットブランチが `main` か確認
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

本リポジトリの2層ブランチ戦略と、世界で広く使われている他のブランチ戦略を比較します。

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

#### 5. 本リポジトリの2層戦略

```
main ←── staging-#* ←── feature/issue-#*
```

| 項目 | 内容 |
|------|------|
| 特徴 | PR番号付きstagingブランチ、自動作成、ハイブリッドマージ |
| メリット | 並行検証が可能、Issue追跡が明確、履歴管理が柔軟 |
| デメリット | 独自戦略のため学習コスト |
| 適用 | 中規模チーム、レビュー重視、並行開発 |

### 戦略比較マトリクス

| 戦略 | PR数 | 複雑度 | CI/CD適性 | 並行開発 | 履歴の見やすさ |
|------|------|--------|-----------|----------|----------------|
| Trunk-Based | 1 | 低 | ◎ | △ | △ |
| GitHub Flow | 1 | 低 | ◎ | △ | △ |
| GitFlow | 3+ | 高 | △ | ◎ | ○ |
| GitLab Flow | 2 | 中 | ○ | ○ | ○ |
| **本戦略** | 2 | 中 | ○ | ◎ | ◎ |

### 本戦略の独自性：ハイブリッドマージ

本戦略の最大の特徴は、**マージ方式を段階で使い分ける**点です。

```
feature/issue-#1 ──(マージ)──▶ staging-#4 ──(squash)──▶ main
      │                              │                    │
      ▼                              ▼                    ▼
   詳細な履歴を保持         履歴を参照可能        クリーンな履歴
```

**メリット**:
- staging-#* では開発中の詳細なコミット履歴を参照可能（デバッグに有用）
- main では1機能 = 1コミットのクリーンな履歴を維持
- `git bisect` や `git blame` が main 上で効果的に機能

### 環境ブランチのアンチパターン

近年、環境ごとにブランチを分ける戦略（dev/staging/prod）は**アンチパターン**として指摘されています。

**問題点**:
- 同一コードが各環境で異なるバイナリになるリスク
- Cherry-pickによる複雑なマージ管理
- 環境固有のコードによる構成ドリフト

**本戦略での対応**:
- `staging-#*` は**環境ブランチではなくレビューブランチ**
- 同一コードがそのままmainへ流れる
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
- GitHub Flow のシンプルさを維持しつつ、レビュー層を追加
- GitFlow ほど複雑ではないが、並行開発をサポート
- PR番号に紐づくstagingブランチで機能単位の追跡が明確
- 環境ブランチのアンチパターンを回避（staging-#*は短命）
- ハイブリッドマージで履歴管理の柔軟性を確保

### 戦略選択のガイドライン

| チーム状況 | 推奨戦略 |
|-----------|----------|
| 経験豊富 + 高度なCI/CD | Trunk-Based |
| 小規模 + 高速リリース | GitHub Flow |
| 大規模 + 規制産業 | GitFlow |
| 中規模 + レビュー重視 + 並行開発 | **本戦略** |

### 参考資料

- [Atlassian Git Tutorials - Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Trunk Based Development](https://trunkbaseddevelopment.com/)
- [GitLab Flow Best Practices](https://about.gitlab.com/topics/version-control/what-are-gitlab-flow-best-practices/)
- [Martin Fowler - Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html)
- [Stop Using Branches for Deploying to Different GitOps Environments](https://codefresh.io/blog/stop-using-branches-deploying-different-gitops-environments/)
