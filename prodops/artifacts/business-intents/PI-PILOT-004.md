# Product Intent — PI-PILOT-004

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-004.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

> **Registro retroativo** — criado em 2026-11-10. O `BS-PILOT-001`, o Iteration Plan Pilot, o Discovery Report e o Release Draft já referenciavam esta Intent, mas o arquivo nunca havia sido criado. O conteúdo abaixo reúne o que esses documentos já registram; o que não tinha fonte está marcado `[apurar]`.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-004` |
| **Título** | Split Payment — Conflito no Sync |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-11-10 (retroativo — o Business Signal de origem é de 2026-07-26) |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Exercitar, com uma Feature real do domínio de Split Payment, o primeiro `Gate.Failed` real em Timeline: um conflito durante o Sync seguido de resolução.

> Origem do problema — BS-PILOT-001: o padrão de conflito durante Sync nunca foi registrado como Event Instance real.

---

## Hipótese

Não registrada na origem — [apurar]. A pergunta de discovery associada está em "Perguntas em aberto".

---

## Escopo da Feature

### Padrão ProdOps exercitado

| Item | Conteúdo |
|---|---|
| Feature | Split Payment com Conflito no Sync |
| Padrão OEM | Gate.Failed durante Sync + Gate.Passed após resolução |
| Complexidade | Média — primeiro Gate.Failed real em Timeline |
| Posição na sequência | 4ª (Bloco 2 — Exceções) |
| Pré-condição de início | Gate de Bloco satisfeito + `Finish.Completed` de F-03 (PI-PILOT-003) |

---

## Critérios de sucesso

1. `Gate.Failed` registrado na fase Sync com payload identificando o conflito (`composition_id`, `conflicting_invoice_ids`, `reason`)
2. Derived State durante o conflito: Work Item em SYNCING (Gate.Failed não muda o state)
3. `Gate.Passed` registrado após resolução do conflito
4. Timeline completa até `Promote.Completed`
5. Derived State = DONE calculado pelo RT-02
6. DQ-02 respondida: Gate.Failed cobre o padrão sem novo Shared Type (confirmado ou gap documentado)

---

## Riscos se a hipótese estiver errada

O conflito durante Sync (PI-PILOT-004) não tem Event Type correspondente no catálogo → gap de cobertura no catálogo da Delivery Journey. (fonte: `BS-PILOT-001`).

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] **DQ-02** — `Delivery.Gate.Failed` com payload cobre conflito de Sync sem conceito novo? (impacto se a resposta for negativa: Novo Shared Type necessário). Fonte: `prodops/artifacts/product/discovery-report-pilot.md`.

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Iteration Plan Pilot | [iteration-plan-pilot.md](../plans/iteration-plan-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
