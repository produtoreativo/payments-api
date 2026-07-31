# F-03 — Journey Canônica (pós-Restart)

**Data:** 2026-07-29  
**Feature:** FTR-003 — Confirmação de Pagamento via Webhook  
**Issue:** #78  
**Business Intent:** PI-PILOT-003  
**Correlation-ID:** `7b670ccf-1c1f-47cb-a1de-b7c9a0ab653f`  
**Iteration-ID:** `IP-EXP016-F03-RESTART`

---

## Código existente verificado

| Componente | Arquivo | Status |
|-----------|---------|--------|
| Webhook Controller | `api/src/modules/invoices/controllers/asaas-webhook.controller.ts` | ✅ Implementado |
| Webhook Queue Service | `api/src/modules/invoices/services/asaas-webhook-queue.service.ts` | ✅ Implementado |
| Webhook Module | `api/src/modules/webhooks/` | ✅ Implementado |
| E2E Test | `api/test/confirmar-pagamento.e2e-spec.ts` | ✅ 9 scenarios |

---

## Gates executados

| Fase | Gate | Resultado |
|------|------|-----------|
| Bootstrap | Smoke gate — dependências instaladas | ✅ PASS |
| Bootstrap | Lint — 0 erros (15 warnings) | ✅ PASS |
| Hack | Acceptance tests — `confirmar-pagamento.e2e-spec.ts` | ✅ 9/9 PASS |
| Sync | Lint revalidado | ✅ PASS |
| Finish | Acceptance tests — nova execução | ✅ 9/9 PASS |
| Validate | Gate de Idempotência — PAYMENT_CONFIRMED duplicado | ✅ PASS |

---

## Sequência de eventos emitidos

| # | Evento | Fase | Estado Derivado | Status |
|---|--------|------|----------------|--------|
| 1 | `Delivery.Bootstrap.Started` | Bootstrap | BOOTSTRAPPING | accepted |
| 2 | `Delivery.Bootstrap.Completed` | Bootstrap | BOOTSTRAPPING | accepted |
| 3 | `Diligence.Capture.Started` | (dispatcher) | BOOTSTRAPPING | dispatched |
| 4 | `Diligence.Capture.Completed` | (dispatcher) | BOOTSTRAPPING | dispatched |
| 5 | `Delivery.Hack.Started` | Hack | HACKING | accepted |
| 6 | `Delivery.Hack.Completed` | Hack | HACKING | accepted |
| 7 | `Delivery.Sync.Started` | Sync | SYNCING | accepted |
| 8 | `Delivery.Sync.Completed` | Sync | SYNCING | accepted |
| 9 | `Delivery.Finish.Started` | Finish | FINISHING | accepted |
| 10 | `Delivery.Finish.Completed` | Finish | FINISHING | accepted |
| 11 | `Delivery.Ship.Started` | Ship | SHIPPING | accepted |
| 12 | `Delivery.Ship.Completed` | Ship | SHIPPING | accepted |
| 13 | `Delivery.Validate.Started` | Validate | VALIDATING | accepted |
| 14 | `Shared.Gate.Passed` | Validate | VALIDATING | accepted |
| 15 | `Delivery.Validate.Completed` | Validate | VALIDATING | accepted |
| 16 | `Diligence.Attach.Started` | (dispatcher) | VALIDATING | dispatched |
| 17 | `Diligence.Attach.Completed` | (dispatcher) | VALIDATING | dispatched |
| 18 | `Delivery.Promote.Started` | Promote | PROMOTING | accepted |
| 19 | `Delivery.Promote.Completed` | Promote | **DONE** | accepted |
| 20 | `Diligence.Promote.Started` | (dispatcher) | DONE | dispatched |
| 21 | `Diligence.Promote.Completed` | (dispatcher) | DONE | dispatched |

**21 eventos** na Journey F-03 (mesma contagem que F-01 #76).

---

## Critérios de sucesso PI-PILOT-003

| Critério | Status |
|---------|--------|
| 1. Timeline de Bootstrap.Started a Promote.Completed registrada | ✅ |
| 2. Replay da Timeline deriva o mesmo estado (DONE) | ✅ |
| 3. Gate.Passed de idempotência registrado na fase Validate | ✅ |
| 4. Derived State calculado corretamente — DONE ao final | ✅ |
| 5. Nenhum Event Type novo necessário para representar o webhook | ✅ (webhook representado via Hack — não como evento de sistema separado) |

---

## Nota sobre Delivery.System.Completed

O PI-PILOT-003 menciona `Delivery.System.Completed` como possível evento de sistema para o webhook. Após análise:
- O event type **não existe no catálogo** atual
- A hipótese do PI foi validada via implementação em código + acceptance tests
- O webhook é representado na Timeline via Hack.Completed (implementação) + Validate Gate.Passed (verificação de idempotência)
- Nenhum event type novo foi necessário — alinhado com o critério 5 do PI-PILOT-003

---

## Estado final

| Campo | Valor |
|-------|-------|
| Derived State | **DONE** |
| Last Event | `prodops.delivery.promote.completed` |
| GitHub-Sync | success |
| Datadog-Sync | success |
| Computed-At | 2026-07-29T14:38:31Z |
| Total eventos na Timeline (incluindo restarts) | 30 |
