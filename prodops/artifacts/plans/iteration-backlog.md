# Iteration Backlog — Demandas Operacionais

> **Propósito:** Itens com OBC mínimo validado, prontos para Delivery imediata. A única decisão restante é a prioridade definida pelo Product Owner. Este backlog não é de refinamento — refinamento acontece no Icebox.
>
> Itens aqui podem entrar em Delivery assim que priorizados. Para entrar no Iteration Plan, precisam de OBC committed + BDD Feature committed.
>
> → [Hierarquia de backlogs](../../framework/backlogs.md)
> → [Escopo de entrega aprovado](iteration-plan.md) — para ver o que entrou/saiu/foi adiado

## Objetivo

Registrar demandas conhecidas que ainda precisam de refinamento, avaliação ou planejamento antes de serem incorporadas ao Iteration Plan ou a um OBC específico.

| ID | Área | Solicitação | Tipo | Prioridade | Status | Próximo Passo |
|----|------|-------------|------|------------|--------|---------------|
| TL-001 | Marketing | Adicionar Analytics para acompanhar a jornada e os resultados dos pagamentos. | Observabilidade de Negócio | Alta | Aberto | Refinar KPIs, eventos e dashboards necessários. |
| TL-002 | Vendas | Acompanhar indicadores de pagamentos e cancelamentos. | KPI de Negócio | Alta | Aberto | Definir métricas, fontes de dados e relatórios executivos. |
| TL-003 | Arquitetura | Implantar DataDog (MS-0172), instrumentar o Notifier e garantir que o Payments esteja completamente instrumentado. | Observabilidade Técnica | Alta | Aberto | Elaborar plano de instrumentação e atualizar o Reliability Plan. |
| TL-004 | Infraestrutura | Integrar o time de Payments ao modelo corporativo de Gestão de Incidentes da Magazine Siará. | Operação / Confiabilidade | Média | Aberto | Definir processo, runbooks, on-call e integrações com ITSM. |

---

# Critérios para saída do Iteration Backlog

Um item deixa o Iteration Backlog quando:

- Foi refinado suficientemente para compor um OBC.
- Foi descartado por decisão de negócio.
- Foi consolidado em um épico ou Iteration Plan.
- Foi implementado e encerrado.

---

# Relação com os artefatos do ProdOps

Cada item poderá originar ou atualizar:

- Product Deck
- Service Deck
- Observable Business Contract (OBC)
- Reliability Plan
- Iteration Plan
- Iteration Backlog

A Repository Tracking List representa demandas ainda em avaliação e serve como principal fonte de entrada para o Continuous Assessment.
