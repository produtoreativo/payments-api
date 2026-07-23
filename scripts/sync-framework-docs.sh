#!/usr/bin/env bash
# ─── DISABLED ────────────────────────────────────────────────────────────────
# sync-framework-docs.sh — DISABLED. See guard below.
# ─────────────────────────────────────────────────────────────────────────────
# sync-framework-docs.sh
#
# Copies ProdOps framework documentation from this product repository to
# prodops-framework (the shared canonical framework repo) and opens a PR.
#
# What is synced (full framework — everything except product artifacts):
#   prodops/framework/       →  framework/
#   prodops/journeys/        →  journeys/
#   prodops/skills/          →  skills/
#   prodops/templates/       →  templates/
#   prodops/execution-model/ →  execution-model/
#   prodops/README.md        →  README.md
#   prodops/README.en.md     →  README.en.md
#
# What is NOT synced (product-specific):
#   prodops/artifacts/   — product knowledge artifacts (OBCs, BDD Features, etc.)
#   prodops/exec/        — product manifest and cards
#
# Prerequisites:
#   - git with SSH access to git@github.com:produtoreativo/prodops-framework.git
#   - gh CLI authenticated (run: gh auth login)
#
# Usage:
#   ./scripts/sync-framework-docs.sh [--dry-run] [--branch <name>] [--no-pr]
#
# Options:
#   --dry-run    Show what would be synced without pushing or opening a PR
#   --branch     Override branch name (default: sync/payments-api-YYYYMMDD-HHMMSS)
#   --no-pr      Push branch but skip PR creation
#
# Exit codes:
#   0  — success (PR created or no changes detected)
#   1  — dependency missing
#   2  — git/network error
#   3  — nothing to sync (clean exit, informational)

# ─── DISABLED ────────────────────────────────────────────────────────────────
# This script is disabled because it is not aligned with the declarative
# export boundary defined in prodops/exec/export-manifest.yaml.
#
# Critical issues:
#   - References stale paths (prodops/journeys/, prodops/execution-model/)
#   - Does not exclude skills/local/** (would export product-specific Skills)
#   - Does not read .prodopsignore
#   - Does not consult export-manifest.yaml
#   - Uses rsync --delete (may remove Framework-independent content)
#
# Before any export or sync:
#   1. Align this script with prodops/exec/export-manifest.yaml
#   2. Add exclusions for skills/local/**, skills/references/local/**
#   3. Remove stale path references
#   4. Add framework-lock.yaml update step
#   5. Review dry-run output with a human before live execution
#
# See: prodops/exec/export-boundary.md
# ─────────────────────────────────────────────────────────────────────────────
echo "ERROR: scripts/sync-framework-docs.sh is disabled pending alignment with prodops/exec/export-manifest.yaml." >&2
echo "See prodops/exec/export-boundary.md for the current export contract." >&2
exit 1

# ── ORIGINAL SCRIPT (preserved for reference) ─────────────────────────────────

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
RST='\033[0m'
BOLD='\033[1m'

step()  { echo -e "${CYN}▶ ${BOLD}${1}${RST}"; }
ok()    { echo -e "${GRN}  ✓ ${1}${RST}"; }
warn()  { echo -e "${YLW}  ⚠ ${1}${RST}"; }
fail()  { echo -e "${RED}  ✗ ${1}${RST}" >&2; }
info()  { echo -e "  ${1}"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
TARGET_REPO="git@github.com:produtoreativo/prodops-framework.git"
TARGET_REPO_HTTPS="https://github.com/produtoreativo/prodops-framework"
BRANCH_NAME="sync/payments-api-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
OPEN_PR=true
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true;         shift ;;
    --branch)    BRANCH_NAME="$2";     shift 2 ;;
    --no-pr)     OPEN_PR=false;        shift ;;
    -h|--help)
      sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      fail "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Preflight checks ──────────────────────────────────────────────────────────
step "Preflight"

for cmd in git rsync; do
  if ! command -v "$cmd" &>/dev/null; then
    fail "Missing required command: $cmd"
    exit 1
  fi
done
ok "git, rsync available"

if [[ "$OPEN_PR" == true ]] && ! command -v gh &>/dev/null; then
  fail "gh CLI not found — install it or use --no-pr"
  exit 1
fi

if [[ "$OPEN_PR" == true ]] && ! gh auth status &>/dev/null; then
  fail "gh CLI not authenticated — run: gh auth login"
  exit 1
fi
ok "gh CLI ready"

if [[ ! -d "${REPO_ROOT}/prodops/framework" ]]; then
  fail "prodops/framework not found at ${REPO_ROOT}. Run from the payments-api repo."
  exit 1
fi
ok "Source docs found"

# ── Collect source metadata ───────────────────────────────────────────────────
step "Collecting source metadata"

SOURCE_COMMIT=$(git -C "${REPO_ROOT}" rev-parse --short HEAD)
SOURCE_BRANCH=$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)
SOURCE_LOG=$(git -C "${REPO_ROOT}" log --oneline -5 -- prodops/framework/ prodops/journeys/ prodops/skills/ prodops/templates/ prodops/execution-model/ prodops/README.md prodops/README.en.md 2>/dev/null || echo "(no recent commits in prodops framework paths)")

info "Repo:   payments-api @ ${SOURCE_BRANCH} (${SOURCE_COMMIT})"
info "Recent framework commits:"
while IFS= read -r line; do
  info "  ${line}"
done <<< "${SOURCE_LOG}"

# ── Clone target repo ─────────────────────────────────────────────────────────
step "Cloning target repo"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

if [[ "$DRY_RUN" == true ]]; then
  warn "DRY RUN — skipping clone, showing diff only"
else
  git clone --depth 1 "${TARGET_REPO}" "${WORK_DIR}/framework-repo" 2>&1 \
    | sed 's/^/  /' \
    || { fail "Clone failed. Check SSH access to ${TARGET_REPO}"; exit 2; }
  ok "Cloned to ${WORK_DIR}/framework-repo"
fi

TARGET_DIR="${WORK_DIR}/framework-repo"

# ── Sync files ────────────────────────────────────────────────────────────────
step "Syncing files"

sync_path() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [[ ! -e "${REPO_ROOT}/${src}" ]]; then
    warn "Source not found, skipping: ${src}"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    info "Would sync: ${src} → ${dst}"
    if [[ -d "${REPO_ROOT}/${src}" ]]; then
      rsync -avn --delete \
        "${REPO_ROOT}/${src}/" \
        "/dev/null" 2>/dev/null | grep -E '^(>|<|deleting)' | sed 's/^/    /' || true
    fi
    return
  fi

  mkdir -p "${TARGET_DIR}/$(dirname "${dst}")"

  if [[ -d "${REPO_ROOT}/${src}" ]]; then
    rsync -av --delete \
      "${REPO_ROOT}/${src}/" \
      "${TARGET_DIR}/${dst}/" \
      2>&1 | grep -E '^(sending|deleting|[a-z])' | sed 's/^/  /' || true
  else
    cp "${REPO_ROOT}/${src}" "${TARGET_DIR}/${dst}"
  fi
  ok "${label}"
}

sync_path "prodops/framework"       "framework"       "framework/ directory"
sync_path "prodops/journeys"        "journeys"        "journeys/ directory"
sync_path "prodops/skills"          "skills"          "skills/ directory"
sync_path "prodops/templates"       "templates"       "templates/ directory"
sync_path "prodops/execution-model" "execution-model" "execution-model/ directory"
sync_path "prodops/README.md"       "README.md"       "README.md"
sync_path "prodops/README.en.md"    "README.en.md"    "README.en.md"

# ── Check for changes ─────────────────────────────────────────────────────────
step "Checking for changes"

if [[ "$DRY_RUN" == true ]]; then
  warn "Dry run complete — no changes pushed"
  exit 0
fi

cd "${TARGET_DIR}"

if git diff --quiet && git ls-files --others --exclude-standard | grep -q .; then
  :  # has untracked files — proceed
elif git diff --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  ok "No changes detected — framework docs are already up to date"
  exit 0
fi

CHANGED_FILES=$(git diff --name-only; git ls-files --others --exclude-standard)
CHANGED_COUNT=$(echo "${CHANGED_FILES}" | grep -c . || true)

info "Changed files (${CHANGED_COUNT}):"
echo "${CHANGED_FILES}" | sed 's/^/    /'

# ── Commit and push ───────────────────────────────────────────────────────────
step "Committing and pushing"

git checkout -b "${BRANCH_NAME}"
git add -A

COMMIT_MSG="sync(framework): update from payments-api@${SOURCE_COMMIT}

Synced from: github.com/produtoreativo/payments-api
Branch:      ${SOURCE_BRANCH}
Commit:      ${SOURCE_COMMIT}

Recent framework changes:
${SOURCE_LOG}

Synced paths:
  prodops/framework/       → framework/
  prodops/journeys/        → journeys/
  prodops/skills/          → skills/
  prodops/templates/       → templates/
  prodops/execution-model/ → execution-model/
  prodops/README.md        → README.md"

git commit -m "${COMMIT_MSG}" \
  --author="sync-framework-docs <noreply@produtoreativo.com>" \
  || { fail "Nothing to commit"; exit 3; }

ok "Committed on branch ${BRANCH_NAME}"

git push origin "${BRANCH_NAME}" 2>&1 | sed 's/^/  /' \
  || { fail "Push failed"; exit 2; }

ok "Pushed to ${TARGET_REPO}"

# ── Open PR ───────────────────────────────────────────────────────────────────
if [[ "$OPEN_PR" == false ]]; then
  info "Branch pushed. Skipping PR (--no-pr)."
  info "Open manually: ${TARGET_REPO_HTTPS}/compare/${BRANCH_NAME}"
  exit 0
fi

step "Opening Pull Request"

PR_BODY="$(cat <<EOF
## Summary

Automated sync from [\`payments-api\`](https://github.com/produtoreativo/payments-api) @ \`${SOURCE_COMMIT}\` (\`${SOURCE_BRANCH}\`).

### Changed files (${CHANGED_COUNT})

\`\`\`
${CHANGED_FILES}
\`\`\`

### Recent framework commits in source

\`\`\`
${SOURCE_LOG}
\`\`\`

### Synced paths

| Source | Target |
|---|---|
| \`prodops/framework/\` | \`framework/\` |
| \`prodops/journeys/\` | \`journeys/\` |
| \`prodops/skills/\` | \`skills/\` |
| \`prodops/templates/\` | \`templates/\` |
| \`prodops/execution-model/\` | \`execution-model/\` |
| \`prodops/README.md\` | \`README.md\` |
| \`prodops/README.en.md\` | \`README.en.md\` |

---
🤖 Generated by \`scripts/sync-framework-docs.sh\`
EOF
)"

PR_URL=$(gh pr create \
  --repo "produtoreativo/prodops-framework" \
  --base "master" \
  --head "${BRANCH_NAME}" \
  --title "sync(framework): update from payments-api@${SOURCE_COMMIT}" \
  --body "${PR_BODY}" \
  2>&1) || { fail "PR creation failed: ${PR_URL}"; exit 2; }

ok "PR created: ${PR_URL}"
echo ""
echo -e "${BOLD}${GRN}Done.${RST} Review and merge at:"
echo -e "  ${BLU}${PR_URL}${RST}"
