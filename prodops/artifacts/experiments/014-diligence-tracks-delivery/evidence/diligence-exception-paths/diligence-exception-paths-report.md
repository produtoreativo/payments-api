# Diligence Exception Paths — Relatório Final
# EXP-014 Iteration 5

**Data:** 2026-07-27
**Status:** ✅ CONCLUÍDA — Todos os gates aprovados
**Runtime Version:** 0.3.0
**demo-run-id:** `exp-014-exc-2026-07-27-2249`

---

## Respostas ao relatório final

### 1. Qual foi o demo-run-id?

```
exp-014-exc-2026-07-27-2249
```

### 2. Quantos eventos foram emitidos por cenário?

| Cenário | Issue | Eventos | Timeline |
|---|---|---|---|
| A — Sync completo | #76 | **8** | diligence-76.json |
| B — Block → Resume | #77 | **10** | diligence-77.json |
| C — Drift → Repair | #78 | **15** | diligence-78.json |
| **Total** | | **33** | |

### 3. O bloqueio foi real?

**SIM.** O script renomeou `derived-state-77.json` → `derived-state-77.json.hidden`, tornando o arquivo inacessível. O gate `attach-precondition` detectou a ausência e emitiu `Block.Declared` com o motivo:

```
Derived State absent for #77 — evidence gate requires readable derived-state-77.json before Attach can proceed
```

O arquivo foi restaurado (`mv hidden → original`) antes de `Block.Resolved`.

### 4. Promote foi impedido durante o bloqueio?

**SIM.** Verificado via timeline: `Block.Declared` (idx=2) precede `Promote.Started` (idx=6). O Promote só executou após `Block.Resolved` (idx=3). Confirmado pelo `validate-demo.sh` — gate: PASS.

### 5. Como ocorreu a retomada?

`derived-state-77.json` foi restaurado byte-a-byte (SHA-256 idêntico ao baseline). `Block.Resolved` emitido imediatamente após a restauração. Fluxo retomado do checkpoint correto: `Attach.Started` (não do início).

### 6. Qual drift foi introduzido?

```
Campo:    oem-state
Valor adulterado:  BOOTSTRAPPING
Valor correto:     HACKING (conforme derived-state-78.json)
```

O drift foi introduzido via GraphQL `updateProjectV2ItemFieldValue` com a opção `BOOTSTRAPPING`. O `derived-state-78.json` permaneceu inalterado (SHA-256 preservado).

### 7. Qual Finding foi criado?

```json
{
  "finding-id": "FND-202607272251-78",
  "issue": 78,
  "divergence-type": "oem-state-mismatch",
  "expected-value": "HACKING",
  "actual-value": "BOOTSTRAPPING",
  "severity": "HIGH",
  "status": "Closed",
  "repair-source": "derived-state-78.json"
}
```

O Finding ID foi escrito no campo `diligence-finding-id` do GitHub Project.

### 8. Qual foi a fonte usada pelo Repair?

```
derived-state-78.json
```

O script leu `.state` de `derived-state-78.json` para obter `HACKING`. O GitHub Project **não foi consultado** como fonte do valor correto — apenas como alvo da escrita. Registrado no evento `Diligence.Repair.Started.data["repair-source"]`.

### 9. GitHub foi restaurado corretamente?

**SIM.** `oem-state` de #78 voltou para `HACKING` (do `BOOTSTRAPPING` adulterado). Estado final do GitHub Project:

| Issue | oem-state | diligence-status | diligence-evidence | runtime-sync |
|---|---|---|---|---|
| #76 | DONE | Closed | Complete | In Sync |
| #77 | VALIDATING | Closed | Complete | In Sync |
| #78 | **HACKING** (restaurado) | Closed | Complete | In Sync |

### 10. Delivery permaneceu inalterado?

**SIM — verificado por SHA-256.**

| Arquivo | Hash antes | Hash depois | Status |
|---|---|---|---|
| derived-state-76.json | b4b4d084... | b4b4d084... | ✅ IDÊNTICO |
| derived-state-77.json | 41857ac1... | 41857ac1... | ✅ IDÊNTICO |
| derived-state-78.json | ea46eb8f... | ea46eb8f... | ✅ IDÊNTICO |
| timelines/76.json | 180e677f... | 180e677f... | ✅ IDÊNTICO |
| timelines/77.json | 4cb783a8... | 4cb783a8... | ✅ IDÊNTICO |
| timelines/78.json | 0a4d1da9... | 0a4d1da9... | ✅ IDÊNTICO |

Nenhum evento `prodops.diligence.*` foi inserido nas Delivery Timelines.

### 11. Quais métricas Datadog foram confirmadas?

Confirmadas via API query (não apenas HTTP 202):

| Métrica | Valor | Esperado |
|---|---|---|
| runtime.diligence.blocked | **1.0** | >= 1 |
| runtime.diligence.drift.detected | **1.0** | >= 1 |
| runtime.diligence.findings.open | **1.0** | >= 1 |
| runtime.diligence.repairs.completed | **1.0** | >= 1 |
| runtime.diligence.features.closed | **3.0** | = 3 |

### 12. A Dashboard mostrou os estados intermediários?

**SIM.** Dashboard `kij-n25-sui` (Iteration 5) criada com Section 4b — EXCEPTION PATHS contendo 6 Query Values reais (Blocked, Drift, Findings Open, Repairing, Repairs Done, Closed). As métricas aparecem na janela de execução do demo-run-id.

### 13. O ciclo Sync completo passou?

**SIM.** Issues #76 e #77 completaram `Capture → Attach → Promote → Close`. Estados `Promoting`, `Promoted`, `Closing`, `Closed` visíveis no GitHub Project durante execução.

### 14. O ciclo Async completo passou?

**SIM.** Issue #78 completou `Scan → Divergence.Detected → Flag → Repair → Promote → Close`. Estados `Scanning`, `Drift`, `Flagged`, `Repairing`, `Repaired` visíveis durante execução.

### 15. A Iteration 5 pode ser marcada como Completed?

**SIM.** Todos os critérios da Definition of Done foram satisfeitos.

---

## Definition of Done — Checklist

- [x] Scenario A chegou a Closed.
- [x] Scenario B bloqueou realmente (derived-state ausente).
- [x] Promote não executou durante o bloqueio (Block idx=2 < Promote idx=6).
- [x] Block.Resolved permitiu retomada do checkpoint correto.
- [x] Scenario C introduziu drift real (oem-state=BOOTSTRAPPING via GraphQL).
- [x] Divergence foi detectada (GitHub ≠ Derived State).
- [x] Finding HIGH foi criado (FND-202607272251-78).
- [x] Repair consultou `derived-state-78.json` (não GitHub).
- [x] GitHub foi reparado a partir do Derived State (oem-state=HACKING restaurado).
- [x] Sync e Async completos foram validados.
- [x] Datadog confirmou as cinco métricas (via query — não só HTTP 202).
- [x] Dashboard `kij-n25-sui` exibiu estados de exceção (Section 4b).
- [x] Delivery Timelines permaneceram inalteradas (SHA-256 idênticos).
- [x] GitHub terminou consistente (Closed/Complete/In Sync para todos).
- [x] Todas as evidências foram criadas (12/12 artefatos).
- [x] Nenhuma credencial foi exposta.

---

## Validação automatizada

```
validate-demo.sh --demo-run-id exp-014-exc-2026-07-27-2249 --mode exception-paths
Result: 53/53 PASS
```

---

## Sumário de execução

| Campo | Valor |
|---|---|
| demo-run-id | exp-014-exc-2026-07-27-2249 |
| Runtime version | 0.3.0 |
| Início | 2026-07-27T22:49:20Z |
| Fim | 2026-07-27T22:52:35Z |
| Duração | ~3m15s |
| Total CloudEvents | 33 (todos validados CloudEvents 1.0) |
| GitHub mutations | ~40 |
| Datadog metrics emitidas | 7 tipos × múltiplas emissões |
| Validação automatizada | 53/53 PASS |

---

## Dashboard

| Campo | Valor |
|---|---|
| ID | `kij-n25-sui` |
| Título | ProdOps Runtime — Delivery Tracked by Diligence |
| Seções | 9 (1–8 + 4b Exception Paths) |
| Widgets | ~49 |
| Nova seção | 4b — EXCEPTION PATHS: Blocked, Drift, Findings Open, Repairing, Repairs Done, Closed |

---

## Evidências geradas

```
evidence/diligence-exception-paths/
├── workspace-validation.md           ← Incremento 1 ✅
├── scenario-a-happy-path.md          ← Incremento 3 ✅
├── scenario-b-block-and-resume.md    ← Incremento 3 ✅
├── scenario-c-drift-flag-repair.md   ← Incremento 3 ✅
├── finding-FND-202607272251-78.json  ← gerado em runtime ✅
├── github-before-after.json          ← gerado em runtime ✅
├── datadog-validation.json           ← atualizado com valores reais ✅
├── delivery-state-preservation.md   ← SHA-256 confirmados ✅
├── timeline-validation.md            ← 8/10/15 eventos confirmados ✅
├── diligence-exception-paths-report.md ← este arquivo ✅
├── demo-run-id.txt                   ← exp-014-exc-2026-07-27-2249 ✅
└── delivery-baseline-sha256.txt      ← baseline SHA-256 ✅

evidence/recordings/exp-014-exc-2026-07-27-2249/
├── demo-summary.json                 ← type: exception-paths ✅
└── diligence-timelines/
    ├── diligence-76.json             ← 8 eventos ✅
    ├── diligence-77.json             ← 10 eventos ✅
    └── diligence-78.json             ← 15 eventos ✅
```

---

## ✅ EXP-014 Iteration 5 — COMPLETED
