# Hierarquia de Backlogs

O Framework ProdOps organiza o trabalho em uma hierarquia de cinco backlogs, cada um representando um nível crescente de comprometimento.

```
Tracking List
      │  item investigado e reconhecido como Intent
      ▼
Icebox Backlog          ← OBC nasce aqui
      │  priorizado para planejamento estratégico
      ▼
Roadmap Backlog         ← vive fora do repositório
      │  comprometido para uma Release
      ▼
Release Backlog
      │  organizado operacionalmente
      ▼
Iteration Backlog
      │  trabalho pronto para iniciar
      ▼
Delivery
```

O trabalho nunca pula níveis sem justificativa explícita registrada no OBC.

---

## Tracking List

**Propósito:** Ponto de entrada do Framework. Captura qualquer sinal que ainda não foi compreendido o suficiente para ser tratado como um compromisso.

**Contém:**

- Perguntas, dúvidas, problemas observados
- Oportunidades e ideias
- Riscos sinalizados
- Hipóteses a investigar
- Feedbacks recebidos
- Requisitos incompletos
- Conceitos confusos
- Sinais de incidentes e postmortems
- Demandas de stakeholders sem refinamento

**Compromisso:** Nenhum. Não existe OBC. Não existe Issue. O objetivo é investigar se o item representa uma Intent válida.

**Quando avançar:** Quando o item tiver sido compreendido o suficiente para ser reconhecido como uma Intent e entrar no Icebox.

**Artefato canônico:** `prodops/artifacts/product/tracking-list.md`

---

## Icebox Backlog

**Propósito:** Primeiro backlog oficial do produto. Quando um item entra no Icebox, ele passa a ser tratado como uma Intent reconhecida.

**O que acontece ao entrar no Icebox:**

- O item é reconhecido como uma Intent válida do Framework.
- Nasce seu OBC (Observable Business Contract) — inicialmente como rascunho (draft).
- O OBC torna-se o identificador permanente daquele trabalho.
- O OBC começa a registrar o histórico de evolução: por quais backlogs passou e quando.

**Compromisso:** O item é reconhecido como relevante, mas ainda sem compromisso de entrega ou data.

**Quando avançar:** Quando o item tiver evidência suficiente para entrar no planejamento estratégico (Roadmap).

**Artefato canônico:** `prodops/artifacts/product/icebox-backlog.md`

---

## Roadmap Backlog

**Propósito:** Representa o planejamento estratégico do produto. Agrupa Releases de um ou múltiplos produtos e repositórios dentro de um horizonte de planejamento.

**Características:**

- Não pertence ao repositório — vive em ferramentas externas (GitHub Projects, Jira Roadmap, Azure DevOps Plans, planilha estratégica).
- Pode agrupar Release Backlogs de múltiplos produtos ou repositórios.
- Representa compromissos de negócio e alinhamentos estratégicos.
- É composto por um ou mais Release Backlogs.

**Compromisso:** Comprometimento estratégico — o produto pretende entregar isso em um horizonte definido.

**Quando avançar:** Quando o item for comprometido para uma Release específica.

**Artefato canônico:** Ferramenta externa de gestão (não há arquivo canônico neste repositório). O OBC registra quando o item entrou no Roadmap.

---

## Release Backlog

**Propósito:** Representa tudo que faz parte de uma Release. Todo item presente neste backlog possui compromisso formal de entrega.

**Características:**

- Um Release pode participar de um Roadmap ou existir de forma independente.
- Contém apenas itens com OBC committed e critérios de aceite definidos.
- Um Release pode ter um ou mais Iteration Backlogs.

**Compromisso:** Compromisso de entrega — o time assumiu que este item estará no release.

**Quando avançar:** Quando o item for planejado para uma Iteration específica.

**Artefato canônico:** `prodops/artifacts/plans/iteration-plan.md` (seção "Iteration Plan recomendado" com status `Entrou`).

---

## Iteration Backlog

**Propósito:** Representa a organização operacional do trabalho dentro de uma Release. É o backlog imediatamente antes da Delivery.

**Pode representar:**

- Sprint
- Kanban
- Semana
- Ciclo operacional
- O próprio Release, quando não houver subdivisão

**Um Release pode ter uma ou várias Iterations.**

**Compromisso:** O time iniciará a implementação nesta Iteration. Todos os pré-requisitos da Delivery devem estar satisfeitos.

**Pré-requisitos obrigatórios para sair da Iteration para Delivery:**
- OBC committed em `prodops/artifacts/obcs/`
- BDD Feature committed em `prodops/artifacts/bdd/`
- Entrada no Iteration Plan com status `Entrou`
- Riscos documentados em `prodops/journeys/assessment/risks.md`
- Entrada no Reliability Plan em `prodops/journeys/assessment/reliability-plans/`

**Artefato canônico:** `prodops/artifacts/plans/iteration-plan.md` (seção "Iteration Backlog identificado").

---

## Observable Business Contract (OBC) como identificador permanente

O OBC nasce quando uma Intent entra no Icebox. Ele acompanha o trabalho por toda a sua vida.

### Ciclo de vida do OBC

| Fase | Estado do OBC | O que acontece |
|---|---|---|
| Tracking List | Não existe | O item ainda não é uma Intent reconhecida |
| Icebox | Draft | OBC criado como rascunho; captura a Intent e hipóteses iniciais |
| Discovery / Exploration | Draft em refinamento | OBC refinado com aprendizados do experimento; critérios emergem |
| Assessment Review | Candidato a committed | OBC revisado por PM + Tech Lead |
| Release / Iteration Backlog | Committed | OBC aprovado; critérios mensuráveis e verificáveis; Downstream pode iniciar |
| Delivery | Committed (em execução) | OBC guia a implementação; BDD Feature o operacionaliza |
| Operation | Committed (validado) | OBC validado em produção; pode ser estendido por novas Intents |

### O que o OBC registra

O OBC não é apenas documentação funcional. Ele é o **histórico vivo do trabalho**:

- Intent original e Origin Stream
- Por quais backlogs passou e quando
- Decisões tomadas e descartadas
- Critérios de aceite e como evoluíram
- Referências a experimentos, riscos e Reliability Plan
- Evidências de validação em produção

---

## GitHub Issue como representação operacional

Uma GitHub Issue não é a origem do trabalho no Framework ProdOps.

Ela é uma **representação operacional** de um compromisso já assumido.

**Quando nasce uma Issue:**

- Normalmente, quando um OBC entra em um **Release Backlog** ou **Iteration Backlog**.
- A Issue representa o trabalho pronto para ser executado pela Delivery.
- A Issue referencia o OBC — não o substitui.

**O Framework é independente de ferramenta.** GitHub Issues, Jira Cards, Azure DevOps Work Items são representações operacionais do mesmo OBC em ferramentas diferentes. O OBC é a fonte de verdade; a Issue é a instância de execução.

---

## Diligence como guardiã da hierarquia

A Diligence é a jornada responsável por manter a hierarquia de backlogs sincronizada.

> **Princípio:** A Diligence é a guardiã da consistência do sistema de trabalho do ProdOps. Ela garante que o estado de cada Observable Business Contract permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

**O que a Diligence mantém sincronizado:**

- Estado do OBC em cada backlog (Icebox, Roadmap, Release, Iteration)
- Representações operacionais nas ferramentas (GitHub Issues, Jira, Azure DevOps)
- Rastreabilidade Intent → OBC → Issue → PR → Release → Operation
- Consistência entre artefatos ProdOps e ferramentas externas

A Diligence nunca implementa software. Ela governa o sistema de trabalho que alimenta a Delivery.

→ [Jornada Diligence](../journeys/diligence/README.md)

---

## Referências

- `prodops/artifacts/product/tracking-list.md` — Tracking List
- `prodops/artifacts/product/icebox-backlog.md` — Icebox Backlog
- `prodops/artifacts/obcs/` — OBCs committed
- `prodops/artifacts/plans/iteration-plan.md` — Release e Iteration Backlog
- `prodops/framework/glossary.md` — definições canônicas
- `prodops/journeys/diligence/README.md` — Jornada Diligence
