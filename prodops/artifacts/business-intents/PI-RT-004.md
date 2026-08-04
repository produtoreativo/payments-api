# Product Intent — PI-RT-004

> **Localização canônica:** `prodops/artifacts/business-intents/PI-RT-004.md`

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-RT-004` |
| **Título** | Iteration Lifecycle Automation — auto-close e assignees |
| **Origin Stream** | Technology |
| **Data de registro** | 2026-08-04 |
| **Business Signal de origem** | [#135](https://github.com/produtoreativo/payments-api/issues/135) — Qualidade operacional Runtime v0.11.0 |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Promovido para Product Backlog — 2026-08-04 |

---

## Objetivo

Completar a automação do ciclo de vida de uma Iteration — fechando automaticamente a issue de rastreamento quando todas as issues são promovidas com sucesso, e preenchendo os assignees das issues a partir das credenciais do Context Engineer que executou o downstream.

> "Queremos que o encerramento de uma Iteration seja completamente automático: a issue de rastreamento fechada, assignees preenchidos, sem nenhuma ação manual após o último Promote.Completed."

---

## Hipótese

> **O downstream-agent já tem acesso ao número da tracking issue da iteração (criada no Plan Bootstrap) e às credenciais do Context Engineer (via `gh` CLI). Faltam apenas os steps de auto-close e assignee no loop de encerramento do downstream.**

---

## Escopo

### Problemas mapeados

| # | Problema | Signal |
|---|---|---|
| 1 | Issue de rastreamento da iteração não fechada automaticamente ao encerrar com sucesso | #135 item 6 |
| 2 | Assignees não preenchidos a partir das credenciais do Context Engineer | #135 item 7 |

### O que está fora do escopo

- Auto-close em caso de falha parcial (escopo: apenas encerramento com sucesso total)
- Notificações externas (Slack, email)

---

## Critérios de sucesso

1. Após o último `Promote.Completed` da iteração, a issue de rastreamento é fechada automaticamente com um comment de encerramento contendo o sumário (DS-IDs, PRs, datas)
2. Ao criar cada issue de feature no Plan Bootstrap, o assignee é preenchido com o usuário GitHub do Context Engineer que está executando o downstream
3. A issue de rastreamento também tem assignee preenchido no momento da criação

---

## Perguntas em aberto

- [ ] O auto-close da tracking issue deve ocorrer no downstream-agent (Iteration Closure step) ou no emit-event dispatcher via `Delivery.Plan.Bootstrap.Completed`?
- [ ] O assignee deve ser o mesmo para todas as issues da iteração, ou pode variar por DS-ID?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [#135](https://github.com/produtoreativo/payments-api/issues/135) | Aberto |
| Business Intent | `prodops/artifacts/business-intents/PI-RT-004.md` | Este arquivo |
| OBC Draft | `prodops/artifacts/obcs/rt-iteration-lifecycle-automation.md` | Draft |
