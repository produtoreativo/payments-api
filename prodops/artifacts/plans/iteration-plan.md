# Iteration Plan — v0.5.0

> **Propósito:** Escopo de entrega aprovado para esta iteração. Contém os itens selecionados, a estratégia de execução, o detalhamento de cada fase e os critérios de saída.
>
> → [Iteration Backlog](../product/backlogs/iteration-backlog.md)

## Histórico

| Versão | Escopo | Status |
|---|---|---|
| v0.2.0 | DS-40: create-invoice-boleto | ✅ Concluído — PR #87 merged |
| v0.3.0 | Trilha A: Runtime Fix (send.sh + Lead Time + Status field) | ✅ Concluído |
| v0.4.0 | Trilha B: DS-38 create-invoice via Pix | ✅ Concluído — PR #89 merged |
| **v0.5.0** | **DS-39 · DS-42 · DS-43 · DS-41** | 🔄 Em execução |

---

## Escopo da iteração

| # | DS | Issue | Feature | Dependência | OBC | BDD | E2E | Status |
|---|---|-------|---------|-------------|-----|-----|-----|--------|
| 1 | DS-39 | [#39](https://github.com/produtoreativo/payments-api/issues/39) | payment-confirmation: confirmar pagamento aprovado via webhook do provedor | — | ✓ | ✓ | ✓ | 🔄 Em execução (parado em FINISHING) |
| 2 | DS-42 | [#42](https://github.com/produtoreativo/payments-api/issues/42) | api-token-validation: garantir acesso autenticado por token de API | — | ✓ | ✓ | ✓ | 🔄 Em execução (parado em SYNCING) |
| 3 | DS-43 | [#43](https://github.com/produtoreativo/payments-api/issues/43) | webhook-configuration: configurar webhook de notificação por token de API | DS-42 | ✓ | ✓ | ✓ | 🔄 Em execução (parado em FINISHING) |
| 4 | DS-41 | [#41](https://github.com/produtoreativo/payments-api/issues/41) | credit-card-authorization-confirmation: aceitar pagamento com cartão de crédito hospedado | — | ✓ | ✓ | ✓ | ✅ DONE — PR #104 |

---

## Critérios de saída da iteração

- ✅ PRs #100, #102, #103, #104 merged em `main`.
- ✅ Evento `prodops.delivery.promote.completed` emitido para issues #39, #42, #43, #41.
- ✅ KPI Lead Time registrado automaticamente no Promote de cada item (9 dias/item).
- ✅ Issues #39, #42, #43, #41 fechadas no GitHub.
- ✅ Diligence concluída para cada item: evidence capturada, attached, promoted e closed.
