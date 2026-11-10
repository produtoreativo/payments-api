# Product Intent — PI-PILOT-005

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-005.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

> **Registro retroativo** — criado em 2026-11-10. O `BS-PILOT-001`, o Iteration Plan Pilot, o Discovery Report e o Release Draft já referenciavam esta Intent, mas o arquivo nunca havia sido criado. O conteúdo abaixo reúne o que esses documentos já registram; o que não tinha fonte está marcado `[apurar]`.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-005` |
| **Título** | Split Payment Reversal — Rework |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-11-10 (retroativo — o Business Signal de origem é de 2026-07-26) |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Exercitar o primeiro Rework real: PR reprovado, retorno ao Hack e restauração do estado pré-rework.

> Origem do problema — BS-PILOT-001: nenhum cenário de Rework (PR que exige revisão e retorno ao Hack) foi executado com eventos reais na Timeline.

---

## Hipótese

Não registrada na origem — [apurar]. A pergunta de discovery associada está em "Perguntas em aberto".

---

## Escopo da Feature

### Padrão ProdOps exercitado

| Item | Conteúdo |
|---|---|
| Feature | Split Payment Reversal com Rework |
| Padrão OEM | Gate.Failed (PR reprovado) + Rework.Started → Rework.Completed |
| Complexidade | Alta — primeiro Rework real; exercita reworkStack do OSE |
| Posição na sequência | 5ª (Bloco 2 — Exceções) |
| Pré-condição de início | `Finish.Completed` de F-04 (PI-PILOT-004) |

---

## Critérios de sucesso

1. `Gate.Failed` registrado na fase Ship com payload descritivo (PR reprovado + razão)
2. `Rework.Started` registrado com payload (motivo da revisão)
3. Derived State = REWORKING durante o ciclo de rework
4. `Rework.Completed` registrado após correção (PR aprovado)
5. Estado pré-rework restaurado após `Rework.Completed` (SHIPPING ou HACKING — confirmar na execução)
6. `rework_count: 1` no Derived State final (DONE)
7. `rework_count` não decrementou após `Rework.Completed`
8. Timeline completa até `Promote.Completed`
9. DQ-03 respondida: segundo `Hack.Started` usa novo EventId (confirmado)

---

## Riscos se a hipótese estiver errada

O Rework (PI-PILOT-005) exige conceitos não previstos no Framework → Shared Types ou event catalog precisam de revisão estrutural. (fonte: `BS-PILOT-001`).

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] **DQ-03** — O segundo `Hack.Started` após `Rework.Started` usa novo EventId ou reutiliza? (impacto se a resposta for negativa: Impacto na deduplicação do OSE). Fonte: `prodops/artifacts/product/discovery-report-pilot.md`.

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Iteration Plan Pilot | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
