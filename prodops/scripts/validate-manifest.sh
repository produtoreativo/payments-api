#!/usr/bin/env bash
# validate-manifest.sh
#
# Valida prodops/exec/manifest.yaml contra o estado real do repositório:
#   1. Todo path declarado em `skills:` e `paths:` existe
#      (linhas marcadas com "# optional" geram WARN em vez de FAIL).
#   2. `commit_types` bate com os tipos aceitos pelo hook commit-msg.sh.
#   3. `commit_summary_max` bate com o limite que o hook realmente aplica
#      (o guard MAX_SUMMARY sobre o subject inteiro, não o quantificador do regex).
#
# Uso: ./prodops/scripts/validate-manifest.sh
# Exit: 0 = consistente | 1 = inconsistência encontrada

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MANIFEST="prodops/exec/manifest.yaml"
HOOK="prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts/commit-msg.sh"

FAILURES=0
WARNINGS=0

fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
warn() { echo "  ⚠ $1"; WARNINGS=$((WARNINGS + 1)); }
ok()   { echo "  ✓ $1"; }

[ -f "$MANIFEST" ] || { echo "✗ $MANIFEST não encontrado"; exit 1; }

# ── 1. Paths declarados existem ─────────────────────────────────────────────
echo "1. Verificando paths declarados (skills: e paths:)"

# Percorre as seções skills: e paths:; extrai "chave: valor" de linhas indentadas.
awk '
  /^[a-z_]+:/ { section = $1 }
  (section == "skills:" || section == "paths:") && /^  [a-z_]+: / {
    optional = ($0 ~ /# optional/) ? "optional" : "required"
    line = $0
    sub(/#.*$/, "", line)          # remove comentário
    split(line, kv, ": ")
    gsub(/^[ \t]+|[ \t]+$/, "", kv[2])
    if (kv[2] != "") print optional " " kv[2]
  }
' "$MANIFEST" | while read -r kind path; do
  if [ -e "$path" ]; then
    ok "$path"
  elif [ "$kind" = "optional" ]; then
    warn "$path (ausente — marcado como optional)"
  else
    fail "$path não existe"
  fi
done

# O while roda em subshell; re-conta falhas de path de forma direta:
PATH_FAILS=$(awk '
  /^[a-z_]+:/ { section = $1 }
  (section == "skills:" || section == "paths:") && /^  [a-z_]+: / && !/# optional/ {
    line = $0; sub(/#.*$/, "", line); split(line, kv, ": ")
    gsub(/^[ \t]+|[ \t]+$/, "", kv[2]); if (kv[2] != "") print kv[2]
  }
' "$MANIFEST" | while read -r p; do [ -e "$p" ] || echo "$p"; done | wc -l)
FAILURES=$((FAILURES + PATH_FAILS))

# ── 2. commit_types == tipos do hook ────────────────────────────────────────
echo "2. Verificando commit_types contra $HOOK"

MANIFEST_TYPES=$(grep -E '^\s+commit_types:' "$MANIFEST" \
  | sed 's/.*\[//; s/\].*//; s/,/ /g; s/  */ /g' | xargs)
HOOK_TYPES=$(grep -oE "\(feat\|[a-z|]+\)" "$HOOK" | head -1 \
  | tr -d '()' | tr '|' ' ' | xargs)

if [ "$MANIFEST_TYPES" = "$HOOK_TYPES" ]; then
  ok "commit_types consistentes: $MANIFEST_TYPES"
else
  fail "commit_types divergem — manifest: [$MANIFEST_TYPES] hook: [$HOOK_TYPES]"
fi

# ── 3. commit_summary_max == limite realmente aplicado pelo hook ────────────
# Confere o mecanismo de enforcement de fato (o guard MAX_SUMMARY que mede o
# subject inteiro), não o quantificador do regex Conventional — este mede só o
# texto após "type(scope): " e não é mais o limitador.
echo "3. Verificando commit_summary_max contra o limite aplicado pelo hook"

MANIFEST_MAX=$(grep -E '^\s+commit_summary_max:' "$MANIFEST" | grep -oE '[0-9]+')
HOOK_MAX=$(grep -oE '^MAX_SUMMARY=[0-9]+' "$HOOK" | grep -oE '[0-9]+' | tail -1)

if [ -z "$HOOK_MAX" ]; then
  fail "commit_summary_max não é aplicado — MAX_SUMMARY ausente em $HOOK (o subject inteiro não é medido)"
elif [ "$MANIFEST_MAX" = "$HOOK_MAX" ]; then
  ok "commit_summary_max aplicado e consistente: $MANIFEST_MAX (subject inteiro)"
else
  fail "commit_summary_max diverge — manifest: $MANIFEST_MAX, hook MAX_SUMMARY: $HOOK_MAX"
fi

# ── Resultado ────────────────────────────────────────────────────────────────
echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "✗ validate-manifest: $FAILURES falha(s), $WARNINGS aviso(s)"
  exit 1
fi
echo "✓ validate-manifest: consistente ($WARNINGS aviso(s))"
