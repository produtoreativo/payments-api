# Taxonomia do Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [README.md](README.md) · [ontology.md](ontology.md)

---

## Sobre este documento

Este documento formaliza a **Taxonomia do Operational Event Model (OEM)**: o sistema de
classificação que organiza, nomeia e governa todos os Operational Events do Framework ProdOps.

A Taxonomia serve como contrato entre o Framework e as Journeys. Ela garante que eventos
de Journeys distintas sejam comparáveis, processáveis e auditáveis de forma consistente.

Este documento não define schema, formato, armazenamento nem catálogos concretos de eventos
por Journey. Esses documentos dependem desta Taxonomia para sua elaboração.

→ [Fundação OEM](README.md) · [Ontologia OEM](ontology.md) · [Ontologia do Framework](../ontology.md)

---

## 1. O que é uma Taxonomia de Eventos

### 1.1 Definição

> **Operational Event Taxonomy** é o sistema de classificação canônico que organiza
> todos os Operational Events do Framework ProdOps em categorias e tipos com semântica
> precisa, nomenclatura padronizada e regras de governança definidas.

A Taxonomia é o contrato que responde:

- A qual classe de acontecimento este evento pertence? → **Event Category**
- Qual o nome preciso deste evento dentro da sua Journey? → **Event Type**
- Quem pode definir novos tipos? Onde são documentados? → **Governança**
- Como os tipos evoluem sem quebrar Timelines existentes? → **Ciclo de vida**

### 1.2 Por que a Taxonomia existe

Sem uma taxonomia, cada Journey inventaria seus próprios nomes e categorias. O resultado
seria:

- Dois eventos com semânticas idênticas recebendo nomes distintos em Journeys diferentes
- Dois eventos com nomes similares tendo semânticas incompatíveis
- Impossibilidade de análises cross-Journey (métricas, Assessment, Diligence)
- Impossibilidade de auditar a Timeline sem conhecimento prévio de cada Journey

A Taxonomia elimina esses problemas ao definir:

1. **Categorias fixas no Framework** — comuns a todas as Journeys
2. **Tipos definidos por Journey** — específicos, mas seguindo regras universais
3. **Tipos compartilhados** — reutilizáveis entre múltiplas Journeys
4. **Convenção de nomenclatura única** — legível, previsível, não-ambígua

### 1.3 Responsabilidade da Taxonomia dentro do OEM

```
OEM
├── Fundação (README.md)    → O que são eventos; princípios
├── Ontologia (ontology.md) → Conceitos, relações, invariantes
├── Taxonomia (taxonomy.md) → Classificação, nomenclatura, governança ← este documento
├── Schema (schema.md)      → Estrutura técnica de cada evento
└── Catálogos por Journey   → Tipos concretos definidos por cada Journey
```

A Taxonomia vive entre a Ontologia (que define os conceitos) e o Schema (que define a
estrutura técnica). Ela não contém tipos concretos de nenhuma Journey — apenas as regras
que permitem que cada Journey defina os seus.

---

## 2. Event Category

### 2.1 Definição e finalidade

> **Event Category** é uma classificação de alto nível que agrupa Event Types por
> natureza operacional. Categorias são definidas exclusivamente no nível do Framework
> e são comuns a todas as Journeys.

A finalidade de uma Category é tripla:

1. **Classificação:** indica a natureza do acontecimento sem exigir leitura do nome completo
2. **Filtro:** permite que Event Consumers (Diligence, métricas, Assessment) filtrem por
   tipo de acontecimento sem conhecer todos os tipos de todas as Journeys
3. **Contrato de comportamento:** cada Category carrega expectativas sobre `alters_state`,
   `requires_producer` e padrões de emissão

### 2.2 Catálogo canônico de Categories

| Category | Descrição | `alters_state` | Producer típico | Frequência por ciclo |
|---|---|---|---|---|
| **Phase Lifecycle** | Entrada ou saída de uma Phase | Sim | Human, Agent | Alta — 2 por Phase (Start/End) |
| **Gate** | Resultado de avaliação de critério de qualidade | Condicional | System, Agent | Alta — 1+ por Phase |
| **Human Decision** | Decisão tomada por um humano no fluxo | Condicional | Human | Baixa — apenas em aprovações |
| **Blocking** | Declaração ou resolução de impedimento | Condicional | Human, Agent | Baixa — exceção ao fluxo normal |
| **Rework** | Retorno a uma Phase anterior | Sim | Human, Agent | Baixa — exceção ao fluxo normal |
| **System** | Evento originado por infraestrutura, pipeline ou ferramenta | Raramente | System | Variável — depende do pipeline |
| **Diligence** | Evento emitido pela Diligence ao detectar anomalia | Raramente | Agent (Diligence) | Baixa — exceção a ser remediada |
| **Correction** | Correção de um evento registrado incorretamente | Não | Human, Agent | Mínima — erro é exceção |

### 2.3 Propriedades de uma Category

| Propriedade | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `name` | identificador único | Sim | PascalCase, sem espaços |
| `description` | texto | Sim | Descrição da natureza operacional |
| `alters_state` | enum: Sim/Não/Condicional | Sim | Se eventos desta category tipicamente alteram Derived State |
| `requires_producer_subtypes` | lista | Não | Subtipos de Producer válidos (vazio = todos) |
| `governance_level` | Framework \| Journey | Sim | Quem pode definir tipos nesta Category |

### 2.4 Categories são fixas no Framework

Categories **não são extensíveis por Journeys**. Uma Journey não pode criar novas
Categories — apenas criar Event Types dentro das Categories existentes.

**Razão:** se Journeys pudessem criar Categories, duas Journeys poderiam criar categorias
com semântica equivalente mas nomes distintos. Isso quebraria a capacidade de análise
cross-Journey dos Event Consumers.

**O que fazer quando nenhuma Category existente serve?**

Um Event Type que não se encaixa em nenhuma Category é um sinal de que:

1. O tipo está sendo definido com granularidade ou semântica errada (o mais provável), ou
2. Uma nova Category Framework pode ser necessária — o que requer revisão da Taxonomia,
   não uma extensão unilateral da Journey

O processo de revisão é descrito na seção 8 (Governança).

### 2.5 Evolução das Categories

Categories evoluem **lentamente e de forma controlada** — somente pelo Framework, não por
Journeys individuais. O ciclo de vida de uma Category:

| Fase | Gatilho | Responsabilidade |
|---|---|---|
| **Proposta** | Múltiplas Journeys precisam de uma natureza sem Category existente | Framework (proposta formal) |
| **Revisão** | Análise de impacto em catálogos existentes | Framework |
| **Ativa** | Category em uso por pelo menos uma Journey | Framework |
| **Depreciada** | Category substituída por outra mais precisa | Framework — tipos migrados |
| **Removida** | Nenhum Type ativo referencia esta Category | Framework — somente após migração completa |

Uma Category depreciada continua válida para Event Types históricos. A remoção só ocorre
após todos os catálogos terem migrado seus tipos para a Category substituta.

---

## 3. Event Type

### 3.1 Definição

> **Event Type** é o nome canônico de uma classe específica de Operational Event,
> pertencente a uma Event Category e definido no catálogo de eventos de uma Journey.

O Event Type é a identidade de uma classe de acontecimento. Cada Operational Event
registrado na Timeline é uma instância de um Event Type.

### 3.2 Quem cria um Event Type

| Quem | Onde | Quando |
|---|---|---|
| A Journey que precisa registrar um novo tipo de acontecimento | Catálogo da Journey (`journeys/<journey>/events/catalog.md`) | Quando nenhum tipo existente — próprio ou compartilhado — cobre o acontecimento |

Nenhum Operational Event pode ser registrado com um Event Type que não esteja catalogado.
Tipos ad-hoc (criados no momento de emissão) violam INV-07.

### 3.3 Quem aprova um Event Type

A aprovação é responsabilidade da **governança da Journey** — a mesma autoridade que aprova
mudanças estruturais naquela Journey (ver seção 8). Para tipos com impacto cross-Journey
(tipos compartilhados), a aprovação requer revisão do Framework.

### 3.4 Onde um Event Type é documentado

Todo Event Type vive em **exatamente um** dos seguintes lugares:

| Tipo | Onde vive | Quem define |
|---|---|---|
| **Tipo compartilhado** | `events/shared-types.md` (futuro) | Framework |
| **Tipo de Journey** | `journeys/<journey>/events/catalog.md` | Journey |

Um tipo não pode existir em mais de um catálogo. Se duas Journeys precisam do mesmo
acontecimento, o tipo é promovido a compartilhado.

### 3.5 Um Event Type pode existir fora de uma Journey?

Sim — os **tipos compartilhados**. São tipos que representam acontecimentos genéricos
reutilizáveis por qualquer Journey, como `Phase.Started`, `Phase.Completed`, `Gate.Passed`,
`Gate.Failed`, `Impediment.Declared`, `Impediment.Resolved`, `Rework.Declared`, `Event.Corrected`.

Tipos compartilhados são definidos pelo Framework, não por uma Journey específica.

### 3.6 Um Event Type pode ser reutilizado por mais de uma Journey?

**Tipos compartilhados:** sim — por definição são reutilizáveis.

**Tipos de Journey:** não diretamente. Se duas Journeys precisam do mesmo acontecimento
com a mesma semântica, o tipo deve ser promovido a compartilhado. Se as semânticas são
distintas, cada Journey define o seu próprio tipo com nome apropriado.

**Regra crítica:** nunca importar um tipo de outra Journey sem promovê-lo a compartilhado.
Um tipo importado informalmente cria dependência oculta entre Journeys.

### 3.7 Propriedades de um Event Type

| Propriedade | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `name` | identificador | Sim | Nome canônico (ver convenção seção 5) |
| `category` | Event Category | Sim | A Category à qual este tipo pertence |
| `journey` | Journey \| `shared` | Sim | Journey dona, ou `shared` |
| `phase` | Phase \| null | Condicional | Phase durante a qual tipicamente ocorre |
| `alters_state` | booleano | Sim | Se instâncias alteram o Derived State |
| `new_state` | valor \| null | Condicional | O Derived State resultante (quando `alters_state = true`) |
| `producer_subtypes` | lista | Sim | Subtipos válidos: Human, System, Agent |
| `preconditions` | lista de texto | Sim | Condições que devem ser verdadeiras antes da emissão |
| `postconditions` | lista de texto | Sim | Condições que se tornam verdadeiras após a emissão |
| `status` | enum | Sim | Draft \| Active \| Deprecated \| Removed |
| `introduced_in` | versão | Sim | Versão do catálogo em que o tipo foi criado |
| `deprecated_in` | versão \| null | Não | Versão em que o tipo foi depreciado |

---

## 4. Relação entre Category e Type

### 4.1 Cardinalidades

| Relação | Cardinalidade | Invariante |
|---|---|---|
| Category → Event Types | 1 : N | Uma Category pode ter zero ou mais Types |
| Event Type → Category | N : 1 | Um Type pertence a exatamente uma Category |
| Event Type → Operational Events | 1 : N | Um Type pode ser instanciado zero ou mais vezes |
| Operational Event → Event Type | N : 1 | Todo evento tem exatamente um Type |

### 4.2 Restrições

**Um Type pode mudar de Category?**

Não. A Category de um Event Type é imutável. Se a categorização se mostrar errada, o
tipo é depreciado e um novo tipo é criado com a Category correta. Tipos históricos
mantêm sua Category original para preservar a integridade das Timelines existentes.

**Uma Category pode desaparecer?**

Apenas após todos os seus Types terem sido depreciados e migrados, e após todas as
Timelines históricas terem sido tratadas. Na prática, Categories nunca desaparecem —
são depreciadas com status claro e deixadas como referência histórica.

**Uma Journey pode criar uma nova Category?**

Não. Categories são exclusividade do Framework. Uma Journey que precisar de uma nova
Category deve propor sua criação ao Framework — não criá-la unilateralmente.

### 4.3 Invariantes específicos da relação Category × Type

**INV-TAX-01 — Imutabilidade da Category por Type**
A Category de um Event Type nunca muda. Se a Category está errada, o tipo é depreciado
e um novo tipo com a Category correta é criado.

**INV-TAX-02 — Monopólio de definição de Categories pelo Framework**
Nenhuma Journey pode criar, modificar ou depreciar uma Event Category sem aprovação
explícita do Framework.

**INV-TAX-03 — Nenhum Type sem Category**
Não existe Event Type sem Category. Um evento não categorizado não é um Operational Event
— é um log.

**INV-TAX-04 — Consistência entre Type e Category quanto a `alters_state`**
Um Event Type com `alters_state = true` deve pertencer a uma Category cujo campo
`alters_state` seja `Sim` ou `Condicional`. Um Type que altera estado mas pertence a
uma Category com `alters_state = Não` é uma inconsistência de taxonomia.

---

## 5. Convenção de Nomenclatura

### 5.1 A convenção adotada

```
[Namespace.]Subject.Action
```

| Componente | Obrigatoriedade | Descrição |
|---|---|---|
| `Namespace` | Opcional — omitido dentro do catálogo da Journey | Identificador da Journey (`Delivery`, `Diligence`, `Assessment`, `Discovery`, `Operation`) ou `Shared` |
| `Subject` | Obrigatório | O que foi afetado — uma Phase, uma entidade, um processo |
| `Action` | Obrigatório | O que aconteceu — verbo no passado ou substantivo de estado |

**Exemplos:**

```
Phase Lifecycle:    Bootstrap.Started       Bootstrap.Completed
Gate:               Gate.Passed             Gate.Failed
Human Decision:     Promote.Approved        Promote.Rejected
Blocking:           Impediment.Declared     Impediment.Resolved
Rework:             Rework.Declared         Rework.Resolved
System:             Pipeline.Failed         Deploy.Completed
Diligence:          Stale.Detected          Drift.Detected
Correction:         Event.Corrected

Com Namespace (referência cross-Journey):
                    Delivery.Bootstrap.Started
                    Diligence.Scan.DriftDetected
                    Shared.Gate.Passed
```

### 5.2 Regras de nomenclatura

**Regra 1 — PascalCase em todos os componentes**
```
✓ Bootstrap.Started
✓ Validate.GateFailed
✗ bootstrap.started
✗ BOOTSTRAP_STARTED
✗ bootstrap-started
```

**Regra 2 — Subject é o contexto mais específico relevante**
```
✓ Bootstrap.Started     → Phase é o subject
✓ OBC.StateChanged      → Entidade afetada é o subject
✗ Delivery.Started      → Ambíguo demais — o que na Delivery começou?
✗ Something.Happened    → Genérico demais
```

**Regra 3 — Action descreve o acontecimento, não a intenção**
```
✓ Gate.Failed           → fato passado
✓ Promote.Approved      → fato passado
✗ Gate.Failing          → estado contínuo
✗ Gate.WillFail         → intenção futura
✗ Gate.ShouldBe         → expectativa
```

**Regra 4 — Par complementar para eventos de transição**
Eventos que representam início e fim de uma ação devem usar Action complementar:
```
✓ Phase.Started / Phase.Completed
✓ Impediment.Declared / Impediment.Resolved
✓ Rework.Declared / Rework.Resolved
✗ Phase.Begin / Phase.Done         → inconsistente
✗ Block.On / Block.Off             → não descritivo
```

**Regra 5 — Nomes sem referência tecnológica**
```
✓ Pipeline.Failed       → processo, não ferramenta
✓ Deploy.Completed      → ação, não ferramenta
✗ GitHubActions.Failed  → referência tecnológica
✗ PRMerged              → referência tecnológica (PR = GitHub)
✗ JiraTicketClosed      → referência tecnológica
```

**Regra 6 — Unicidade semântica no conjunto combinado de catálogos**
Dois tipos com o mesmo Subject.Action mas em Journeys diferentes devem ter semânticas
*diferentes*. Se as semânticas são iguais, o tipo deve ser compartilhado.

```
Aceitável:
  Delivery.Promote.Completed  ≠  Diligence.Promote.Completed
  (Promote tem significado diferente em cada Journey)

Não aceitável (promover a compartilhado):
  Delivery.Gate.Failed  ≈  Diligence.Gate.Failed
  (Gate.Failed tem a mesma semântica — deve ser Shared.Gate.Failed)
```

### 5.3 Vantagens desta convenção

| Vantagem | Descrição |
|---|---|
| **Leitura direta** | `Bootstrap.Started` é auto-descritivo sem consultar o catálogo |
| **Namespace opcional** | Dentro do catálogo, o Namespace é implícito — menos verbosidade |
| **Cross-Journey inequívoco** | Com Namespace, `Delivery.Promote.Completed` é inequívoco |
| **Par complementar natural** | `Phase.Started` / `Phase.Completed` formam par óbvio |
| **Livre de tecnologia** | Refatoring de ferramentas não exige renomear eventos |
| **Ordenação alfabética natural** | `Bootstrap.*` agrupa todos os eventos de Bootstrap |

### 5.4 Limitações conhecidas

| Limitação | Mitigação |
|---|---|
| **Colisão de Subject entre Journeys** | Namespace resolve; Shared promove |
| **Subject ambíguo para eventos cross-Phase** | Usar Category como Subject alternativo |
| **Verbosidade com Namespace** | Namespace só é obrigatório fora do catálogo da Journey |
| **Evolução de nomes de Phase** | Renomear Phase exige deprecar tipos e criar novos — alto custo |

---

## 6. Evolução da Taxonomia

### 6.1 Ciclo de vida de um Event Type

```
Necessidade          Proposta              Revisão           Aprovação
identificada    →    redigida no      →    pelos              pelo
pela Journey         catálogo              consumidores       Framework
                     (status: Draft)       (Diligence,        (status: Active)
                                           Métricas,
                                           Assessment)
                                               ↓
                                    (em uso nas Timelines)
                                               ↓
                     Necessidade de           ↓
                     mudança       →    Deprecação          Novo tipo criado
                                        (status: Deprecated) (substitui)
                                               ↓
                     Nenhuma emissão          ↓
                     nova esperada  →    Remoção do catálogo (status: Removed)
                                        (Timelines históricas preservadas)
```

### 6.2 Como um novo Event Type nasce

1. **Identificação:** a Journey identifica um acontecimento que deve ser registrado e para
   o qual nenhum tipo existente (próprio ou compartilhado) possui semântica adequada.
2. **Verificação de duplicatas:** antes de propor, a Journey verifica os catálogos de todas
   as Journeys e o catálogo de tipos compartilhados para confirmar que o tipo não existe.
3. **Rascunho:** o tipo é documentado com todas as propriedades obrigatórias, incluindo
   Category, precondições, pós-condições e se altera o Derived State.
4. **Revisão:** a proposta é revisada pelos Event Consumers principais (Diligence, quem
   mantém as métricas, quem mantém o Assessment) para verificar impacto.
5. **Aprovação:** o tipo entra em status `Active` e pode ser emitido por Skills.

### 6.3 Como um Event Type evolui

Event Types **não evoluem** — eles são imutáveis após aprovação. Um tipo ativo não pode
ter suas propriedades alteradas (Category, `alters_state`, `new_state`).

**O que pode mudar sem deprecar:**
- Clarificação da `description` (editorial)
- Adição de exemplos na documentação
- Adição de notas de clarificação sobre precondições/pós-condições

**O que exige deprecar e criar novo tipo:**
- Mudança de Category
- Mudança de `alters_state`
- Mudança de `new_state`
- Renomear o tipo
- Mudar a semântica do acontecimento representado

### 6.4 Como um Event Type é depreciado

1. O tipo recebe status `Deprecated` no catálogo.
2. Uma `deprecation_note` é adicionada explicando a razão e o tipo substituto.
3. Skills que emitiam o tipo depreciado são atualizadas para emitir o tipo substituto.
4. **Timelines históricas que contêm eventos do tipo depreciado permanecem válidas.** O tipo
   depreciado continua sendo reconhecido pelos Event Consumers para leitura de histórico.

### 6.5 Como um Event Type é removido

Um tipo só entra em status `Removed` quando:

- Está em status `Deprecated` há pelo menos um ciclo completo de Journey (para garantir
  que nenhuma Timeline ativa ainda o usa ativamente)
- Nenhuma nova emissão ocorreu desde a deprecação
- Os Event Consumers confirmaram que o tipo pode ser excluído do processamento ativo

**Importante:** remover um tipo do catálogo não apaga eventos históricos que o usam.
Timelines são imutáveis — eventos com tipos removidos permanecem na Timeline com o tipo
original registrado. O catálogo mantém tipos removidos como referência histórica read-only.

### 6.6 Compatibilidade entre versões

O catálogo de uma Journey é versionado. Regras de compatibilidade:

| Mudança | Compatível? | Ação |
|---|---|---|
| Adicionar novo tipo (status: Active) | Sim | Compatível com versões anteriores — consumidores ignoram tipos desconhecidos |
| Deprecar tipo existente | Sim | Compatível — tipo ainda reconhecido |
| Remover tipo (status: Removed) | Atenção | Consumidores devem tratar eventos históricos com tipos removidos |
| Renomear tipo | Não | Exige deprecar o original e criar novo — nunca renomear diretamente |
| Mudar `alters_state` de um tipo ativo | Não | Exige deprecar e criar novo |

---

## 7. Regras para as Journeys

### 7.1 O contrato

Toda Journey que define Event Types deve assinar o seguinte contrato:

**REG-01 — Verificar antes de criar**
Antes de criar um novo Event Type, a Journey DEVE verificar se existe um tipo equivalente
nos tipos compartilhados ou no catálogo de outra Journey. Duplicar semântica viola INV-07
e fragmenta a capacidade analítica dos Event Consumers.

**REG-02 — Usar tipos compartilhados quando disponíveis**
Se um tipo compartilhado cobre o acontecimento com precisão adequada, a Journey DEVE
usá-lo — não criar uma variação própria. Tipos compartilhados são superiores porque são
processados por todos os Event Consumers sem necessidade de mapeamento específico.

**REG-03 — Promover tipos equivalentes entre Journeys**
Se duas Journeys precisam do mesmo acontecimento com a mesma semântica, o tipo DEVE ser
promovido a compartilhado. A duplicidade nunca é a solução correta.

**REG-04 — Seguir a convenção de nomenclatura**
Todos os Event Types DEVEM seguir a convenção `Subject.Action` com PascalCase. Nomes que
violam a convenção não podem entrar em status Active.

**REG-05 — Documentar todas as propriedades obrigatórias**
Um Event Type sem Category, sem `alters_state` definido, sem precondições ou sem
pós-condições não é um tipo completo. Tipos incompletos não podem entrar em status Active.

**REG-06 — Não referenciar tecnologia nos nomes**
Event Types NÃO DEVEM referenciar ferramentas, plataformas, sistemas ou implementações
em seus nomes. O nome deve sobreviver à substituição de qualquer ferramenta.

**REG-07 — Documentar o impacto no Derived State**
Todo Event Type DEVE declarar explicitamente se altera o Derived State e, se sim, para
qual valor. A ambiguidade sobre `alters_state` invalida o tipo como fonte confiável de
projeção de estado.

**REG-08 — Documentar o Event Producer esperado**
Todo Event Type DEVE declarar quais subtipos de Producer são válidos para sua emissão.
Um evento emitido por um Producer não declarado é uma violação de taxonomia.

**REG-09 — Par complementar para transições**
Eventos que representam início e fim de uma transição DEVEM existir em par. Não se define
apenas `Phase.Started` sem `Phase.Completed`.

**REG-10 — Manter compatibilidade da Timeline**
Nenhuma mudança em Event Types pode invalidar Timelines existentes. A Timeline é imutável
— as regras de evolução (seção 6) devem ser seguidas para garantir que eventos históricos
permaneçam legíveis.

---

## 8. Governança

### 8.1 Estrutura de governança

A Taxonomia tem dois níveis de governança, correspondentes aos dois tipos de elemento:

| Elemento | Governado por | Processo |
|---|---|---|
| **Event Category** | Framework | Proposta formal, revisão de impacto em todas as Journeys, aprovação centralizada |
| **Shared Event Type** | Framework | Proposta de Journey, revisão por todos os consumidores, aprovação centralizada |
| **Journey Event Type** | Journey | Proposta interna, revisão por consumidores da Journey (Diligence), aprovação da Journey |

### 8.2 Responsabilidades do Framework na governança

O Framework é responsável por:

- **Manter o catálogo de Event Categories** — adicionar, deprecar, remover
- **Manter o catálogo de tipos compartilhados** — `events/shared-types.md` (futuro)
- **Arbitrar conflitos de nomenclatura** — quando duas Journeys propõem tipos similares
- **Auditar consistência cross-Journey** — garantir que REG-01 a REG-10 são seguidos
- **Revisar propostas de novas Categories** — avaliar se realmente não se encaixa nas existentes
- **Definir e versionar a Taxonomia** — este documento

O Framework **não** é responsável por:

- Definir os Event Types específicos de cada Journey — isso é responsabilidade da Journey
- Validar se a emissão de eventos está ocorrendo corretamente — isso é responsabilidade da Diligence

### 8.3 Responsabilidades da Journey na governança

Cada Journey é responsável por:

- **Manter seu catálogo de Event Types** — criar, aprovar, deprecar seus tipos
- **Garantir conformidade com REG-01 a REG-10** — toda proposta de tipo deve atender
- **Notificar o Framework** quando propõe tipos que podem ser compartilhados
- **Garantir que Skills emitem os tipos corretos** — o catálogo e as Skills devem estar alinhados
- **Manter versionamento do catálogo** — cada mudança incrementa a versão

### 8.4 Quem pode aprovar novas Categories?

Somente o **Framework** pode aprovar novas Event Categories. O processo:

1. Uma Journey identifica que nenhuma Category existente cobre a natureza do acontecimento
2. A Journey propõe a nova Category com: nome, descrição, `alters_state`, `requires_producer`
3. O Framework avalia se a Category realmente não é coberta pelas existentes
4. Se aprovada, a Category é adicionada à Taxonomia com versionamento

### 8.5 Quem pode depreciar eventos?

| O que | Quem pode depreciar |
|---|---|
| Event Category | Framework apenas |
| Shared Event Type | Framework apenas |
| Journey Event Type | A Journey dona do tipo |

---

## 9. Relação com Documentos Futuros

Esta Taxonomia é a base para os seguintes documentos — todos dependem das categorias,
convenções e regras definidas aqui:

### 9.1 Documentos do domínio OEM

| Documento | Como usa a Taxonomia |
|---|---|
| `events/schema.md` | Define a estrutura técnica de cada atributo de um Event Type; usa Category para validações de consistência |
| `events/shared-types.md` | Catálogo de tipos compartilhados — todos seguem a nomenclatura e as regras desta Taxonomia |
| `events/timeline.md` | Define o comportamento da Timeline; usa Categories para regras de ordenação e derivação de estado |
| `events/event-store.md` | Define armazenamento; usa Categories para estratégias de indexação e retenção |

### 9.2 Documentos por Journey

| Documento | Como usa a Taxonomia |
|---|---|
| `journeys/*/events/catalog.md` | Define os Event Types da Journey; cada tipo DEVE seguir a convenção de nomenclatura, pertencer a uma Category desta Taxonomia e satisfazer REG-01 a REG-10 |

### 9.3 Documentos de consumo

| Consumidor | Como usa a Taxonomia |
|---|---|
| **Diligence** | Checks filtram por Category (ex.: "houve evento de Category Gate.Failed nos últimos N dias?"); detecta ausências por Category esperada por Phase |
| **Assessment** | Análise de padrões usa Categories para agregar — ex.: "proporção de Gate.Failed em Gate.Passed ao longo de 3 releases" |
| **Métricas** | Métricas de tempo usam `Phase Lifecycle` como âncoras; métricas de qualidade usam `Gate`; métricas de retrabalho usam `Rework` |
| **Agentes** | Filtram a Timeline por Category para tomar decisões contextuais sem processar todos os eventos |

---

## 10. Anti-padrões

### ANT-01 — Duplicação semântica entre Journeys

**O problema:** Journey A cria `Validate.Completed` e Journey B cria `Review.Done`, ambos
representando a conclusão bem-sucedida de uma fase de validação.

**Consequência:** métricas cross-Journey são impossíveis sem mapeamento manual. Assessment
não consegue comparar Journeys.

**Solução:** promover a tipo compartilhado `Phase.Completed` com propriedades específicas.

---

### ANT-02 — Nomes diferentes para a mesma semântica na mesma Journey

**O problema:** `Bootstrap.Started` e `Bootstrap.Begin` coexistem no mesmo catálogo com
a mesma semântica.

**Consequência:** ambiguidade na Timeline; consumidores precisam tratar os dois.

**Solução:** um único tipo por semântica; deprecar o duplicado imediatamente.

---

### ANT-03 — Event Category sobrepostas

**O problema:** criar uma Category `Transition` que engloba tanto Phase Lifecycle quanto
Human Decision.

**Consequência:** filtros por Category perdem precisão; Diligence não consegue distinguir
transição automática de decisão humana.

**Solução:** Categories devem ser orthogonais — nenhum Event Type deve ser ambíguo entre
duas Categories.

---

### ANT-04 — Event Type genérico demais

**O problema:** criar `Thing.Happened` ou `Event.Occurred` como tipo genérico de fallback.

**Consequência:** a Timeline perde significado; métricas derivadas desses tipos são inúteis.

**Solução:** todo tipo deve ter semântica precisa. Se o acontecimento não pode ser nomeado
com precisão, ele não deve ser registrado como Operational Event.

---

### ANT-05 — Event Type tecnológico

**O problema:** criar `PullRequest.Merged` (referência ao GitHub), `JiraTicket.Closed`
ou `CircleCI.PipelinePassed`.

**Consequência:** mudar de ferramenta invalida toda a Timeline histórica; consumidores
ficam acoplados à infraestrutura.

**Solução:** nomear o acontecimento pelo processo, não pela ferramenta: `CodeReview.Approved`,
`Pipeline.Completed`, `WorkItem.Closed`.

---

### ANT-06 — Event Type que representa intenção, não fato

**O problema:** criar `Deploy.Planned`, `Gate.Expected`, `Phase.Scheduled`.

**Consequência:** viola P-01 (eventos representam fatos); a Timeline mistura fatos com
planejamento, tornando-se não confiável como fonte de verdade.

**Solução:** somente fatos ocorridos são Operational Events. Planejamento vive em
artefatos do Knowledge Space.

---

### ANT-07 — Journey criando Event Category unilateralmente

**O problema:** Discovery decide que precisa de uma Category `Signal` e a cria no seu
próprio catálogo.

**Consequência:** a Category `Signal` não é reconhecida pelos Event Consumers do Framework;
quebra a padronização; fragmenta análises cross-Journey.

**Solução:** proposta formal ao Framework; enquanto não aprovada, o tipo usa a Category
existente mais próxima.

---

### ANT-08 — Mudar `alters_state` de um tipo ativo

**O problema:** um tipo ativo tem `alters_state = false` e a Journey decide mudar para
`true` sem deprecar o tipo.

**Consequência:** Timelines históricas calculam Derived State incorretamente para eventos
anteriores à mudança; inconsistência retrospectiva indetectável.

**Solução:** deprecar o tipo e criar novo com `alters_state` correto. Imutabilidade do
tipo é INV-TAX-01.

---

### ANT-09 — Importar tipos de outra Journey sem promover a compartilhado

**O problema:** Delivery decide usar `Diligence.Scan.Completed` em sua Timeline porque
"é o mesmo acontecimento".

**Consequência:** dependência oculta entre Journeys; se Diligence depreca o tipo, Delivery
quebra; o tipo aparece em contexto errado nas análises.

**Solução:** promover a tipo compartilhado `Scan.Completed` ou criar `Delivery.Scan.Completed`
com semântica própria.

---

### ANT-10 — Criar tipos para acontecimentos não operacionais

**O problema:** criar `BusinessDecision.Made` (decisão estratégica de produto) ou
`StakeholderMeeting.Held` como Operational Events.

**Consequência:** polui a Timeline com acontecimentos fora do escopo do ProdOps; os Event
Consumers não sabem o que fazer com eles.

**Solução:** Operational Events representam fatos do *processo de execução do Framework*
— não fatos do mundo externo, do negócio ou da estratégia.

---

### ANT-11 — Tipos de correção usados para esconder erros

**O problema:** ao invés de investigar por que um evento incorreto foi emitido, a Journey
emite `Event.Corrected` rotineiramente como workaround.

**Consequência:** a Timeline se torna ruído; a causa raiz dos erros de emissão nunca é
tratada; consumidores perdem confiança na Timeline.

**Solução:** `Event.Corrected` é para erros excepcionais de registro humano ou de sistema.
Emissões frequentes de correção indicam falha no processo de emissão — que deve ser
corrigida nas Skills, não na Timeline.

---

## Referências

- [Fundação OEM](README.md)
- [Ontologia OEM](ontology.md)
- [Ontologia do Framework](../ontology.md)
- Análise de eventos da Delivery
- Refinamento da fundação OEM
- Relatório da ontologia OEM

---

*Esta Taxonomia é a fonte canônica de classificação e nomenclatura do OEM. Todo catálogo
de eventos por Journey, todo documento de schema e todo documento de implementação deve
referenciar este documento como origem das convenções e regras de governança.*
