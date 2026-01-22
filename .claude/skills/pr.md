# /pr スキル

現在のfeatureブランチからPRを作成する。

## 引数

- `title` (任意): PRタイトル（省略時はブランチ名から生成）

## 前提条件

- 現在のブランチが `feature/issue-#*` 形式であること
- リモートリポジトリが設定されていること

## 実行手順

1. 現在のブランチ名を確認する
   ```bash
   git branch --show-current
   ```

2. ブランチ名が `feature/issue-#*` 形式か検証する
   - 形式が不正な場合はエラーを表示して終了

3. 未コミットの変更がないか確認する
   ```bash
   git status --porcelain
   ```
   - 変更がある場合は警告を表示

4. リモートにプッシュする
   ```bash
   git push -u origin <current_branch>
   ```

5. PRタイトルを決定する
   - 引数で指定されていればそれを使用
   - なければブランチ名から生成（例: `feature/issue-#123-add-login` → `Issue #123: add login`）

6. PRを作成する
   ```bash
   gh pr create --base develop --title "<title>" --body "<body>"
   ```
   - bodyにはIssue番号への参照を含める

7. 結果を表示する
   - PR URL
   - 次のステップ（GitHub Actionsがstagingブランチを自動作成）

## エラーハンドリング

- featureブランチでない場合: エラーメッセージを表示
- プッシュに失敗した場合: エラー詳細を表示
- PR作成に失敗した場合: エラー詳細を表示

## 注意事項

- PRはdevelop向けに作成されるが、GitHub Actionsが自動的に:
  1. `staging-<PR番号>` ブランチを作成
  2. PRのベースブランチをstagingに変更
