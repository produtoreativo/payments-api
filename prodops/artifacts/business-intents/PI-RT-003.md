# Product Intent — PI-RT-003

> **Localização canônica:** `prodops/artifacts/business-intents/PI-RT-003.md`

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-RT-003` |
| **Título** | Dashboard Evolution — cycle time, iteration filter e labels |
| **Origin Stream** | Technology |
| **Data de registro** | 2026-08-04 |
| **Business Signal de origem** | [#135](https://github.com/produtoreativo/payments-api/issues/135) — Qualidade operacional Runtime v0.11.0 |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Promovido para Product Backlog — 2026-08-04 |

---

## Objetivo

Evoluir os dashboards Datadog do Runtime para incluir métricas de cycle time por phase, filtro por Iteration ID e labels corretos — tornando o painel executivo observável por iteração e por phase de entrega.

> "Queremos que o dashboard Datadog mostre quanto tempo cada Feature gasta em cada phase (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote), com filtro por iteração ativa, e com labels que reflitam os nomes canônicos das phases — não os nomes internos dos CloudEvents."

---

## Hipótese

> **O Datadog já recebe os eventos com os dados necessários (timestamps por phase, issue tag, iteration tag). Faltam apenas as métricas derivadas de cycle time e os filtros/labels adequados nas queries e nos widgets existentes.**

---

## Escopo

### Problemas mapeados

| # | Problema | Signal |
|---|---|---|
| 1 | Dashboard sem métricas de cycle time por phase | #135 item 4a |
| 2 | Dashboard sem filtro por Iteration ID | #135 item 4b |
| 3 | Labels dos widgets com nomes incorretos (nomes internos CloudEvents vs nomes canônicos) | #135 item 4c |

### O que está fora do escopo

- Novos tipos de métricas além de cycle time e lead time
- Alertas (cobertura por PI futura)
- Mudanças no pipeline emit-event (coberto por PI-RT-001)

---

## Critérios de sucesso

1. Widget de cycle time por phase exibe tempo médio de Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote por iteração
2. Template variable `$iteration_id` disponível em todos os dashboards Runtime — permite filtrar por `v0.11.0`, `v0.12.0`, etc.
3. Labels dos widgets usam nomes canônicos: "Bootstrap", "Hack", "Sync", "Finish", "Ship", "Validate", "Promote" — não `prodops.delivery.bootstrap.started`

---

## Perguntas em aberto

- [ ] O cycle time por phase deve ser calculado como diferença de timestamps no Datadog (log-based metric) ou enviado explicitamente via `send.sh` como uma métrica separada?
- [ ] A tag `iteration:<id>` já está presente nos eventos emitidos, ou precisa ser adicionada ao `send.sh`?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [#135](https://github.com/produtoreativo/payments-api/issues/135) | Aberto |
| Business Intent | `prodops/artifacts/business-intents/PI-RT-003.md` | Este arquivo |
| OBC Draft | `prodops/artifacts/obcs/rt-dashboard-evolution.md` | Draft |
