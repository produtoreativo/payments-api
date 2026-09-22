#!/usr/bin/env bash
# install-claude.sh — Install the .claude/ directory structure for Claude Code.
#
# Creates:
#   .claude/skills/    — copied from framework's pre-materialized .claude/skills/
#   .claude/agents/    — copied from framework's pre-materialized .claude/agents/
#   .claude/settings.json — permissions template (if absent)
#
# Requires prodops/ to be already installed (run install-prodops.sh first).
#
# Usage:
#   bash prodops/scripts/install-claude.sh [--target <dir>] [--force]
#
# Flags:
#   --target <dir>   Target repository root (default: current directory)
#   --force          Overwrite existing agent files with framework defaults
#
# Exit codes:
#   0  success
#   1  error (missing dependency, invalid args)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TARGET_DIR="$(pwd)"
FORCE="false"

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    --force)  FORCE="true"; shift ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

log()   { printf '[install-claude] %s\n' "$*"; }
warn()  { printf '[install-claude] WARNING: %s\n' "$*" >&2; }
error() { printf '[install-claude] ERROR: %s\n' "$*" >&2; }

# ── Precondition: prodops/ must exist ────────────────────────────────────────

if [[ ! -d "${TARGET_DIR}/prodops/skills" ]]; then
  error "prodops/skills/ not found at ${TARGET_DIR}"
  error "Run install-prodops.sh first, then re-run this script."
  exit 1
fi

# ── 1. Create .claude/ directory structure ────────────────────────────────────

log "Creating .claude/ directory structure..."
mkdir -p "${TARGET_DIR}/.claude/skills"
mkdir -p "${TARGET_DIR}/.claude/agents"

# ── 2. Copy pre-materialized skills → .claude/skills/ ────────────────────────
# The framework ships .claude/skills/ already materialized; copy it directly.
# Falls back to running materialize-skills.sh for framework versions < v2.3.0.

FRAMEWORK_SKILLS_SRC="${REPO_ROOT}/.claude/skills"

if [[ -d "${FRAMEWORK_SKILLS_SRC}" ]]; then
  log "Copying pre-materialized skills → .claude/skills/..."
  copied=0
  skipped=0
  while IFS= read -r src_file; do
    rel="${src_file#${FRAMEWORK_SKILLS_SRC}/}"
    dest="${TARGET_DIR}/.claude/skills/${rel}"
    if [[ -f "${dest}" && "${FORCE}" == "false" ]]; then
      log "  SKIP (exists): .claude/skills/${rel}"
      skipped=$((skipped + 1))
    else
      mkdir -p "$(dirname "${dest}")"
      cp "${src_file}" "${dest}"
      log "  copied: .claude/skills/${rel}"
      copied=$((copied + 1))
    fi
  done < <(find "${FRAMEWORK_SKILLS_SRC}" -type f | LC_ALL=C sort)
  log "  skills: ${copied} copied, ${skipped} skipped"
else
  # Fallback: materialize from prodops/skills/ in the target repo
  MATERIALIZE_SKILLS="${TARGET_DIR}/prodops/scripts/agents/materialize-skills.sh"
  if [[ -f "${MATERIALIZE_SKILLS}" ]]; then
    log "Framework .claude/skills/ not found — falling back to materialize-skills.sh..."
    (cd "${TARGET_DIR}" && bash "${MATERIALIZE_SKILLS}")
  else
    warn ".claude/skills/ source not found and materialize-skills.sh missing — .claude/skills/ will be empty"
  fi
fi

# ── 3. Copy pre-materialized agents → .claude/agents/ ────────────────────────
# The framework ships .claude/agents/ already materialized; copy it directly.
# Falls back to prodops/agents/ for framework versions < v2.3.0.

FRAMEWORK_AGENTS_SRC="${REPO_ROOT}/.claude/agents"

if [[ -d "${FRAMEWORK_AGENTS_SRC}" ]]; then
  log "Copying pre-materialized agents → .claude/agents/..."
  installed=0
  skipped=0
  while IFS= read -r src_file; do
    agent_name="$(basename "${src_file}")"
    target_file="${TARGET_DIR}/.claude/agents/${agent_name}"
    if [[ -f "${target_file}" && "${FORCE}" == "false" ]]; then
      log "  SKIP (exists): .claude/agents/${agent_name}"
      skipped=$((skipped + 1))
    else
      cp "${src_file}" "${target_file}"
      log "  copied: .claude/agents/${agent_name}"
      installed=$((installed + 1))
    fi
  done < <(find "${FRAMEWORK_AGENTS_SRC}" -maxdepth 1 -name "*.md" | LC_ALL=C sort)
  log "  agents: ${installed} copied, ${skipped} skipped"
else
  # Fallback: copy from prodops/agents/ in the target repo
  AGENTS_SRC="${TARGET_DIR}/prodops/agents"
  if [[ -d "${AGENTS_SRC}" ]]; then
    log "Framework .claude/agents/ not found — falling back to prodops/agents/..."
    installed=0
    skipped=0
    while IFS= read -r src_file; do
      agent_name="$(basename "${src_file}")"
      target_file="${TARGET_DIR}/.claude/agents/${agent_name}"
      if [[ -f "${target_file}" && "${FORCE}" == "false" ]]; then
        log "  SKIP (exists): .claude/agents/${agent_name}"
        skipped=$((skipped + 1))
      else
        cp "${src_file}" "${target_file}"
        log "  copied: .claude/agents/${agent_name}"
        installed=$((installed + 1))
      fi
    done < <(find "${AGENTS_SRC}" -maxdepth 1 -name "*.md" | LC_ALL=C sort)
    log "  agents: ${installed} copied, ${skipped} skipped"
  else
    warn "prodops/agents/ not found — skipping agent installation"
  fi
fi

# ── 4. Create .claude/settings.json template ─────────────────────────────────

SETTINGS="${TARGET_DIR}/.claude/settings.json"

if [[ ! -f "${SETTINGS}" ]]; then
  log "Creating .claude/settings.json template..."
  cat >"${SETTINGS}" <<'EOF'
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git stash*)",
      "Bash(git fetch*)",
      "Bash(git rebase*)",
      "Bash(git checkout*)",
      "Bash(git branch*)",
      "Bash(gh pr*)",
      "Bash(gh issue*)",
      "Bash(gh release*)",
      "Read",
      "WebSearch",
      "WebFetch"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(rm -rf /*)"
    ]
  }
}
EOF
  log "Created: .claude/settings.json"
  log "  → Review and customize permissions for your project before committing."
else
  log "SKIP (exists): .claude/settings.json"
fi

# ── 5. Summary ────────────────────────────────────────────────────────────────

printf '\n'
log ".claude/ installation complete at: ${TARGET_DIR}"
printf '\n'
log "Next steps:"
log "  1. Review .claude/agents/ — adjust product-specific tool constraints"
log "  2. Review .claude/settings.json — set correct permission allowlist"
log "  3. Commit .claude/ to version control (exclude .claude/worktrees/ in .gitignore)"
log "  4. Run: bash prodops/scripts/doctor.sh"
