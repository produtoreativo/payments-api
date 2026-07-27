# Iteration Plan — IP-001 (Piloto Operacional Fase 2)

> **Localização canônica:** `prodops/artifacts/plans/iteration-plan-pilot.md`
>
> **Propósito:** Registro de execução da Iteration IP-001. Contém a ordem obrigatória das 6 Features, os critérios para iniciar cada Feature, os critérios de pausa e o acompanhamento de progresso.
>
> **Este documento não é um backlog de planejamento ou priorização.** Planejamento acontece no Discovery (Release Draft e Roadmap). Priorização é responsabilidade do Product Owner. O `/delivery` é um executor determinístico deste plano — não toma decisões de prioridade.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Iteration** | IP-001 |
| **Release** | [REL-PILOT-v1](../product/release-plan-pilot.md) |
| **Produto** | payments-api |
| **Data de criação** | 2026-07-26 |
| **Status** | Aguardando Entry Gate da Release |
| **Features** | 6 (sequenciais — uma por vez) |
| **Restrição fundamental** | Apenas uma Feature em execução por vez. A próxima Feature só inicia após `Delivery.Finish.Completed` da anterior. |

---

## 1. Restrição fundamental

> **Uma única Feature pode estar em execução em qualquer momento.**
>
> A próxima Feature **somente pode iniciar** após `Delivery.Finish.Completed` da Feature anterior estar registrado na Timeline.
>
> Esta restrição não é uma preferência — é uma propriedade da Iteration IP-001. O `/delivery` não pode iniciar uma nova Feature sem que o evento de `Finish.Completed` da Feature anterior esteja presente na Timeline.

---

## 2. Papel do `/delivery`

O comando `/delivery` é um **executor determinístico** deste Iteration Plan. Ele:

- **Executa** a fase indicada (Bootstrap, Hack, Sync, Finish) conforme o skill correspondente
- **Emite** os Event Instances corretos na Timeline via RT-01
- **Verifica** que a pré-condição de início de cada Feature está satisfeita antes de prosseguir
- **Para** quando encontra um critério de pausa e reporta o estado ao operador

O `/delivery` **não**:
- Decide qual Feature executar
- Reordena Features
- Inicia uma nova Feature antes do `Finish.Completed` da anterior
- Toma decisões de Gate.Failed (registra o evento, não resolve o conflito)
- Decide se um bloqueio é um Impediment ou um Gate

---

## 3. Sequência obrigatória das 6 Features

### Bloco 1 — Happy Path (ordem obrigatória)

| Posição | Feature | Intent | Pré-condição de início |
|---|---|---|---|
| **F-01** | Invoice PIX — Happy Path | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) | Entry Gate da Release satisfeito |
| **F-02** | Invoice Cartão — Compliance Gate | [PI-PILOT-002](../business-intents/PI-PILOT-002.md) | `Finish.Completed` de F-01 na Timeline |
| **F-03** | Confirmação de Pagamento — Webhook | [PI-PILOT-003](../business-intents/PI-PILOT-003.md) | `Finish.Completed` de F-02 na Timeline |

**Gate de Bloco** (após F-03, antes de F-04):

| Critério | Verificação |
|---|---|
| F-01, F-02, F-03 com `Promote.Completed` | Timelines registradas |
| Nenhum gap estrutural nas 3 happy paths | Discovery Report — seção Gaps |
| DQ-01 respondida | Nota no Discovery Report |
| RT-01 e RT-02: Exit 0 (regressão) | `npm test` em ambos os pacotes |

### Bloco 2 — Exceções (ordem obrigatória, após gate de bloco)

| Posição | Feature | Intent | Pré-condição de início |
|---|---|---|---|
| **F-04** | Split Payment — Conflito Sync | [PI-PILOT-004](../business-intents/PI-PILOT-004.md) | Gate de Bloco satisfeito + `Finish.Completed` de F-03 |
| **F-05** | Split Payment Reversal — Rework | [PI-PILOT-005](../business-intents/PI-PILOT-005.md) | `Finish.Completed` de F-04 |
| **F-06** | Split Payment Settlement — Blocking | [PI-PILOT-006](../business-intents/PI-PILOT-006.md) | `Finish.Completed` de F-05 |

---

## 4. Critérios para iniciar cada Feature

### F-01 — Invoice PIX

**Pré-condições:**
- [ ] Entry Gate da Release satisfeito (ver Release Plan)
- [ ] Branch `feature/pilot-invoice-pix` criada a partir de `master`
- [ ] Ambiente sandbox disponível (Asaas sandbox ativo)

**Evento de início:** `Delivery.Bootstrap.Started` emitido via RT-01

**Pré-condição de início verificada por:** operador (não automatizado neste piloto)

---

### F-02 — Invoice Cartão

**Pré-condições:**
- [ ] `Delivery.Finish.Completed` de F-01 presente na Timeline de PI-PILOT-001
- [ ] Derived State de F-01 = DONE (verificado via RT-02)
- [ ] Branch `feature/pilot-invoice-cartao` criada a partir de `master`

**Evento de início:** `Delivery.Bootstrap.Started` emitido via RT-01

---

### F-03 — Confirmação de Pagamento

**Pré-condições:**
- [ ] `Delivery.Finish.Completed` de F-02 presente na Timeline de PI-PILOT-002
- [ ] Derived State de F-02 = DONE (verificado via RT-02)
- [ ] Branch `feature/pilot-confirmacao-pagamento` criada a partir de `master`

**Evento de início:** `Delivery.Bootstrap.Started` emitido via RT-01

---

### F-04 — Split Payment (Conflito Sync)

**Pré-condições:**
- [ ] Gate de Bloco satisfeito (todos os critérios acima)
- [ ] `Delivery.Finish.Completed` de F-03 presente na Timeline de PI-PILOT-003
- [ ] DQ-02 respondida: Event Type para Gate.Failed de conflito confirmado
- [ ] Branch `feature/pilot-split-payment-sync` criada a partir de `master`

**Evento de início:** `Delivery.Bootstrap.Started` emitido via RT-01

---

### F-05 — Split Payment Reversal (Rework)

**Pré-condições:**
- [ ] `Delivery.Finish.Completed` de F-04 presente na Timeline de PI-PILOT-004
- [ ] Derived State de F-04 = DONE (verificado via RT-02)
- [ ] Teste de regressão RT-02 (`npm test`) executado — Exit 0
- [ ] Branch `feature/pilot-split-payment-reversal` criada a partir de `master`

**Nota sobre Rework:** esta Feature exercita o padrão de Rework. O `/delivery` emite `Rework.Started` quando o PR recebe Changes Requested e `Rework.Completed` quando o PR é aprovado após correção. O Rework não é uma decisão do `/delivery` — é disparado pelo evento de Gate.Failed no Ship.

**Evento de início:** `Delivery.Bootstrap.Started` emitido via RT-01

---

### F-06 — Split Payment Settlement (Blocking)

**Pré-condições:**
- [ ] `Delivery.Finish.Completed` de F-05 presente na Timeline de PI-PILOT-005
- [ ] Derived State de F-05 = DONE com `rework_count: 1` (verificado via RT-02)
- [ ] DQ-04 respondida: Event Type canônico para Impediment declarado
- [ ] Teste de regressão RT-02 (`npm test`) executado — Exit 0
- [ ] Branch `feature/pilot-split-payment-settlement` criada a partir de `master`

**Nota sobre Blocking:** esta Feature exercita o padrão de Blocking com Lookback. O `/delivery` emite `Impediment.Raised` quando o impedimento é identificado e `Impediment.Resolved` quando o impedimento é resolvido. A verificação do Lookback é feita pelo operador via RT-02 após o `Impediment.Resolved`.

**Evento de início:** `Delivery.Bootstrap.Started` emitido via RT-01

---

## 5. Critérios de pausa (pause gates)

A Iteration é pausada (sem cancelamento) nos seguintes cenários:

### Pausa por gap estrutural

**Trigger:** qualquer Feature revela Event Type ausente no catálogo, Shared Type insuficiente, ou propriedade de determinismo violada.

**Ação:**
1. Registrar `Delivery.Gate.Failed` na Timeline com payload descritivo do gap
2. Documentar o gap na seção "Gaps encontrados" do Discovery Report
3. Pausar a execução da Feature — não avançar para a próxima
4. Aguardar decisão do operador: workaround ou Evolution Plan

**O `/delivery` não resolve o gap** — registra o bloqueio e para.

---

### Pausa por bloqueio externo (Impediment)

**Trigger:** PI-PILOT-006 (ou qualquer Feature) encontra bloqueio por dependência externa.

**Ação:**
1. Emitir `Delivery.Impediment.Raised` na Timeline com payload (descrição, blocker_owner)
2. Registrar `blocked_since` no Derived State
3. Pausar a execução — aguardar resolução

**O `/delivery` não resolve o impedimento** — registra o bloqueio e para.

**Retomada:** operador confirma resolução → `/delivery` emite `Delivery.Impediment.Resolved`.

---

### Pausa por regressão em Runtime

**Trigger:** `npm test` em RT-01 ou RT-02 falha durante a execução da Iteration.

**Ação:**
1. Não emitir mais Event Instances até regressão ser corrigida
2. Registrar nota no Discovery Report
3. Corrigir regressão → executar `npm test` novamente → Exit 0 → retomar

---

### Pausa por Gate de Bloco não satisfeito

**Trigger:** F-04 tentaria iniciar mas o Gate de Bloco (entre Bloco 1 e Bloco 2) não está satisfeito.

**Ação:**
1. Não iniciar F-04
2. Identificar qual critério do Gate de Bloco está pendente
3. Resolver o critério pendente
4. Verificar novamente o Gate de Bloco
5. Iniciar F-04 somente após gate satisfeito

---

## 6. Acompanhamento de progresso

### Estado das Features

| Feature | `Bootstrap.Started` | `Finish.Completed` | `Promote.Completed` | Derived State |
|---|---|---|---|---|
| F-01 Invoice PIX | — | — | — | — |
| F-02 Invoice Cartão | — | — | — | — |
| F-03 Confirmação Pagamento | — | — | — | — |
| *Gate de Bloco* | — | — | — | — |
| F-04 Split Payment Sync | — | — | — | — |
| F-05 Split Payment Reversal | — | — | — | — |
| F-06 Split Payment Settlement | — | — | — | — |

*A preencher durante a execução — timestamps dos eventos chave.*

### DQs respondidas

| DQ | Pergunta | Respondida? | Resultado |
|---|---|---|---|
| DQ-01 | Webhook → `System.*`? | — | — |
| DQ-02 | Conflito Sync → `Gate.Failed` sem novo tipo? | — | — |
| DQ-03 | Segundo `Hack.Started` usa novo EventId? | — | — |
| DQ-04 | Canônico: `Impediment.Raised` ou `Gate.Blocked`? | — | — |
| DQ-05 | Lookback funciona em condição real? | — | — |

---

## 7. Rastreabilidade

| Artefato | Localização |
|---|---|
| Release Plan | [release-plan-pilot.md](../product/release-plan-pilot.md) |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) |
| Delivery Strategy | [delivery-strategy-pilot.md](../product/delivery-strategy-pilot.md) |
| PI-PILOT-001 | [PI-PILOT-001.md](../business-intents/PI-PILOT-001.md) |
| PI-PILOT-002 | [PI-PILOT-002.md](../business-intents/PI-PILOT-002.md) |
| PI-PILOT-003 | [PI-PILOT-003.md](../business-intents/PI-PILOT-003.md) |
| PI-PILOT-004 | [PI-PILOT-004.md](../business-intents/PI-PILOT-004.md) |
| PI-PILOT-005 | [PI-PILOT-005.md](../business-intents/PI-PILOT-005.md) |
| PI-PILOT-006 | [PI-PILOT-006.md](../business-intents/PI-PILOT-006.md) |
