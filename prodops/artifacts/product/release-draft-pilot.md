# Release Draft — REL-PILOT-v1

> **Localização canônica:** `prodops/artifacts/product/release-draft-pilot.md`
>
> Um **Release Draft** registra o escopo, os critérios de aceite e a rastreabilidade de uma Release antes de qualquer compromisso de OBC. É um artefato de Discovery — não é um plano de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `REL-PILOT-v1` |
| **Título** | Piloto Operacional ProdOps — Fase 2: 6 Features Reais |
| **Business Signal** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Discovery Report** | [discovery-report-pilot.md](./discovery-report-pilot.md) |
| **Roadmap** | [roadmap-pilot.md](./roadmap-pilot.md) |
| **Data de criação** | 2026-07-26 |
| **Status** | Draft — aguarda Downstream (OBC) |
| **Tipo** | Piloto fechado — sem impacto em produção de usuário final |

---

## 1. Objetivo da Release

Executar o Piloto Operacional Fase 2 do ProdOps Runtime com 6 Features reais do payments-api, produzindo Timelines com Event Instances reais para cada Work Item — cobrindo o espectro completo de padrões da máquina de estados OEM (happy path, Gate.Failed, Rework, Blocking + Lookback) — e gerando evidência de realizabilidade antes de qualquer OBC.

---

## 2. Features da Release

### F-01 — Invoice PIX (Happy Path)

| Campo | Conteúdo |
|---|---|
| **Intent** | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) |
| **Padrão OEM** | Happy Path — Bootstrap.Started → Promote.Completed |
| **Complexidade** | Baixa — Event Types de fase apenas |
| **Posição** | 1ª na sequência |

**Critérios de aceite:**

- [ ] Timeline registrada: `Bootstrap.Started` → `Promote.Completed` sem interrupção
- [ ] Nenhum Event Type real ficou sem correspondente no catálogo Delivery v2
- [ ] Derived State = DONE calculado pelo RT-02
- [ ] GitHub COR sincronizado: State = DONE no Custom Field
- [ ] `Gate.Passed` registrado em pelo menos uma fase
- [ ] Nenhum PAN, credencial ou dado sensível em qualquer campo de EventInstance

---

### F-02 — Invoice Cartão sem PAN (Happy Path + Compliance Gate)

| Campo | Conteúdo |
|---|---|
| **Intent** | [PI-PILOT-002](../business-intents/PI-PILOT-002.md) |
| **Padrão OEM** | Happy Path + Gate.Passed (compliance) |
| **Complexidade** | Baixa-Média — adiciona gate de compliance |
| **Posição** | 2ª na sequência |

**Critérios de aceite:**

- [ ] Timeline registrada: `Bootstrap.Started` → `Promote.Completed` sem interrupção
- [ ] `Gate.Passed` na fase Validate com payload descritivo de compliance (PAN-free verificado)
- [ ] Nenhum EventInstance na Timeline contém PAN em qualquer campo (id, event_type, payload, notes, producer_identity)
- [ ] Derived State = DONE calculado pelo RT-02
- [ ] Invariante: inspeção da Timeline confirma PAN-free estruturalmente

---

### F-03 — Confirmação de Pagamento via Webhook (Happy Path + Sistema)

| Campo | Conteúdo |
|---|---|
| **Intent** | [PI-PILOT-003](../business-intents/PI-PILOT-003.md) |
| **Padrão OEM** | Happy Path + `Delivery.System.*` (evento de sistema externo) |
| **Complexidade** | Média — confirma cobertura de eventos assíncronos |
| **Posição** | 3ª na sequência |

**Critérios de aceite:**

- [ ] Timeline registrada com evento `Delivery.System.Completed` (ou equivalente) representando o webhook
- [ ] `producer_identity` do evento de sistema identificado (handler interno, não provider externo)
- [ ] Replay da Timeline após `System.*` deriva o mesmo estado que o cálculo incremental (determinismo)
- [ ] `Gate.Passed` de idempotência registrado na fase Validate
- [ ] Derived State = DONE calculado pelo RT-02
- [ ] DQ-01 respondida: Event Type para webhook documentado como confirmado ou gap registrado

---

### F-04 — Split Payment com Conflito no Sync

| Campo | Conteúdo |
|---|---|
| **Intent** | [PI-PILOT-004](../business-intents/PI-PILOT-004.md) |
| **Padrão OEM** | Gate.Failed durante Sync + Gate.Passed após resolução |
| **Complexidade** | Média — primeiro Gate.Failed real em Timeline |
| **Posição** | 4ª na sequência |

**Critérios de aceite:**

- [ ] `Gate.Failed` registrado na fase Sync com payload identificando o conflito (`composition_id`, `conflicting_invoice_ids`, `reason`)
- [ ] Derived State durante o conflito: Work Item em SYNCING (Gate.Failed não muda o state)
- [ ] `Gate.Passed` registrado após resolução do conflito
- [ ] Timeline completa até `Promote.Completed`
- [ ] Derived State = DONE calculado pelo RT-02
- [ ] DQ-02 respondida: Gate.Failed cobre o padrão sem novo Shared Type (confirmado ou gap documentado)

---

### F-05 — Split Payment Reversal com Rework

| Campo | Conteúdo |
|---|---|
| **Intent** | [PI-PILOT-005](../business-intents/PI-PILOT-005.md) |
| **Padrão OEM** | Gate.Failed (PR reprovado) + Rework.Started → Rework.Completed |
| **Complexidade** | Alta — primeiro Rework real; exercita reworkStack do OSE |
| **Posição** | 5ª na sequência |

**Critérios de aceite:**

- [ ] `Gate.Failed` registrado na fase Ship com payload descritivo (PR reprovado + razão)
- [ ] `Rework.Started` registrado com payload (motivo da revisão)
- [ ] Derived State = REWORKING durante o ciclo de rework
- [ ] `Rework.Completed` registrado após correção (PR aprovado)
- [ ] Estado pré-rework restaurado após `Rework.Completed` (SHIPPING ou HACKING — confirmar na execução)
- [ ] `rework_count: 1` no Derived State final (DONE)
- [ ] `rework_count` não decrementou após `Rework.Completed`
- [ ] Timeline completa até `Promote.Completed`
- [ ] DQ-03 respondida: segundo `Hack.Started` usa novo EventId (confirmado)

---

### F-06 — Split Payment Settlement com Blocking e Lookback

| Campo | Conteúdo |
|---|---|
| **Intent** | [PI-PILOT-006](../business-intents/PI-PILOT-006.md) |
| **Padrão OEM** | Impediment.Raised + Impediment.Resolved + Lookback temporal |
| **Complexidade** | Máxima — exercita preBlockState, blocked_since e Lookback estrito |
| **Posição** | 6ª e última na sequência |

**Critérios de aceite:**

- [ ] `Impediment.Raised` registrado com payload (descrição, blocker_owner, raised_by)
- [ ] Derived State = BLOCKED após `Impediment.Raised`, com `blocked_since` preenchido
- [ ] Estado pré-block preservado no OSE durante o bloqueio
- [ ] `Impediment.Resolved` registrado com payload (resolução, resolved_by)
- [ ] Estado pré-block restaurado após `Impediment.Resolved`, `blocked_since` limpo
- [ ] Lookback verificado:
  - `lookback(events, T_before_block)` → estado = FINISHING (ou estado pré-block)
  - `lookback(events, T_blocked)` → BLOCKED
  - `lookback(events, T_after_resolve)` → FINISHING (restaurado)
  - `lookback(events, Promote.Completed)` → DONE
- [ ] Block Time calculável: `T_resolved - T_blocked` mensurável pela Timeline
- [ ] Timeline completa até `Promote.Completed`
- [ ] DQ-04 respondida: Event Type canônico para impedimento externo confirmado (Impediment.Raised ou Gate.Blocked)
- [ ] DQ-05 respondida: Lookback funcionou corretamente em condição real

---

## 3. Critérios de conclusão da Release

A Release REL-PILOT-v1 está **concluída** quando:

1. Todos os 6 Work Items têm `Promote.Completed` registrado na Timeline
2. Derived State = DONE calculado pelo RT-02 para todos os 6
3. GitHub COR sincronizado para todos os 6 (State = DONE nos Custom Fields)
4. Todas as perguntas DQ-01 a DQ-05 respondidas (confirmadas ou gap documentado)
5. Discovery Report `discovery-report-pilot.md` preenchido com resultados reais
6. EXP-013 `runtime-validation-discovery-report.md` atualizado com evidências

**Critério de não-conclusão (stop sign):**

A Release é interrompida se qualquer Feature revelar um **gap estrutural** no Framework (não apenas fricção operacional):
- Event Type ausente sem workaround possível no catálogo atual
- Shared Type insuficiente para representar o padrão em condição real
- Propriedade de determinismo do Replay quebrada em condição real
- OSE produz Derived State incorreto para qualquer padrão com eventos reais

Se o critério de não-conclusão for atingido, o próximo passo é **Opção B do Discovery Report** — Evolution Plan antes de Downstream.

---

## 4. O que está fora do escopo desta Release

| Fora de escopo | Razão |
|---|---|
| OBC definitivo | Não criar ainda — aguarda Discovery Report completo |
| Iteration Plan individual | Não criar ainda — aguarda Downstream |
| Código de produção novo | Não implementar código neste Discovery |
| Runtime, SDK, OEM, Timeline, catálogos | Não alterar — esta Release é de Discovery |
| Dashboards Datadog | Não criar ainda |
| GitHub Project (issues, milestones) | Não criar ainda |
| Escalonamento para outros produtos | Fora do escopo — piloto fechado |

---

## 5. Rastreabilidade completa

| Artefato | Localização |
|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| F-01: PI-PILOT-001 | [PI-PILOT-001.md](../business-intents/PI-PILOT-001.md) |
| F-02: PI-PILOT-002 | [PI-PILOT-002.md](../business-intents/PI-PILOT-002.md) |
| F-03: PI-PILOT-003 | [PI-PILOT-003.md](../business-intents/PI-PILOT-003.md) |
| F-04: PI-PILOT-004 | [PI-PILOT-004.md](../business-intents/PI-PILOT-004.md) |
| F-05: PI-PILOT-005 | [PI-PILOT-005.md](../business-intents/PI-PILOT-005.md) |
| F-06: PI-PILOT-006 | [PI-PILOT-006.md](../business-intents/PI-PILOT-006.md) |
| Discovery Report | [discovery-report-pilot.md](./discovery-report-pilot.md) |
| Roadmap | [roadmap-pilot.md](./roadmap-pilot.md) |
| Experimento base | [EXP-013](../experiments/013-runtime-validation/experiment.md) |
| Documentação de revisão | [documentation-review-product-discovery-pilot.md](../../documentation-review-product-discovery-pilot.md) |
