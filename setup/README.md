# Branch Workflow Setup

2層ブランチ戦略 (`feature/issue-#* → staging-#* → main`) を他のリポジトリに導入するためのセットアップツールです。

## Quick Start

```bash
# このリポジトリをクローン
git clone https://github.com/your-org/branch.git
cd branch

# 導入先のリポジトリで実行
./setup/install.sh /path/to/your/repo

# または、導入先リポジトリ内で実行
cd /path/to/your/repo
/path/to/branch/setup/install.sh
```

## Usage

```bash
./setup/install.sh [OPTIONS] [TARGET_DIR]
```

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | ヘルプを表示 |
| `-f, --force` | 既存ファイルを上書き |
| `-n, --no-hooks` | Git Hooksをインストールしない |
| `-r, --apply-rules` | GitHub Rulesetsを自動適用 (gh CLI必須) |

### Examples

```bash
# カレントディレクトリに導入
./setup/install.sh

# 指定ディレクトリに導入
./setup/install.sh /path/to/repo

# 強制上書き + Rulesets適用
./setup/install.sh -f -r /path/to/repo

# Git Hooksなしで導入
./setup/install.sh -n /path/to/repo
```

## Installed Files

スクリプト実行後、以下のファイルが導入先リポジトリにインストールされます：

### GitHub Actions Workflows

```
.github/workflows/
├── create-staging-branch.yml    # feature→main PR時にstaging-#*を自動作成
├── validate-pr-to-main.yml      # main PR時のソースブランチ検証
└── cleanup-staging-branch.yml   # マージされなかったstaging-#*を削除
```

### Git Hooks (optional)

```
.githooks/
├── pre-commit    # ブランチ命名規則チェック
├── pre-push      # 保護ブランチへの直接push防止
├── commit-msg    # コミットメッセージフォーマット
└── README.md     # フック説明
```

### GitHub Rulesets (reference)

```
.github/rulesets/
├── main-branch.json      # mainブランチ保護ルール
└── staging-branch.json   # staging-#*ブランチ保護ルール
```

### Documentation

```
BRANCH_WORKFLOW.md    # ワークフロー説明ドキュメント
```

## Post-Installation

### 1. Git Hooks有効化

スクリプトが自動設定しますが、手動で設定する場合：

```bash
git config core.hooksPath .githooks
```

### 2. GitHub Rulesets設定

#### Option A: gh CLI で自動適用

```bash
./setup/install.sh -r /path/to/repo
```

#### Option B: GitHub UIで手動設定

1. Repository Settings → Rules → Rulesets
2. "New ruleset" → "Import ruleset"
3. `.github/rulesets/main-branch.json` をインポート
4. 同様に `staging-branch.json` もインポート

### 3. ファイルのコミット

```bash
git add .
git commit -m "Add branch workflow configuration"
git push
```

## Requirements

- Git repository (既存のリポジトリ)
- Bash shell
- (Optional) [gh CLI](https://cli.github.com/) - Rulesets自動適用に必要

## Directory Structure

```
setup/
├── install.sh              # インストールスクリプト
├── README.md               # このファイル
└── templates/
    ├── workflows/          # GitHub Actions ワークフロー
    ├── githooks/           # Git Hooks
    ├── rulesets/           # GitHub Rulesets
    └── BRANCH_WORKFLOW.md  # ワークフロー説明
```
