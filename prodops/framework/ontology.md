[English](ontology.en.md)

# ProdOps Ontology

Definição canônica dos conceitos estruturais do Framework ProdOps.

Este documento é a **fonte única de verdade** para a hierarquia de conceitos. Todos os outros documentos que descrevem ou citam esses conceitos devem referenciar este documento em vez de redefinir os termos.

→ Para o vocabulário completo, ver [glossary.md](glossary.md).
→ Para o fluxo operacional, ver [operating-model.md](operating-model.md).

---

## Hierarquia de conceitos

O ProdOps é organizado em duas dimensões ortogonais:

**Dimensão estrutural** — organiza o trabalho:

```
Framework
  └── Journey (5 jornadas)
        └── Cycle (agrupamentos dentro de uma jornada)
              └── Phase (estágios individuais dentro de um ciclo)
```

**Dimensão transversal** — define como e com quê o trabalho é executado:

```
Execution Model  ←  define o nível de compromisso aplicado à Journey
Capability       ←  mecanismo reutilizável consumido pela Phase
Skill            ←  implementação executável de uma Phase ou Journey
  └── Step       ←  sub-unidade de uma Skill
```

O diagrama completo de relacionamentos:

```
Framework
├── Execution Model (Upstream | Downstream)
│     aplica-se a ↓ qualquer Journey
├── Journey
│     ├── Discovery
│     ├── Delivery
│     │     ├── Cycle: CI Sync  →  Phase: Bootstrap → Hack → Sync → Finish
│     │     └── Cycle: CI Async →  Phase: Ship → Validate → Promote
│     ├── Operation
│     ├── Assessment
│     └── Diligence
│           ├── Cycle: diligence-sync   →  Phase: Capture → Attach → Promote → Close
│           ├── Cycle: diligence-async  →  Phase: Scan → Flag → Repair
│           └── Cycle: workspace-reconciliation → Phase: Inspect → Reconcile → Verify
│
├── Capability (consumida pelas Phases)
│     ├── Delivery Capabilities  (Commit Workflow, Contract Management, Evidence Management, Observability, Reliability)
│     └── Diligence Capabilities (Backlog Synchronization, Work Item Management, Divergence Detection, Workspace Reconciliation, …)
│
└── Skill (implementa Phase, Cycle ou Journey)
      └── Step (sub-unidade de uma Skill)
```

---

## Definições canônicas

### Framework

**O que é:** O sistema canônico de princípios, vocabulário, modelo operacional, jornadas, capabilities e skills que define como o ProdOps funciona.

**Responsabilidade:** Ser a fonte única de verdade sobre como trabalhar com ProdOps — independente de qual produto, portfolio ou workspace o está usando.

**Nível de abstração:** Meta-nível. Define a estrutura que todos os outros níveis (Portfolio, Workspace, Product Repository) adotam.

**Contém:** Princípios, glossário, fluxo oficial, Execution Model, jornadas, capabilities, skills, templates, Origin Streams.

**Existe em:** Repositório dedicado de referência; distribuído e adotado por Product Repositories.

**Nunca representa:** Roadmap, Backlogs de produto, Business Intents, Features, Releases.

---

### Execution Model

**O que é:** Os dois modos de compromisso e critérios de qualidade que definem como qualquer jornada será executada — Upstream (exploração) e Downstream (compromisso).

**Responsabilidade:** Definir o nível de rigor, os quality gates e o compromisso de entrega aplicado quando qualquer jornada é executada.

**Nível de abstração:** Transversal a todas as jornadas. O modo não é a jornada — ele define como a jornada executa.

**Contém:** Upstream, Downstream, regras de transição entre modos.

**Existe em:** Parte do Framework; aplicado por cada jornada.

**Nunca representa:** Uma jornada específica, um ciclo, uma fase.

→ [execution-model/README.md](../execution-model/README.md)

---

### Journey (Jornada)

**O que é:** Um caminho de trabalho com responsabilidade única, ciclo de vida próprio e critérios de entrada e saída definidos.

**Responsabilidade:** Organizar o trabalho por intenção — o que está sendo feito — independente do modo de execução (o modo define apenas como a jornada executa).

**Nível de abstração:** Imediatamente abaixo do Framework. O Execution Model se aplica sobre a jornada; a jornada não está dentro do Execution Mode.

**As 5 jornadas:**

| Jornada | Tipo | Responsabilidade |
|---|---|---|
| Discovery | Clássica | Reduzir incerteza e preparar o trabalho |
| Delivery | Clássica | Construir, validar e promover a solução |
| Operation | Clássica | Operar e evoluir o produto em produção |
| Assessment | Transversal | Produzir análises para apoiar decisões |
| Diligence | Transversal | Garantir aderência ao modelo operacional |

**Contém:** Um ou mais Cycles.

**Existe em:** O Framework define as 5 jornadas; Product Repositories as executam.

**Nunca representa:** Um modo de execução. Upstream e Downstream não são jornadas.

→ [journeys/README.md](../journeys/README.md)

---

### Cycle (Ciclo)

**O que é:** Um agrupamento ordenado de fases dentro de uma jornada, com propósito, acionamento e natureza distintos.

**Responsabilidade:** Separar conjuntos de fases que têm natureza operacional diferente dentro da mesma jornada — por exemplo, trabalho síncrono vs. assíncrono, ou reativo vs. proativo.

**Nível de abstração:** Entre Journey e Phase — agrupa fases com propósito comum, mas não substitui a jornada.

**Os ciclos por jornada:**

| Jornada | Ciclo | Natureza |
|---|---|---|
| Delivery | CI Sync | Síncrono — trabalho local, conduzido pelo engenheiro |
| Delivery | CI Async | Assíncrono — trabalho conduzido pela plataforma |
| Diligence | diligence-sync | Reativo — acionado por evento externo |
| Diligence | diligence-async | Proativo — iniciado por varredura periódica |
| Diligence | workspace-reconciliation | Por demanda — Inspect → Reconcile → Verify |

**Nota:** Discovery, Operation e Assessment não têm ciclos formais — operam como uma sequência fluida de fases sem agrupamento explícito.

**Contém:** Um conjunto ordenado de Phases.

**Existe em:** Dentro de uma Journey.

**Nunca representa:** Uma jornada, uma fase individual, uma capability.

---

### Phase (Fase)

**O que é:** Um estágio individual e ordenado dentro de um Cycle, com entrada, saída e responsabilidade únicos.

**Responsabilidade:** Executar uma etapa atômica e verificável dentro de um ciclo. Cada fase tem pré-condições claras de entrada e pós-condições verificáveis de saída.

**Nível de abstração:** A menor unidade estrutural do modelo conceitual. Abaixo da Phase existem apenas Steps — unidades de implementação dentro de Skills.

**As fases por ciclo:**

| Ciclo | Fases |
|---|---|
| CI Sync | Bootstrap → Hack → Sync → Finish |
| CI Async | Ship → Validate → Promote |
| diligence-sync | Capture → Attach → Promote → Close |
| diligence-async | Scan → Flag → Repair |
| workspace-reconciliation | Inspect → Reconcile → Verify |

**Contém:** Nenhum sub-conceito formal — a implementação de uma Phase é feita por uma Skill e seus Steps.

**Existe em:** Dentro de um Cycle.

**Nunca representa:** Uma jornada, um ciclo, uma capability, um artefato.

> **Distinção obrigatória — Lifecycle Stage vs. Delivery Phase:**
>
> O documento [`phases.md`](phases.md) descreve **Concepção** e **Inception** — estágios do ciclo de vida de uma Business Intent **antes** da jornada Delivery. Esses são **Lifecycle Stages** (estágios de ciclo de vida), conceitualmente distintos das **Delivery Phases** (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) e das **Diligence Phases** (Capture, Attach, etc.).
>
> Quando houver ambiguidade, usar o qualificador: "Lifecycle Stage", "Delivery Phase" ou "Diligence Phase".

---

### Capability

**O que é:** Competência técnica reutilizável consumida por uma ou mais Phases. Não tem acionamento próprio — é invocada quando a Phase a requer.

**Responsabilidade:** Prover um mecanismo técnico específico que múltiplas fases podem usar sem duplicar sua definição.

**Nível de abstração:** Transversal às fases — não está hierarquicamente abaixo delas, mas é consumida por elas.

**Três famílias distintas:**

| Família | Escopo | Exemplos |
|---|---|---|
| **Delivery Capability** | Mecanismo de Framework consumido pelas fases da jornada Delivery | Commit Workflow, Contract Management, Evidence Management, Observability, Reliability |
| **Diligence Capability** | Mecanismo consumido pelas fases da jornada Diligence | Backlog Synchronization, Work Item Management, Divergence Detection, Artifact Evolution, Workspace Reconciliation |
| **Product Capability** | A funcionalidade do produto sendo construída — o objeto do trabalho, não o mecanismo | Split payment, Pix, webhook de confirmação |

**Regra crítica:** Quando o contexto for ambíguo, usar o qualificador completo: "Delivery Capability", "Diligence Capability" ou "Product Capability". Nunca usar "Capability" sozinho quando puder haver confusão entre os três tipos.

**Existe em:** `journeys/delivery/capabilities/` (Delivery) e `journeys/diligence/capabilities/` (Diligence).

**Nunca representa:** Uma fase, um ciclo, uma jornada, uma skill. Product Capability não é um mecanismo do Framework — é o objeto do trabalho.

---

### Skill

**O que é:** Comportamento executável implementado por um agente. Corresponde a uma Phase, Cycle ou Journey e descreve exatamente o que o agente deve fazer, quando entrar, o que ler e o que produzir.

**Responsabilidade:** Ser a implementação executável de uma Phase ou de uma Journey entry point. É a ponte entre o modelo conceitual e a execução pelo agente.

**Nível de abstração:** Implementação — não é documentação conceitual. Uma Skill implementa uma Phase; não substitui a definição da Phase. A documentação conceitual vive em `journeys/`; a Skill executável vive em `skills/`.

**Contém:** Steps (sub-unidades ordenadas dentro de uma Skill).

**Existe em:** `prodops/skills/` — separado da documentação conceitual.

**Nunca representa:** Documentação conceitual, template, artifact, capability.

→ [skills/README.md](../skills/README.md)

---

### Step

**O que é:** Sub-unidade ordenada dentro de uma Skill, com entrada e saída próprias.

**Responsabilidade:** Implementar uma etapa específica dentro de uma Skill de forma autossuficiente e isolada. Um Step pode ser invocado individualmente quando necessário.

**Nível de abstração:** Implementação — abaixo de Skill. O Step não existe no modelo conceitual acima do nível de Skill; ele pertence exclusivamente à dimensão de implementação.

**Contém:** Instruções executáveis, referências a artefatos de entrada e saída.

**Existe em:** `prodops/skills/<skill>/steps/<step>/SKILL.md` ou `prodops/skills/<skill>/<cycle>/steps/<step>/SKILL.md`.

**Nunca representa:** Uma Phase, uma Capability, um artefato conceitual.

---

## Relações entre conceitos

| Relação | Descrição |
|---|---|
| Framework contém → Journey | O Framework define as 5 jornadas; journeys não existem fora do Framework |
| Execution Model aplica-se sobre → Journey | O modo (Upstream/Downstream) define como a Journey executa; não é a Journey |
| Journey contém → Cycle | Uma Journey tem um ou mais Cycles com natureza distinta |
| Cycle contém → Phase | Um Cycle é a sequência ordenada de suas Phases |
| Phase consome → Capability | Uma Phase invoca Capabilities para executar mecanismos reutilizáveis |
| Skill implementa → Phase | Uma Skill é a implementação executável de uma Phase (ou Cycle/Journey routing) |
| Skill contém → Step | Um Step é uma sub-unidade da Skill, invocável individualmente |
| Capability ≠ Skill | Capability é um mecanismo conceitual; Skill é comportamento executável de agente |
| Cycle ≠ Journey | Um Cycle agrupa Phases; não substitui nem representa a Journey |
| Step ≠ Phase | Step é implementação; Phase é conceito estrutural |

---

## Notas de distinção

### Upstream e Downstream não são jornadas

Upstream e Downstream são **modos de execução** — definem nível de compromisso e critérios de qualidade. Qualquer jornada pode operar em qualquer modo.

> Errado: "O item está no Upstream" como sinônimo de "está em Discovery".
> Correto: "O item está em Discovery, no modo Upstream."

### Ciclos vs. Agrupamentos

Na literatura de entrega de software, "CI Sync" e "CI Async" são chamados de "agrupamentos" em alguns documentos ProdOps anteriores. O termo canônico é **Cycle** (ciclo). Agrupamento é descrição informal; Cycle é o conceito formal.

### Capability não é hierarquicamente abaixo de Phase

A Capability é consumida pela Phase, mas não está "dentro" dela na hierarquia. É transversal — um mesmo mecanismo (ex: Evidence Management) é consumido por múltiplas fases em jornadas diferentes.

### OBC Partitioning é um processo, não uma Capability

`framework/README.md` referencia "OBC Partitioning" como "capability". Na ontologia ProdOps, OBC Partitioning é um **processo de governança** (responsabilidade do Portfolio PM + Tech Leads) executado entre Discovery no BIB e a criação de Local OBCs nos Product Backlogs. Não é uma Delivery Capability nem uma Diligence Capability. Ver [obc.md](obc.md).

---

## Fonte canônica

Este documento (`ontology.md`) é a fonte canônica da hierarquia de conceitos ProdOps.

| Documento | Papel em relação à ontologia |
|---|---|
| `glossary.md` | Definições lexicais completas dos termos — referencia esta ontologia para hierarquia |
| `operating-model.md` | Modelo operacional com fluxo de trabalho — referencia esta ontologia para conceitos |
| `execution-model/README.md` | Detalhamento de Upstream e Downstream — subconjunto desta ontologia |
| `journeys/*/README.md` | Detalhamento de cada jornada — referencia Cycle e Phase desta ontologia |
| `skills/README.md` | Catálogo de Skills — referencia esta ontologia para posicionamento de Skill e Step |
