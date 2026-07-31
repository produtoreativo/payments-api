# EXP-014 — Diligence Tracks Delivery

**Produto:** payments-api
**Iteration:** IP-001 — Piloto Operacional Fase 2
**Status:** ✅ CONCLUÍDO — Iterações 1, 2, 3, 4, 4b e 5 — COMPLETED (demo-run-id: exp-014-exc-2026-07-27-2249, 53/53 PASS)
**Última execução:** 2026-07-27T20:07Z
**demo-run-id:** `exp-014-demo-2026-07-27-1959`

---

## Objetivo

Demonstrar que o ProdOps Runtime rastreia automaticamente o estado de Delivery de cada Feature (via CloudEvents) e que a Diligence captura e anexa as evidências operacionais ao mesmo Work Item, mantendo GitHub Project e Datadog sincronizados em tempo real.

---

## Como reproduzir

### Pré-requisitos

```bash
# 1. Verificar ambiente
bash prodops/runtime/scripts/prepare-demo.sh
# → deve retornar 25/25 PASS

# 2. No Claude Code (VS Code) — comando demonstrável:
/delivery --demo --with-diligence
```

Ou diretamente:

```bash
bash prodops/runtime/scripts/demo-delivery-with-diligence.sh \
  --demo \
  --with-diligence \
  --demo-run-id exp-014-demo-$(date -u +%Y-%m-%d-%H%M)
```

### Validação pós-execução

```bash
bash prodops/runtime/scripts/validate-demo.sh \
  --demo-run-id <demo-run-id>
# → deve retornar 28/28 PASS
```

---

## Links

| Sistema | URL |
|---|---|
| GitHub Project | https://github.com/orgs/produtoreativo/projects/25 |
| Delivery Board | https://github.com/orgs/produtoreativo/projects/25/views/2 |
| Diligence Tracking | https://github.com/orgs/produtoreativo/projects/25/views/4 |
| Runtime Reconciliation | https://github.com/orgs/produtoreativo/projects/25/views/5 |
| Datadog Dashboard (operacional) | https://app.datadoghq.com/dashboard/jhq-ztv-3pv |
| Datadog Executive Cockpit (4b) | https://app.datadoghq.com/dashboard/4rs-983-e35 |
| Iteration Plan | `prodops/artifacts/plans/iteration-plan-pilot.md` |

---

## Features demonstradas

| Issue | Feature | Estado Final | Diligence |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX — Happy Path | **DONE** | Attached / Complete / In Sync |
| #77 | FTR-002: Invoice Cartão | **VALIDATING** | Attached / Complete / In Sync |
| #78 | FTR-003: Confirmação de Pagamento | **HACKING** | Attached / Complete / In Sync |

---

## Evidências principais

| Evidência | Arquivo |
|---|---|
| Relatório Iter 1 | `evidence/iteration-1-diligence-tracks-delivery.md` |
| Relatório Iter 2 | `evidence/iteration-2-recorded-operational-flow.md` |
| Relatório Iter 3 | `evidence/iteration-3-recording-evidence-closure.md` |
| Inventário de artefatos | `evidence/artifact-inventory.md` |
| GitHub Views (export) | `evidence/github-views-export.json` |
| GitHub Views (validação) | `evidence/github-views-validation.md` |
| Datadog Dashboard (def.) | `evidence/datadog-dashboard-definition.json` |
| Executive Cockpit (relatório) | `evidence/iteration-4-executive-cockpit-dashboard.md` |
| Executive Cockpit (def.) | `evidence/executive-dashboard/executive-dashboard-definition.json` |
| Executive Cockpit (validação) | `evidence/executive-dashboard/executive-dashboard-validation.json` |
| Timelines gravação oficial | `evidence/recordings/exp-014-demo-2026-07-27-1959/` |
| Executive Cockpit (iter 4b) | `evidence/iteration-4-executive-cockpit-dashboard.md` |

---

## Resultado da última execução

```
validate-demo.sh — demo-run-id: exp-014-demo-2026-07-27-1959

28/28 PASS

✅ DEMO READY
✅ DELIVERY CONSISTENT
✅ DILIGENCE TRACKING
✅ GITHUB IN SYNC
✅ DATADOG IN SYNC
```

---

## Segurança

Nenhuma credencial está presente neste diretório. Credenciais são lidas exclusivamente de `api/.env` em tempo de execução e nunca copiadas para arquivos de evidência.
