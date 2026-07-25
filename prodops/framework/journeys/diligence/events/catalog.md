# Diligence Event Catalog — v2
# ProdOps Framework — Jornada Diligence

> **Versão:** 2.0.0
> **Status:** Active
> **Namespace:** `Diligence`
> **Journey:** Diligence
> **Schema:** [Event Type Schema v1.0.0](../../../../events/event-type-schema.md)
> **Changelog v2.0.0:** Gate.Passed, Gate.Failed, Impediment.Declared → Deprecated (promovidos a Shared Types Active). Impediment.Resolved → aguarda shared-types v1.1.0 para deprecação formal.

---

## Visão geral

| # | Event Type | Category | alters_state | new_state | Producers | Status v2 |
|---|---|---|---|---|---|---|
| 1 | Capture.Started | Phase Lifecycle | true | CAPTURING | Human, Agent | Active |
| 2 | Capture.Completed | Phase Lifecycle | true | CAPTURED | Human, Agent | Active |
| 3 | Attach.Completed | Phase Lifecycle | true | ATTACHED | Human, Agent | Active |
| 4 | Promote.Completed | Phase Lifecycle | true | PROMOTED | Human, Agent | Active |
| 5 | Close.Completed | Phase Lifecycle | true | DONE | Human, Agent | Active |
| 6 | Scan.Started | Phase Lifecycle | true | SCANNING | Agent | Active |
| 7 | Scan.Completed | Phase Lifecycle | true | SCANNED | Agent | Active |
| 8 | Flag.Completed | Phase Lifecycle | true | FLAGGED | Agent | Active |
| 9 | Repair.Started | Phase Lifecycle | true | REPAIRING | Human, Agent | Active |
| 10 | Repair.Completed | Phase Lifecycle | true | REPAIRED | Human, Agent | Active |
| 11 | Promote.Approved | Human Decision | true | PROMOTING | Human | Active |
| 12 | Promote.Rejected | Human Decision | false | — | Human | Active |
| 13 | Waiver.Granted | Human Decision | true | WAIVED | Human | Active |
| 14 | Waiver.Rejected | Human Decision | false | — | Human | Active |
| 15 | Gate.Passed | Gate | false | — | System, Agent | **Deprecated** → Shared.Gate.Passed |
| 16 | Gate.Failed | Gate | false | — | System, Agent | **Deprecated** → Shared.Gate.Failed |
| 17 | Impediment.Declared | Blocking | true | BLOCKED | Human, Agent | **Deprecated** → Shared.Impediment.Declared |
| 18 | Impediment.Resolved | Blocking | false | — | Human | Active — aguarda Shared.Impediment.Resolved (shared-types v1.1.0) |
| 19 | Divergence.Detected | Diligence | false | — | Agent | Active |
| 20 | Finding.Recorded | Diligence | false | — | Agent | Active |

---

## Diligence Sync — Capture

---

### Capture.Started

| Campo | Valor |
|---|---|
| **name** | `Capture.Started` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `CAPTURING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O registro de um novo Work Item na Jornada Diligence foi iniciado. O Work Item está sendo
capturado — suas informações básicas estão sendo verificadas e registradas no sistema antes
de ser formalmente associado ao projeto gerenciado.

**preconditions:**
- O Work Item (OBC ou Issue) existe e foi identificado como candidato à captura
- O Work Item ainda não possui Timeline na Jornada Diligence

**postconditions:**
- O Work Item transita para o estado CAPTURING
- A Timeline da Diligence para este Work Item é criada com este evento

**payload_shape:**
- `source_id` (string, obrigatório): identificador do Work Item de origem (ex.: número do Issue no GitHub)
- `capture_reason` (string, obrigatório): motivo pelo qual o Work Item está sendo capturado

**owner_journey:** Diligence

---

### Capture.Completed

| Campo | Valor |
|---|---|
| **name** | `Capture.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `CAPTURED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Work Item foi capturado com sucesso. Todas as informações obrigatórias foram verificadas
e o registro está completo. O Work Item aguarda associação ao projeto gerenciado (Attach).

**preconditions:**
- O Work Item está no estado CAPTURING
- Todas as propriedades obrigatórias do Work Item foram verificadas e estão completas
- O Work Item não está duplicado no sistema

**postconditions:**
- O Work Item transita para o estado CAPTURED
- O registro está completo e pronto para o step de Attach

**owner_journey:** Diligence

---

## Diligence Sync — Attach

---

### Attach.Completed

| Campo | Valor |
|---|---|
| **name** | `Attach.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `ATTACHED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Work Item foi associado com sucesso ao projeto gerenciado da Diligence. A partir deste
evento, o Work Item é visível nas views do projeto e pode ser gerenciado pelo ciclo de
promoção. O Work Item aguarda revisão humana para aprovação de promoção.

**preconditions:**
- O Work Item está no estado CAPTURED
- O projeto gerenciado da Diligence existe e está acessível
- O Work Item não estava previamente associado ao projeto

**postconditions:**
- O Work Item transita para o estado ATTACHED
- O Work Item é membro do projeto gerenciado
- O Work Item aparece nas views relevantes do projeto

**payload_shape:**
- `project_id` (string, obrigatório): identificador do projeto gerenciado ao qual o Work Item foi associado
- `project_item_id` (string, obrigatório): identificador do item no projeto após associação

**owner_journey:** Diligence

---

## Diligence Sync — Promote

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
| **replacement_type** | `Shared.Gate.Passed` — ver [shared-types.md](../../../../events/shared-types.md) |

**description:**
Um gate automatizado de verificação passou com sucesso. Na Jornada Diligence, gates
verificam critérios de readiness antes da promoção — completude de campos obrigatórios,
presença de labels canônicas, conformidade com padrões de nomenclatura. O Derived State
não é alterado.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado

**postconditions:**
- O gate está registrado como passante na Timeline
- O Derived State permanece inalterado

**payload_shape:**
- `gate_name` (string, obrigatório): identificador do gate executado (ex.: `readiness-check`, `label-conformance`)
- `duration_ms` (integer, obrigatório): duração da execução em milissegundos

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas que referenciam este tipo continuam válidas — o tipo
permanece no catálogo como referência histórica somente leitura. Novas emissões devem usar
`Shared.Gate.Passed`. Par complementar: Gate.Failed.

**owner_journey:** Diligence

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
| **replacement_type** | `Shared.Gate.Failed` — ver [shared-types.md](../../../../events/shared-types.md) |

**description:**
Um gate automatizado de verificação falhou. O critério verificado não foi satisfeito. O
Work Item permanece no estado atual — o Producer deve tomar ação corretiva antes de uma
nova tentativa de aprovação.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado e produziu resultado de falha

**postconditions:**
- A falha do gate está registrada na Timeline
- O Derived State permanece inalterado
- Cabe ao Producer avaliar se Promote.Rejected deve ser emitido

**payload_shape:**
- `gate_name` (string, obrigatório): identificador do gate executado
- `reason` (string, obrigatório): descrição do critério que falhou
- `duration_ms` (integer, obrigatório): duração da execução em milissegundos

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas continuam válidas. Novas emissões devem usar
`Shared.Gate.Failed`. Par complementar: Gate.Passed.

**owner_journey:** Diligence

---

### Promote.Approved

| Campo | Valor |
|---|---|
| **name** | `Promote.Approved` |
| **category** | Human Decision |
| **alters_state** | `true` |
| **new_state** | `PROMOTING` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um responsável humano aprovou a promoção do Work Item para o estado de readiness. A
aprovação sinaliza que o Work Item satisfaz os critérios de qualidade da Diligence e
pode ser formalmente promovido.

**preconditions:**
- O Work Item está no estado ATTACHED
- Os gates de readiness foram executados com sucesso (Gate.Passed na Timeline)
- A revisão humana foi concluída

**postconditions:**
- O Work Item transita para o estado PROMOTING
- A promoção pode ser executada (Promote.Completed será emitido pelo sistema ou agente)

**payload_shape:**
- `approver` (string, obrigatório): identidade do responsável que aprovou
- `readiness_criteria` (string, obrigatório): descrição dos critérios satisfeitos para aprovação

**notes:**
**Semanticamente diferente de `Promote.Approved` na Delivery.** Na Delivery, essa
aprovação autoriza implantação em produção. Na Diligence, autoriza a promoção no backlog
(avanço de readiness). As precondições, pós-condições e contexto são distintos — não
são candidatos a Shared Type.

**owner_journey:** Diligence

---

### Promote.Rejected

| Campo | Valor |
|---|---|
| **name** | `Promote.Rejected` |
| **category** | Human Decision |
| **alters_state** | `false` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um responsável humano rejeitou a promoção do Work Item. O Work Item não satisfez os
critérios necessários para avançar de readiness. O estado permanece ATTACHED — o Producer
deve corrigir as deficiências e submeter para nova revisão.

**preconditions:**
- O Work Item está no estado ATTACHED
- Uma revisão humana foi realizada e o Work Item não atende aos critérios

**postconditions:**
- O Derived State permanece ATTACHED
- O motivo da rejeição está registrado na Timeline
- Nova revisão pode ser solicitada após as correções necessárias

**payload_shape:**
- `rejector` (string, obrigatório): identidade do responsável que rejeitou
- `reason` (string, obrigatório): descrição do critério não satisfeito

**owner_journey:** Diligence

---

### Promote.Completed

| Campo | Valor |
|---|---|
| **name** | `Promote.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `PROMOTED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Work Item foi promovido com sucesso ao nível de readiness. A promoção foi executada
após aprovação humana (Promote.Approved). O Work Item aguarda fechamento formal pelo
responsável.

**preconditions:**
- O Work Item está no estado PROMOTING
- Promote.Approved foi registrado na Timeline antes deste evento

**postconditions:**
- O Work Item transita para o estado PROMOTED
- O Work Item está formalmente no nível de readiness atingido

**notes:**
**Semanticamente diferente de `Promote.Completed` na Delivery.** Na Delivery, representa
implantação em produção com estado final DONE. Na Diligence, representa promoção de
readiness no backlog — não é o estado final (Close.Completed ainda é necessário).

**owner_journey:** Diligence

---

## Diligence Sync — Close

---

### Close.Completed

| Campo | Valor |
|---|---|
| **name** | `Close.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `DONE` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O ciclo Diligence Sync foi encerrado com sucesso. O Work Item foi promovido e formalmente
fechado pelo responsável. O estado DONE indica que o ciclo Sync está concluído para este
Work Item — o ciclo Async pode ser iniciado em iterações futuras.

**preconditions:**
- O Work Item está no estado PROMOTED
- Promote.Completed foi registrado na Timeline
- O responsável confirmou o fechamento

**postconditions:**
- O Work Item transita para o estado DONE
- O ciclo Diligence Sync está encerrado
- A Timeline permanece aberta para eventos de correção e para o ciclo Async futuro

**owner_journey:** Diligence

---

## Diligence Async — Scan

---

### Scan.Started

| Campo | Valor |
|---|---|
| **name** | `Scan.Started` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `SCANNING` |
| **producer_subtypes** | `[Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O ciclo assíncrono de varredura foi iniciado para o Work Item. O agente de Diligence está
verificando a conformidade do Work Item em relação aos critérios definidos — labels,
campos obrigatórios, associação ao projeto, estados esperados.

**preconditions:**
- O Work Item possui uma Timeline ativa na Jornada Diligence
- O ciclo de varredura programado foi acionado

**postconditions:**
- O Work Item transita para o estado SCANNING
- O agente de Diligence está executando as verificações

**payload_shape:**
- `scan_cycle` (string, obrigatório): identificador do ciclo de varredura (ex.: `2026-Q3-W30`)
- `criteria_version` (string, obrigatório): versão dos critérios de conformidade aplicados

**owner_journey:** Diligence

---

### Divergence.Detected

| Campo | Valor |
|---|---|
| **name** | `Divergence.Detected` |
| **category** | Diligence |
| **alters_state** | `false` |
| **producer_subtypes** | `[Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Uma divergência em relação aos critérios de conformidade foi detectada durante a varredura.
Cada divergência encontrada gera um evento separado — múltiplos eventos podem ser emitidos
durante o mesmo ciclo de varredura. O Derived State permanece SCANNING.

**preconditions:**
- O Work Item está no estado SCANNING
- O agente identificou uma divergência específica durante a varredura

**postconditions:**
- A divergência está registrada na Timeline com descrição
- O Derived State permanece SCANNING
- A divergência será avaliada ao final da varredura (Scan.Completed)

**payload_shape:**
- `divergence_type` (string, obrigatório): categoria da divergência detectada (ex.: `missing-label`, `stale-state`, `missing-required-field`)
- `divergence_description` (string, obrigatório): descrição detalhada da divergência encontrada
- `severity` (string, obrigatório): severidade da divergência (`high`, `medium`, `low`)

**owner_journey:** Diligence

---

### Finding.Recorded

| Campo | Valor |
|---|---|
| **name** | `Finding.Recorded` |
| **category** | Diligence |
| **alters_state** | `false` |
| **producer_subtypes** | `[Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um achado específico de auditoria foi registrado para o Work Item durante a varredura.
Diferente de Divergence.Detected (que registra uma não-conformidade operacional), o
Finding documenta uma observação estrutural que pode ou não requerer ação imediata.

**preconditions:**
- O Work Item está no estado SCANNING
- O agente identificou um achado relevante para auditoria

**postconditions:**
- O achado está registrado na Timeline
- O Derived State permanece SCANNING
- O achado estará disponível para análise de Assessment

**payload_shape:**
- `finding_type` (string, obrigatório): categoria do achado (ex.: `stale-timeline`, `missing-evidence`, `producer-anomaly`)
- `finding_description` (string, obrigatório): descrição detalhada do achado
- `action_required` (boolean, obrigatório): indica se o achado requer ação corretiva

**owner_journey:** Diligence

---

### Scan.Completed

| Campo | Valor |
|---|---|
| **name** | `Scan.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `SCANNED` |
| **producer_subtypes** | `[Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O ciclo assíncrono de varredura foi concluído para o Work Item. Todas as verificações
foram executadas. O resultado (divergências e achados) está registrado na Timeline.
O próximo evento será Flag.Completed (se divergências foram encontradas) ou nenhum
(se a varredura resultou em conformidade total).

**preconditions:**
- O Work Item está no estado SCANNING
- Todas as verificações do ciclo de varredura foram executadas

**postconditions:**
- O Work Item transita para o estado SCANNED
- Todos os Divergence.Detected e Finding.Recorded do ciclo estão registrados
- O agente avaliará se Flag.Completed deve ser emitido

**payload_shape:**
- `scan_cycle` (string, obrigatório): identificador do ciclo de varredura concluído
- `divergences_found` (integer, obrigatório): quantidade de divergências detectadas
- `findings_found` (integer, obrigatório): quantidade de achados registrados
- `compliant` (boolean, obrigatório): `true` se nenhuma divergência foi detectada

**owner_journey:** Diligence

---

## Diligence Async — Flag

---

### Flag.Completed

| Campo | Valor |
|---|---|
| **name** | `Flag.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `FLAGGED` |
| **producer_subtypes** | `[Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
As divergências encontradas durante a varredura foram formalmente sinalizadas. O Work Item
requer ação corretiva — reparo das divergências ou concessão de waiver. O estado FLAGGED
indica que o Work Item não está em conformidade e precisa de atenção.

**preconditions:**
- O Work Item está no estado SCANNED
- Pelo menos um Divergence.Detected foi registrado no ciclo de varredura
- `compliant = false` no Scan.Completed correspondente

**postconditions:**
- O Work Item transita para o estado FLAGGED
- As divergências estão formalmente sinalizadas e aguardam ação
- Repair.Started ou Waiver.Granted são os próximos eventos esperados

**payload_shape:**
- `flagged_divergences_count` (integer, obrigatório): quantidade de divergências sinalizadas
- `highest_severity` (string, obrigatório): severidade mais alta entre as divergências sinalizadas

**owner_journey:** Diligence

---

## Diligence Async — Repair

---

### Repair.Started

| Campo | Valor |
|---|---|
| **name** | `Repair.Started` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `REPAIRING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O processo de reparo das divergências sinalizadas foi iniciado. O responsável (humano
ou agente) está aplicando as correções necessárias para restaurar a conformidade do
Work Item.

**preconditions:**
- O Work Item está no estado FLAGGED
- O responsável pelo reparo foi identificado

**postconditions:**
- O Work Item transita para o estado REPAIRING
- O reparo está em andamento

**payload_shape:**
- `repairer` (string, obrigatório): identidade do responsável pelo reparo
- `repair_plan` (string, obrigatório): descrição das ações de reparo planejadas

**owner_journey:** Diligence

---

### Repair.Completed

| Campo | Valor |
|---|---|
| **name** | `Repair.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `REPAIRED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O reparo das divergências foi concluído com sucesso. O Work Item está em conformidade.
O ciclo Diligence Async está encerrado para esta iteração — o Work Item poderá ser
varrido novamente em ciclos futuros.

**preconditions:**
- O Work Item está no estado REPAIRING
- Todas as divergências sinalizadas foram corrigidas
- O agente ou humano confirmou a conclusão do reparo

**postconditions:**
- O Work Item transita para o estado REPAIRED
- O Work Item está em conformidade com os critérios da Diligence
- A Timeline permanece aberta para ciclos futuros de varredura

**payload_shape:**
- `repairs_applied` (integer, obrigatório): quantidade de correções aplicadas
- `verification_result` (string, obrigatório): descrição da verificação pós-reparo

**owner_journey:** Diligence

---

## Eventos Transversais — Human Decision (Waiver)

---

### Waiver.Granted

| Campo | Valor |
|---|---|
| **name** | `Waiver.Granted` |
| **category** | Human Decision |
| **alters_state** | `true` |
| **new_state** | `WAIVED` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Uma exceção formal foi concedida para uma ou mais divergências sinalizadas. O waiver
representa uma decisão explícita de que a divergência é aceitável nas circunstâncias
atuais — sem necessidade de reparo. O Work Item transita para WAIVED — estado de
exceção aprovada.

**preconditions:**
- O Work Item está no estado FLAGGED
- Uma solicitação de waiver foi apresentada e avaliada por responsável autorizado

**postconditions:**
- O Work Item transita para o estado WAIVED
- A exceção está registrada formalmente com justificativa
- O Work Item não precisa de reparo para as divergências cobertas pelo waiver

**payload_shape:**
- `waiver_authority` (string, obrigatório): identidade de quem concedeu o waiver
- `justification` (string, obrigatório): justificativa formal para a concessão do waiver
- `waiver_scope` (string, obrigatório): quais divergências específicas estão cobertas pelo waiver
- `expiration` (string, opcional): ciclo ou data em que o waiver expira e deve ser reavaliado

**notes:**
Conceito exclusivo da Jornada Diligence — não existe equivalente no catálogo da Delivery.
O Waiver formaliza a gestão de exceções operacionais.

**owner_journey:** Diligence

---

### Waiver.Rejected

| Campo | Valor |
|---|---|
| **name** | `Waiver.Rejected` |
| **category** | Human Decision |
| **alters_state** | `false` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A solicitação de waiver foi rejeitada. As divergências sinalizadas não foram aceitas como
excepcionáveis — o Work Item deve ser reparado. O estado permanece FLAGGED e Repair.Started
é o próximo evento esperado.

**preconditions:**
- O Work Item está no estado FLAGGED
- Uma solicitação de waiver foi avaliada e rejeitada

**postconditions:**
- O Derived State permanece FLAGGED
- O motivo da rejeição está registrado na Timeline
- Repair.Started é o próximo evento esperado

**payload_shape:**
- `rejector` (string, obrigatório): identidade de quem rejeitou o waiver
- `reason` (string, obrigatório): motivo da rejeição

**owner_journey:** Diligence

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
| **replacement_type** | `Shared.Impediment.Declared` — ver [shared-types.md](../../../../events/shared-types.md) |

**description:**
Um impedimento externo foi declarado para o Work Item. O trabalho da Diligence não pode
progredir até que o impedimento seja resolvido. Pode ocorrer em qualquer fase dos ciclos
Sync ou Async.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED, não REPAIRED, não WAIVED)
- Um impedimento externo foi identificado que impede a progressão

**postconditions:**
- O Work Item transita para o estado BLOCKED
- O trabalho é suspenso até Impediment.Resolved

**payload_shape:**
- `impediment_description` (string, obrigatório): descrição do impedimento e de quem pode resolvê-lo
- `blocking_since` (string, obrigatório): timestamp de quando o impedimento foi identificado

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas que referenciam este tipo continuam válidas. Novas
emissões devem usar `Shared.Impediment.Declared`. Par complementar: Impediment.Resolved.

**owner_journey:** Diligence

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
O impedimento externo foi resolvido e o trabalho pode ser retomado. O Work Item retorna
ao estado em que estava antes do impedimento ser declarado.

O estado de retorno **não está hardcoded** neste tipo — o Consumer usa o mecanismo de
Lookback (`preBlockedState`) definido no `timeline.md` para calcular o estado anterior
ao BLOCKED. Esta é a implementação refinada do mecanismo, diferente da simplificação
adotada no catálogo MVP da Delivery.

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
**Candidato a promoção como Shared Type.** Aguardando shared-types v1.1.0 — bloqueado
pela necessidade de convergência técnica da Delivery v2 (concluída). A promoção de
`Shared.Impediment.Resolved` para Active será o desbloqueio para deprecar este tipo
Journey. Quando shared-types v1.1.0 for publicado, este tipo será marcado como
Deprecated com `replacement_type: Shared.Impediment.Resolved`.

**owner_journey:** Diligence

---

## Fluxos de referência

### Fluxo feliz — Diligence Sync completo

```
Timeline: OBC-Checkout
────────────────────────────────────────────────────
Diligence Sync
  1. Capture.Started    → CAPTURING
  2. Capture.Completed  → CAPTURED
  3. Attach.Completed   → ATTACHED
  4. Gate.Passed        (readiness-check)
  5. Promote.Approved   → PROMOTING
  6. Promote.Completed  → PROMOTED
  7. Close.Completed    → DONE
────────────────────────────────────────────────────
Derived State: DONE
Events alters_state=true: 6 | false: 1
```

### Fluxo com divergência e reparo — Diligence Async

```
Timeline: OBC-Checkout (continuação do Sync acima)
────────────────────────────────────────────────────
Diligence Async (iteração Q3)
  8. Scan.Started        → SCANNING
  9. Divergence.Detected  (missing-label, high)
 10. Finding.Recorded    (stale-timeline, action_required=false)
 11. Scan.Completed      → SCANNED (compliant=false, divergences=1)
 12. Flag.Completed      → FLAGGED
 13. Repair.Started      → REPAIRING
 14. Repair.Completed    → REPAIRED
────────────────────────────────────────────────────
Derived State: REPAIRED
```

### Fluxo com waiver

```
  8. Scan.Started        → SCANNING
  9. Divergence.Detected  (legacy-field, low)
 10. Scan.Completed      → SCANNED (compliant=false, divergences=1)
 11. Flag.Completed      → FLAGGED
 12. Waiver.Granted      → WAIVED (justification: "campo legado, migração Q4")
────────────────────────────────────────────────────
Derived State: WAIVED
```

### Fluxo com impedimento — Lookback em ação

```
  8. Scan.Started        → SCANNING
  9. Impediment.Declared → BLOCKED
 10. Impediment.Resolved → alters_state=false [Lookback → retorna SCANNING]
 11. Divergence.Detected  (missing-label, medium)
 12. Scan.Completed      → SCANNED (compliant=false)
 13. Flag.Completed      → FLAGGED
 14. Repair.Started      → REPAIRING
 15. Repair.Completed    → REPAIRED

Lookback em pos 10:
  Impediment.Declared encontrado em pos 9
  Busca antes de pos 9: pos 8 = Scan.Started, new_state=SCANNING (≠ BLOCKED)
  Estado de retorno: SCANNING  ✓
```

---

*Todos os 20 Event Types neste catálogo satisfazem o Event Type Schema v1.0.0.*
*Versão do catálogo: 2.0.0. Active: 17. Deprecated: 3 (Gate.Passed, Gate.Failed, Impediment.Declared). Impediment.Resolved: Active — aguarda shared-types v1.1.0 para deprecação formal.*
