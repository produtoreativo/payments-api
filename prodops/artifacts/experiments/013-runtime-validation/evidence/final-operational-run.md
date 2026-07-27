# Final Operational Run — EXP-013 Iteration 7
# Non-Uniform Scenario: DONE / VALIDATING / HACKING

**Execution date:** 2026-07-27T15:44Z–15:47Z
**Script:** `prodops/runtime/scripts/bootstrap-non-uniform.sh`
**runtime-version:** 0.3.0
**Runtime Doctor:** PASS (13/13 — DD_APP_KEY agora presente)

---

## Correlation IDs (Iteration 7 Final Run)

| Issue | Feature | Correlation ID | Target State |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX | `8c296acd-849b-49d4-a812-0fb186c673b7` | DONE |
| #77 | FTR-002: Invoice Cartão | `e63de2fc-a11b-445c-a433-7e735ce456ba` | VALIDATING |
| #78 | FTR-003: Confirmação Pagamento | `e1eaf136-db1b-45ea-932b-7818d38f9620` | HACKING |

---

## Execution Results

### FTR-001 (#76) — 15 events → DONE

| # | CloudEvent Type | Timestamp | State After |
|---|---|---|---|
| 1 | prodops.delivery.bootstrap.started | 15:44:19Z | BOOTSTRAPPING |
| 2 | prodops.delivery.bootstrap.completed | 15:44:27Z | BOOTSTRAPPING |
| 3 | prodops.delivery.hack.started | 15:44:31Z | HACKING |
| 4 | prodops.delivery.hack.completed | 15:44:39Z | HACKING |
| 5 | prodops.delivery.sync.started | 15:44:44Z | SYNCING |
| 6 | prodops.delivery.sync.completed | 15:44:52Z | SYNCING |
| 7 | prodops.delivery.finish.started | 15:44:55Z | FINISHING |
| 8 | prodops.delivery.finish.completed | 15:45:03Z | FINISHING |
| 9 | prodops.delivery.ship.started | 15:45:06Z | SHIPPING |
| 10 | prodops.delivery.ship.completed | 15:45:14Z | SHIPPING |
| 11 | prodops.delivery.validate.started | 15:45:19Z | VALIDATING |
| 12 | prodops.shared.gate.passed | 15:45:27Z | VALIDATING |
| 13 | prodops.delivery.validate.completed | 15:45:31Z | VALIDATING |
| 14 | prodops.delivery.promote.started | 15:45:35Z | PROMOTING |
| 15 | prodops.delivery.promote.completed | 15:45:43Z | **DONE** |

### FTR-002 (#77) — 11 events → VALIDATING

| # | CloudEvent Type | Timestamp | State After |
|---|---|---|---|
| 1 | prodops.delivery.bootstrap.started | 15:45:51Z | BOOTSTRAPPING |
| 2 | prodops.delivery.bootstrap.completed | 15:46:00Z | BOOTSTRAPPING |
| 3 | prodops.delivery.hack.started | 15:46:03Z | HACKING |
| 4 | prodops.delivery.hack.completed | 15:46:10Z | HACKING |
| 5 | prodops.delivery.sync.started | 15:46:14Z | SYNCING |
| 6 | prodops.delivery.sync.completed | 15:46:22Z | SYNCING |
| 7 | prodops.delivery.finish.started | 15:46:25Z | FINISHING |
| 8 | prodops.delivery.finish.completed | 15:46:33Z | FINISHING |
| 9 | prodops.delivery.ship.started | 15:46:36Z | SHIPPING |
| 10 | prodops.delivery.ship.completed | 15:46:44Z | SHIPPING |
| 11 | prodops.delivery.validate.started | 15:46:47Z | **VALIDATING** |

### FTR-003 (#78) — 3 events → HACKING

| # | CloudEvent Type | Timestamp | State After |
|---|---|---|---|
| 1 | prodops.delivery.bootstrap.started | 15:46:55Z | BOOTSTRAPPING |
| 2 | prodops.delivery.bootstrap.completed | 15:47:02Z | BOOTSTRAPPING |
| 3 | prodops.delivery.hack.started | 15:47:06Z | **HACKING** |

---

## CloudEvent Validation

29/29 CloudEvents validados (PASS em ambos os gates — producer e timeline).

---

## Derived State Final

```
derived-state-76.json → state: DONE       | last-event-type: prodops.delivery.promote.completed
derived-state-77.json → state: VALIDATING | last-event-type: prodops.delivery.validate.started
derived-state-78.json → state: HACKING    | last-event-type: prodops.delivery.hack.started
```

---

## Datadog Confirmation

- 29 pontos enviados via `runtime.event.received` — HTTP 202 em todos
- Confirmação via `/api/v1/query` (DD_APP_KEY):

| Filtro | Pontos (30 min) | Status API |
|---|---|---|
| `service:payments-api` | 95 total acumulado | ok |
| `issue:76` | 31 | ok |
| `issue:77` | 22 | ok |
| `issue:78` | 6 | ok |

Dashboard: https://app.datadoghq.com/dashboard/e43-cy6-dti/prodops-runtime--exp-013-delivery-happy-path

---

## GitHub Project Confirmation

Lido via GraphQL após execução:

| Issue | oem-state | oem-last-event |
|---|---|---|
| #76 | DONE | prodops.delivery.promote.completed |
| #77 | VALIDATING | prodops.delivery.validate.started |
| #78 | HACKING | prodops.delivery.hack.started |

GitHub Project: https://github.com/orgs/produtoreativo/projects/25
