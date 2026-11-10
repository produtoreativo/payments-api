# Product Intent — PI-PILOT-006

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-006.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

> **Registro retroativo** — criado em 2026-11-10. O `BS-PILOT-001`, o Iteration Plan Pilot, o Discovery Report e o Release Draft já referenciavam esta Intent, mas o arquivo nunca havia sido criado. O conteúdo abaixo reúne o que esses documentos já registram; o que não tinha fonte está marcado `[apurar]`.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-006` |
| **Título** | Split Payment Settlement — Blocking e Lookback |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-11-10 (retroativo — o Business Signal de origem é de 2026-07-26) |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Exercitar Blocking com Lookback em condição real: impedimento externo declarado, resolvido e estado pré-bloqueio restaurado.

> Origem do problema — BS-PILOT-001: nenhum cenário de Blocking (Impediment) com Lookback foi exercitado em condição real.

---

## Hipótese

Não registrada na origem — [apurar]. A pergunta de discovery associada está em "Perguntas em aberto".

---

## Escopo da Feature

### Padrão ProdOps exercitado

| Item | Conteúdo |
|---|---|
| Feature | Split Payment Settlement com Blocking e Lookback |
| Padrão OEM | Impediment.Raised + Impediment.Resolved + Lookback temporal |
| Complexidade | Máxima — exercita preBlockState, blocked_since e Lookback estrito |
| Posição na sequência | 6ª e última (Bloco 2 — Exceções) |
| Pré-condição de início | `Finish.Completed` de F-05 (PI-PILOT-005) |

---

## Critérios de sucesso

1. `Impediment.Raised` registrado com payload (descrição, blocker_owner, raised_by)
2. Derived State = BLOCKED após `Impediment.Raised`, com `blocked_since` preenchido
3. Estado pré-block preservado no OSE durante o bloqueio
4. `Impediment.Resolved` registrado com payload (resolução, resolved_by)
5. Estado pré-block restaurado após `Impediment.Resolved`, `blocked_since` limpo
6. Lookback verificado em T_before_block, T_blocked, T_after_resolve e em `Promote.Completed`
7. Block Time calculável: `T_resolved - T_blocked` mensurável pela Timeline
8. Timeline completa até `Promote.Completed`
9. DQ-04 respondida: Event Type canônico para impedimento externo confirmado (Impediment.Raised ou Gate.Blocked)
10. DQ-05 respondida: Lookback funcionou corretamente em condição real

---

## Riscos se a hipótese estiver errada

O Blocking + Lookback (PI-PILOT-006) falha em condição real → propriedade de imutabilidade da Timeline não satisfeita — bloqueio crítico. (fonte: `BS-PILOT-001`).

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] **DQ-04** — `Delivery.Impediment.Raised` ou `Delivery.Gate.Blocked` é o canônico para impedimento externo? (impacto se a resposta for negativa: Ambiguidade no catálogo). Fonte: `prodops/artifacts/product/discovery-report-pilot.md`.

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Iteration Plan Pilot | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
