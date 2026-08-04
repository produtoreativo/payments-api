# Product Intent — PI-RT-002

> **Localização canônica:** `prodops/artifacts/business-intents/PI-RT-002.md`

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-RT-002` |
| **Título** | Continuous Operational Trail — trail contínuo por phase durante execução |
| **Origin Stream** | Technology |
| **Data de registro** | 2026-08-04 |
| **Business Signal de origem** | [#135](https://github.com/produtoreativo/payments-api/issues/135) — Qualidade operacional Runtime v0.11.0 |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |

---

## Objetivo

Garantir que o trail operacional de cada issue é registrado de forma contínua — durante a execução de cada phase, não apenas no final — e que o downstream-agent documenta suas ações no trail à medida que executa o loop de issues.

> "Queremos que o trail de uma Feature seja uma narrativa contínua da execução — com entradas em cada phase — não um dump final. Isso permite auditoria em tempo real e diagnóstico de falhas mid-flight."

---

## Hipótese

> **O downstream-agent pode ser instruído a escrever entradas de trail após cada phase concluída, e cada skill pode emitir trail entries ao completar sua execução — sem mudanças no schema de eventos ou no pipeline.**

---

## Escopo

### Problemas mapeados

| # | Problema | Signal |
|---|---|---|
| 1 | downstream-agent não documenta ações durante execução do loop de issues | #135 item 1 |
| 2 | Trail de cada Work Item registrado apenas ao final, não durante phases individuais | #135 item 5 |

### O que está fora do escopo

- Mudanças no formato CloudEvents
- Integração do trail com Datadog (coberto por PI-RT-003)

---

## Critérios de sucesso

1. Ao término de cada phase (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote), uma entrada é adicionada ao trail da issue antes de avançar à próxima phase
2. O downstream-agent registra no GitHub Issue comment as ações executadas em cada step do loop (qual phase iniciou, qual concluiu, qual issue está processando)
3. Um trail parcial de uma execução interrompida mid-flight permite diagnóstico até a última phase executada

---

## Perguntas em aberto

- [ ] O trail deve ir para o GitHub Issue comment, para um arquivo `trails/<slug>.md`, ou ambos?
- [ ] O downstream-agent deve usar o emit-event para Trail.Phase.Completed ou escrever diretamente em arquivo?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [#135](https://github.com/produtoreativo/payments-api/issues/135) | Aberto |
| Business Intent | `prodops/artifacts/business-intents/PI-RT-002.md` | Este arquivo |
