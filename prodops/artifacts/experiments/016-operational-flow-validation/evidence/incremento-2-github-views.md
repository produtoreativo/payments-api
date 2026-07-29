# EXP-016 — Incremento 2: GitHub Project Views

**Data:** 2026-07-29

---

## Views Criadas para EXP-016

| View # | Nome | Layout | Criada em |
|--------|------|--------|-----------|
| 8 | 05 — Active Features | BOARD | 2026-07-29T13:21:24Z |
| 9 | 06 — Executive Overview | TABLE | 2026-07-29T13:21:32Z |

**Nota:** "05 — Active Features" usa `filter: label:"journey:delivery"` para mostrar exclusivamente Features Delivery. "06 — Executive Overview" exibe todos os itens do projeto em modo tabela com campos executivos.

---

## Estado Final — Todas as Views (project #25)

| View # | Nome | Layout | Propósito EXP-016 |
|--------|------|--------|-------------------|
| 2 | 01 — Delivery Timeline | BOARD | Delivery Board + Delivery Timeline |
| 4 | 03 — Diligence Tracking | BOARD | Diligence Board |
| 5 | 04 — Runtime Reconciliation | TABLE | Reconciliação runtime |
| 7 | 02 - Iteration Plan | BOARD | Contexto do Iteration Plan |
| 8 | 05 — Active Features | BOARD | Active Features (filtrado por journey:delivery) |
| 9 | 06 — Executive Overview | TABLE | Executive Overview (todos os itens) |

**Nota de configuração:** `group_by` não é setável via API REST (422 "not a permitted key"). As views de board devem ser configuradas manualmente no GitHub UI para agrupar por `oem-state` (Delivery Timeline, Active Features) e `diligence-status` (Diligence Board). Esse comportamento é herdado das views existentes do EXP-014.

---

## Links das Views

| View | URL |
|------|-----|
| 01 — Delivery Timeline | https://github.com/orgs/produtoreativo/projects/25/views/2 |
| 03 — Diligence Tracking | https://github.com/orgs/produtoreativo/projects/25/views/4 |
| 05 — Active Features | https://github.com/orgs/produtoreativo/projects/25/views/8 |
| 06 — Executive Overview | https://github.com/orgs/produtoreativo/projects/25/views/9 |

**Resultado Incremento 2:** ✓ 6 views disponíveis, cobrindo todos os requisitos de demonstração do EXP-016.
