# Relatório de Convergência Conceitual — ProdOps Framework
# Pré-implementação da Jornada de Diligence

> Gerado em: 2026-07-23  
> Escopo: toda a documentação sob `prodops/framework/`, `prodops/skills/`, `prodops/artifacts/`, `prodops/exec/`, `AGENTS.md` e `prodops/README.md`  
> Arquivos auditados: ~142  
> Status: **somente leitura — nenhum arquivo foi modificado**

---

# Executive Summary

A documentação do Framework está amplamente coerente nos documentos mais recentes e detalhados
(`glossary.md`, `ontology.md`, `knowledge-vs-execution.md`, `backlogs.md`,
`execution-mapping/`). No entanto, foram identificadas **19 divergências**, **5 ambiguidades**
e **4 lacunas** que comprometem a implementação consistente da Diligence.

O documento mais desatualizado do corpus é `prodops/framework/journeys/README.md`, que usa
vocabulário de uma versão anterior do Framework. O segundo conflito de maior impacto operacional
é o formato canônico de título de Work Item, que possui **três versões incompatíveis em
circulação simultânea**.

**Contagem:**

| Categoria | Total | Alta | Média | Baixa |
|---|---|---|---|---|
| Divergências | 19 | 4 | 10 | 5 |
| Ambiguidades | 5 | — | — | — |
| Lacunas | 4 | — | — | — |
| **Bloqueadores para Diligence** | **7** | — | — | — |

---

# Conceitos Consolidados

Os seguintes conceitos estão definidos de forma consistente e coerente entre todos os
documentos relevantes:

- **Knowledge Space vs. Execution Space**: princípio firmemente estabelecido em
  `knowledge-vs-execution.md`, `execution-mapping/README.md`, `matrix.md`,
  `work-item-schema.md`, `manifest.yaml` e skills de Diligence. Nenhum documento nega o
  princípio central ("Artefato nunca é um GitHub Issue").

- **OBC como documento Markdown (não Issue)**: consistente em `glossary.md`, `backlogs.md`,
  `artifact-governance.md`, `operating-model.md`, `execution-mapping/README.md`, `matrix.md`,
  `manifest.yaml`.

- **Upstream e Downstream são modos, não jornadas**: consistente em `ontology.md`,
  `glossary.md`, `flow.md`, `execution-model/README.md`, `journeys/delivery/README.md`,
  `journeys/discovery/README.md`.

- **As 5 jornadas (Discovery, Delivery, Operation, Assessment, Diligence)**: nomeação
  consistente em `ontology.md`, `glossary.md`, `operating-model.md`, `journeys/README.md`.

- **Ciclos da Diligence (diligence-sync, diligence-async)**: consistentes entre
  `diligence/README.md`, `diligence-sync.md`, `diligence-async.md` e respectivos `SKILL.md`.

- **Fases dos ciclos**: Capture → Attach → Promote → Close; Scan → Flag → Repair;
  Inspect → Reconcile → Verify — coerentes entre framework e skills.

- **OBC states**: Draft → Refining → Committed → In Delivery → Operational → Archived:
  consistente em todos os documentos.

- **GitHub Projects como Execution Space**: consistente em `manifest.yaml`,
  `operating-model.md`, `knowledge-vs-execution.md`.

- **Reliability Plan como gate condicional** (não universal): consistente em `backlogs.md`,
  `flow.md`, `AGENTS.md`, `downstream/SKILL.md`, steps de promote.

- **Iteration Plan como registro de execução** (não backlog de planejamento): consistente em
  `glossary.md`, `backlogs.md`, `artifact-governance.md`.

- **Cardinalidade N:M entre artefatos e Work Items**: consistente em
  `knowledge-vs-execution.md`, `execution-mapping/README.md`, `matrix.md`.

- **Skill implementa Journey/Cycle/Phase — não é conceito estrutural do Framework**:
  consistente em `ontology.md`, `glossary.md`, `skills/README.md`.

---

# Divergências Encontradas

## D-001: Workspace Reconciliation — Capability ou Cycle?

- **Documentos:** `prodops/framework/ontology.md`, `prodops/framework/journeys/diligence/workspace-reconciliation.md`, `prodops/skills/diligence/workspace-reconciliation/SKILL.md`, `prodops/framework/journeys/diligence/README.md`
- **Trecho:**
  - `ontology.md` (tabela de ciclos): `"| Diligence | workspace-reconciliation | Por demanda — Inspect → Reconcile → Verify |"` — lista como **Cycle**.
  - `workspace-reconciliation.md`: `"Workspace Reconciliation é uma **capability** (não um ciclo) do ProdOps Diligence."` — declara explicitamente que **não é ciclo**.
  - `workspace-reconciliation/SKILL.md`: `"Workspace Reconciliation é uma **capability**, não um ciclo. É invocada por Bootstrap, Diligence Async e Diligence Sync como sub-rotina."` — reafirma como capability.
  - `diligence/README.md`: na seção "Ciclos" lista workspace-reconciliation como ciclo; na seção "Capabilities" lista como capability. O mesmo documento classifica o conceito nas duas categorias simultaneamente.
- **Conceito:** Cycle vs. Capability; hierarquia conceitual (ontology)
- **Descrição:** O documento canônico da hierarquia (`ontology.md`) lista workspace-reconciliation como Cycle. Os documentos de especificação o definem explicitamente como Capability. `diligence/README.md` usa os dois termos para o mesmo conceito no mesmo arquivo.
- **Impacto:** Agentes que lerem `ontology.md` tratarão workspace-reconciliation como ciclo com acionamento próprio; agentes que lerem `workspace-reconciliation.md` ou o SKILL.md saberão que é sub-rotina invocável. A implementação da Diligence não pode ser consistente se a classificação fundamental varia por documento.
- **Gravidade:** Alta
- **Recomendação:** Adotar `workspace-reconciliation.md` e `SKILL.md` como referência canônica: workspace-reconciliation é uma **Capability** do Diligence. Atualizar `ontology.md` para remover workspace-reconciliation da tabela de Cycles. Atualizar `diligence/README.md` para listar apenas diligence-sync e diligence-async como ciclos, e workspace-reconciliation apenas na seção de Capabilities.

---

## D-002: Formato Canônico de Título de Work Item — Três Padrões Incompatíveis

- **Documentos:** `AGENTS.md`, `prodops/framework/journeys/diligence/diligence-sync.md`, `prodops/framework/execution-mapping/work-item-schema.md`, `prodops/skills/diligence/SKILL.md`, `prodops/skills/downstream/SKILL.md`, `prodops/skills/diligence/diligence-sync/steps/attach/SKILL.md`
- **Trecho:**
  - `AGENTS.md`: `"Usar o padrão de título: [Operation] — [Artifact Type] [Artifact ID]: descrição"`
  - `diligence-sync.md`: `"Título canônico: [Operation] — [Artifact Type] [Artifact ID]: descrição concisa"` / exemplo: `"Promote — Local OBC observability-datadog: avançar para Iteration Plan"`
  - `work-item-schema.md`: `"[Artifact ID]: descrição concisa"` — sem prefixo de operação
  - `diligence/SKILL.md` (guardrails): `"Usar sempre o padrão canônico de título de Work Item: [Artifact ID]: descrição."`
  - `downstream/SKILL.md` (guardrails): `"Use the canonical Work Item title pattern: [Artifact ID]: description."`
  - `attach/SKILL.md` exemplo: `"observability-datadog: avançar para Iteration Plan"` — sem prefixo
- **Conceito:** Work Item schema; padrão de nomenclatura de GitHub Issues
- **Descrição:** Três padrões incompatíveis: (1) `[Operation] — [Artifact Type] [Artifact ID]: descrição` (AGENTS.md, diligence-sync.md); (2) `[Artifact ID]: descrição` (work-item-schema.md, diligence/SKILL.md, downstream/SKILL.md, attach/SKILL.md). O `scan/SKILL.md` detecta títulos no padrão `[Operation] —` como divergências a reparar, enquanto `AGENTS.md` instrui agentes a usar exatamente esse padrão.
- **Impacto:** A Diligence vai reparar Issues criados pela própria Diligence, gerando loops de reparo inconsistentes.
- **Gravidade:** Alta
- **Recomendação:** Adotar `work-item-schema.md` como fonte de verdade. Padrão oficial: `[Artifact ID]: descrição concisa`. Atualizar `AGENTS.md` e `diligence-sync.md` para usar este padrão. O padrão com prefixo `[Operation] —` é descrito no `scan/SKILL.md` como "padrão antigo" — confirmar e remover de todos os documentos normativos.

---

## D-003: "Business Signal Issue" — Conceito Canônico vs. Anti-Padrão Explícito

- **Documentos:** `prodops/framework/glossary.md`, `prodops/framework/knowledge-vs-execution.md`
- **Trecho:**
  - `glossary.md`: Define `"Business Signal Issue: GitHub Issue que representa um Business Signal."` e `"Business Intent Issue: GitHub Issue que representa uma Business Intent."` como entradas canônicas.
  - `knowledge-vs-execution.md` (Seção "Incorreto"): `"❌ 'Business Signal Issue' como tipo canônico de Issue (o tipo nomeia o artefato, não a operação)"` e `"❌ 'A Business Intent Issue #42' (Nomeia a Issue pelo artefato, estabelecendo 1:1)"`
- **Conceito:** Nomenclatura de Work Items; relação artefato-Issue
- **Descrição:** `glossary.md` define "Business Signal Issue" e "Business Intent Issue" como termos canônicos. `knowledge-vs-execution.md` lista os mesmos padrões como erros a evitar. Os dois documentos são diretamente contraditórios.
- **Impacto:** O Scan verifica conformidade de Issues — mas o critério de conformidade depende de qual documento prevalece. Agentes diferentes vão gerar e avaliar Issues de formas incompatíveis.
- **Gravidade:** Alta
- **Recomendação:** Eliminar "Business Signal Issue" e "Business Intent Issue" do `glossary.md`. Substituir por "Business Signal Work Item" e "Business Intent Work Item", alinhando com `backlogs.md` e `operating-model.md`. `knowledge-vs-execution.md` é o documento mais recente e conceitualmente consistente — deve prevalecer.

---

## D-004: Terminologia Obsoleta em journeys/README.md

- **Documentos:** `prodops/framework/journeys/README.md`, `prodops/framework/backlogs.md`, `prodops/framework/glossary.md`
- **Trecho:**
  - `journeys/README.md` usa: `"Repository Tracking List / Global Tracking List"`, `"Product Intent Backlog"` — termos que não existem no glossário canônico.
  - Atribui `"Product Intent Backlog"` à Diligence como responsável — mas docs canônicos dizem que o Product Backlog é gerenciado pelo Product Owner; a Diligence sincroniza, não gerencia.
  - `backlogs.md`, `glossary.md`, `artifact-governance.md`: usam "Portfolio Tracking List", "Product Tracking List", "Product Backlog" de forma consistente.
- **Conceito:** Nomenclatura de backlogs; responsabilidade por backlog
- **Descrição:** `journeys/README.md` usa três termos que não existem no vocabulário canônico e atribui responsabilidade de gerenciamento de backlog incorretamente à Diligence. O arquivo é uma versão anterior do Framework, anterior à padronização de vocabulário.
- **Impacto:** Agentes que lerem este arquivo não encontrarão os artefatos canônicos pelo nome correto. Confusão sistemática de vocabulário.
- **Gravidade:** Alta
- **Recomendação:** Reescrever `journeys/README.md` usando vocabulário canônico: substituir "Repository Tracking List / Global Tracking List" por "Portfolio Tracking List / Product Tracking List"; substituir "Product Intent Backlog" por "Product Backlog"; corrigir a tabela para atribuir gerenciamento do Product Backlog ao Product Owner.

---

## D-005: Business Signal Exige GitHub Issue 1:1 (Skills) vs. Modelo N:M (Canônico)

- **Documentos:** `prodops/skills/diligence/diligence-sync/steps/capture/SKILL.md`, `prodops/skills/diligence/diligence-async/steps/scan/SKILL.md`, `prodops/framework/knowledge-vs-execution.md`
- **Trecho:**
  - `capture/SKILL.md`: `"Business Signals exigem um GitHub Issue correspondente (Business Signal Issue). O ciclo diligence-sync não está completo para um Business Signal sem o Issue criado."` — implica 1:1 obrigatório.
  - `scan/SKILL.md`: classifica como divergência quando `"Issue == '—' ou ausente → divergência: Business Signal sem GitHub Issue"` — trata ausência como erro.
  - `knowledge-vs-execution.md`: `"não se deve criar um Work Item por artefato"` e `"❌ 'Criar Issue para o Business Signal' (o Signal é um artefato — a Issue representa trabalho SOBRE ele)"`
- **Conceito:** Cardinalidade artefato-Work Item; Business Signal
- **Descrição:** As skills de Diligence tratam a existência de Issue como obrigatória para todo Business Signal na tracking list. O modelo canônico diz explicitamente que não se deve criar Work Items por artefato e cita exatamente esse padrão como erro.
- **Impacto:** A Diligence vai criar Issues para Business Signals passivos (sem trabalho ativo em andamento) e classificar ausência como divergência, criando ruído e violando o princípio N:M do modelo.
- **Gravidade:** Alta
- **Recomendação:** Revisar `capture/SKILL.md` e `scan/SKILL.md` para alinhar com o modelo N:M. A Scan deve verificar se existe Work Item apenas quando há trabalho identificado em andamento sobre o Signal. Reformular: de "Business Signal sem Issue" para "Business Signal com operação ativa sem Work Item correspondente".

---

## D-006: OBC Partitioning — Capability ou Processo de Governança?

- **Documentos:** `prodops/framework/ontology.md`, `prodops/framework/obc.md`, `prodops/framework/backlogs.md`, `prodops/framework/glossary.md`
- **Trecho:**
  - `ontology.md`: `"OBC Partitioning não é uma Capability. Na ontologia ProdOps, OBC Partitioning é um **processo de governança**. Não é uma Framework Capability nem uma Product Capability."`
  - `obc.md`: `"O **Particionamento do OBC** é a capability responsável por transformar um Global OBC em Local OBCs."`
  - `backlogs.md`: `"**O que é:** Capability responsável por transformar o Global OBC em Local OBCs"`
  - `glossary.md`: `"**Definição:** Capability responsável por transformar um Global OBC em Local OBCs"`
- **Conceito:** OBC Partitioning; classificação como Capability ou Processo de Governança
- **Descrição:** `ontology.md` afirma explicitamente que OBC Partitioning NÃO é Capability; `obc.md`, `backlogs.md` e `glossary.md` a chamam de "Capability". `ontology.md` inclusive menciona a inconsistência sem resolvê-la nos outros documentos.
- **Impacto:** Confusão sobre quando invocar OBC Partitioning e quem é responsável.
- **Gravidade:** Média
- **Recomendação:** Adotar `ontology.md` como referência. Atualizar `obc.md`, `backlogs.md` e `glossary.md` para usar "processo de governança" em vez de "capability".

---

## D-007: Icebox — Critério de Entrada: Draft ou Refining?

- **Documentos:** `prodops/framework/artifact-governance.md`, `prodops/framework/backlogs.md`, `prodops/framework/glossary.md`
- **Trecho:**
  - `artifact-governance.md` (Icebox — Critério de entrada): `"Item no Product Backlog com Local OBC em estado **Draft**"`
  - `backlogs.md` (Icebox): `"O estado do Local OBC é **Refining**."`
  - `backlogs.md` (transição): `"Quando o Discovery ativo começa, transiciona para **Refining** e passa a ser representado na VIEW Icebox."`
  - `glossary.md` (Icebox): `"Estado do Local OBC: Refining."`
- **Conceito:** Ciclo de vida do OBC; estado no Icebox
- **Descrição:** `artifact-governance.md` diz que o OBC entra no Icebox em estado "Draft". `backlogs.md` e `glossary.md` dizem que o OBC está em "Refining" quando está no Icebox.
- **Impacto:** O step Promote da Diligence verifica pré-requisitos de transição — critério errado pode mover itens incorretamente.
- **Gravidade:** Média
- **Recomendação:** Corrigir `artifact-governance.md`: o critério de entrada no Icebox é "Local OBC transicionando de Draft para **Refining** — início do Discovery ativo", alinhando com `backlogs.md` e `glossary.md`.

---

## D-008: Iteration Backlog — BDD Draft Exigido ou Não?

- **Documentos:** `prodops/framework/artifact-governance.md`, `prodops/framework/backlogs.md`
- **Trecho:**
  - `artifact-governance.md` (Iteration Backlog — Critério de entrada): `"OBC Committed + BDD Feature **draft**"`
  - `backlogs.md` (Iteration Backlog — Critérios): `"Local OBC no estado Committed, Discovery funcional, técnico e operacional suficiente, Riscos identificados"` — sem mencionar BDD Feature.
  - `backlogs.md` (Iteration Plan — Critérios): `"Local OBC committed + BDD Feature committed"` — BDD committed só é exigido no Plan.
- **Conceito:** Critérios de transição no backlog; estado da BDD Feature
- **Descrição:** `artifact-governance.md` exige BDD Feature draft para entrar no Iteration Backlog. `backlogs.md` não exige BDD para o Iteration Backlog — apenas para o Iteration Plan.
- **Impacto:** O step Promote da Diligence pode bloquear itens legítimos no Iteration Backlog por critério inconsistente.
- **Gravidade:** Média
- **Recomendação:** Adotar `backlogs.md` como referência. Corrigir `artifact-governance.md` para remover "BDD Feature draft" do critério de Iteration Backlog. BDD committed é requisito do Iteration Plan — não do Backlog.

---

## D-009: delivery/README.md — Reliability Plan como Gate Universal

- **Documentos:** `prodops/framework/journeys/delivery/README.md`, `prodops/framework/backlogs.md`, `AGENTS.md`, `prodops/skills/downstream/SKILL.md`
- **Trecho:**
  - `delivery/README.md`: `"Um item só entra no Iteration Plan quando possui OBC committed + BDD Feature committed + riscos documentados + **Reliability Plan**."` — sem condicional.
  - `backlogs.md`: `"Entrada no Reliability Plan quando **aplicável**: movimentação financeira, integração externa, mudança de SLO, risco alto/crítico, alteração de persistência ou segurança"`
  - `AGENTS.md`: `"Reliability Plan é gate **quando** houver movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência ou segurança."` — condicional explícito.
  - `downstream/SKILL.md`: condicional explícito.
- **Conceito:** Gates de Iteration Plan; Reliability Plan
- **Descrição:** `delivery/README.md` apresenta o Reliability Plan como gate universal e incondicional. Todos os outros documentos o definem como gate condicional.
- **Impacto:** Um agente que leia `delivery/README.md` bloqueará toda entrega que não tiver Reliability Plan, mesmo quando nenhum gatilho de risco está presente. Paralisa entregas legítimas.
- **Gravidade:** Média
- **Recomendação:** Corrigir `delivery/README.md`: adicionar a cláusula condicional — "Reliability Plan produzido pelo Assessment **quando houver** movimentação financeira, integração externa, mudança de SLO, risco alto/crítico, alteração de persistência ou segurança."

---

## D-010: Product Backlog "Contém" — Business Intents vs. OBCs

- **Documentos:** `prodops/framework/glossary.md`, `prodops/framework/backlogs.md`, `prodops/framework/artifact-governance.md`
- **Trecho:**
  - `glossary.md` (Product Backlog): `"Contém exclusivamente **OBCs (Local OBCs)** — nunca Business Signals, nunca Business Intents, nunca Global OBCs."`
  - `backlogs.md`: `"Contém exclusivamente: Business Intents. Cada Intent possui um Local OBC como documento de contrato."`
  - `artifact-governance.md`: `"Contém: APENAS Business Intents (cada Intent possui um Local OBC como documento de contrato)"`
- **Conceito:** Conteúdo do Product Backlog; entidade principal do backlog
- **Descrição:** `glossary.md` diz que o Product Backlog contém "OBCs (Local OBCs)". `backlogs.md` e `artifact-governance.md` dizem que contém "Business Intents" (com OBCs como documentos de contrato associados).
- **Impacto:** Afeta como agentes interpretam o que referenciar em Work Items: o OBC ou a Business Intent.
- **Gravidade:** Média
- **Recomendação:** Adotar `backlogs.md` como referência. Corrigir `glossary.md`: o Product Backlog contém **Business Intents**, cada uma com um Local OBC associado como documento de contrato. O OBC não "está" no backlog — representa a Intent.

---

## D-011: Responsabilidade da Diligence — "aderência" vs. "consistência"

- **Documentos:** `prodops/framework/journeys/README.md`, `prodops/framework/glossary.md`, `prodops/framework/ontology.md`, `prodops/framework/journeys/diligence/README.md`
- **Trecho:**
  - `journeys/README.md`: `"[Diligence] Garantir aderência ao modelo operacional"`
  - `glossary.md`, `ontology.md`, `diligence/README.md`: `"Garantir consistência do sistema de trabalho"`
- **Conceito:** Responsabilidade da jornada Diligence
- **Descrição:** 1 documento usa "aderência ao modelo operacional"; 3 documentos usam "consistência do sistema de trabalho". Formulações distintas com implicações operacionais diferentes.
- **Impacto:** Menor conflito conceitual — reforça que `journeys/README.md` está desatualizado.
- **Gravidade:** Baixa
- **Recomendação:** Corrigir `journeys/README.md` para usar "Garantir consistência do sistema de trabalho".

---

## D-012: diligence/README.md — Workspace Reconciliation Classificada como Ciclo E Capability no Mesmo Arquivo

- **Documento:** `prodops/framework/journeys/diligence/README.md`
- **Trecho:**
  - Seção "Ciclos": `"| Diligence | workspace-reconciliation | Por demanda — Inspect → Reconcile → Verify |"` — lista como ciclo.
  - Seção "Capabilities": `"| [Workspace Reconciliation](workspace-reconciliation.md) | Alinhar GitHub Workspace... | Bootstrap, Diligence Async, Diligence Sync |"` — lista como capability.
- **Conceito:** workspace-reconciliation; Cycle vs. Capability
- **Descrição:** O mesmo documento apresenta workspace-reconciliation como Cycle (na seção de Ciclos) e como Capability (na seção de Capabilities). Internamente inconsistente, além de conflitar com `ontology.md` (D-001).
- **Impacto:** Leitores do `diligence/README.md` não conseguem determinar se workspace-reconciliation deve ser tratado como ciclo ou capability.
- **Gravidade:** Média
- **Recomendação:** Corrigir `diligence/README.md`: remover workspace-reconciliation da seção "Ciclos". Manter apenas na seção "Capabilities" com nota explicando que é invocada pelos ciclos e pelo Bootstrap.

---

## D-013: "Readiness Verification" — Capability Ausente da Ontologia

- **Documentos:** `prodops/framework/journeys/diligence/capabilities/README.md`, `prodops/framework/ontology.md`
- **Trecho:**
  - `capabilities/README.md`: lista 6 capabilities incluindo `"Readiness Verification | Verificar pré-requisitos de Downstream antes que um item entre em Delivery | Promote, Scan"`
  - `ontology.md` (Área Diligence): `"Backlog Synchronization, Work Item Management, Divergence Detection, Artifact Evolution, Workspace Reconciliation"` — sem Readiness Verification.
- **Conceito:** Capabilities da Diligence; catálogo de capabilities
- **Descrição:** `capabilities/README.md` lista "Readiness Verification" como capability da Diligence. `ontology.md` não a inclui.
- **Impacto:** Inconsistência no catálogo de capabilities.
- **Gravidade:** Baixa
- **Recomendação:** Adicionar "Readiness Verification" à lista de Diligence Capabilities em `ontology.md`.

---

## D-014: flow.md — "Business Signal Issue" como Output Direto

- **Documentos:** `prodops/framework/flow.md`, `prodops/framework/knowledge-vs-execution.md`
- **Trecho:**
  - `flow.md` Step 2, "O que é produzido": `"Business Signal Issue (GitHub: Portfolio GitHub Project)"` — trata a Issue como representação do Signal.
  - `knowledge-vs-execution.md` (Incorreto): `"❌ 'Criar Issue para o Business Signal' (o Signal é um artefato — a Issue representa trabalho SOBRE ele)"`
- **Conceito:** Business Signal; representação no GitHub; modelo artefato-Issue
- **Descrição:** `flow.md` apresenta "Business Signal Issue" como output direto do registro de um Business Signal. `knowledge-vs-execution.md` diz que criar Issue "para" um Business Signal é um erro de modelo. Reforça o padrão 1:1 que o modelo N:M rejeita.
- **Impacto:** Agentes que seguirem `flow.md` criarão Issues para Business Signals passivos — comportamento rejeitado pelo modelo canônico.
- **Gravidade:** Média
- **Recomendação:** Corrigir `flow.md` Step 2: remover "Business Signal Issue" da lista de outputs. O output do registro de um Business Signal é o registro no arquivo `tracking-list.md`. Uma Issue só é criada quando há trabalho ativo (operação Capture) em andamento.

---

## D-015: Link Quebrado em workspace-reconciliation.md

- **Documento:** `prodops/framework/journeys/diligence/workspace-reconciliation.md`
- **Trecho:** `"→ [Capabilities README](../../README.md)"` — aponta para `journeys/diligence/README.md`, não para `capabilities/README.md`.
- **Conceito:** Navegação interna
- **Descrição:** Link incorreto em documento de especificação de capability.
- **Impacto:** Navegação quebrada.
- **Gravidade:** Baixa
- **Recomendação:** Corrigir: `"→ [Capabilities README](capabilities/README.md)"`.

---

## D-016: Capture/SKILL.md — "Criar OBC se não existe" vs. Guardrail "Nunca inventar OBCs"

- **Documentos:** `prodops/skills/diligence/diligence-sync/steps/capture/SKILL.md`, `prodops/skills/diligence/SKILL.md`
- **Trecho:**
  - `capture/SKILL.md` (Ação 2): `"Se o OBC não existe: Criar o arquivo seguindo o template disponível... Preencher: identificador, Business Intent de origem, estado inicial, decisão registrada."`
  - `diligence/SKILL.md` (Guardrails): `"Nunca inventar OBCs, BDD Features ou riscos — apenas sincronizar o que já existe."`
- **Conceito:** Escopo da Diligence; criação de artefatos
- **Descrição:** O guardrail global do Diligence proíbe inventar OBCs. O step Capture instrui a criar um OBC novo se ele não existir. A criação de um OBC ausente pelo Capture não é "sincronização do que já existe".
- **Impacto:** Agente fica em conflito: deve criar o OBC ausente (como Capture diz) ou bloquear por ser "invenção"?
- **Gravidade:** Média
- **Recomendação:** Esclarecer o guardrail global: "Nunca inventar OBCs sem um gatilho canônico documentado — Capture pode criar um OBC apenas quando há experimento concluído, decisão de Assessment ou sinal de Operation como gatilho explícito." Ou reformular o Capture para deixar claro que ele "registra" uma decisão já tomada — não "inventa".

---

## D-017: diligence-sync.md — Título Canônico Diferente do work-item-schema.md

*Ver D-002 — variante específica deste documento.*

---

## D-018: AGENTS.md — Formato de Título Diferente do work-item-schema.md

*Ver D-002 — variante específica deste documento.*

---

## D-019: delivery/README.md — Reliability Plan como Gate Universal (Variante Iteration Plan)

*Ver D-009 — coberto no mesmo documento.*

---

# Ambiguidades

## A-001: "Exploration" — Etapa do Fluxo ou Atividade Contínua?

O termo "Exploration" é introduzido em `glossary.md`, `flow.md` e `ontology.md` como a "etapa entre Business Intent e OBC Committed". Mas o Discovery pode acontecer durante a Operation (Refinamento Contínuo do OBC). Não está claro se "Exploration" se aplica apenas ao período Icebox ou também durante Operation. Os documentos não resolvem essa ambiguidade explicitamente.

## A-002: Quando a Diligence "sincroniza" vs. quando "cria"?

Os princípios da Diligence dizem "sincronizar, não implementar". Mas `capture/SKILL.md` cria artefatos, `attach/SKILL.md` cria Issues, `promote/SKILL.md` cria entradas no Iteration Plan. A linha entre "sincronizar" e "criar" não está claramente definida nos documentos de princípio — criando risco de interpretação excessivamente restritiva ou excessivamente permissiva do escopo da Diligence.

## A-003: GitHub Issue como "representação operacional" de uma Business Intent

`glossary.md` define "Business Intent Issue: GitHub Issue que representa uma Business Intent — decisão estratégica de perseguir valor." `knowledge-vs-execution.md` diz que Issues representam **trabalho sobre** artefatos, não os artefatos em si. É possível ler os dois documentos de forma compatível (uma Issue representa a operação Explore sobre uma Intent), mas a formulação do glossary.md sugere identidade, não operação.

## A-004: "Diligence sincroniza as decisões do Assessment" — o que significa sincronizar uma decisão?

`diligence/README.md` afirma: "A Diligence sincroniza as decisões do Assessment nos backlogs." Não está especificado se isso significa: (a) criar Work Items para rastrear a implementação das decisões, (b) atualizar os estados dos OBCs com base nas decisões, ou (c) ambos. Os steps de Capture e Promote sugerem (b), mas Attach sugere (a).

## A-005: Promoção de Upstream — Pula o Icebox?

`glossary.md` (Product Backlog) afirma: "Um item promovido de Upstream que satisfaz os critérios do estado Committed pula o refinamento no Icebox e aparece na VIEW Iteration Backlog." Isso significa que o OBC pode ir de Draft diretamente para Committed sem passar por Refining? Não existe documentação explícita dos estados intermediários válidos quando um item é promovido de Upstream.

---

# Lacunas

## L-001: Protocolo de Transição de Modo (Upstream → Downstream) Não Documentado

Todos os documentos mencionam que a mudança de modo requer "decisão explícita". Nenhum documento especifica quem documenta essa decisão, onde é registrada, qual artefato é atualizado e qual é o critério mínimo para que a transição seja considerada "explícita".

## L-002: Diligence Não Tem Protocolo para Business Intents Sem OBC Associado

Os ciclos da Diligence assumem que toda Business Intent tem um Local OBC. Não existe guidance sobre o que fazer quando uma Business Intent existe no Product Backlog mas ainda não tem OBC criado (estado pré-Draft). Os critérios de Scan, Capture e Attach são definidos em termos de OBC.

## L-003: Ciclo de Vida do Work Item nas Transições Intermediárias do OBC Não Documentado

Existe documentação sobre o ciclo de vida do OBC (Draft → Archived) e sobre o ciclo de vida do Work Item no GitHub (Open → Done). Mas não existe mapeamento explícito do que deve acontecer ao Work Item quando o OBC transiciona entre estados específicos — exceto para o estado Operational (Close). Os estados intermediários (Committed → In Delivery) não têm protocolo de atualização de Work Item documentado.

## L-004: Steps Individuais do Workspace Reconciliation Não Documentam Nível de Automação

`workspace-reconciliation.md` e o SKILL.md mencionam "Automation First (Princípio 8)" e a cadeia API → MCP → CLI → SDK → Browser Automation. Mas os steps individuais (inspect, reconcile, verify) não documentam quais ações específicas seguem qual nível de automação — deixando para o agente inferir caso a caso.

---

# Recomendações

## Alta Prioridade (Bloqueadores)

1. **[D-002]** Consolidar o formato de título de Work Item. Definir `work-item-schema.md` como fonte única e atualizar `AGENTS.md` e `diligence-sync.md` para usar `[Artifact ID]: descrição`. Esta é a divergência de maior impacto operacional — a Scan vai reparar Issues criados pela própria Diligence.

2. **[D-001 + D-012]** Reclassificar workspace-reconciliation como Capability em `ontology.md` e `diligence/README.md`. Remove ambiguidade fundamental sobre o tipo de conceito, que afeta como as skills orquestram workspace-reconciliation.

3. **[D-005]** Revisar a lógica de verificação de Business Signal no Scan. Substituir a regra "Business Signal sem Issue = divergência" por "Business Signal com operação ativa sem Work Item = divergência". Impede a criação de ruído operacional e conflito com o modelo N:M.

4. **[D-004]** Reescrever `journeys/README.md` com vocabulário canônico (Portfolio Tracking List, Product Tracking List, Product Backlog). Arquivo sistematicamente desatualizado.

5. **[D-003]** Resolver o conflito "Business Signal Issue" no `glossary.md`. Remover ou reformular as entradas "Business Signal Issue" e "Business Intent Issue" para alinhar com o princípio de nomenclatura por operação de `knowledge-vs-execution.md`.

## Média Prioridade

6. **[D-016]** Clarificar o guardrail "Nunca inventar OBCs" vs. Capture que cria OBCs. Edição simples no guardrail global da Diligence para esclarecer que Capture cria com base em gatilho canônico.

7. **[D-007]** Corrigir `artifact-governance.md` — critério de entrada do Icebox: Draft → Refining.

8. **[D-008]** Corrigir `artifact-governance.md` — critério de entrada do Iteration Backlog: remover "BDD Feature draft".

9. **[D-009]** Corrigir `delivery/README.md` — Reliability Plan como gate condicional: adicionar cláusula condicional ausente.

10. **[D-010]** Corrigir `glossary.md` — Product Backlog contém Business Intents (não OBCs diretamente).

11. **[D-014]** Corrigir `flow.md` Step 2 — remover "Business Signal Issue" da lista de outputs.

12. **[D-006]** Rever a declaração do OBC Partitioning como "Capability" em `obc.md`, `backlogs.md` e `glossary.md` para "processo de governança".

13. **[D-012]** Corrigir `diligence/README.md` — remover workspace-reconciliation da seção "Ciclos".

## Baixa Prioridade

14. **[D-011]** Corrigir `journeys/README.md` — responsabilidade da Diligence: "aderência" → "consistência do sistema de trabalho".

15. **[D-013]** Adicionar "Readiness Verification" ao catálogo de Capabilities em `ontology.md`.

16. **[D-015]** Corrigir link quebrado em `workspace-reconciliation.md`.

---

# Bloqueadores para Implementação da Diligence

Os seguintes problemas **devem ser resolvidos** antes de que a implementação da Diligence possa produzir comportamento consistente e correto:

| # | Divergência | Risco se não resolvido |
|---|---|---|
| B-1 | **[D-002]** Formato de título de Work Item ambíguo (3 padrões) | Scan repara Issues criados pela própria Diligence — loops de reparo inconsistentes |
| B-2 | **[D-001]** workspace-reconciliation classificado como Cycle e Capability simultaneamente | Orquestradores invocam como ciclo independente ou como capability — comportamentos incompatíveis |
| B-3 | **[D-005]** Scan classifica ausência de Issue como divergência para todos os Business Signals | Criação de Issues espúrios para Signals passivos — polui o GitHub Project |
| B-4 | **[D-012]** `diligence/README.md` lista workspace-reconciliation como Cycle na seção "Ciclos" | Agentes que usam este arquivo como referência tentam acioná-lo como ciclo independente |
| B-5 | **[D-004]** `journeys/README.md` usa vocabulário obsoleto (Product Intent Backlog, Repository Tracking List) | Agentes não encontrarão os artefatos canônicos pelo nome correto |
| B-6 | **[L-003]** Falta protocolo para atualização de Work Items em transições intermediárias do OBC | Diligence sabe criar (Attach) e fechar (Close) Work Items — mas não o que fazer em Committed → In Delivery |
| B-7 | **[D-003]** Conflito "Business Signal Issue" vs. anti-padrão | Critério de conformidade de Issues ambíguo — Scan não sabe o que validar |

---

# Conceitos Canônicos Propostos

## "Business Signal Issue" / "Business Intent Issue"

**Proposta:** Eliminar estes termos do glossário como tipos nomeados. Substituir por
**"Business Signal Work Item"** e **"Business Intent Work Item"**.

**Justificativa:** `knowledge-vs-execution.md` é o documento mais recente e conceitualmente
consistente sobre o modelo de relação artefato-Issue. O princípio de nomenclatura por operação
(em vez de por artefato) é mais robusto e alinhado com o modelo N:M. A formulação pelo artefato
implica identidade 1:1, que o Framework rejeita explicitamente.

---

## Workspace Reconciliation

**Proposta:** workspace-reconciliation é uma **Capability** do Diligence — invocável por
Bootstrap, Diligence Async e Diligence Sync como sub-rotina de correção de infraestrutura. Não é
um Cycle.

**Justificativa:** `workspace-reconciliation.md` e o SKILL.md são os documentos de especificação
dedicados; são coerentes entre si; a classificação como Capability é conceitualmente correta —
pode ser consumida por múltiplos pontos do Framework sem pertencer exclusivamente a nenhum Cycle.

---

## Formato de Título de Work Item

**Proposta:** `[Artifact ID]: descrição concisa`

**Justificativa:** `work-item-schema.md` é o documento de schema canônico (referenciado em
`manifest.yaml` como fonte de verdade). O padrão com prefixo `[Operation] —` é descrito em
`scan/SKILL.md` como "padrão antigo" a ser reparado — o que confirma que foi supersedido.

---

## OBC Partitioning

**Proposta:** OBC Partitioning é um **processo de governança**, não uma Capability.

**Justificativa:** `ontology.md` é explicitamente a "fonte única de verdade da hierarquia de
conceitos" e rejeita a classificação como Capability. A distinção importa: Capabilities são
mecanismos reutilizáveis de processo; OBC Partitioning é atividade pontual de responsabilidade
humana (Portfolio PM + Tech Leads).

---

## Product Backlog — Entidade Principal

**Proposta:** O Product Backlog contém **Business Intents** — cada uma representada por um Local
OBC como documento de contrato.

**Justificativa:** `backlogs.md` e `artifact-governance.md` são os documentos especializados para
o tema; ambos dizem "Business Intents". O OBC é um documento vivo que acompanha a Intent — não o
item do backlog em si.

---

## Diligence — Responsabilidade

**Proposta:** "Garantir consistência do sistema de trabalho do ProdOps"

**Justificativa:** 3 documentos usam esta formulação (`glossary.md`, `ontology.md`,
`diligence/README.md`) vs. 1 documento desatualizado (`journeys/README.md`). "Consistência do
sistema de trabalho" é operacionalmente mais preciso do que "aderência ao modelo operacional".

---

## Business Signal — Deve ter GitHub Issue?

**Proposta:** Um Business Signal **pode** ter zero ou mais Work Items ao longo de sua vida. A
ausência de Issue não é uma divergência. Uma Issue é criada quando há uma **operação ativa**
(Capture, Review, Promote) sendo executada sobre o Signal.

**Justificativa:** `knowledge-vs-execution.md` estabelece o modelo N:M como princípio; é o
documento mais recente e conceitualmente correto; a regra 1:1 implícita nas skills de Diligence é
inconsistente com este modelo e produzirá ruído operacional em produção.
