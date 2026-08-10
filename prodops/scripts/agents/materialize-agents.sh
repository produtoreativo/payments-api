#!/usr/bin/env bash
# materialize-agents.sh — Copy canonical ProdOps agent definitions into
# player-specific directories.
#
# Source:  prodops/agents/<agent>.md
# Targets:
#   .claude/agents/<agent>.md       (Claude Code)
#   .agents/agents/<agent>.md       (Codex / OpenAI Agents)   [if .agents/ exists]
#
# Unlike skills, agents are copied verbatim — no provenance header transform.
# The source in prodops/agents/ is the single source of truth.
#
# Usage:
#   materialize-agents.sh [--agent <name>] [--check] [--force]
#
# Flags:
#   --agent <name>   Materialize only this agent (default: all in prodops/agents/)
#   --check          Report drift without writing; exits 1 if drift found
#   --force          Overwrite even if target differs from source
#
# Exit codes:
#   0   All targets up-to-date (or --check: no drift)
#   1   Drift detected (--check mode) or invalid args
#   2   Divergence detected without --force

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
AGENTS_SRC="${REPO_ROOT}/prodops/agents"

# Player directories: each entry is "<player-name>:<target-dir>"
PLAYER_TARGETS=(
  "claude:.claude/agents"
  "codex:.agents/agents"
)

CHECK_ONLY="false"
FORCE="false"
TARGET_AGENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)  CHECK_ONLY="true"; shift ;;
    --force)  FORCE="true"; shift ;;
    --agent)  TARGET_AGENT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,25p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

log()  { echo "[materialize-agents] $*"; }
warn() { echo "[materialize-agents] WARNING: $*" >&2; }

DRIFT_COUNT=0
WRITTEN_COUNT=0
UP_TO_DATE_COUNT=0

materialize_agent() {
  local agent_file="$1"
  local agent_name
  agent_name="$(basename "${agent_file}")"

  local src_content
  src_content="$(cat "${agent_file}")"

  for entry in "${PLAYER_TARGETS[@]}"; do
    local player="${entry%%:*}"
    local target_dir_rel="${entry##*:}"
    local target_dir="${REPO_ROOT}/${target_dir_rel}"

    # Skip Codex target if .agents/ doesn't exist and we're not in force mode
    if [[ "${player}" == "codex" && ! -d "${REPO_ROOT}/.agents" ]]; then
      continue
    fi

    local target="${target_dir}/${agent_name}"

    if [[ -f "${target}" ]]; then
      local target_content
      target_content="$(cat "${target}")"

      if [[ "${target_content}" == "${src_content}" ]]; then
        log "✓ up-to-date  [${player}] ${agent_name}"
        ((UP_TO_DATE_COUNT++))
        continue
      fi

      if [[ "${FORCE}" == "false" ]]; then
        warn "Divergence in [${player}] ${agent_name} — use --force to overwrite"
        ((DRIFT_COUNT++))
        if [[ "${CHECK_ONLY}" == "false" ]]; then
          continue
        fi
      else
        log "↻ overwriting [${player}] ${agent_name} (--force)"
        ((DRIFT_COUNT++))
      fi
    else
      log "✚ new         [${player}] ${agent_name}"
      ((DRIFT_COUNT++))
    fi

    [[ "${CHECK_ONLY}" == "true" ]] && continue

    mkdir -p "${target_dir}"
    cp "${agent_file}" "${target}"
    log "  → written: ${target_dir_rel}/${agent_name}"
    ((WRITTEN_COUNT++))
  done
}

# Discover agents
if [[ -n "${TARGET_AGENT}" ]]; then
  src="${AGENTS_SRC}/${TARGET_AGENT}"
  [[ "${src}" != *.md ]] && src="${src}.md"
  if [[ ! -f "${src}" ]]; then
    echo "ERROR: Agent source not found: ${src}" >&2
    exit 1
  fi
  AGENT_FILES=("${src}")
else
  mapfile -t AGENT_FILES < <(find "${AGENTS_SRC}" -maxdepth 1 -name "*.md" | LC_ALL=C sort)
fi

if [[ ${#AGENT_FILES[@]} -eq 0 ]]; then
  log "No agent sources found in ${AGENTS_SRC}"
  exit 0
fi

log "Mode: $([ "${CHECK_ONLY}" == "true" ] && echo "CHECK" || echo "WRITE")  Force: ${FORCE}"
log "Agents to process: $(printf '%s ' "${AGENT_FILES[@]}" | xargs -n1 basename | tr '\n' ' ')"
echo ""

for agent_file in "${AGENT_FILES[@]}"; do
  materialize_agent "${agent_file}"
done

echo ""
log "Summary:"
log "  Up-to-date: ${UP_TO_DATE_COUNT}"
log "  Written:    ${WRITTEN_COUNT}"
log "  Drift:      ${DRIFT_COUNT}"

if [[ "${CHECK_ONLY}" == "true" && "${DRIFT_COUNT}" -gt 0 ]]; then
  log "CHECK FAILED — run without --check to update"
  exit 1
fi

exit 0
