# Representação Operacional da Delivery — Proposta Arquitetural
# ProdOps Framework — Diligence × Delivery

> Data: 2026-07-24
> Tipo: Proposta arquitetural — somente leitura e proposta
> Status: RASCUNHO — aguardando revisão e aprovação
> Escopo: Jornada Delivery (entrada no Iteration Plan → promoção para produção)
> Autor: Proposta gerada a partir de leitura profunda do Framework ProdOps

---

## 1. Executive Summary

A Jornada Delivery possui estrutura de fases bem definida (CI Sync: Bootstrap → Hack → Sync → Finish; CI Async: Ship → Validate → Promote) e quality gates verificáveis por artefato. Entretanto, a representação operacional dessa jornada no GitHub é atualmente **implícita**: não existe modelo de estados formais para Work Items de Delivery, nenhum GitHub Project `ProdOps — Delivery` declarado, e o catálogo de Checks da Diligence possui cobertura mínima sobre a Jornada Delivery (apenas DIL-RDY-001 e DIL-RDY-002, ambos focados em gates de entrada e promoção, não em observabilidade do fluxo).

Este documento propõe:

1. Um modelo de estados operacionais para itens em Delivery, com BLOCKED e WAITING como conceitos de primeira classe.
2. A estrutura do GitHub Project `ProdOps — Delivery` (Fields, Labels, Views) com separação clara entre Knowledge Space e Execution Space.
3. Uma camada de observabilidade do fluxo derivável inteiramente do GitHub state.
4. Critérios precisos para abertura automática de Work Items pela Diligence na Jornada Delivery.
5. A interface entre Delivery e Assessment via sinais de Diligence.
6. Um catálogo inicial de 18 métricas deriváveis do Execution Space.

**Decisões imutáveis respeitadas:** Diligence não conduz Delivery. GitHub Projects/Issues = COR. Princípios de knowledge-vs-execution.md são fonte de verdade. Não há sexta jornada. A proposta não cria Skills, Skills Steps, altera manifests ou reorganiza arquivos.

---

## 2. Fontes Analisadas

| Documento | Papel na análise |
|---|---|
| `prodops/framework/ontology.md` | Hierarquia Journey → Cycle → Phase; distinção Capability/Skill |
| `prodops/framework/knowledge-vs-execution.md` | Princípios fundamentais; Knowledge Space vs. Execution Space |
| `prodops/framework/glossary.md` | Vocabulário canônico |
| `prodops/exec/manifest.yaml` | Pipeline, skills, paths, gates, GitHub COR |
| `prodops/framework/execution-mapping/work-item-schema.md` | Campos canônicos, enums de operation, artifact_type, status |
| `prodops/framework/execution-mapping/matrix.md` | Operações permitidas por artefato |
| `prodops/framework/execution-mapping/README.md` | Modelo conceitual de Work Items |
| `prodops/framework/journeys/README.md` | Separação jornadas/modos; fluxo Downstream |
| `prodops/framework/journeys/delivery/README.md` | Responsabilidade, entrada, fases da Delivery |
| `prodops/framework/journeys/delivery/ci-sync.md` | Ciclo CI Sync: Bootstrap → Hack → Sync → Finish |
| `prodops/framework/journeys/delivery/ci-async.md` | Ciclo CI Async: Ship → Validate → Promote |
| `prodops/framework/journeys/delivery/phases/*/README.md` | Especificação de cada fase (7 fases lidas) |
| `prodops/framework/journeys/diligence/README.md` | Propósito, ciclos, capabilities, anti-padrões |
| `prodops/framework/journeys/diligence/checks/catalog.yaml` | 14 Checks ativos catalogados |
| `prodops/framework/journeys/diligence/github-workspace.md` | Especificação canônica do Execution Space Diligence |
| `prodops/framework/journeys/diligence/github-workspace-schema.yaml` | Schema de campos por entidade |
| `prodops/framework/journeys/diligence/diligence-sync.md` | Ciclo reativo; fases Capture/Attach/Promote/Close |
| `prodops/framework/journeys/diligence/diligence-async.md` | Ciclo proativo; fases Scan/Flag/Repair |
| `prodops/framework/journeys/assessment/README.md` | Responsabilidade e artefatos do Assessment |
| `prodops/framework/backlogs.md` | Hierarquia e fluxo de backlogs |
| `prodops/framework/flow.md` | Fluxo canônico do Framework |
| `prodops/artifacts/plans/iteration-plan.md` | Estrutura real de um Iteration Plan em uso |
| `prodops/artifacts/plans/reliability/README.md` | Reliability Plan com referências a DORA |

---

## 3. Estado Atual da Jornada Delivery

### 3.1 O que existe e funciona

A Jornada Delivery possui:

- **Pipeline declarado** em `manifest.yaml`: `ci_sync: [bootstrap, hack, sync, finish]` e `ci_async: [ship, validate, promote]`
- **Sete fases documentadas** com responsabilidade, pré-condições e pós-condições verificáveis
- **Quality gates verificáveis**: `lint`, `acceptance`, `build`, `no_mocks`, `smoke` (todos em `manifest.yaml`)
- **Critério de entrada formal**: OBC committed + BDD Feature committed + riscos documentados + (condicionalmente) Reliability Plan
- **Critério de saída formal**: Release Trail com promoção registrada; aprovação formal de PM + Tech Lead
- **Dois Checks de Diligence** cobrindo Delivery: DIL-RDY-001 (Reliability Plan) e DIL-RDY-002 (Promote Criteria)

### 3.2 O que está ausente — lacunas identificadas

| Lacuna | Impacto |
|---|---|
| Nenhum modelo de estados operacionais para Work Items em Delivery | Não é possível responder "em que fase está este item?" via GitHub |
| Nenhum GitHub Project `ProdOps — Delivery` declarado | Diligence não tem superfície canônica para observar o fluxo |
| Nenhum campo de timestamp por fase nos Work Items | Impossível calcular lead time, cycle time ou tempo por fase |
| Estados BLOCKED e WAITING são apenas tags informais | Bloqueios não são detectáveis por Checks automatizados |
| Nenhum Check de Diligence para: item parado, rework, drift CI, ausência de responsável | Drift entre fases não é detectado proativamente |
| Nenhum critério formal para criação automática de Work Items durante Delivery | Gaps de rastreabilidade não são detectados até ciclo Async |
| Nenhuma interface formal Delivery → Assessment via Diligence | Sinais de que OBC requer reassessment não são capturados |
| DORA metrics referenciadas no Reliability Plan mas sem mecanismo de coleta | Métricas declaradas, não observáveis |

---

## 4. Modelo de Estados Operacionais

### 4.1 Diagrama do modelo de estados

```
                         ┌────────────────────────────────────────────┐
                         │         ITERATION PLAN ENTRY               │
                         │  [OBC committed + BDD committed +          │
                         │   Riscos documentados]                     │
                         └──────────────┬─────────────────────────────┘
                                        │
                                        ▼
                              ┌─────────────────┐
                              │   BOOTSTRAPPING  │ ◄─── CI Sync inicia
                              └────────┬────────┘
                                       │  smoke gate verde
                                       ▼
                              ┌─────────────────┐
                              │    HACKING       │ ◄─── TDD: Red→Green→Yellow
                              └────────┬────────┘
                                       │  commit(s) com evidência TDD
                                       ▼
                              ┌─────────────────┐
                              │    SYNCING       │ ◄─── rebase + align artefatos
                              └────────┬────────┘
                                       │  artefatos alinhados, base atualizada
                                       ▼
                              ┌─────────────────┐
                              │   FINISHING      │ ◄─── lint + build + acceptance + PR
                              └────────┬────────┘
                                       │  PR publicado com evidências
                                       │  (PR review pode criar WAITING aqui)
                                       ▼
                              ┌─────────────────┐
                              │    SHIPPING      │ ◄─── CI Async: build + deploy staging
                              └────────┬────────┘
                                       │  artefato publicado, deploy realizado
                                       ▼
                              ┌─────────────────┐
                              │   VALIDATING     │ ◄─── runtime, SLO, BDD em staging
                              └────────┬────────┘
                                       │  evidência de validação registrada
                                       ▼
                              ┌─────────────────┐
                              │   PROMOTING      │ ◄─── Release Approval + Release Trail
                              └────────┬────────┘
                                       │  promoção para produção confirmada
                                       ▼
                              ┌─────────────────┐
                              │     DONE         │ ◄─── OBC → Operational; Work Item fecha
                              └─────────────────┘

Estados transversais (podem interceptar qualquer fase):
  ┌─────────────────┐     ┌─────────────────┐
  │    BLOCKED       │     │    WAITING       │
  │ (bloqueio ativo) │     │ (aguardando ação │
  │                  │     │  externa)        │
  └─────────────────┘     └─────────────────┘

Rework (retorno ao Hacking):
  SYNCING ──── conflito irresolvível ──────────► HACKING
  FINISHING ── gate falhou ────────────────────► HACKING
  VALIDATING ─ falha em runtime ──────────────► HACKING (novo ciclo Red Bar)
```

### 4.2 Especificação de cada estado

#### Estado: BOOTSTRAPPING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Bootstrapping` |
| **Fase correspondente** | Bootstrap (CI Sync) |
| **Condição de entrada** | Item entra no Iteration Plan com todos os pré-requisitos satisfeitos (OBC committed, BDD committed, riscos documentados, Reliability Plan quando condicionalmente obrigatório) |
| **Condição de saída** | Smoke gate verde; ambiente local preparado; dependências instaladas |
| **Condições bloqueantes** | Smoke gate falha; dependência externa indisponível; variável de ambiente ausente |
| **Duração esperada** | Minutos a horas |
| **Artefato produzido** | Nenhum — confirma ambiente pronto |
| **Gatilho de próximo estado** | Hack start estabelece branch; item passa a `Hacking` |

#### Estado: HACKING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Hacking` |
| **Fase correspondente** | Hack (CI Sync) |
| **Condição de entrada** | Branch criada via `hack start`; ambiente Bootstrap confirmado |
| **Condição de saída** | Ciclo Red→Green→Yellow completo; commit com Conventional Commits; evidência TDD registrada |
| **Condições bloqueantes** | Red Bar não completado; contrato ausente ou inconsistente; dependência técnica bloqueante |
| **Duração esperada** | Horas a dias |
| **Artefato produzido** | Commits na feature branch; entradas no Release Trail |
| **Gatilho de próximo estado** | `hack commit` concluído; item passa a `Syncing` |
| **Retorno possível** | Pode receber item de `Syncing` (conflito irresolvível) ou `Finishing` (gate falhou) |

#### Estado: SYNCING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Syncing` |
| **Fase correspondente** | Sync — steps `rebase` e `align` (CI Sync) |
| **Condição de entrada** | Hack concluído; branch com commits prontos |
| **Condição de saída** | `rebase` completo (working tree limpa, testes passando sobre base integrada); `align` completo (BDD, Event Storming, arquitetura, OBC alinhados com diff) |
| **Condições bloqueantes** | Conflito irresolvível sem voltar ao Hacking; artefato ProdOps inconsistente que requer decisão de negócio |
| **Duração esperada** | Minutos a horas |
| **Artefato produzido** | Branch integrada; artefatos ProdOps atualizados (BDD Feature, Event Storming, arquitetura, Release Trail) |
| **Gatilho de próximo estado** | Sync concluído → `Finishing` |

#### Estado: FINISHING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Finishing` |
| **Fase correspondente** | Finish (CI Sync) |
| **Condição de entrada** | Sync completo (branch integrada + artefatos alinhados) |
| **Condição de saída** | Todos os quality gates verdes (lint, build, acceptance, no_mocks); DoD satisfeito; PR publicado com evidências; evidência no Release Trail |
| **Condições bloqueantes** | Qualquer gate falha; DoD insatisfeito; test pulado sem justificativa |
| **Duração esperada** | Horas |
| **Artefato produzido** | Pull Request com evidências; entrada no Release Trail |
| **Gatilho de próximo estado** | PR aprovado → `Shipping` (pode haver `Waiting` durante review) |

#### Estado: WAITING (transversal, mais comum em Finishing)

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Waiting` |
| **Natureza** | Estado transversal — pode ocorrer em qualquer fase, mas mais comum entre Finishing e Shipping |
| **Condição de entrada** | Item aguarda ação externa: PR review, aprovação de PM/Tech Lead, decisão de negócio, dependência de outro item |
| **Condição de saída** | Ação externa concluída; item retorna à fase correspondente |
| **Condições bloqueantes** | Revisor indisponível; dependência de item externo não concluído |
| **Duração esperada** | Horas a dias (qualquer WAITING > 2 dias úteis deve ser sinalizado pela Diligence) |
| **Observabilidade** | Campo `Delivery Phase` permanece na fase atual; campo `Delivery Status` = `Waiting`; campo `Waiting Since` (data) preenchido |

#### Estado: BLOCKED (transversal)

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Blocked` |
| **Natureza** | Estado transversal — bloqueio ativo que impede progresso mesmo com esforço |
| **Condição de entrada** | Gate falhou repetidamente; dependência externa bloqueante; decisão de negócio pendente que não pode ser contornada |
| **Condição de saída** | Bloqueio resolvido; Diligence registra Finding se bloqueio for sistêmico |
| **Duração esperada** | Qualquer BLOCKED > 1 dia útil deve gerar Finding por DIL-DEL-004 (novo check proposto) |
| **Distinção de WAITING** | BLOCKED = impedimento ativo (não pode progredir). WAITING = dependência conhecida com prazo (pode progredir quando ação ocorrer). |
| **Observabilidade** | `Delivery Status` = `Blocked`; campo `Blocked Reason` preenchido com categoria canônica |

#### Estado: SHIPPING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Shipping` |
| **Fase correspondente** | Ship (CI Async) |
| **Condição de entrada** | PR aprovado; CI gates verdes; Finish concluído |
| **Condição de saída** | Artefato publicado no registry; deploy em staging realizado; progressive delivery configurada quando aplicável |
| **Condições bloqueantes** | Pipeline de build falha; deploy falha; rollback necessário |
| **Duração esperada** | Minutos a horas |
| **Artefato produzido** | Artefato publicado (container, ZIP, layer); deploy em staging |
| **Gatilho de próximo estado** | Deploy confirmado em staging → `Validating` |

#### Estado: VALIDATING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Validating` |
| **Fase correspondente** | Validate (CI Async) |
| **Condição de entrada** | Deploy em staging realizado |
| **Condição de saída** | Evidência de validação coletada: smoke tests, runtime contract validation, BDD em staging, SLO validation, observabilidade confirmada; Release Trail atualizado |
| **Condições bloqueantes** | Smoke test falha; BDD falha em staging; SLO violado; incidente detectado pós-deploy |
| **Duração esperada** | Horas |
| **Retorno possível** | Falha → novo ciclo Hacking (comportamento observado vira novo Red Bar) |
| **Artefato produzido** | Evidências de validação no Release Trail; report de SLO |

#### Estado: PROMOTING

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Promoting` |
| **Fase correspondente** | Promote (CI Async) |
| **Condição de entrada** | Validação completa com evidências; riscos avaliados; prontidão operacional confirmada |
| **Condição de saída** | Release Approval de PM + Tech Lead; deploy em produção; Release Trail com entrada definitiva; OBC → Operational |
| **Condições bloqueantes** | Approval negado; risco alto não documentado; rollback plan ausente; Finding bloqueante ativo sem Waiver |
| **Duração esperada** | Horas |
| **Check aplicável** | DIL-RDY-002 (Promote Criteria Satisfied) |
| **Artefato produzido** | Release Trail definitivo; Release documentation; Task fechada |

#### Estado: DONE

| Atributo | Valor |
|---|---|
| **Nome canônico** | `Done` |
| **Condição de entrada** | Promote completo; produção confirmada; Release Trail registrado; Task fechada |
| **Artefato resultante** | OBC transiciona para estado `Operational`; Work Item fecha; Diligence Close executado |

### 4.3 Transições válidas

```
BOOTSTRAPPING → HACKING             [smoke gate verde]
BOOTSTRAPPING → BLOCKED             [ambiente irrecuperável]
HACKING       → SYNCING             [hack commit concluído]
HACKING       → BLOCKED             [bloqueio técnico irresolvível]
HACKING       → WAITING             [dependência de decisão externa]
SYNCING       → FINISHING           [rebase + align completos]
SYNCING       → HACKING             [conflito irresolvível — rework]
FINISHING     → SHIPPING            [PR aprovado]
FINISHING     → HACKING             [gate falhou — rework]
FINISHING     → WAITING             [aguardando PR review]
SHIPPING      → VALIDATING          [deploy em staging confirmado]
SHIPPING      → BLOCKED             [pipeline falha persistente]
VALIDATING    → PROMOTING           [evidências coletadas, riscos avaliados]
VALIDATING    → HACKING             [falha em runtime — rework]
VALIDATING    → BLOCKED             [incidente crítico pós-deploy]
PROMOTING     → DONE                [Release Approval + deploy em produção]
PROMOTING     → BLOCKED             [approval negado / Finding bloqueante]
WAITING       → [estado anterior]   [ação externa concluída]
BLOCKED       → [estado anterior]   [bloqueio resolvido]
```

**Retornos (rework):** Qualquer transição de volta para `Hacking` a partir de `Syncing`, `Finishing` ou `Validating` constitui **rework** e deve ser rastreado no campo `Rework Count` (incremento +1).

---

## 5. GitHub Project — ProdOps: Delivery

### 5.1 Propósito e escopo

O Project `ProdOps — Delivery` representa operacionalmente a Jornada Delivery: rastreia Work Items referentes a operações ativas sobre OBCs, BDD Features e Reliability Plans que estão dentro do escopo Iteration Plan → Promoção para produção.

**Não rastreia:** Discovery, Portfolio, Business Intents, arquivamento, itens fora do Iteration Plan.

### 5.2 Fields propostos

#### Campos Knowledge Space (READ-ONLY no GitHub — fonte de verdade é o Markdown)

| Campo | Tipo | Obrigatório | Descrição | Fonte de verdade |
|---|---|---|---|---|
| `Artifact Type` | single_select | Sim | Tipo do artefato afetado: `Local OBC`, `BDD Feature`, `Reliability Plan` | `work-item-schema.md` enum |
| `Artifact ID` | text | Sim | Slug do artefato (ex: `pix-payment-v1`) | Arquivo Markdown |
| `Operation` | single_select | Sim | Operação em execução: `Implement`, `Validate`, `Update`, `Promote` | `work-item-schema.md` enum |
| `Journey` | single_select | Sim | Sempre `Delivery` neste Project | `ontology.md` |
| `Execution Mode` | single_select | Sim | Sempre `Downstream` na Delivery | `manifest.yaml` |
| `OBC State` | single_select | Sim | Estado atual do OBC no Markdown: `Committed`, `In Delivery`, `Operational` | Arquivo OBC |
| `Release Target` | text | Condicional | Versão alvo (ex: `v2.1.0`) | `iteration-plan.md` |

> **Regra:** Estes campos são populados pela Diligence ao criar/atualizar Work Items. Nunca editados manualmente no GitHub — edição manual cria drift detectável por DIL-WSP-001.

#### Campos Execution Space (WRITE no GitHub — fonte de verdade é o GitHub Issue)

| Campo | Tipo | Obrigatório | Opções | Descrição |
|---|---|---|---|---|
| `Delivery Phase` | single_select | Sim | `Bootstrapping`, `Hacking`, `Syncing`, `Finishing`, `Shipping`, `Validating`, `Promoting` | Fase atual da Delivery em que o item se encontra |
| `Delivery Status` | single_select | Sim | `Active`, `Waiting`, `Blocked`, `Done` | Estado operacional (Active = progredindo; Waiting = aguardando ação externa; Blocked = impedimento ativo) |
| `Cycle` | single_select | Sim | `CI Sync`, `CI Async` | Ciclo ativo para o item |
| `Phase Entered At` | date | Sim | — | Data em que o item entrou na fase atual |
| `Blocked Reason` | single_select | Condicional | `Gate Failure`, `External Dependency`, `Business Decision Pending`, `Technical Blocker`, `Review Pending`, `Pipeline Failure`, `Other` | Preenchido quando `Delivery Status = Blocked` |
| `Waiting Since` | date | Condicional | — | Preenchido quando `Delivery Status = Waiting` |
| `Rework Count` | number | Sim (default 0) | — | Número de retornos ao Hacking (rework events) |
| `Gate Results` | text | Condicional | — | Resultado dos quality gates (pass/fail + evidência) — preenchido pelo Finish/Promote |
| `PR Link` | text | Condicional | — | Link do Pull Request gerado pelo Finish |
| `Assignee` | person (nativo) | Sim | — | Responsável pelo item |
| `Priority` | single_select (nativo) | Sim | `Critical`, `High`, `Medium`, `Low` | Prioridade operacional |
| `Status` (nativo) | single_select (nativo) | Sim | `Todo`, `In Progress`, `Done`, `Blocked`, `Cancelled` | Status nativo do GitHub Project (espelha Delivery Status para compatibilidade) |

#### Campos de observabilidade (calculados / preenchidos por eventos)

| Campo | Tipo | Calculado por | Descrição |
|---|---|---|---|
| `Bootstrap Started At` | date | Diligence / automação | Timestamp de entrada em Bootstrapping |
| `Hacking Started At` | date | Diligence / automação | Timestamp de entrada em Hacking |
| `Finishing Started At` | date | Diligence / automação | Timestamp de entrada em Finishing |
| `Ship Started At` | date | Diligence / automação | Timestamp de entrada em Shipping |
| `Validate Started At` | date | Diligence / automação | Timestamp de entrada em Validating |
| `Promote Started At` | date | Diligence / automação | Timestamp de entrada em Promoting |
| `Promoted At` | date | Diligence / automação | Timestamp de promoção para produção |

> **Nota de implementação:** Timestamps por fase são o mecanismo fundamental para derivar Lead Time for Changes, Cycle Time e Time per Phase. Sem eles, as métricas DORA não são deriváveis do GitHub state.

### 5.3 Labels propostos

**Regra de distinção:** Labels classificam Work Items para busca e filtro via `gh issue list`. Não são fonte de verdade para estado (estado vive nos Fields). Não duplicar: se um Field já captura a informação, um Label não deve capturar a mesma.

| Label | Formato | Propósito | Valores permitidos |
|---|---|---|---|
| `phase:<valor>` | `phase:hacking`, `phase:validating` | Permitir filtro por fase ativa via CLI sem depender do Project | `bootstrapping`, `hacking`, `syncing`, `finishing`, `shipping`, `validating`, `promoting` |
| `cycle:<valor>` | `cycle:ci-sync`, `cycle:ci-async` | Filtro por ciclo | `ci-sync`, `ci-async` |
| `status:<valor>` | `status:blocked`, `status:waiting` | Filtro por situação operacional | `blocked`, `waiting`, `active` |
| `rework` | `rework` | Marcador de item que sofreu rework (Rework Count > 0) | — (presence-only) |
| `gate-failed:<gate>` | `gate-failed:lint`, `gate-failed:acceptance` | Rastrear qual gate falhou para análise de padrões | `lint`, `build`, `acceptance`, `no-mocks`, `smoke` |
| `operation:<valor>` | `operation:implement` | Operação canônica (já definido em work-item-schema.md) | enum `operation` |
| `artifact-type:<valor>` | `artifact-type:local-obc` | Tipo de artefato (já definido em work-item-schema.md) | enum `artifact_type` |
| `journey:delivery` | `journey:delivery` | Identificação de Journey para filtro cross-project | — |

**O que NÃO é Label:**
- Estado de OBC (vive no Markdown do OBC)
- Versão de release (vive no Field `Release Target`)
- Prioridade (vive no Field `Priority` nativo do GitHub)
- Assignee (vive no campo nativo `Assignees`)

### 5.4 Views propostas

#### View 1 — Kanban Delivery (Board Principal)

| Atributo | Valor |
|---|---|
| **Nome** | `Delivery Board` |
| **Tipo** | Board (Kanban) |
| **Filtro** | `Delivery Status != Done` e `Delivery Status != Cancelled` |
| **Group by** | `Delivery Phase` |
| **Sort by** | `Priority` (desc), `Phase Entered At` (asc) |
| **Uso** | Visão de fluxo diário: onde estão os itens, o que está parado, o que está progredindo |

#### View 2 — Bloqueados e em Espera

| Atributo | Valor |
|---|---|
| **Nome** | `Blocked & Waiting` |
| **Tipo** | Table |
| **Filtro** | `Delivery Status = Blocked OR Delivery Status = Waiting` |
| **Colunas** | Artifact ID, Delivery Phase, Delivery Status, Blocked Reason, Blocked/Waiting Since, Assignee |
| **Sort by** | `Phase Entered At` (asc — mais antigos primeiro) |
| **Uso** | Radar diário de impedimentos; Diligence verifica diariamente para detectar bloqueios > threshold |

#### View 3 — CI Sync (fases locais)

| Atributo | Valor |
|---|---|
| **Nome** | `CI Sync` |
| **Tipo** | Table |
| **Filtro** | `Cycle = CI Sync` e `Delivery Status != Done` |
| **Colunas** | Artifact ID, Delivery Phase, Delivery Status, Assignee, Hacking Started At, Rework Count |
| **Sort by** | `Delivery Phase` (ordem lógica), `Priority` (desc) |
| **Uso** | Foco no trabalho local do engenheiro: Bootstrap, Hack, Sync, Finish |

#### View 4 — CI Async (plataforma e pipelines)

| Atributo | Valor |
|---|---|
| **Nome** | `CI Async` |
| **Tipo** | Table |
| **Filtro** | `Cycle = CI Async` e `Delivery Status != Done` |
| **Colunas** | Artifact ID, Delivery Phase, Delivery Status, Ship Started At, Gate Results, PR Link |
| **Sort by** | `Delivery Phase` (ordem lógica), `Priority` (desc) |
| **Uso** | Foco no pipeline: Ship, Validate, Promote; visibilidade de gates |

#### View 5 — Fila de Promote (Awaiting Approval)

| Atributo | Valor |
|---|---|
| **Nome** | `Promote Queue` |
| **Tipo** | Table |
| **Filtro** | `Delivery Phase = Promoting` |
| **Colunas** | Artifact ID, OBC State, Release Target, Gate Results, Promote Started At, Assignee |
| **Sort by** | `Promote Started At` (asc) |
| **Uso** | Visibilidade para PM e Tech Lead do que aguarda Release Approval |

#### View 6 — Rework e Qualidade

| Atributo | Valor |
|---|---|
| **Nome** | `Rework Tracker` |
| **Tipo** | Table |
| **Filtro** | `Rework Count > 0` |
| **Colunas** | Artifact ID, Delivery Phase, Rework Count, Gate Results, Hacking Started At |
| **Sort by** | `Rework Count` (desc) |
| **Uso** | Análise de padrões de rework; identificar gates que geram mais retorno |

#### View 7 — Concluídos (Sprint/Período)

| Atributo | Valor |
|---|---|
| **Nome** | `Done — Current Sprint` |
| **Tipo** | Table |
| **Filtro** | `Delivery Status = Done` e `Promoted At >= [início do sprint]` |
| **Colunas** | Artifact ID, Promoted At, Release Target, Rework Count, Lead Time |
| **Sort by** | `Promoted At` (desc) |
| **Uso** | Throughput e retrospectiva; insumo para métricas de fluxo |

#### View 8 — Dashboard de Métricas (Readonly Summary)

| Atributo | Valor |
|---|---|
| **Nome** | `Flow Metrics` |
| **Tipo** | Table agrupada |
| **Filtro** | Todos os itens do sprint atual |
| **Group by** | `Delivery Phase` |
| **Colunas** | Count, Avg Phase Entered At, Blocked Count, Rework Count |
| **Uso** | Insumo para cálculo manual de métricas de fluxo; Diligence usa para relatório periódico |

---

## 6. Observabilidade do Fluxo

Para cada questão de observabilidade, a proposta define o dado necessário, como a Diligence deriva a resposta e qual Check habilita a observação.

### 6.1 "Onde está o fluxo bloqueado?"

**Dado necessário:**
- Campo `Delivery Status = Blocked` ou `Delivery Status = Waiting`
- Campo `Blocked Reason` (categoria do bloqueio)
- Campo `Phase Entered At` (quanto tempo no estado atual)

**Como a Diligence deriva:**
```
SELECT artifact_id, delivery_phase, blocked_reason, phase_entered_at
FROM github_project
WHERE delivery_status IN ('Blocked', 'Waiting')
ORDER BY phase_entered_at ASC
```

**Check habilitador:** DIL-DEL-004 (NOVO — ver Seção 7: Item parado por tempo excessivo)

**Representação:** Finding `FND-YYYY-NNNN` com `check_id: DIL-DEL-004`, referenciando o Artifact ID e a fase bloqueada. Severity = `High` quando > 2 dias úteis; `Critical` quando > 5 dias úteis.

---

### 6.2 "Quanto tempo um item ficou em cada fase?"

**Dado necessário:**
- Timestamps por fase: `Bootstrap Started At`, `Hacking Started At`, `Finishing Started At`, `Ship Started At`, `Validate Started At`, `Promote Started At`, `Promoted At`

**Como a Diligence deriva:**
```
time_in_hacking    = Finishing Started At - Hacking Started At
time_in_finishing  = Ship Started At - Finishing Started At
time_in_shipping   = Validate Started At - Ship Started At
time_in_validating = Promote Started At - Validate Started At
time_in_promoting  = Promoted At - Promote Started At
total_lead_time    = Promoted At - Bootstrap Started At
```

**Check habilitador:** DIL-DEL-005 (NOVO — Timestamp de fase ausente para Work Item ativo em Delivery)

**Nota:** Sem os timestamps por fase, as métricas DORA e de fluxo não são deriváveis automaticamente. Os timestamps são a dependência fundamental de toda a camada de observabilidade.

---

### 6.3 "Quantos itens retrocederam (rework)?"

**Dado necessário:**
- Campo `Rework Count` (número inteiro, incrementado a cada retorno ao Hacking)
- Campo `Delivery Phase` (fase atual)
- Label `rework` (presence-only para busca via CLI)

**Como a Diligence deriva:**
```
rework_items = SELECT artifact_id, rework_count FROM github_project WHERE rework_count > 0
rework_rate = COUNT(rework_items) / COUNT(all_items_in_period)
```

**Padrão de sinal de rework:** Transição de `Delivery Phase` de `Syncing`, `Finishing` ou `Validating` para `Hacking`. A Diligence detecta isso durante Diligence Sync (na fase Attach): se `Delivery Phase` foi atualizado para `Hacking` após ter sido `Finishing` ou `Validating`, o campo `Rework Count` deve ser incrementado.

**Check habilitador:** DIL-DEL-006 (NOVO — Rework Count desatualizado em relação à fase observada)

---

### 6.4 "Quais gates falharam?"

**Dado necessário:**
- Campo `Gate Results` (texto com resultado de cada gate: `lint:PASS`, `acceptance:FAIL`, etc.)
- Label `gate-failed:<gate>` (para busca via CLI)
- Campo `Delivery Status = Blocked` com `Blocked Reason = Gate Failure`

**Como a Diligence deriva:**
- Varredura do campo `Gate Results` nos Work Items em `Finishing` e `Promoting`
- Contagem de ocorrências por tipo de gate: `gate-failed:lint`, `gate-failed:acceptance`, etc.

**Check habilitador:** DIL-DEL-007 (NOVO — Gate falhou sem Finding de rastreio aberto)

---

### 6.5 "Onde há uma fila?" (itens esperando entrar em uma fase)

**Dado necessário:**
- Campo `Delivery Phase` (fase atual)
- Campo `Delivery Status = Waiting` (aguardando transição)
- Distribuição de itens por fase no Project

**Como a Diligence deriva:**
- Count de itens por `Delivery Phase` — concentração em uma fase sinaliza gargalo/fila
- Itens com `Delivery Status = Waiting` na fase `Finishing` = fila para Shipping (aguardando PR review)
- Itens com `Delivery Status = Waiting` na fase `Promoting` = fila para produção (aguardando Release Approval)

**Threshold para sinalizar:** ≥ 3 itens em `Waiting` na mesma fase por > 1 dia = Finding de gargalo de fluxo.

---

### 6.6 "Onde há rework?" (distinção de progressão normal)

**Distinção fundamental:**
- **Progressão normal:** `Hacking → Syncing → Finishing → Shipping` (sem retorno)
- **Rework:** qualquer transição de volta para `Hacking` a partir de `Syncing`, `Finishing` ou `Validating`

**Como distinguir:** O campo `Rework Count` acumulado por item. Se `Rework Count = 0` e o item está em qualquer fase: progressão normal. Se `Rework Count > 0`: o item sofreu rework ao menos uma vez.

**Padrão de rework mais custoso:** `Validating → Hacking` (rework pós-staging) — indica que o problema escapou de todos os gates locais e só foi detectado em runtime. Este padrão deve gerar Finding com Severity = `High`.

---

### 6.7 "Qual fase gera mais tempo de espera?"

**Como a Diligence calcula:**
1. Para todos os itens `Done` no período: calcular `time_in_<phase>` para cada fase usando os timestamps
2. Calcular média e percentil 90 de tempo por fase
3. Identificar fase com maior média: essa é a fase geradora de maior wait time

**Insumo para métricas:** Esta derivação alimenta a métrica `Average Time per Phase` (ver Seção 9) e a métrica `Flow Efficiency` (tempo ativo vs. tempo de espera).

**Check habilitador:** Nenhum Check existente cobre análise agregada de tempo por fase. A Diligence Async deve incluir este cálculo no Scan periódico, gerando Finding informativo (`severity: Info`) quando uma fase excede 3x a média das demais.

---

## 7. Critérios para Abertura Automática de Work Items

A tabela abaixo descreve os 10 padrões propostos para criação automática de Work Items pela Diligence durante a Jornada Delivery. Para cada padrão, é indicado se existe Check correspondente no catálogo atual.

### 7.1 Tabela de critérios

#### Padrão 1 — Pull Request sem OBC referenciada

| Atributo | Valor |
|---|---|
| **Nome** | `PR Without OBC Reference` |
| **Detecção** | Diligence Sync acionada por PR event: verifica body do PR por referência a `artifact_id` de Local OBC |
| **Condição de gatilho** | PR aberto com `base = main` (ou branch de release) sem menção ao slug de OBC no body ou nos campos do Project |
| **Artifact ID** | Slug do OBC inferível pelo path dos arquivos modificados (`api/src/<domain>/`) |
| **Operation** | `Implement` |
| **Severity** | `High` |
| **Auto-close** | Quando PR body for atualizado com referência canônica ao OBC |
| **Check existente?** | DIL-TRC-001 cobre Work Item sem referência de artefato, mas não especificamente PR sem OBC. **NOVO CHECK NEEDED: DIL-DEL-001** |

#### Padrão 2 — OBC sem BDD Feature quando em Iteration Plan

| Atributo | Valor |
|---|---|
| **Nome** | `OBC in Delivery Without BDD` |
| **Detecção** | Diligence Async Scan: verifica OBCs com estado `In Delivery` ou `Committed` no Iteration Plan; verifica existência de arquivo `.feature` em `prodops/artifacts/bdd/` referenciando o OBC |
| **Condição de gatilho** | OBC com estado `Committed` aparece no Iteration Plan e não existe `.feature` file correspondente |
| **Artifact ID** | Slug do OBC |
| **Operation** | `Create` (sobre BDD Feature ausente) |
| **Severity** | `Critical` (bloqueia Deliver — BDD é pré-requisito de entrada) |
| **Auto-close** | Quando arquivo `.feature` for criado com referência ao OBC |
| **Check existente?** | DIL-RDY-002 verifica critérios de Promote, mas não detecta ausência de BDD na entrada ao Iteration Plan. **NOVO CHECK NEEDED: DIL-DEL-002** |

#### Padrão 3 — Item parado por tempo excessivo numa fase

| Atributo | Valor |
|---|---|
| **Nome** | `Delivery Item Stale in Phase` |
| **Detecção** | Diligence Async Scan periódico: compara `Phase Entered At` com data atual para Work Items em `Delivery Status != Done` |
| **Condição de gatilho** | `Phase Entered At` < (hoje - 2 dias úteis) E `Delivery Status != Waiting` E `Delivery Status != Blocked` |
| **Artifact ID** | Slug do OBC do Work Item |
| **Operation** | `Review` (investigar causa do atraso) |
| **Severity** | `High` quando 2-4 dias; `Critical` quando > 4 dias |
| **Auto-close** | Quando `Delivery Status` mudar (item progrediu ou foi explicitamente marcado como Blocked/Waiting) |
| **Check existente?** | Nenhum. **NOVO CHECK NEEDED: DIL-DEL-003** |

#### Padrão 4 — Promote sem evidências de validação

| Atributo | Valor |
|---|---|
| **Nome** | `Promote Without Validation Evidence` |
| **Detecção** | Diligence Sync acionado por transição de Validating para Promoting: verifica se campo `Gate Results` contém evidência de Validate e se Release Trail foi atualizado |
| **Condição de gatilho** | Item transiciona para `Delivery Phase = Promoting` sem `Gate Results` preenchido com resultados de Validate, ou sem entrada correspondente no Release Trail |
| **Artifact ID** | Slug do OBC |
| **Operation** | `Validate` (evidência pendente) |
| **Severity** | `Critical` — bloqueia Promote |
| **Auto-close** | Quando `Gate Results` for preenchido com evidências e Release Trail for atualizado |
| **Check existente?** | DIL-RDY-002 verifica critérios de Promote mas não verifica especificamente evidências de Validate no Work Item. **NOVO CHECK NEEDED: DIL-DEL-004** |

#### Padrão 5 — Pipeline quebrado sem Work Item de rastreio

| Atributo | Valor |
|---|---|
| **Nome** | `CI Pipeline Failure Without Tracking` |
| **Detecção** | Diligence Sync acionado por GitHub Actions failure event: verifica se existe Work Item aberto com `Delivery Status = Blocked` e `Blocked Reason = Pipeline Failure` para a branch afetada |
| **Condição de gatilho** | GitHub Actions workflow falha na branch `main` ou em branch de feature com PR aberto, e não existe Work Item de rastreio com `gate-failed:*` label ou `Blocked Reason = Pipeline Failure` |
| **Artifact ID** | Slug do OBC inferido pelo PR associado à branch |
| **Operation** | `Review` |
| **Severity** | `High` |
| **Auto-close** | Quando pipeline retornar verde ou quando Work Item existente for atualizado com `Delivery Status = Active` |
| **Check existente?** | Nenhum. **NOVO CHECK NEEDED: DIL-DEL-005** |

#### Padrão 6 — Drift entre artefato Markdown e estado do GitHub Issue

| Atributo | Valor |
|---|---|
| **Nome** | `Artifact State vs GitHub State Drift` |
| **Detecção** | Diligence Async Scan: compara campo `OBC State` no Work Item (Knowledge Space → leitura do Markdown) com campo `Delivery Phase` (Execution Space) |
| **Condição de gatilho** | Campo `OBC State` no Work Item difere do estado real declarado no arquivo `prodops/artifacts/obcs/<slug>.md` |
| **Artifact ID** | Slug do OBC |
| **Operation** | `Reconcile` |
| **Severity** | `Medium` |
| **Auto-close** | Quando campo `OBC State` no Work Item for atualizado para coincidir com o Markdown |
| **Check existente?** | DIL-WSP-001 cobre conformidade do Workspace Schema, mas não drift específico de campo OBC State. **NOVO CHECK NEEDED: DIL-DEL-006** |

#### Padrão 7 — Reliability Plan ausente para OBC em Delivery

| Atributo | Valor |
|---|---|
| **Nome** | `Reliability Plan Missing for Delivery OBC` |
| **Detecção** | Diligence Sync no gate de entrada ao Iteration Plan: verifica gatilhos de obrigatoriedade do Reliability Plan no OBC |
| **Condição de gatilho** | OBC entra no Iteration Plan, satisfaz pelo menos um gatilho de obrigatoriedade (movimentação financeira, integração externa, mudança de SLO, risco alto/crítico, persistência/segurança), e Reliability Plan não existe em `prodops/artifacts/plans/reliability/` |
| **Artifact ID** | Slug do OBC |
| **Operation** | `Create` (Reliability Plan) |
| **Severity** | `High` — bloqueia entrada na Delivery |
| **Auto-close** | Quando Reliability Plan for criado e aprovado |
| **Check existente?** | **DIL-RDY-001 JÁ EXISTE** — cobre exatamente este padrão. Nenhum novo Check necessário. |

#### Padrão 8 — BDD Feature sem cenários de aceitação definidos

| Atributo | Valor |
|---|---|
| **Nome** | `BDD Feature Without Acceptance Scenarios` |
| **Detecção** | Diligence Async Scan: lê arquivos `.feature` em `prodops/artifacts/bdd/` e verifica se há pelo menos um `Scenario:` ou `Scenario Outline:` definido |
| **Condição de gatilho** | Arquivo `.feature` existe mas não contém nenhum `Scenario:` ou contém apenas `Scenario:` sem steps `Given/When/Then` |
| **Artifact ID** | Path do arquivo `.feature` |
| **Operation** | `Refine` |
| **Severity** | `High` quando OBC está em Iteration Plan; `Medium` quando em Icebox |
| **Auto-close** | Quando arquivo `.feature` for atualizado com cenários válidos |
| **Check existente?** | Nenhum. **NOVO CHECK NEEDED: DIL-DEL-007** |

#### Padrão 9 — OBC em Delivery sem responsável

| Atributo | Valor |
|---|---|
| **Nome** | `Delivery OBC Without Assignee` |
| **Detecção** | Diligence Async Scan: verifica Work Items ativos no Project `ProdOps — Delivery` sem campo `Assignees` preenchido |
| **Condição de gatilho** | Work Item com `Delivery Phase != Done` e `Assignees` vazio por > 1 dia |
| **Artifact ID** | Slug do OBC |
| **Operation** | `Review` (designar responsável) |
| **Severity** | `Medium` |
| **Auto-close** | Quando `Assignees` for preenchido |
| **Check existente?** | Nenhum. **NOVO CHECK NEEDED: DIL-DEL-008** |

#### Padrão 10 — PR merged sem feature flag ou rollback plan quando Risk = High

| Atributo | Valor |
|---|---|
| **Nome** | `High Risk PR Without Rollback Plan` |
| **Detecção** | Diligence Sync acionado por PR merge event: verifica se PR de OBC com risco `High` ou `Critical` (conforme Reliability Plan ou Risk Register) tem menção explícita a feature flag ou rollback plan no body |
| **Condição de gatilho** | PR mergeado na branch base; OBC associado tem risco `High` ou `Critical` no Risk Register ou Reliability Plan; PR body não contém referência a feature flag (ex: `FF_*`, `FEATURE_FLAG`, `feature flag`) nem rollback plan |
| **Artifact ID** | Slug do OBC |
| **Operation** | `Update` (documentar rollback plan post-merge) |
| **Severity** | `High` |
| **Auto-close** | Quando PR for atualizado com documentação de rollback, ou quando Reliability Plan for atualizado com rollback strategy |
| **Check existente?** | Nenhum. **NOVO CHECK NEEDED: DIL-DEL-009** |

### 7.2 Resumo — Checks existentes vs. novos

| Padrão | Check Existente | Status |
|---|---|---|
| 1 — PR sem OBC | DIL-TRC-001 (parcial) | **NOVO: DIL-DEL-001** |
| 2 — OBC sem BDD em Delivery | DIL-RDY-002 (parcial) | **NOVO: DIL-DEL-002** |
| 3 — Item parado | — | **NOVO: DIL-DEL-003** |
| 4 — Promote sem evidência | DIL-RDY-002 (parcial) | **NOVO: DIL-DEL-004** |
| 5 — Pipeline sem rastreio | — | **NOVO: DIL-DEL-005** |
| 6 — Drift Markdown vs. GitHub | DIL-WSP-001 (parcial) | **NOVO: DIL-DEL-006** |
| 7 — Reliability Plan ausente | **DIL-RDY-001 JÁ EXISTE** | Nenhum novo Check |
| 8 — BDD sem cenários | — | **NOVO: DIL-DEL-007** |
| 9 — OBC sem responsável | — | **NOVO: DIL-DEL-008** |
| 10 — High risk sem rollback | — | **NOVO: DIL-DEL-009** |

**Total:** 1 Check existente cobre completamente o padrão 7. Os demais 9 requerem Checks novos (DIL-DEL-001 a DIL-DEL-009) a serem adicionados ao `catalog.yaml`.

---

## 8. Integração com Assessment

A Diligence não conduz Assessment. Ela observa, detecta sinais e emite recomendações rastreáveis. Esta seção define quando e como a Diligence sinaliza que um OBC em Delivery pode requerer novo Assessment.

### 8.1 Eventos acionadores (sinais observáveis)

#### Categoria A — Padrões pós-Delivery

| Sinal | Como detectar | Threshold |
|---|---|---|
| Taxa de rework > 30% nos últimos 2 sprints | `Rework Count > 0` em > 30% dos itens Promoted no período | Evidência de que acceptance criteria eram imprecisos |
| Validate gate falhando repetidamente | `gate-failed:acceptance` label em > 2 itens consecutivos do mesmo OBC | Evidência de que BDD não capturou edge cases reais |
| Tempo em Validating > 3x a média dos demais OBCs | Timestamp analysis no Scan periódico | Evidência de que critérios de aceite em staging são inadequados |
| Promote com riscos aceitos silenciosamente (Risk = High, sem Waiver formal) | DIL-DEL-009 disparado com frequência para o mesmo OBC | Evidência de que o Reliability Plan está desatualizado |

#### Categoria B — Sinais operacionais pós-promoção

| Sinal | Como detectar | Threshold |
|---|---|---|
| SLO violado nos 30 dias pós-promote | Entrada no Reliability Plan com SLO `<threshold` | OBC precisa de Assessment para atualizar SLIs/SLOs |
| Incidente relacionado ao OBC pós-promoção | Postmortem adicionado ao Release Trail com `type: Incident` | Evidência de que o Reliability Plan não cobriu o failure mode |
| Rollback executado em produção | Campo `Promoted At` + entrada de rollback no Release Trail | Evidência de que Validate não era representativo do ambiente produtivo |

#### Categoria C — Gatilhos temporais

| Trigger | Condição |
|---|---|
| 3 ciclos de Delivery completos sobre o mesmo OBC | OBC acumulou 3 Promotes — momento natural para reassessment de critérios |
| 6 meses desde o último Assessment do OBC | Temporal — OBC pode ter drifted da realidade de negócio |

### 8.2 Evidência mínima necessária antes de recomendar Assessment

A Diligence só emite recomendação formal de Assessment quando:

- [ ] Pelo menos 1 ciclo de Deliver completo (Promote concluído) com Release Trail existente
- [ ] OBC em estado `Operational` (não apenas `Released` ou `In Delivery`)
- [ ] Pelo menos um dos sinais da Seção 8.1 observado com evidência rastreável no GitHub
- [ ] Finding DIL-DEL-010 (NOVO — "Assessment Recommendation") criado com evidências

### 8.3 Métricas que justificam Assessment

| Métrica | Threshold quantitativo | Interpretação |
|---|---|---|
| `Validate Gate Failure Rate` | > 30% dos itens do OBC em 3 sprints | BDD não cobre os failure modes reais |
| `Rework Rate` | > 25% em 2 sprints consecutivos | Critérios de aceite são imprecisos ou instáveis |
| `Time in Validating` | > 3x a mediana do pipeline | Staging environment inadequado ou critérios complexos demais |
| `Time to Restore` (pós-incidente) | > 4 horas em produção | Reliability Plan insuficiente para o domínio |
| `Rollback Count` | ≥ 2 rollbacks em produção no mesmo OBC | OBC pronto para Delivery mas não para o ambiente produtivo |

### 8.4 Interface — como a Diligence emite a recomendação

**O que a Diligence produz:**

1. **Finding** `FND-YYYY-NNNN` com `check_id: DIL-DEL-010`, `severity: Medium` (informativo/recomendação)
2. **Work Item** no Project `ProdOps — Delivery`:
   - `Artifact Type: Local OBC`
   - `Artifact ID: <slug>`
   - `Operation: Review` (revisão para decisão sobre Assessment)
   - `Journey: Diligence`
3. **Escalação** para `Product Owner` e `Assessment Owner`

**O que a Diligence NÃO faz:**
- Não inicia o Assessment
- Não modifica o OBC
- Não decide se o Assessment é necessário — apenas sinaliza os dados que sugerem isso
- Não fecha o Finding até que o Assessment seja formalmente concluído ou descartado com justificativa

---

## 9. Catálogo Inicial de Métricas

### Legenda

- **Derivação:** formula ou processo para calcular a partir do GitHub state
- **Unidade:** time / count / percentage / ratio
- **Direção:** ↓ (menor é melhor) / ↑ (maior é melhor)

---

### 9.1 Métricas de Fluxo

#### M-01 — Lead Time for Changes (DORA)

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Tempo desde o primeiro commit na feature branch até o Promote em produção |
| **Fórmula** | `Promoted At - Hacking Started At` (por item) |
| **Unidade** | Horas / dias |
| **Direção** | ↓ |
| **Threshold sugerido** | Elite: < 1 dia; High: < 7 dias; Medium: < 30 dias |
| **DORA** | Lead Time for Changes |
| **Revela** | Quão rápido o fluxo transforma código em valor em produção |

#### M-02 — Deployment Frequency (DORA)

| Atributo | Valor |
|---|---|
| **Categoria** | Throughput |
| **Definição** | Número de Promotes bem-sucedidos para produção por sprint ou semana |
| **Fórmula** | `COUNT(items WHERE Delivery Status = Done AND Promoted At >= sprint_start)` |
| **Unidade** | count / sprint |
| **Direção** | ↑ |
| **Threshold sugerido** | Elite: múltiplos por dia; High: diário; Medium: semanal |
| **DORA** | Deployment Frequency |
| **Revela** | Cadência de entrega e capacidade do pipeline |

#### M-03 — Change Failure Rate (DORA)

| Atributo | Valor |
|---|---|
| **Categoria** | Quality |
| **Definição** | Porcentagem de Promotes que resultam em rollback ou incidente em produção |
| **Fórmula** | `COUNT(rollbacks + incidents pós-promote) / COUNT(total promotes)` no período |
| **Unidade** | percentage |
| **Direção** | ↓ |
| **Threshold sugerido** | Elite: < 5%; High: 5-10%; Medium: 10-15% |
| **DORA** | Change Failure Rate |
| **Revela** | Qualidade dos gates de Validate e Promote |

#### M-04 — Time to Restore Service (DORA)

| Atributo | Valor |
|---|---|
| **Categoria** | Stability |
| **Definição** | Tempo desde detecção de incidente pós-promote até restauração do serviço |
| **Fórmula** | Derivado do Release Trail: `incident_resolved_at - incident_detected_at` |
| **Unidade** | Horas |
| **Direção** | ↓ |
| **Threshold sugerido** | Elite: < 1 hora; High: < 1 dia |
| **DORA** | Time to Restore Service |
| **Revela** | Efetividade do rollback plan e maturidade operacional |

---

### 9.2 Métricas de Tempo por Fase

#### M-05 — Average Time in Hacking

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Tempo médio que itens passam na fase Hacking (implementação) |
| **Fórmula** | `AVG(Finishing Started At - Hacking Started At)` para itens Done no período |
| **Unidade** | Horas |
| **Direção** | ↓ (redução indica melhor refinamento de escopo ou maior familiaridade com o domínio) |
| **Threshold sugerido** | Baseline por OBC; anomalia quando > 2x a mediana do histórico |
| **Revela** | Complexidade de implementação; se o OBC estava bem refinado |

#### M-06 — Average Time in Finishing

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Tempo médio na fase Finishing (gates + PR) |
| **Fórmula** | `AVG(Ship Started At - Finishing Started At)` para itens Done |
| **Unidade** | Horas |
| **Direção** | ↓ |
| **Threshold sugerido** | > 4 horas médio = investigar gate failures frequentes |
| **Revela** | Eficiência dos quality gates; acúmulo de debt técnico |

#### M-07 — Average Time in Validating

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Tempo médio na fase Validate (staging, SLO, BDD) |
| **Fórmula** | `AVG(Promote Started At - Validate Started At)` para itens Done |
| **Unidade** | Horas |
| **Direção** | ↓ |
| **Threshold sugerido** | > 8 horas = investigar complexidade de staging ou inadequação de BDD |
| **Revela** | Representatividade do ambiente de staging; adequação dos critérios BDD |

#### M-08 — Average Waiting Time (PR Review)

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Tempo médio que itens passam em `Delivery Status = Waiting` entre Finishing e Shipping (aguardando PR review) |
| **Fórmula** | `AVG(Ship Started At - Waiting Since)` para itens que passaram por WAITING em Finishing |
| **Unidade** | Horas |
| **Direção** | ↓ |
| **Threshold sugerido** | > 24 horas = gargalo de review capacity |
| **Revela** | Capacidade de review da equipe; potencial gargalo antes de CI Async |

---

### 9.3 Métricas de Qualidade e Rework

#### M-09 — Rework Rate

| Atributo | Valor |
|---|---|
| **Categoria** | Rework |
| **Definição** | Porcentagem de itens que retornaram ao Hacking ao menos uma vez |
| **Fórmula** | `COUNT(items WHERE Rework Count > 0) / COUNT(all items Done)` no período |
| **Unidade** | percentage |
| **Direção** | ↓ |
| **Threshold sugerido** | < 10% = saudável; 10-25% = atenção; > 25% = investigar critérios de aceite |
| **Revela** | Qualidade dos critérios de aceite (BDD) e dos quality gates locais |

#### M-10 — Gate Pass Rate por Gate

| Atributo | Valor |
|---|---|
| **Categoria** | Quality |
| **Definição** | Porcentagem de itens que passam no gate na primeira tentativa, por tipo de gate |
| **Fórmula** | `COUNT(items WITHOUT gate-failed:<gate> label) / COUNT(all items)` por gate |
| **Unidade** | percentage |
| **Direção** | ↑ |
| **Threshold sugerido** | < 85% de pass rate no primeiro attempt = gate problemático |
| **Revela** | Qual gate específico gera mais rework; onde investir em qualidade |

#### M-11 — Validate Gate Failure Rate

| Atributo | Valor |
|---|---|
| **Categoria** | Quality |
| **Definição** | Porcentagem de itens que falham no Validate (ambiente de staging) após passar em todos os gates locais |
| **Fórmula** | `COUNT(items BLOCKED in Validating) / COUNT(items that reached Validating)` |
| **Unidade** | percentage |
| **Direção** | ↓ |
| **Threshold sugerido** | > 15% = gaps nos gates locais; > 30% = trigger de Assessment |
| **Revela** | Divergência entre ambiente local e staging; adequação da suíte de acceptance |

---

### 9.4 Métricas de Estabilidade

#### M-12 — Pipeline Failure Rate

| Atributo | Valor |
|---|---|
| **Categoria** | Stability |
| **Definição** | Frequência de falhas de pipeline CI por sprint |
| **Fórmula** | `COUNT(items WITH gate-failed:* label) / COUNT(all items)` no período |
| **Unidade** | percentage |
| **Direção** | ↓ |
| **Threshold sugerido** | > 20% = pipeline instável; investigar infra ou testes flaky |
| **Revela** | Estabilidade da infraestrutura de CI; qualidade da suíte de testes |

#### M-13 — Rollback Rate

| Atributo | Valor |
|---|---|
| **Categoria** | Stability |
| **Definição** | Porcentagem de Promotes que resultaram em rollback (retorno do artefato de produção para versão anterior) |
| **Fórmula** | `COUNT(Release Trail entries WITH type: Rollback) / COUNT(Promotes)` |
| **Unidade** | percentage |
| **Direção** | ↓ |
| **Threshold sugerido** | > 5% = risco sistêmico de qualidade de entrega |
| **Revela** | Efetividade da fase Validate como proxy de produção |

---

### 9.5 Métricas de Previsibilidade

#### M-14 — Cycle Time Variance

| Atributo | Valor |
|---|---|
| **Categoria** | Predictability |
| **Definição** | Variância do Lead Time for Changes entre itens concluídos no período |
| **Fórmula** | `STDEV(Promoted At - Hacking Started At)` para itens Done no período |
| **Unidade** | Horas (desvio padrão) |
| **Direção** | ↓ |
| **Threshold sugerido** | Variância > 3x a mediana = fluxo imprevisível |
| **Revela** | Consistência do processo; quanto se pode confiar nas estimativas |

#### M-15 — Phase Time Predictability

| Atributo | Valor |
|---|---|
| **Categoria** | Predictability |
| **Definição** | Razão entre tempo real em Hacking vs. tempo estimado (quando estimativa está disponível no Iteration Plan) |
| **Fórmula** | `AVG(actual_hacking_time / estimated_hacking_time)` para itens com estimativa |
| **Unidade** | ratio |
| **Direção** | Próximo de 1.0 (1.0 = perfeito; > 1.5 = consistentemente subestimado) |
| **Threshold sugerido** | > 1.5 = refinement insuficiente antes de entrar em Delivery |
| **Revela** | Qualidade do refinement no Iteration Backlog |

---

### 9.6 Métricas de Throughput e Profundidade de Fila

#### M-16 — Throughput

| Atributo | Valor |
|---|---|
| **Categoria** | Throughput |
| **Definição** | Número de itens promovidos para produção por sprint |
| **Fórmula** | `COUNT(items WHERE Delivery Status = Done AND Promoted At >= sprint_start)` |
| **Unidade** | count / sprint |
| **Direção** | ↑ (estável ou crescente) |
| **Threshold sugerido** | Baseline por equipe; queda > 30% por 2 sprints consecutivos = investigar |
| **Revela** | Capacidade de entrega da equipe no período |

#### M-17 — Queue Depth per Phase

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Número de itens acumulados em cada fase em um dado momento |
| **Fórmula** | `COUNT(items BY Delivery Phase WHERE Delivery Status != Done)` |
| **Unidade** | count (por fase) |
| **Direção** | ↓ (concentração em uma fase = gargalo) |
| **Threshold sugerido** | Concentração de > 40% dos itens ativos em uma única fase = gargalo |
| **Revela** | Onde o fluxo está represado; fase gargalo do sistema |

#### M-18 — Flow Efficiency

| Atributo | Valor |
|---|---|
| **Categoria** | Flow |
| **Definição** | Porcentagem do Lead Time em que o item estava em estado ativo (não Waiting, não Blocked) |
| **Fórmula** | `(Lead Time - Total Waiting/Blocked Time) / Lead Time` por item |
| **Unidade** | percentage |
| **Direção** | ↑ |
| **Threshold sugerido** | < 25% = maior parte do tempo é espera; > 40% = bom; > 70% = excelente |
| **Revela** | Eficiência real do fluxo; quanto tempo o item espera vs. é trabalhado |

---

## 10. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Timestamps por fase não preenchidos consistentemente por agentes ou equipe | Alta | Crítico — invalida todas as métricas de tempo | Definir preenchimento automático via hook de transição de estado no GitHub Project + Check DIL-DEL-005 |
| Drift entre `OBC State` no Project e estado real no Markdown | Média | Alto — representa incorretamente o estado do OBC | DIL-DEL-006 detecta periodicamente; Workspace Reconciliation corrige |
| Rework Count não incrementado em retornos ao Hacking | Média | Médio — subestima rework rate | Diligence Sync deve detectar regressão de fase e incrementar automaticamente |
| Equipe contorna o modelo usando labels ou texto livre em vez de Fields canônicos | Média | Alto — Diligence perde observabilidade | Workspace Reconciliation verifica Fields vs. spec periodicamente; DIL-WSP-001 |
| Novos Checks DIL-DEL-* adicionados ao catalog.yaml sem atualizar manifest.yaml | Baixa | Médio — agentes não encontram os Checks | Garantir que catalog.yaml seja a única fonte de verdade para Checks; agents leem o catalog diretamente |
| Assessment recommendation (DIL-DEL-010) ignorada por falta de owner | Média | Alto — OBC envelhece sem reassessment | Escalação obrigatória para Product Owner quando Finding fica aberto > 10 dias |
| Fields Knowledge Space editados manualmente no GitHub criando drift | Média | Alto — GitHub sobrescreve a verdade do Markdown | Política explícita de read-only + DIL-WSP-001 detecta drift |
| Métricas DORA derivadas do GitHub e não do CI/CD tool real | Alta | Médio — aproximação, não medição exata | Documentar como proxy; future work: integrar com GitHub Actions timestamps |

---

## 11. Próximos Passos

Os próximos passos são propostas — nenhuma ação é tomada por este documento.

### Imediato (antes de implementar qualquer coisa)

1. **Validar o modelo de estados** com a equipe de engenharia e Product Owner — especialmente BLOCKED vs. WAITING e o mecanismo de Rework Count
2. **Decidir sobre timestamps por fase** — mecanismo de coleta: manual, GitHub Action, ou hook de Diligence Sync
3. **Aprovar os 9 novos Checks propostos** (DIL-DEL-001 a DIL-DEL-009) antes de adicionar ao `catalog.yaml`
4. **Confirmar o GitHub Project `ProdOps — Delivery`** como projeto separado do Project existente de produto, ou como Views adicionais no Project existente

### Curto prazo (após aprovação)

5. **Criar GitHub Project `ProdOps — Delivery`** com os Fields e Labels propostos via Workspace Reconciliation
6. **Adicionar os 9 novos Checks ao `catalog.yaml`** seguindo o schema existente
7. **Atualizar `manifest.yaml`** com referência ao novo Project e aos novos Checks
8. **Iniciar coleta de métricas baseline** para M-01 a M-18 com os dados atuais disponíveis

### Médio prazo

9. **Implementar DIL-DEL-003** (Item parado) como primeira automação da Diligence Async sobre Delivery
10. **Validar M-01 (Lead Time)** com dados reais de ao menos 1 sprint
11. **Calibrar os thresholds das métricas** com base no baseline coletado

---

## 12. O que NÃO mudou (guardrails)

Este documento é uma proposta. As seguintes decisões são imutáveis e este documento as respeitou integralmente:

| Decisão imutável | Como foi respeitada |
|---|---|
| Existem exatamente cinco jornadas | Nenhuma sexta jornada foi proposta |
| Diligence é a guardiã da COR | A proposta posiciona Diligence como observadora e guardiã — não como executora de Delivery |
| Diligence NÃO conduz Delivery | Os novos Checks detectam, observam e recomendam — nunca executam fases de Delivery |
| GitHub Projects/Issues = Canonical Operational Representation | O modelo proposto usa exclusivamente GitHub Project e Issues; Jira/ADO/Linear não são mencionados como alternativas |
| Princípios de knowledge-vs-execution.md são finais | Knowledge Space Fields são READ-ONLY no GitHub; o Markdown é sempre a fonte de verdade |
| Delivery começa com entrada no Iteration Plan | O estado `BOOTSTRAPPING` é o primeiro estado — corresponde exatamente à entrada no Iteration Plan |
| Delivery termina com promoção para produção | O estado `DONE` corresponde exatamente ao Promote completado com OBC → Operational |
| Não criar Skills, alterar manifests, templates ou reorganizar arquivos | Este documento apenas propõe — nenhum arquivo foi modificado exceto a criação deste |

---

*Fim do documento — versão 1.0-RASCUNHO — 2026-07-24*
