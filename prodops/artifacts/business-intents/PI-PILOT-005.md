# Product Intent — PI-PILOT-005

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-005.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-005` |
| **Título** | Split Payment Reversal — PR com Revisão Manual e Rework |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-26 |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Registrar e validar o padrão de Rework no ProdOps Runtime — exercitando o cenário em que um Pull Request de Split Payment Reversal exige revisão manual (Gate.Failed no Ship), o Work Item retorna ao Hack para correção, e o ciclo é retomado após o Rework.Completed.

> "Queremos que a Feature de Split Payment Reversal, quando um PR for reprovado em review e exigir retorno ao Hack, registre o ciclo de Rework na Timeline com Rework.Started e Rework.Completed, confirmando que o OSE deriva REWORKING e restaura o estado correto após a conclusão."

---

## Hipótese

> **O padrão de Rework — disparado por reprovação de PR no review (Gate.Failed no Ship) — pode ser representado integralmente no OEM com `Delivery.Rework.Started` e `Delivery.Rework.Completed`, sem necessidade de conceitos adicionais. O OSE mantém `rework_count` e restaura o estado pré-rework corretamente.**

---

## Escopo da Feature

### O que esta Feature entrega (domínio de Payments)

Implementação do fluxo de estorno (reversal) de um Split Payment: quando apenas um dos pagamentos parciais foi confirmado e o outro precisa ser revertido, a payments-api cancela o invoice pendente e emite o reversal do invoice confirmado. A Feature cobre o cenário em que o PR de implementação foi reprovado em code review por issues de segurança no mecanismo de reversal, exigindo retorno ao Hack.

### Padrão ProdOps exercitado

| Padrão | Exercitado? |
|---|---|
| Happy Path parcial (até Ship) | ✅ — o ciclo começa como happy path |
| Gate.Failed no Ship (PR reprovado) | ✅ — dispara o Rework |
| Rework.Started → Rework.Completed | ✅ **Foco primário** — padrão central desta Feature |
| Happy Path após Rework | ✅ — ciclo retomado e concluído |
| Blocking (Impediment) | ❌ — não exercitado nesta Feature |

### Invariante crítica do OSE

- `rework_count` é incrementado no `Rework.Started` e **nunca decrementado** no `Rework.Completed`
- Estado pré-rework é restaurado pelo pop do `reworkStack` (HACKING, neste caso)
- O Derived State final (DONE) reflete `rework_count: 1` — evidência permanente do ciclo de revisão

### Sequência de eventos esperada na Timeline

```
Delivery.Bootstrap.Started
Delivery.Hack.Started
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Sync.Completed
Delivery.Finish.Started
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.Gate.Failed          (PR reprovado em review — issue de segurança no reversal)
  payload: { reason: "PR #42 reprovado — mecanismo de reversal sem idempotência adequada" }
Delivery.Rework.Started       (retorno ao Hack para correção)
  payload: { reason: "Corrigir idempotência do reversal antes de re-submeter PR" }
  → Estado: REWORKING, rework_count: 1
Delivery.Hack.Started         (novo ciclo de Hack — mesmo Work Item)
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Sync.Completed
Delivery.Finish.Started
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.Rework.Completed     (PR aprovado após correção)
  → Estado: restaurado para SHIPPING (pre-rework state)
Delivery.Gate.Passed          (PR aprovado)
Delivery.Ship.Completed
Delivery.Validate.Started
Delivery.Gate.Passed
Delivery.Validate.Completed
Delivery.Promote.Started
Delivery.Promote.Completed
  → Estado final: DONE, rework_count: 1
```

---

## Valor esperado

### Para o piloto operacional

- Primeira evidência de Rework real em Timeline de Work Item
- Validação de que o OSE gerencia `reworkStack` corretamente com eventos reais
- Baseline de overhead de Rework — Lead Time adicional por ciclo de revisão

### Para o produto (payments-api)

- Feature de Split Payment Reversal com ciclo de revisão rastreável
- Histórico auditável: PR reprovado em `<timestamp>`, Rework iniciado, PR aprovado em `<timestamp>`, duração do ciclo de revisão mensurável

---

## Critérios de sucesso

1. `Rework.Started` e `Rework.Completed` registrados na Timeline com payload descritivo
2. Derived State = REWORKING durante o ciclo de rework
3. Derived State restaurado corretamente para o estado pré-rework após `Rework.Completed`
4. `rework_count: 1` no Derived State final (DONE)
5. Timeline completa até `Promote.Completed`
6. Nenhum Event Type novo foi necessário para representar o Rework

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] O `Rework.Started` é emitido logo após o `Gate.Failed` ou há um evento intermediário de decisão humana entre eles?
- [ ] O segundo `Hack.Started` (após o `Rework.Started`) é um novo Event Instance ou reutiliza o ID do primeiro?
- [ ] O Lookback em um timestamp durante o Rework deve mostrar REWORKING ou o estado pré-rework?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
