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

- Gerencia a Global Tracking List, Business Intent Backlog, Global OBCs, Roadmap, Platform Releases e Milestones.
- Executa o OBC Partitioning para decompor Global OBCs em Local OBCs.
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
- Governa Repository Tracking List, Product Intent Backlog, Icebox, Iteration Backlog, Iteration Plan, Local OBCs, Reliability Plans.
- Este repositório (`payments-api`) é um Product Repository.

---

## Fluxo global (Portfolio → Product)

```
Global Tracking List
  ↓ reconhecido como Intent
Business Intent Backlog       ← Global OBC Draft nasce aqui
  ↓ Discovery no BIB
OBC Partitioning              ← Global OBC → Local OBCs
  ↓ Local OBCs direcionados
Product Intent Backlog        ← Local OBC Draft nasce aqui (ou chega via Partitioning)
```

## Fluxo local (Product)

```
Repository Tracking List
  ↓ Premortem + Análise de Risco Preliminar + Owner Approval
Product Intent Backlog        ← Local OBC Draft nasce aqui se ainda não existe
```

## Convergência — fluxo de Delivery

```
Product Intent Backlog
  ↓ Discovery (Icebox)
Icebox                        ← Local OBC em estado Refining
  ↓ Local OBC Committed validado
Iteration Backlog             ← Local OBC em estado Committed
  ↓ Local OBC committed + BDD committed
Iteration Plan                ← Local OBC em estado Implemented
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation                     ← Local OBC e Global OBC em estado Operational
  ↓
Refinamento Contínuo do OBC
```

---

## Governança dos artefatos de Plataforma

### Global Tracking List

| Campo | Valor |
|---|---|
| **Owner** | Portfolio (Product Manager Portfolio) |
| **Onde nasce** | Portfolio — qualquer sinal de plataforma sem compreensão suficiente |
| **Repositório** | `prodops-portfolio` (externo; referenciado, não replicado) |
| **Quem modifica** | Product Manager Portfolio, stakeholders autorizados |
| **Quem aprova** | Product Manager Portfolio |
| **Consumidores** | Business Intent Backlog, Assessment (Portfolio) |
| **Ciclo de vida** | Item criado → investigado → reconhecido como Intent (avança para Business Intent Backlog) ou descartado |
| **Jornadas** | Assessment (Portfolio) |

### Business Intent Backlog

| Campo | Valor |
|---|---|
| **Owner** | Portfolio (Product Manager Portfolio) |
| **Onde nasce** | Portfolio — Intent reconhecida na Global Tracking List |
| **Repositório** | `prodops-portfolio` (externo) |
| **Quem modifica** | Product Manager Portfolio |
| **Quem aprova** | Product Manager Portfolio |
| **Consumidores** | Roadmap, OBC Partitioning, Product Intent Backlog (via Local OBCs) |
| **OBC** | Global OBC Draft criado ao entrar neste backlog |
| **Ciclo de vida** | Intent aceita → Global OBC Draft criado → Discovery → OBC Partitioning → distribuído para PIBs |
| **Jornadas** | Assessment (Portfolio), Discovery (Upstream/Downstream) |

### Roadmap

| Campo | Valor |
|---|---|
| **Owner** | Portfolio |
| **Onde nasce** | Portfolio — Business Intent priorizada para horizonte estratégico |
| **Repositório** | Ferramenta externa (GitHub Projects, Jira, Azure DevOps) |
| **Quem modifica** | Product Manager Portfolio |
| **Quem aprova** | Portfolio Leadership |
| **Consumidores** | Platform Release, Product Repositories |
| **Ciclo de vida** | Intent priorizada → entra no Roadmap → comprometida para Platform Release |
| **Jornadas** | Assessment (Portfolio), Diligence |

### Platform Release

| Campo | Valor |
|---|---|
| **Owner** | Portfolio |
| **Onde nasce** | Portfolio — conjunto de Business Intents comprometidas para entrega coordenada |
| **Repositório** | `prodops-portfolio` (externo) |
| **Quem modifica** | Portfolio Manager |
| **Quem aprova** | Portfolio Leadership |
| **Consumidores** | Product Intent Backlog (Product Repositories), Workspace |
| **Ciclo de vida** | Planejada → comprometida → distribuída para repositórios → validada no Workspace |
| **Jornadas** | Delivery (Workspace), Assessment (Portfolio) |

---

## Governança dos artefatos de Product Repository

### Repository Tracking List

| Campo | Valor |
|---|---|
| **Owner** | Product Owner do repositório |
| **Onde nasce** | Product Repository — qualquer sinal local não compreendido |
| **Artefato canônico** | `prodops/artifacts/product/tracking-list.md` |
| **Quem modifica** | Qualquer membro do time |
| **Quem aprova** | Product Owner |
| **Consumidores** | Product Intent Backlog (via Premortem + Análise de Risco Preliminar + Owner Approval), Assessment |
| **Critério de entrada** | Qualquer sinal de negócio, técnico ou operacional sem compromisso |
| **Critério de saída** | Aprovado pelo Product Owner → Product Intent Backlog; ou descartado |
| **Jornadas** | Assessment, Diligence, Operation (como destino de aprendizados operacionais) |

### Product Intent Backlog

| Campo | Valor |
|---|---|
| **Owner** | Product Owner |
| **Onde nasce** | Product Repository — ponto de convergência dos fluxos global e local |
| **Artefato canônico** | Gerenciado pelo Diligence; instâncias rastreadas no Iteration Plan |
| **Quem modifica** | Product Owner + Diligence |
| **Quem aprova** | Product Owner (Owner Approval obrigatório para fluxo local) |
| **Consumidores** | Icebox, Assessment |
| **OBC** | Local OBC Draft criado ao entrar (se ainda não existia via OBC Partitioning) |
| **Critério de entrada** | Fluxo global: Local OBC via OBC Partitioning; Fluxo local: Premortem + Análise de Risco Preliminar + Owner Approval |
| **Critério de saída** | Item aceito no Icebox para Discovery |
| **Jornadas** | Assessment, Diligence |

### Icebox

| Campo | Valor |
|---|---|
| **Owner** | Product Owner |
| **Onde nasce** | Product Repository — item aceito no Product Intent Backlog |
| **Artefato canônico** | `prodops/artifacts/product/icebox-backlog.md` |
| **Quem modifica** | Product Team (Product Manager, Tech Lead, engenheiros) |
| **Quem aprova** | Product Owner + Tech Lead (para saída do Icebox) |
| **Consumidores** | Iteration Backlog |
| **OBC** | Local OBC em estado Refining (Discovery); atinge Committed ao sair |
| **Critério de entrada** | Item aceito no Product Intent Backlog |
| **Critério de saída** | Local OBC Committed validado → Iteration Backlog |
| **Jornadas** | Discovery (Downstream), Assessment |

### Iteration Backlog

| Campo | Valor |
|---|---|
| **Owner** | Product Owner |
| **Onde nasce** | Product Repository — item com Local OBC Committed saindo do Icebox |
| **Artefato canônico** | `prodops/artifacts/plans/iteration-backlog.md` |
| **Quem modifica** | Product Owner, Diligence |
| **Quem aprova** | Product Owner (priorização) |
| **Consumidores** | Iteration Plan |
| **OBC** | Local OBC Committed (ao sair para Iteration Plan) |
| **Critério de entrada** | Local OBC Committed + BDD Feature draft |
| **Critério de saída** | Local OBC committed em arquivo + BDD Feature committed + entrada no Iteration Plan |
| **Jornadas** | Diligence, Assessment |

### Iteration Plan

| Campo | Valor |
|---|---|
| **Owner** | Tech Lead / Product Owner |
| **Onde nasce** | Product Repository — execução da iteração em andamento |
| **Artefato canônico** | `prodops/artifacts/plans/iteration-plan.md` |
| **Quem modifica** | Equipe de Delivery |
| **Quem aprova** | Product Owner + Tech Lead (para entrada de itens) |
| **Consumidores** | Delivery (CI Sync, CI Async), Release Trail |
| **OBC** | Local OBC em estado Implemented (durante Delivery) |
| **Critério de entrada** | Local OBC committed + BDD Feature committed + Reliability Plan |
| **Critério de saída** | Delivery concluído + evidências registradas |
| **Jornadas** | Delivery, Diligence |

### Global OBC

→ **Definição completa, composição, ciclo de vida e governança:** [`obc.md`](obc.md)

| Campo | Valor |
|---|---|
| **Owner** | Portfolio PM |
| **Onde nasce** | Business Intent Backlog |
| **Artefato canônico** | `prodops/artifacts/obcs/global/<slug>.md` |
| **Ciclo de vida** | Draft → Refining → Operational → Archived |
| **Jornadas** | Discovery (BIB), Operation |

### Local OBC

→ **Definição completa, composição, ciclo de vida e governança:** [`obc.md`](obc.md)

| Campo | Valor |
|---|---|
| **Owner** | Product Manager + Tech Lead do produto |
| **Onde nasce** | Product Intent Backlog (após OBC Partitioning ou Owner Approval fluxo local) |
| **Artefato canônico** | `prodops/artifacts/obcs/local/<slug>.md` (quando committed) |
| **Ciclo de vida** | Draft → Refining → Committed → Implemented → Operational → Archived |
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
| **Critério de saída** | Aprovado antes da entrada no Iteration Plan |
| **Jornadas** | Assessment, Delivery, Operation |

---

## Matriz de responsabilidades

| Artefato | Owner | Quem modifica | Quem aprova | Consumidores principais |
|---|---|---|---|---|
| Global Tracking List | Portfolio PM | Portfolio PM + stakeholders | Portfolio PM | Business Intent Backlog |
| Business Intent Backlog | Portfolio PM | Portfolio PM | Portfolio PM | Roadmap, OBC Partitioning |
| Roadmap | Portfolio | Portfolio PM | Portfolio Leadership | Platform Release |
| Platform Release | Portfolio | Portfolio Manager | Portfolio Leadership | PIB, Workspace |
| Repository Tracking List | Product Owner | Qualquer membro do time | Product Owner | PIB (via aprovação) |
| Product Intent Backlog | Product Owner | Product Owner + Diligence | Product Owner | Icebox |
| Icebox | Product Owner | Product Team | PO + Tech Lead | Iteration Backlog |
| Iteration Backlog | Product Owner | PO + Diligence | Product Owner | Iteration Plan |
| Iteration Plan | Tech Lead / PO | Equipe de Delivery | PO + Tech Lead | Delivery, Release Trail |
| Global OBC | Portfolio PM | Portfolio PM, Tech Leads | Portfolio PM | Local OBCs, Roadmap |
| Local OBC | PM + Tech Lead | PM, TL, engenheiros | PM + Tech Lead (Assessment Review) | Delivery, BDD, Release Trail |
| Reliability Plan | Tech Lead + SRE | TL, SRE, engenheiros | TL + PO | Iteration Plan, Delivery |
| BDD Feature | Tech Lead | PM, TL, engenheiros | Tech Lead | Hack, testes, Release Trail |
| Release Trail | Delivery team | Equipe de Delivery (append-only) | — | Operation, retrospectivas |

---

## Referências

→ [Hierarquia de backlogs](backlogs.md)
→ [OBC: ciclo de vida completo](obc.md)
→ [Modelo operacional](operating-model.md)
→ [Fluxo oficial](flow.md)
