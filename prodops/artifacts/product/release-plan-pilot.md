# Release Plan — REL-PILOT-v1

> **Localização canônica:** `prodops/artifacts/product/release-plan-pilot.md`
>
> O Release Plan detalha **como** a Release será executada — entrada, saída, dependências entre Features e estratégia de validação. É a ponte entre o Discovery (Release Draft) e a execução (Iteration Plan).

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `REL-PILOT-v1` |
| **Título** | Release Plan — Piloto Operacional ProdOps Fase 2 |
| **Release Draft de origem** | [release-draft-pilot.md](./release-draft-pilot.md) |
| **Discovery Report** | [discovery-report-pilot.md](./discovery-report-pilot.md) |
| **Roadmap** | [roadmap-pilot.md](./roadmap-pilot.md) |
| **Iteration Plan** | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) |
| **Data de criação** | 2026-07-26 |
| **Status** | Draft — aguarda gate de entrada |

---

## 1. Objetivos da Release

### Objetivo primário

Executar o Piloto Operacional Fase 2 com 6 Features reais do payments-api, produzindo Timelines com Event Instances reais e evidência de realizabilidade do ProdOps Runtime para os seguintes padrões:

| Padrão | Feature que valida |
|---|---|
| Happy Path (Bootstrap → Promote) | PI-PILOT-001, 002, 003 |
| Gate.Passed com payload de compliance | PI-PILOT-002 |
| Evento de sistema externo (webhook) | PI-PILOT-003 |
| Gate.Failed com resolução | PI-PILOT-004 |
| Rework (reworkStack + rework_count) | PI-PILOT-005 |
| Blocking + Lookback temporal | PI-PILOT-006 |

### Objetivo secundário

Responder as perguntas DQ-01 a DQ-05 do Discovery com evidência real — confirmando ou documentando gaps no OEM, nos Shared Types e no catálogo Delivery v2.

### O que a Release NÃO objetiva

- Implementação de RT-03 (GitHub Sync automatizado), RT-04 (Datadog Adapter), RT-05/RT-06 (Dashboards)
- Escalonamento do Framework para outros produtos
- Definição de OBC definitivo
- Criação de GitHub Actions ou pipelines de CI/CD

---

## 2. Critérios de Entrada (Entry Gate)

A Release só inicia quando **todos** os critérios abaixo estiverem satisfeitos:

| Critério | Verificação | Status |
|---|---|---|
| Discovery Report aprovado (prodops/artifacts/product/discovery-report-pilot.md) | Hipótese classificada como "Confirmada" ou "Parcialmente confirmada" — Opção A | A verificar |
| RT-01 (Operational Event Producer) — 37 testes, Exit 0 | `cd runtime/producer && npm test` | Verificado — Fase 1 |
| RT-02 (Operational State Engine) — 98 testes, Exit 0 | `cd runtime/state-engine && npm test` | Verificado — Fase 1 |
| SDK v0.1.1 sem erros de tipo | `cd runtime/sdk && npx tsc --noEmit` Exit 0 | Verificado — Fase 1 |
| Workspace COR (GitHub Projects) reconciliado | Evidências em `experiments/013-runtime-validation/evidence/` | Verificado — EXP-013 |
| Iteration Plan IP-001 existente e aprovado | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) | A verificar |
| Delivery Strategy documentada | [delivery-strategy-pilot.md](./delivery-strategy-pilot.md) | Criado neste prompt |

**Critério de bloqueio:** se qualquer componente de Runtime (RT-01, RT-02, SDK) apresentar regressão antes do início da Release, a entrada é bloqueada até a regressão ser corrigida.

---

## 3. Critérios de Saída (Exit Gate)

A Release está **concluída** quando todos os critérios abaixo estiverem satisfeitos:

### Critérios obrigatórios (todos devem ser atendidos)

| Critério | Evidência |
|---|---|
| 6 Timelines registradas — uma por Feature | `experiments/013-runtime-validation/evidence/timelines/` |
| Derived State = DONE para as 6 Features | RT-02 calculou corretamente para cada Timeline |
| GitHub COR sincronizado para as 6 Features | Custom Fields refletem State = DONE |
| DQ-01 respondida (webhook Event Type) | Confirmado no catálogo ou gap documentado |
| DQ-02 respondida (Gate.Failed para conflito de Sync) | Confirmado no catálogo ou gap documentado |
| DQ-03 respondida (segundo Hack.Started usa novo EventId) | Confirmado na execução de PI-005 |
| DQ-04 respondida (Impediment.Raised vs Gate.Blocked) | Decisão registrada em Discovery Report |
| DQ-05 respondida (Lookback funciona em condição real) | Evidência em PI-006 |
| Discovery Report atualizado com resultados reais | `discovery-report-pilot.md` — seções preenchidas |
| EXP-013 Discovery Report atualizado | `runtime-validation-discovery-report.md` — seções preenchidas |

### Critério de saída antecipada (stop sign)

A Release é interrompida e transicionada para Opção B do Discovery Report se:

- Qualquer Feature revelar gap estrutural sem workaround no OEM, nos Shared Types ou no catálogo
- RT-01 ou RT-02 produzirem resultado incorreto com eventos reais (não coberto pelos testes sintéticos)
- A propriedade de determinismo do Replay for violada em condição real

---

## 4. Dependências entre Features

### Dependências de sequência (hard constraints)

A premissa fundamental da Release é que **uma única Feature pode estar em execução por vez**. A próxima Feature só pode iniciar após `Delivery.Finish.Completed` da anterior.

```
PI-PILOT-001 → [Finish.Completed] → PI-PILOT-002
PI-PILOT-002 → [Finish.Completed] → PI-PILOT-003
PI-PILOT-003 → [Finish.Completed] → PI-PILOT-004 (gate de bloco)
PI-PILOT-004 → [Finish.Completed] → PI-PILOT-005
PI-PILOT-005 → [Finish.Completed] → PI-PILOT-006
```

### Gate entre Bloco 1 (Happy Path) e Bloco 2 (Exceções)

O Bloco 2 não inicia até que o gate entre blocos seja satisfeito:

| Critério do gate | Evidência |
|---|---|
| PI-PILOT-001: `Promote.Completed` registrado | Timeline de PI-001 |
| PI-PILOT-002: `Promote.Completed` registrado + Gate.Passed de compliance | Timeline de PI-002 |
| PI-PILOT-003: `Promote.Completed` registrado + DQ-01 respondida | Timeline de PI-003 + nota no Discovery Report |
| Nenhum gap estrutural identificado nas 3 happy paths | Discovery Report — seção 6 "Gaps" vazia ou com workaround |

### Dependências de pré-condição

| Feature | Pré-condição | Verificação |
|---|---|---|
| PI-PILOT-001 | RT-01 e RT-02 operacionais; Workspace COR reconciliado | Entry Gate da Release |
| PI-PILOT-002 | PI-001 concluída; Gate.Passed funcionando em RT-02 | Timeline de PI-001 |
| PI-PILOT-003 | PI-002 concluída; DQ-01 respondida | Timeline de PI-002 + nota |
| PI-PILOT-004 | Gate de Bloco 1 satisfeito | Gate entre blocos |
| PI-PILOT-005 | PI-004 concluída; reworkStack verificado via teste de regressão em RT-02 | Timeline de PI-004 + `npm test` RT-02 |
| PI-PILOT-006 | PI-005 concluída; Lookback testado via teste de regressão em RT-02 | Timeline de PI-005 + `npm test` RT-02 |

### Dependências externas (fora do escopo desta Release)

| Dependência | Impacto | Gestão |
|---|---|---|
| Provider Asaas (QR Code, webhook de confirmação) | PI-001, PI-002, PI-003 dependem do provider real | Usar ambiente sandbox para o piloto |
| GitHub Projects COR | Todas as Features dependem do workspace reconciliado | Workspace já reconciliado — EXP-013 |
| Aprovação regulatória (PI-006 settlement) | Bloqueio real que dispara Impediment.Raised | Cenário real ou simulado controlado |

---

## 5. Estratégia de Validação

### Validação por Feature

Cada Feature é validada em dois momentos:

**Validação em Finish (CI Sync):**
- Timeline registrada com eventos corretos até `Finish.Completed`
- Derived State calculado pelo RT-02 está correto
- Nenhum Event Type real ficou sem correspondente no catálogo
- PR submetido e aprovado (sem Changes Requested)

**Validação em Validate (CI Async):**
- Gate.Passed registrado com payload descritivo
- Derived State = DONE após `Promote.Completed`
- GitHub COR sincronizado
- Pergunta DQ correspondente respondida

### Validação do conjunto (Release Exit Gate)

Após as 6 Features concluídas:

1. **Regressão RT-01/RT-02:** executar `npm test` em `runtime/producer/` e `runtime/state-engine/` — Exit 0 obrigatório
2. **Coerência de Timelines:** inspecionar todas as 6 Timelines e confirmar que Event Types são consistentes com o catálogo Delivery v2
3. **Lookback cross-Feature:** selecionar timestamps de cada Feature e executar `lookback()` via RT-02 — confirmar resultados corretos
4. **Discovery Report:** preencher todas as seções "A preencher" e confirmar hipótese (Confirmada / Parcialmente / Refutada)

### Estratégia de validação para padrões excepcionais

| Padrão | Validação específica |
|---|---|
| Gate.Failed (PI-004) | Confirmed: Derived State durante Gate.Failed permanece SYNCING (não muda); após Gate.Passed, continua normalmente |
| Rework (PI-005) | Confirmed: `rework_count = 1` no Derived State final; `reworkStack` vazio após Rework.Completed |
| Blocking (PI-006) | Confirmed: Lookback retorna BLOCKED para qualquer `T` entre `T_blocked` e `T_resolved`; DONE após Promote |

---

## 6. Rastreabilidade

| Artefato | Localização |
|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| Release Draft | [release-draft-pilot.md](./release-draft-pilot.md) |
| Iteration Plan | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) |
| Delivery Strategy | [delivery-strategy-pilot.md](./delivery-strategy-pilot.md) |
| GitHub Project Template | [github-project-template-pilot.md](./github-project-template-pilot.md) |
| PI-PILOT-001 a 006 | [business-intents/](../business-intents/) |
| EXP-013 | [experiments/013-runtime-validation/](../experiments/013-runtime-validation/) |
