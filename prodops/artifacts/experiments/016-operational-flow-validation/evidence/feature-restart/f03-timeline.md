# F-03 — Timeline Completa (Issue #78)

**Data:** 2026-07-29  
**Total de eventos:** 30

---

## Estrutura da Timeline

A Timeline de #78 é um append-only log. Cada segmento foi produzido por uma execução distinta:

### Segmento 1 — Execução original (correlation-id: `912b411c`)

| # | Evento | Timestamp |
|---|--------|-----------|
| 1 | `prodops.delivery.bootstrap.started` | 2026-07-27T20:05:03Z |
| 2 | `prodops.delivery.bootstrap.completed` | 2026-07-27T20:05:15Z |
| 3 | `prodops.delivery.hack.started` | 2026-07-27T20:05:24Z |

### Segmento 2 — Restart RST-1 (correlation-id: `ccd352e0`)

| # | Evento | Timestamp |
|---|--------|-----------|
| 4 | `prodops.delivery.restart.requested` | 2026-07-29T14:20:X |
| 5 | `prodops.delivery.restart.started` | 2026-07-29T14:20:X |
| 6 | `prodops.delivery.restart.completed` | 2026-07-29T14:20:X |

### Segmento 3 — Restart RST-2 / Teste de Idempotência (correlation-id: `7b670ccf`)

| # | Evento | Timestamp |
|---|--------|-----------|
| 7 | `prodops.delivery.restart.requested` | 2026-07-29T14:22:X |
| 8 | `prodops.delivery.restart.started` | 2026-07-29T14:22:X |
| 9 | `prodops.delivery.restart.completed` | 2026-07-29T14:22:X |

### Segmento 4 — Journey Canônica F-03 (correlation-id: `7b670ccf`)

| # | Evento | Estado Derivado |
|---|--------|----------------|
| 10 | `prodops.delivery.bootstrap.started` | BOOTSTRAPPING |
| 11 | `prodops.delivery.bootstrap.completed` | BOOTSTRAPPING |
| 12 | `prodops.diligence.capture.started` | BOOTSTRAPPING |
| 13 | `prodops.diligence.capture.completed` | BOOTSTRAPPING |
| 14 | `prodops.delivery.hack.started` | HACKING |
| 15 | `prodops.delivery.hack.completed` | HACKING |
| 16 | `prodops.delivery.sync.started` | SYNCING |
| 17 | `prodops.delivery.sync.completed` | SYNCING |
| 18 | `prodops.delivery.finish.started` | FINISHING |
| 19 | `prodops.delivery.finish.completed` | FINISHING |
| 20 | `prodops.delivery.ship.started` | SHIPPING |
| 21 | `prodops.delivery.ship.completed` | SHIPPING |
| 22 | `prodops.delivery.validate.started` | VALIDATING |
| 23 | `prodops.shared.gate.passed` | VALIDATING |
| 24 | `prodops.delivery.validate.completed` | VALIDATING |
| 25 | `prodops.diligence.attach.started` | VALIDATING |
| 26 | `prodops.diligence.attach.completed` | VALIDATING |
| 27 | `prodops.delivery.promote.started` | PROMOTING |
| 28 | `prodops.delivery.promote.completed` | **DONE** |
| 29 | `prodops.diligence.promote.started` | DONE |
| 30 | `prodops.diligence.promote.completed` | DONE |

---

## Propriedade de Imutabilidade

- Os 3 eventos do Segmento 1 (execução original) **não foram alterados**
- Os 6 eventos dos Segmentos 2-3 (restarts) **preservaram a história completa**
- O Replay da Timeline (segmento 4 apenas) deriva o estado final: **DONE**

---

## Derived State final

```json
{
  "issue": "78",
  "state": "DONE",
  "last-event-type": "prodops.delivery.promote.completed",
  "runtime-correlation-id": "7b670ccf-1c1f-47cb-a1de-b7c9a0ab653f",
  "computed-at": "2026-07-29T14:38:31Z"
}
```
