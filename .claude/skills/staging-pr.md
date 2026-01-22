# /staging-pr スキル

stagingブランチからdevelopへのPRを作成する。

## 引数

- `pr_number` (必須): stagingブランチのPR番号
- `title` (任意): PRタイトル

## 前提条件

- `staging-<pr_number>` ブランチがリモートに存在すること
- 対象のfeature PRがstagingにマージ済みであること

## 実行手順

1. 引数を解析する
   - 第1引数: PR番号（数字のみ）
   - 第2引数以降: タイトル（あれば）

2. stagingブランチの存在を確認する
   ```bash
   git ls-remote --heads origin staging-<pr_number>
   ```

3. stagingブランチをフェッチする
   ```bash
   git fetch origin staging-<pr_number>
   ```

4. PRタイトルを決定する
   - 引数で指定されていればそれを使用
   - なければ `Merge staging-<pr_number> into develop`

5. PRを作成する
   ```bash
   gh pr create --base develop --head staging-<pr_number> --title "<title>" --body "<body>"
   ```

6. 結果を表示する
   - PR URL
   - レビュー観点（Issue/機能要件が正しく実装されているか）

## エラーハンドリング

- PR番号が指定されていない場合: エラーメッセージを表示
- stagingブランチが存在しない場合: エラーメッセージを表示
- PR作成に失敗した場合: エラー詳細を表示

## 例

```
/staging-pr 456
→ staging-456 から develop への PR を作成

/staging-pr 456 ユーザー認証機能の統合
→ カスタムタイトルで PR を作成
```
