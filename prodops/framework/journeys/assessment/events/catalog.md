# Assessment Event Catalog — v2
# ProdOps Framework — Jornada Assessment

> **Versão:** 2.0.0
> **Status:** Active
> **Namespace:** `Assessment`
> **Journey:** Assessment
> **Schema:** [Event Type Schema v1.0.0](../../../events/event-type-schema.md)
> **Changelog v2.0.0:** Gate.Passed, Gate.Failed, Impediment.Declared → Deprecated (promovidos a Shared Types Active). Impediment.Resolved → aguarda shared-types v1.1.0 para deprecação formal.

---

## Visão geral

| # | Event Type | Category | alters_state | new_state | Producers | Status v2 |
|---|---|---|---|---|---|---|
| 1 | Collect.Started | Phase Lifecycle | true | COLLECTING | Human, Agent | Active |
| 2 | Collect.Completed | Phase Lifecycle | true | COLLECTED | Human, Agent | Active |
| 3 | Analyze.Started | Phase Lifecycle | true | ANALYZING | Human, Agent | Active |
| 4 | Analyze.Completed | Phase Lifecycle | true | ANALYZED | Human, Agent | Active |
| 5 | Synthesize.Completed | Phase Lifecycle | true | SYNTHESIZED | Human, Agent | Active |
| 6 | Report.Published | Phase Lifecycle | true | DONE | Human, Agent, System | Active |
| 7 | Monitor.Activated | Phase Lifecycle | true | MONITORING | System, Agent | Active |
| 8 | Alert.Raised | Phase Lifecycle | true | ALERTED | System, Agent | Active |
| 9 | Report.Approved | Human Decision | true | REPORTING | Human | Active |
| 10 | Report.Rejected | Human Decision | true | SYNTHESIZED | Human | Active |
| 11 | Recommendation.Issued | Human Decision | false | — | Human, Agent | Active |
| 12 | Risk.Identified | Human Decision | false | — | Human, Agent | Active |
| 13 | Opportunity.Identified | Human Decision | false | — | Human, Agent | Active |
| 14 | Gate.Passed | Gate | false | — | System, Agent | **Deprecated** → Shared.Gate.Passed |
| 15 | Gate.Failed | Gate | false | — | System, Agent | **Deprecated** → Shared.Gate.Failed |
| 16 | Impediment.Declared | Blocking | true | BLOCKED | Human, Agent | **Deprecated** → Shared.Impediment.Declared |
| 17 | Impediment.Resolved | Blocking | false | — | Human | Active — aguarda Shared.Impediment.Resolved (shared-types v1.1.0) |
| 18 | Threshold.Crossed | System | false | — | System, Agent | Active |
| 19 | Evolve.Proposed | System | false | — | System, Agent | Active |

---

## Assessment Sync — Collect

---

### Collect.Started

| Campo | Valor |
|---|---|
| **name** | `Collect.Started` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `COLLECTING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O ciclo de coleta de evidências do Assessment foi iniciado. O escopo da análise, a janela
temporal e os critérios de seleção de Work Items foram definidos. O corpus de evidências
está sendo construído a partir das Timelines de Delivery e Diligence e dos artefatos do Framework.

**preconditions:**
- O gatilho do ciclo de Assessment foi acionado (cadência, limiar, sinal, ou solicitação)
- O escopo da análise foi definido (journeys incluídas, período, Work Items)
- Um Work Item de Assessment foi criado para este ciclo

**postconditions:**
- O Work Item transita para o estado COLLECTING
- A Timeline do Assessment registra o início do ciclo com o escopo definido

**payload_shape:**
- `assessment_id` (string, obrigatório): identificador único deste ciclo de Assessment
- `scope_description` (string, obrigatório): descrição do escopo (journeys, período, critérios)
- `evidence_window_start` (string, obrigatório): ISO 8601 — início da janela de evidências
- `evidence_window_end` (string, obrigatório): ISO 8601 — fim da janela de evidências
- `trigger` (string, obrigatório): o gatilho que acionou este ciclo (`cadence`, `threshold`, `external_signal`, `explicit_request`)

**owner_journey:** Assessment

---

### Collect.Completed

| Campo | Valor |
|---|---|
| **name** | `Collect.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `COLLECTED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O corpus de evidências do Assessment está completo e indexado. As Timelines dos Work Items
no escopo foram coletadas, as métricas brutas foram extraídas, e os artefatos relevantes
(OBCs, Reliability Plans, Release Trails, Findings da Diligence) foram referenciados.
O Work Item está pronto para análise.

**preconditions:**
- O Work Item está no estado COLLECTING
- Todas as Timelines no escopo foram coletadas ou documentadas como indisponíveis
- Os artefatos relevantes foram indexados

**postconditions:**
- O Work Item transita para o estado COLLECTED
- O corpus de evidências está completo e referenciado
- A completude dos dados está documentada no payload

**payload_shape:**
- `timelines_collected` (integer, obrigatório): número de Timelines coletadas no escopo
- `work_items_in_scope` (integer, obrigatório): número de Work Items no escopo da análise
- `evidence_items_indexed` (integer, obrigatório): total de itens de evidência indexados
- `data_completeness` (string, obrigatório): `complete` ou `partial` — se partial, nota sobre o que está ausente

**owner_journey:** Assessment

---

## Assessment Sync — Analyze

---

### Analyze.Started

| Campo | Valor |
|---|---|
| **name** | `Analyze.Started` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `ANALYZING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A fase de análise do Assessment foi iniciada. O analista (humano ou agente) está calculando
métricas operacionais, identificando padrões e correlacionando Findings da Diligence com
os dados das Timelines. Múltiplos eventos de observação (Recommendation.Issued, Risk.Identified,
Opportunity.Identified, Gate.Passed/Failed) podem ser emitidos durante esta fase.

**preconditions:**
- O Work Item está no estado COLLECTED
- O corpus de evidências foi validado (Gate.Passed de completude registrado ou exception documentada)

**postconditions:**
- O Work Item transita para o estado ANALYZING
- A análise está em execução — métricas sendo calculadas

**payload_shape:**
- `analysis_approach` (string, obrigatório): descrição da abordagem de análise
- `metrics_planned` (array of strings, obrigatório): métricas planejadas para cálculo (ex.: `["lead_time", "cycle_time", "gate_failure_rate"]`)

**owner_journey:** Assessment

---

### Analyze.Completed

| Campo | Valor |
|---|---|
| **name** | `Analyze.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `ANALYZED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A fase de análise foi concluída. As métricas foram calculadas, os padrões foram identificados,
e os Findings da Diligence foram correlacionados. Os resultados da análise estão documentados
e prontos para síntese. Eventuais Recommendation.Issued, Risk.Identified, e Opportunity.Identified
foram emitidos durante esta fase.

**preconditions:**
- O Work Item está no estado ANALYZING
- Todas as métricas planejadas em Analyze.Started foram calculadas (ou indisponibilidade documentada)
- Padrões foram identificados e classificados (melhorando / estável / degradando)

**postconditions:**
- O Work Item transita para o estado ANALYZED
- Os resultados da análise estão disponíveis para síntese

**payload_shape:**
- `metrics_calculated` (array of strings, obrigatório): métricas efetivamente calculadas
- `patterns_identified` (integer, obrigatório): número de padrões identificados
- `findings_correlated` (integer, obrigatório): número de Findings da Diligence correlacionados
- `recommendations_issued_count` (integer, obrigatório): número de Recommendation.Issued emitidos durante a análise

**owner_journey:** Assessment

---

## Assessment Sync — Synthesize

---

### Synthesize.Completed

| Campo | Valor |
|---|---|
| **name** | `Synthesize.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `SYNTHESIZED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A síntese dos resultados da análise foi concluída. Os insights foram consolidados em
conclusões de alto nível, as recomendações foram priorizadas, e o rascunho do Assessment
Report está pronto para revisão humana e aprovação. Gates de qualidade sobre o Report
podem ser executados neste momento.

**preconditions:**
- O Work Item está no estado ANALYZED
- Os resultados da análise foram processados e consolidados
- Pelo menos uma conclusão e uma recomendação foram formuladas

**postconditions:**
- O Work Item transita para o estado SYNTHESIZED
- O rascunho do Assessment Report está pronto para revisão e aprovação
- Gates de qualidade sobre o Report serão executados antes de Report.Approved

**payload_shape:**
- `insights_count` (integer, obrigatório): número de insights consolidados
- `recommendations_count` (integer, obrigatório): número de recomendações no rascunho
- `trend_summary` (string, obrigatório): sumário das tendências identificadas (`improving`, `stable`, `degrading`, `mixed`)

**owner_journey:** Assessment

---

## Assessment Sync — Report

---

### Report.Approved

| Campo | Valor |
|---|---|
| **name** | `Report.Approved` |
| **category** | Human Decision |
| **alters_state** | `true` |
| **new_state** | `REPORTING` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um responsável humano aprovou o Assessment Report para publicação. O Report foi revisado e
satisfaz os critérios de qualidade — as conclusões são fundamentadas em evidências, as
recomendações são específicas e atribuídas, e o período analisado está documentado.

**preconditions:**
- O Work Item está no estado SYNTHESIZED
- Os gates de qualidade do Report foram executados com sucesso (Gate.Passed na Timeline)
- O Report foi revisado pelo responsável

**postconditions:**
- O Work Item transita para o estado REPORTING
- A publicação do Report pode ser executada (Report.Published será emitido)

**payload_shape:**
- `approver` (string, obrigatório): identidade de quem aprovou o Report
- `quality_gates_passed` (integer, obrigatório): número de gates de qualidade aprovados antes desta decisão

**owner_journey:** Assessment

---

### Report.Rejected

| Campo | Valor |
|---|---|
| **name** | `Report.Rejected` |
| **category** | Human Decision |
| **alters_state** | `true` |
| **new_state** | `SYNTHESIZED` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Assessment Report foi rejeitado pelo responsável. O Report não satisfez os critérios de
qualidade — conclusões insuficientemente fundamentadas, recomendações vagas, ou análise
incompleta. O Work Item retorna ao estado SYNTHESIZED — nova síntese deve ser realizada
antes de submeter para nova aprovação.

**preconditions:**
- O Work Item está no estado SYNTHESIZED
- O Report foi revisado pelo responsável e não satisfaz os critérios

**postconditions:**
- O Work Item retorna ao estado SYNTHESIZED
- O motivo da rejeição está registrado na Timeline
- Nova síntese e novo Report.Approved serão necessários

**payload_shape:**
- `rejector` (string, obrigatório): identidade de quem rejeitou o Report
- `reason` (string, obrigatório): descrição dos critérios não satisfeitos

**owner_journey:** Assessment

---

### Report.Published

| Campo | Valor |
|---|---|
| **name** | `Report.Published` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `DONE` |
| **producer_subtypes** | `[Human, Agent, System]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Assessment Report foi publicado formalmente. O ciclo Assessment Sync está encerrado. O
Report está disponível para consulta e as recomendações estão atribuídas para execução.
A Timeline do ciclo de Assessment permanece aberta para eventos de correção.

**preconditions:**
- O Work Item está no estado REPORTING
- Report.Approved foi registrado na Timeline
- O Report foi publicado no artefato designado

**postconditions:**
- O Work Item transita para o estado DONE
- O Assessment Report está formalmente publicado e acessível
- As recomendações estão atribuídas para acompanhamento

**payload_shape:**
- `report_id` (string, obrigatório): identificador único do Report publicado
- `report_location` (string, obrigatório): caminho ou referência ao artefato publicado
- `recommendations_count` (integer, obrigatório): número de recomendações no Report publicado
- `next_assessment_trigger` (string, obrigatório): descrição do próximo gatilho de Assessment (data ou condição)

**owner_journey:** Assessment

---

## Assessment Async — Monitor

---

### Monitor.Activated

| Campo | Valor |
|---|---|
| **name** | `Monitor.Activated` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `MONITORING` |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O ciclo de monitoramento contínuo foi ativado. O sistema está observando permanentemente
as métricas derivadas das Timelines de Delivery e Diligence, comparando com os limiares
definidos. Eventos de observação (Threshold.Crossed, Recommendation.Issued, Evolve.Proposed)
podem ser emitidos durante este ciclo sem alterar o Derived State.

**preconditions:**
- Um Work Item de monitoramento foi criado para este ciclo Async
- Os limiares de alerta foram configurados

**postconditions:**
- O Work Item transita para o estado MONITORING
- O monitoramento contínuo está ativo — métricas sendo observadas

**payload_shape:**
- `monitor_cycle_id` (string, obrigatório): identificador do ciclo de monitoramento (ex.: `2026-Q3-MONITOR`)
- `metrics_watched` (array of strings, obrigatório): métricas sendo monitoradas
- `thresholds_count` (integer, obrigatório): número de limiares configurados

**owner_journey:** Assessment

---

## Assessment Async — Alert

---

### Alert.Raised

| Campo | Valor |
|---|---|
| **name** | `Alert.Raised` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `ALERTED` |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um alerta formal foi levantado após análise dos limiares cruzados. A situação requer
avaliação estruturada — um ciclo de Assessment Sync deve ser acionado. O alerta é
registrado com severidade e contexto suficiente para iniciar o Sync imediatamente.

**preconditions:**
- O Work Item está no estado MONITORING
- Um ou mais Threshold.Crossed foram registrados indicando situação de atenção
- O sistema determinou que um alerta formal é justificado (severidade ou combinação de limiares)

**postconditions:**
- O Work Item transita para o estado ALERTED
- Um ciclo de Assessment Sync deve ser acionado
- O Monitor.Activated do próximo ciclo será emitido após a conclusão do Sync

**payload_shape:**
- `alert_title` (string, obrigatório): título curto do alerta
- `alert_description` (string, obrigatório): descrição detalhada do contexto
- `severity` (string, obrigatório): `high`, `medium`, `low`
- `triggering_events` (array of strings, obrigatório): ids dos Threshold.Crossed que motivaram este alerta

**owner_journey:** Assessment

---

## Eventos de Observação — Human Decision

---

### Recommendation.Issued

| Campo | Valor |
|---|---|
| **name** | `Recommendation.Issued` |
| **category** | Human Decision |
| **alters_state** | `false` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Uma recomendação formal foi produzida durante o ciclo de Assessment. A recomendação é
específica, atribuída, priorizada e fundamentada em evidências da Timeline. Pode ser
emitida durante Analyze ou Synthesize (Sync) ou durante Monitor (Async). Múltiplos
Recommendation.Issued podem ocorrer no mesmo ciclo.

**preconditions:**
- O Work Item está em estado ativo de análise (ANALYZING, ANALYZED, SYNTHESIZED, ou MONITORING)
- A recomendação tem um responsável definido e evidência citada

**postconditions:**
- A recomendação está registrada formalmente na Timeline
- O Derived State não é alterado

**payload_shape:**
- `recommendation_title` (string, obrigatório): título da recomendação
- `recommendation_description` (string, obrigatório): descrição detalhada com evidência
- `priority` (string, obrigatório): `high`, `medium`, `low`
- `assignee` (string, opcional): identidade do responsável pela recomendação
- `evidence_event_ids` (array of strings, opcional): ids dos eventos que fundamentam a recomendação

**owner_journey:** Assessment

---

### Risk.Identified

| Campo | Valor |
|---|---|
| **name** | `Risk.Identified` |
| **category** | Human Decision |
| **alters_state** | `false` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um risco operacional foi formalmente identificado durante a análise. O risco é uma
condição observada nas Timelines ou Findings que, se não tratada, pode degradar o
modelo operacional. O registro do risco não altera o Derived State — é uma observação
formal que pode fundamentar Recommendations e Evolution Plans.

**preconditions:**
- O Work Item está em estado ativo de análise
- O risco foi identificado com base em evidências das Timelines ou Findings

**postconditions:**
- O risco está formalmente registrado na Timeline com severidade e probabilidade
- O Derived State não é alterado

**payload_shape:**
- `risk_description` (string, obrigatório): descrição detalhada do risco identificado
- `severity` (string, obrigatório): `critical`, `high`, `medium`, `low`
- `probability` (string, obrigatório): `high`, `medium`, `low`
- `evidence_summary` (string, obrigatório): descrição das evidências que fundamentam o risco
- `mitigation_suggestion` (string, opcional): sugestão inicial de mitigação

**owner_journey:** Assessment

---

### Opportunity.Identified

| Campo | Valor |
|---|---|
| **name** | `Opportunity.Identified` |
| **category** | Human Decision |
| **alters_state** | `false` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Uma oportunidade de melhoria ou evolução foi formalmente identificada durante a análise.
A oportunidade é uma condição observada nas Timelines ou Findings que, se aproveitada,
pode aprimorar o modelo operacional. O registro não altera o Derived State — é uma
observação formal que pode originar New Business Intents ou Evolution Plans.

**preconditions:**
- O Work Item está em estado ativo de análise
- A oportunidade foi identificada com base em evidências

**postconditions:**
- A oportunidade está formalmente registrada na Timeline
- O Derived State não é alterado

**payload_shape:**
- `opportunity_description` (string, obrigatório): descrição detalhada da oportunidade
- `potential_impact` (string, obrigatório): descrição do impacto potencial se aproveitada
- `confidence` (string, obrigatório): `high`, `medium`, `low`
- `evidence_summary` (string, obrigatório): evidências que fundamentam a oportunidade

**owner_journey:** Assessment

---

## Eventos Transversais — Gate

---

### Gate.Passed

| Campo | Valor |
|---|---|
| **name** | `Gate.Passed` |
| **category** | Gate |
| **alters_state** | `false` |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | Deprecated |
| **introduced_in** | 1.0.0 |
| **deprecated_in** | 2.0.0 |
| **deprecation_reason** | Promovido a Shared Type. Não emitir novos eventos com este tipo Journey — usar Shared.Gate.Passed. |
| **replacement_type** | `Shared.Gate.Passed` — ver [shared-types.md](../../../events/shared-types.md) |

**description:**
Um gate automatizado de qualidade passou com sucesso. Na Jornada Assessment, gates verificam
critérios de qualidade do próprio ciclo — completude dos dados coletados, cobertura mínima
de métricas, fundamentação das recomendações em evidências. O Derived State não é alterado.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado

**postconditions:**
- O gate está registrado como passante na Timeline
- O Derived State permanece inalterado

**payload_shape:**
- `gate_name` (string, obrigatório): identificador do gate (ex.: `data-completeness`, `metric-coverage`, `recommendation-evidence`)
- `duration_ms` (integer, obrigatório): duração da execução em milissegundos

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas que referenciam este tipo continuam válidas — o tipo
permanece no catálogo como referência histórica somente leitura. Novas emissões devem usar
`Shared.Gate.Passed`. Par complementar: Gate.Failed.

**owner_journey:** Assessment

---

### Gate.Failed

| Campo | Valor |
|---|---|
| **name** | `Gate.Failed` |
| **category** | Gate |
| **alters_state** | `false` |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | Deprecated |
| **introduced_in** | 1.0.0 |
| **deprecated_in** | 2.0.0 |
| **deprecation_reason** | Promovido a Shared Type. Não emitir novos eventos com este tipo Journey — usar Shared.Gate.Failed. |
| **replacement_type** | `Shared.Gate.Failed` — ver [shared-types.md](../../../events/shared-types.md) |

**description:**
Um gate automatizado de qualidade falhou. O critério verificado não foi satisfeito. O Work
Item permanece no estado atual — o Producer deve avaliar se Report.Rejected deve ser emitido
(no caso de gate sobre o Report) ou se a análise deve ser complementada.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado e produziu resultado de falha

**postconditions:**
- A falha do gate está registrada na Timeline
- O Derived State permanece inalterado

**payload_shape:**
- `gate_name` (string, obrigatório): identificador do gate
- `reason` (string, obrigatório): descrição do critério que falhou
- `duration_ms` (integer, obrigatório): duração da execução em milissegundos

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas continuam válidas. Novas emissões devem usar
`Shared.Gate.Failed`. Par complementar: Gate.Passed.

**owner_journey:** Assessment

---

## Eventos Transversais — Blocking

---

### Impediment.Declared

| Campo | Valor |
|---|---|
| **name** | `Impediment.Declared` |
| **category** | Blocking |
| **alters_state** | `true` |
| **new_state** | `BLOCKED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Deprecated |
| **introduced_in** | 1.0.0 |
| **deprecated_in** | 2.0.0 |
| **deprecation_reason** | Promovido a Shared Type. Não emitir novos eventos com este tipo Journey — usar Shared.Impediment.Declared. |
| **replacement_type** | `Shared.Impediment.Declared` — ver [shared-types.md](../../../events/shared-types.md) |

**description:**
Um impedimento externo foi declarado para o ciclo de Assessment. O trabalho não pode
progredir — pode ser falta de acesso a Timelines, indisponibilidade de sistemas de análise,
ou dependência de dados externos que ainda não estão disponíveis.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um impedimento externo foi identificado que impede a progressão do ciclo

**postconditions:**
- O Work Item transita para o estado BLOCKED
- O trabalho é suspenso até Impediment.Resolved

**payload_shape:**
- `impediment_description` (string, obrigatório): descrição do impedimento e de quem ou o que pode resolvê-lo
- `blocking_since` (string, obrigatório): timestamp em que o impedimento foi identificado

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas que referenciam este tipo continuam válidas. Novas
emissões devem usar `Shared.Impediment.Declared`. Par complementar: Impediment.Resolved.

**owner_journey:** Assessment

---

### Impediment.Resolved

| Campo | Valor |
|---|---|
| **name** | `Impediment.Resolved` |
| **category** | Blocking |
| **alters_state** | `false` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O impedimento externo foi resolvido e o ciclo de Assessment pode ser retomado. O Work Item
retorna ao estado em que estava antes do impedimento ser declarado.

O estado de retorno **não está hardcoded** — o Consumer usa o mecanismo de Lookback
(`preBlockedState`) definido no `timeline.md` para calcular o estado anterior ao BLOCKED.
Implementação refinada e consistente com Diligence. Esta é a terceira Journey a confirmar
este padrão — a convergência técnica de Delivery v2 (`alters_state=false`) foi concluída em 2026-07-25.

**preconditions:**
- O Work Item está no estado BLOCKED
- O impedimento declarado em Impediment.Declared foi resolvido

**postconditions:**
- O Derived State **não é alterado diretamente** por este evento (`alters_state = false`)
- O Consumer usa Lookback para determinar o estado de retorno (estado pré-BLOCKED)
- A resolução do impedimento está registrada na Timeline

**payload_shape:**
- `resolution_description` (string, obrigatório): descrição de como o impedimento foi resolvido

**notes:**
**Candidato a promoção como Shared Type.** Aguardando shared-types v1.1.0 — a Delivery v2
convergiu para `alters_state=false` em 2026-07-25, satisfazendo o CRT-02 bloqueante.
A promoção de `Shared.Impediment.Resolved` para Active será o desbloqueio para deprecar
este tipo Journey. Quando shared-types v1.1.0 for publicado, este tipo será marcado como
Deprecated com `replacement_type: Shared.Impediment.Resolved`. Par complementar: Impediment.Declared.

**owner_journey:** Assessment

---

## Eventos de Sistema — System

---

### Threshold.Crossed

| Campo | Valor |
|---|---|
| **name** | `Threshold.Crossed` |
| **category** | System |
| **alters_state** | `false` |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Uma métrica derivada das Timelines cruzou um limiar predefinido durante o monitoramento
contínuo. O cruzamento é registrado como observação — não altera o estado do ciclo de
monitoramento. Múltiplos Threshold.Crossed podem preceder um Alert.Raised. O sistema
avalia se o conjunto de limiares cruzados justifica um alerta formal.

**preconditions:**
- O Work Item está no estado MONITORING
- Uma métrica operacional derivada das Timelines ultrapassou o valor limiar configurado

**postconditions:**
- O cruzamento do limiar está registrado na Timeline
- O Derived State permanece MONITORING
- O sistema avalia se Alert.Raised deve ser emitido

**payload_shape:**
- `metric_name` (string, obrigatório): nome da métrica que cruzou o limiar (ex.: `gate_failure_rate`, `cycle_time_p95`)
- `threshold_value` (string, obrigatório): valor do limiar configurado
- `actual_value` (string, obrigatório): valor real medido que cruzou o limiar
- `direction` (string, obrigatório): `above` — métrica ultrapassou limiar superior; `below` — ficou abaixo do limiar inferior
- `measurement_window` (string, obrigatório): janela temporal da medição (ex.: `30d`, `7d`)

**owner_journey:** Assessment

---

### Evolve.Proposed

| Campo | Valor |
|---|---|
| **name** | `Evolve.Proposed` |
| **category** | System |
| **alters_state** | `false` |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Uma proposta de evolução incremental foi gerada durante o monitoramento contínuo — sem
necessidade de um ciclo Assessment Sync completo. O sistema ou agente identificou uma
melhoria específica, localizada e de baixo risco que pode ser proposta diretamente para
avaliação. O Derived State permanece MONITORING.

**preconditions:**
- O Work Item está no estado MONITORING
- O sistema identificou uma oportunidade de evolução incremental com evidência suficiente

**postconditions:**
- A proposta de evolução está registrada na Timeline
- O Derived State permanece MONITORING
- A proposta pode ser aceita ou ignorada — não aciona Assessment Sync automaticamente

**payload_shape:**
- `proposal_title` (string, obrigatório): título curto da proposta
- `proposal_description` (string, obrigatório): descrição detalhada da evolução proposta
- `target_journey` (string, opcional): Journey alvo da proposta (`Delivery`, `Diligence`, `Framework`)
- `evidence_summary` (string, obrigatório): resumo das evidências que fundamentam a proposta

**owner_journey:** Assessment

---

## Fluxos de referência

### Fluxo feliz — Assessment Sync completo

```
Timeline: Assessment-2026-Q2
────────────────────────────────────────────────────
Assessment Sync
  1. Collect.Started      → COLLECTING
     [trigger: cadence, window: 2026-Q2]
  2. Gate.Passed          (data-completeness)
  3. Collect.Completed    → COLLECTED (45 timelines, complete)
  4. Analyze.Started      → ANALYZING
  5. Recommendation.Issued (alters_state=false)
     [Lead Time P95 aumentou 28% — investigar Bootstrap]
  6. Opportunity.Identified (alters_state=false)
     [Gate Failure Rate decrescente — padrão positivo]
  7. Analyze.Completed    → ANALYZED
     [4 métricas calculadas, 3 padrões, 2 findings correlacionados]
  8. Synthesize.Completed → SYNTHESIZED
     [3 insights, 2 recommendations, trend=mixed]
  9. Gate.Passed          (recommendation-evidence)
 10. Report.Approved      → REPORTING
 11. Report.Published     → DONE
────────────────────────────────────────────────────
Derived State final: DONE
Events alters_state=true: 7 | false: 4
```

### Fluxo com rejeição de Report

```
Timeline: Assessment-2026-Q3
────────────────────────────────────────────────────
  1. Collect.Started      → COLLECTING
  2. Collect.Completed    → COLLECTED
  3. Analyze.Started      → ANALYZING
  4. Analyze.Completed    → ANALYZED
  5. Synthesize.Completed → SYNTHESIZED
  6. Gate.Failed          (recommendation-evidence)
     [2 recommendations sem evidência citada]
  7. Report.Rejected      → SYNTHESIZED [rejeição: evidências insuficientes]
  [re-síntese com evidências complementadas]
  8. Synthesize.Completed → SYNTHESIZED
  9. Gate.Passed          (recommendation-evidence)
 10. Report.Approved      → REPORTING
 11. Report.Published     → DONE
────────────────────────────────────────────────────
Ciclos de síntese: 2
```

### Fluxo de monitoramento com alerta

```
Timeline: Monitor-2026-Q3
────────────────────────────────────────────────────
Assessment Async
  1. Monitor.Activated    → MONITORING
     [métricas: gate_failure_rate, cycle_time, block_time]
  2. Threshold.Crossed    (gate_failure_rate: threshold=15%, actual=23%)
     (alters_state=false)
  3. Threshold.Crossed    (cycle_time_p95: threshold=5d, actual=8d)
     (alters_state=false)
  4. Evolve.Proposed      (alters_state=false)
     [proposta: revisar critérios de lint gate — 40% das falhas são lint]
  5. Alert.Raised         → ALERTED (severity=high)
     [dois limiares críticos cruzados simultaneamente]
────────────────────────────────────────────────────
→ Assessment Sync acionada (Assessment-2026-Q3-Alert)
→ novo Monitor.Activated no ciclo seguinte
```

### Fluxo com impedimento — Lookback em ação

```
Timeline: Assessment-2026-Q4
────────────────────────────────────────────────────
  1. Collect.Started      → COLLECTING
  2. Impediment.Declared  → BLOCKED
     [acesso às Timelines de Delivery negado — credenciais expiradas]
  3. Impediment.Resolved  → alters_state=false
     [Lookback → retorna COLLECTING]
  4. Collect.Completed    → COLLECTED
  5. Analyze.Started      → ANALYZING
  ...

Lookback em pos 3:
  Impediment.Declared encontrado em pos 2
  Busca antes de pos 2: pos 1 = Collect.Started, new_state=COLLECTING (≠ BLOCKED)
  Estado de retorno: COLLECTING ✓
────────────────────────────────────────────────────
```

---

*Todos os 19 Event Types neste catálogo satisfazem o Event Type Schema v1.0.0.*
*Versão do catálogo: 2.0.0. Active: 16. Deprecated: 3 (Gate.Passed, Gate.Failed, Impediment.Declared). Impediment.Resolved: Active — aguarda shared-types v1.1.0 para deprecação formal.*
