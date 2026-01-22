# Git Hooks

ブランチ運用ルールを自動でチェックするGit Hooksです。

## セットアップ

```bash
# hooksディレクトリを設定
git config core.hooksPath .githooks

# 実行権限を付与（必要な場合）
chmod +x .githooks/*
```

## 提供されるHooks

### pre-commit

コミット前に実行されます。

**チェック内容:**
- ブランチ名が命名規則に従っているか（警告）
- 保護ブランチへの直接コミット（警告）

### commit-msg

コミットメッセージの作成後に実行されます。

**チェック内容:**
- Conventional Commits形式か（警告）
- 1行目が72文字以内か（警告）

### pre-push

プッシュ前に実行されます。

**チェック内容:**
- ブランチ名が命名規則に従っているか（エラー）
- featureブランチがmainの最新から分岐しているか（警告）
- mainへの直接プッシュ（警告）

## ブランチ命名規則

| パターン | 例 |
|----------|-----|
| `main` | 本番環境ブランチ |
| `staging-#{PR番号}` | `staging-#4` |
| `feature/issue-#{issue番号}` | `feature/issue-#123` |
| `feature/issue-#{issue番号}-{説明}` | `feature/issue-#123-add-login` |

## Conventional Commits

推奨されるコミットメッセージ形式:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### タイプ一覧

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

## 厳格モードへの変更

警告をエラーに変更したい場合は、各hookファイル内の `# exit 1` のコメントを外してください。

## Hooksの無効化

一時的に無効にする場合:

```bash
# 特定のコミットでスキップ
git commit --no-verify -m "message"

# 特定のプッシュでスキップ
git push --no-verify
```

恒久的に無効にする場合:

```bash
git config --unset core.hooksPath
```
