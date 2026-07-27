# Discovery Report — Piloto Operacional ProdOps (Fase 2)

> **Localização canônica:** `prodops/artifacts/product/discovery-report-pilot.md`
>
> Este documento consolida o resultado do Discovery da Fase 2 do Piloto Operacional e serve como entrada formal para a decisão de Downstream. É o relatório de síntese — não substitui os artefatos de origem.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Título** | Discovery Report — Piloto Operacional Fase 2 |
| **Business Signal** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Antecedente** | [BS-RUNTIME-001](../business-signals/BS-RUNTIME-001.md) · [PI-RUNTIME-001](../business-intents/PI-RUNTIME-001.md) |
| **Product Intents** | PI-PILOT-001 a PI-PILOT-006 |
| **Experimento de base** | [EXP-013](../experiments/013-runtime-validation/experiment.md) |
| **Data de criação** | 2026-07-26 |
| **Status** | Em Discovery — aguarda execução das 6 Features |
| **Decisão** | Pendente — a definir após execução |

---

## 1. Contexto

### Por que este Discovery foi realizado

A Fase 1 do Piloto Operacional (EXP-013) produziu os componentes de Runtime:

- SDK v0.1.1 — modelos, contratos, tipos derivados
- RT-01 (Operational Event Producer) — 37 testes, Exit 0
- RT-02 (Operational State Engine) — 98 testes, Exit 0
- Workspace COR reconciliado (GitHub Projects)

O que a Fase 1 não produziu foi **evidência de execução com Work Items reais de negócio**. Todos os testes são sintéticos. Nenhuma Timeline real foi registrada.

A Fase 2 existe para fechar esse gap: selecionar 6 Features reais do payments-api que cubram o espectro completo de padrões da máquina de estados, executar cada Feature como Work Item com Runtime ativo, e coletar evidências que respondam às perguntas Q1–Q8 do EXP-013.

### Estrutura das 6 Features

| Feature | Padrão primário | Intent |
|---|---|---|
| Invoice PIX | Happy Path — Bootstrap→Promote | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) |
| Invoice Cartão (sem PAN) | Happy Path + Gate de Compliance | [PI-PILOT-002](../business-intents/PI-PILOT-002.md) |
| Confirmação de Pagamento (webhook) | Happy Path + Evento de Sistema | [PI-PILOT-003](../business-intents/PI-PILOT-003.md) |
| Split Payment (conflito Sync) | Gate.Failed durante Sync | [PI-PILOT-004](../business-intents/PI-PILOT-004.md) |
| Split Payment Reversal (Rework) | Rework.Started → Rework.Completed | [PI-PILOT-005](../business-intents/PI-PILOT-005.md) |
| Split Payment Settlement (Blocking) | Impediment.Raised → Resolved + Lookback | [PI-PILOT-006](../business-intents/PI-PILOT-006.md) |

---

## 2. Hipótese avaliada

### Hipótese central

> **O ProdOps Runtime (SDK, RT-01, RT-02, OEM, Shared Types, catálogo Delivery v2) é suficiente para registrar, processar e derivar estado para 6 Work Items reais do payments-api que cubram happy path, Gate.Failed, Rework e Blocking — sem necessidade de alterações estruturais no Framework.**

Esta hipótese será confirmada ou refutada pela execução das 6 Features com Timeline completa.

---

## 3. Mapa de cobertura de padrões

| Padrão OEM | Feature que exercita | Intent |
|---|---|---|
| Bootstrap → Promote (full lifecycle) | Invoice PIX | PI-PILOT-001 |
| Gate.Passed (compliance) | Invoice Cartão | PI-PILOT-002 |
| Delivery.System.* (evento externo) | Confirmação de Pagamento | PI-PILOT-003 |
| Gate.Failed durante fase intermediária | Split Payment conflito Sync | PI-PILOT-004 |
| Rework.Started + Rework.Completed | Split Payment Reversal | PI-PILOT-005 |
| Impediment.Raised + Impediment.Resolved | Split Payment Settlement | PI-PILOT-006 |
| Lookback com semântica temporal estrita | Split Payment Settlement | PI-PILOT-006 |
| `blocked_since` + `preBlockState` | Split Payment Settlement | PI-PILOT-006 |
| `rework_count` acumulado | Split Payment Reversal | PI-PILOT-005 |

**Cobertura de estados da máquina de estados:**

| State | Exercitado em | Feature |
|---|---|---|
| BOOTSTRAPPING | Invoice PIX | PI-PILOT-001 |
| HACKING | Todos | PI-PILOT-001 a 006 |
| SYNCING | Todos | PI-PILOT-001 a 006 |
| FINISHING | Todos (inclusive durante Blocking) | PI-PILOT-001 a 006 |
| SHIPPING | Todos (inclusive durante Rework) | PI-PILOT-001 a 006 |
| VALIDATING | Todos | PI-PILOT-001 a 006 |
| PROMOTING | Todos | PI-PILOT-001 a 006 |
| DONE | Todos | PI-PILOT-001 a 006 |
| BLOCKED | Split Payment Settlement | PI-PILOT-006 |
| REWORKING | Split Payment Reversal | PI-PILOT-005 |

---

## 4. Análise de pré-condições

### O que já está pronto (não requer trabalho neste Discovery)

| Componente | Estado | Evidência |
|---|---|---|
| SDK v0.1.1 | Implementado, tipado, 0 erros | `runtime/sdk/` |
| RT-01 (Producer) | 37 testes, Exit 0 | `runtime/producer/` |
| RT-02 (OSE) | 98 testes, Exit 0 | `runtime/state-engine/` |
| GitHub Projects COR | Workspace reconciliado | `experiments/013-runtime-validation/evidence/` |
| Catálogo Delivery v2 | 17 Event Types | `framework/journeys/delivery/events/catalog.md` |
| Shared Types v1.0.0 | Gate.Passed, Gate.Failed, Impediment.Raised, Impediment.Resolved | `framework/events/shared-types.md` |

### O que precisa ser confirmado na execução

| Questão | Feature que responde | Pergunta EXP-013 |
|---|---|---|
| `System.*` cobre webhook de confirmação? | PI-PILOT-003 | Q1 — OEM suficiente? |
| Gate.Failed cobre conflito de Sync? | PI-PILOT-004 | Q1 — OEM suficiente? |
| Derived State correto para Rework? | PI-PILOT-005 | Q2 — Derived State suficiente? |
| Derived State correto para Blocking? | PI-PILOT-006 | Q2 — Derived State suficiente? |
| Lookback estrito em condição real? | PI-PILOT-006 | Q3 — Timeline reconstruível? |
| Shared Types suficientes para impedimento real? | PI-PILOT-006 | Q7 — Shared Types suficientes? |

---

## 5. Perguntas em aberto do Discovery

Estas perguntas devem ser respondidas durante a execução — não são bloqueadoras para o Discovery mas são necessárias para o Downstream:

| # | Pergunta | Feature | Impacto se resposta for NÃO |
|---|---|---|---|
| DQ-01 | `Delivery.System.Completed` é o Event Type correto para representar webhook de confirmação? | PI-PILOT-003 | Gap de cobertura — Evolution Plan |
| DQ-02 | `Delivery.Gate.Failed` com payload cobre conflito de Sync sem conceito novo? | PI-PILOT-004 | Novo Shared Type necessário |
| DQ-03 | O segundo `Hack.Started` após `Rework.Started` usa novo EventId ou reutiliza? | PI-PILOT-005 | Impacto na deduplicação do OSE |
| DQ-04 | `Delivery.Impediment.Raised` ou `Delivery.Gate.Blocked` é o canônico para impedimento externo? | PI-PILOT-006 | Ambiguidade no catálogo |
| DQ-05 | O Lookback funciona corretamente com eventos reais de Payments em condição de produção? | PI-PILOT-006 | Propriedade de imutabilidade não satisfeita |

---

## 6. Resultado (a preencher após execução)

### Hipótese

- [ ] **Confirmada** — todos os 6 Work Items executados sem gap estrutural
- [ ] **Parcialmente confirmada** — maioria confirmada; gaps não-estruturais (workaround disponível)
- [ ] **Refutada** — pelo menos um gap estrutural identificado sem workaround

### Por Feature

| Feature | Status | Gap identificado |
|---|---|---|
| PI-PILOT-001 — Invoice PIX | A executar | — |
| PI-PILOT-002 — Invoice Cartão | A executar | — |
| PI-PILOT-003 — Confirmação Pagamento | A executar | — |
| PI-PILOT-004 — Split Payment Sync | A executar | — |
| PI-PILOT-005 — Split Payment Reversal | A executar | — |
| PI-PILOT-006 — Split Payment Settlement | A executar | — |

---

## 7. Recomendação

*A preencher após execução das 6 Features.*

### Opção A — Downstream (OBC)

*Marcar se todas as hipóteses DQ-01 a DQ-05 foram respondidas sem gap estrutural.*

- [ ] Criar `OBC-PILOT-001` com escopo de entrega das 6 Features

### Opção B — Upstream continua (Evolution Plan)

*Marcar se qualquer DQ revelou gap estrutural sem workaround.*

- [ ] Criar Evolution Plan endereçando o gap antes de OBC

---

## 8. Próximos passos

### Imediatos (pós-aprovação do Discovery)

1. Revisar o Roadmap (`roadmap-pilot.md`) e confirmar sequência de execução das Features
2. Confirmar Release Draft (`release-draft-pilot.md`) com os critérios de aceite de cada Feature
3. Iniciar execução da PI-PILOT-001 (Invoice PIX) — mais simples, estabelece o baseline

### Após execução completa

4. Preencher as seções "A preencher" deste Discovery Report
5. Atualizar EXP-013/runtime-validation-discovery-report.md com evidências reais
6. Tomar a decisão Opção A ou Opção B

---

## 9. Rastreabilidade

| Artefato | Localização |
|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| Business Intents (6) | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) a [PI-PILOT-006](../business-intents/PI-PILOT-006.md) |
| Roadmap | [roadmap-pilot.md](./roadmap-pilot.md) |
| Release Draft | [release-draft-pilot.md](./release-draft-pilot.md) |
| Experimento base | [EXP-013](../experiments/013-runtime-validation/experiment.md) |
| Discovery Report do EXP-013 | [runtime-validation-discovery-report.md](../experiments/013-runtime-validation/runtime-validation-discovery-report.md) |
| Documentação de revisão | [documentation-review-product-discovery-pilot.md](../../documentation-review-product-discovery-pilot.md) |
