# Feature Restart — Execução

**Data:** 2026-07-29  
**Issue:** #78 — FTR-003: Confirmação de Pagamento — Webhook

---

## Contexto pré-Restart

| Campo | Valor |
|-------|-------|
| Estado derivado | HACKING |
| Timeline (eventos) | 3 (Bootstrap.Started, Bootstrap.Completed, Hack.Started) |
| Correlation-ID anterior | `912b411c-ee70-4cf2-896c-a110d5c052a4` |
| Razão do bloqueio | Journey abandonada em HACKING sem Hack.Completed, Sync, Finish ou Promote |

---

## Dry-run (validação prévia)

```json
{
  "status": "dry-run",
  "restart-id": "RST-78-20260729T141954Z",
  "new-correlation-id": "fde5cc00-beab-482c-bac9-40f9ec31fb20",
  "previous-correlation-id": "912b411c-ee70-4cf2-896c-a110d5c052a4",
  "current-state": "HACKING",
  "timeline-events-preserved": 3,
  "events-to-emit": ["Delivery.Restart.Requested","Delivery.Restart.Started","Delivery.Restart.Completed"]
}
```

---

## Restart RST-1 (aplicado a #78)

| Campo | Valor |
|-------|-------|
| Restart-ID | `RST-78-20260729T142003Z` |
| Novo Correlation-ID | `ccd352e0-af94-4152-89eb-49cb147b898c` |
| Correlation-ID anterior | `912b411c-ee70-4cf2-896c-a110d5c052a4` |
| Eventos preservados | 3 |
| Status | completed |
| Solicitado em | 2026-07-29T14:20:03Z |
| Concluído em | 2026-07-29T14:20:46Z |
| Idempotency-key | `78\|912b411c-...\|[reason]\|full` |

**Eventos emitidos pelo RST-1:**
- `prodops.delivery.restart.requested` — accepted ✓
- `prodops.delivery.restart.started` — accepted ✓
- `prodops.delivery.restart.completed` — accepted ✓

---

## Restart RST-2 (teste de idempotência)

O segundo Restart foi criado como resultado direto do teste de idempotência — explicação detalhada em `idempotency-analysis.md`.

| Campo | Valor |
|-------|-------|
| Restart-ID | `RST-78-20260729T142214Z` |
| Novo Correlation-ID | `7b670ccf-1c1f-47cb-a1de-b7c9a0ab653f` |
| Correlation-ID anterior | `ccd352e0-af94-4152-89eb-49cb147b898c` (novo corr do RST-1) |
| Eventos preservados | 6 |
| Status | completed |
| Idempotency-key | `78\|ccd352e0-...\|[reason]\|full` (chave diferente do RST-1) |

---

## Imutabilidade da Timeline

A Timeline original foi **preservada integralmente**. Nenhum evento foi editado, excluído ou reordenado.

Antes do Restart:
```
[bootstrap.started, bootstrap.completed, hack.started]  (3 eventos)
```

Após RST-1:
```
[bootstrap.started, bootstrap.completed, hack.started,
 restart.requested, restart.started, restart.completed]  (6 eventos)
```

Após RST-2:
```
[... 6 anteriores ..., restart.requested, restart.started, restart.completed]  (9 eventos)
```

---

## Artefatos criados

| Arquivo | Descrição |
|---------|-----------|
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142003Z.json` | Artefato RST-1 |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142003Z-requested.json` | Evidência emit-event RST-1 Requested |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142003Z-started.json` | Evidência emit-event RST-1 Started |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142003Z-completed.json` | Evidência emit-event RST-1 Completed |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142214Z.json` | Artefato RST-2 |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142214Z-requested.json` | Evidência emit-event RST-2 Requested |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142214Z-started.json` | Evidência emit-event RST-2 Started |
| `prodops/artifacts/runtime/restarts/78/RST-78-20260729T142214Z-completed.json` | Evidência emit-event RST-2 Completed |
