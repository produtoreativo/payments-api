# EXP-016 — Incremento 6: Preparação para Demonstração

**Data:** 2026-07-29

---

## Resultado do prepare-demo.sh

```
Total checks — PASS: 24 | WARN: 1 | FAIL: 0
Result: READY WITH WARNINGS
```

**WARN:** View "02 — Iteration Plan" não encontrada por nome exato — view existe como "02 - Iteration Plan" (view #7, traço simples vs em-dash). Comportamento não-bloqueante para a demonstração EXP-016.

---

## EXP-016 Demo Readiness — Checklist

### GitHub Project

| Check | Status |
|-------|--------|
| Project #25 acessível | ✓ PASS |
| 01 — Delivery Timeline [BOARD] | ✓ PASS |
| 03 — Diligence Tracking [BOARD] | ✓ PASS |
| 04 — Runtime Reconciliation [TABLE] | ✓ PASS |
| 02 - Iteration Plan [BOARD] | ✓ PASS |
| 05 — Active Features [BOARD] | ✓ PASS (criada Incremento 2) |
| 06 — Executive Overview [TABLE] | ✓ PASS (criada Incremento 2) |
| Campos: oem-state, oem-last-event, diligence-status, diligence-evidence, runtime-sync | ✓ PASS |
| Feature #76 state: DONE | ✓ PASS |

### Datadog

| Check | Status |
|-------|--------|
| DD_API_KEY válida | ✓ PASS |
| DD_APP_KEY válida | ✓ PASS |
| Dashboard operacional (jhq-ztv-3pv) | ✓ PASS |
| Dashboard executiva (4rs-983-e35) | ✓ PASS |
| 21 métricas enviadas no flow EXP-016 | ✓ PASS |

### Runtime

| Check | Status |
|-------|--------|
| Runtime Doctor: PASS | ✓ PASS |
| events.yaml: 32 events | ✓ PASS |
| Catalog: todos os eventos Delivery e Diligence | ✓ PASS |
| derived-state-76.json: DONE | ✓ PASS |
| Dispatcher integrado (Step 6 do emit-event) | ✓ PASS |
| Subscriptions: delivery-diligence.yaml | ✓ PASS |

---

## Setup para Gravação da Demonstração

### Pré-requisitos confirmados

1. `api/.env` com DD_API_KEY, DD_APP_KEY, DD_SITE, GITHUB_TOKEN — ✓
2. `gh` autenticado com permissão de Projects — ✓
3. Runtime Doctor: PASS — ✓

### Sequência recomendada para gravação

**Janelas necessárias (lado a lado):**
- VS Code (Claude Code no terminal)
- Browser: GitHub Project, view "05 — Active Features" ou "01 — Delivery Timeline"
- Browser: Datadog Executive Cockpit (4rs-983-e35)

**Para uma nova demonstração com Feature fresca:**

```bash
# 1. Resetar Feature #77 (VALIDATING) para rodar do zero
# (selecionar a feature adequada)

# 2. Executar a Journey pelo Claude Code:
/bootstrap    → emite Bootstrap.Started + Bootstrap.Completed
/hack         → emite Hack.Started + Hack.Completed
/sync         → emite Sync.Started + Sync.Completed
/finish       → emite Finish.Started + Finish.Completed
/ship         → emite Ship.Started + Ship.Completed
/validate     → emite Validate.Started + Gate.Passed + Validate.Completed
/promote      → emite Promote.Started + Promote.Completed
```

Ou via script direto:

```bash
bash prodops/runtime/tools/emit-event/tests/chain/run-chain.sh \
  --player claude \
  --work-item-id 77 \
  --iteration-id IP-EXP016-DEMO
```

**Cada emissor aciona automaticamente:**
- GitHub Project → card muda de coluna
- Datadog → métrica `runtime.event.received` atualiza dashboard
- Diligence → Capture/Attach/Promote reagem a Bootstrap.Completed/Validate.Completed/Promote.Completed

### Configuração manual recomendada no GitHub Project antes da gravação

1. Abrir view "05 — Active Features" ou "01 — Delivery Timeline"
2. Configurar `Column by: oem-state` (se não estiver configurado)
3. Verificar que os cards das Features estão visíveis nas colunas corretas

---

## Feature Disponível para Demonstração ao Vivo

| Issue | Feature | Estado atual | Adequada para demo |
|-------|---------|-------------|-------------------|
| #77 | FTR-002: Invoice Cartão | VALIDATING | ✓ Pode ser resetada para demonstração |
| #78 | FTR-003: Confirmação de Pagamento | HACKING | ✓ Pode continuar de HACKING |
| #79 | FTR-004: Split Payment — Conflito | Não iniciada | ✓ Ideal (percorre tudo do início) |

---

**Resultado Incremento 6:** ✓ Ambiente pronto para gravação. 24/25 PASS (WARN não-bloqueante). Fluxo validado end-to-end com 21 eventos.
