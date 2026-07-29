# EXP-015 — Runtime Dispatch Refactoring (Incremento 4)

**Data**: 2026-07-28  
**Branch**: `experiment/015-delivery-skills-event-producers`

---

## Problema Identificado (Gap B do Status Baseline)

Antes desta validação, o dispatcher era invocado pelo runner (`run-chain.sh`) após cada fase:

```bash
# ANTES (violação arquitetural)
dispatch_if_subscribed() {
  local event_type="$1"
  bash "$DISPATCHER" --event-type "$event_type" ...
}

# Chamado após cada skill:
run_skill "bootstrap" && dispatch_if_subscribed "prodops.delivery.bootstrap.completed"
```

Isso violava o princípio: **Skills → Tool → Runtime pipeline → Dispatcher**.  
O runner conhecia subscriptions, o que é responsabilidade exclusiva do Runtime.

---

## Solução Implementada

### Step 6 integrado ao `emit-event` pipeline

Arquivo: `prodops/runtime/tools/emit-event/scripts/emit-event`

```bash
DISPATCHER="$RUNTIME_DIR/dispatcher/dispatch.sh"
SUBSCRIPTIONS="$RUNTIME_DIR/subscriptions/delivery-diligence.yaml"

# ── Step 6: Dispatch to subscribers (non-fatal) ──────────────────────────────
DISPATCH_STATUS="skipped"
DISPATCH_SUBS="[]"

if [[ -f "$DISPATCHER" && -f "$SUBSCRIPTIONS" ]]; then
  HAS_SUB=$(python3 - "$SUBSCRIPTIONS" "$CE_TYPE" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
subs = data.get("subscriptions", {}).get(sys.argv[2], [])
print("yes" if subs else "no")
PYEOF
)
  if [[ "$HAS_SUB" == "yes" ]]; then
    bash "$DISPATCHER" --event-type "$CE_TYPE" ...
    DISPATCH_STATUS="success"
  else
    log "Dispatcher: no subscription for $CE_TYPE — skipped"
  fi
fi
```

### Output expandido com campo `dispatch`

```json
{
  "status": "accepted",
  "event-id": "...",
  "event-type": "prodops.delivery.bootstrap.completed",
  "dispatch": {
    "status": "success",
    "subscriptions": [
      {"subscriber": "diligence.capture", "status": "success"}
    ]
  }
}
```

### Runner limpo (sem conhecimento de dispatch)

```bash
# DEPOIS — run-chain.sh
# Dispatcher is now called from within the Runtime pipeline (emit-event Step 6).
# The runner does NOT call the dispatcher directly.
```

---

## Prevenção de Recursão

O dispatcher lê `delivery-diligence.yaml` que contém apenas event types Delivery:

```yaml
subscriptions:
  prodops.delivery.bootstrap.completed:
    - diligence.capture
  prodops.delivery.validate.completed:
    - diligence.attach
  prodops.delivery.promote.completed:
    - diligence.promote
```

Quando o dispatcher emite eventos Diligence (via `emit-event`), esses eventos:
1. Passam pelo pipeline normal (Steps 1–5)
2. Chegam ao Step 6
3. `HAS_SUB` retorna "no" (nenhuma subscription para event types Diligence)
4. `DISPATCH_STATUS="skipped"`

**Nenhuma recursão possível** — a guarda é declarativa (ausência de entrada no YAML).

---

## Verificação

```bash
# Confirma Step 6 no pipeline
grep -n "Step 6\|DISPATCHER\|dispatch.sh\|SUBSCRIPTIONS" \
  prodops/runtime/tools/emit-event/scripts/emit-event

# Confirma ausência de dispatch no runner
grep -n "dispatch\|DISPATCHER" \
  prodops/runtime/tools/emit-event/tests/chain/run-chain.sh

# Confirma ausência de dispatch em skill scripts
grep -rn "dispatch\|DISPATCHER" \
  prodops/runtime/tools/emit-event/tests/chain/skills/
```

**Resultados**:
- `emit-event`: linhas 27, 28, 280, 286, 288, 299, 318 — Step 6 integrado ✓
- `run-chain.sh`: apenas comentário na linha 21 ✓
- `skills/*.sh`: zero ocorrências ✓

---

## Fluxo Final (EXP-015)

```
Skill.Started →  prodops_emit_event  → [emit.sh → timeline → derive-state → datadog → github → dispatcher*]
                                                                                                    ↓
Skill.Completed → prodops_emit_event → [emit.sh → timeline → derive-state → datadog → github → dispatcher]
                                                                                                    ↓
                                                                                         Diligence.Capture.Started
                                                                                         Diligence.Capture.Completed

* dispatcher skipped para eventos sem subscription (Started, Hack.*, Sync.*, etc.)
```

**Status Incremento 4**: ✓ CONCLUÍDO
