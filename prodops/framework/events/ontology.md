# Ontologia do Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [README.md](README.md) — fundação do OEM

---

## Sobre este documento

Este documento formaliza a ontologia do **Operational Event Model (OEM)**: os conceitos
canônicos, as relações entre eles, as cardinalidades válidas, os invariantes invioláveis
e as fronteiras de responsabilidade de cada domínio.

Este documento não define schema, formato, armazenamento, implementação técnica nem
mecanismos de automação. Esses assuntos pertencem a documentos posteriores.

→ [Fundação OEM](README.md) · [Ontologia do Framework](../ontology.md) · [Glossário](../glossary.md)

---

## 1. Diagrama Canônico

```
┌────────────────────────────────────────────────────────────────────────────┐
│                      OPERATIONAL EVENT MODEL (OEM)                         │
│                                                                            │
│   Event Producer                    Event Category                        │
│   (Human | System | Agent)          (Phase Lifecycle | Gate |              │
│          │                           Human Decision | Blocking |           │
│          │ produces (1→N)            System | Rework | Diligence)          │
│          │                                    │                            │
│          │                                    │ classifies (1→N)           │
│          │                                    ↓                            │
│          └─────────────────────────→ [ Operational Event ]                 │
│                                            │    │                          │
│                                            │    └──── Event Evidence       │
│                                            │           (1:1 com evento)    │
│                                            │                               │
│                                   typed by │                               │
│                                            ↓                               │
│                                       Event Type                           │
│                                    (definido por Journey)                  │
│                                            │                               │
│                                            │ instancia (N→1)               │
│                                            ↓                               │
│                                  [ Operational Timeline ]                  │
│                                    (por Work Item — 1:1)                   │
│                                            │                               │
│                               projeta em   │                               │
│                                            ↓                               │
│                                    [ Derived State ]                       │
│                                    (projeção atual — 1:1 com Timeline)     │
│                                                                            │
└────────────────────────────────────────────┬───────────────────────────────┘
                                             │
                materializa Derived State em │
                                             ↓
                      ┌──────────────────────────────────────────┐
                      │    Canonical Operational Representation   │
                      │    (COR — consumidora do OEM, não parte) │
                      └──────────────────────┬───────────────────┘
                                             │
                              verificada por │
                                             ↓
                      ┌──────────────────────────────────────────┐
                      │              Diligence                   │
                      │  (Event Consumer — verifica Timeline×COR)│
                      └──────────────────────────────────────────┘

Event Consumers (orthogonal — consomem a Timeline diretamente):

   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │   Métricas   │   │  Assessment  │   │   Agentes    │
   │  (funções    │   │  (análise de │   │  (decisões   │
   │   de tempo)  │   │   padrões)   │   │   baseadas   │
   └──────────────┘   └──────────────┘   │   em fatos)  │
                                         └──────────────┘
```

---

## 2. Conceitos Canônicos

### 2.1 Operational Event

> O fato atômico e imutável que registra uma transição, decisão ou condição significativa
> ocorrida durante a execução de uma Journey.

**Propriedades obrigatórias:**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `journey` | referência | Journey à qual o evento pertence |
| `cycle` | referência (opcional) | Cycle específico, quando aplicável |
| `phase` | referência | Phase durante a qual o evento ocorreu |
| `work_item` | referência | Work Item ao qual o evento pertence |
| `event_type` | Event Type | O tipo canônico deste evento |
| `producer` | Event Producer | Quem originou o evento |
| `timestamp` | ponto no tempo | Momento preciso em que o evento ocorreu |
| `evidence` | Event Evidence | O registro imutável do evento (auto-evidência) |

**Propriedades opcionais:**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `cause` | referência | Evento anterior que causou este evento (causalidade explícita) |
| `artifacts` | lista de referências | Artefatos do Knowledge Space afetados ou referenciados |
| `alters_state` | booleano | Se este evento altera o Derived State |
| `new_state` | valor | O Derived State resultante (quando `alters_state = true`) |

**O que o Operational Event não é:**

- Não é o Work Item — ele pertence ao Work Item
- Não é o artefato (OBC, BDD) — ele registra algo que aconteceu com o artefato
- Não é o Derived State — ele pode causar uma mudança de estado, mas não é o estado
- Não é intenção futura — registra apenas fatos passados

---

### 2.2 Operational Timeline

> A sequência ordenada, imutável e acumulativa de todos os Operational Events associados
> a um Work Item específico, desde sua criação até seu encerramento.

**Propriedades:**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `work_item` | referência (1:1) | O Work Item ao qual esta Timeline pertence |
| `events` | lista ordenada | Todos os Operational Events, ordenados por timestamp |
| `derived_state` | Derived State | A projeção atual — computed, não armazenado |

**Características estruturais:**

- **Ordenada por timestamp:** nunca por ordem de inserção
- **Append-only:** eventos só são adicionados, nunca removidos ou reordenados
- **Acumulativa:** a Timeline só cresce ao longo da vida do Work Item
- **Autoritativa:** em conflito com qualquer outra representação de estado, a Timeline
  prevalece

**O que a Timeline não é:**

- Não é um log de sistema — tem semântica de processo, não de infraestrutura
- Não é um Kanban — não representa o estado atual; produz o estado como derivação
- Não é um histórico de edições do Work Item — registra eventos do processo, não mudanças
  de metadados do Work Item

---

### 2.3 Derived State

> O estado atual de um Work Item, computado como projeção do último Operational Event
> que altera estado na sua Operational Timeline.

**Propriedades:**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `timeline` | referência (1:1) | A Timeline a partir da qual o estado é derivado |
| `value` | estrutura | O estado atual: Journey + Phase + Status + qualquer dimensão relevante |
| `derived_from` | referência | O evento específico que determinou este estado |
| `at` | ponto no tempo | Timestamp do evento que gerou este estado |

**Regra de derivação:**

```
Derived State = f(último evento onde alters_state = true na Timeline)
```

Se nenhum evento na Timeline altera estado, o Derived State é o estado inicial do Work Item
(entrada na Journey).

**Características:**

- **Mutável:** muda a cada novo evento com `alters_state = true`
- **Derivado:** nunca atualizado manualmente; apenas via novos eventos
- **Sem memória:** o Derived State não registra o passado — a Timeline faz isso
- **Sempre consistente com a Timeline:** se estiver inconsistente, a Timeline prevalece

---

### 2.4 Event Producer

> O agente responsável por originar e registrar um Operational Event.

Todo Operational Event tem exatamente um Producer. A identidade do Producer é imutável
após o registro do evento — não pode ser alterada retroativamente.

**Três subtipos:**

| Subtipo | Descrição | Identificação |
|---|---|---|
| **Human** | Pessoa que tomou uma decisão ou executou uma ação | Papel (role) + identidade |
| **System** | Pipeline, ferramenta ou plataforma automatizada | Nome do sistema + versão |
| **Agent** | Agente de IA executando uma Skill | Tipo de agente + instância |

**Notas sobre identidade:**

- Um Human Producer é identificado pelo seu papel no processo (ex.: "Tech Lead aprovando
  Promote") e pela sua identidade — não apenas por um username.
- Um System Producer é identificado pelo sistema específico (ex.: "CI Pipeline — build gate")
  — não genérico como "automação".
- Um Agent Producer é identificado pelo tipo de agente e pela Skill sendo executada.

**Event Producer como conceito formal:**

O Event Producer não é uma entidade independente com ciclo de vida próprio no OEM — é um
atributo estrutural obrigatório de todo Operational Event. Não existe um "registro de
Producers" separado; o Producer existe como parte do evento que originou.

---

### 2.5 Event Consumer

> O papel assumido por qualquer componente do Framework que lê Operational Events ou
> a Operational Timeline para produzir análise, verificação ou decisão.

Event Consumer é um papel, não uma entidade. O mesmo componente pode ser Producer em
um contexto e Consumer em outro.

**Consumidores canônicos do OEM:**

| Consumidor | O que consome | Para que finalidade |
|---|---|---|
| **Diligence** | Timeline completa | Verificação de consistência COR×Timeline; Checks temporais |
| **Métricas** | Timestamps de eventos | Cálculo de Lead Time, Rework, Gate Quality, DORA |
| **Assessment** | Padrões de eventos entre Timelines | Análise objetiva de múltiplas releases |
| **Agentes** | Timeline do Work Item corrente | Tomada de decisão baseada em fatos; contexto de execução |
| **Humanos** | Visualização da Timeline | Revisão, audit, postmortem, retrospectiva |

**Nota sobre a COR:**

A COR não consome a Timeline diretamente — ela materializa o Derived State. A COR é uma
projeção de um único ponto na Timeline (o estado atual), não uma consumidora analítica
de toda a sequência de eventos.

**Event Consumer como conceito formal:**

Assim como Event Producer, Event Consumer é um atributo de interação, não uma entidade
com ciclo de vida próprio no OEM. Ele define o papel de quem lê eventos — mas os
consumidores em si (Diligence, Assessment, Agentes) são conceitos definidos em seus
próprios domínios.

---

### 2.6 Event Category

> Uma classificação de alto nível que agrupa Event Types por natureza operacional.

Event Categories são definidas no nível do Framework — são fixas e aplicam-se a todas
as Journeys. Um Event Type pertence a exatamente uma Category.

**Categorias canônicas:**

| Category | Natureza | Exemplos de tipos |
|---|---|---|
| **Phase Lifecycle** | Transição de entrada ou saída de uma Phase | `Phase.Started`, `Phase.Completed` |
| **Gate** | Resultado de avaliação de um critério de qualidade | `Gate.Passed`, `Gate.Failed` |
| **Human Decision** | Decisão tomada por um humano no fluxo | `Approve.Granted`, `Approve.Rejected` |
| **Blocking** | Declaração ou resolução de impedimento | `Impediment.Declared`, `Impediment.Resolved` |
| **Rework** | Retorno a uma Phase anterior | `Rework.Declared`, `Rework.Resolved` |
| **System** | Evento originado por infraestrutura ou pipeline | `Pipeline.Failed`, `Deploy.Completed` |
| **Diligence** | Evento emitido pela Diligence ao detectar anomalia | `Stale.Detected`, `Drift.Detected` |
| **Correction** | Correção de um evento registrado incorretamente | `Event.Corrected` |

**Propriedades de uma Category:**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `name` | identificador | Nome único da categoria |
| `nature` | descrição | A natureza operacional que a categoria representa |
| `alters_state` | booleano | Se eventos desta categoria tipicamente alteram o Derived State |
| `requires_producer` | subtipo | Subtipo de Producer obrigatório (ex.: Human Decision requer Human) |

---

### 2.7 Event Type

> O nome canônico de uma classe específica de Operational Event, pertencente a uma
> Event Category e definido no catálogo de eventos de uma Journey.

**Event Type vs. Operational Event:**

- `Event Type` é a classe: a definição abstrata de um tipo de evento (`Bootstrap.Started`)
- `Operational Event` é a instância: a ocorrência concreta de um tipo em um momento
  específico para um Work Item específico

**Propriedades de um Event Type:**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `name` | identificador | Nome no formato `Phase.Action` (PascalCase) |
| `category` | Event Category | A categoria à qual este tipo pertence |
| `journey` | Journey | A Journey cujo catálogo define este tipo |
| `phase` | Phase | A Phase durante a qual este evento tipicamente ocorre |
| `alters_state` | booleano | Se instâncias deste tipo alteram o Derived State |
| `new_state` | valor (opcional) | O Derived State resultante quando `alters_state = true` |
| `producer_subtypes` | lista | Subtipos de Producer válidos para este tipo |
| `preconditions` | lista | Condições que devem ser verdadeiras antes de emitir este evento |
| `postconditions` | lista | Condições que se tornam verdadeiras após emitir este evento |

**Convenção de nomenclatura:**

```
[Phase].[Action]        → Bootstrap.Completed
[Phase].[Subject]       → Hack.PROpened
[Gate].[Result]         → Validate.GateFailed
[Entity].[Transition]   → OBC.StateChanged
```

O catálogo de Event Types de cada Journey é definido em documentos específicos por
Journey (`journeys/<journey>/events/catalog.md`). Este documento define o conceito de
Event Type — não os tipos concretos de nenhuma Journey.

---

### 2.8 Event Evidence

> O registro imutável que prova que um Operational Event ocorreu.

**Princípio fundamental:**

> Um Operational Event é auto-evidenciante: o próprio registro do evento É a evidência
> de que ele ocorreu.

Porém, eventos de alta criticidade (aprovações, promoções, gates de qualidade) podem
referenciar evidências adicionais externas ao OEM — artefatos do Knowledge Space,
resultados de pipeline, relatórios de teste.

**Dois níveis de evidência:**

| Nível | Descrição | Origem |
|---|---|---|
| **Intrínseca** | O registro imutável do evento em si (producer, timestamp, context) | O OEM — parte de todo evento |
| **Referenciada** | Artefatos externos que corroboram o evento | Knowledge Space, pipeline, sistemas externos |

**Event Evidence como conceito formal:**

Event Evidence não é uma entidade separada com identidade própria — é uma propriedade
estrutural de todo Operational Event. Sua formalização como conceito canônico serve para
deixar explícito que:

1. Todo evento é evidência de sua própria ocorrência (evidência intrínseca)
2. Eventos críticos devem referenciar evidências externas verificáveis
3. A Diligence pode verificar a qualidade da evidência — não apenas a existência do evento

---

## 3. Relações

### 3.1 Tabela de relações

| Conceito | Depende de | Pertence a | Produz | Consome | Referencia | Pode existir sem |
|---|---|---|---|---|---|---|
| **Operational Event** | Event Type, Event Producer, Work Item | Operational Timeline | Event Evidence (intrínseca) | — | Journey, Phase, Cycle, Artifacts | Derived State change (evento pode não alterar estado) |
| **Operational Timeline** | Work Item | — (é a raiz por Work Item) | Derived State | — | Work Item | Não pode existir sem Work Item |
| **Derived State** | Operational Timeline | Operational Timeline | — | COR (para materialização) | — | Não pode existir sem Timeline |
| **Event Producer** | — | — (é um papel) | Operational Events | — | — | Event Producer existe independentemente de OEM |
| **Event Consumer** | — | — (é um papel) | — | Operational Events / Timeline | — | Event Consumer existe independentemente de OEM |
| **Event Category** | — | OEM (Framework) | — | — | Event Types | Sim — Category existe mesmo sem Types associados |
| **Event Type** | Event Category | Journey Event Catalog | Operational Events (instâncias) | — | Phase, Journey | Não — Type exige Category |
| **Event Evidence** | Operational Event | Operational Event | — | Diligence (verificação) | Artefatos externos | Evidência intrínseca: não. Referenciada: sim |

### 3.2 Relações detalhadas por conceito

**Operational Event:**
- pertence a exatamente **1** Operational Timeline
- é tipado por exatamente **1** Event Type
- tem exatamente **1** Event Producer
- produz exatamente **1** Event Evidence (intrínseca)
- pode referenciar **0 a N** artefatos do Knowledge Space
- pode ou não alterar o Derived State (depende do Event Type)
- pode ter **0 ou 1** evento de causa (causalidade explícita)

**Operational Timeline:**
- pertence a exatamente **1** Work Item
- contém **0 a N** Operational Events (0 no momento de criação)
- produz exatamente **1** Derived State (a projeção atual)
- é consumida por **N** Event Consumers (Diligence, métricas, Assessment, agentes)
- é materializada parcialmente pela COR (apenas o Derived State, não a Timeline completa)

**Derived State:**
- pertence a exatamente **1** Operational Timeline
- é derivado de exatamente **1** Operational Event (o último que altera estado)
- é materializado pela COR (parcialmente — a COR não armazena toda a Timeline)
- nunca é editado diretamente — apenas via novos eventos na Timeline

**Event Category:**
- agrupa **1 a N** Event Types
- é definida no nível do Framework — não por Journey
- um Event Type pertence a exatamente **1** Category

**Event Type:**
- pertence a exatamente **1** Event Category
- pertence ao catálogo de exatamente **1** Journey
- é instanciado por **0 a N** Operational Events (ao longo da vida do sistema)
- cada instância é um Operational Event concreto

---

## 4. Cardinalidades

### 4.1 Tabela de cardinalidades

| Relação | Cardinalidade | Justificativa |
|---|---|---|
| Work Item → Operational Timeline | 1:1 | Cada Work Item tem exatamente uma história operacional |
| Operational Timeline → Operational Events | 1:N | Uma Timeline contém zero ou mais eventos |
| Operational Event → Operational Timeline | N:1 | Todo evento pertence a exatamente uma Timeline |
| Operational Event → Event Type | N:1 | Todo evento é tipado por exatamente um Type |
| Operational Event → Event Producer | N:1 | Todo evento tem exatamente um Producer |
| Operational Event → Event Evidence (intrínseca) | 1:1 | Todo evento é auto-evidenciante |
| Operational Event → Artefatos referenciados | N:M | Um evento pode referenciar múltiplos artefatos; um artefato pode ser referenciado por múltiplos eventos |
| Operational Timeline → Derived State | 1:1 | Uma Timeline tem exatamente um Derived State (o atual) |
| Event Category → Event Types | 1:N | Uma Category agrupa um ou mais Types |
| Event Type → Event Category | N:1 | Um Type pertence a exatamente uma Category |
| Event Type → Operational Events | 1:N | Um Type pode ser instanciado zero ou mais vezes |
| Event Producer → Operational Events | 1:N | Um Producer pode originar zero ou mais eventos |

### 4.2 Cardinalidades críticas com justificativa expandida

**1 Work Item : 1 Operational Timeline**
A Timeline é a identidade operacional de um Work Item. Não faz sentido um Work Item ter
duas Timelines paralelas — seria como ter duas histórias simultâneas. Se um Work Item é
dividido em dois, dois Work Items distintos surgem, cada um com sua própria Timeline.

**N Operational Events : 1 Operational Timeline** (não 1:1)
A Timeline começa vazia (o Work Item existe antes de ter eventos). Ao longo da vida do
Work Item, eventos são adicionados. A cardinalidade mínima é 0 (Work Item recém-criado
sem nenhum evento ainda registrado).

**N Operational Events : 1 Event Type** (não 1:1)
O mesmo tipo de evento pode ocorrer múltiplas vezes no mesmo Work Item — por exemplo,
`Hack.PROpened` pode ocorrer 3 vezes se houve 3 PRs ao longo de múltiplas iterações.
O Event Type define a classe; a Timeline contém todas as instâncias.

**1 Operational Timeline : 1 Derived State** (snapshot atual — não histórico)
O Derived State não é uma lista de todos os estados que o Work Item já teve — isso é
o histórico de eventos na Timeline. O Derived State é o estado *agora*. Há sempre
exatamente um estado atual por Work Item.

---

## 5. Invariantes

Os invariantes são regras que nunca podem ser violadas, independente de Journey, Phase,
implementação ou contexto. Qualquer violação representa uma quebra fundamental do OEM.

### INV-01 — Imutabilidade dos eventos

> Todo Operational Event é imutável a partir do momento de seu registro.

Nenhum campo de um evento registrado pode ser alterado — nem o timestamp, nem o producer,
nem o state change. Se um evento foi registrado incorretamente, um novo evento do tipo
`Event.Corrected` é emitido, referenciando o evento original. O evento original permanece
na Timeline inalterado.

**Violação:** alterar diretamente qualquer campo de um evento já registrado.

### INV-02 — Integridade da Timeline (append-only)

> Operational Events nunca são removidos de uma Operational Timeline.

A Timeline é append-only — cresce ao longo da vida do Work Item, nunca diminui. Remover
um evento equivaleria a apagar um fato da história operacional — o que tornaria a Timeline
não confiável como fonte de verdade.

**Violação:** excluir, arquivar ou mover eventos de uma Timeline.

### INV-03 — Unicidade de Timeline por Work Item

> Todo Work Item tem exatamente uma Operational Timeline.

Não existem Timelines duplicadas, alternativas ou paralelas para o mesmo Work Item.

**Violação:** criar uma segunda Timeline para um Work Item que já tem uma Timeline ativa.

### INV-04 — Producer obrigatório em todo evento

> Todo Operational Event tem exatamente um Event Producer identificado.

Não existem eventos anônimos no OEM. A ausência de Producer invalida o registro como
Operational Event — tornando-o um log sem semântica de processo.

**Violação:** registrar um evento sem Producer, ou com Producer genérico como "sistema"
sem identificação precisa.

### INV-05 — Derived State nunca é atualizado diretamente

> O Derived State de um Work Item é sempre e exclusivamente computado a partir dos eventos
> da sua Operational Timeline.

Nenhum agente, humano, sistema ou mecanismo externo pode atualizar o Derived State
diretamente. A única forma de mudar o Derived State é adicionar um novo evento à Timeline
com `alters_state = true`.

**Violação:** atualizar um campo de estado do Work Item sem registrar o evento correspondente.

### INV-06 — COR nunca é fonte de verdade

> A Canonical Operational Representation (COR) é uma materialização do Derived State —
> nunca a fonte primária de verdade operacional.

Em caso de divergência entre o que a COR exibe e o que a Timeline indica, a Timeline
prevalece. A COR deve ser corrigida para refletir o Derived State derivado da Timeline.

**Violação:** usar o estado exibido na COR como referência quando ele diverge da Timeline,
sem investigar e corrigir a divergência.

### INV-07 — Event Types são definidos em catálogos por Journey

> Nenhum Operational Event pode usar um Event Type que não esteja definido no catálogo
> de eventos da Journey correspondente.

Eventos ad-hoc com tipos inventados no momento de emissão comprometem a padronização e
tornam a Timeline impossível de processar de forma consistente pelos Event Consumers.

**Violação:** registrar um evento com um tipo arbitrário não catalogado.

### INV-08 — A ausência de evento esperado é tratada como dado

> Quando um evento esperado para uma Phase não ocorre dentro da janela temporal esperada,
> essa ausência é registrada como informação operacional — não ignorada como lacuna.

A Diligence é responsável por detectar ausências de eventos e emitir o evento de
diagnóstico correspondente (categoria Diligence, ex.: `Stale.Detected`).

**Violação:** ignorar a ausência de um evento esperado sem registrá-la como anomalia.

### INV-09 — Timeline do Work Item prevalece sobre qualquer outra representação

> Em caso de conflito entre a Operational Timeline e qualquer outro sistema que represente
> o estado do Work Item (COR, backlogs, relatórios), a Timeline prevalece.

**Violação:** resolver uma divergência corrigindo a Timeline para corresponder à COR, em
vez de corrigir a COR para corresponder à Timeline.

### INV-10 — Correções são eventos, nunca edições retroativas

> Erros em eventos registrados são corrigidos pela emissão de um novo evento do tipo
> `Event.Corrected`, nunca pela edição retroativa do evento original.

**Violação:** editar qualquer campo de um evento já registrado, mesmo que o campo contenha
informação errada.

---

## 6. Fronteiras de Responsabilidade

### 6.1 O que pertence ao OEM

O OEM é responsável pela definição e governança dos seguintes conceitos:

- **Operational Event:** definição, propriedades obrigatórias e opcionais, invariantes
- **Operational Timeline:** estrutura, ordenação, propriedade append-only, relação com Work Item
- **Derived State:** definição, regra de derivação, relação com Timeline
- **Event Producer:** taxonomia de subtipos (Human, System, Agent)
- **Event Consumer:** definição do papel; os consumidores concretos são definidos em seus domínios
- **Event Category:** taxonomia canônica de categorias (fixas no Framework)
- **Event Type:** estrutura e convenções de nomenclatura; os tipos concretos são definidos por Journey
- **Event Evidence:** definição dos dois níveis (intrínseca e referenciada)
- **Invariantes** (INV-01 a INV-10)
- **Princípios** (P-01 a P-10, definidos no README)

### 6.2 O que pertence à Diligence

A Diligence é um Event Consumer especializado — ela verifica, não produz o estado
operacional. É responsável por:

- Definição dos Checks temporais (evento esperado não ocorreu?)
- Definição dos Checks de consistência (COR reflete o Derived State?)
- Geração de Findings quando invariantes são violados
- Emissão de eventos da categoria `Diligence` quando anomalias são detectadas
- Workspace Reconciliation (manter a COR sincronizada com o Derived State)

A Diligence **não** é responsável por:
- Definir o que é um Operational Event
- Definir os invariantes do OEM
- Conduzir Journeys — apenas verificá-las

### 6.3 O que pertence à COR

A Canonical Operational Representation é responsável por:

- Materialização do Derived State em uma representação acessível para humanos e agentes
- Estrutura dos Work Items (Fields, Labels, Views) que exibem o estado atual
- Schema de representação (o que é mostrado e como)

A COR **não** é responsável por:
- Armazenar a Timeline de eventos
- Ser fonte de verdade
- Definir o Derived State — ela apenas o materializa

### 6.4 O que pertence às Journeys

Cada Journey é responsável por:

- Definição do catálogo de Event Types específicos para suas Phases e Cycles
- Definição das janelas temporais esperadas por Phase (usado por Diligence para INV-08)
- Definição de quais eventos alteram o Derived State e para qual valor
- Obrigação de emissão: quais Skills emitem quais eventos em quais Steps
- Definição das pré e pós-condições de cada Event Type

As Journeys **não** são responsáveis por:
- Definir os invariantes do OEM
- Definir a estrutura da Timeline
- Definir o que é um Event Producer ou Consumer

### 6.5 O que não pertence a nenhum dos anteriores (implementação)

Os seguintes tópicos não pertencem à ontologia — são domínios de implementação tratados
em documentos futuros:

- **Schema técnico de eventos:** formato, campos, tipos de dados, validação
- **Event Store:** mecanismo de armazenamento e recuperação
- **Projection Engine:** mecanismo que computa o Derived State a partir da Timeline
- **Integração com ferramentas:** como eventos são registrados em GitHub, Jira, etc.
- **Automação baseada em eventos:** reações automáticas à emissão de eventos

---

## 7. Dependências Futuras

Os seguintes documentos dependerão desta ontologia para sua definição:

### 7.1 Documentos do domínio OEM

| Documento | Depende de | Finalidade |
|---|---|---|
| `events/schema.md` | Ontologia (estrutura de Operational Event, Event Type) | Define campos obrigatórios, formatos e regras de validação |
| `events/categories.md` | Ontologia (Event Category) | Expande a definição de cada categoria com exemplos |
| `events/timeline.md` | Ontologia (Operational Timeline, Derived State) | Define comportamento da Timeline, ordenação, projeção |

### 7.2 Documentos por Journey

| Documento | Depende de | Finalidade |
|---|---|---|
| `journeys/delivery/events/catalog.md` | Ontologia (Event Type, Event Category) | Catálogo de Event Types da Jornada Delivery |
| `journeys/diligence/events/catalog.md` | Ontologia (Event Type, categoria Diligence) | Catálogo de Event Types da Jornada Diligence |
| `journeys/assessment/events/catalog.md` | Ontologia (Event Type) | Catálogo de Event Types da Jornada Assessment |
| `journeys/discovery/events/catalog.md` | Ontologia (Event Type) | Catálogo de Event Types da Jornada Discovery |
| `journeys/operation/events/catalog.md` | Ontologia (Event Type) | Catálogo de Event Types da Jornada Operation |

### 7.3 Documentos de integração

| Documento | Depende de | Finalidade |
|---|---|---|
| `events/github-implementation.md` | Schema + Timeline | Como eventos são registrados na COR (GitHub) |
| `events/diligence-integration.md` | Ontologia + Diligence | Como Diligence consome a Timeline para Checks |
| `events/metrics.md` | Ontologia (Timeline, timestamps) | Como métricas são calculadas a partir de eventos |

---

## 8. Conceitos Avaliados e Descartados

Os seguintes conceitos foram considerados durante a elaboração desta ontologia e
descartados com justificativa:

| Conceito candidato | Motivo do descarte |
|---|---|
| **Operational History** | Linguagem informal para Timeline; formalizar implicaria cardinalidade ambígua (por OBC? Por Sprint?) |
| **Event Stream** | Sinônimo de Timeline com conotação de implementação (streaming) — desnecessário no nível conceitual |
| **Event Aggregate** | Pertence a domínio de implementação (DDD Aggregate) — não ao modelo conceitual |
| **Projection Engine** | Mecanismo executor — pertence a `events/timeline.md` ou implementação |
| **Event Subscriber** | Sinônimo técnico de Event Consumer — o termo Consumer é suficiente neste nível |
| **Event Schema** | Schema é implementação — pertence a `events/schema.md` |
| **Timeline Version** | Versionamento de Timeline é implementação — a Timeline é append-only por definição |

---

## Referências

- [Fundação OEM](README.md)
- [Ontologia do Framework](../ontology.md)
- [Knowledge Space vs. Execution Space](../knowledge-vs-execution.md)
- [Glossário](../glossary.md)
- Análise de eventos da Delivery
- Refinamento da fundação OEM

---

*Esta ontologia é a fonte canônica da estrutura conceitual do Operational Event Model.
Todo catálogo de eventos por Journey e todo documento de implementação deve referenciar
este documento como origem das definições e invariantes.*
