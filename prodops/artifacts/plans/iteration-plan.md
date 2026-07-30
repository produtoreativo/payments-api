# Iteration Plan — v0.2.0

> **Propósito:** Escopo de entrega aprovado para esta iteração. Contém os itens selecionados, a estratégia de execução e os critérios de saída.
>
> → [Iteration Backlog](../product/backlogs/iteration-backlog.md)

## Escopo da iteração

| # | Issue | Feature | Status |
|---|-------|---------|--------|
| 1 | [#40](https://github.com/produtoreativo/payments-api/issues/40) | create-invoice-boleto: criar invoice via Boleto Bancário no gateway Payments | Em andamento |

## Critérios de saída

- BDD Feature `create-invoice-boleto.feature` com todos os cenários passando (CI Sync + CI Async).
- PR aprovado e merged em `main`.
- Diligence concluída: evidence capturada, attached, promoted e closed.
- Evento `prodops.delivery.promote.completed` emitido para a issue #40.
