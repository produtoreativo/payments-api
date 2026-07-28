# Documentation Review — Release Planning e Iteration Planning do Piloto Operacional

**Data:** 2026-07-26
**Revisor:** Claude (automatizado)
**Escopo:** Prompt 02 — Release Planning e Iteration Planning da Fase 2 do Piloto Operacional
**Antecedente:** [documentation-review-product-discovery-pilot.md](./documentation-review-product-discovery-pilot.md)

---

## Sumário

Release Planning e Iteration Planning da Fase 2 concluídos. Foram criados 5 artefatos que transformam o Discovery aprovado em plano operacional: Release Plan, Iteration Plan, Delivery Strategy, GitHub Project Template e esta documentação de revisão.

Nenhum código foi implementado. Nenhuma GitHub Action foi criada. Nenhum OBC definitivo foi criado. Nenhum comando `/delivery` foi criado. Nenhum arquivo de Runtime, SDK, OEM, Timeline ou catálogo de eventos foi alterado.

---

## Arquivos criados

| Artefato | Localização | Tipo |
|---|---|---|
| Release Plan | `prodops/artifacts/product/release-plan-pilot.md` | Release Plan |
| Iteration Plan | `prodops/artifacts/plans/iteration-plan-pilot.md` | Iteration Plan |
| Delivery Strategy | `prodops/artifacts/product/delivery-strategy-pilot.md` | Operational Model |
| GitHub Project Template | `prodops/artifacts/product/github-project-template-pilot.md` | COR Template (conceitual) |
| Este documento | `prodops/documentation-review-pilot-release-planning.md` | Documentation Review |

---

## Conformidade com restrições

| Restrição | Status |
|---|---|
| NÃO implementar código | ✅ Nenhum arquivo `.ts`, `.js`, `.json` criado |
| NÃO alterar Runtime, SDK, OEM, Timeline ou catálogos | ✅ Confirmado |
| NÃO criar GitHub Actions | ✅ Template é conceitual — sem YAML de workflow |
| NÃO criar dashboards | ✅ Ausente |
| NÃO criar OBC definitivo | ✅ Ausente — todos os artefatos são de planejamento, não de contrato |
| NÃO criar o comando `/delivery` | ✅ Ausente — Delivery Strategy descreve modelo operacional, não implementa o skill |
| Iteration Plan deve explicitar que `/delivery` não toma decisões de prioridade | ✅ Seção 2 do Iteration Plan: "O `/delivery` **não**: Decide qual Feature executar; Reordena Features" |
| GitHub Project deve ser descrito apenas como representação operacional da COR | ✅ Seção 1 do GitHub Project Template: "O GitHub Project é a COR — nunca origina estado" |
| Consistência com a Discovery | ✅ Verificado — ver seção de rastreabilidade abaixo |

---

## Rastreabilidade

### Grafo de artefatos (Prompt 01 + Prompt 02)

```
BS-PILOT-001 (Business Signal)
    │
    ├── PI-PILOT-001 a PI-PILOT-006 (Product Intents)
    │
    ▼
discovery-report-pilot.md (Discovery Report)
    │
    ▼
roadmap-pilot.md (Roadmap)
    │
    ▼
release-draft-pilot.md (Release Draft)
    │
    ▼ [Prompt 02]
release-plan-pilot.md (Release Plan)
    │
    ├── iteration-plan-pilot.md (Iteration Plan IP-001)
    ├── delivery-strategy-pilot.md (Delivery Strategy)
    └── github-project-template-pilot.md (COR Template)
```

### Consistência entre Discovery e Planning

| Decisão do Discovery | Como aparece no Planning |
|---|---|
| Uma Feature por vez | `iteration-plan-pilot.md` — Seção 1: restrição fundamental |
| Próxima Feature após `Finish.Completed` | `iteration-plan-pilot.md` — Seção 4: pré-condições por Feature |
| Gate entre Bloco 1 e Bloco 2 | `iteration-plan-pilot.md` — Seção 3, gate de bloco |
| Sequência: 001 → 002 → 003 → 004 → 005 → 006 | `iteration-plan-pilot.md` — Tabelas de Bloco 1 e Bloco 2 |
| DQ-01 a DQ-05 devem ser respondidas | `release-plan-pilot.md` — Exit Gate; `iteration-plan-pilot.md` — tabela de DQs |
| Critérios de não-conclusão (stop sign) | `release-plan-pilot.md` — Seção 3: saída antecipada |
| Lookback verificado em F-06 | `delivery-strategy-pilot.md` — events por fase (PI-006) |

---

## Decisões preservadas

### Decisão 1 — `/delivery` como executor determinístico (não decisor)

**Origem:** premissa do Prompt 02.

**Como foi preservada:** `iteration-plan-pilot.md` Seção 2 lista explicitamente o que o `/delivery` faz e o que não faz. A lista de "não" inclui: decide qual Feature executar, reordena Features, inicia Feature antes do `Finish.Completed` da anterior, toma decisão de Gate.Failed, decide se um bloqueio é Impediment ou Gate.

**Por que importa:** o `/delivery` futuro será implementado com base neste Iteration Plan. A separação entre execução determinística e decisão de produto deve ser explícita para que a implementação não incorpore lógica de priorização.

---

### Decisão 2 — Finish somente encerra após merge do PR

**Origem:** premissa do Prompt 02.

**Como foi preservada:** `delivery-strategy-pilot.md` Seção 4 (Fase 4 — Finish): "Invariante crítica: `Finish.Completed` só é emitido **após** o PR ser merged. Nunca antes."

**Por que importa:** `Finish.Completed` é o gate entre Features no Iteration Plan. Se o evento fosse emitido antes do merge, a próxima Feature poderia iniciar com código não integrado em `master`.

---

### Decisão 3 — Retorno de Finish para Hack via Rework (Changes Requested)

**Origem:** premissa do Prompt 02.

**Como foi preservada:** `delivery-strategy-pilot.md` Seção 3 descreve o fluxo completo de Changes Requested → `Rework.Started` → Hack → Sync → Finish → `Rework.Completed`. Inclui regra de decisão: o operador (não o `/delivery`) decide se a revisão dispara Rework ou mudança inline.

**Por que importa:** `Rework.Started` incrementa `rework_count` no OSE. Este padrão é exercitado por PI-PILOT-005. A regra de decisão separa Rework real (mudança significativa) de ajuste cosmético (sem impacto na Timeline).

---

### Decisão 4 — GitHub Project como COR apenas (nunca fonte de verdade)

**Origem:** manifest.yaml (`canonical_operational_representation`) + Discovery.

**Como foi preservada:** `github-project-template-pilot.md` Seção 1 e Seção 6 (Regras de representação). Regra 3: "Atualizar o GitHub Project não cria eventos na Timeline." Regra 2: "O Custom Field State é sempre o valor de `DerivedState.state` calculado pelo RT-02."

**Por que importa:** é a invariante arquitetural central do OEM. Se o GitHub Project fosse tratado como fonte de verdade, o Derived State do OSE seria ignorado — invalidando o RT-02 e o piloto.

---

### Decisão 5 — Drift de GitHub Project é aceito no piloto

**Origem:** RT-03 não implementado.

**Como foi preservada:** `github-project-template-pilot.md` Regra 6: "Como RT-03 não está implementado, haverá latência entre o Event Instance emitido via RT-01 e a atualização do Custom Field no GitHub Project. Esta latência é **conhecida e aceitável** no piloto."

**Por que importa:** sem documentar este drift explicitamente, o operador poderia interpretar o estado desatualizado no GitHub Project como o estado real — quando o RT-02 tem o estado correto.

---

## Próximos passos

### Imediatos (aguardando próximo prompt)

1. Verificar Entry Gate da Release (checklist em `release-plan-pilot.md` Seção 2)
2. Confirmar que os 5 artefatos deste Planning são consistentes com os 10 artefatos do Discovery (Prompt 01)
3. Aguardar próximo prompt

### Após aprovação do Planning

4. Executar Entry Gate da Release (verificar RT-01, RT-02, Workspace COR)
5. Iniciar IP-001: F-01 (Invoice PIX) — `Delivery.Bootstrap.Started`
6. Seguir a sequência do Iteration Plan: F-01 → F-02 → ... → F-06

### O que ainda não existe (aguarda execução)

| Artefato | Quando criar |
|---|---|
| Timelines das 6 Features | Durante a execução do Iteration Plan |
| Discovery Report preenchido (seções "A preencher") | Após conclusão de cada Feature |
| OBC definitivo | Após Discovery Report completo — Opção A |
| Dashboards Datadog | Pós-piloto (RT-04 + RT-05) |
| GitHub Sync automatizado (RT-03) | Pós-piloto |

---

## Inventário completo de artefatos (Prompt 01 + Prompt 02)

| Artefato | Localização | Prompt |
|---|---|---|
| BS-PILOT-001 | `prodops/artifacts/business-signals/BS-PILOT-001.md` | 01 |
| PI-PILOT-001 | `prodops/artifacts/business-intents/PI-PILOT-001.md` | 01 |
| PI-PILOT-002 | `prodops/artifacts/business-intents/PI-PILOT-002.md` | 01 |
| PI-PILOT-003 | `prodops/artifacts/business-intents/PI-PILOT-003.md` | 01 |
| PI-PILOT-004 | `prodops/artifacts/business-intents/PI-PILOT-004.md` | 01 |
| PI-PILOT-005 | `prodops/artifacts/business-intents/PI-PILOT-005.md` | 01 |
| PI-PILOT-006 | `prodops/artifacts/business-intents/PI-PILOT-006.md` | 01 |
| Discovery Report | `prodops/artifacts/product/discovery-report-pilot.md` | 01 |
| Roadmap | `prodops/artifacts/product/roadmap-pilot.md` | 01 |
| Release Draft | `prodops/artifacts/product/release-draft-pilot.md` | 01 |
| doc-review (Discovery) | `prodops/documentation-review-product-discovery-pilot.md` | 01 |
| Release Plan | `prodops/artifacts/product/release-plan-pilot.md` | 02 |
| Iteration Plan | `prodops/artifacts/plans/iteration-plan-pilot.md` | 02 |
| Delivery Strategy | `prodops/artifacts/product/delivery-strategy-pilot.md` | 02 |
| GitHub Project Template | `prodops/artifacts/product/github-project-template-pilot.md` | 02 |
| Este documento | `prodops/documentation-review-pilot-release-planning.md` | 02 |
