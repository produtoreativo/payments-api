# Governança de Artefatos do ProdOps

Este documento define a governança de todos os artefatos do Framework ProdOps: onde cada artefato nasce, quem é responsável, quem pode alterá-lo, quem aprova suas mudanças, quem o consome e em quais jornadas participa.

→ [Hierarquia de backlogs](backlogs.md)
→ [Modelo operacional](operating-model.md)

---

## Princípios de Governança

1. **Cada artefato possui exatamente um Owner.** Nenhum artefato tem dois donos.
2. **Cada artefato possui uma única fonte de verdade.** Não deve existir o mesmo artefato duplicado em dois repositórios.
3. **Todo artefato pertence a exatamente um nível da arquitetura.** Framework, Portfolio, Workspace ou Product Repository.
4. **Aprovações ocorrem apenas nos pontos definidos pelo Framework.** Não há aprovações implícitas ou ad hoc.
5. **Todo artefato possui ciclo de vida claramente definido.** Nascimento, evolução e encerramento são documentados.
6. **Skills nunca geram informações que substituam o OBC.** Novos artefatos de Skills complementam ou referenciam o OBC.

---

## Papel de cada nível da arquitetura

### Framework (ProdOps Framework)

- Define padrões, jornadas, templates, Skills, validações e terminologia canônica.
- Não governa produtos, não governa Roadmaps, não governa backlogs de produto.
- Fornece o modelo que os demais níveis adotam.
- Repositório: `prodops-framework` (referência canônica documentada neste repositório como implementação de referência).

### Portfolio (ProdOps Portfolio)

- Gerencia a Portfolio Tracking List (Business Signals), Business Intent Backlog (Business Intents), Roadmap (VIEW sobre BIB), Platform Releases (VIEW sobre BIB) e Milestones.
- Decide o que a plataforma entrega, quando e em que sequência.
- Não implementa software diretamente.
- Repositório: `prodops-portfolio` (ainda não criado; conceitos documentados aqui como referência).

### Workspace (ProdOps Workspace)

- Integra múltiplos Product Repositories para execução e testes conjuntos.
- Não governa Backlogs, não governa Roadmaps, não cria Business Intents.
- Coordena exclusivamente a execução integrada entre Product Repositories.
- Repositório: `prodops-workspace` (ainda não criado; conceitos documentados aqui como referência).

### Product Repository

- Implementa e opera um produto específico.
- Governa Product Tracking List (Business Signals), Product Backlog (Business Intents), Icebox (VIEW), Iteration Backlog (VIEW), Release (VIEW), Iteration Plan, OBCs, Reliability Plans.
- Este repositório (`payments-api`) é um Product Repository.

---

## Fluxo global (Portfolio → Product)

```
Portfolio Tracking List
  ↓ Business Signal gera Business Intent
Business Intent Backlog       ← Global OBC Draft nasce aqui
  ↓ priorizado
  ├─ Roadmap [VIEW sobre BIB]
  └─ Platform Release [VIEW sobre BIB]
  ↓ aceito pelo Product Owner
Product Backlog
```

## Fluxo local (Product)

```
Product Tracking List
  ↓ Business Signal → Business Intent + Owner Approval
Product Backlog               ← Local OBC Draft nasce aqui se ainda não existe
```

## Convergência — fluxo de Delivery

```
Product Backlog
  ↓ VIEW Icebox — Discovery
Icebox [VIEW]
  ↓ OBC Committed
Iteration Backlog [VIEW]
  ↓ OBC committed + BDD committed
Iteration Plan
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation
```

---

## Governança dos artefatos de Plataforma

### Portfolio Tracking List

| Campo | Valor |
|---|---|
| **Owner** | Portfolio (Product Manager Portfolio) |
| **Contém** | APENAS Business Signals |
| **Onde nasce** | Portfolio — qualquer Business Signal de plataforma sem compreensão suficiente |
| **Repositório** | `prodops-portfolio` (externo; referenciado, não replicado) |
| **Quem modifica** | Product Manager Portfolio, stakeholders autorizados |
| **Quem aprova** | Product Manager Portfolio |
| **Consumidores** | Business Intent Backlog (quando Business Signal gera Business Intent) |
| **Ciclo de vida** | Business Signal criado → investigado → gera Business Intent (avança para Business Intent Backlog) ou descartado |
| **Jornadas** | Assessment (Portfolio) |

### Business Intent Backlog

| Campo | Valor |
|---|---|
| **Owner** | Portfolio (Product Manager Portfolio) |
| **Contém** | APENAS Business Intents |
| **Onde nasce** | Portfolio — Business Intent gerada de Business Signal da Portfolio Tracking List |
| **Repositório** | `prodops-portfolio` (externo) |
| **Quem modifica** | Product Manager Portfolio |
| **Quem aprova** | Product Manager Portfolio |
| **Consumidores** | Roadmap (VIEW), Platform Release (VIEW), Product Backlog (via OBC Partitioning) |
| **OBC** | Global OBC Draft criado ao entrar neste backlog |
| **Ciclo de vida** | Business Intent aceita → Global OBC Draft criado → Discovery → Roadmap/Platform Release (VIEWs) ou descartado |
| **Jornadas** | Assessment (Portfolio), Discovery (Upstream) |

### Roadmap (VIEW sobre Business Intent Backlog)

| Campo | Valor |
|---|---|
| **Owner** | Portfolio |
| **Natureza** | VIEW sobre o Business Intent Backlog — não é um backlog separado |
| **Onde nasce** | Portfolio — Business Intent posicionada em horizonte estratégico |
| **Repositório** | GitHub Projects (Views do Portfolio GitHub Project) |
| **Quem modifica** | Product Manager Portfolio |
| **Quem aprova** | Portfolio Leadership |
| **Consumidores** | Platform Release (VIEW), Product Repositories |
| **Ciclo de vida** | Business Intent posicionada em horizonte → comprometida para Platform Release |
| **Jornadas** | Assessment (Portfolio), Diligence |

### Platform Release (VIEW sobre Business Intent Backlog)

| Campo | Valor |
|---|---|
| **Owner** | Portfolio |
| **Natureza** | VIEW sobre o Business Intent Backlog — não é um backlog separado |
| **Onde nasce** | Portfolio — conjunto de Business Intents agrupadas para entrega coordenada |
| **Repositório** | `prodops-portfolio` (externo) / GitHub Projects (Views do Portfolio GitHub Project) |
| **Quem modifica** | Portfolio Manager |
| **Quem aprova** | Portfolio Leadership |
| **Consumidores** | Product Backlog (Product Repositories via OBC Partitioning), Workspace |
| **Ciclo de vida** | Planejada → comprometida → distribuída para repositórios → validada no Workspace |
| **Jornadas** | Delivery (Workspace), Assessment (Portfolio) |

---

## Governança dos artefatos de Product Repository

### Product Tracking List

| Campo | Valor |
|---|---|
| **Owner** | Product Owner do repositório |
| **Contém** | APENAS Business Signals |
| **Onde nasce** | Product Repository — qualquer Business Signal local não compreendido |
| **Artefato canônico** | `prodops/artifacts/product/backlogs/tracking-list.md` |
| **Quem modifica** | Qualquer membro do time |
| **Quem aprova** | Product Owner |
| **Consumidores** | Product Backlog (quando Business Signal gera Business Intent via Premortem + Owner Approval) |
| **Critério de entrada** | Qualquer Business Signal de negócio, técnico ou operacional sem compromisso |
| **Critério de saída** | Aprovado pelo Product Owner → gera Business Intent + entra no Product Backlog; ou descartado |
| **Jornadas** | Assessment, Diligence, Operation (como destino de aprendizados operacionais) |

### Product Backlog

| Campo | Valor |
|---|---|
| **Owner** | Product Owner |
| **Contém** | APENAS Business Intents (cada Intent possui um Local OBC como documento de contrato) |
| **Onde nasce** | Product Repository — ponto de convergência dos fluxos global e local |
| **Artefato canônico** | Gerenciado pelo Diligence; instâncias rastreadas no Iteration Plan |
| **Quem modifica** | Product Owner + Diligence |
| **Quem aprova** | Product Owner (Owner Approval obrigatório para fluxo local) |
| **Consumidores** | VIEW Icebox (Assessment, Discovery), VIEW Iteration Backlog (Delivery) |
| **OBC** | Local OBC Draft criado ao entrar (se ainda não existia via OBC Partitioning) |
| **Critério de entrada** | Fluxo global: Local OBC via OBC Partitioning aceito pelo Product Owner; Fluxo local: Business Signal → Business Intent + Premortem + Owner Approval |
| **Critério de saída** | Item entra na VIEW Icebox para Discovery |
| **Jornadas** | Assessment, Diligence |

### Icebox

| Campo | Valor |
|---|---|
| **Owner** | Product Owner |
| **Onde nasce** | Product Repository — item aceito no Product Backlog (VIEW sobre Product Backlog) |
| **Artefato canônico** | `prodops/artifacts/product/backlogs/icebox-backlog.md` |
| **Quem modifica** | Product Team (Product Manager, Tech Lead, engenheiros) |
| **Quem aprova** | Product Owner + Tech Lead (para saída do Icebox) |
| **Consumidores** | Iteration Backlog |
| **OBC** | Refining (Discovery); atinge Committed ao sair |
| **Critério de entrada** | Item no Product Backlog com Local OBC em estado Draft |
| **Critério de saída** | OBC Committed → Iteration Backlog |
| **Jornadas** | Discovery (Downstream), Assessment |

### Iteration Backlog

| Campo | Valor |
|---|---|
| **Owner** | Product Owner |
| **Onde nasce** | Product Repository — item com OBC Committed saindo do Icebox |
| **Artefato canônico** | `prodops/artifacts/product/backlogs/iteration-backlog.md` |
| **Quem modifica** | Product Owner, Diligence |
| **Quem aprova** | Product Owner (priorização) |
| **Consumidores** | Iteration Plan |
| **OBC** | Committed |
| **Critério de entrada** | OBC Committed + BDD Feature draft |
| **Critério de saída** | OBC committed + BDD Feature committed + entrada no Iteration Plan |
| **Jornadas** | Diligence, Assessment |

### Iteration Plan

| Campo | Valor |
|---|---|
| **Owner** | Tech Lead / Product Owner |
| **Onde nasce** | Product Repository — execução da iteração em andamento |
| **Artefato canônico** | `prodops/artifacts/governance/plans/iteration-plan.md` |
| **Quem modifica** | Equipe de Delivery |
| **Quem aprova** | Product Owner + Tech Lead (para entrada de itens) |
| **Consumidores** | Delivery (CI Sync, CI Async), Release Trail |
| **OBC** | In Delivery (durante Delivery) |
| **Critério de entrada** | OBC committed + BDD Feature committed + Reliability Plan quando os gatilhos canônicos de risco forem aplicáveis |
| **Critério de saída** | Delivery concluído + evidências registradas |
| **Jornadas** | Delivery, Diligence |

### Observable Business Contract (OBC)

| Campo | Valor |
|---|---|
| **Owner** | Product Manager + Tech Lead do item |
| **Onde nasce** | Business Intent Backlog (fluxo global) ou Product Backlog (fluxo local) |
| **Artefato canônico** | `prodops/artifacts/business/obcs/<slug>.md` (quando committed) |
| **Quem modifica** | Product Manager, Tech Lead, engenheiros (com registro de mudanças) |
| **Quem aprova** | Product Manager + Tech Lead (Assessment Review) |
| **Consumidores** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Ciclo de vida** | Draft → Refining → Committed → In Delivery → Operational → Archived |
| **Jornadas** | Discovery, Delivery, Operation, Assessment, Diligence |

### Reliability Plan

| Campo | Valor |
|---|---|
| **Owner** | Tech Lead + SRE |
| **Onde nasce** | Assessment — produzido durante Premortem ou Assessment Review |
| **Artefato canônico** | `prodops/journeys/assessment/reliability-plans/` |
| **Quem modifica** | Tech Lead, SRE, engenheiros |
| **Quem aprova** | Tech Lead + Product Owner |
| **Consumidores** | Iteration Plan, Delivery, Operation |
| **Critério de entrada** | Premortem concluído; riscos identificados |
| **Critério de saída** | Aprovado antes da entrada no Iteration Plan — aplicável apenas quando os gatilhos canônicos estiverem presentes |
| **Jornadas** | Assessment, Delivery, Operation |

---

## Matriz de responsabilidades

| Artefato | Owner | Quem modifica | Quem aprova | Consumidores principais |
|---|---|---|---|---|
| Portfolio Tracking List | Portfolio PM | Portfolio PM + stakeholders | Portfolio PM | Business Intent Backlog |
| Business Intent Backlog | Portfolio PM | Portfolio PM | Portfolio PM | Roadmap (VIEW), Platform Release (VIEW), Product Backlog |
| Roadmap (VIEW sobre BIB) | Portfolio | Portfolio PM | Portfolio Leadership | Platform Release |
| Platform Release (VIEW sobre BIB) | Portfolio | Portfolio Manager | Portfolio Leadership | Product Backlog, Workspace |
| Product Tracking List | Product Owner | Qualquer membro do time | Product Owner | Product Backlog (via aprovação) |
| Product Backlog | Product Owner | Product Owner + Diligence | Product Owner | VIEW Icebox, VIEW Iteration Backlog |
| Icebox (VIEW) | Product Owner | Product Team | PO + Tech Lead | VIEW Iteration Backlog |
| Iteration Backlog (VIEW) | Product Owner | PO + Diligence | Product Owner | Iteration Plan |
| Iteration Plan | Tech Lead / PO | Equipe de Delivery | PO + Tech Lead | Delivery, Release Trail |
| OBC | PM + Tech Lead | PM, TL, engenheiros | PM + Tech Lead (Assessment Review) | Delivery, BDD, Release Trail |
| Reliability Plan | Tech Lead + SRE | TL, SRE, engenheiros | TL + PO | Iteration Plan, Delivery |
| BDD Feature | Tech Lead | PM, TL, engenheiros | Tech Lead | Hack, testes, Release Trail |
| Release Trail | Delivery team | Equipe de Delivery (append-only) | — | Operation, retrospectivas |

---

## Referências

→ [Hierarquia de backlogs](backlogs.md)
→ [OBC: ciclo de vida completo](glossary.md#obc-observable-business-contract)
→ [Modelo operacional](operating-model.md)
→ [Fluxo oficial](flow.md)
