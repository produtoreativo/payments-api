# Delivery Event Catalog — v2
# ProdOps Framework — Jornada Delivery

> **Versão:** 2.0.0
> **Status:** Active
> **Namespace:** `Delivery`
> **Journey:** Delivery
> **Schema:** [Event Type Schema v1.0.0](../../../events/event-type-schema.md)
> **Changelog v2.0.0:** Gate.Passed, Gate.Failed, Impediment.Declared → Deprecated (promovidos a Shared Types Active). Impediment.Resolved → convergência técnica: alters_state=false, Lookback. Cutover: 2026-07-25. Preparado para deprecação após shared-types v1.1.0.

---

## Visão geral

| # | Event Type | Category | alters_state | new_state | Producers | Status v2 |
|---|---|---|---|---|---|---|
| 1 | Bootstrap.Started | Phase Lifecycle | true | BOOTSTRAPPING | Human, Agent | Active |
| 2 | Bootstrap.Completed | Phase Lifecycle | true | HACKING | Human, Agent | Active |
| 3 | Hack.Completed | Phase Lifecycle | true | SYNCING | Human, Agent | Active |
| 4 | Sync.Completed | Phase Lifecycle | true | FINISHING | System | Active |
| 5 | Finish.Completed | Phase Lifecycle | true | SHIPPING | Human, Agent | Active |
| 6 | Ship.Completed | Phase Lifecycle | true | VALIDATING | System | Active |
| 7 | Promote.Completed | Phase Lifecycle | true | DONE | System | Active |
| 8 | Gate.Passed | Gate | false | — | System, Agent | **Deprecated** → Shared.Gate.Passed |
| 9 | Gate.Failed | Gate | false | — | System, Agent | **Deprecated** → Shared.Gate.Failed |
| 10 | Promote.Approved | Human Decision | true | PROMOTING | Human | Active |
| 11 | Promote.Rejected | Human Decision | true | VALIDATING | Human | Active |
| 12 | Impediment.Declared | Blocking | true | BLOCKED | Human, Agent | **Deprecated** → Shared.Impediment.Declared |
| 13 | Impediment.Resolved | Blocking | false | — (Lookback) | Human | Active — convergido v2 |
| 14 | Rework.Declared | Rework | true | HACKING | Human, Agent | Active |
| 15 | Rework.Completed | Rework | true | SYNCING | Human, Agent | Active |

---

## CI Sync — Bootstrap

---

### Bootstrap.Started

| Campo | Valor |
|---|---|
| **name** | `Bootstrap.Started` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `BOOTSTRAPPING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Work Item iniciou a Phase de Bootstrap. O ambiente de trabalho está sendo preparado:
o branch será criado, dependências serão instaladas, e o smoke gate inicial será executado.

**preconditions:**
- O Work Item está ativo no backlog com definição de done completa
- O Work Item não está em nenhum state ativo anterior (primeiro evento de state da Timeline)
- Não existe outro Work Item em BOOTSTRAPPING para o mesmo developer no mesmo ciclo

**postconditions:**
- O Work Item transita para o estado BOOTSTRAPPING
- A Timeline registra Bootstrap.Started como primeiro evento de state

**payload_shape:**
- `assignee` (string, obrigatório): identidade do developer que iniciou o Bootstrap
- `base_branch` (string, obrigatório): nome do branch base do repositório

**owner_journey:** Delivery

---

### Bootstrap.Completed

| Campo | Valor |
|---|---|
| **name** | `Bootstrap.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `HACKING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A Phase de Bootstrap foi concluída com sucesso. O branch de trabalho foi criado, o
ambiente está configurado, e o smoke gate inicial passou. O Work Item está pronto para
desenvolvimento ativo.

**preconditions:**
- O Work Item está no estado BOOTSTRAPPING
- O branch de trabalho foi criado com sucesso
- O smoke gate inicial passou (Gate.Passed foi registrado na Timeline antes deste evento)

**postconditions:**
- O Work Item transita para o estado HACKING
- A Timeline contém Bootstrap.Started seguido de Bootstrap.Completed

**payload_shape:**
- `branch_name` (string, obrigatório): nome do branch criado para o Work Item
- `base_commit` (string, obrigatório): hash do commit base do branch

**owner_journey:** Delivery

---

## CI Sync — Hack

---

### Hack.Completed

| Campo | Valor |
|---|---|
| **name** | `Hack.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `SYNCING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A implementação do Work Item foi concluída pelo developer. Um Pull Request foi aberto para
revisão de código. O Work Item aguarda revisão pelos peers.

**preconditions:**
- O Work Item está no estado HACKING
- Pelo menos um commit foi adicionado ao branch de trabalho
- Um Pull Request foi aberto apontando para o branch base

**postconditions:**
- O Work Item transita para o estado SYNCING
- A Timeline registra Hack.Completed com referência ao PR aberto

**payload_shape:**
- `pr_number` (integer, obrigatório): número do Pull Request aberto
- `pr_title` (string, obrigatório): título do Pull Request
- `commits_count` (integer, obrigatório): quantidade de commits no PR

**owner_journey:** Delivery

---

## CI Sync — Sync

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
Um gate automatizado de qualidade passou com sucesso. O gate verifica um critério específico
de qualidade — lint, testes, cobertura, segurança — sem alterar o estado do Work Item.
Múltiplos Gate.Passed podem ocorrer na mesma Timeline em Phases diferentes.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado

**postconditions:**
- O gate está registrado como passante na Timeline
- O Derived State não é alterado

**payload_shape:**
- `gate_name` (string, obrigatório): identificador do gate executado (ex.: `smoke-test`, `lint`, `unit-tests`)
- `duration_ms` (integer, obrigatório): duração da execução do gate em milissegundos

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas que referenciam este tipo continuam válidas — o tipo
permanece no catálogo como referência histórica somente leitura. Novas emissões devem usar
`Shared.Gate.Passed`. Par complementar: Gate.Failed.

**owner_journey:** Delivery

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
Um gate automatizado de qualidade falhou. O gate verificou um critério de qualidade que
não foi satisfeito. O Work Item permanece no estado atual — a falha do gate é um sinal
para que o Producer inicie correção (Rework ou nova tentativa).

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado e produziu resultado de falha

**postconditions:**
- A falha do gate está registrada na Timeline
- O Derived State não é alterado
- O Producer é responsável por declarar Rework.Declared se a falha exigir retorno ao desenvolvimento

**payload_shape:**
- `gate_name` (string, obrigatório): identificador do gate executado
- `reason` (string, obrigatório): descrição da causa da falha
- `duration_ms` (integer, obrigatório): duração da execução do gate em milissegundos

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas continuam válidas. Novas emissões devem usar
`Shared.Gate.Failed`. Par complementar: Gate.Passed.

**owner_journey:** Delivery

---

### Sync.Completed

| Campo | Valor |
|---|---|
| **name** | `Sync.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `FINISHING` |
| **producer_subtypes** | `[System]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A Phase de Sync foi concluída. A feature branch incorporou as mudanças mais recentes da
origin (fetch + rebase) e os artefatos ProdOps foram alinhados com o estado atual da
implementação (BDD Features, Event Storming, arquitetura, Release Trail). Sync não publica
nem atualiza a origin — apenas sincroniza o estado local com o que já existe nela.

**preconditions:**
- O Work Item está no estado SYNCING
- O fetch + rebase da feature branch sobre a origin foi executado sem conflitos não resolvidos
- Os artefatos ProdOps foram verificados e estão alinhados com o estado atual da implementação

**postconditions:**
- O Work Item transita para o estado FINISHING
- A feature branch está atualizada com a origin
- Os artefatos ProdOps refletem o estado atual da implementação
- Nenhuma alteração foi publicada na origin

**payload_shape:**
- `rebase_commit` (string, obrigatório): hash do commit de HEAD após o rebase
- `base_branch` (string, obrigatório): branch base usado no rebase (ex.: `master`)
- `aligned_artifacts` (array, opcional): lista de artefatos ProdOps verificados (ex.: `["bdd", "event-storming", "release-trail"]`)

**owner_journey:** Delivery

---

## CI Sync — Finish

---

### Finish.Completed

| Campo | Valor |
|---|---|
| **name** | `Finish.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `SHIPPING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
A Phase de Finish foi concluída. As checagens finais do CI Sync foram satisfeitas — o
Work Item está validado e pronto para o ciclo assíncrono de entrega. A partir deste evento,
o Work Item entra no CI Async.

**preconditions:**
- O Work Item está no estado FINISHING
- Os critérios de done do CI Sync estão satisfeitos (testes passando, cobertura mínima atingida)

**postconditions:**
- O Work Item transita para o estado SHIPPING
- O CI Sync está encerrado para este Work Item
- O Work Item pode ser incluído no próximo ciclo de Ship

**owner_journey:** Delivery

---

## CI Async — Ship

---

### Ship.Completed

| Campo | Valor |
|---|---|
| **name** | `Ship.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `VALIDATING` |
| **producer_subtypes** | `[System]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Work Item foi implantado com sucesso em ambiente de homologação. A Phase de Ship foi
concluída. O Work Item está disponível para validação no ambiente de homologação.

**preconditions:**
- O Work Item está no estado SHIPPING
- O pipeline de implantação em homologação foi executado com sucesso

**postconditions:**
- O Work Item transita para o estado VALIDATING
- O Work Item está acessível em ambiente de homologação para validação

**payload_shape:**
- `environment` (string, obrigatório): identificador do ambiente de homologação em que foi implantado
- `deploy_version` (string, obrigatório): versão ou tag implantada

**owner_journey:** Delivery

---

## CI Async — Validate

---

*A Phase Validate é representada neste MVP por eventos Gate.Passed e Gate.Failed (já definidos
acima) e pela decisão humana de promover ou rejeitar (abaixo). Eventos específicos de
validação automatizada são candidatos ao catálogo v2.*

---

## CI Async — Promote

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
Um responsável humano aprovou a promoção do Work Item para Sandbox após validação em
Staging. A aprovação é a decisão formal de que o Work Item está pronto para entrar no
Sandbox (Release Candidate). Production está fora da Delivery Journey — o deploy em
Production é acionado manualmente via GitHub Actions.

**preconditions:**
- O Work Item está no estado VALIDATING
- A validação em Staging foi concluída satisfatoriamente

**postconditions:**
- O Work Item transita para o estado PROMOTING
- O pipeline de implantação em Sandbox pode ser iniciado

**payload_shape:**
- `approver` (string, obrigatório): identidade de quem aprovou a promoção
- `environment_validated` (string, obrigatório): ambiente em que a validação foi realizada (Staging)

**owner_journey:** Delivery

---

### Promote.Rejected

| Campo | Valor |
|---|---|
| **name** | `Promote.Rejected` |
| **category** | Human Decision |
| **alters_state** | `true` |
| **new_state** | `VALIDATING` |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um responsável humano rejeitou a promoção do Work Item para Sandbox. O Work Item retorna
ao estado VALIDATING — novas validações em Staging devem ser realizadas antes de uma
nova decisão de promoção.

**preconditions:**
- O Work Item está no estado VALIDATING
- Uma avaliação do Work Item em Staging foi realizada

**postconditions:**
- O Work Item retorna ao estado VALIDATING
- O motivo da rejeição está registrado na Timeline
- Uma nova aprovação será necessária para promover para Sandbox

**payload_shape:**
- `rejector` (string, obrigatório): identidade de quem rejeitou a promoção
- `reason` (string, obrigatório): motivo da rejeição

**owner_journey:** Delivery

---

### Promote.Completed

| Campo | Valor |
|---|---|
| **name** | `Promote.Completed` |
| **category** | Phase Lifecycle |
| **alters_state** | `true` |
| **new_state** | `DONE` |
| **producer_subtypes** | `[System]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O Work Item foi implantado com sucesso no Sandbox (Release Candidate). O ciclo CI Async
está encerrado. O Work Item atingiu seu estado final na Delivery Journey — está entregue
e disponível no Sandbox para validação de release. O deploy em Production é um passo
separado, acionado manualmente via GitHub Actions, fora da Delivery Journey.

**preconditions:**
- O Work Item está no estado PROMOTING
- O Promote.Approved foi registrado na Timeline
- O pipeline de implantação em Sandbox foi executado com sucesso

**postconditions:**
- O Work Item transita para o estado DONE
- O Work Item está disponível no Sandbox
- Nenhum novo evento de state é esperado para este Work Item (exceto Correction)

**payload_shape:**
- `environment` (string, obrigatório): identificador do ambiente de destino (`sandbox`)
- `deploy_version` (string, obrigatório): versão ou tag implantada
- `deploy_commit` (string, obrigatório): hash do commit implantado

**owner_journey:** Delivery

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
Um impedimento externo foi declarado para o Work Item. O Work Item está bloqueado —
o trabalho não pode progredir até que o impedimento seja resolvido. O impedimento pode
ser declarado em qualquer Phase.

**preconditions:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um impedimento externo foi identificado que impede a progressão do Work Item

**postconditions:**
- O Work Item transita para o estado BLOCKED
- O impedimento está registrado na Timeline com descrição
- O trabalho é suspenso até Impediment.Resolved

**payload_shape:**
- `impediment_description` (string, obrigatório): descrição do impedimento e de quem ou o que pode resolvê-lo
- `blocking_since` (string, obrigatório): timestamp em que o impedimento foi identificado (pode ser anterior ao timestamp do evento)

**notes:**
**Promovido a Shared Type em shared-types v1.0.0.** Este tipo Journey está Deprecated desde
v2.0.0 do catálogo. Timelines históricas que referenciam este tipo continuam válidas. Novas
emissões devem usar `Shared.Impediment.Declared`. Par complementar: Impediment.Resolved.

**owner_journey:** Delivery

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
| **convergence_version** | 2.0.0 |
| **migration_cutover** | 2026-07-25 |
| **migration_note** | Convergido para padrão canônico (alters_state=false, Lookback). Consumers que dependiam de new_state=HACKING devem usar preBlockedState(). Eventos emitidos antes do cutover (2026-07-25) são interpretados sob as regras v1. |

**description:**
O impedimento externo foi resolvido e o trabalho pode ser retomado. O Work Item retorna
ao estado em que estava antes do impedimento ser declarado.

O estado de retorno **não está hardcoded** neste tipo — o Consumer usa o mecanismo de
Lookback (`preBlockedState`) definido no `timeline.md` para calcular o estado anterior
ao BLOCKED. Esta é a implementação canônica, alinhada com Diligence e Assessment.

**preconditions:**
- O Work Item está no estado BLOCKED
- O impedimento declarado em Impediment.Declared (ou Shared.Impediment.Declared) foi resolvido

**postconditions:**
- O Derived State **não é alterado diretamente** por este evento (`alters_state = false`)
- O Consumer usa Lookback para determinar o estado de retorno (estado pré-BLOCKED)
- A resolução do impedimento está registrada na Timeline

**payload_shape:**
- `resolution_description` (string, obrigatório): descrição de como o impedimento foi resolvido

**notes:**
**Convergido para padrão canônico em v2.0.0.** Na v1.0.0, este tipo usava `alters_state=true,
new_state=HACKING` — uma simplificação MVP que retornava sempre ao estado HACKING,
independentemente do estado pré-BLOCKED. A v2.0.0 corrige esta simplificação: o Consumer
deve usar Lookback (`preBlockedState`) para determinar o estado de retorno correto.

**Compatibilidade retroativa:** eventos emitidos antes de 2026-07-25 (cutover v1→v2)
foram registrados sob as regras v1 e são interpretados como `alters_state=true, new_state=HACKING`
para fins de replay histórico. Usar o `timestamp` do evento como discriminador.

**Próximo passo:** após shared-types v1.1.0 promover `Shared.Impediment.Resolved` para Active,
este tipo será marcado como Deprecated com `replacement_type: Shared.Impediment.Resolved`.
Par complementar: Impediment.Declared.

**owner_journey:** Delivery

---

## Eventos Transversais — Rework

---

### Rework.Declared

| Campo | Valor |
|---|---|
| **name** | `Rework.Declared` |
| **category** | Rework |
| **alters_state** | `true` |
| **new_state** | `HACKING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
Um ciclo de rework foi declarado para o Work Item. O Work Item retorna ao desenvolvimento
ativo — a implementação precisa ser revisada ou corrigida antes de uma nova tentativa de
revisão e entrega.

**preconditions:**
- O Work Item está no estado SYNCING ou FINISHING
- Uma razão de rework foi identificada (Gate.Failed, Review.ChangesRequested, ou decisão humana)

**postconditions:**
- O Work Item transita para o estado HACKING
- O rework está registrado na Timeline com a razão
- O developer retoma o desenvolvimento no branch existente ou em novo branch

**payload_shape:**
- `rework_reason` (string, obrigatório): descrição do que motivou o rework
- `origin_event_id` (string, opcional): id do evento que motivou o rework (ex.: Gate.Failed ou Review.ChangesRequested)

**notes:**
Candidato a Shared Type — a semântica de retorno ao desenvolvimento por qualidade
insuficiente é genérica. Par complementar: Rework.Completed.

**owner_journey:** Delivery

---

### Rework.Completed

| Campo | Valor |
|---|---|
| **name** | `Rework.Completed` |
| **category** | Rework |
| **alters_state** | `true` |
| **new_state** | `SYNCING` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | Active |
| **introduced_in** | 1.0.0 |

**description:**
O ciclo de rework foi concluído. O Work Item está pronto para uma nova tentativa de revisão
de código. Um novo Pull Request foi aberto (ou o PR existente foi atualizado com as
correções).

**preconditions:**
- O Work Item está no estado HACKING após um Rework.Declared
- As correções necessárias foram implementadas
- Um Pull Request está disponível para revisão

**postconditions:**
- O Work Item transita para o estado SYNCING
- Um novo ciclo de revisão de código começa
- A Timeline contém Rework.Declared antes de Rework.Completed

**payload_shape:**
- `pr_number` (integer, obrigatório): número do Pull Request disponível para revisão após o rework
- `changes_description` (string, obrigatório): descrição das mudanças realizadas durante o rework

**notes:**
Candidato a Shared Type — par complementar de Rework.Declared.

**owner_journey:** Delivery

---

## Fluxos de referência

### Fluxo feliz (sem impedimentos ou rework)

```
Timeline: WI-042
────────────────────────────────────────────────────────────────
CI Sync
  1. Bootstrap.Started    → BOOTSTRAPPING
  2. Gate.Passed          (smoke-test)
  3. Bootstrap.Completed  → HACKING
  4. Hack.Completed       → SYNCING
  5. Gate.Passed          (lint)
  6. Gate.Passed          (unit-tests)
  7. Sync.Completed       → FINISHING
  8. Gate.Passed          (integration-tests)
  9. Finish.Completed     → SHIPPING
CI Async
 10. Ship.Completed       → VALIDATING
 11. Gate.Passed          (e2e-tests)
 12. Promote.Approved     → PROMOTING
 13. Promote.Completed    → DONE
────────────────────────────────────────────────────────────────
Derived State final: DONE
Events com alters_state = true: 7
Events com alters_state = false: 6
```

### Fluxo com rework

```
Timeline: WI-099
────────────────────────────────────────────────────────────────
  1. Bootstrap.Started    → BOOTSTRAPPING
  2. Gate.Passed          (smoke-test)
  3. Bootstrap.Completed  → HACKING
  4. Hack.Completed       → SYNCING
  5. Gate.Failed          (lint)
  6. Rework.Declared      → HACKING   [retorno por lint failure]
  7. Rework.Completed     → SYNCING   [correções aplicadas]
  8. Gate.Passed          (lint)
  9. Gate.Passed          (unit-tests)
 10. Sync.Completed       → FINISHING
 ...continua...
────────────────────────────────────────────────────────────────
Ciclos de rework: 2
```

### Fluxo com impedimento — Lookback em ação (padrão v2)

```
Timeline: WI-033
────────────────────────────────────────────────────────────────
  1. Bootstrap.Started    → BOOTSTRAPPING
  2. Gate.Passed          (smoke-test)
  3. Bootstrap.Completed  → HACKING
  4. Impediment.Declared  → BLOCKED   [dependência externa]
  ...dias depois...
  5. Impediment.Resolved  → alters_state=false [Lookback → retorna HACKING]
  6. Hack.Completed       → SYNCING
  ...continua...

Lookback em pos 5:
  Impediment.Declared encontrado em pos 4
  Busca antes de pos 4: pos 3 = Bootstrap.Completed, new_state=HACKING (≠ BLOCKED)
  Estado de retorno: HACKING  ✓
────────────────────────────────────────────────────────────────
```

---

*Todos os 17 Event Types neste catálogo satisfazem o Event Type Schema v1.0.0.*
*Versão do catálogo: 2.0.0. Active: 14. Deprecated: 3 (Gate.Passed, Gate.Failed, Impediment.Declared). Impediment.Resolved: Active — convergido, aguarda shared-types v1.1.0 para deprecação formal.*
