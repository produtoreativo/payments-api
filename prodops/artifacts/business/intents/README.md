# Intents

> **Nota de nomenclatura:** Este diretório foi originalmente chamado de `business-intents/` e o conceito era chamado de "Business Intent". A nomenclatura canônica atual é **Intent** com um **Origin Stream** declarado. O caminho canônico atual é `prodops/artifacts/business/intents/`. Ver [`framework/glossary.md`](../../../framework/glossary.md#intent).

Uma **Intent** representa uma intenção de gerar valor ainda não comprometida com implementação. É o ponto de entrada único do Framework ProdOps para qualquer mudança, independente de sua origem.

## O que é uma Intent

- Uma intenção de gerar valor ainda não comprometida
- Tem exatamente um Origin Stream: Business, Enterprise, Team ou Technology
- Pode ser: novo Value Stream, oportunidade, problema de negócio, necessidade operacional, hipótese, requisito de compliance, melhoria de processo, evolução técnica
- Ainda não existe experimento, backlog ou plano de entrega

## Os quatro Origin Streams

| Origin Stream | Representa |
|---|---|
| **Business** | Mercado, cliente, produto — receita, conversão, adoção, retenção |
| **Enterprise** | Compliance, regulação, auditoria, parceiros, governança corporativa |
| **Team** | Processo, automações, produtividade, onboarding, fluxo de trabalho |
| **Technology** | Plataforma, segurança, infraestrutura, observabilidade, confiabilidade |

→ [Definição detalhada de cada Origin Stream](../../../framework/origin-streams.md)

## O que acontece após o registro

A Intent entra em Exploration. O Continuous Assessment decide o próximo passo:

```
Intent (com Origin Stream declarado)
  ↓
Exploration (Discovery / Upstream)
  ↓
Observable Business Contract (OBC)
  ↓
Upstream (exploração) ou Downstream (entrega comprometida)
```

→ [Fluxo completo do Framework](../../../framework/flow.md)

## Como registrar uma Intent

Utilize o template em [`prodops/templates/business-intents/`](../../../templates/business-intents/).

## Intents ativas

*(registrar aqui à medida que intents forem criadas)*

| Intent | Origin Stream | Status |
|---|---|---|
| [Split Payment — Múltiplos Pagamentos no Checkout](./split-payment.md) | Business | Em Exploration |
