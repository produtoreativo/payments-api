#!/usr/bin/env bash
# Materialize canonical ProdOps skills into player-specific directories.
#
# Source:  prodops/skills/<skill>/SKILL.md
# Targets:
#   .claude/skills/<skill>/SKILL.md       (Claude Code)
#   .agents/skills/<skill>/SKILL.md       (Codex / OpenAI Agents)
#   .github/skills/<skill>/SKILL.md       (GitHub Copilot)
#
# Usage:
#   materialize-skills.sh [--skill <name>] [--check] [--force]
#
# Flags:
#   --skill <name>   Materialize only this skill (default: all in prodops/skills/)
#   --check          Report drift without writing; exits 1 if drift found
#   --force          Overwrite even if target has manual divergence
#
# Exit codes:
#   0   All targets up-to-date (or --check: no drift)
#   1   Drift detected (--check mode) or invalid args
#   2   Manual divergence detected (without --force)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/prodops/skills"

PLAYER_DIRS=(
  ".claude/skills"
  ".agents/skills"
  ".github/skills"
)

PLAYER_NAMES=(
  "claude"
  "codex"
  "copilot"
)

CHECK_ONLY="false"
FORCE="false"
TARGET_SKILL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)          CHECK_ONLY="true"; shift ;;
    --force)          FORCE="true"; shift ;;
    --skill)          TARGET_SKILL="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,20p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

log()  { echo "[materialize-skills] $*"; }
warn() { echo "[materialize-skills] WARNING: $*" >&2; }
err()  { echo "[materialize-skills] ERROR: $*" >&2; }

DRIFT_COUNT=0
DIVERGENCE_COUNT=0
WRITTEN_COUNT=0
UP_TO_DATE_COUNT=0

provenance_header() {
  local skill="$1" player="$2"
  cat <<EOF
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/${skill}/SKILL.md
     Player:    ${player}
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill ${skill}
-->
EOF
}

strip_header() {
  # Remove the provenance header (<!-- ... -->) from the start of a file
  sed '/^<!-- MATERIALIZED FILE/,/^-->/d'
}

materialize_skill() {
  local skill="$1"
  local src="$SKILLS_SRC/$skill/SKILL.md"

  if [[ ! -f "$src" ]]; then
    warn "Skill source not found: $src — skipping"
    return
  fi

  local src_content
  src_content=$(cat "$src")

  for i in "${!PLAYER_DIRS[@]}"; do
    local player_dir="${PLAYER_DIRS[$i]}"
    local player="${PLAYER_NAMES[$i]}"
    local target_dir="$REPO_ROOT/$player_dir/$skill"
    local target="$target_dir/SKILL.md"

    local generated_content
    # Tools like Codex CLI require YAML frontmatter on the very first line.
    # If the source starts with ---, inject the provenance comment after the
    # closing --- so the frontmatter block remains at line 1.
    if [[ "$src_content" == ---* ]]; then
      local fm_end_line
      fm_end_line=$(printf '%s\n' "$src_content" | awk 'NR==1{next} /^---/{print NR; exit}')
      if [[ -n "$fm_end_line" ]]; then
        local frontmatter body
        frontmatter=$(printf '%s\n' "$src_content" | head -n "$fm_end_line")
        body=$(printf '%s\n' "$src_content" | tail -n +"$((fm_end_line + 1))")
        generated_content="${frontmatter}
$(provenance_header "$skill" "$player")
${body}"
      else
        generated_content="$(provenance_header "$skill" "$player")
${src_content}"
      fi
    else
      generated_content="$(provenance_header "$skill" "$player")
${src_content}"
    fi

    if [[ -f "$target" ]]; then
      local target_body target_first_line
      target_body=$(strip_header < "$target")
      target_first_line=$(head -1 "$target")

      # Check drift: compare canonical body AND verify structural correctness.
      # If the source has frontmatter, the target must also start with ---
      # (not with a provenance comment) — otherwise tools like Codex CLI fail.
      local structure_ok=true
      if [[ "$src_content" == ---* && "$target_first_line" != "---" ]]; then
        structure_ok=false
      fi

      if [[ "$target_body" == "$src_content" && "$structure_ok" == "true" ]]; then
        log "✓ up-to-date  [$player] $skill"
        ((UP_TO_DATE_COUNT++))
        continue
      fi

      # Drift detected — check if it's just a stale header or a manual edit
      local target_no_header
      target_no_header=$(strip_header < "$target")

      if [[ "$target_no_header" == "$src_content" ]]; then
        # Only header differs (e.g. timestamp) — safe to update
        log "↻ refresh     [$player] $skill (header only)"
        ((DRIFT_COUNT++))
      else
        # Body differs from canonical — potential manual edit
        if [[ "$FORCE" == "false" ]]; then
          warn "Manual divergence in [$player] $skill — use --force to overwrite"
          warn "  Target: $target"
          ((DIVERGENCE_COUNT++))
          if [[ "$CHECK_ONLY" == "false" ]]; then
            continue
          fi
        else
          warn "Overwriting manual divergence in [$player] $skill (--force)"
          ((DRIFT_COUNT++))
        fi
      fi
    else
      log "✚ new         [$player] $skill"
      ((DRIFT_COUNT++))
    fi

    if [[ "$CHECK_ONLY" == "true" ]]; then
      continue
    fi

    mkdir -p "$target_dir"
    printf '%s\n' "$generated_content" > "$target"
    log "  → written: $target"
    ((WRITTEN_COUNT++))
  done
}

# Discover skills
if [[ -n "$TARGET_SKILL" ]]; then
  SKILLS=("$TARGET_SKILL")
else
  mapfile -t SKILLS < <(find "$SKILLS_SRC" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort)
fi

log "Mode: $([ "$CHECK_ONLY" == "true" ] && echo "CHECK" || echo "WRITE")  Force: $FORCE"
log "Skills to process: ${SKILLS[*]}"
echo ""

for skill in "${SKILLS[@]}"; do
  materialize_skill "$skill"
done

echo ""
log "Summary:"
log "  Up-to-date:   $UP_TO_DATE_COUNT"
log "  Written:      $WRITTEN_COUNT"
log "  Drift:        $DRIFT_COUNT"
log "  Divergence:   $DIVERGENCE_COUNT (manual edits — use --force to overwrite)"

if [[ "$CHECK_ONLY" == "true" && $((DRIFT_COUNT + DIVERGENCE_COUNT)) -gt 0 ]]; then
  log "CHECK FAILED — run without --check to update"
  exit 1
fi

if [[ "$DIVERGENCE_COUNT" -gt 0 && "$FORCE" == "false" && "$CHECK_ONLY" == "false" ]]; then
  exit 2
fi

exit 0
