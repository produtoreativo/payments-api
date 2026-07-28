# Fundação Arquitetural — Product Lifecycle Journey
# ProdOps Framework

> Data: 2026-07-24
> Tipo: Análise arquitetural — somente leitura e proposta
> Status: RASCUNHO — aguardando revisão e aprovação

---

## 1. Executive Summary

Este documento propõe a fundação arquitetural da **Product Lifecycle Journey** — uma nova jornada
canônica do ProdOps Framework, identificada como necessária a partir da leitura completa da
documentação existente.

A Product Lifecycle Journey resolve um gap estrutural importante: nenhuma das cinco jornadas atuais
(Discovery, Delivery, Operation, Assessment, Diligence) assume responsabilidade explícita pela
**gestão do ciclo de vida completo de uma Business Intent / OBC** — da entrada no Product Backlog
até o estado Archived. As jornadas existentes operam sobre segmentos do fluxo, mas nenhuma detém
a máquina de estados do artefato que persiste por toda a vida do produto.

A necessidade dessa jornada já estava implícita na documentação: `knowledge-vs-execution.md` lista
`Product Lifecycle` como um dos GitHub Projects canônicos — ao lado de `Diligence` e `Operations`.
O presente documento transforma essa menção implícita em proposta arquitetural completa.

**Resultado esperado deste documento:**

| Artefato | Status |
|---|---|
| Definição canônica proposta | ✓ |
| Questão central definida | ✓ |
| Escopo explícito (CAN / CANNOT) | ✓ |
| Modelo de ciclo de vida dos artefatos | ✓ |
| Ciclos propostos (analogia com Diligence) | ✓ |
| Capabilities propostas | ✓ |
| GitHub Projects propostos | ✓ |
| Relações com outras jornadas | ✓ |
| Entradas e saídas | ✓ |
| Anti-padrões identificados | ✓ |
| Inconsistências na documentação | ✓ |
| Próximos passos sugeridos | ✓ |

**Nenhum arquivo existente foi modificado.** Este documento é exclusivamente de análise e proposta.

---

## 2. Fontes Analisadas

Todos os arquivos abaixo foram lidos na íntegra para esta análise:

### Foundation Files — Framework

| Arquivo | Propósito |
|---|---|
| `prodops/framework/ontology.md` | Hierarquia canônica de conceitos: Framework → Journey → Cycle → Phase → Capability → Skill → Step |
| `prodops/framework/glossary.md` | Definições lexicais de todos os termos (943 linhas) |
| `prodops/framework/knowledge-vs-execution.md` | Princípio fundacional: Knowledge Space vs. Execution Space |
| `prodops/framework/journeys/README.md` | Visão geral das 5 jornadas e seus fluxos |
| `prodops/exec/manifest.yaml` | Fonte única legível por máquina do Framework |
| `prodops/framework/execution-mapping/README.md` | Contrato declarativo artefato × operação × GitHub |
| `prodops/framework/execution-mapping/work-item-schema.md` | Schema canônico de Work Items |
| `prodops/framework/execution-mapping/matrix.md` | Matriz completa artefatos × operações × recursos |
| `AGENTS.md` | Roteador de agentes — regras invioláveis |

### Journey Documentation

| Arquivo | Propósito |
|---|---|
| `prodops/framework/journeys/diligence/README.md` | Definição canônica completa da jornada Diligence |
| `prodops/framework/journeys/diligence/workspace-reconciliation.md` | Capability Workspace Reconciliation |
| `prodops/framework/journeys/diligence/capabilities/README.md` | Catálogo de 6 Capabilities da Diligence |
| `prodops/framework/journeys/diligence/diligence-sync.md` | Ciclo síncrono: Capture → Attach → Promote → Close |
| `prodops/framework/journeys/discovery/README.md` | Jornada Discovery — Upstream e Downstream |
| `prodops/framework/journeys/delivery/README.md` | Jornada Delivery — CI Sync + CI Async |
| `prodops/framework/journeys/operation/README.md` | Jornada Operation |
| `prodops/framework/journeys/assessment/README.md` | Jornada Assessment |

### Framework Structural Files

| Arquivo | Propósito |
|---|---|
| `prodops/framework/backlogs.md` | Hierarquia completa de backlogs (390 linhas) |
| `prodops/framework/flow.md` | Fluxo oficial do Framework (304 linhas) |
| `prodops/framework/phases.md` | Lifecycle Stages: Concepção e Inception |

### Artifact Files

| Arquivo | Propósito |
|---|---|
| `prodops/artifacts/product/backlogs/tracking-list.md` | Product Tracking List atual do produto |
| `prodops/documentation-review-diligence-journey.md` | Precedente: formalização da Diligence Journey |

### Files Containing "Product Lifecycle" or "lifecycle" (grep)

| Arquivo | Menção relevante |
|---|---|
| `prodops/framework/knowledge-vs-execution.md` (linha 20) | `"ex.: Diligence, Product Lifecycle, Operations"` |
| `prodops/artifacts/experiments/001-credit-card-lifecycle/` | Lifecycle de cartão de crédito — experimento de produto |
| `prodops/README.en.md` | lifecycle mencionado como conceito de produto |
| `prodops/artifacts/obcs/README.md` | Estados do OBC referenciados como "lifecycle" |

---

## 3. Conceitos Encontrados na Documentação Atual

### 3.1 Business Intent (BI)

**Onde definido:** `glossary.md`, `flow.md`, `backlogs.md`, `phases.md`

**Significado atual:** Representa uma decisão estratégica de perseguir valor. Nasce de um Business
Signal (ou criada diretamente no BIB). Possui um OBC como documento de contrato. Tem identidade
e ciclo de vida próprios — não substitui o Business Signal.

**Ciclo de vida documentado:** Business Signal → (geração) → Business Intent → (aceite) →
Product Backlog → Icebox → Iteration Backlog → Iteration Plan → Delivery → Operation → Archived.

**Consistência:** Consistente em todos os documentos que a definem. A geração e o ciclo de vida
estão documentados de forma coerente.

---

### 3.2 OBC (Observable Business Contract)

**Onde definido:** `glossary.md`, `obc.md` (referenciado), `flow.md`, `backlogs.md`, `matrix.md`

**Significado atual:** O contrato vivo de uma Business Intent. Dois níveis: Global OBC
(Portfolio, fluxo global) e Local OBC (Product Repository). Estados formais:
`Draft → Refining → Committed → In Delivery → Operational → Archived`.

**Consistência:** Consistente em todos os documentos. O ciclo de vida dos estados é canônico e
repetido de forma coerente. A matriz de transições de Work Items em relação aos estados do OBC
está documentada em `work-item-schema.md`.

**Gap identificado:** Nenhuma jornada é explicitamente responsável por CONDUZIR as transições
de estado do OBC. A Diligence VERIFICA e SINCRONIZA — mas não dirige. O Product Owner aprova
— mas não é uma jornada. Este é o gap que a Product Lifecycle Journey resolve.

---

### 3.3 Icebox / Icebox View

**Onde definido:** `glossary.md`, `backlogs.md`, `phases.md`

**Significado atual:** View sobre o Product Backlog que representa itens com Local OBC em estado
`Refining`. É onde a Discovery no Downstream ocorre — refinamento funcional, técnico e
operacional. O artefato canônico é `prodops/artifacts/product/backlogs/icebox-backlog.md`.

**Consistência:** Consistente. Claramente definido como VIEW (não backlog separado). Definição
estável entre `glossary.md` e `backlogs.md`.

---

### 3.4 Roadmap

**Onde definido:** `glossary.md`, `backlogs.md`, `flow.md`

**Significado atual:** View sobre o Business Intent Backlog — não é um backlog separado. Organiza
itens do BIB em horizontes de entrega (agora / próximo / futuro). Gerenciado pelo Portfolio.

**Consistência:** Consistente. Claramente definido como VIEW sobre BIB, não como backlog
independente. Sem conflitos entre documentos.

---

### 3.5 BIB (Business Intent Backlog)

**Onde definido:** `glossary.md`, `backlogs.md`, `flow.md`

**Significado atual:** Backlog estratégico da plataforma que representa Business Intents aceitas
para Discovery. O Global OBC nasce como Draft ao entrar aqui. Gerenciado pelo Portfolio.

**Consistência:** Consistente em todos os documentos. A sigla BIB é usada de forma consistente.

---

### 3.6 PIB / Iteration Plan / Product Iteration Backlog

**Onde definido:** `glossary.md`, `backlogs.md`, `flow.md`, `manifest.yaml`

**Iteration Plan:** Registro da execução de Delivery de uma iteração. Contém itens do Iteration
Backlog com OBC committed + BDD committed + riscos documentados.

**Iteration Backlog:** View sobre o Product Backlog que representa itens com OBC em estado
`Committed`, prontos para Delivery.

**Nota:** O termo "PIB" (Product Iteration Backlog) não aparece na documentação canônica. A sigla
correta é Iteration Backlog (VIEW) e Iteration Plan (artefato de execução).

**Consistência:** Consistente. Distinção clara entre Iteration Backlog (VIEW) e Iteration Plan
(artefato de execução).

---

### 3.7 Release Backlog

**Onde definido:** `glossary.md`, `backlogs.md`

**Significado atual:** Release é uma VIEW sobre o Product Backlog que representa itens agrupados
por versão de release do produto. Gerenciado pelo Product Owner.

**Nota importante:** Release não é uma fila de trabalho — é uma VIEW de agrupamento para
planejamento e comunicação de versões.

**Consistência:** Consistente com o modelo de VIEWs do Product Backlog.

---

### 3.8 Tracking List

**Onde definido:** `glossary.md`, `backlogs.md`, `flow.md`

**Portfolio Tracking List:** Captura Business Signals da plataforma ainda não compreendidos.
**Product Tracking List:** Captura Business Signals do produto já direcionados.

**Consistência:** Consistente. Ambas contêm APENAS Business Signals — jamais Business Intents
ou OBCs.

---

### 3.9 Promote (como operação)

**Onde definido:** `glossary.md`, `execution-mapping/matrix.md`, `execution-mapping/README.md`,
`journeys/discovery/README.md`, `journeys/diligence/diligence-sync.md`

**Múltiplos usos identificados:**

| Contexto | Significado |
|---|---|
| CI Async Phase (Delivery) | Terceiro estágio do CI Async: aprova formalmente a evolução da versão |
| Diligence Sync Phase | Fase que move item na hierarquia de backlogs verificando pré-condições |
| Discovery (promoção para Downstream) | Artefato graduado de Upstream para Downstream |
| Execution Mapping (operação) | Família Estrutura: "artefato avança de nível" |

**Inconsistência:** O mesmo termo "Promote" é usado para quatro operações conceitualmente
distintas, sem qualificador. Ver Seção 4 — Inconsistências.

---

### 3.10 Discovery Journey (escopo, entradas, saídas)

**Escopo:** Exploração e preparação do trabalho. Existe em modo Upstream (explorar, sem gates)
e Downstream (preparar item comprometido para Delivery, no Icebox).

**Entradas:** Business Intent, Business Signal, OBC Draft, hipóteses.

**Saídas:** Decision Package, experimentos documentados, OBC refinado (Refining), BDD Feature
draft, Decision Package com recomendação clara.

**Fronteira de saída:** OBC em estado Committed + BDD Feature committed = pronto para
Iteration Backlog.

---

### 3.11 Assessment Journey (escopo, entradas, saídas)

**Escopo:** Produzir análises para apoiar decisões. Transversal — ocorre tanto no Upstream
quanto no Downstream.

**Entradas:** Experimentos concluídos, hipóteses, OBC refinado, sinais de Operation.

**Saídas:** Reliability Plans, análises de risco, Decision Packages, Premortems, recomendações
de priorização.

---

### 3.12 Delivery Journey (escopo, entradas, saídas)

**Escopo:** Construir, validar e promover a solução.

**Entradas:** Iteration Plan com item (OBC Committed + BDD Committed + riscos documentados).

**Saídas:** Software entregue, Release Trail atualizado, OBC em estado In Delivery → Operational,
evidências registradas.

**Nota:** A Delivery não gerencia backlogs — ela consome o Iteration Plan diretamente.

---

### 3.13 Operation Journey (escopo)

**Escopo:** Operar e evoluir o produto em produção.

**Responsabilidades:** observabilidade, monitoramento, resposta a incidentes, postmortems,
coleta de métricas DORA, geração de novos Business Signals a partir de aprendizados operacionais.

**Fronteira de entrada:** Após o Promote da Delivery (CI Async).

---

### 3.14 Release (conceito)

**Múltiplos significados identificados:**

| Conceito | Onde vive | Responsável |
|---|---|---|
| Release (VIEW do Product Backlog) | Product Backlog | Product Owner |
| Platform Release (VIEW do BIB) | Business Intent Backlog | Portfolio |
| GitHub Release | Execution Space | CI Async (Ship + Validate + Promote) |
| Release Trail | Knowledge Space (artefato) | SE + PO após Delivery |

**Inconsistência:** O termo "Release" é polissêmico sem qualificador. Ver Seção 4.

---

### 3.15 Lifecycle (conceito)

**Onde aparece na documentação:**

1. `glossary.md` — "ciclo de vida" do OBC: `Draft → Refining → Committed → In Delivery →
   Operational → Archived`
2. `glossary.md` — "Estágio de Produto" (PoC → MVP → IPR → MVR → MVT → MLP)
3. `phases.md` — "Lifecycle Stages" (Concepção e Inception) — distintos de Delivery Phases
4. `ontology.md` — nota sobre "Lifecycle Stage vs. Phase" como distinção obrigatória
5. `knowledge-vs-execution.md` (linha 20) — "Product Lifecycle" como nome de GitHub Project

**Conclusão:** O conceito de lifecycle aparece disperso em múltiplos documentos sem uma jornada
que o unifique. A documentação reconhece implicitamente a necessidade de uma "Product Lifecycle"
como domínio (via `knowledge-vs-execution.md`) sem formalizá-la como Journey.

---

## 4. Inconsistências Identificadas

### INC-001 — "Promote" polissêmico sem qualificador

**Arquivos:** `glossary.md`, `diligence-sync.md`, `matrix.md`, `journeys/discovery/README.md`,
`journeys/delivery/README.md`

**Descrição:** O termo "Promote" é usado para quatro operações distintas:
(1) Promote da Delivery (CI Async) = publicar versão aprovada em produção;
(2) Promote da Diligence Sync = mover item na hierarquia de backlogs;
(3) Promote de Upstream → Downstream = graduação de experimento para entrega comprometida;
(4) Promote como operação no Execution Mapping (família Estrutura).

**Impacto:** Agentes e humanos podem executar o ciclo errado ao ouvir "Promote". Um Promote de
Diligence não é o mesmo que um Promote de Delivery.

**Recomendação:** Qualificar com o contexto explícito: "Lifecycle Promote" (avanço no backlog),
"Delivery Promote" (publicação em produção), "Upstream Promote" (graduação de experimento).

---

### INC-002 — "Release" polissêmico sem qualificador sistemático

**Arquivos:** `glossary.md`, `backlogs.md`, `matrix.md`, `journeys/delivery/README.md`

**Descrição:** O termo "Release" aparece com quatro significados distintos sem qualificador
sistemático: (1) VIEW do Product Backlog; (2) Platform Release (VIEW do BIB); (3) GitHub Release
(artefato de Delivery); (4) Release Trail (artefato Knowledge Space).

**Impacto:** Confusão sobre quem gerencia o "Release" e em qual nível hierárquico.

**Recomendação:** A Product Lifecycle Journey deve esclarecer: ela gerencia a Release VIEW do
Product Backlog. A Delivery gerencia o GitHub Release. O Portfolio gerencia a Platform Release.

---

### INC-003 — Responsabilidade da máquina de estados do OBC não atribuída a nenhuma jornada

**Arquivos:** `glossary.md`, `backlogs.md`, `flow.md`, `obc.md` (referenciado)

**Descrição:** O OBC tem estados formais (`Draft → Refining → Committed → In Delivery →
Operational → Archived`). A Diligence VERIFICA e SINCRONIZA esses estados. O Assessment AVALIA
antes das transições. A Delivery EXECUTA o que o OBC descreve. Mas nenhuma jornada é a
**proprietária da máquina de estados do OBC** — quem decide que o OBC transitou de Draft para
Refining? Quem declara Operational? Quem arquiva?

**Impacto:** Sem proprietário explícito da máquina de estados, as transições dependem de
convenções implícitas não documentadas, criando drift e inconsistências operacionais.

**Recomendação:** A Product Lifecycle Journey é a candidata natural para ser a proprietária
da máquina de estados do OBC no nível de produto.

---

### INC-004 — Nenhuma jornada gerencia a transição Iteration Backlog → Iteration Plan

**Arquivos:** `backlogs.md`, `journeys/delivery/README.md`, `journeys/README.md`

**Descrição:** O glossário diz "O Product Owner ainda precisa selecioná-lo explicitamente para o
Iteration Plan." Mas não há jornada que codifique esse processo. A Delivery começa APÓS o
Iteration Plan estar preenchido. A Diligence verifica consistência, mas não conduz a seleção.
Há um void de governança entre Iteration Backlog e Iteration Plan.

**Impacto:** O processo de seleção de itens para o Iteration Plan é ad-hoc, sem jornada
responsável, sem verificação de pré-condições canônicas.

**Recomendação:** A Product Lifecycle Journey deve codificar o processo de seleção e entrada
de itens no Iteration Plan como uma fase formal.

---

### INC-005 — O Lifecycle Stage "Inception" não mapeia para nenhuma jornada formal

**Arquivos:** `phases.md`, `glossary.md`, `journeys/README.md`

**Descrição:** O `phases.md` define "Inception" como o período desde a entrada no Product Backlog
até o Local OBC atingir o estado Committed (Iteration Backlog). Esse período é gerenciado
informalmente por "Product Owner + Tech Lead" com apoio da Discovery (no Icebox). Mas "Inception"
não é uma jornada — é um Lifecycle Stage sem jornada proprietária explícita.

**Impacto:** O trabalho de refinamento, decisão e promoção durante a Inception não tem jornada
que o estruture formalmente, exceto Discovery (que é a jornada de exploração) e Assessment
(que é transversal).

**Recomendação:** A Product Lifecycle Journey deve incorporar a Inception como parte de seu
escopo, posicionando o refinamento do Icebox e a transição para Iteration Backlog como fases
formais.

---

### INC-006 — Tracking List menciona que Business Signals devem ter GitHub Issue correspondente, contradizendo knowledge-vs-execution.md

**Arquivos:** `artifacts/product/backlogs/tracking-list.md` (cabeçalho), `knowledge-vs-execution.md`

**Descrição:** O cabeçalho do `tracking-list.md` diz: "Cada Business Signal deve ter um GitHub
Issue correspondente (Business Signal Issue). Entradas sem Issue estão incompletas — executar
Diligence Sync → Attach para criar o Issue."

Já `knowledge-vs-execution.md` e `glossary.md` são explícitos: "Work Items são criados quando
há operação ativa sobre o Signal — não automaticamente ao registrar o Signal. A ausência de
Work Item não é uma divergência enquanto não houver operação ativa."

**Impacto:** Agentes que leem apenas o `tracking-list.md` criarão Issues para todos os Business
Signals registrados, violando o princípio N:M fundamental do Framework.

**Recomendação:** Corrigir o cabeçalho do `tracking-list.md` para remover a instrução de Issue
obrigatório, alinhando com o princípio de Work Item por operação ativa.

---

### INC-007 — Knowledge-vs-execution.md menciona "Product Lifecycle" como GitHub Project sem definição de Journey

**Arquivo:** `knowledge-vs-execution.md` linha 20

**Descrição:** A linha 20 do `knowledge-vs-execution.md` menciona explicitamente "Product
Lifecycle" como um dos GitHub Projects canônicos — mas a Journey "Product Lifecycle" não existe
entre as cinco jornadas definidas no Framework.

**Impacto:** A menção cria expectativa de uma Journey sem fornece sua especificação. Agentes e
humanos não têm referência para o escopo desta Journey.

**Recomendação:** Formalizar a Product Lifecycle Journey como proposto neste documento.

---

### INC-008 — Responsabilidade de arquivamento do OBC não é atribuída

**Arquivos:** `glossary.md`, `matrix.md`

**Descrição:** O estado `Archived` existe no ciclo de vida do OBC mas a operação `Archive` na
matriz aponta para jornada `Operation` com responsáveis `PO`. Não há processo formal de
arquivamento — apenas a operação existe na matriz sem um ciclo que a conduza.

**Impacto:** OBCs podem permanecer em estado `Operational` indefinidamente sem arquivamento
formal, poluindo o Product Backlog com itens obsoletos.

**Recomendação:** A Product Lifecycle Journey deve incluir um ciclo de arquivamento formal.

---

## 5. Respostas às 10 Questões Arquiteturais

### Questão 1 — Qual problema resolve a Product Lifecycle Journey?

A Product Lifecycle Journey resolve o **gap entre o início de uma Business Intent no Product
Backlog e sua declaração como Operational** — passando por todas as transições intermediárias.

Mais especificamente, resolve:

1. **Nenhuma jornada é proprietária da máquina de estados do OBC** no nível de produto.
2. **A transição Iteration Backlog → Iteration Plan não tem jornada proprietária**: ninguém
   formaliza essa seleção com verificação canônica.
3. **O Lifecycle Stage "Inception" não mapeia para uma Journey formal**: o trabalho de
   refinamento no Icebox, decisão de promoção para Committed e entrada no Iteration Backlog
   é feito por convenção sem Journey proprietária.
4. **O arquivamento do OBC não tem processo formal**: OBCs chegam a Operational sem caminho
   estruturado para Archived.
5. **A Release VIEW do Product Backlog não tem Journey proprietária**: nenhuma Journey
   gerencia o agrupamento de itens por versão de release do produto.

---

### Questão 2 — Onde começa a Product Lifecycle Journey?

**Ponto de entrada:** A entrada de um item no **Product Backlog** — seja via OBC Partitioning
(fluxo global) ou via Owner Approval (fluxo local).

**Artefato acionador:** Local OBC em estado `Draft` no Product Backlog.

**Evento específico:** Owner Approval ou recepção de Local OBC do Portfolio. Este é o momento em
que o Product Owner formaliza compromisso de investigação e o item ganha identidade permanente
no produto.

**Nota:** A Product Lifecycle Journey não começa no Business Signal (que é Concepção, domínio do
Portfolio) nem no BIB (que é Concepção também). Começa quando o item cruza a fronteira
Concepção → Inception.

---

### Questão 3 — Onde termina a Product Lifecycle Journey?

**Condição de done:** A Journey termina para um artefato específico quando:

1. O OBC atinge o estado `Archived` — após período em `Operational`; **OU**
2. O OBC é `Discarded` durante o refinamento — com registro de aprendizado canônico.

O estado `Operational` não é o fim — é um estado estável durante o qual o OBC pode receber
evidências operacionais, novos sinais e eventual evolução. A Journey de facto acompanha o OBC
até o fim de seu ciclo de vida.

**Fronteira com Operation:** A Operation gerencia o que acontece EM PRODUÇÃO. A Product Lifecycle
Journey gerencia o estado do artefato que descreve o que está em produção. São complementares e
paralelas durante a fase Operational.

---

### Questão 4 — Quais responsabilidades pertencem à Product Lifecycle Journey?

Com base nas lacunas identificadas:

1. **Maquina de estados do OBC**: conduzir e verificar transições `Draft → Refining →
   Committed → In Delivery → Operational → Archived`
2. **Gestão do Icebox**: coordenar o refinamento de itens até o estado Committed
3. **Gestão do Iteration Backlog**: manter a VIEW de itens prontos para Delivery
4. **Seleção para o Iteration Plan**: codificar o processo de seleção e verificação de
   pré-condições antes da entrada no Iteration Plan
5. **Gestão da Release VIEW**: agrupar itens por versão de release do produto
6. **Promoção de Lifecycle**: conduzir transições de backlog formalmente verificadas
7. **Arquivamento de OBC**: processo formal de transição de `Operational` para `Archived`
8. **Descarte durante Inception**: registro canônico de aprendizado quando OBC é descartado
9. **Visibilidade do portfólio de produto**: representação operacional do estado de todos os
   OBCs do produto em um GitHub Project
10. **Rastreabilidade end-to-end**: garantir que cada OBC tenha rastro completo de seu ciclo

---

### Questão 5 — O que NÃO pertence à Product Lifecycle Journey?

**O que é da Discovery:**
- Exploração de hipóteses e experimentos Upstream
- Produção do Decision Package
- Refinamento funcional/técnico/operacional do OBC (Discovery conduz; Product Lifecycle
  verifica a completude e conduz a transição formal)

**O que é da Assessment:**
- Análise de riscos e avaliação de Reliability Plan
- Recomendações de priorização estratégica
- Assessment Review (PM + Tech Lead)

**O que é da Delivery:**
- Implementação do código (Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote)
- Gerenciamento de PRs, pipelines, releases de software
- Execução do Iteration Plan

**O que é da Operation:**
- Monitoramento em produção
- Resposta a incidentes
- Postmortems e runbooks

**O que é da Diligence:**
- Verificação de consistência entre Knowledge Space e Execution Space
- Detecção de drift de artefatos
- Reconciliação do GitHub Workspace
- Verificação de rastreabilidade entre artefatos e Work Items

**O que é do Portfolio:**
- Gestão do BIB e Platform Release
- Definição do Roadmap estratégico
- OBC Partitioning

---

### Questão 6 — Quais outras Jornadas ela depende?

| Jornada | Dependência | Natureza |
|---|---|---|
| **Discovery** | A Discovery produz o OBC refinado até Committed; sem ela, a Product Lifecycle Journey não tem artefato pronto para promover | Pré-condição de transição |
| **Assessment** | O Assessment aprova a Assessment Review (PM + Tech Lead); sem aprovação, o OBC não transiciona de Refining → Committed | Gate de transição |
| **Delivery** | A Delivery executa o trabalho; sem ela, o OBC não pode transicionar de In Delivery → Operational | Execução dependente |
| **Diligence** | A Diligence verifica consistência do que a Product Lifecycle Journey declara; é parceira de verificação | Verificação contínua |
| **Operation** | A Operation fornece sinais e evidências que atualizam o estado Operational do OBC | Alimentação de evidências |

---

### Questão 7 — Quais Capabilities provavelmente existirão?

Com base nas operações identificadas como responsabilidades da Product Lifecycle Journey:

| Capability | Responsabilidade |
|---|---|
| **Intent Intake** | Receber e registrar formalmente uma Business Intent no Product Backlog com Local OBC Draft |
| **Lifecycle State Management** | Conduzir e verificar a máquina de estados do OBC: Draft → Refining → Committed → In Delivery → Operational → Archived |
| **Backlog View Management** | Manter as VIEWs do Product Backlog (Icebox, Iteration Backlog, Release) sincronizadas com o estado real dos OBCs |
| **Readiness Gate** | Verificar pré-condições canônicas antes de transições formais (Committed → Iteration Plan) |
| **Release Planning** | Agrupar itens por versão de release e coordenar o planejamento de entrega com o Product Owner |
| **Intent Retirement** | Conduzir o processo formal de arquivamento (Operational → Archived) ou descarte (Discarded) com registro canônico |

---

### Questão 8 — Quais Projects GitHub ela deverá possuir?

A Product Lifecycle Journey deve possuir **um GitHub Project canônico** para o nível de produto:

**Título:** `ProdOps — Product Lifecycle`

**O que rastreia:** Work Items sobre Business Intents, Local OBCs, BDD Features e Iteration Plans
no ciclo de vida do produto.

**Views propostas:**

| View | O que mostra |
|---|---|
| `All Lifecycle Items` | Todos os Work Items do ciclo de vida, sem filtro |
| `Icebox` | Work Items sobre OBCs em estado Refining |
| `Iteration Backlog` | Work Items sobre OBCs em estado Committed, prontos para Delivery |
| `In Delivery` | Work Items sobre OBCs em estado In Delivery |
| `Operational` | Work Items sobre OBCs em estado Operational |
| `Release Planning` | Work Items agrupados por Release alvo |
| `Blocked` | Work Items com Status = Blocked (pré-condições não satisfeitas) |
| `Archived` | Work Items de arquivamento concluídos (histórico) |

**Nota sobre Portfolio Project:** O Portfolio já possui seu próprio GitHub Project cobrindo
Business Signals e Business Intents no BIB. O `ProdOps — Product Lifecycle` não duplica esse
escopo — começa onde o Portfolio termina (entrada no Product Backlog).

---

### Questão 9 — Como utilizar a Canonical Operational Representation definida pela Diligence?

A Product Lifecycle Journey herda o schema canônico estabelecido em
`prodops/framework/execution-mapping/work-item-schema.md`:

**Campos obrigatórios para todos os Work Items:**
- `artifact_type`: enum canônico (Local OBC, Business Intent, BDD Feature, Iteration Plan, etc.)
- `artifact_id`: slug ou path do artefato
- `operation`: enum canônico (Create, Refine, Approve, Promote, Archive, etc.)
- `journey`: `Product Lifecycle` (valor a adicionar ao enum `journey`)

**Labels obrigatórias:**
- `operation:<valor>`
- `artifact-type:<valor>`
- `journey:product-lifecycle`

**Campos adicionais propostos para Work Items de Product Lifecycle:**

```yaml
product_lifecycle_fields:
  - name: Lifecycle Stage
    type: single_select
    options: [Inception, In Delivery, Operational, Archived, Discarded]

  - name: OBC State
    type: single_select
    options: [Draft, Refining, Committed, In Delivery, Operational, Archived]

  - name: Target Release
    type: text
    description: "Versão de release alvo (ex: v2.1.0)"
```

**Padrão de título de Work Item:**

```
[Artifact ID]: descrição da operação canônica
```

Exemplos:
```
create-invoice-v2: refinamento — seção BDD incompleta
create-invoice-v2: transição Refining → Committed
create-invoice-v2: seleção para Iteration Plan v2.1
```

---

### Questão 10 — Como manter independência entre Product Lifecycle e Diligence?

A independência é mantida pela clareza de papéis:

| Aspecto | Product Lifecycle faz | Diligence faz |
|---|---|---|
| Transições de estado do OBC | CONDUZ — decide quando e como transicionar | VERIFICA — confirma que a transição foi executada corretamente |
| Work Items | CRIA para suas operações próprias | VERIFICA se estão estruturados conforme schema |
| Backlog | GERENCIA — mantém as VIEWs | SINCRONIZA — detecta drift entre artefato e backlog |
| GitHub Project | OPERA — cria e fecha Work Items | INSPECIONA — verifica conformidade do projeto |
| Readiness Gate | EXECUTA — verifica pré-condições e bloqueia se necessário | NÃO DUPLICA — não re-executa o gate |

**Interfaces limpas:**

1. **Contrato de saída da Product Lifecycle para a Diligence:** OBC com estado canônico
   claramente declarado no arquivo Markdown. A Diligence lê o arquivo — não precisa de
   sinalização adicional.

2. **Contrato de saída da Diligence para a Product Lifecycle:** Finding ou relatório de
   inconsistência. A Product Lifecycle reage, mas não depende de um sinal específico da
   Diligence para avançar — usa seus próprios critérios.

3. **Sem acoplamento de execução:** A Product Lifecycle não invoca ciclos da Diligence. A
   Diligence não invoca ciclos da Product Lifecycle. Elas são observadoras uma da outra via
   o Knowledge Space compartilhado (arquivos Markdown).

---

## 6. Proposta Arquitetural

### 6.1 Definição Canônica

> **Product Lifecycle é a jornada responsável por gerenciar o ciclo de vida completo das
> Business Intents no Product Repository — desde a entrada no Product Backlog até o
> arquivamento formal — mantendo a máquina de estados do OBC, conduzindo transições de
> backlog com verificação de pré-condições e garantindo rastreabilidade de ponta a ponta
> entre intenção estratégica e valor operacional verificável.**

---

### 6.2 Questão Central

> **A intenção foi transformada em valor operacional verificável?**

Esta questão complementa as questões centrais das outras jornadas:

| Jornada | Questão central |
|---|---|
| Discovery | O que precisamos compreender antes de assumir um compromisso? |
| Assessment | Qual é a situação e o que deve ser decidido ou preparado? |
| Delivery | Como transformar o compromisso em mudança verificável? |
| Operation | O produto está produzindo os resultados e comportamentos esperados? |
| Diligence | O conhecimento, as decisões, a execução e as evidências continuam coerentes? |
| **Product Lifecycle** | **A intenção foi transformada em valor operacional verificável?** |

---

### 6.3 Escopo (CAN / CANNOT)

#### CAN — O que a Product Lifecycle Journey PODE e DEVE fazer:

1. Registrar formalmente a entrada de uma Business Intent no Product Backlog com Local OBC Draft
2. Conduzir o processo de refinamento no Icebox (coordenando Discovery e Assessment)
3. Declarar o estado do OBC em cada transição formal (`Draft → Refining → Committed → ...`)
4. Verificar pré-condições de entrada no Iteration Backlog (OBC Committed + Discovery concluída)
5. Verificar pré-condições de entrada no Iteration Plan (OBC Committed + BDD + riscos)
6. Gerenciar a VIEW Release do Product Backlog — agrupar itens por versão
7. Registrar e rastrear a promoção de itens entre níveis do backlog
8. Declarar o estado Operational após confirmação da Delivery e evidências operacionais
9. Conduzir o processo formal de arquivamento de OBC (Operational → Archived)
10. Registrar descarte de intents durante Inception com aprendizado canônico
11. Manter rastreabilidade end-to-end: Intent → OBC → BDD → Delivery → Operational
12. Produzir representação operacional no GitHub Project `ProdOps — Product Lifecycle`
13. Bloquear formalmente a entrada de itens em Delivery sem pré-condições satisfeitas
14. Coordenar com o Portfolio para receber Local OBCs via OBC Partitioning
15. Notificar a Diligence (via estado do artefato) quando transições ocorrem

#### CANNOT — O que a Product Lifecycle Journey NÃO PODE fazer:

1. Implementar código de produto (pertence à Delivery)
2. Executar experimentação e exploração (pertence à Discovery)
3. Produzir análises de risco e Reliability Plans (pertence ao Assessment)
4. Monitorar produção e responder a incidentes (pertence à Operation)
5. Verificar consistência de artefatos entre Knowledge e Execution Space (pertence à Diligence)
6. Aprovar o OBC sozinha — aprovação requer PM + Tech Lead (Assessment Review)
7. Definir prioridades estratégicas no BIB (pertence ao Portfolio)
8. Executar o OBC Partitioning (pertence ao Portfolio PM + Tech Leads)
9. Criar Business Intents diretamente (nasce de Business Signal ou do Portfolio)
10. Modificar trilhas históricas de Delivery ou Operation
11. Substituir o Discovery — ela coordena, não executa
12. Tomar decisões de negócio sobre o conteúdo do OBC

---

### 6.4 Modelo de Ciclo de Vida dos Artefatos

#### Estados do Local OBC (máquina de estados proprietária da Product Lifecycle Journey)

```
                ┌──────────────────────────────────────────────────────────┐
                │                  PRODUCT BACKLOG                         │
                │                                                          │
  [Owner       ]│ Draft ──── Refining ──── Committed ──── In Delivery ─── Operational ──── Archived
  Approval     ]│   │           │              │               │                │               │
                │   │       [Icebox        [Iteration       [Iteration      [Operation      [Arquivamento
                │   │        VIEW]          Backlog          Plan →          em curso]       formal]
                │   │                        VIEW]           Delivery]
                └──────────────────────────────────────────────────────────┘
```

#### Transições e condições de gate

| Transição | Gate | Responsável |
|---|---|---|
| Entrada → `Draft` | Owner Approval + OBC Draft criado | Product Owner |
| `Draft` → `Refining` | Discovery iniciada no Icebox | Product Lifecycle Journey |
| `Refining` → `Committed` | Assessment Review aprovada (PM + Tech Lead) + BDD committed | Assessment + Product Owner |
| `Committed` → `In Delivery` | Entrada no Iteration Plan com OBC + BDD + riscos | Product Lifecycle Journey |
| `In Delivery` → `Operational` | Promote da Delivery concluído + Release Trail registrado + evidência operacional | Delivery → Product Lifecycle Journey declara |
| `Operational` → `Archived` | Processo formal de arquivamento com registro canônico | Product Lifecycle Journey |
| Qualquer estado → `Discarded` | Decisão de descarte com registro de aprendizado no OBC | Product Owner + Product Lifecycle Journey |

#### Jornada responsável por cada transição

| Transição | Journey que CONDUZ | Journey que VERIFICA |
|---|---|---|
| Entry → Draft | Product Lifecycle | Diligence |
| Draft → Refining | Product Lifecycle | Diligence |
| Refining → Committed | Assessment (Review), Discovery (refinamento) | Product Lifecycle + Diligence |
| Committed → In Delivery | Product Lifecycle (Gate) | Diligence |
| In Delivery → Operational | Delivery (executa) | Product Lifecycle (declara) + Diligence |
| Operational → Archived | Product Lifecycle | Diligence |

---

### 6.5 Ciclos Propostos

A Product Lifecycle Journey propõe **três ciclos** complementares:

---

#### Ciclo 1: lifecycle-intake

**Trigger:** Novo Local OBC Draft recebido no Product Backlog (via OBC Partitioning ou Owner
Approval no fluxo local).

**Natureza:** Síncrono, reativo, orientado a eventos.

**Fases:**
1. **Register** — Registrar formalmente o item no Product Backlog com Local OBC Draft; atribuir
   identificador canônico; declarar estado `Draft`
2. **Classify** — Classificar o modo de execução inicial (Upstream ou Downstream); declarar
   Origin Stream; vincular ao Business Intent de origem
3. **Route** — Encaminhar para a VIEW Icebox (estado → `Refining`); iniciar rastreamento no
   GitHub Project Product Lifecycle; criar Work Item de intake se há operação ativa

**Saídas:** OBC registrado em `prodops/artifacts/obcs/`; item na VIEW Icebox; rastreabilidade
estabelecida.

---

#### Ciclo 2: lifecycle-promote

**Trigger:** Pré-condição de transição satisfeita — Assessment Review aprovada, OBC Committed,
BDD committed, ou evidência de Delivery concluída.

**Natureza:** Síncrono, reativo, bloqueante quando pré-condições não satisfeitas.

**Fases:**
1. **Verify** — Verificar pré-condições canônicas da transição alvo
2. **Advance** — Executar a transição de estado e atualizar o OBC; mover item na VIEW correta
3. **Register** — Registrar a transição com data, responsável e evidência no OBC

**Saídas:** OBC com estado atualizado; item na VIEW correspondente; rastreabilidade da transição.

---

#### Ciclo 3: lifecycle-close

**Trigger:** Sinal de arquivamento (OBC Operational por período definido sem evolução ativa)
ou decisão explícita de descarte.

**Natureza:** Síncrono, reativo, orientado a decisão humana.

**Fases:**
1. **Evaluate** — Avaliar elegibilidade para arquivamento: evidências presentes, OBC atualizado,
   Release Trail completo
2. **Archive** — Transicionar o OBC para `Archived`; registrar data, decisão e responsável
3. **Preserve** — Garantir que o histórico completo (Work Items, evidências, Release Trail)
   permaneça acessível

**Saídas:** OBC em estado `Archived`; histórico preservado; VIEW Archived atualizada.

---

### 6.6 Capabilities Propostas

#### Capability 1: Intent Intake

**Responsabilidade:** Receber e registrar formalmente uma Business Intent no Product Backlog,
criando o Local OBC Draft e estabelecendo rastreabilidade de origem.

**Ciclos consumidores:** lifecycle-intake

**Entradas:** Local OBC Draft (via Partitioning ou fluxo local), Owner Approval, Origin Stream.

**Saídas:** OBC registrado em estado Draft, item na VIEW Icebox, rastreabilidade estabelecida.

**Operações:** `Create` (Local OBC), `Capture` (se origem Business Signal), `Promote` (Signal
→ Intent, quando fluxo local)

---

#### Capability 2: Lifecycle State Management

**Responsabilidade:** Conduzir e verificar a máquina de estados do OBC em cada transição formal.
É a Capability central da Journey — proprietária do `Draft → Refining → Committed → In Delivery
→ Operational → Archived`.

**Ciclos consumidores:** lifecycle-intake, lifecycle-promote, lifecycle-close

**Entradas:** Estado atual do OBC, pré-condições de transição, decisão de jornada competente.

**Saídas:** OBC com estado atualizado, transição registrada, VIEW correspondente atualizada.

**Operações:** `Update` (estado do OBC), `Promote` (transição de backlog), `Archive`

---

#### Capability 3: Backlog View Management

**Responsabilidade:** Manter as VIEWs do Product Backlog (Icebox, Iteration Backlog, Release)
sincronizadas com o estado real dos OBCs — sem modificar a fonte de verdade dos artefatos.

**Ciclos consumidores:** lifecycle-intake, lifecycle-promote

**Entradas:** Estado do OBC, VIEW de destino, regras de filtro por estado.

**Saídas:** VIEWs atualizadas refletindo o estado real; divergências identificadas para a
Diligence quando a VIEW não reflete o artefato.

**Operações:** `Update` (VIEW), `Reconcile` (quando há drift entre VIEW e artefato)

---

#### Capability 4: Readiness Gate

**Responsabilidade:** Verificar pré-condições canônicas antes de transições formais — especialmente
a entrada no Iteration Plan. Bloquear e registrar quando pré-condições não estão satisfeitas.

**Ciclos consumidores:** lifecycle-promote

**Entradas:** Item candidato à transição, critérios canônicos (OBC Committed, BDD committed,
riscos documentados, Reliability Plan quando aplicável).

**Saídas:** Gate Pass (pré-condições satisfeitas) ou Gate Block (pré-condições ausentes com
registro de O QUE está faltando).

**Operações:** `Validate` (pré-condições), `Review` (readiness)

---

#### Capability 5: Release Planning

**Responsabilidade:** Agrupar itens por versão de release do produto; coordenar o planejamento
de entrega com o Product Owner; manter a VIEW Release atualizada.

**Ciclos consumidores:** lifecycle-promote

**Entradas:** Itens comprometidos no Iteration Backlog, decisão do Product Owner sobre versão alvo.

**Saídas:** VIEW Release atualizada; agrupamento por versão declarado no OBC.

**Operações:** `Update` (Release view), `Release` (agrupamento)

---

#### Capability 6: Intent Retirement

**Responsabilidade:** Conduzir o processo formal de arquivamento (Operational → Archived) ou
descarte (→ Discarded) com registro canônico de aprendizado e histórico preservado.

**Ciclos consumidores:** lifecycle-close

**Entradas:** OBC em estado Operational (arquivamento) ou decisão de descarte.

**Saídas:** OBC em estado Archived ou Discarded; aprendizado registrado; histórico preservado.

**Operações:** `Archive`, `Discard`

---

### 6.7 GitHub Projects Propostos

#### Project 1: ProdOps — Product Lifecycle

**Título:** `ProdOps — Product Lifecycle`

**O que rastreia:** Work Items sobre o ciclo de vida de Business Intents e Local OBCs no
Product Repository — desde a entrada no Product Backlog até o arquivamento.

**Campos necessários (herda do schema canônico + adicionais):**

```yaml
campos_herdados:
  - Artifact Type        # enum canônico
  - Artifact ID          # slug do OBC
  - Operation            # enum canônico
  - Journey              # "Product Lifecycle"
  - Execution Mode       # Upstream / Downstream
  - Owner                # Product Owner / PCE
  - Release              # versão alvo

campos_adicionais:
  - Lifecycle Stage      # Inception / In Delivery / Operational / Archived / Discarded
  - OBC State            # Draft / Refining / Committed / In Delivery / Operational / Archived
  - Target Release       # versão de release alvo
  - Gate Status          # Pass / Blocked / Pending
```

**Views propostas:**

| View | Filtro | Propósito |
|---|---|---|
| `All Lifecycle Items` | (nenhum) | Visão completa de todos os Work Items do ciclo de vida |
| `Icebox` | `OBC State = Refining` | Itens em refinamento no Icebox |
| `Iteration Backlog` | `OBC State = Committed` | Itens prontos para Delivery |
| `In Delivery` | `OBC State = In Delivery` | Itens em execução de Delivery |
| `Operational` | `OBC State = Operational` | Itens em produção |
| `Release Planning` | agrupado por `Target Release` | Planejamento de versões |
| `Blocked` | `Gate Status = Blocked` | Itens bloqueados por pré-condições não satisfeitas |
| `Archived` | `OBC State = Archived OR Discarded` | Histórico de encerramento |

---

### 6.8 Relações com Outras Jornadas

| Journey | Tipo de Relação | Interface | Dados Trocados |
|---|---|---|---|
| **Discovery** | Pré-condição | OBC refinado até Committed; Discovery EXECUTA, Product Lifecycle VERIFICA completude | OBC em estado Refining → Committed; BDD Feature draft |
| **Assessment** | Gate | Assessment Review = gate de transição Refining → Committed; Assessment APROVA, Product Lifecycle AVANÇA | Decisão de aprovação registrada no OBC; Reliability Plan quando aplicável |
| **Delivery** | Consumidora | Delivery consome Iteration Plan produzido pela Product Lifecycle; Delivery EXECUTA, Product Lifecycle DECLARA Operational | Iteration Plan (entrada); Release Trail + evidências (saída) |
| **Operation** | Alimentadora | Operation fornece sinais e evidências que atualizam o estado Operational do OBC | Evidências operacionais, incidentes, postmortems que atualizam o OBC |
| **Diligence** | Verificadora | Diligence VERIFICA a consistência do que a Product Lifecycle DECLARA; interface limpa via artefatos Markdown | Estado do OBC (fonte de verdade: arquivo Markdown); Work Items com schema canônico |
| **Portfolio** | Fornecedora | Portfolio ENVIA Local OBCs via OBC Partitioning; Product Lifecycle RECEBE e registra | Local OBC Draft; rastreabilidade para Global OBC |

---

### 6.9 Entradas e Saídas

#### Entradas (o que entra na Product Lifecycle Journey):

| Entrada | Origem | Quando |
|---|---|---|
| Local OBC Draft | Portfolio (via OBC Partitioning) | Fluxo global — após Discovery no BIB |
| Local OBC Draft | Product Owner (via Owner Approval) | Fluxo local — após Premortem + Análise de Risco |
| Assessment Review aprovada | Assessment Journey | Quando PM + Tech Lead aprovam refinamento |
| OBC em estado Committed + BDD committed | Discovery + Assessment | Quando item está pronto para Delivery |
| Release Trail + evidências operacionais | Delivery Journey | Após Promote do CI Async |
| Sinais operacionais | Operation Journey | Durante período Operational |
| Decisão de arquivamento | Product Owner | Quando OBC está pronto para ser encerrado |
| Decisão de descarte | Product Owner | Quando intenção é cancelada durante Inception |

#### Saídas (o que sai da Product Lifecycle Journey):

| Saída | Destino | Estado |
|---|---|---|
| OBC com estado `Draft` | Product Backlog (Icebox) | Início do refinamento |
| OBC com estado `Committed` | Iteration Backlog (VIEW) | Pronto para Delivery |
| Iteration Plan (entrada de item) | Delivery Journey | Execução de Delivery |
| OBC com estado `In Delivery` | Delivery Journey + Diligence | Execução em curso |
| OBC com estado `Operational` | Operation Journey + Diligence | Valor entregue |
| OBC com estado `Archived` | Knowledge Space (histórico) | Encerramento formal |
| Work Items no GitHub Project | Execution Space (Product Lifecycle Project) | Rastreabilidade operacional |
| Gate Block report | Product Owner + jornada competente | Quando pré-condições não satisfeitas |
| Release VIEW atualizada | Product Owner | Planejamento de versões |

---

### 6.10 Anti-padrões

| Anti-padrão | Por que é errado |
|---|---|
| **Iniciar Delivery antes de OBC Committed + BDD committed** | Viola o gate canônico; código sem contrato verificável é retrabalho garantido |
| **Usar o GitHub Project como fonte de verdade do estado do OBC** | O OBC canônico vive no arquivo Markdown — o Project é representação derivada |
| **Promover item para Iteration Plan sem verificação de pré-condições** | Viola o princípio de Gate; cria debt de governança e rastreabilidade fragmentada |
| **Confundir Release VIEW com Platform Release** | São conceitos distintos em níveis diferentes; misturá-los quebra a hierarquia de backlogs |
| **Arquivar OBC sem registro formal de aprendizado** | Perde rastreabilidade histórica — OBCs arquivados devem ter rastro completo |
| **Descartar Business Intent durante Inception sem registro** | Após Owner Approval, todo encerramento exige registro canônico de aprendizado |
| **Manter OBC em estado `Operational` indefinidamente sem revisão** | OBCs não arquivados poluem o backlog e criam ruído operacional |
| **Permitir que a Diligence conduza transições de estado** | A Diligence VERIFICA — quem CONDUZ é a Product Lifecycle; confundir papéis quebra a independência |
| **Criar Work Items para cada OBC automaticamente** | Viola o princípio N:M; Work Items representam operações ativas — não os artefatos em si |
| **Iniciar lifecycle-promote sem evento acionador verificável** | Ciclos reativos devem ter trigger explícito — promoções sem evento são drift de processo |
| **Gerenciar o BIB ou Platform Release dentro da Product Lifecycle Journey** | Esses pertencem ao Portfolio — a Journey começa no Product Backlog |
| **Confundir "Promote" da Delivery com "Promote" do Lifecycle** | São operações distintas em contextos distintos; sempre qualificar com o contexto |

---

## 7. Riscos

| # | Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|---|
| R1 | Sobreposição com Diligence — fronteiras mal definidas | Alta | Alto | Definição explícita de papéis (CONDUZ vs. VERIFICA); interfaces via artefatos Markdown |
| R2 | A Journey se torna um "super-backlog" gerenciando tudo | Média | Alto | Escopo explícito (CAN / CANNOT) documentado e revisado |
| R3 | Conflito com Product Owner na gestão de prioridades | Média | Alto | Documentar que priorização pertence ao PO — a Journey gerencia o processo, não a decisão |
| R4 | Enum `journey` não inclui `Product Lifecycle` no work-item-schema.md | Baixa | Médio | Adicionar ao enum como parte da formalização da Journey |
| R5 | Ciclos da Journey não têm Skills implementadas | Alta | Alto | Proposta é arquitetural — Skills são próximo passo; não implementar prematuramente |
| R6 | Confusão com o termo "Product Lifecycle" já mencionado em knowledge-vs-execution.md | Baixa | Baixo | Este documento formaliza a menção implícita; a referência confirma a intenção do Framework |
| R7 | Duplicação de responsabilidade com a fase Promote do CI Async | Média | Alto | Qualificar explicitamente: "Delivery Promote" = publicação; "Lifecycle Promote" = transição de backlog |

---

## 8. Próximos Passos Sugeridos

Os próximos passos são sugestões arquiteturais — nenhum deve ser implementado antes de
revisão e aprovação deste documento.

**P1 — Revisão e aprovação deste documento** (humano)
- Portfolio PM + Tech Lead + Product Owner revisam a proposta
- Decisão de aprovar, ajustar ou rejeitar cada seção

**P2 — Corrigir INC-006 no tracking-list.md** (pontual, baixo risco)
- Remover instrução de Issue obrigatório por Business Signal
- Alinhar com o princípio canônico de Work Item por operação ativa

**P3 — Adicionar "Product Lifecycle" ao enum journey no work-item-schema.md** (pontual)
- Adicionar ao `journey` enum: `Product Lifecycle`
- Atualizar `manifest.yaml` e docs derivados

**P4 — Formalizar a Journey no journeys/README.md** (documentação)
- Adicionar Product Lifecycle à tabela de jornadas (atualizar de 5 para 6 jornadas)
- Criar `journeys/product-lifecycle/README.md` com a definição canônica

**P5 — Criar journeys/product-lifecycle/README.md** (documentação)
- Estrutura análoga ao `journeys/diligence/README.md`
- Mínimo: Definição, Questão Central, Escopo, Ciclos, Capabilities

**P6 — Implementar Skills para os 3 ciclos** (implementação — requer aprovação prévia)
- `prodops/skills/product-lifecycle/lifecycle-intake/SKILL.md`
- `prodops/skills/product-lifecycle/lifecycle-promote/SKILL.md`
- `prodops/skills/product-lifecycle/lifecycle-close/SKILL.md`

**P7 — Criar GitHub Project ProdOps — Product Lifecycle** (operacional)
- Requer aprovação e implementação das Skills primeiro
- Seguir o mesmo padrão de campos e views da Diligence

**P8 — Resolver INC-001 (Promote polissêmico)** (documentação)
- Adicionar qualificadores em todos os documentos afetados
- Criar seção de "Notas de Distinção" no ontology.md para o termo Promote

---

## 9. O que NÃO mudou (guardrails confirmados)

Esta análise confirma que os seguintes princípios do Framework permanecem intocados e devem ser
respeitados pela Product Lifecycle Journey:

| Princípio | Confirmado |
|---|---|
| Knowledge Space (Markdown) é sempre a fonte de verdade | ✓ — OBC canônico vive no arquivo, não no GitHub |
| Work Item ≠ Artefato | ✓ — Work Items representam operações, não os OBCs |
| Cardinalidade N:M entre artefatos e Work Items | ✓ — Um OBC pode ter zero ou muitos Work Items |
| GitHub Projects são representação operacional, não fonte de verdade | ✓ — Canonical Operational Representation derivada |
| Journeys não são modos de execução | ✓ — Upstream/Downstream são modos, não jornadas |
| Diligence é transversal e verificadora — não condutora | ✓ — Product Lifecycle CONDUZ; Diligence VERIFICA |
| OBC Partitioning é processo de governança humano, não Capability | ✓ — Mantido como atividade pontual de responsabilidade humana |
| Priorização do backlog pertence ao Product Owner | ✓ — Product Lifecycle gerencia processo, não decisão |
| Delivery começa somente no Iteration Plan | ✓ — Pré-condição mantida e verificada pela Journey |
| Assessment Review é gate de transição Refining → Committed | ✓ — Não substituível pela Product Lifecycle Journey |
| A Diligence não implementa código nem cria OBCs | ✓ — Papéis permanecem separados |
| As 5 jornadas existentes mantêm suas responsabilidades intactas | ✓ — Product Lifecycle preenche gap, não duplica |
