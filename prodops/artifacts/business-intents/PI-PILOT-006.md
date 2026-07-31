# Product Intent — PI-PILOT-006

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-006.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-006` |
| **Título** | Split Payment Settlement — Blocking, Retomada e Conclusão |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-26 |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Registrar e validar o padrão de Blocking (Impediment) com Lookback no ProdOps Runtime — exercitando o cenário em que a Feature de Split Payment Settlement é bloqueada por uma dependência externa (aprovação regulatória ou disponibilidade de ambiente), retomada após resolução, e concluída — validando que o OSE deriva BLOCKED, preserva `blocked_since`, restaura o estado pré-block no Resolved, e que o Lookback retorna o estado correto para qualquer ponto no tempo.

> "Queremos que a Feature de Split Payment Settlement, quando bloqueada por impedimento externo, registre `Impediment.Raised` e `Impediment.Resolved` na Timeline, e que o Lookback retorne BLOCKED em qualquer timestamp dentro da janela de bloqueio, e o estado correto fora dela."

---

## Hipótese

> **O padrão de Blocking com Impediment pode ser representado integralmente no OEM usando `Delivery.Impediment.Raised` e `Delivery.Impediment.Resolved` (Shared Types), o OSE preserva corretamente `blocked_since` e restaura o estado pré-block no Resolved, e o Lookback funciona com semântica temporal estrita — confirmando Q2, Q3 e Q7 do EXP-013 em condição real.**

---

## Escopo da Feature

### O que esta Feature entrega (domínio de Payments)

Implementação do fluxo de liquidação final (settlement) de um Split Payment: reconciliação definitiva entre os dois pagamentos parciais confirmados, registro da liquidação no modelo interno, e notificação ao financeiro. A Feature é bloqueada temporariamente por pendência regulatória (aprovação interna antes de ativar o settlement em produção), e retomada após a aprovação.

### Padrão ProdOps exercitado

| Padrão | Exercitado? |
|---|---|
| Happy Path parcial (até o bloqueio) | ✅ — ciclo começa como happy path |
| Impediment.Raised (Blocking) | ✅ **Foco primário** |
| Impediment.Resolved (Retomada) | ✅ **Foco primário** |
| Happy Path após resolução | ✅ — ciclo retomado e concluído |
| Lookback com semântica temporal estrita | ✅ **Foco primário** — validação de Q2, Q3 |
| Rework | ❌ — não exercitado nesta Feature |

### Invariantes críticas do OSE

1. `blocked_since` é definido no `Impediment.Raised` e limpo no `Impediment.Resolved`
2. Estado pré-block é preservado em `preBlockState` e restaurado no `Impediment.Resolved`
3. `lookback(events, T_blocked)` retorna State = BLOCKED
4. `lookback(events, T_before_block)` retorna State = pré-block (ex.: FINISHING)
5. `lookback(events, T_after_resolve)` retorna State = pré-block restaurado (FINISHING continuado)
6. Correções que chegam após `T_until` não são aplicadas no Lookback

### Sequência de eventos esperada na Timeline

```
Delivery.Bootstrap.Started
Delivery.Hack.Started
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Sync.Completed
Delivery.Finish.Started
  → Estado: FINISHING, phase: Finish
Delivery.Impediment.Raised         (T_blocked — bloqueio declarado)
  payload: {
    description: "Aguardando aprovação regulatória para ativar settlement em produção",
    blocker_owner: "Legal/Compliance",
    raised_by: "Tech Lead Payments"
  }
  → Estado: BLOCKED, blocked_since: T_blocked, preBlockState: FINISHING
  [... período de bloqueio ...]
Delivery.Impediment.Resolved       (T_resolved — aprovação recebida)
  payload: {
    resolution: "Aprovação regulatória recebida — settlement autorizado para produção",
    resolved_by: "Legal/Compliance"
  }
  → Estado: FINISHING (restaurado), blocked_since: undefined
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.Ship.Completed
Delivery.Validate.Started
Delivery.Gate.Passed
Delivery.Validate.Completed
Delivery.Promote.Started
Delivery.Promote.Completed
  → Estado final: DONE
```

### Lookback esperado

| Timestamp de referência | Estado esperado (lookback) |
|---|---|
| `T < Bootstrap.Started` | `null` |
| `T = Hack.Started` | HACKING |
| `T = Finish.Started` | FINISHING |
| `T = T_blocked` | BLOCKED (blocked_since = T_blocked) |
| `T` entre `T_blocked` e `T_resolved` | BLOCKED |
| `T = T_resolved` | FINISHING (restaurado) |
| `T = Promote.Completed` | DONE |

---

## Valor esperado

### Para o piloto operacional

- Validação end-to-end do padrão de Blocking com Lookback em condição real
- Confirmação das perguntas Q2 (Derived State suficiente?) e Q3 (Timeline pode ser reconstruída?) do EXP-013
- Baseline de Block Time mensurável: `T_resolved - T_blocked`
- Evidência de que `blocked_since` preserva a informação de quando o bloqueio ocorreu

### Para o produto (payments-api)

- Feature de Split Payment Settlement com impedimento rastreável
- Block Time auditável na Timeline — impacto do processo regulatório mensurável
- Baseline para SLOs de tempo de resolução de impedimentos regulatórios

---

## Critérios de sucesso

1. `Impediment.Raised` registrado com payload descritivo (motivo, owner, raised_by)
2. `Impediment.Resolved` registrado com payload de resolução
3. Derived State = BLOCKED durante o período de bloqueio
4. `blocked_since` definido no Raised e limpo no Resolved
5. Estado pré-block restaurado corretamente após o Resolved
6. Lookback retorna os estados corretos para cada ponto de referência na tabela acima
7. Timeline completa até `Promote.Completed`
8. Nenhum Shared Type novo foi necessário — `Impediment.Raised` e `Impediment.Resolved` cobrem o padrão

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] O `Impediment.Raised` usa `Delivery.Impediment.Raised` ou `Delivery.Gate.Blocked` — qual o Event Type canônico para bloqueio por dependência externa no catálogo Delivery v2?
- [ ] O Lookback deve ser calculado na execução real ou verificado via teste de regressão no RT-02?
- [ ] Como medir o Block Time na prática — calculado pelo OSE a partir de `blocked_since` ou derivado da diferença `T_resolved - T_blocked` na Timeline?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
