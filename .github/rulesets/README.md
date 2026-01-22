# Branch Rulesets

このディレクトリには GitHub Rulesets の設定ファイルが含まれています。

## ブランチフロー

```
feature/issue-#* → staging-* → develop → main
                 (機能実装)  (機能確認)  (リリース確認)
```

## ファイル構成

| ファイル | 対象ブランチ | 目的 |
|----------|-------------|------|
| main-branch.json | main | リリース保護 |
| develop-branch.json | develop | 統合ブランチ保護 |
| staging-branch.json | staging-* | 機能検証ブランチ保護 |

## 保護ルール

### 共通ルール

| 設定 | 値 |
|------|-----|
| PR 必須 | ✅ |
| レビュー必須 | 1人以上 |
| ステータスチェック必須 | validate ジョブ |
| force push 禁止 | ✅ |
| 古いレビューの却下 | ✅ |
| レビュースレッド解決必須 | ✅ |

### ブランチ別ルール

| ブランチ | 削除禁止 | PRソース制限 |
|----------|---------|-------------|
| main | ✅ | develop のみ |
| develop | ✅ | staging-* のみ |
| staging-* | ❌ | feature/issue-#* のみ |

## レビュー観点

### develop → main (リリースレビュー)

- リリース対象の機能に問題がないか
- 本番環境への影響確認
- リリースタイミングの妥当性

### staging-* → develop (機能レビュー)

- Issue/機能要件が正しく実装されているか
- コード品質の確認
- テストの妥当性

## 適用手順

### GitHub UI からインポート

1. リポジトリの **Settings** → **Rules** → **Rulesets** を開く
2. **New ruleset** → **Import a ruleset** をクリック
3. JSON ファイルを選択してインポート
4. 以下の順序でインポートを実行:
   - `main-branch.json`
   - `develop-branch.json`
   - `staging-branch.json`

### GitHub CLI からインポート

```bash
# main branch ruleset
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --input .github/rulesets/main-branch.json

# develop branch ruleset
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --input .github/rulesets/develop-branch.json

# staging branch ruleset
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --input .github/rulesets/staging-branch.json
```

## 関連ワークフロー

| ワークフロー | 役割 |
|-------------|------|
| create-staging-branch.yml | staging ブランチ自動作成 |
| validate-pr-to-main.yml | main への PR 検証 |
| validate-pr-to-develop.yml | develop への PR 検証 |
| validate-pr-to-staging.yml | staging への PR 検証 |

## 注意事項

- Rulesets を有効にする前に、対象ブランチ (main, develop) が存在することを確認してください
- ステータスチェックは、ワークフローが一度実行されるまで選択肢に表示されない場合があります
