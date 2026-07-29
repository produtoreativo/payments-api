# Feature Restart — Atualização do Catálogo

**Data:** 2026-07-29  
**Arquivo:** `prodops/runtime/catalog/events.yaml`

---

## Eventos adicionados

| Event Type | Cloud Event Type | alters-state |
|-----------|------------------|--------------|
| `Delivery.Restart.Requested` | `prodops.delivery.restart.requested` | false |
| `Delivery.Restart.Started` | `prodops.delivery.restart.started` | false |
| `Delivery.Restart.Completed` | `prodops.delivery.restart.completed` | false |

## Critérios de design

- `alters-state: false` — Restart é um meta-evento; não altera o Derived State da Feature
- Sem `new-state` — a Journey continua do mesmo estado derivado
- Journey: `Delivery` — pertence ao domínio Delivery (não Diligence)
- Cycle: `Restart` — ciclo próprio, semanticamente distinto de Bootstrap

## Catálogo após atualização

- **Total de eventos:** 35 (era 32)
- **Eventos Delivery:** 18 (era 15)
- **Eventos Shared:** 1
- **Eventos Diligence:** 16

## Recursão

Restart events não estão em `delivery-diligence.yaml` (subscriptions). O Dispatcher (Step 6) retorna `status: skipped` para esses tipos — sem risco de loop.

---

**Resultado:** Catálogo atualizado sem breaking changes. Backward compatible.
