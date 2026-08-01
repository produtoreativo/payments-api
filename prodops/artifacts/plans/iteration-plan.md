# Iteration Plan — v0.6.0

> **Propósito:** Escopo de entrega aprovado para esta iteração. Contém os itens selecionados, a estratégia de execução, o detalhamento de cada fase e os critérios de saída.
>
> → [Iteration Backlog](../product/backlogs/iteration-backlog.md)

## Histórico

| Versão | Escopo | Status |
|---|---|---|
| v0.2.0 | DS-40: create-invoice-boleto | ✅ Concluído — PR #87 merged |
| v0.3.0 | Trilha A: Runtime Fix (send.sh + Lead Time + Status field) | ✅ Concluído |
| v0.4.0 | Trilha B: DS-38 create-invoice via Pix | ✅ Concluído — PR #89 merged |
| v0.5.0 | DS-39 · DS-42 · DS-43 · DS-41 | ✅ Concluído |
| **v0.6.0** | **DS-39 · DS-42 · DS-43 · DS-41** | 🔄 Em andamento |

---

## Escopo da iteração

| # | DS | Issue | Feature | Dependência | OBC | BDD | E2E | Status |
|---|---|-------|---------|-------------|-----|-----|-----|--------|
| 1 | DS-39 | [#106](https://github.com/produtoreativo/payments-api/issues/106) | payment-confirmation: confirmar pagamento aprovado via webhook do provedor | — | ✓ | ✓ | ✓ | 🔄 Pendente |
| 2 | DS-42 | [#107](https://github.com/produtoreativo/payments-api/issues/107) | api-token-validation: garantir acesso autenticado por token de API | — | ✓ | ✓ | ✓ | 🔄 Pendente |
| 3 | DS-43 | [#108](https://github.com/produtoreativo/payments-api/issues/108) | webhook-configuration: configurar webhook de notificação por token de API | DS-42 | ✓ | ✓ | ✓ | 🔄 Pendente |
| 4 | DS-41 | [#109](https://github.com/produtoreativo/payments-api/issues/109) | credit-card-authorization-confirmation: aceitar pagamento com cartão de crédito hospedado | — | ✓ | ✓ | ✓ | 🔄 Pendente |

---

## Critérios de saída da iteração

- [ ] PRs merged em `main` para cada issue.
- [ ] Evento `prodops.delivery.promote.completed` emitido para issues #106, #107, #108, #109.
- [ ] KPI Lead Time calculável: `Bootstrap.Started` presente nos timelines de cada issue.
- [ ] Issues #106, #107, #108, #109 fechadas no GitHub.
- [ ] Diligence concluída para cada item: evidence capturada, attached, promoted e closed.
