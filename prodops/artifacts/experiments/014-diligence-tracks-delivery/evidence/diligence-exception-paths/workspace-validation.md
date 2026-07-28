# Workspace Validation — Incremento 1
# EXP-014 Iteration 5 — Diligence Exception Paths

**Data:** 2026-07-27
**GitHub Project:** produtoreativo/payments-api #25
**Project ID:** `PVT_kwDOAT1J1c4BeiVu`
**Status:** ✅ CONFORME

---

## Campos validados via GitHub GraphQL API

### diligence-status (13 opções) — Field ID: `PVTSSF_lADOAT1J1c4BeiVuzhY_qk8`

| Opção | ID | Cor | Status |
|---|---|---|---|
| Pending | 93df4fc2 | GRAY | ✅ existente |
| Sync In Progress | f2edf7aa | BLUE | ✅ existente |
| Captured | 4f7fa188 | BLUE | ✅ existente |
| Attached | e5973bed | GREEN | ✅ existente |
| Blocked | e95a10ed | RED | ✅ novo (iter-5) |
| Promoting | 4de4332e | YELLOW | ✅ novo (iter-5) |
| Promoted | 836d3f38 | YELLOW | ✅ novo (iter-5) |
| Closing | c90fb08c | ORANGE | ✅ novo (iter-5) |
| Closed | 931ee946 | GREEN | ✅ novo (iter-5) |
| Scanning | da45992c | PURPLE | ✅ novo (iter-5) |
| Flagged | 31827168 | RED | ✅ novo (iter-5) |
| Repairing | 010ff47e | ORANGE | ✅ novo (iter-5) |
| Repaired | 305641b4 | GREEN | ✅ novo (iter-5) |

### diligence-evidence (4 opções) — Field ID: `PVTSSF_lADOAT1J1c4BeiVuzhY_ql4`

| Opção | ID | Status |
|---|---|---|
| Missing | 497d5edc | ✅ existente |
| Partial | 2f23d1d3 | ✅ existente |
| Complete | 2f35bb96 | ✅ existente |
| Invalid | (novo) | ✅ novo (iter-5) |

### runtime-sync (5 opções) — Field ID: `PVTSSF_lADOAT1J1c4BeiVuzhY_ql8`

| Opção | ID | Status |
|---|---|---|
| Pending | 3a08a4d9 | ✅ existente |
| In Sync | 72301378 | ✅ existente |
| Drift | (novo) | ✅ novo (iter-5) |
| Repairing | (novo) | ✅ novo (iter-5) |
| Blocked | (novo) | ✅ novo (iter-5) |

### Novos campos de texto

| Campo | Field ID | Tipo | Status |
|---|---|---|---|
| diligence-block-reason | PVTF_lADOAT1J1c4BeiVuzhZBJH8 | TEXT | ✅ criado (iter-5) |
| diligence-finding-id | PVTF_lADOAT1J1c4BeiVuzhZBJIY | TEXT | ✅ criado (iter-5) |

---

## Catálogo de eventos

13 novos CloudEvent types adicionados a `prodops/runtime/catalog/events.yaml`:

| Evento | CE Type |
|---|---|
| Diligence.Promote.Started | prodops.diligence.promote.started |
| Diligence.Promote.Completed | prodops.diligence.promote.completed |
| Diligence.Close.Started | prodops.diligence.close.started |
| Diligence.Close.Completed | prodops.diligence.close.completed |
| Diligence.Block.Declared | prodops.diligence.block.declared |
| Diligence.Block.Resolved | prodops.diligence.block.resolved |
| Diligence.Scan.Started | prodops.diligence.scan.started |
| Diligence.Scan.Completed | prodops.diligence.scan.completed |
| Diligence.Divergence.Detected | prodops.diligence.divergence.detected |
| Diligence.Flag.Started | prodops.diligence.flag.started |
| Diligence.Flag.Completed | prodops.diligence.flag.completed |
| Diligence.Repair.Started | prodops.diligence.repair.started |
| Diligence.Repair.Completed | prodops.diligence.repair.completed |

---

## Gate do Incremento 1

- [x] Nenhuma opção ausente
- [x] Nenhum campo duplicado
- [x] Workspace confirmado via GraphQL API
- [x] 13 opções em diligence-status (esperado: 13)
- [x] 4 opções em diligence-evidence (esperado: 4)
- [x] 5 opções em runtime-sync (esperado: 5)
- [x] 2 campos de texto criados
- [x] 13 novos CE types no catálogo

**✅ INCREMENTO 1 — GATE APROVADO**
