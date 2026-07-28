# Roadmap — Piloto Operacional ProdOps (Fase 2)

> **Localização canônica:** `prodops/artifacts/product/roadmap-pilot.md`
>
> Este Roadmap registra a sequência planejada de entrega das 6 Features do Piloto Operacional Fase 2. Não é um OBC nem um compromisso de data. É a visão de produto para suportar a decisão de Downstream.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Título** | Roadmap — Piloto Operacional Fase 2 |
| **Business Signal** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Discovery Report** | [discovery-report-pilot.md](./discovery-report-pilot.md) |
| **Release única** | [REL-PILOT-v1](./release-draft-pilot.md) |
| **Data de criação** | 2026-07-26 |
| **Status** | Draft — aguarda conclusão do Discovery e decisão de Downstream |
| **Horizonte** | Piloto fechado — sem roadmap de escalonamento neste documento |

---

## 1. Visão do Roadmap

O Roadmap é composto por **uma única Release candidata (REL-PILOT-v1)** com 6 Features sequenciadas para maximizar a cobertura de padrões OEM de forma incremental:

1. As 3 Features de happy path (PI-PILOT-001 a 003) devem ser executadas primeiro — cada uma adiciona um padrão novo (sistema puro → gate de compliance → evento de sistema externo)
2. As 3 Features de exceção (PI-PILOT-004 a 006) dependem da base estabelecida pelas happy paths — exercitam padrões mais complexos sobre a mesma infraestrutura

---

## 2. Releases

### REL-PILOT-v1 — Piloto Operacional Fase 2

| Campo | Conteúdo |
|---|---|
| **Identificador** | `REL-PILOT-v1` |
| **Descrição** | Execução do Piloto Operacional com 6 Features reais do payments-api cobrindo o espectro completo de padrões da máquina de estados OEM |
| **Objetivo** | Produzir evidência de realizabilidade do Runtime com Work Items reais antes de qualquer OBC |
| **Status** | Draft — aguarda Downstream |
| **Pré-condição** | Discovery Report aprovado (Opção A) |
| **Critério de conclusão** | Todas as 6 Features com `Promote.Completed` registrado e Derived State = DONE |

**Features incluídas (em ordem de execução):**

| Posição | Feature | Intent | Padrão primário |
|---|---|---|---|
| 1 | Invoice PIX | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) | Happy Path puro |
| 2 | Invoice Cartão | [PI-PILOT-002](../business-intents/PI-PILOT-002.md) | Happy Path + Gate de Compliance |
| 3 | Confirmação de Pagamento | [PI-PILOT-003](../business-intents/PI-PILOT-003.md) | Happy Path + Evento de Sistema |
| 4 | Split Payment (conflito Sync) | [PI-PILOT-004](../business-intents/PI-PILOT-004.md) | Gate.Failed + resolução |
| 5 | Split Payment Reversal | [PI-PILOT-005](../business-intents/PI-PILOT-005.md) | Rework.Started → Completed |
| 6 | Split Payment Settlement | [PI-PILOT-006](../business-intents/PI-PILOT-006.md) | Blocking + Lookback |

---

## 3. Lógica de sequenciamento

### Por que esta ordem?

#### Bloco 1 — Happy Path (PI-PILOT-001 → 002 → 003)

As 3 Features de happy path são sequenciadas por complexidade crescente de Event Types:

- **001** estabelece o ciclo base com Event Types de fase (`.Started`, `.Completed`) — o conjunto mínimo
- **002** adiciona o Gate de compliance — exercita o primeiro `Gate.Passed` real com payload descritivo
- **003** adiciona o evento de sistema — exercita `System.*` e confirma que o padrão assíncrono (webhook) é representável

Cada Feature do bloco é independente — pode ser executada em qualquer ordem dentro do bloco, mas o bloco como um todo precede o Bloco 2.

#### Bloco 2 — Exceções (PI-PILOT-004 → 005 → 006)

As 3 Features de exceção são sequenciadas por complexidade crescente do OSE:

- **004** exercita `Gate.Failed` — o mais simples dos padrões de exceção; envolve apenas o OSE seguindo o caminho normal (sem `preBlockState` ou `reworkStack`)
- **005** exercita `Rework` — usa o `reworkStack` do OSE; requer que o equipe saiba como emitir `Rework.Started` e `Rework.Completed` com payload correto
- **006** exercita `Blocking + Lookback` — o mais complexo; usa `preBlockState`, `blocked_since`, e exige validação do Lookback temporal

#### Dependências entre blocos

```
Bloco 1 (Happy Path) → estabelece → Bloco 2 (Exceções)

PI-001 → PI-002 → PI-003 → PI-004 → PI-005 → PI-006
                            ↑                    ↑
                     Gate.Failed           Blocking
                     (base simples)     (complexidade máxima)
```

---

## 4. Critérios de gate entre blocos

### Gate para iniciar Bloco 2 (exceções)

O Bloco 2 só inicia após:

- [ ] PI-PILOT-001: Timeline completa, Promote.Completed registrado, Derived State = DONE
- [ ] PI-PILOT-002: Gate.Passed de compliance registrado e verificado
- [ ] PI-PILOT-003: `System.*` registrado e Derived State = DONE
- [ ] DQ-01 respondida: Event Type para webhook de confirmação confirmado ou gap documentado
- [ ] Nenhum gap estrutural identificado nas 3 happy paths

---

## 5. Métricas esperadas por Feature

| Feature | Métrica principal | O que mede |
|---|---|---|
| PI-PILOT-001 | Lead Time (Bootstrap → Promote) | Baseline do ciclo de entrega mais simples |
| PI-PILOT-002 | Lead Time + Gate Time (Validate) | Overhead de compliance gate |
| PI-PILOT-003 | Cycle Time (Hack → Ship) | Cycle Time com evento de sistema assíncrono |
| PI-PILOT-004 | Conflict Resolution Time (Gate.Failed → Gate.Passed) | Tempo de resolução de conflito |
| PI-PILOT-005 | Rework Time (Rework.Started → Rework.Completed) | Overhead de um ciclo de revisão |
| PI-PILOT-006 | Block Time (Impediment.Raised → Resolved) | Impacto de impedimento externo no Lead Time |

---

## 6. Riscos do Roadmap

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Gap de Event Type descoberto em PI-PILOT-003 (webhook) | Média | Alto — bloqueia Bloco 2 | Evolution Plan imediato para catálogo Delivery v2 |
| Gap de Shared Type em PI-PILOT-006 (Impediment vs Gate.Blocked) | Média | Médio — ambiguidade endereçável | Decisão de nomenclatura no Discovery antes de executar PI-006 |
| RT-01 ou RT-02 revelam limitação em condição real | Baixa | Alto — bloqueia o piloto | Testes de regressão no início de cada Feature |
| Rework aninhado (PI-PILOT-005) não testado com eventos reais | Baixa | Médio — reworkStack funciona em teste, pode ter edge case real | Checar `rework_count` manualmente após execução |

---

## 7. O que está fora do escopo do Roadmap

| Fora de escopo | Razão |
|---|---|
| Iteration Plans individuais por Feature | Não criar ainda — aguarda Downstream (OBC) |
| OBC definitivo | Não criar ainda — aguarda Discovery Report completo |
| Dashboards Datadog | Não criar ainda — aguarda execução real |
| GitHub Project milestones | Não criar ainda — aguarda Downstream |
| Escalonamento para outros produtos | Fora do escopo deste piloto — REL-PILOT-v1 é fechado |

---

## 8. Rastreabilidade

| Artefato | Localização |
|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| Discovery Report | [discovery-report-pilot.md](./discovery-report-pilot.md) |
| Release Draft | [release-draft-pilot.md](./release-draft-pilot.md) |
| PI-PILOT-001 | [PI-PILOT-001.md](../business-intents/PI-PILOT-001.md) |
| PI-PILOT-002 | [PI-PILOT-002.md](../business-intents/PI-PILOT-002.md) |
| PI-PILOT-003 | [PI-PILOT-003.md](../business-intents/PI-PILOT-003.md) |
| PI-PILOT-004 | [PI-PILOT-004.md](../business-intents/PI-PILOT-004.md) |
| PI-PILOT-005 | [PI-PILOT-005.md](../business-intents/PI-PILOT-005.md) |
| PI-PILOT-006 | [PI-PILOT-006.md](../business-intents/PI-PILOT-006.md) |
