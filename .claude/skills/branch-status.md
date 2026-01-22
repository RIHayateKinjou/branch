# /branch-status スキル

現在のブランチ状況を表示する。

## 引数

なし

## 実行手順

1. 現在のブランチ名を取得する
   ```bash
   git branch --show-current
   ```

2. ブランチの種類を判定する
   - `main`: 本番ブランチ
   - `develop`: 開発ブランチ
   - `staging-*`: ステージングブランチ
   - `feature/issue-#*`: 機能ブランチ
   - その他: 不明なブランチ

3. リモートとの差分を確認する
   ```bash
   git fetch origin
   git status -sb
   ```

4. 未コミットの変更を確認する
   ```bash
   git status --porcelain
   ```

5. ブランチフローにおける位置を表示する
   ```
   feature/issue-#* → staging-* → develop → main
         ↑ 現在地
   ```

6. 次のアクションを提案する
   - feature: `/pr` でPR作成
   - staging: `/staging-pr` でdevelopへPR作成
   - develop: `/release-pr` でmainへPR作成
   - main: 作業ブランチではないため `/feature` で新しいブランチを作成

## 出力例

```
## ブランチ状況

現在のブランチ: feature/issue-#123-add-login
ブランチタイプ: 機能ブランチ

### リモートとの差分
ローカル: 2 commits ahead
リモート: up to date

### 未コミットの変更
M src/auth.js
A src/login.js

### ブランチフロー位置
feature/issue-#* → staging-* → develop → main
      ↑ 現在地

### 次のアクション
- 変更をコミット後、`/pr` でPRを作成してください
```
