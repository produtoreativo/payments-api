# Artifact Inventory — EXP-014

**Gerado em:** 2026-07-27T17:35Z
**Gravação de referência:** `exp-014-demo-2026-07-27-1728`

Legenda: **Present** | **Missing** | **Declared but not packaged** | **Generated externally** | **Manual evidence required**

---

## evidence/

| Arquivo | Status | Observação |
|---|---|---|
| `iteration-1-diligence-tracks-delivery.md` | **Present** | Evidência Iter 1 — 12 CloudEvents, GitHub Attached/Complete/In Sync |
| `iteration-2-recorded-operational-flow.md` | **Present** | Evidência Iter 2 — Incrementos 1–7 |
| `iteration-3-recording-evidence-closure.md` | **Present** | Este relatório (Iter 3) |
| `artifact-inventory.md` | **Present** | Este arquivo |
| `demo-context.json` | **Present** | Contexto gerado por prepare-demo.sh |
| `github-views-export.json` | **Present** | Export via GraphQL API |
| `github-views-validation.md` | **Present** | Validação API + notas de UI |
| `datadog-dashboard-definition.json` | **Present** | Export via Datadog API (7590 bytes) |

---

## evidence/recordings/exp-014-demo-2026-07-27-01/ (ensaio técnico — Iter 2 Incremento 6)

| Arquivo | Status | Observação |
|---|---|---|
| `delivery-timelines/76.json` | **Present** | 15 eventos |
| `delivery-timelines/77.json` | **Present** | 11 eventos |
| `delivery-timelines/78.json` | **Present** | 3 eventos |
| `diligence-timelines/diligence-76.json` | **Present** | 4 eventos |
| `diligence-timelines/diligence-77.json` | **Present** | 4 eventos |
| `diligence-timelines/diligence-78.json` | **Present** | 4 eventos |
| `derived-states/derived-state-76.json` | **Present** | DONE |
| `derived-states/derived-state-77.json` | **Present** | VALIDATING |
| `derived-states/derived-state-78.json` | **Present** | HACKING |
| `github-snapshot.json` | **Present** | Estado GitHub após execução |
| `demo-summary.json` | **Present** | `{delivery: 29, diligence: 12}` |
| `datadog-validation.json` | **Missing** | Não gerado no ensaio (aceito — ensaio fast) |
| `iteration-plan-snapshot.md` | **Missing** | Não existia ainda no Incremento 6 |
| `recording.mp4` / `recording-link.md` | **Missing** | Ensaio sem gravação de tela (expected) |
| `screenshots/` | **Missing** | Ensaio sem screenshots (expected) |

---

## evidence/recordings/exp-014-demo-2026-07-27-1728/ (gravação oficial — Iter 2 Incremento 7 / Iter 3)

| Arquivo | Status | Observação |
|---|---|---|
| `delivery-timelines/76.json` | **Present** | 15 eventos |
| `delivery-timelines/77.json` | **Present** | 11 eventos |
| `delivery-timelines/78.json` | **Present** | 3 eventos |
| `diligence-timelines/diligence-76.json` | **Present** | 4 eventos |
| `diligence-timelines/diligence-77.json` | **Present** | 4 eventos |
| `diligence-timelines/diligence-78.json` | **Present** | 4 eventos |
| `derived-states/derived-state-76.json` | **Present** | DONE |
| `derived-states/derived-state-77.json` | **Present** | VALIDATING |
| `derived-states/derived-state-78.json` | **Present** | HACKING |
| `github-snapshot.json` | **Present** | Estado GitHub após execução |
| `demo-summary.json` | **Present** | `{delivery: 29, diligence: 12}` |
| `iteration-plan-snapshot.md` | **Present** | Gerado em Iter 3 |
| `datadog-validation.json` | **Present** | Gerado em Iter 3 |
| `recording-link.md` | **Present** | Requer gravação de tela manual |
| `screenshots/` | **Manual evidence required** | Requer captura manual durante gravação |

---

## Scripts e infraestrutura

| Artefato | Status | Observação |
|---|---|---|
| `.claude/commands/delivery.md` | **Present** | `/delivery` slash command — criado em Iter 3 |
| `prodops/runtime/scripts/create-github-views.sh` | **Present** | Reescrito em Iter 3 com REST API |
| `prodops/runtime/scripts/demo-delivery-with-diligence.sh` | **Present** | Principal script de execução |
| `prodops/runtime/scripts/prepare-demo.sh` | **Present** | Pre-flight check (25/25 PASS) |
| `prodops/runtime/scripts/validate-demo.sh` | **Present** | Validação pós-execução (28/28 PASS) |
| `prodops/runtime/datadog/create-demo-dashboard.sh` | **Present** | Dashboard criado: `jhq-ztv-3pv` |

---

## Artefatos externos (não versionados no repositório)

| Artefato | Status | Localização |
|---|---|---|
| Datadog Dashboard | **Generated externally** | https://app.datadoghq.com/dashboard/jhq-ztv-3pv |
| GitHub Project Views (#2–#5) | **Generated externally** | https://github.com/orgs/produtoreativo/projects/25 |
| Métricas Datadog | **Generated externally** | Retidas 13 meses (padrão Datadog) |
| Vídeo de gravação de tela | **Manual evidence required** | Ver `recording-link.md` |

---

## README

| Arquivo | Status |
|---|---|
| `014-diligence-tracks-delivery/README.md` | **Present** — gerado em Iter 3 |
