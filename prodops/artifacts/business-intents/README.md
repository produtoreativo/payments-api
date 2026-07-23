# Business Intents

> **Nota de nomenclatura:** A nomenclatura canônica é **Business Intent**. O path `prodops/artifacts/business-intents/` é preservado por compatibilidade. Ver [`framework/glossary.md`](../../framework/glossary.md#business-intent).

Uma **Business Intent** representa uma decisão estratégica de perseguir valor — nascida de um ou mais Business Signals. Não é um compromisso de implementação. um Business Signal pode gerar uma ou mais Business Intents (ou a Intent pode ser criada diretamente no BIB); a Business Intent possui um OBC como documento de contrato — o Global OBC co-nasce com a Intent; Local OBCs são criados por OBC Partitioning, um por produto.

## O que é uma Business Intent

- Uma decisão estratégica de perseguir valor, nascida de Business Signal(s)
- Tem exatamente um Origin Stream: Business, Enterprise, Team ou Technology
- Pode representar: novo Value Stream, oportunidade, problema de negócio, necessidade operacional, hipótese, requisito de compliance, melhoria de processo, evolução técnica
- Não é um compromisso de implementação — ainda não existe OBC committed, backlog ou plano de entrega

## Os quatro Origin Streams

| Origin Stream | Representa |
|---|---|
| **Business** | Mercado, cliente, produto — receita, conversão, adoção, retenção |
| **Enterprise** | Compliance, regulação, auditoria, parceiros, governança corporativa |
| **Team** | Processo, automações, produtividade, onboarding, fluxo de trabalho |
| **Technology** | Plataforma, segurança, infraestrutura, observabilidade, confiabilidade |

→ [Definição detalhada de cada Origin Stream](../../framework/origin-streams.md)

## O que acontece após o registro

A Business Intent entra em Exploration. O Continuous Assessment decide o próximo passo:

```
Business Signal (com Origin Stream declarado)
  ↓ (1:N, ou criado diretamente)
Business Intent (decisão estratégica)
  │  └─ OBC (documento de contrato — 4 dimensões: Business, Enterprise, Team, Technology)
  ↓
Exploration (Discovery / Upstream)
  ↓
Upstream (exploração) ou Downstream (entrega comprometida)
```

→ [Fluxo completo do Framework](../../framework/flow.md)

## Como registrar uma Business Intent

Utilize o template em [`prodops/templates/business-intents/`](../../templates/business-intents/).

## Business Intents ativas

*(registrar aqui à medida que Business Intents forem criadas)*

| Business Intent | Origin Stream | Status |
|---|---|---|
| [Split Payment — Múltiplos Pagamentos no Checkout](./split-payment.md) | Business | Em Exploration |
