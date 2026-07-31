# Modelo de Eventos da Jornada Delivery — Análise Arquitetural
# ProdOps Framework

> Data: 2026-07-24
> Tipo: Proposta arquitetural — análise e proposta
> Status: RASCUNHO — aguardando revisão e aprovação
> Pergunta central: Estados, Eventos ou ambos como fonte de verdade operacional?

---

## 1. Executive Summary

**Veredicto:** **Eventos como primários + Estados como derivados** é o modelo correto para a
representação operacional da Jornada Delivery no ProdOps Framework.

Este documento investiga se um modelo orientado a eventos é superior ao modelo baseado em estados
proposto no documento anterior (`documentation-review-delivery-operational-representation.md`). A
conclusão é que os dois modelos não são opostos — são complementares, com papéis distintos e
igualmente necessários.

**O estado correto do modelo operacional da Delivery:**

```
Eventos (commit em GitHub Issue comment)  ←  fonte primária da verdade operacional
    ↓
Estado derivado (Fields do GitHub Project)  ←  projeção legível do último evento
    ↓
Views do GitHub Project  ←  Kanban/tabela sobre o estado atual
    ↓
Diligence  ←  verifica coerência: estado consistente com último evento? evento esperado ocorreu?
```

**Justificativa em três linhas:**
1. O documento anterior já era um modelo de eventos implícito: timestamps por fase são eventos sem nome e sem estrutura.
2. Estados sem eventos não suportam DORA, rework, causalidade ou auditoria. Eventos sem estados não são visualizáveis em Kanban. A combinação resolve ambos.
3. GitHub tem capacidade nativa suficiente para o modelo híbrido: Issue comments (eventos), Fields (estado atual), Timeline (eventos de sistema). Nenhuma infraestrutura externa é necessária para o MVP.

---

## 2. Fontes Analisadas

| Documento | Papel nesta análise |
|---|---|
| `prodops/framework/ontology.md` | Hierarquia Journey → Cycle → Phase; Capability vs. Skill |
| `prodops/framework/knowledge-vs-execution.md` | Princípios fundamentais do modelo operacional |
| `prodops/framework/glossary.md` | Vocabulário canônico (943 linhas) |
| `prodops/exec/manifest.yaml` | Pipeline, gates, paths, vocabulário canônico |
| `prodops/framework/execution-mapping/work-item-schema.md` | Schema de Work Item; enums operacionais |
| `prodops/framework/journeys/delivery/README.md` | Responsabilidade e entradas da Delivery |
| `prodops/framework/journeys/delivery/ci-sync.md` | CI Sync: Bootstrap → Hack → Sync → Finish |
| `prodops/framework/journeys/delivery/ci-async.md` | CI Async: Ship → Validate → Promote |
| `prodops/skills/bootstrap/SKILL.md` | Skill Bootstrap: inputs, flow, guardrails, post-conditions |
| `prodops/skills/hack/SKILL.md` | Skill Hack: steps (start/tdd/commit), quality gates |
| `prodops/skills/hack/steps/start/SKILL.md` | Hack Start: git flow, branch creation |
| `prodops/skills/hack/steps/tdd/SKILL.md` | Hack TDD: Red→Green→Yellow, artifact closure |
| `prodops/skills/hack/steps/commit/SKILL.md` | Hack Commit: conventional commits, gates |
| `prodops/skills/sync/SKILL.md` | Skill Sync: rebase e align |
| `prodops/skills/finish/SKILL.md` | Skill Finish: quality gates, PR preparation |
| `prodops/skills/ship/SKILL.md` | Skill Ship: build, publish, deploy |
| `prodops/skills/validate/SKILL.md` | Skill Validate: runtime evidence, SLO, OBC |
| `prodops/skills/promote/SKILL.md` | Skill Promote: approval, Release Trail, close |
| `prodops/skills/downstream/SKILL.md` | Downstream orchestrator: readiness, full flow |
| `prodops/framework/journeys/diligence/checks/catalog.yaml` | 14 Checks ativos catalogados |
| `prodops/documentation-review-product-lifecycle-foundation.md` | Análise anterior: lifecycle da Business Intent |
| `prodops/documentation-review-delivery-operational-representation.md` | Análise anterior: modelo de estados, GitHub Project, 18 métricas |

---

## 3. Baseline: O Modelo Atual Baseado em Estados

### 3.1 O que o documento anterior propôs

O documento `documentation-review-delivery-operational-representation.md` propôs:

**Modelo de estados com nove posições:**
```
Bootstrapping → Hacking → Syncing → Finishing → Shipping → Validating → Promoting → Done
     ↕                ↕           ↕
  Blocked / Waiting (transversal)
```

**Fields do GitHub Project:**
- `Delivery Phase`: estado atual da fase (Bootstrapping, Hacking, ... Promoting)
- `Delivery Status`: Active | Waiting | Blocked | Done
- `Cycle`: CI Sync | CI Async
- `Phase Entered At`: data de entrada na fase atual
- `Blocked Reason`, `Waiting Since`, `Rework Count`, `Gate Results`, `PR Link`
- Timestamps por fase: `Bootstrap Started At`, `Hacking Started At`, ... `Promoted At`

**Catálogo de 18 métricas deriváveis** de combinações de timestamps dos Fields.

**Seis novos Checks propostos** (DIL-DEL-001 a DIL-DEL-006) para detectar divergências operacionais.

### 3.2 Limitações estruturais do modelo puro de estados

| Limitação | Impacto operacional |
|---|---|
| Sem histórico: não há como saber como o item chegou ao estado atual | Causa raiz de bloqueios não é investigável sem diário manual |
| Sem causalidade: estado mudou, mas por quê? | Diligence não pode distinguir transição normal de rework forçado |
| Sem sequência: o item foi Finishing antes de Hacking? | Inversões de ordem não são detectáveis |
| Rework é um contador, não uma trilha: `Rework Count = 2` mas quais foram os retornos? | Assessment não pode correlacionar rework com gate falhos específicos |
| Gate failure é um campo de texto (`Gate Results`): sem estrutura | Diligence não pode agregar "lint falhou N vezes" por período |
| Rollback pós-produção: qual estado? `Shipping` de volta? | Não existe semântica clara para regressão pós-Promote |
| Timestamps por fase requerem 7 Fields separados | Cada fase que não existe ainda é um Field que pode permanecer vazio |
| Diligence deve fazer polling do estado atual | Não é notificada quando algo muda — precisa escanear periodicamente |
| Bloqueio expirado sem resolução: como saber quando foi declarado? | `Phase Entered At` não é o mesmo que `Blocked Since` |

### 3.3 O que o modelo de estados resolve bem

O modelo de estados é necessário e suficiente para:
- Visualização Kanban: "onde estão os itens agora?"
- Filtros de View: `Delivery Phase = Finishing` e `Delivery Status = Blocked`
- Acompanhamento diário pelo time (Daily Standup)
- Diligence Async: verificação do estado atual via `gh project` API
- Bloqueio de gates: "não pode Promote sem todos os campos preenchidos"

---

## 4. Hipótese: Modelo Orientado a Eventos

### 4.1 A hipótese central

> Se cada transição significativa na Jornada Delivery for registrada como um evento estruturado
> (com timestamp, produtor, fase, motivo e evidência), então:
> - O estado atual pode ser *derivado* do último evento, tornando os Fields consistentes por construção
> - As métricas DORA tornam-se calculáveis diretamente de timestamps de eventos, sem Fields adicionais
> - O rework, o bloqueio e a causalidade tornam-se registros de primeira classe, não contadores
> - A Diligence pode verificar padrões temporais ("evento esperado não ocorreu em 48h") impossíveis com estado puro
> - A auditoria torna-se completa: toda mudança tem autor, motivo e timestamp

### 4.2 Definição de evento para este modelo

Um **evento de Delivery** é um registro imutável, com timestamp, que documenta uma transição ou
observação significativa durante a execução da Jornada Delivery para um item específico.

Propriedades de um evento:
- **Imutabilidade:** eventos não são editados após registro. Erros geram eventos de correção.
- **Ordenação:** eventos têm timestamp; a sequência importa.
- **Produtor explícito:** quem ou o que gerou o evento (humano, agente, pipeline, Diligence).
- **Fase de contexto:** a qual fase da Delivery o evento pertence.
- **Efeito de estado:** qual transição de campo o evento causa (se causar).

---

## 5. Análise Crítica: Estado vs Evento

### 5.1 Comparação direta

| Dimensão | Modelo de estados puro | Modelo de eventos puro | Modelo híbrido |
|---|---|---|---|
| **Visualização Kanban** | Nativo — Fields alimentam Views | Requer derivação em tempo real | Estado derivado → alimenta Views |
| **Lead time / Cycle time** | Exige timestamps por fase (N fields) | Derivado diretamente de eventos | Derivado de eventos; Fields opcionais |
| **Rework detection** | Contador sem trilha | Sequência explícita de eventos | Sequência de eventos + counter derivado |
| **Causalidade** | Ausente | Explícita (cada evento tem razão) | Explícita nos eventos |
| **Auditoria** | Estado atual, sem histórico | Trilha completa | Trilha de eventos + estado legível |
| **Diligence — verificação atual** | Simples (poll Fields) | Requer derivação de estado | Poll Fields OU verifica evento mais recente |
| **Diligence — verificação temporal** | Impossível sem timestamps | Nativo (event timestamp) | Nativo via eventos |
| **Rollback semântico** | Ambíguo (qual estado?) | Evento explícito (`Ship.RollbackTriggered`) | Evento + estado derivado |
| **Implementação no GitHub** | Fields nativos → simples | Comments com schema → moderado | Comments + Fields → moderado |
| **Disciplina operacional** | Baixa (apenas atualizar campo) | Alta (emitir evento estruturado) | Moderada (evento gera estado automaticamente) |
| **Assessment signals** | Baseados em estado pontual | Baseados em padrões de eventos | Padrões de eventos → sinais ricos |
| **DORA metrics** | Exigem Fields de timestamp | Derivadas de eventos | Derivadas de eventos; Fields como cache |

### 5.2 Forças e fraquezas: estado puro

**Forças:**
- GitHub Projects são nativamente orientados a estado (Fields, Views, filtros)
- Simples para humanos: olhar um Board e entender onde está cada item
- Workspace Reconciliation (Capability Diligence) já opera sobre state fields
- Baixa barreira de adoção: time apenas atualiza um campo
- API GitHub Projects V2 suporta leitura de Fields diretamente

**Fraquezas:**
- Sem história: não há como responder "quanto tempo ficou em Hacking?" sem timestamps adicionais
- Sem causalidade: a mudança de `Hacking → Syncing` não captura se foi primeira vez ou quinto rework
- Rework invisível: `Rework Count = 3` não diz quais gates falharam em cada retorno
- Gates binários: `lint:FAIL` no campo `Gate Results` não tem timestamp nem frequência
- Rollback ambíguo: pós-promoção, o item deveria voltar para qual estado?
- Bloqueio sem duração: `Phase Entered At` ≠ `Blocked Since` — não é possível saber quando o bloqueio começou
- Metrics dependem de N Fields separados: cada métrica adicional requer um Field novo

### 5.3 Forças e fraquezas: eventos puro

**Forças:**
- Trilha completa e imutável: toda transição registrada com timestamp, produtor e razão
- DORA trivialmente calculável: `lead_time = Promote.Completed.timestamp - Bootstrap.Started.timestamp`
- Rework explícito: sequência de eventos mostra exatamente qual fase originou cada retorno
- Causalidade nativa: `Hack.TDDCycleCompleted` → `Hack.CommitCreated` é uma relação de causa-efeito
- Diligence temporal: "Bootstrap.Started há > 48h sem Hack.Started" é um Check possível
- Assessment pode consumir padrões de eventos ao longo de releases, não apenas estado pontual

**Fraquezas:**
- GitHub Issues não têm event log estruturado nativo — eventos precisam ser escritos em comments
- Disciplina alta: toda fase deve emitir o evento correto, com o schema correto
- Estado requer derivação: para responder "qual o estado atual?" é preciso ler o último evento relevante
- Visualização Kanban requer estado derivado — não basta ter eventos para mostrar um Board
- Agentes podem emitir eventos inconsistentes se o schema não for rigoroso
- Comments são mutáveis (editáveis, deletáveis) — eventos em comments podem ser corrompidos

### 5.4 Análise do modelo híbrido

O modelo híbrido resolve as fraquezas de ambos:

```
EVENTO (emitido)
    ↓
Escrito como comment estruturado no GitHub Issue (imutável na prática)
    ↓
Agente/Diligence lê o evento e deriva o novo estado
    ↓
Estado atualizado nos Fields do GitHub Project (observável pelo time)
    ↓
Views do Kanban refletem o estado atual
    ↓
Diligence verifica: estado ↔ último evento? evento esperado ocorreu no prazo?
```

**Regra fundamental do modelo híbrido:**
> O Field `Delivery Phase` é sempre derivado do último evento com `state_change: true`.
> Nenhum Field é atualizado diretamente — toda mudança de estado começa com a emissão de um evento.

---

## 6. Catálogo Canônico de Eventos

### 6.1 Convenções de nomenclatura

- **Formato:** `Phase.EventName` em PascalCase
- **Fase de contexto:** Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework, Blocking
- **Produtor:** `Human` (engenheiro, PM, Tech Lead, revisor) | `System` (pipeline, git, CI) | `Agent` (Claude Code, agente de automação) | `Diligence` (varredura automática)
- **ID:** `DEL-EVT-NNN` sequencial

### 6.2 Catálogo completo

#### FASE: BOOTSTRAP

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-001 | Bootstrap.Declared | System/Agent (Downstream readiness) | `Delivery Phase → Bootstrapping` | M-01: Delivery Start | Não |
| DEL-EVT-002 | Bootstrap.Started | Human (Engineer) | Confirma Bootstrapping | M-02: Bootstrap Start | Não |
| DEL-EVT-003 | Bootstrap.DependenciesInstalled | Agent | Nenhum | — | Não |
| DEL-EVT-004 | Bootstrap.SmokeGatePassed | System (smoke cmd) | Nenhum | — | Não |
| DEL-EVT-005 | Bootstrap.SmokeGateFailed | System (smoke cmd) | `Delivery Status → Blocked` | M-09: Gate failure | Sim: DIL-DEL-SmokeGate |
| DEL-EVT-006 | Bootstrap.Completed | Agent | `Delivery Phase → Hacking` | M-02: Bootstrap End | Não |
| DEL-EVT-007 | Bootstrap.EnvironmentBlocker | Human (Engineer) | `Delivery Status → Blocked` | M-09: Blocker start | Sim |

#### FASE: HACK

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-008 | Hack.Started | Human/Agent (hack start) | Confirma Hacking | M-03: Hack Start | Não |
| DEL-EVT-009 | Hack.BranchCreated | System (git) | Nenhum | — | Não |
| DEL-EVT-010 | Hack.RedBarConfirmed | Agent/Human | Nenhum | — | Não |
| DEL-EVT-011 | Hack.GreenBarConfirmed | Agent/Human | Nenhum | — | Não |
| DEL-EVT-012 | Hack.TDDCycleCompleted | Agent/Human | Nenhum | — | Não |
| DEL-EVT-013 | Hack.CommitCreated | System (git hook) | Nenhum | — | Não |
| DEL-EVT-014 | Hack.ArtifactsUpdated | Agent (tdd/yellow) | Nenhum | — | Não |
| DEL-EVT-015 | Hack.ImpedimentDeclared | Human (Engineer) | `Delivery Status → Blocked` | M-10: Blocker start | Sim |
| DEL-EVT-016 | Hack.ImpedimentResolved | Human (Engineer) | `Delivery Status → Active` | M-10: Blocker end | Não (fecha Finding) |
| DEL-EVT-017 | Hack.Completed | Agent/Human | `Delivery Phase → Syncing` | M-03: Hack End | Não |

#### FASE: SYNC

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-018 | Sync.RebaseStarted | Agent/Human | Confirma Syncing | — | Não |
| DEL-EVT-019 | Sync.ConflictDetected | System (git) | Nenhum | — | Sim (se persistente) |
| DEL-EVT-020 | Sync.ConflictResolved | Human | Nenhum | — | Não |
| DEL-EVT-021 | Sync.RebaseCompleted | Agent/System | Nenhum | — | Não |
| DEL-EVT-022 | Sync.AlignStarted | Agent/Human | Nenhum | — | Não |
| DEL-EVT-023 | Sync.ArtifactsAligned | Agent | Nenhum | — | Não |
| DEL-EVT-024 | Sync.UnresolvableConflict | Human | `Delivery Phase → Hacking` | M-11: Rework | Sim |
| DEL-EVT-025 | Sync.Completed | Agent/Human | `Delivery Phase → Finishing` | — | Não |

#### FASE: FINISH

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-026 | Finish.Started | Agent/Human | Confirma Finishing | M-04: Finish Start | Não |
| DEL-EVT-027 | Finish.LintGatePassed | System (npm lint) | Nenhum | M-08: Gate pass | Não |
| DEL-EVT-028 | Finish.LintGateFailed | System (npm lint) | Nenhum | M-08: Gate fail | Sim |
| DEL-EVT-029 | Finish.AcceptanceGatePassed | System (test:acceptance) | Nenhum | M-08: Gate pass | Não |
| DEL-EVT-030 | Finish.AcceptanceGateFailed | System (test:acceptance) | `Delivery Status → Blocked` | M-08: Gate fail | Sim |
| DEL-EVT-031 | Finish.BuildGatePassed | System (npm build) | Nenhum | M-08: Gate pass | Não |
| DEL-EVT-032 | Finish.BuildGateFailed | System (npm build) | `Delivery Status → Blocked` | M-08: Gate fail | Sim |
| DEL-EVT-033 | Finish.NoMocksGatePassed | System (grep) | Nenhum | — | Não |
| DEL-EVT-034 | Finish.NoMocksGateFailed | System (grep) | `Delivery Status → Blocked` | — | Sim |
| DEL-EVT-035 | Finish.PROpened | System (GitHub) | Nenhum | M-05: PR Open | Não |
| DEL-EVT-036 | Finish.ReviewRequested | Human (Engineer) | `Delivery Status → Waiting` | M-13: Review Start | Não |
| DEL-EVT-037 | Finish.ReviewApproved | Human (Reviewer) | `Delivery Status → Active` | M-13: Review End | Não |
| DEL-EVT-038 | Finish.ChangesRequested | Human (Reviewer) | `Delivery Phase → Hacking` | M-11: Rework | Sim (condicional) |
| DEL-EVT-039 | Finish.GateFailureRework | Human/Agent | `Delivery Phase → Hacking` | M-11: Rework | Sim |
| DEL-EVT-040 | Finish.Completed | Agent/Human | `Delivery Phase → Shipping` | M-04: Finish End | Não |

#### FASE: SHIP

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-041 | Ship.Started | System (CI pipeline) | `Delivery Phase → Shipping` | M-05: Ship Start | Não |
| DEL-EVT-042 | Ship.BuildStarted | System | Nenhum | — | Não |
| DEL-EVT-043 | Ship.BuildCompleted | System | Nenhum | — | Não |
| DEL-EVT-044 | Ship.BuildFailed | System (pipeline) | `Delivery Status → Blocked` | M-09: Pipeline fail | Sim |
| DEL-EVT-045 | Ship.ArtifactPublished | System (registry) | Nenhum | — | Não |
| DEL-EVT-046 | Ship.DeployStarted | System (pipeline) | Nenhum | — | Não |
| DEL-EVT-047 | Ship.DeployCompleted | System | Nenhum | — | Não |
| DEL-EVT-048 | Ship.DeployFailed | System (pipeline) | `Delivery Status → Blocked` | M-09: Deploy fail | Sim |
| DEL-EVT-049 | Ship.RollbackTriggered | Human/System | `Delivery Status → Blocked` | M-12: Rollback | Sim |
| DEL-EVT-050 | Ship.RollbackCompleted | Human/System | `Delivery Status → Active` | M-12: Rollback end | Não |
| DEL-EVT-051 | Ship.Completed | System/Agent | `Delivery Phase → Validating` | M-05: Ship End | Não |

#### FASE: VALIDATE

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-052 | Validate.Started | Human/Agent | `Delivery Phase → Validating` | M-06: Validate Start | Não |
| DEL-EVT-053 | Validate.SmokeTestsPassed | System | Nenhum | — | Não |
| DEL-EVT-054 | Validate.SmokeTestsFailed | System | `Delivery Status → Blocked` | M-09: Gate fail | Sim |
| DEL-EVT-055 | Validate.BDDScenariosValidated | System/Human | Nenhum | M-14: BDD pass | Não |
| DEL-EVT-056 | Validate.BDDScenariosFailed | System/Human | `Delivery Phase → Hacking` | M-11: Rework + M-14 | Sim |
| DEL-EVT-057 | Validate.SLOValidated | System/Human | Nenhum | M-15: SLO pass | Não |
| DEL-EVT-058 | Validate.SLOViolationDetected | System | `Delivery Status → Blocked` | M-15: SLO fail | Sim |
| DEL-EVT-059 | Validate.IncidentSignalDetected | System/Human | `Delivery Status → Blocked` | M-12: Incident | Sim: Critical |
| DEL-EVT-060 | Validate.EvidenceRecorded | Human/Agent | Nenhum | — | Não |
| DEL-EVT-061 | Validate.GatePassed | Human/Agent | Nenhum | M-06: Gate pass | Não |
| DEL-EVT-062 | Validate.GateFailed | Human/Agent | `Delivery Phase → Hacking` | M-11: Rework | Sim |
| DEL-EVT-063 | Validate.Completed | Human/Agent | `Delivery Phase → Promoting` | M-06: Validate End | Não |

#### FASE: PROMOTE

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-064 | Promote.Started | Human/Agent | `Delivery Phase → Promoting` | M-07: Promote Start | Não |
| DEL-EVT-065 | Promote.GatesVerified | Human/Agent | Nenhum | — | Não |
| DEL-EVT-066 | Promote.ApprovalRequested | Human (Engineer) | `Delivery Status → Waiting` | M-16: Approval wait | Não |
| DEL-EVT-067 | Promote.Approved | Human (PM + Tech Lead) | `Delivery Status → Active` | M-16: Approval end | Não |
| DEL-EVT-068 | Promote.Rejected | Human (PM + Tech Lead) | `Delivery Status → Blocked` | — | Sim |
| DEL-EVT-069 | Promote.DeployedToProduction | System (pipeline) | Nenhum | M-07: Deploy prod | Não |
| DEL-EVT-070 | Promote.ReleaseTrailRecorded | Human/Agent | Nenhum | — | Não |
| DEL-EVT-071 | Promote.OBCTransitioned | Human/Agent | Nenhum (OBC fica em Markdown) | — | Não |
| DEL-EVT-072 | Promote.WorkItemClosed | System (GitHub) | `Delivery Status → Done` | M-01: Delivery End | Não |
| DEL-EVT-073 | Promote.Completed | Human/Agent | `Delivery Phase → Done` | M-07: Promote End | Não |

#### EVENTOS TRANSVERSAIS: REWORK

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-074 | Rework.Declared | Human/Agent | `Delivery Phase → Hacking` + `Rework Count + 1` | M-11: Rework event | Sim (se Rework Count ≥ 3) |
| DEL-EVT-075 | Rework.OriginRecorded | Human/Agent | Nenhum | M-11: Rework root cause | Não |

#### EVENTOS TRANSVERSAIS: BLOCKING

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-076 | Blocking.ImpedimentDeclared | Human (Engineer) | `Delivery Status → Blocked` | M-10: Block start | Sim (se > 24h) |
| DEL-EVT-077 | Blocking.ImpedimentResolved | Human (Engineer) | `Delivery Status → Active` | M-10: Block end | Não (fecha Finding) |
| DEL-EVT-078 | Blocking.WaitingDeclared | Human (Engineer) | `Delivery Status → Waiting` | M-13: Wait start | Não |
| DEL-EVT-079 | Blocking.WaitingResolved | Human/System | `Delivery Status → Active` | M-13: Wait end | Não |

#### EVENTOS DE DILIGENCE (gerados pela Diligence, não pelo time)

| ID | Evento | Produtor | State Change | Metric Anchor | Finding? |
|---|---|---|---|---|---|
| DEL-EVT-080 | Diligence.StaleItemDetected | Diligence (Async Scan) | Nenhum | — | Sim |
| DEL-EVT-081 | Diligence.ReworkPatternDetected | Diligence (Async Scan) | Nenhum | — | Sim |
| DEL-EVT-082 | Diligence.MissingEventDetected | Diligence (Async Scan) | Nenhum | — | Sim |
| DEL-EVT-083 | Diligence.StateEventInconsistency | Diligence (Async Scan) | Nenhum | — | Sim |

**Total: 83 eventos canônicos** (66 por fase + 4 rework + 4 blocking + 9 validate/promote humanos + 4 Diligence)

---

## 7. Detalhamento por Evento (Fases Selecionadas)

### 7.1 Bootstrap.Started (DEL-EVT-002)

| Atributo | Valor |
|---|---|
| **Event ID** | DEL-EVT-002 |
| **Nome** | Bootstrap.Started |
| **Produtor** | Human (Engineer) |
| **Fase** | Bootstrap (CI Sync) |
| **Trigger** | `/bootstrap` invocado pelo engenheiro |
| **Pre-conditions** | Item no Iteration Plan com OBC committed + BDD committed + riscos documentados + Reliability Plan (quando exigido); `Bootstrap.Declared` já emitido |
| **Post-conditions** | Agente inicia leitura de `manifest.yaml` para identificar dependências e gates |
| **Artifacts affected** | Nenhum — Bootstrap não lê nem escreve artefatos de produto |
| **Evidence** | Timestamp registrado; `Delivery Status = Active` confirmado |
| **State change** | Confirma `Delivery Phase = Bootstrapping` (já setado por Bootstrap.Declared) |
| **Metrics** | Ancora M-02 (Bootstrap Lead Time — start) |
| **Finding trigger** | Não |
| **Assessment signal** | Frequência de Bootstrap sem Completed subsequente (indica problemas de ambiente) |
| **GitHub representation** | Comment estruturado no Issue: `DEL-EVT-002 Bootstrap.Started YYYY-MM-DDTHH:MM:SSZ` |

### 7.2 Hack.TDDCycleCompleted (DEL-EVT-012)

| Atributo | Valor |
|---|---|
| **Event ID** | DEL-EVT-012 |
| **Nome** | Hack.TDDCycleCompleted |
| **Produtor** | Agent/Human |
| **Fase** | Hack (CI Sync) |
| **Trigger** | Yellow bar completo: lint passa, sem forbidden mocks, sem secrets, Event Storming e architecture atualizados, Release Trail atualizado |
| **Pre-conditions** | `Hack.GreenBarConfirmed` para o mesmo cenário BDD |
| **Post-conditions** | Código pronto para commit; todos os gates do ciclo satisfeitos; Release Trail tem evidência completa |
| **Artifacts affected** | `prodops/artifacts/event-storming/plan.json` (se evento de domínio adicionado); `prodops/artifacts/architecture/overview.md` (se estrutural); Release Trail session file |
| **Evidence** | Output do lint; output do teste green; confirmação de ausência de forbidden mocks; Release Trail updated |
| **State change** | Nenhum (estado permanece Hacking até Hack.Completed) |
| **Metrics** | Não ancora uma métrica de lead time diretamente — contribui para a contagem de ciclos TDD por item |
| **Finding trigger** | Não |
| **Assessment signal** | Número de ciclos TDD por item = proxy de complexidade; padrão de Red→Green longo = indication de dívida técnica |
| **GitHub representation** | Comment estruturado com resultado dos gates (lint: PASS, green: PASS, etc.) |

### 7.3 Finish.ChangesRequested (DEL-EVT-038)

| Atributo | Valor |
|---|---|
| **Event ID** | DEL-EVT-038 |
| **Nome** | Finish.ChangesRequested |
| **Produtor** | Human (Reviewer) |
| **Fase** | Finish (CI Sync) → causa retorno a Hack |
| **Trigger** | PR Review retorna com "Changes Requested" no GitHub |
| **Pre-conditions** | `Finish.ReviewRequested` foi emitido; PR está aberto para review |
| **Post-conditions** | Item retorna a Hacking; `Rework Count` incrementa; agente cria novo ciclo TDD |
| **Artifacts affected** | PR status update; Release Trail (nota de rework) |
| **Evidence** | URL do PR; comentário do reviewer; timestamp |
| **State change** | `Delivery Phase → Hacking`; `Delivery Status → Active`; `Rework Count + 1` |
| **Metrics** | Ancora M-11 (Rework Rate); ancora M-13 (Review Cycle Time) |
| **Finding trigger** | Sim — se `Rework Count ≥ 3` para o mesmo item, Diligence deve abrir Finding de rework excessivo |
| **Assessment signal** | Alta frequência de PR Changes Requested indica: critério de aceite mal especificado no BDD ou divergência entre BDD e implementação |
| **GitHub representation** | GitHub native PR event (automático no Timeline) + Comment estruturado emitido pelo agente: `DEL-EVT-038 Finish.ChangesRequested ...` |

### 7.4 Validate.BDDScenariosFailed (DEL-EVT-056)

| Atributo | Valor |
|---|---|
| **Event ID** | DEL-EVT-056 |
| **Nome** | Validate.BDDScenariosFailed |
| **Produtor** | System/Human (staging environment validation) |
| **Fase** | Validate (CI Async) → causa retorno a Hack |
| **Trigger** | BDD scenario(s) falha(m) no ambiente de staging |
| **Pre-conditions** | `Ship.Completed` emitido; deploy em staging confirmado |
| **Post-conditions** | Item retorna a Hacking; comportamento observado em staging torna-se novo Red Bar para próximo ciclo TDD |
| **Artifacts affected** | Release Trail (evidência de falha); BDD Feature (potencial atualização de scenario se o comportamento real revelou gap de especificação) |
| **Evidence** | Output do test runner em staging; URL de log; cenário(s) falhados identificados |
| **State change** | `Delivery Phase → Hacking`; `Delivery Status → Active`; `Rework Count + 1` |
| **Metrics** | Ancora M-11 (Rework Rate); M-14 (BDD pass rate); M-09 (CI gate failure rate) |
| **Finding trigger** | Sim — sempre abre Finding: BDD failure in staging indica que gates locais não detectaram o problema. Severity = `High` (escapou de lint + acceptance local). |
| **Assessment signal** | Padrão de BDD failure em staging indica: ou cobertura de acceptance local insuficiente, ou divergência entre ambiente local e staging. Ambos são sinais para Assessment de confiabilidade. |
| **GitHub representation** | Comment estruturado com cenário falhado + link para log de staging + Finding ID gerado |

### 7.5 Promote.Approved (DEL-EVT-067)

| Atributo | Valor |
|---|---|
| **Event ID** | DEL-EVT-067 |
| **Nome** | Promote.Approved |
| **Produtor** | Human (PM + Tech Lead) |
| **Fase** | Promote (CI Async) |
| **Trigger** | Decisão formal de Release Approval: `Promover` ou `Promover com restrição` (vocabulário canônico do manifest) |
| **Pre-conditions** | Todos os critérios de DIL-RDY-002 satisfeitos; `Promote.GatesVerified` emitido; nenhum Finding bloqueante sem Waiver |
| **Post-conditions** | Deploy para produção autorizado; OBC transiciona para `Operational` no Markdown; Release Trail recebe entrada definitiva |
| **Artifacts affected** | `prodops/artifacts/obcs/<slug>.md` (status → Operational); `prodops/artifacts/trails/sessions/<session>.md` (entrada definitiva); Work Item (fecha) |
| **Evidence** | Nome do aprovador; decision string canônica (`Promover`); timestamp; restrições registradas se decisão foi `Promover com restrição` |
| **State change** | `Delivery Status → Active` (saindo de Waiting); após deploy: `Delivery Status → Done` via `Promote.Completed` |
| **Metrics** | Ancora M-16 (Approval Wait Time end); âncora final de M-01 (Total Delivery Lead Time) |
| **Finding trigger** | Não |
| **Assessment signal** | Frequência de `Promover com restrição` vs. `Promover` é sinal de qualidade do processo; `Não promover` ou `Descartar` devem gerar Assessment review |
| **GitHub representation** | Comment estruturado + GitHub Issue assignee update + PR merge event (Timeline nativo) |

---

## 8. Relação Eventos × GitHub

### 8.1 O papel de cada elemento GitHub no modelo de eventos

#### GitHub Issue — Work Item

O Issue é o **container** de todos os eventos de um item de Delivery. Cada evento é um comment estruturado no Issue.

- **Issue Body:** campos canônicos iniciais (artifact_type, artifact_id, operation, journey, execution_mode) — imutáveis após criação
- **Issue Comments:** eventos de Delivery emitidos ao longo do ciclo de vida
- **Issue Timeline:** eventos nativos do GitHub (PR linked, labels added, assignee changed) — capturam automaticamente alguns eventos de sistema
- **Issue Status (nativo):** espelha `Delivery Status` do Project Field — atualizado quando o Field muda

#### GitHub Issue Comments — Armazenamento de Eventos

**Esta é a decisão de implementação mais importante do modelo de eventos.**

Eventos estruturados são escritos como comments no Issue com o seguinte schema:

```json
{
  "prodops_event": true,
  "event_id": "DEL-EVT-067",
  "event_name": "Promote.Approved",
  "timestamp": "2026-07-24T14:32:00Z",
  "phase": "Promote",
  "cycle": "CI Async",
  "producer_type": "Human",
  "producer_identity": "christiano.m.almeida@accenture.com",
  "state_change": {
    "Delivery Status": "Active",
    "next_event_trigger": "Promote.DeployedToProduction"
  },
  "decision": "Promover",
  "evidence": {
    "release_trail": "prodops/artifacts/trails/sessions/2026-07-24-abc123.md",
    "pr_url": "https://github.com/org/payments-api/pull/42"
  },
  "restrictions": null
}
```

**Por que comments e não um campo separado:**
- Comments são ordenados cronologicamente — sequência de eventos preservada
- Comments têm timestamps imutáveis no GitHub (edited_at registrado, mas created_at não muda)
- Comments podem ser buscados via API (`gh api repos/org/repo/issues/42/comments`)
- Comments aparecem no Timeline — visualizável sem acesso ao API
- Um Field de texto não suporta múltiplos eventos do mesmo tipo (não há array de Fields)

**Limitação crítica:** Comments podem ser editados ou deletados por quem tem acesso. Para imutabilidade de auditoria, o evento deve também ser registrado no Release Trail (arquivo Markdown), que é versionado por git.

#### GitHub Project Fields — Estado Derivado

Fields são **projeções legíveis do último evento com state_change**. Nunca são atualizados diretamente — são consequência de um evento.

| Field | Derivado de... | Atualizado quando... |
|---|---|---|
| `Delivery Phase` | Último evento com `state_change.Delivery Phase` | Qualquer evento com state_change de fase |
| `Delivery Status` | Último evento com `state_change.Delivery Status` | Qualquer evento com state_change de status |
| `Rework Count` | COUNT de eventos `Rework.Declared` + outros retornos | Evento com `state_change.Rework Count + 1` |
| `Phase Entered At` | Timestamp do último evento de mudança de fase | Evento com state_change de fase |
| `Blocked Since` | Timestamp de `Blocking.ImpedimentDeclared` | Evento `Blocking.ImpedimentDeclared` |
| `Gate Results` | Acumulado dos eventos Gate.*Passed/Failed | Qualquer evento Gate.* |

**No modelo híbrido, Fields são caches, não fontes de verdade. A fonte de verdade são os eventos (comments).**

#### GitHub Project Views — Kanban sobre Estado Derivado

Views filtram Fields (estado derivado dos eventos) para visualização humana. As Views propostas no documento anterior permanecem válidas e são alimentadas pelos Fields derivados de eventos.

#### GitHub Labels — Classificação Auxiliar

Labels classificam Work Items para filtro CLI. No modelo de eventos, labels são atualizadas como consequência de eventos específicos:

| Evento | Label adicionada | Label removida |
|---|---|---|
| `Blocking.ImpedimentDeclared` | `status:blocked` | `status:active` |
| `Blocking.WaitingDeclared` | `status:waiting` | `status:active` |
| `Rework.Declared` | `rework` | — |
| `Finish.LintGateFailed` | `gate-failed:lint` | — |
| `Promote.Completed` | — | Todos os `phase:*`, `status:*` |

#### GitHub PR Timeline — Eventos de Sistema Captados Automaticamente

O GitHub captura automaticamente no Issue Timeline eventos relacionados a PRs linkados:
- PR opened (captura `Finish.PROpened`)
- PR review approved (captura `Finish.ReviewApproved`)
- PR merged (captura parte de `Ship.Started`)
- PR closed (captura situações de abandono)

Esses eventos nativos do GitHub complementam os events comentados — para esses casos, não é necessário emitir um comment adicional (o Timeline já registra).

### 8.2 Mecanismo de emissão de eventos por produtor

| Produtor | Como emite | Quem aciona |
|---|---|---|
| **Human (Engineer)** | Agente Claude Code emite comment JSON ao final de cada step de Skill | Engineer invoca `/hack start`, `/sync`, `/finish`, etc. |
| **Human (PM/Tech Lead)** | Agente Claude Code ou formulário GitHub emite comment após decisão verbal | PM anuncia "Promover" em review meeting |
| **System (git)** | GitHub Actions workflow emite comment via `gh api` após gate | CI pipeline conclui lint/build/test |
| **System (pipeline)** | GitHub Actions emite comment via `gh api` após build/deploy | Merge para main dispara CI |
| **Agent (automated)** | Agente autônomo emite comment ao verificar condição | Schedule ou webhook aciona Diligence |
| **Diligence** | Diligence Async Scan emite comment + abre Finding | Varredura periódica detecta anomalia |

### 8.3 Armazenamento duplo para imutabilidade

Para garantir auditoria completa:

```
Evento emitido
    ↓
1. Comment JSON no GitHub Issue  ← rápido, pesquisável, visível
    ↓
2. Entrada no Release Trail (Markdown)  ← imutável (git-versionado), sobrevive a GitHub
```

O Release Trail é a fonte de auditoria de longo prazo. O comment é a fonte de consulta operacional.

---

## 9. Derivação de Estado a partir de Eventos

### 9.1 Regras de derivação para Delivery Phase

| Último evento com state_change de fase | Delivery Phase resultante |
|---|---|
| `Bootstrap.Declared` | `Bootstrapping` |
| `Bootstrap.Completed` | `Hacking` |
| `Hack.Completed` | `Syncing` |
| `Sync.UnresolvableConflict` | `Hacking` (rework) |
| `Sync.Completed` | `Finishing` |
| `Finish.ChangesRequested` | `Hacking` (rework) |
| `Finish.GateFailureRework` | `Hacking` (rework) |
| `Finish.Completed` | `Shipping` |
| `Ship.Started` (from CI pipeline) | `Shipping` |
| `Ship.Completed` | `Validating` |
| `Validate.BDDScenariosFailed` | `Hacking` (rework) |
| `Validate.GateFailed` | `Hacking` (rework) |
| `Validate.Completed` | `Promoting` |
| `Promote.Completed` | `Done` |

### 9.2 Regras de derivação para Delivery Status

| Último evento com state_change de status | Delivery Status resultante |
|---|---|
| `Bootstrap.Started`, `Hack.ImpedimentResolved`, `Blocking.ImpedimentResolved` | `Active` |
| `Bootstrap.SmokeGateFailed`, `Hack.ImpedimentDeclared`, `Finish.AcceptanceGateFailed`, `Ship.DeployFailed`, `Promote.Rejected`, `Blocking.ImpedimentDeclared` | `Blocked` |
| `Finish.ReviewRequested`, `Promote.ApprovalRequested`, `Blocking.WaitingDeclared` | `Waiting` |
| `Promote.WorkItemClosed`, `Promote.Completed` | `Done` |

### 9.3 Regra de conflito entre eventos

Quando dois eventos concorrentes afetam o mesmo Field:
- O evento com o timestamp mais recente vence.
- Em caso de empate (improvável): o evento de maior severidade vence (Blocked > Waiting > Active).
- A Diligence detecta sequências de eventos incoerentes como `Diligence.StateEventInconsistency`.

### 9.4 Diagrama de máquina de estados derivada de eventos

```
                    Bootstrap.Declared
                           │
                           ▼
                    [BOOTSTRAPPING / Active]
                    Bootstrap.SmokeGateFailed ──────► [BOOTSTRAPPING / Blocked]
                    Bootstrap.Completed                       │
                           │              Bootstrap.SmokeGatePassed (after fix)
                           ▼                                  │
                    [HACKING / Active] ◄──────────────────────┘
                    Hack.ImpedimentDeclared ─────► [HACKING / Blocked]
                    Hack.Completed                            │
                           │              Hack.ImpedimentResolved
                           ▼                                  │
                    [SYNCING / Active] ◄──────────────────────┘
                    Sync.UnresolvableConflict ──────────────────► [HACKING / Active + Rework+1]
                    Sync.Completed                    ▲
                           │                          │
                           ▼                          │ Finish.ChangesRequested
                    [FINISHING / Active]               │ Finish.GateFailureRework
                    Finish.ReviewRequested ──► [FINISHING / Waiting]
                    Finish.ReviewApproved ───► [FINISHING / Active]
                    Finish.Completed
                           │
                           ▼
                    [SHIPPING / Active]
                    Ship.BuildFailed ────────► [SHIPPING / Blocked]
                    Ship.RollbackTriggered ──► [SHIPPING / Blocked]
                    Ship.Completed
                           │
                           ▼
                    [VALIDATING / Active]
                    Validate.BDDScenariosFailed ─────────────────► [HACKING / Active + Rework+1]
                    Validate.SLOViolationDetected ──► [VALIDATING / Blocked]
                    Validate.Completed
                           │
                           ▼
                    [PROMOTING / Active]
                    Promote.ApprovalRequested ──► [PROMOTING / Waiting]
                    Promote.Approved ───────────► [PROMOTING / Active]
                    Promote.Rejected ───────────► [PROMOTING / Blocked]
                    Promote.Completed
                           │
                           ▼
                    [DONE]
```

---

## 10. Cálculo de Métricas a partir de Eventos

### 10.1 Métricas DORA derivadas de eventos

| Métrica DORA | Eventos usados | Fórmula |
|---|---|---|
| **Lead Time for Change** | `Bootstrap.Declared`, `Promote.Completed` | `T(Promote.Completed) - T(Bootstrap.Declared)` |
| **Deployment Frequency** | `Promote.DeployedToProduction` | `COUNT(DEL-EVT-069) / período` |
| **Change Fail Rate** | `Validate.BDDScenariosFailed`, `Validate.GateFailed`, `Ship.DeployFailed`, `Promote.Completed` | `COUNT(eventos de falha pós-Ship) / COUNT(Promote.Completed)` |
| **Mean Time to Recovery** | `Ship.DeployFailed` ou `Validate.IncidentSignalDetected`, `Ship.Completed` (novo deploy) | `T(próximo Ship.Completed bem-sucedido) - T(falha detectada)` |

### 10.2 Métricas de fluxo derivadas de eventos (M-01 a M-18 do documento anterior)

| ID | Métrica | Eventos usados | Fórmula |
|---|---|---|---|
| M-01 | Total Delivery Lead Time | `Bootstrap.Declared`, `Promote.Completed` | `T(EVT-073) - T(EVT-001)` |
| M-02 | Bootstrap Lead Time | `Bootstrap.Started`, `Bootstrap.Completed` | `T(EVT-006) - T(EVT-002)` |
| M-03 | Hack Cycle Time | `Hack.Started`, `Hack.Completed` | `T(EVT-017) - T(EVT-008)` |
| M-04 | Finish Cycle Time | `Finish.Started`, `Finish.Completed` | `T(EVT-040) - T(EVT-026)` |
| M-05 | Ship Time | `Ship.Started`, `Ship.Completed` | `T(EVT-051) - T(EVT-041)` |
| M-06 | Validate Cycle Time | `Validate.Started`, `Validate.Completed` | `T(EVT-063) - T(EVT-052)` |
| M-07 | Promote Cycle Time | `Promote.Started`, `Promote.Completed` | `T(EVT-073) - T(EVT-064)` |
| M-08 | Gate Failure Rate | `Finish.Lint/Acceptance/Build/NoMocksFailed`, `Finish.Completed` | `COUNT(gate fail events) / COUNT(Finish.Completed)` |
| M-09 | Pipeline Failure Rate | `Ship.BuildFailed`, `Ship.DeployFailed`, `Ship.Completed` | `COUNT(Ship failures) / COUNT(Ship.Completed)` |
| M-10 | Blocker Duration | `Blocking.ImpedimentDeclared`, `Blocking.ImpedimentResolved` | `T(EVT-077) - T(EVT-076)` per item |
| M-11 | Rework Rate | `Rework.Declared` (+ `Sync.UnresolvableConflict`, `Finish.ChangesRequested`, `Validate.*Failed` with phase→Hacking) | `COUNT(retorno a Hacking) / COUNT(itens no período)` |
| M-12 | Rollback Rate | `Ship.RollbackTriggered`, `Promote.Completed` | `COUNT(EVT-049) / COUNT(EVT-073)` |
| M-13 | PR Review Wait Time | `Finish.ReviewRequested`, `Finish.ReviewApproved` or `Finish.ChangesRequested` | `T(review event) - T(EVT-036)` |
| M-14 | BDD Pass Rate (staging) | `Validate.BDDScenariosValidated`, `Validate.BDDScenariosFailed` | `COUNT(EVT-055) / [COUNT(EVT-055)+COUNT(EVT-056)]` |
| M-15 | SLO Compliance Rate | `Validate.SLOValidated`, `Validate.SLOViolationDetected` | `COUNT(EVT-057) / [COUNT(EVT-057)+COUNT(EVT-058)]` |
| M-16 | Approval Wait Time | `Promote.ApprovalRequested`, `Promote.Approved` or `Promote.Rejected` | `T(approval event) - T(EVT-066)` |
| M-17 | Cycle Efficiency | All `Active` periods, all `Waiting`+`Blocked` periods | `SUM(Active time) / SUM(Total time)` per item |
| M-18 | Phase Throughput | `Bootstrap.Declared` events per week/sprint | `COUNT(EVT-001) per período` |

**Conclusão sobre Fields de timestamp:** No modelo de eventos, nenhum Field de timestamp adicional (Bootstrap Started At, Hacking Started At, etc.) é estritamente necessário. Os eventos contêm os timestamps. Os Fields podem ser mantidos como caches para otimizar a performance de Views, mas não são a fonte de verdade das métricas.

---

## 11. Diligence no Modelo de Eventos

### 11.1 Como a Diligence opera no modelo híbrido

A Diligence opera em três modos, todos ampliados pelo modelo de eventos:

**a) Verifica estado atual (como antes)**
- Poll dos Fields `Delivery Phase` e `Delivery Status` no GitHub Project
- Verifica conformidade: `OBC State` no Field == OBC Markdown
- Checks existentes (DIL-RDY-001, DIL-RDY-002, etc.) funcionam como antes

**b) Verifica histórico de eventos (NOVO — impossível sem eventos)**
- Lê comments do Issue filtrados por `"prodops_event": true`
- Verifica se eventos esperados ocorreram dentro de janelas de tempo
- Detecta sequências inválidas de eventos (estado inconsistente com últimos eventos)

**c) Emite eventos ela mesma (NOVO — Diligence como produtora de eventos)**
- Quando detecta anomalia, emite `Diligence.StaleItemDetected` como comment estruturado
- Abre Finding e referencia o evento Diligence no Finding
- O evento Diligence fica na trilha do Issue, tornando a ação da Diligence auditável

### 11.2 Novos Checks possíveis apenas com eventos

| Novo Check | Detecção | Impossível sem eventos porque... |
|---|---|---|
| DIL-DEL-EVT-001: Bootstrap.Started sem Completed em 4h | `T(now) - T(Bootstrap.Started) > 4h` sem `Bootstrap.Completed` | Estado puro mostra "Bootstrapping" mas não quando começou |
| DIL-DEL-EVT-002: Hack sem TDD evidence | Há `Hack.Completed` mas não há `Hack.RedBarConfirmed` antes | Estado puro não registra etapas internas do Hack |
| DIL-DEL-EVT-003: Rework de staging 3+ vezes | COUNT `Validate.BDDScenariosFailed` > 2 para o mesmo item | Estado puro tem `Rework Count` mas não distingue origem |
| DIL-DEL-EVT-004: Gate failure sem Finding aberto | `Finish.AcceptanceGateFailed` sem Finding correspondente no registro | Estado puro não registra quando o gate falhou |
| DIL-DEL-EVT-005: Promote.Approved sem Promote.GatesVerified | Sequência inválida de eventos | Estado puro não verifica ordem de operações |
| DIL-DEL-EVT-006: Waiting > 48h sem owner | `Blocking.WaitingDeclared` há > 48h sem `Blocking.WaitingResolved` | Estado puro: `Waiting Since` cobre isso, mas não quem deve resolver |
| DIL-DEL-EVT-007: Deploy em produção sem Release Trail | `Promote.DeployedToProduction` sem `Promote.ReleaseTrailRecorded` seguinte | Estado puro não registra que o trail foi atualizado |

### 11.3 O loop scan/flag/repair no modelo de eventos

**Scan (Diligence Async):**
```
Para cada Work Item ativo na Jornada Delivery:
  1. Ler último evento com state_change → derivar estado esperado
  2. Comparar com Field Delivery Phase/Status → detectar inconsistência
  3. Verificar janelas temporais por fase (eventos com timestamp muito antigo)
  4. Verificar sequências obrigatórias (ex: Hack.RedBarConfirmed antes de Hack.Completed)
  5. Verificar eventos de Diligence anteriores (está o Finding do ciclo anterior resolvido?)
```

**Flag (Diligence Async):**
```
Para cada anomalia detectada no Scan:
  1. Emitir evento Diligence.StaleItemDetected no Issue (comment JSON)
  2. Criar Finding com referência ao evento Diligence e ao evento de Delivery que originou a anomalia
  3. Atualizar registry.yaml
  4. Notificar assignee (se configurado)
```

**Repair (Diligence Async):**
```
Para cada Finding aberto:
  1. Verificar se o evento de resolução ocorreu (ex: Blocking.ImpedimentResolved após Finding de bloqueio)
  2. Se resolução detectada: transicionar Finding para Verified, emitir Evidence
  3. Verificar se os Fields foram atualizados em consistência com o evento de resolução
  4. Caso Fields desatualizados: Diligence atualiza Fields + emite Diligence.StateEventInconsistency
```

---

## 12. Benefícios: DORA, Assessment, Observabilidade, Auditoria, Automação, Agentes

### 12.1 DORA

| Métrica DORA | Com estado puro | Com modelo de eventos |
|---|---|---|
| Lead Time for Change | Requer 2 Fields timestamp | `T(Promote.Completed) - T(Bootstrap.Declared)` — um evento de cada extremo |
| Deployment Frequency | Requer log manual ou GitHub Release counting | `COUNT(Promote.DeployedToProduction) / período` |
| Change Fail Rate | Impossível sem histórico de falhas pós-deploy | `COUNT(falhas pós-Ship) / COUNT(Promote.Completed)` |
| MTTR | Impossível — estado não captura quando falha começou | `T(Ship.Completed new deploy) - T(Validate.IncidentSignalDetected)` |

**Conclusão DORA:** As quatro métricas core do DORA são deriváveis trivialmente de eventos. Apenas `Change Fail Rate` e `MTTR` são impossíveis com estado puro; as outras são possíveis mas requerem Fields adicionais. Com eventos, nenhum Field adicional é necessário.

### 12.2 Assessment

O modelo de eventos transforma o Assessment de reativo (baseado em estado pontual) para preditivo (baseado em padrões):

| Padrão de evento | Sinal de Assessment |
|---|---|
| `Finish.ChangesRequested` frequente para um OBC | BDD pode estar mal especificado — revisar critérios de aceite |
| `Validate.BDDScenariosFailed` recorrente | Gap entre acceptance local e ambiente de staging — verificar parity |
| `Bootstrap.SmokeGateFailed` recorrente | Problema de infraestrutura ou setup — Review do ambiente |
| `Rework.Declared` com origem em `Validate.*Failed` alto | Defects escapando de todos os gates locais — revisar testing policy |
| `Ship.RollbackTriggered` em múltiplos itens no mesmo sprint | Problema sistêmico — possível regressão de plataforma |
| `Blocking.ImpedimentDeclared` com reason "Business Decision Pending" > 3 vezes | OBC pode ter incerteza de domínio não resolvida antes da Delivery |

### 12.3 Observabilidade

Com estado puro, um Kanban mostra "onde os itens estão agora". Com o modelo de eventos, o mesmo Kanban mostra estados derivados + um dashbard de métricas de fluxo é possível:

```
Board: estado atual (derivado de eventos)
    ↓ mais drill-down:
Timeline do Issue: sequência de eventos por item
    ↓ mais agregação:
Métricas por período: lead time, rework rate, gate failure rate
    ↓ mais tendência:
Comparação entre releases: está o fluxo melhorando?
```

Tudo isso é calculável a partir dos mesmos events commitados em comments do Issue.

### 12.4 Auditoria

O modelo de eventos cria uma trilha de auditoria que suporta compliance:

- **Quem aprovou o deploy?** `Promote.Approved` tem `producer_identity` com email.
- **Quando exatamente o deploy foi para produção?** `Promote.DeployedToProduction` tem timestamp ISO.
- **Qual a evidência do TDD para esta feature?** `Hack.TDDCycleCompleted` referencia o Release Trail.
- **Por que o item retornou ao Hacking?** `Rework.Declared` tem `origin_event` e razão.
- **O gate de aceite passou antes do deploy?** Sequência de eventos prova: `Finish.AcceptanceGatePassed` antes de `Finish.Completed`.

### 12.5 Automação

Eventos são o mecanismo de disparo de automações:

| Evento | Automação possível |
|---|---|
| `Bootstrap.Declared` | Criar comment de boas-vindas; verificar OBC/BDD disponíveis |
| `Finish.PROpened` | Atribuir revisores automaticamente; executar linters extras |
| `Ship.Started` (CI merge) | Acionar pipeline de build; criar snapshot de métricas |
| `Validate.SLOViolationDetected` | Notificar on-call; criar incident tracking |
| `Promote.Completed` | Atualizar OBC para Operational; fechar Work Item; notificar stakeholders |
| `Diligence.StaleItemDetected` | Notificar assignee; escalonar para lead se sem resposta em 4h |

### 12.6 Agentes

Agentes de LLM (Claude Code, downstream-agent, etc.) beneficiam-se do modelo de eventos de duas formas:

**Como produtores:** Agentes emitem eventos ao final de cada step. Isso torna o comportamento do agente auditável — o event log mostra exatamente o que cada invocação de `/hack`, `/sync`, `/finish` produziu.

**Como consumidores:** Antes de continuar uma sessão interrompida, um agente lê os events do Issue para entender o estado atual sem depender de memória. `"Qual o último evento? Bootstrap.SmokeGateFailed. Então o próximo passo é resolver o bloqueio de ambiente."` — contexto auto-suficiente.

---

## 13. Plano de Migração Incremental

A migração para o modelo híbrido deve ser incremental e não deve quebrar o Framework atual.

### Fase 0 — Baseline (estado atual, sem mudança)

O modelo de estados do documento anterior permanece como está. O GitHub Project `ProdOps — Delivery` pode ser configurado com os Fields propostos (Delivery Phase, Delivery Status, etc.). Nenhuma mudança de Framework é necessária para este passo.

**Reversibilidade:** Nativa — o estado atual continua funcionando.

### Fase 1 — Event schema definition (sem implementação)

Publicar este documento como proposta arquitetural. Definir o schema JSON canônico do evento (formato do comment). Definir quais eventos cada Skill deve emitir ao final de cada step.

**Impacto:** Zero — apenas documentação.
**Reversibilidade:** Nativa.
**Pré-requisito para Fase 2:** Aprovação do schema de evento.

### Fase 2 — Event emission by agents (MVP mínimo)

Atualizar os Skills (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) para emitir um comment JSON ao final de cada step principal. Começar com os eventos de maior valor: `Bootstrap.Declared`, `Bootstrap.Completed`, `Promote.Completed`, e os eventos de gate failure.

**Impacto:** Skills produzem um comment adicional. Comportamento dos Skills permanece o mesmo.
**Reversibilidade:** Parar de emitir events não quebra nada — Fields ainda existem.
**Benefício imediato:** Lead time calculável sem Fields adicionais.

### Fase 3 — State derivation (completo o loop)

Criar um GitHub Actions workflow que lê novos comments de evento e atualiza os Fields correspondentes. Isso fecha o loop: events → state derivado → Kanban legível.

**Impacto:** GitHub Actions workflow novo. Fields passam a ser atualizados automaticamente.
**Reversibilidade:** Desativar o workflow; Fields voltam a ser atualizados manualmente.
**Benefício:** Consistência garantida entre events e Fields; sem drift possível.

### Fase 4 — Diligence event checks (expansão)

Adicionar ao catálogo os novos Checks baseados em eventos (DIL-DEL-EVT-001 a DIL-DEL-EVT-007). Atualizar o Diligence Async Scan para ler events dos Issues além de verificar Fields.

**Impacto:** Catálogo de Checks expandido. Diligence lê mais dados (comments de evento).
**Reversibilidade:** Desativar os novos Checks; Diligence volta ao modelo de estado.
**Benefício:** Detecção de anomalias impossíveis com estado puro.

### Fase 5 — Assessment event signals (consolidação)

Configurar o Assessment para consumir relatórios agregados de eventos (produzidos pela Diligence Async) como sinais de saúde operacional. Isso transforma o Assessment de reativo para preditivo.

**Impacto:** Assessment workflow expandido.
**Benefício:** DORA completo, patterns de rework correlacionáveis, observabilidade de longo prazo.

### Resumo do plano

```
Fase 0: Estado atual (sem mudança)
    ↓
Fase 1: Schema de eventos definido (documentação)    ← CUSTO MÍNIMO, REVERSÍVEL
    ↓
Fase 2: Skills emitem events (MVE — Minimum Viable Events)
    ↓
Fase 3: GitHub Actions deriva estado dos events      ← LOOP FECHADO
    ↓
Fase 4: Diligence usa events para novos Checks
    ↓
Fase 5: Assessment consome agregados de events
```

---

## 14. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| **Disciplina de emissão:** agents ou humanos esquecem de emitir eventos | Alta | Alto | Automatizar: Skill emite evento como último step obrigatório — sem evento, step não completa |
| **Schema drift:** formato de evento muda sem versão | Média | Alto | Versionar o schema de evento; campo `schema_version` em todo comment de evento |
| **Comments editáveis:** imutabilidade não é garantida pelo GitHub | Média | Médio | Backup no Release Trail (Markdown versionado por git) para auditoria de longo prazo |
| **Performance:** Issues com muitos comments ficam lentos para carregar | Baixa | Médio | Paginate API calls; usar `gh api` filtrado por `since` parameter |
| **GitHub API limits:** leitura de todos os events de todos os Issues em massa | Média | Médio | Diligence lê em lote; rate limit handling no workflow; caching de último event por Issue |
| **Complexidade de adoção:** time resistente a emitir eventos estruturados | Alta | Alto | Automatizar emissão nos Skills; o engenheiro não precisa saber do schema — o agente cuida |
| **Estado e evento dessincronizados:** Fields não atualizados após evento | Média | Médio | Fase 3 do plano de migração resolve com automação; Diligence detecta via DIL-DEL-EVT |
| **Eventos órfãos:** eventos sem Item correspondente no Project | Baixa | Baixo | Diligence verifica que todo Issue com evento de Delivery está no Project correto |

---

## 15. Próximos Passos

1. **Aprovação deste documento** pelo Framework Owner (Christiano Milfont) como proposta arquitetural.

2. **Definir o schema JSON canônico** de evento em `prodops/framework/journeys/delivery/event-schema.md`. O schema proposto neste documento (seção 8.2) é a base.

3. **Priorizar os 10 eventos de maior ROI** para emissão na Fase 2:
   - `Bootstrap.Declared`, `Bootstrap.Completed` (lead time start/end de bootstrap)
   - `Hack.Completed` (lead time de hacking)
   - `Finish.PROpened`, `Finish.ReviewApproved` (PR cycle time)
   - `Finish.AcceptanceGateFailed` (gate failure tracking)
   - `Validate.BDDScenariosFailed` (staging rework detection)
   - `Promote.Approved`, `Promote.DeployedToProduction`, `Promote.Completed` (DORA Lead Time)

4. **Prototipar o GitHub Actions workflow** de derivação de estado (Fase 3) em uma branch de experimento.

5. **Adicionar os Checks DIL-DEL-EVT** ao catálogo da Diligence (catalog.yaml), começando pelos de maior impacto: DIL-DEL-EVT-001 (Bootstrap sem Completed em 4h) e DIL-DEL-EVT-004 (Gate failure sem Finding).

6. **Revisar as Skill files** (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) para incluir o step de emissão de evento como post-condition obrigatória — mas sem alterar a estrutura conceitual das Skills.

---

## 16. Veredicto Final

### Fonte de verdade do modelo operacional do ProdOps: Estados, Eventos, ou Ambos?

**Recomendação: Eventos como primários + Estados como derivados.**

### 16.1 Justificativa técnica (5 razões específicas)

**Razão 1 — O modelo de estados do documento anterior já era um modelo de eventos implícito**

Os campos `Bootstrap Started At`, `Hacking Started At`, `Finishing Started At`, `Promoted At` — propostos no documento anterior — são eventos sem nome. Cada um registra o momento de uma transição. O modelo de eventos apenas formaliza e estrutura o que o modelo de estados já exigia implicitamente para computar métricas. Formalizar é sempre superior a implicar.

**Razão 2 — DORA não é calculável com estado puro**

`Change Fail Rate` (quantas mudanças causaram falha em produção) e `MTTR` (tempo para recuperar de um incidente) são impossíveis sem eventos porque dependem de saber *quando* a falha ocorreu e *quando* foi resolvida — informações que o estado atual não preserva. O modelo de estados pode calcular Lead Time e Deployment Frequency com Fields de timestamp, mas não as quatro métricas DORA sem uma forma de log de eventos.

**Razão 3 — GitHub tem capacidade nativa suficiente para o modelo híbrido**

Issue comments ordenados cronologicamente com schema JSON são o mecanismo de persistência de eventos. O GitHub Timeline captura automaticamente eventos de PR. Fields do Project são o mecanismo de projeção de estado. Views filtram o estado. Nenhuma infraestrutura adicional (banco de dados, event bus, plataforma de streaming) é necessária para o MVP. O modelo opera inteiramente dentro das capacidades atuais do GitHub.

**Razão 4 — Rework, causalidade e rollback exigem eventos estruturados**

`Rework Count = 3` (estado) não responde: "Qual gate causou o primeiro retorno? Qual fase originou o segundo? O terceiro foi por mudança de requisito ou por falha em staging?" Eventos respondem todas essas perguntas sem trabalho adicional de coleta. Para Assessment e para melhoria contínua do processo, causalidade é mais valiosa do que contadores.

**Razão 5 — Diligence torna-se proativa, não apenas reativa**

Com estado puro, a Diligence verifica "o estado atual é o estado correto?" — uma pergunta pontual. Com eventos, a Diligence verifica "o evento esperado ocorreu dentro do prazo?" — uma pergunta temporal que detecta problemas antes que se tornem bloqueios visíveis no Kanban. A Diligence proativa ("Bootstrap foi declarado há 6 horas e não houve evento de Completed") é estruturalmente superior à reativa ("Delivery Status = Blocked").

### 16.2 O que muda imediatamente se esta recomendação for adotada

1. **Skills emitem eventos** ao final de cada step como último ato obrigatório — comment JSON no Issue.
2. **Fields passam a ser derivados** de eventos, não atualizados diretamente.
3. **Release Trail** continua como backup de auditoria (imutabilidade git-versionada) — papel não muda, mas passa a ser correlacionado com eventos por timestamp.
4. **Catálogo de Checks** da Diligence é expandido com Checks temporais baseados em eventos.
5. **Métricas DORA** passam a ser calculáveis automaticamente sem Fields adicionais.

### 16.3 O que permanece igual

- As cinco jornadas (Discovery, Delivery, Operation, Assessment, Diligence) não mudam.
- O pipeline CI Sync → CI Async não muda.
- Os quality gates (lint, acceptance, build, no_mocks) não mudam.
- Os Skills (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) mudam apenas em seu último step (emissão de evento) — a lógica central permanece.
- O GitHub Project `ProdOps — Delivery` com seus Fields permanece — Fields agora são derivados, não fonte primária.
- A Diligence como guardiã da COR não muda de papel — expande suas capacidades.
- O princípio `knowledge-vs-execution.md` permanece intacto: eventos são representação de execução, não knowledge.

### 16.4 Risco de NÃO adotar esta recomendação

O risco de permanecer no modelo puro de estados é **ossificar a incapacidade de medir o que importa**. DORA requer eventos — sem eles, as métricas permanecem declaradas na documentação mas não observáveis na operação. Rework continua sendo um contador opaco. Rollback continua sendo semanticamente ambíguo. Assessment continua operando sobre snapshots de estado, não sobre padrões de comportamento ao longo do tempo.

A jornada Delivery tem as Skills mais maduras do Framework. É exatamente por isso que esta é a jornada mais pronta para dar o próximo passo: de representação operacional de estado para representação operacional de eventos. Não adotar este modelo em Delivery significa adiar indefinidamente a observabilidade real do processo de entrega do produto.

---

*Documento gerado por análise arquitetural profunda do ProdOps Framework.
Nenhum arquivo existente foi modificado. Este documento é exclusivamente proposta.*
