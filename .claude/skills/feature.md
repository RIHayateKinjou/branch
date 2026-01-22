# /feature スキル

Issue番号を指定してfeatureブランチを作成する。

## 引数

- `issue_number` (必須): Issue番号
- `description` (任意): ブランチの説明（ケバブケース）

## 実行手順

1. 引数を解析する
   - 第1引数: Issue番号（数字のみ）
   - 第2引数以降: 説明（あれば）

2. developブランチの最新を取得する
   ```bash
   git fetch origin develop
   ```

3. ブランチ名を決定する
   - 説明なし: `feature/issue-#<issue_number>`
   - 説明あり: `feature/issue-#<issue_number>-<description>`

4. 新しいブランチを作成してチェックアウトする
   ```bash
   git checkout -b <branch_name> origin/develop
   ```

5. 結果を表示する
   - 作成したブランチ名
   - 次のステップ（作業後に `/pr` でPR作成）

## エラーハンドリング

- Issue番号が指定されていない場合: エラーメッセージを表示
- Issue番号が数字でない場合: エラーメッセージを表示
- 同名のブランチが既に存在する場合: 確認を求める

## 例

```
/feature 123
→ feature/issue-#123 を作成

/feature 456 add-user-authentication
→ feature/issue-#456-add-user-authentication を作成
```
