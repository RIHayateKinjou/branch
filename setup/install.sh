#!/bin/bash
# =============================================================================
# Branch Workflow Setup Script
# 2層ブランチ戦略 (feature/issue-#* → staging-#* → main) のセットアップ
# =============================================================================

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# -----------------------------------------------------------------------------
# ヘルプ表示
# -----------------------------------------------------------------------------
show_help() {
  echo "Usage: $0 [OPTIONS] [TARGET_DIR]"
  echo ""
  echo "2層ブランチ戦略をリポジトリに導入するセットアップスクリプト"
  echo ""
  echo "Options:"
  echo "  -h, --help          このヘルプを表示"
  echo "  -f, --force         既存ファイルを上書き"
  echo "  -n, --no-hooks      Git Hooksをインストールしない"
  echo "  -r, --apply-rules   GitHub Rulesetsを適用 (gh CLI必須)"
  echo ""
  echo "Arguments:"
  echo "  TARGET_DIR          導入先ディレクトリ (デフォルト: カレントディレクトリ)"
  echo ""
  echo "Examples:"
  echo "  $0                  カレントディレクトリに導入"
  echo "  $0 /path/to/repo    指定ディレクトリに導入"
  echo "  $0 -f -r .          強制上書き + Rulesets適用"
}

# -----------------------------------------------------------------------------
# オプション解析
# -----------------------------------------------------------------------------
FORCE=false
NO_HOOKS=false
APPLY_RULES=false
TARGET_DIR="."

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -n|--no-hooks)
      NO_HOOKS=true
      shift
      ;;
    -r|--apply-rules)
      APPLY_RULES=true
      shift
      ;;
    -*)
      echo -e "${RED}Error: Unknown option $1${NC}"
      show_help
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# -----------------------------------------------------------------------------
# 前提条件チェック
# -----------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Branch Workflow Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ターゲットディレクトリの確認
if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Directory not found: $TARGET_DIR${NC}"
  exit 1
fi

cd "$TARGET_DIR"
TARGET_DIR="$(pwd)"

# Gitリポジトリかどうか確認
if [[ ! -d ".git" ]]; then
  echo -e "${RED}Error: Not a git repository: $TARGET_DIR${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Target directory: $TARGET_DIR"

# テンプレートディレクトリの確認
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo -e "${RED}Error: Template directory not found: $TEMPLATE_DIR${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Template directory: $TEMPLATE_DIR"
echo ""

# -----------------------------------------------------------------------------
# ファイルコピー関数
# -----------------------------------------------------------------------------
copy_file() {
  local src="$1"
  local dest="$2"
  local dest_dir="$(dirname "$dest")"

  # ディレクトリ作成
  mkdir -p "$dest_dir"

  # 既存ファイルチェック
  if [[ -f "$dest" && "$FORCE" != true ]]; then
    echo -e "${YELLOW}⚠${NC}  Skip (exists): $dest"
    return 0
  fi

  cp "$src" "$dest"
  echo -e "${GREEN}✓${NC} Copied: $dest"
}

# -----------------------------------------------------------------------------
# GitHub Actions ワークフローのインストール
# -----------------------------------------------------------------------------
echo -e "${BLUE}Installing GitHub Actions workflows...${NC}"

copy_file "$TEMPLATE_DIR/workflows/create-staging-branch.yml" ".github/workflows/create-staging-branch.yml"
copy_file "$TEMPLATE_DIR/workflows/validate-pr-to-main.yml" ".github/workflows/validate-pr-to-main.yml"
copy_file "$TEMPLATE_DIR/workflows/cleanup-staging-branch.yml" ".github/workflows/cleanup-staging-branch.yml"

echo ""

# -----------------------------------------------------------------------------
# Git Hooks のインストール
# -----------------------------------------------------------------------------
if [[ "$NO_HOOKS" != true ]]; then
  echo -e "${BLUE}Installing Git Hooks...${NC}"

  copy_file "$TEMPLATE_DIR/githooks/pre-commit" ".githooks/pre-commit"
  copy_file "$TEMPLATE_DIR/githooks/pre-push" ".githooks/pre-push"
  copy_file "$TEMPLATE_DIR/githooks/commit-msg" ".githooks/commit-msg"
  copy_file "$TEMPLATE_DIR/githooks/README.md" ".githooks/README.md"

  # 実行権限を付与
  chmod +x .githooks/pre-commit .githooks/pre-push .githooks/commit-msg 2>/dev/null || true

  # Git hooks パスを設定
  git config core.hooksPath .githooks
  echo -e "${GREEN}✓${NC} Configured: git config core.hooksPath .githooks"

  echo ""
fi

# -----------------------------------------------------------------------------
# Rulesets (参照用) のインストール
# -----------------------------------------------------------------------------
echo -e "${BLUE}Installing Rulesets (reference)...${NC}"

copy_file "$TEMPLATE_DIR/rulesets/main-branch.json" ".github/rulesets/main-branch.json"
copy_file "$TEMPLATE_DIR/rulesets/staging-branch.json" ".github/rulesets/staging-branch.json"

echo ""

# -----------------------------------------------------------------------------
# ドキュメントのインストール
# -----------------------------------------------------------------------------
echo -e "${BLUE}Installing documentation...${NC}"

copy_file "$TEMPLATE_DIR/BRANCH_WORKFLOW.md" "BRANCH_WORKFLOW.md"

echo ""

# -----------------------------------------------------------------------------
# GitHub Rulesets の適用 (オプション)
# -----------------------------------------------------------------------------
if [[ "$APPLY_RULES" == true ]]; then
  echo -e "${BLUE}Applying GitHub Rulesets...${NC}"

  # gh CLI の確認
  if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh CLI is not installed${NC}"
    echo "  Install: https://cli.github.com/"
    exit 1
  fi

  # 認証確認
  if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: gh CLI is not authenticated${NC}"
    echo "  Run: gh auth login"
    exit 1
  fi

  # リポジトリ情報取得
  REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
  if [[ -z "$REPO" ]]; then
    echo -e "${RED}Error: Could not determine repository${NC}"
    exit 1
  fi

  echo -e "${GREEN}✓${NC} Repository: $REPO"

  # main ブランチ Ruleset 適用
  echo -n "  Applying main branch ruleset... "
  if gh api "repos/$REPO/rulesets" \
    --method POST \
    --input "$TEMPLATE_DIR/rulesets/main-branch.json" &> /dev/null; then
    echo -e "${GREEN}done${NC}"
  else
    echo -e "${YELLOW}skipped (may already exist)${NC}"
  fi

  # staging ブランチ Ruleset 適用
  echo -n "  Applying staging branch ruleset... "
  if gh api "repos/$REPO/rulesets" \
    --method POST \
    --input "$TEMPLATE_DIR/rulesets/staging-branch.json" &> /dev/null; then
    echo -e "${GREEN}done${NC}"
  else
    echo -e "${YELLOW}skipped (may already exist)${NC}"
  fi

  echo ""
fi

# -----------------------------------------------------------------------------
# 完了
# -----------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup completed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Review BRANCH_WORKFLOW.md for workflow documentation"
echo "  2. Commit and push the new files"
echo "  3. Configure GitHub Rulesets in repository settings"
echo "     (or re-run with -r option if gh CLI is available)"
echo ""
echo "Files installed:"
echo "  .github/workflows/create-staging-branch.yml"
echo "  .github/workflows/validate-pr-to-main.yml"
echo "  .github/workflows/cleanup-staging-branch.yml"
if [[ "$NO_HOOKS" != true ]]; then
  echo "  .githooks/pre-commit"
  echo "  .githooks/pre-push"
  echo "  .githooks/commit-msg"
  echo "  .githooks/README.md"
fi
echo "  .github/rulesets/main-branch.json (reference)"
echo "  .github/rulesets/staging-branch.json (reference)"
echo "  BRANCH_WORKFLOW.md"
echo ""
