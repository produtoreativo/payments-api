# OBC — Observable Business Contract

O **Observable Business Contract** é o contrato vivo que representa uma intenção de negócio durante todo o seu ciclo de vida. É a fonte de verdade do trabalho — conecta negócio, produto, arquitetura, engenharia, operação, observabilidade e confiabilidade. Não deve existir outro documento exercendo esse papel.

→ [Template de OBC](../templates/obcs/obc.md)
→ [OBCs committed do produto](../artifacts/obcs/)
→ [Fluxo do framework](flow.md)
→ [Hierarquia de backlogs](backlogs.md)

---

## O que é

**Definição:** Artefato de produto que descreve o comportamento esperado de uma capability em termos observáveis: o que o sistema deve fazer, quais eventos emite, quais níveis de serviço oferece e como responde a falhas.

**Propósito:** Ser a linguagem compartilhada entre produto, engenharia e operação ao longo de toda a vida da intenção. O OBC não termina com o Delivery — continua evoluindo durante a Operation.

**Criação:** Nasce quando uma Intent é aceita. No fluxo global, ao entrar no Business Intent Backlog. No fluxo local, ao entrar no Product Intent Backlog. O OBC existe **antes** do Discovery, **antes** do Upstream, **antes** do Downstream.

**Nota histórica:** anteriormente definido de forma incorreta como "Outcome-Based Criterion". A definição canônica é **Observable Business Contract**.

---

## Composição

Um OBC é composto por sete seções. As seções marcadas como obrigatórias para Minimum OBC devem estar presentes antes da entrada no Iteration Backlog.

| Seção | Conteúdo | Obrigatório para Minimum OBC |
|---|---|---|
| **Status** | Estado atual (Draft / Minimum OBC / Active / Operational / Archived) e localização no backlog | Sim |
| **Business Outcome** | O resultado de negócio que a capability entrega, em linguagem de produto | Sim |
| **Observable Events** | Tabela de eventos que o sistema emite; cada evento tem significado e dimensões rastreáveis | Sim |
| **Initial SLIs** | Indicadores de nível de serviço iniciais com targets declarados | Sim |
| **Reliability Rules** | Regras de confiabilidade que governam o comportamento em falhas e casos extremos | Sim |
| **Response Contract** | Contrato de resposta da API ou evento (payload esperado, campos obrigatórios) | Sim |
| **Related Artifacts** | Links para BDD Feature, Iteration Plan, Icebox, OBCs relacionados | Recomendado |

### Status

Indica em qual estado o OBC se encontra e onde está localizado no ciclo de backlogs. Deve ser atualizado a cada transição.

### Business Outcome

Descreve o resultado que o sistema entrega do ponto de vista do negócio — não a implementação técnica. Deve responder: *para quem, o quê e com qual garantia*.

Pode conter uma subseção "Em linguagem executiva" com explicação sem jargão técnico, útil para alinhamento com stakeholders não técnicos.

### Observable Events

Lista os eventos que o sistema emite para sinalizar cada desfecho relevante. Cada evento deve ter:
- **Nome canônico** do evento (ex: `invoice.created`)
- **Significado** — o que esse evento representa
- **Dimensões obrigatórias** — campos que o evento deve carregar para rastreabilidade

Eventos de falha são tão importantes quanto eventos de sucesso. A ausência de um evento dentro de uma janela de SLO é, em si, um sinal observável.

### Initial SLIs

Define os indicadores iniciais de nível de serviço com targets quantitativos. Devem ser observáveis via eventos declarados acima. O alinhamento entre eventos e SLIs é o que torna o OBC verificável.

### Reliability Rules

Regras explícitas que governam o comportamento do sistema em situações de falha, retentativa, idempotência e degradação. São os invariantes que a implementação não pode violar.

### Response Contract

Define o contrato de resposta da capability — payload retornado, campos obrigatórios, campos condicionais. Serve como contrato entre o produtor e os consumidores da capability.

### Related Artifacts

Lista os artefatos diretamente relacionados ao OBC: BDD Feature correspondente, posição no Iteration Plan, posição no Icebox, e OBCs com dependência direta.

---

## Estados

| Estado | Quando | Descrição |
|---|---|---|
| **Draft** | Business Intent Backlog / Product Intent Backlog | Criado; pode estar incompleto; registra intenção inicial, hipóteses e aprendizados |
| **Minimum OBC** | Iteration Backlog | Menor conjunto de informações necessárias para entrada em Delivery; gate entre Discovery e Delivery |
| **Active** | Iteration Plan → Delivery | Em execução; acompanha implementação, evidências, validações e decisões |
| **Operational** | Operation | Funcionalidade em produção; atualizado com informações operacionais |
| **Archived** | — | Não faz mais parte da evolução ativa; histórico preservado |

---

## Ciclo de vida

| Backlog / Fase | Estado do OBC | O que acontece |
|---|---|---|
| Global Tracking List / Repository Tracking List | Não existe | O item ainda não é uma Intent reconhecida |
| Business Intent Backlog (fluxo global) | Draft | OBC criado; captura a Intent e hipóteses iniciais |
| Product Intent Backlog (fluxo local) | Draft | OBC criado ao ser aceito pelo Product Owner |
| Icebox (Discovery) | Draft em refinamento | Discovery refina o OBC; critérios emergem; Upstream pode ocorrer |
| Assessment Review | Candidato a Minimum OBC | OBC revisado por PM + Tech Lead; seções obrigatórias validadas |
| Iteration Backlog | Minimum OBC | OBC mínimo validado; Downstream pode iniciar |
| Iteration Plan / Delivery | Active | Guia a implementação; BDD Feature o operacionaliza |
| Operation | Operational | Em produção; complementado com métricas, SLOs, incidentes, postmortems |
| — | Archived | Intenção encerrada; histórico preservado |

O OBC registra o **histórico vivo do trabalho**: por quais backlogs passou, quando, decisões tomadas, como os critérios evoluíram, referências a experimentos e riscos.

---

## OBC no Upstream

Durante o Upstream, o OBC permanece em Draft. Pode ser alterado livremente, pode estar incompleto, não bloqueia experimentos. Registra aprendizados, hipóteses e decisões produzidas pelos experimentos. Nenhuma Skill deve exigir OBC completo durante o Upstream.

OBCs produzidos dentro de experimentos Upstream permanecem no diretório do experimento (`prodops/journeys/discovery/experiments/<NNN-slug>/obcs/`) até a promoção formal para `prodops/artifacts/obcs/`.

---

## OBC no Downstream

Ao entrar no Downstream, o OBC deixa de ser apenas um registro — passa a ser o contrato operacional da entrega. É refinado no Icebox até atingir Minimum OBC, então controla toda a evolução das jornadas seguintes.

O conjunto mínimo exigido para iniciar o Downstream:
- OBC committed em `prodops/artifacts/obcs/<slug>.md` com estado Minimum OBC
- BDD Feature committed em `prodops/artifacts/bdd/<slug>.feature`
- Reliability Plan atualizado em `prodops/journeys/assessment/reliability-plans/`

---

## OBC e as Skills

Todas as Skills do Downstream utilizam o OBC como principal fonte de contexto. As Skills nunca geram informações paralelas que substituam o OBC. Novos artefatos produzidos por Skills complementam ou referenciam o OBC. O OBC permanece como a única fonte de verdade da intenção.

---

## Governança

| Campo | Valor |
|---|---|
| **Owner** | Product Manager + Tech Lead do item |
| **Onde nasce** | Business Intent Backlog (fluxo global) ou Product Intent Backlog (fluxo local) |
| **Artefato canônico** | `prodops/artifacts/obcs/<slug>.md` (quando committed) |
| **Quem modifica** | Product Manager, Tech Lead, engenheiros (com registro de mudanças) |
| **Quem aprova** | Product Manager + Tech Lead (Assessment Review) |
| **Consumidores** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Ciclo de vida** | Draft → Minimum OBC → Active → Operational → Archived |
| **Jornadas** | Discovery, Delivery, Operation, Assessment, Diligence |

---

## Localização dos artefatos

| Situação | Localização |
|---|---|
| OBC exploratório (em experimento Upstream) | `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md` |
| OBC committed (pronto para Downstream) | `prodops/artifacts/obcs/<slug>.md` |

Todo OBC committed deve ter arquivo próprio em `prodops/artifacts/obcs/`. Product Decks, Service Decks, BDD Features, Reliability Plans e demais artefatos devem referenciar o OBC correspondente sem duplicar sua definição.

---

## Quando não usar

Não usar OBC como substituto de tarefa técnica isolada ou ticket de bug sem Intent correspondente. GitHub Issues, Jira Cards e Azure DevOps Work Items são **representações operacionais** de um OBC já existente — não são o ponto de entrada do trabalho.

---

## Referências

→ [Template de OBC](../templates/obcs/obc.md)
→ [OBCs committed do produto](../artifacts/obcs/)
→ [Fluxo do framework](flow.md)
→ [Hierarquia de backlogs](backlogs.md)
→ [Governança de artefatos](artifact-governance.md)
→ [Fases: Concepção e Inception](phases.md)
→ [Jornada Discovery](../journeys/discovery/README.md)
→ [Reliability Plans](../journeys/assessment/reliability-plans/README.md)
