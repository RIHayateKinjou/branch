# /release-pr スキル

developからmainへのリリースPRを作成する。

## 引数

- `title` (任意): PRタイトル（省略時は日付ベースで生成）

## 前提条件

- developブランチがリモートに存在すること
- developにリリース対象の変更がマージ済みであること

## 実行手順

1. developブランチの最新を確認する
   ```bash
   git fetch origin develop
   git fetch origin main
   ```

2. develop と main の差分を確認する
   ```bash
   git log origin/main..origin/develop --oneline
   ```
   - 差分がない場合は警告を表示

3. PRタイトルを決定する
   - 引数で指定されていればそれを使用
   - なければ `Release YYYY-MM-DD` 形式で生成

4. PRボディを生成する
   - develop に含まれる変更の概要
   - マージされたPRの一覧

5. PRを作成する
   ```bash
   gh pr create --base main --head develop --title "<title>" --body "<body>"
   ```

6. 結果を表示する
   - PR URL
   - レビュー観点（リリース可否の判断）
   - 含まれる変更の一覧

## エラーハンドリング

- developブランチが存在しない場合: エラーメッセージを表示
- develop と main に差分がない場合: 警告を表示して確認
- PR作成に失敗した場合: エラー詳細を表示

## 例

```
/release-pr
→ Release 2025-01-22 というタイトルで PR を作成

/release-pr v1.2.0 リリース
→ カスタムタイトルで PR を作成
```
