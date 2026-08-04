# Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0

---

## Sobre este documento

Este documento é a referência fundacional do domínio **Operational Event Model (OEM)** dentro
do ProdOps Framework.

Ele define o que é um Operational Event, qual é o seu papel no Framework, como ele se
relaciona com os demais conceitos da ontologia e quais princípios governam o seu uso.

Este documento não define schema, formato de armazenamento, implementação técnica, nem
como cada Journey utiliza eventos. Esses assuntos são tratados em documentos específicos
por Journey.

→ [Ontologia](../ontology.md) · [Knowledge vs. Execution](../knowledge-vs-execution.md) · [Glossário](../glossary.md)

---

## 1. Motivação

### 1.1 O que o modelo de estados representa

O ProdOps opera com dois espaços distintos: o Knowledge Space, onde vivem os artefatos
conceituais (OBCs, Business Intents, BDD Features), e o Execution Space, onde vivem as
operações sobre esses artefatos (Work Items, Pull Requests, Releases).

A Canonical Operational Representation (COR) — implementada hoje através de GitHub Projects e
Issues — representa o estado atual de cada Work Item: em que fase está, quem é o responsável,
qual é o artefato associado. Essa representação é correta e necessária.

Porém, o estado atual responde apenas a uma pergunta: **onde o Work Item está agora?**

### 1.2 O que o modelo de estados não representa

Há uma classe inteira de perguntas que o estado atual não consegue responder:

- Como o Work Item chegou até aqui?
- Por quanto tempo permaneceu em cada fase?
- Quantas vezes precisou retornar para uma fase anterior?
- Qual gate falhou e qual foi a causa registrada?
- Quem tomou quais decisões e quando?
- A promoção para produção foi precedida pelas evidências corretas?
- O sistema está evoluindo em termos de velocidade, qualidade e previsibilidade?

Essas perguntas exigem **sequência**, **causalidade** e **história** — dimensões que o estado
atual, por definição, não preserva. Ao mudar de estado, o estado anterior desaparece.

### 1.3 A hipótese do Operational Event

A hipótese que originou este domínio é direta:

> **A verdadeira fonte de verdade operacional não é o estado atual. É a sequência de
> acontecimentos que levou ao estado atual.**

Se cada transição significativa durante a execução de uma Journey for registrada como um
fato imutável — com produtor, momento, contexto e evidência — então:

- o estado atual torna-se derivável: é a projeção do último evento relevante;
- as métricas tornam-se computáveis: são funções sobre timestamps de eventos;
- a causalidade torna-se auditável: cada estado tem uma causa registrada;
- a Diligence torna-se preditiva: verifica se eventos esperados ocorreram dentro de janelas
  temporais, não apenas se o estado atual é correto;
- os agentes tornam-se mais precisos: decidem baseados em fatos ocorridos, não em snapshots.

### 1.4 Problemas que o Operational Event Model resolve

| Dimensão | Limitação com estados puros | O que OEM resolve |
|---|---|---|
| **Observabilidade** | "Onde está o Work Item agora?" apenas | "Como chegou até aqui? Quanto tempo levou?" |
| **Auditoria** | Nenhum rastro das transições passadas | Cada transição registrada com produtor e momento |
| **Métricas** | Campos de timestamp ad-hoc sem semântica | Lead time, rework, gate quality deriváveis de eventos |
| **DORA** | Change Fail Rate e MTTR exigem histórico | Eventos de falha e recuperação tornam DORA computável |
| **Assessment** | Baseado em percepções subjetivas | Baseado em padrões de eventos observados ao longo de releases |
| **Automação** | Reage ao estado atual (polling) | Reage a eventos (push) — mais eficiente e preciso |
| **Agentes** | Inferem causa de estados divergentes | Leem sequência de eventos e têm causalidade explícita |

---

## 2. Definição

### 2.1 Operational Event

> **Operational Event** é um fato ocorrido durante a execução de uma Journey que marca
> uma transição, decisão ou condição significativa dentro do fluxo operacional do ProdOps.

Um Operational Event:

- **representa algo que aconteceu** — não algo que está acontecendo nem algo que irá acontecer;
- **é imutável** — uma vez registrado, não pode ser alterado ou excluído;
- **tem produtor identificado** — humano, sistema ou agente que o originou;
- **tem momento preciso** — timestamp que o ancora na linha do tempo do Work Item;
- **é contextual** — pertence a uma Journey, Phase e Work Item específicos;
- **é atômico** — representa um único fato, não uma agregação de fatos;
- **produz evidência** — o próprio registro do evento é uma evidência de que ele ocorreu.

### 2.2 O que não é um Operational Event

| Conceito | Distinção |
|---|---|
| **Estado atual** | O estado é uma projeção do último evento, não o evento em si |
| **Log técnico** | Log registra operações de sistema sem semântica de negócio; ver seção 6 |
| **Domain Event** | Domain Event pertence ao modelo de domínio do produto; ver seção 7 |
| **Business Signal** | Business Signal é um artefato do Knowledge Space, não um evento operacional |
| **Intenção futura** | Planejamento, estimativa e compromisso não são Operational Events |
| **Artefato** | OBC, BDD Feature, Reliability Plan são artefatos — não eventos |

---

## 3. Papel no Framework

### 3.1 Posicionamento na ontologia

O Operational Event não é um novo nível na hierarquia Framework → Journey → Cycle → Phase →
Capability → Skill. Ele pertence a uma dimensão orthogonal: **a dimensão temporal**.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Dimensão Estrutural (o que)                                                 │
│                                                                              │
│  Framework → Journey → Cycle → Phase → Capability → Skill → Step            │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│  Dimensão Temporal (quando e como)                                           │
│                                                                              │
│  Operational Event → Operational Timeline → Estado derivado                  │
│                                                                              │
│  Os eventos fluem através da dimensão estrutural — cada evento pertence      │
│  a uma Phase, que pertence a um Cycle, que pertence a uma Journey.           │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Relação com cada conceito da ontologia

**Business Signal**
O Business Signal é um artefato do Knowledge Space. Operational Events não são Business
Signals. No entanto, eventos operacionais podem ser analisados pela Diligence para determinar
se um novo Business Signal deve ser gerado — por exemplo, se um padrão de falhas em Validate
repetido em múltiplos releases indica uma gap de produto não capturada no Knowledge Space.

**Business Intent**
A Business Intent é um artefato do Knowledge Space. Operational Events registram o trabalho
executado sobre os artefatos que materializam uma Business Intent (OBCs, BDD Features). A
sequência de eventos ao longo das Journeys constitui a história operacional da Intent.

**OBC (Observable Business Contract)**
O OBC é o artefato central do contrato. Operational Events registram transições de estado
do OBC (`OBC.StateChanged`), marcos de validação (`OBC.ValidateCompleted`), e condições de
promoção (`OBC.PromotedToOperational`). O OBC nunca se torna um evento — ele gera eventos
quando sofre transformações significativas.

**Journey**
Cada Operational Event pertence a exatamente uma Journey. O evento carrega a identidade da
Journey que o gerou. Isso permite que a Diligence agregue eventos por Journey e produza
análises de consistência e desempenho por domínio.

**Cycle**
O Cycle é o agrupamento de Phases. Operational Events podem marcar o início e o fim de um
Cycle (`Cycle.Started`, `Cycle.Completed`) e qualquer transição significativa dentro dele.
Eventos permitem comparar ciclos ao longo do tempo — por exemplo, CI Sync de sprint 1 vs. CI
Sync de sprint 10.

**Phase**
A Phase é a granularidade primária dos Operational Events da Delivery. A maior parte dos
eventos ocorre na transição entre Phases: entrada, saída, gate pass, gate fail, bloqueio,
desbloqueio. Um evento de Phase carrega o nome da Phase, o Cycle ao qual pertence e a Journey.

**Capability**
Capabilities são mecanismos reutilizáveis. Operational Events registrados durante a execução
de uma Capability podem ser reutilizados por qualquer Journey que consuma essa Capability.
Por exemplo, a Capability de Evidence Management produz eventos de coleta de evidência que
são relevantes tanto para Delivery quanto para Diligence.

**Skill e Step**
Skill e Step são a camada de implementação executável. Cada Skill é responsável por emitir
os Operational Events correspondentes às transições que executa. A emissão de eventos não é
opcional — um Step que não emite seu evento de conclusão é considerado incompleto.

**Canonical Operational Representation (COR)**
A COR — implementada em GitHub Projects e Issues — materializa o Derived State produzido
pelo OEM: Fields e Labels do GitHub representam o último estado conhecido, derivado dos
eventos da Timeline. A COR é **consumidora** do OEM — não é parte dele. A Diligence verifica
a consistência entre a Timeline de eventos e o estado materializado na COR; quando há
divergência, a Timeline prevalece.

---

## 4. Operational Timeline

### 4.1 Definição

> **Operational Timeline** é a sequência ordenada e imutável de todos os Operational Events
> associados a um Work Item, desde a sua criação até o seu encerramento.

A Timeline é a história completa de um Work Item. Ela responde não apenas onde o Work Item
está, mas de onde veio, como chegou, quantas vezes mudou de direção e por quais razões.

### 4.2 Propriedades da Timeline

- **Ordenada:** os eventos têm ordem definida pelo timestamp — nunca por inserção.
- **Imutável:** um evento registrado não pode ser removido ou alterado.
- **Acumulativa:** a Timeline só cresce — nunca diminui.
- **Autoritativa:** em caso de divergência entre a Timeline e o estado atual declarado na COR,
  a Timeline prevalece.

### 4.3 Derived State

> **Derived State** é o estado atual de um Work Item computado a partir da sua Operational
> Timeline — especificamente, a projeção do último evento que altera estado.

O Derived State é **mutável**: cada novo evento pode alterá-lo. Os eventos que o originam
são imutáveis. Essa assimetria é intencional — o estado muda, mas a causa de cada mudança
é preservada para sempre na Timeline.

O Derived State é a única forma legítima de estado operacional no OEM. Estados não derivados
de eventos são snapshots opacos sem causalidade rastreável.

```
Timeline                          Derived State resultante
────────────────────────────────  ──────────────────────────────
Bootstrap.Started   (t₁)         → BOOTSTRAPPING
Bootstrap.Completed (t₂)         → HACKING
Hack.Completed      (t₃)         → SYNCING
Rework.Declared     (t₄)         → HACKING        (rework_count: 1)
Rework.Completed    (t₅)         → SYNCING
Sync.Completed      (t₆)         → FINISHING
Finish.Completed    (t₇)         → SHIPPING
```

A regra de derivação é direta: o Derived State é determinado pelo último evento que altera
estado. A COR armazena esse Derived State como projeção legível para humanos e agentes —
nunca como fonte de verdade.

### 4.4 O que a Timeline habilita

- **Lead Time:** `T(último evento de encerramento) - T(primeiro evento de início)`
- **Tempo por Phase:** `T(exit event) - T(entry event)` para cada Phase
- **Rework:** contagem de eventos que representam retorno a uma Phase anterior
- **Gate quality:** proporção de `Gate.Passed` vs. `Gate.Failed` por tipo de gate
- **Previsibilidade:** variância entre tempo esperado e tempo real por Phase

---

## 5. Operational Event e Estado

Eventos e estados não competem. Possuem responsabilidades distintas e complementares.

| Dimensão | Operational Event | Estado |
|---|---|---|
| **Natureza** | Imutável — representa um fato passado | Mutável — representa a situação atual |
| **Eixo temporal** | Histórico — sequência ao longo do tempo | Snapshot — corte no momento presente |
| **Estrutura** | Sequencial — a ordem importa | Posicional — apenas o valor atual importa |
| **Papel primário** | Produz métricas, auditoria e causalidade | Facilita visualização e operação cotidiana |
| **Pergunta respondida** | O que aconteceu, quando e por quem? | Onde o Work Item está agora? |
| **Derivação** | Não é derivado — é a fonte primária | É derivado da sequência de eventos |
| **Ciclo de vida** | Acumula — nunca é apagado | Substituído a cada transição |
| **Uso pela Diligence** | Verificação temporal e de causalidade | Verificação de estado pontual |
| **Visibilidade para humanos** | Timeline / histórico | Kanban / board / lista |

A arquitetura correta combina os dois: **eventos como fonte de verdade primária; estado como
projeção derivada para consumo operacional**.

---

## 6. Operational Event e Log

### 6.1 O problema da confusão

Operational Events podem parecer semelhantes a logs. A diferença é fundamental.

### 6.2 Comparativo

| Dimensão | Log técnico | Operational Event |
|---|---|---|
| **Semântica** | Operação de sistema (debug, trace, info, error) | Fato de negócio significativo no fluxo operacional |
| **Produtor** | Sistema automaticamente | Humano, sistema ou agente identificado |
| **Público** | Engenharia de infraestrutura | Engenharia, produto, operação, diligence, agentes |
| **Volume** | Dezenas a milhares por minuto | Dezenas por ciclo de vida completo |
| **Retenção** | Transitória — pode ser descartado | Permanente — nunca descartado |
| **Imutabilidade** | Pode ser rotacionado e purgado | Imutável por definição |
| **Contexto de negócio** | Ausente — é dado técnico | Obrigatório — carrega Journey, Phase, Work Item |
| **Interpretabilidade** | Requer correlação técnica | Auto-descritivo para stakeholders de produto |

### 6.3 Audit Trail

Um Audit Trail é um subconjunto da Timeline: registros com foco em conformidade e
responsabilização — especialmente eventos que envolvem aprovações humanas, gates de qualidade
e decisões de promoção. O Audit Trail é derivado da Timeline — não é uma estrutura separada.

---

## 7. Operational Event e Domain Event

### 7.1 Domain Event

No contexto de Domain-Driven Design (DDD), um **Domain Event** representa algo significativo
que ocorreu no domínio do problema — o negócio da aplicação. Por exemplo: `PagamentoConfirmado`,
`ContaCrediária­Aberta`, `WebhookEntregue`.

Domain Events pertencem ao **domínio do produto** — o sistema que o ProdOps ajuda a construir.

### 7.2 Business Event

Um **Business Event** é um evento do negócio — algo que ocorreu no mundo real e que o sistema
deve registrar ou reagir. Por exemplo: `ClienteComprou`, `ContratoCancelado`.

Business Events são insumos para o Knowledge Space — especialmente para Business Signals e
Business Intents.

### 7.3 Operational Event

Um **Operational Event** é um evento do **processo de trabalho** — algo que ocorreu durante
a execução de uma Journey do ProdOps. Por exemplo: `Bootstrap.Completed`, `Validate.GateFailed`,
`Promote.Approved`.

Operational Events pertencem ao **ProdOps Framework** — ao processo de construir o produto,
não ao produto em si.

### 7.4 Comparativo

| Tipo | Pertence a | Exemplo | Consumido por |
|---|---|---|---|
| **Domain Event** | Domínio do produto (DDD) | `PagamentoConfirmado` | Sistemas do produto |
| **Business Event** | Mundo real / negócio | `ClienteAssinou` | Business Signals, Analytics |
| **Operational Event** | Processo ProdOps | `Bootstrap.Started` | Diligence, Métricas, Agentes |

Os três tipos podem coexistir sem conflito — são ortogonais. Um `Promote.Completed` pode
desencadear a observação de `PagamentoConfirmado` em produção, que por sua vez pode gerar
um `Business Signal`. Essa cadeia é perfeitamente válida — cada evento pertence ao seu domínio.

---

## 8. Benefícios

### 8.1 Para Engenharia

- **Lead time calculável:** tempo total de Bootstrap até Promote derivado da Timeline, sem
  campos ad-hoc ou processos manuais de registro.
- **Rework identificado:** cada retorno a uma Phase anterior é um evento nomeado, com causa
  registrada — não uma métrica inferida de estados.
- **Gate quality mensurável:** proporção de pass/fail por tipo de gate ao longo do tempo
  indica quais gates precisam de atenção.
- **DORA sem instrumentação extra:** Lead Time for Changes, Deployment Frequency, Change
  Failure Rate e MTTR são deriváveis diretamente da Timeline.

### 8.2 Para Produto

- **Previsibilidade:** padrões de tempo por Phase ao longo de sprints constroem modelos
  preditivos — o time sabe quanto tempo Bootstrap tipicamente leva.
- **Priorização informada:** quais OBCs ficaram mais tempo em Validate? Quais gates falharam
  repetidamente? A Timeline responde sem relatórios manuais.
- **Assessment orientado a evidências:** ao invés de retrospectivas subjetivas, a análise
  de padrões de eventos sustenta recomendações de Assessment com dados.

### 8.3 Para Operação

- **Auditoria completa:** cada Promote.Approved tem produtor, timestamp e critérios de gate
  registrados — rastreabilidade para conformidade e postmortem.
- **Detecção de anomalias:** eventos ausentes em janelas temporais esperadas são sinais de
  bloqueio antes que o item apareça como atrasado no Kanban.
- **Rollback rastreável:** `Ship.RollbackTriggered` com causa registrada produz dados para
  análise de estabilidade do sistema de delivery.

### 8.4 Para Diligence

- **Checks temporais:** "o evento esperado ocorreu dentro da janela?" é uma classe de
  verificação que o estado puro não permite. Eventos habilitam Diligence preditiva.
- **Causalidade de Findings:** um Finding aberto pela Diligence pode referenciar o evento
  específico que o originou — aumentando precisão e reduzindo falsos positivos.
- **Sincronização baseada em fatos:** a Diligence verifica se o estado declarado na COR é
  consistente com o último evento registrado — detecção de drift mais precisa.

### 8.5 Para Assessment

- **Base objetiva para análise:** o Assessment recebe a Timeline completa de uma ou mais
  releases como insumo — não uma percepção subjetiva do que ocorreu.
- **Triggers mensuráveis:** padrões de eventos (ex.: `Validate.GateFailed` > 30% em 3
  releases consecutivos) justificam um novo ciclo de Assessment com dados.
- **Evolução verificável:** comparar a Timeline da release 1 com a release 10 produz evidência
  objetiva de melhoria ou degradação do processo.

### 8.6 Para Agentes de IA

- **Decisões baseadas em fatos:** um agente que lê a Timeline decide com base no que ocorreu,
  não no que infere de um estado divergente.
- **Contexto rico para instrumentação:** ao invés de reconstruir o contexto da Phase atual a
  partir de campos dispersos, o agente lê a sequência de eventos e tem a história completa.
- **Emissão de eventos como contrato:** a obrigação de emitir eventos ao final de cada Step
  torna o comportamento dos agentes verificável — a Diligence detecta agentes que não
  cumpriram seu contrato.

---

## 9. Princípios

### P-01 — Operational Events representam fatos, não intenções

Um Operational Event registra algo que ocorreu. Planejamento, estimativa, compromisso e
decisão futura não são eventos operacionais. A frase canônica é: "isso aconteceu" — nunca
"isso vai acontecer" ou "isso deveria acontecer".

### P-02 — Operational Events são imutáveis

Uma vez registrado, um Operational Event não pode ser alterado, corrigido ou excluído. Se
um evento foi registrado incorretamente, um novo evento de correção (`Event.Corrected`) é
emitido — o evento original permanece na Timeline.

### P-03 — Todo Operational Event tem produtor identificado

Não existem eventos anônimos. O produtor pode ser um humano (identificado por papel e
identidade), um sistema (identificado por nome e versão) ou um agente (identificado por
tipo e instância). A ausência de produtor identificado invalida o evento como Operational.

### P-04 — Operational Events pertencem a uma Journey, Phase e Work Item

Um evento existe no contexto de um Work Item específico, em uma Phase específica, em uma
Journey específica. Eventos sem contexto de Journey não são Operational Events — são logs.

### P-05 — O estado atual é uma projeção, nunca a fonte de verdade

O estado declarado na COR deve ser derivado do último evento relevante. Se houver
divergência entre o estado atual e o que a Timeline indica, a Timeline prevalece. A Diligence
é responsável por detectar e reparar essa divergência.

### P-06 — A ausência de evento esperado é informação

Se uma Phase deveria ter produzido um evento e não o produziu dentro de uma janela temporal
esperada, essa ausência é um sinal operacional. A Diligence trata ausências de eventos como
dados — não como lacunas irrelevantes.

### P-07 — Emissão de eventos é obrigatória, não opcional

Uma Skill que executa uma transição de Phase é responsável por emitir o Operational Event
correspondente. A emissão não é opcional — um Step sem evento de conclusão é um Step
incompleto. Isso é verificável pela Diligence.

### P-08 — Eventos habilitam métricas; campos não são métricas

Campos do Work Item (como timestamps de entrada em cada Phase) são projeções de eventos —
não métricas em si. As métricas são funções computadas sobre a Timeline. Se os eventos
existem, os campos de timestamps tornam-se redundantes e podem ser eliminados.

### P-09 — Eventos não substituem artefatos

Um Operational Event registra que algo ocorreu com um artefato — não substitui o artefato.
O OBC, a BDD Feature, o Reliability Plan continuam sendo artefatos do Knowledge Space. O
evento `OBC.StateChanged` é evidência de que o OBC mudou — o OBC em si vive no repositório.

### P-10 — A Timeline é o ativo mais valioso do sistema operacional

O código entregue pode ser descartado. O OBC pode ser arquivado. A Timeline de eventos de
como o trabalho foi executado é um ativo permanente — ela contém a inteligência operacional
acumulada sobre como o time entrega, aprende e melhora.

---

## 10. Escopo deste documento

### O que este documento define

- O conceito de **Operational Event** e suas propriedades fundamentais.
- O conceito de **Operational Timeline** — a sequência imutável de eventos por Work Item.
- O conceito de **Derived State** — o estado atual como projeção da Timeline.
- A posição do OEM na ontologia do Framework.
- Os princípios que governam o uso de eventos em qualquer Journey.
- As distinções entre Operational Event, log, Domain Event e Business Event.
- Os benefícios do modelo para cada audiência.

### O que este documento não define

Este documento deliberadamente não trata dos seguintes tópicos — eles são abordados em
documentos específicos, à medida que cada Journey e domínio os formaliza:

| Tópico não tratado | Documento responsável |
|---|---|
| Schema de eventos (campos obrigatórios, formato) | `events/schema.md` (futuro) |
| Catálogo de eventos da Jornada Delivery | `journeys/delivery/events/catalog.md` (futuro) |
| Catálogo de eventos de outras Journeys | Por Journey, quando formalizado |
| Armazenamento e recuperação de eventos | `events/storage.md` (futuro) |
| Implementação em GitHub (comments, timeline) | `events/github-implementation.md` (futuro) |
| Integração com ferramentas externas | `events/integrations.md` (futuro) |
| Automação baseada em eventos | Por Journey e Capability |
| Como Diligence consome eventos | `journeys/diligence/events.md` (futuro) |
| Modelo de eventos para Assessment | `journeys/assessment/events.md` (futuro) |
| Retenção, purge e arquivamento | `events/lifecycle.md` (futuro) |

### Relação com documentos existentes

| Documento | Relação |
|---|---|
| [`ontology.md`](../ontology.md) | OEM complementa a ontologia — não altera a hierarquia Journey → Cycle → Phase |
| [`knowledge-vs-execution.md`](../knowledge-vs-execution.md) | OEM opera no Execution Space — eventos não são artefatos do Knowledge Space |
| [`glossary.md`](../glossary.md) | Os termos deste documento serão adicionados ao glossário na próxima revisão |
| [`journeys/diligence/README.md`](../journeys/diligence/README.md) | Diligence consome eventos para verificação temporal e de causalidade |

---

## Referências

- [Ontologia do Framework](../ontology.md)
- [Knowledge Space vs. Execution Space](../knowledge-vs-execution.md)
- [Canonical Operational Representation](../knowledge-vs-execution.md#representação-operacional-canônica)
- [Glossário](../glossary.md)
- Modelo de estados da Delivery — análise que precedeu este domínio
- Modelo de eventos da Delivery — análise que gerou a hipótese OEM

---

*Este documento é a fonte canônica do Operational Event Model. Toda documentação de Journey
que utilize eventos deve referenciar este documento como origem dos princípios.*
