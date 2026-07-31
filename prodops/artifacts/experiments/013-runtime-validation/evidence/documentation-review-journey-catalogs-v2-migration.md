# Plano de Migração — Journey Catalogs v2
# ProdOps Framework — Shared Types Migration

> **Data:** 2026-07-25
> **Tipo:** Plano de migração — somente planejamento, sem alterações
> **Status:** Plano aprovado
> **Depende de:** [Shared Types](framework/events/shared-types.md) · [Lifecycle](framework/events/lifecycle.md)

---

## Executive Summary

| Item | Resultado |
|---|---|
| Journeys a migrar | 3 (Delivery, Diligence, Assessment) |
| Total de Event Types afetados | 11 (deprecações) + 1 (convergência técnica) |
| Tipos que permanecem exclusivos após migração | Delivery: 13 · Diligence: 16 · Assessment: 15 |
| Catálogos alterados neste documento | 0 |
| Trabalho adicional requerido antes da migração | Delivery v2: convergência técnica de Impediment.Resolved |
| Fases de execução | 5 (sequenciadas) |
| Risco mais crítico | Consumer breaking change na Delivery para Impediment.Resolved |

---

## 1. Inventário

### 1.1 Delivery — 17 Event Types

| # | Event Type | Situação pós-migração | Ação v2 |
|---|---|---|---|
| 1 | Bootstrap.Started | **Exclusivo** — permanece Active | Nenhuma |
| 2 | Bootstrap.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 3 | Hack.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 4 | Sync.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 5 | Finish.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 6 | Ship.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 7 | Promote.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 8 | **Gate.Passed** | **Promovido** → Shared.Gate.Passed (Active) | Deprecar em v2.0.0 |
| 9 | **Gate.Failed** | **Promovido** → Shared.Gate.Failed (Active) | Deprecar em v2.0.0 |
| 10 | Review.Approved | **Exclusivo** — permanece Active | Nenhuma |
| 11 | Review.ChangesRequested | **Exclusivo** — permanece Active | Nenhuma |
| 12 | Promote.Approved | **Exclusivo** — permanece Active | Nenhuma |
| 13 | Promote.Rejected | **Exclusivo** — permanece Active | Nenhuma |
| 14 | **Impediment.Declared** | **Promovido** → Shared.Impediment.Declared (Active) | Deprecar em v2.0.0 |
| 15 | **Impediment.Resolved** | **Convergência técnica** + Proposed (Shared) | Atualizar alters_state=false; Deprecar após shared-types v1.1.0 |
| 16 | Rework.Declared | **Exclusivo** — permanece Active | Nenhuma |
| 17 | Rework.Completed | **Exclusivo** — permanece Active | Nenhuma |

**Resumo Delivery:** 3 deprecações imediatas + 1 convergência + 13 exclusivos inalterados.

### 1.2 Diligence — 20 Event Types

| # | Event Type | Situação pós-migração | Ação v2 |
|---|---|---|---|
| 1 | Capture.Started | **Exclusivo** — permanece Active | Nenhuma |
| 2 | Capture.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 3 | Attach.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 4 | Promote.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 5 | Close.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 6 | Scan.Started | **Exclusivo** — permanece Active | Nenhuma |
| 7 | Scan.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 8 | Flag.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 9 | Repair.Started | **Exclusivo** — permanece Active | Nenhuma |
| 10 | Repair.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 11 | Promote.Approved | **Exclusivo** — permanece Active | Nenhuma |
| 12 | Promote.Rejected | **Exclusivo** — permanece Active | Nenhuma |
| 13 | Waiver.Granted | **Exclusivo** — permanece Active | Nenhuma |
| 14 | Waiver.Rejected | **Exclusivo** — permanece Active | Nenhuma |
| 15 | **Gate.Passed** | **Promovido** → Shared.Gate.Passed (Active) | Deprecar em v2.0.0 |
| 16 | **Gate.Failed** | **Promovido** → Shared.Gate.Failed (Active) | Deprecar em v2.0.0 |
| 17 | **Impediment.Declared** | **Promovido** → Shared.Impediment.Declared (Active) | Deprecar em v2.0.0 |
| 18 | **Impediment.Resolved** | Aguarda shared-types v1.1.0 | Deprecar após promoção do Shared Type |
| 19 | Divergence.Detected | **Exclusivo** — permanece Active | Nenhuma |
| 20 | Finding.Recorded | **Exclusivo** — permanece Active | Nenhuma |

**Resumo Diligence:** 3 deprecações imediatas + 1 condicional + 16 exclusivos inalterados.

### 1.3 Assessment — 19 Event Types

| # | Event Type | Situação pós-migração | Ação v2 |
|---|---|---|---|
| 1 | Collect.Started | **Exclusivo** — permanece Active | Nenhuma |
| 2 | Collect.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 3 | Analyze.Started | **Exclusivo** — permanece Active | Nenhuma |
| 4 | Analyze.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 5 | Synthesize.Completed | **Exclusivo** — permanece Active | Nenhuma |
| 6 | Report.Published | **Exclusivo** — permanece Active | Nenhuma |
| 7 | Monitor.Activated | **Exclusivo** — permanece Active | Nenhuma |
| 8 | Alert.Raised | **Exclusivo** — permanece Active | Nenhuma |
| 9 | Report.Approved | **Exclusivo** — permanece Active | Nenhuma |
| 10 | Report.Rejected | **Exclusivo** — permanece Active | Nenhuma |
| 11 | Recommendation.Issued | **Exclusivo** — permanece Active | Nenhuma |
| 12 | Risk.Identified | **Exclusivo** — permanece Active | Nenhuma |
| 13 | Opportunity.Identified | **Exclusivo** — permanece Active | Nenhuma |
| 14 | **Gate.Passed** | **Promovido** → Shared.Gate.Passed (Active) | Deprecar em v2.0.0 |
| 15 | **Gate.Failed** | **Promovido** → Shared.Gate.Failed (Active) | Deprecar em v2.0.0 |
| 16 | **Impediment.Declared** | **Promovido** → Shared.Impediment.Declared (Active) | Deprecar em v2.0.0 |
| 17 | **Impediment.Resolved** | Aguarda shared-types v1.1.0 | Deprecar após promoção do Shared Type |
| 18 | Threshold.Crossed | **Exclusivo** — permanece Active | Nenhuma |
| 19 | Evolve.Proposed | **Exclusivo** — permanece Active | Nenhuma |

**Resumo Assessment:** 3 deprecações imediatas + 1 condicional + 15 exclusivos inalterados.

---

## 2. Plano de migração por Shared Type

### 2.1 Gate.Passed → Shared.Gate.Passed

**Tipo Journey → Shared Type:**

| Journey | Tipo Journey (origin) | v1 status | Ação v2 | Shared substituto |
|---|---|---|---|---|
| Delivery | Delivery.Gate.Passed | Active | Deprecated | Shared.Gate.Passed |
| Diligence | Diligence.Gate.Passed | Active | Deprecated | Shared.Gate.Passed |
| Assessment | Assessment.Gate.Passed | Active | Deprecated | Shared.Gate.Passed |

**Estratégia de migração:**

Não há mudança semântica nem técnica — `alters_state=false` e o payload (`gate_name`, `duration_ms`)
são idênticos em todas as implementações. A migração é exclusivamente de nomenclatura:
a emissão passa de `{Journey}.Gate.Passed` para `Shared.Gate.Passed`.

**Passos para cada Journey:**

1. No catálogo v2: adicionar entrada do tipo com `lifecycle_status: Deprecated`,
   `deprecated_in: 2.0.0`, `deprecation_reason: "Promovido a Shared Type"`,
   `replacement_type: "Shared.Gate.Passed"`
2. Atualizar Skills que emitem `Gate.Passed` para referenciar o Shared Type
3. Manter a entrada no catálogo como referência histórica (não remover)

**Compatibilidade retroativa:**

100% preservada. Timelines históricas com `Gate.Passed` emitido sob os catálogos v1
continuam válidas. O tipo Deprecated não é removido — apenas não deve ser emitido em
novos eventos. Consumers processando Timelines históricas continuam reconhecendo o tipo.

---

### 2.2 Gate.Failed → Shared.Gate.Failed

Estratégia idêntica a Gate.Passed. Payload (`gate_name`, `reason`, `duration_ms`) é
idêntico nas três Journeys. Nenhuma mudança semântica ou técnica.

**Compatibilidade retroativa:** 100% preservada — mesma análise de Gate.Passed.

---

### 2.3 Impediment.Declared → Shared.Impediment.Declared

**Tipo Journey → Shared Type:**

| Journey | alters_state | new_state | Payload v1 | Payload Shared |
|---|---|---|---|---|
| Delivery | true | BLOCKED | impediment_description, blocking_since | idêntico |
| Diligence | true | BLOCKED | impediment_description, blocking_since | idêntico |
| Assessment | true | BLOCKED | impediment_description, blocking_since | idêntico |

**Estratégia de migração:** idêntica a Gate.Passed — zero variação técnica ou semântica.

**Compatibilidade retroativa:** 100% preservada.

---

### 2.4 Impediment.Resolved (convergência Delivery + promoção futura)

Este é o caso mais complexo e o único que exige mudança técnica antes da migração.

**Situação atual:**

| Journey | alters_state | new_state | Padrão |
|---|---|---|---|
| Delivery v1 | `true` | `HACKING` (hardcoded) | Simplificação MVP documentada |
| Diligence | `false` | — (Lookback) | Padrão canônico |
| Assessment | `false` | — (Lookback) | Padrão canônico |
| Shared (target) | `false` | — (Lookback) | Padrão canônico |

**O problema:**

A mudança de `alters_state: true → false` em Delivery v2 é uma alteração na definição
do Event Type. Consumers que processam Timelines da Delivery e dependem de
`Impediment.Resolved` como evento state-altering (para calcular Derived State) precisam
ser atualizados.

Especificamente: o Consumer que calcula o Derived State de uma Timeline da Delivery
após um `Impediment.Resolved` precisará usar Lookback (`preBlockedState`) em vez de
assumir `new_state = HACKING`.

Ver seção 4 para o plano detalhado.

---

## 3. Plano de Deprecação

### 3.1 Tipos a deprecar imediatamente (Gate.Passed, Gate.Failed, Impediment.Declared)

Para cada um dos 9 tipos (3 tipos × 3 Journeys):

**Campos obrigatórios no catálogo v2:**

```
lifecycle_status: Deprecated
deprecated_in: 2.0.0
deprecation_reason: Promovido a Shared Type. Ver framework/events/shared-types.md.
replacement_type: Shared.<NomeDoTipo>
migration_deadline: 2.0.0 (imediato — migração simultânea à deprecação)
```

**Quando podem ser removidos (Deprecated → Removed):**

Critérios per `lifecycle.md` seção 2.1 — Deprecated → Removed:

1. Nenhuma nova emissão do tipo Journey ocorreu após a `migration_deadline`
2. Todas as Skills que emitiam o tipo foram atualizadas para o Shared Type
3. Event Consumers confirmaram que tratam o tipo como histórico
4. Período mínimo: ao menos **um ciclo completo** de cada Journey sem novas emissões
   (um ciclo de Delivery = uma entrega completa de Work Item; um ciclo de Diligence =
   um ciclo completo de Scan; um ciclo de Assessment = um Assessment Sync completo)

**Preservação de Timelines históricas:**

O tipo Deprecated permanece como entrada read-only no catálogo. Timelines históricas
que referenciam `Gate.Passed` (Journey origin) continuam válidas e processáveis.
Nenhuma retroconversão é necessária ou desejável.

### 3.2 Impediment.Resolved — deprecação condicional

A deprecação do tipo Journey `Impediment.Resolved` em cada catálogo só pode ocorrer após:

1. Shared Types v1.1.0 promover `Impediment.Resolved` para Active
2. A Journey ter confirmado compatibilidade com o Shared Type

**Delivery:** adicional — a convergência técnica (seção 4) é pré-requisito.
**Diligence e Assessment:** já usam `alters_state=false` — podem deprecar imediatamente após shared-types v1.1.0.

---

## 4. Plano Delivery v2 — Convergência de Impediment.Resolved

### 4.1 A mudança técnica

| Campo | Valor v1 (atual) | Valor v2 (target) |
|---|---|---|
| `alters_state` | `true` | `false` |
| `new_state` | `HACKING` | — (removido) |
| Comportamento | Altera o Derived State diretamente | Consumer usa Lookback |
| `lifecycle_status` | Active | Deprecated → Shared.Impediment.Resolved |

### 4.2 Impacto em Consumers existentes

**Consumers afetados:** qualquer Consumer que processa Timelines da Delivery e:

- Calcula o Derived State após um `Impediment.Resolved` sem usar Lookback
- Depende explicitamente de `new_state = HACKING` para determinar o estado de retorno

**Consumers não afetados:**

- Consumers que apenas leem eventos sem calcular Derived State (relatórios, auditoria)
- Consumers que processam Timelines completas (DONE) — o estado final é o mesmo
- Consumers que já implementam Lookback (nenhum atualmente, mas a migração é o pré-requisito)

### 4.3 Análise de impacto retroativo em Timelines históricas

**Cenário:** Timeline com `Impediment.Resolved` emitido sob Delivery v1 (alters_state=true):

```
pos 1: Bootstrap.Started    → BOOTSTRAPPING
pos 2: Bootstrap.Completed  → HACKING
pos 3: Impediment.Declared  → BLOCKED
pos 4: Impediment.Resolved  [v1: alters_state=true, new_state=HACKING]
pos 5: Hack.Completed       → SYNCING
...
pos N: Promote.Completed    → DONE
```

**Computed Derived State em pos 4, sob v1:** HACKING (explícito via new_state)
**Computed Derived State em pos 4, sob v2:** BLOCKED (alters_state=false; Lookback retorna HACKING como estado efetivo, mas o Derived State da Timeline permanece BLOCKED até o próximo alters_state=true em pos 5)

**Impacto real:**
- Para Timelines COMPLETAS (DONE): o Derived State em qualquer ponto posterior a pos 5
  é idêntico em v1 e v2. **Impacto: zero.**
- Para Timelines COM EVENTOS FUTUROS MAS ABERTAS: o estado no intervalo entre pos 4 e
  pos 5 difere (v1: HACKING; v2: BLOCKED). Impacto baixo — o Consumer que usa Lookback
  saberá que o trabalho retomou, mesmo com Derived State = BLOCKED.
- Para Timelines SEM EVENTO APÓS Impediment.Resolved (Work Item travado entre resolução
  e próximo ato): o Derived State calculado difere. Impacto potencialmente relevante.

**Mitigação:**

**Estratégia de cutover temporal:** usar o `timestamp` do Event Instance como discriminador.

```
function deriveStateFromImpedimentResolved(event, timeline):
  DELIVERY_V2_CUTOVER = <data de publicação de Delivery v2>
  
  if event.timestamp < DELIVERY_V2_CUTOVER:
    // Emitido sob Delivery v1 — comportamento legado
    return "HACKING"
  else:
    // Emitido sob Delivery v2 — padrão Lookback
    return preBlockedState(timeline, event.position)
```

Esta estratégia não requer alteração nos Event Instances (que são imutáveis) e não exige
um campo adicional nos eventos. O Consumer usa o timestamp do evento e o timestamp de corte
da migração para determinar qual comportamento aplicar.

**Alternativa:** adicionar um campo `legacy_new_state: "HACKING"` ao payload dos novos
eventos emitidos sob o padrão v2, para facilitar migração gradual. **Não recomendada** —
adiciona ruído ao payload e contradiz a semântica do tipo.

**Recomendação:** cutover temporal com timestamp de migração documentado no catálogo Delivery v2.

### 4.4 Sequência de execução para Delivery v2

```
Passo 1 — Auditoria de Consumers (pré-migração)
│
│  • Identificar todos os Consumers de Timelines da Delivery
│  • Catalogar quais dependem de Impediment.Resolved como state-altering
│  • Confirmar quais serão atualizados antes ou junto com o catálogo
│
↓
Passo 2 — Atualizar Consumers para suportar Lookback
│
│  • Implementar preBlockedState() nos Consumers afetados
│  • Validar com Timelines históricas (os Consumers devem produzir
│    resultado equivalente para Timelines completas)
│
↓
Passo 3 — Publicar Delivery v2 catalog
│
│  • Impediment.Resolved: alters_state=false, new_state removido
│  • Impediment.Resolved: lifecycle_status=Active (temporário — será Deprecated
│    quando shared-types v1.1.0 promover o Shared Type)
│  • Gate.Passed, Gate.Failed, Impediment.Declared: Deprecated
│  • Registrar DELIVERY_V2_CUTOVER timestamp no catalog changelog
│
↓
Passo 4 — Publicar shared-types.md v1.1.0
│
│  • Impediment.Resolved: Proposed → Active
│  • CRT-02 reavaliado e satisfeito
│
↓
Passo 5 — Delivery v2.1: deprecar Impediment.Resolved
│
│  • Impediment.Resolved: Active → Deprecated
│  • replacement_type: Shared.Impediment.Resolved
│
↓
Passos 6-7 — Diligence v2, Assessment v2 (paralelo)
│
│  • Gate.Passed, Gate.Failed, Impediment.Declared, Impediment.Resolved: Deprecated
│  • Referência ao Shared Type em cada tipo
```

---

## 5. Compatibilidade retroativa — demonstração

### 5.1 Invariante OEM preservado

O OEM define (`timeline.md` seção 1):
> A Timeline é imutável e append-only. Event Instances já registradas nunca são alteradas.

A migração v2 **não altera Event Instances**. Ela altera apenas as definições dos Event Types
no catálogo da Journey. As Event Instances armazenam:
- `event_type`: nome do tipo (string)
- `schema_version`: versão do schema OEM no momento da emissão
- `payload`: dados imutáveis

Nenhum desses campos é alterado pela migração.

### 5.2 Demonstration por tipo

| Event Type | Timelines históricas | Computed Derived State | Impacto |
|---|---|---|---|
| `Gate.Passed` (deprecado) | Mantidas integralmente | Inalterado — alters_state=false em v1 e v2 | Zero |
| `Gate.Failed` (deprecado) | Mantidas integralmente | Inalterado — alters_state=false em v1 e v2 | Zero |
| `Impediment.Declared` (deprecado) | Mantidas integralmente | Inalterado — alters_state=true, new_state=BLOCKED em v1 e v2 | Zero |
| `Impediment.Resolved` Delivery (convergência) | Mantidas — cutover temporal necessário | Diferença no estado do intervalo pós-resolução pré-próximo-evento | **Baixo** — mitigado por cutover temporal |
| `Impediment.Resolved` Diligence/Assessment (deprecado) | Mantidas integralmente | Inalterado — alters_state=false em v1 e v2 | Zero |

### 5.3 Garantia de backward compatibility para Consumers

Consumers que processam Timelines históricas devem continuar suportando os tipos
Deprecated para leitura. Os catálogos v2 não removem os tipos — apenas os marcam como
Deprecated com referência ao Shared Type.

**Consumer update contract:**
- Novos eventos (pós-migração): emitidos com Shared Type → Consumer usa definição Shared
- Eventos históricos (pré-migração): referenciados com tipo Journey → Consumer usa definição Journey v1
- Discriminador recomendado: timestamp do evento vs. cutover timestamp da migração

---

## 6. Estado final dos catálogos após migração completa

### 6.1 Delivery v2 — estado final

| Event Type | Status | Notas |
|---|---|---|
| Bootstrap.Started | Active | Exclusivo |
| Bootstrap.Completed | Active | Exclusivo |
| Hack.Completed | Active | Exclusivo |
| Sync.Completed | Active | Exclusivo |
| Finish.Completed | Active | Exclusivo |
| Ship.Completed | Active | Exclusivo |
| Promote.Completed | Active | Exclusivo |
| **Gate.Passed** | **Deprecated** | replacement: Shared.Gate.Passed |
| **Gate.Failed** | **Deprecated** | replacement: Shared.Gate.Failed |
| Review.Approved | Active | Exclusivo |
| Review.ChangesRequested | Active | Exclusivo |
| Promote.Approved | Active | Exclusivo |
| Promote.Rejected | Active | Exclusivo |
| **Impediment.Declared** | **Deprecated** | replacement: Shared.Impediment.Declared |
| **Impediment.Resolved** | **Deprecated** | alters_state=false (convergência) · replacement: Shared.Impediment.Resolved |
| Rework.Declared | Active | Exclusivo |
| Rework.Completed | Active | Exclusivo |
| **Total Active** | **13** | — |
| **Total Deprecated** | **4** | — |

### 6.2 Diligence v2 — estado final

| Event Type | Status | Notas |
|---|---|---|
| Capture.Started | Active | Exclusivo |
| Capture.Completed | Active | Exclusivo |
| Attach.Completed | Active | Exclusivo |
| Promote.Completed | Active | Exclusivo |
| Close.Completed | Active | Exclusivo |
| Scan.Started | Active | Exclusivo |
| Scan.Completed | Active | Exclusivo |
| Flag.Completed | Active | Exclusivo |
| Repair.Started | Active | Exclusivo |
| Repair.Completed | Active | Exclusivo |
| Promote.Approved | Active | Exclusivo |
| Promote.Rejected | Active | Exclusivo |
| Waiver.Granted | Active | Exclusivo |
| Waiver.Rejected | Active | Exclusivo |
| **Gate.Passed** | **Deprecated** | replacement: Shared.Gate.Passed |
| **Gate.Failed** | **Deprecated** | replacement: Shared.Gate.Failed |
| **Impediment.Declared** | **Deprecated** | replacement: Shared.Impediment.Declared |
| **Impediment.Resolved** | **Deprecated** | replacement: Shared.Impediment.Resolved |
| Divergence.Detected | Active | Exclusivo |
| Finding.Recorded | Active | Exclusivo |
| **Total Active** | **16** | — |
| **Total Deprecated** | **4** | — |

### 6.3 Assessment v2 — estado final

| Event Type | Status | Notas |
|---|---|---|
| Collect.Started | Active | Exclusivo |
| Collect.Completed | Active | Exclusivo |
| Analyze.Started | Active | Exclusivo |
| Analyze.Completed | Active | Exclusivo |
| Synthesize.Completed | Active | Exclusivo |
| Report.Published | Active | Exclusivo |
| Monitor.Activated | Active | Exclusivo |
| Alert.Raised | Active | Exclusivo |
| Report.Approved | Active | Exclusivo |
| Report.Rejected | Active | Exclusivo |
| Recommendation.Issued | Active | Exclusivo |
| Risk.Identified | Active | Exclusivo |
| Opportunity.Identified | Active | Exclusivo |
| **Gate.Passed** | **Deprecated** | replacement: Shared.Gate.Passed |
| **Gate.Failed** | **Deprecated** | replacement: Shared.Gate.Failed |
| **Impediment.Declared** | **Deprecated** | replacement: Shared.Impediment.Declared |
| **Impediment.Resolved** | **Deprecated** | replacement: Shared.Impediment.Resolved |
| Threshold.Crossed | Active | Exclusivo |
| Evolve.Proposed | Active | Exclusivo |
| **Total Active** | **15** | — |
| **Total Deprecated** | **4** | — |

### 6.4 Shared Types — estado após v1.1.0

| Event Type | Status | Adicionado em |
|---|---|---|
| Gate.Passed | Active | shared-types 1.0.0 |
| Gate.Failed | Active | shared-types 1.0.0 |
| Impediment.Declared | Active | shared-types 1.0.0 |
| Impediment.Resolved | **Active** (promovido de Proposed) | shared-types 1.1.0 |

---

## 7. Riscos

### Risco 1 — Consumer breaking change para Impediment.Resolved Delivery (ALTO)

**Descrição:** Consumers que calculam Derived State de Timelines da Delivery usando
`Impediment.Resolved` como estado-altering vão produzir resultados incorretos após
Delivery v2 se não forem atualizados antes.

**Probabilidade:** Alta — qualquer Consumer que implementa `derivedState(timeline)` sem
Lookback é afetado.

**Impacto:** Alto — se não mitigado, Consumers retornariam BLOCKED em vez de HACKING
para o período entre Impediment.Resolved e o próximo evento state-altering.

**Mitigação:**
1. Auditoria de Consumers antes da publicação de Delivery v2 (Passo 1 do plano)
2. Implementação de Lookback nos Consumers afetados como pré-requisito (Passo 2)
3. Estratégia de cutover temporal para Timelines históricas
4. Rollout com feature flag: Consumers habilitam novo comportamento gradualmente

**Critério de go/no-go:** todos os Consumers auditados em Passo 1 foram atualizados e
validados antes da publicação de Delivery v2.

---

### Risco 2 — Skills emitindo tipos Journey após deprecação (MÉDIO)

**Descrição:** Skills que continuam emitindo `Gate.Passed` (Journey) em vez de
`Shared.Gate.Passed` após a deprecação. Tecnicamente, Events ainda são reconhecidos
(o tipo Deprecated permanece no catálogo), mas semanticamente as Skills estariam
emitindo um tipo deprecated — Anti-Pattern ANT-LC-01.

**Mitigação:**
1. Atualizar Skills como parte do mesmo release do catálogo v2 (migração simultânea)
2. Adicionar validação de lifecycle_status nas Skills — rejeitar emissão de tipos Deprecated
3. `migration_deadline: 2.0.0` (imediato) sinaliza que não há período de tolerância

---

### Risco 3 — Migração parcial (catálogos v2 sem Skills atualizadas) (MÉDIO)

**Descrição:** catálogo publicado como v2 mas Skills ainda emitindo tipos v1. Durante
o período de inconsistência, novos Event Instances têm `event_type` desalinhado com
o catálogo atual.

**Mitigação:**
1. Publicar catálogo v2 e Skills atualizadas no mesmo momento (deploy atômico)
2. Validar em ambiente de staging antes de publicar

---

### Risco 4 — Ordem de migração incorreta para Impediment.Resolved (MÉDIO)

**Descrição:** Se Diligence ou Assessment deprecarem `Impediment.Resolved` como Shared
ANTES de shared-types v1.1.0 existir, o `replacement_type` apontaria para um tipo não
existente.

**Mitigação:** a ordem de execução (seção 8) é sequencial para Impediment.Resolved —
Delivery v2 → shared-types v1.1.0 → Diligence v2 + Assessment v2.

---

### Risco 5 — Remoção prematura de tipos Deprecated (BAIXO)

**Descrição:** equipe remove tipos Deprecated antes dos critérios de remoção serem
satisfeitos, invalidando referências em Timelines históricas.

**Mitigação:** critérios de remoção documentados explicitamente (seção 3.1). Remoção
só após ciclo completo de cada Journey sem novas emissões + confirmação de Consumers.

---

## 8. Ordem recomendada de execução

```
FASE 1 — Pré-migração (sem publicação de catálogo)
────────────────────────────────────────────────────
  1.1 Auditar todos os Consumers de Timelines da Delivery
  1.2 Identificar dependências em Impediment.Resolved como state-altering
  1.3 Implementar preBlockedState() nos Consumers afetados
  1.4 Validar retrocompatibilidade com Timelines históricas em staging
  1.5 Critério de saída: todos os Consumers auditados e atualizados

FASE 2 — Delivery v2 (desbloqueante crítico)
────────────────────────────────────────────────────
  2.1 Publicar Delivery catalog v2.0.0:
      • Gate.Passed → Deprecated (replacement: Shared.Gate.Passed)
      • Gate.Failed → Deprecated (replacement: Shared.Gate.Failed)
      • Impediment.Declared → Deprecated (replacement: Shared.Impediment.Declared)
      • Impediment.Resolved → alters_state=false (convergência técnica)
      • Registrar DELIVERY_V2_CUTOVER timestamp
  2.2 Atualizar Skills de Delivery para emitir Shared Types
  2.3 Critério de saída: nenhum Consumer reportando regressão

FASE 3 — Shared Types v1.1.0
────────────────────────────────────────────────────
  3.1 Reavaliar CRT-02 para Impediment.Resolved (agora satisfeito)
  3.2 Publicar shared-types.md v1.1.0:
      • Impediment.Resolved: Proposed → Active
  3.3 Critério de saída: Shared Type publicado

FASE 4 — Diligence v2 e Assessment v2 (paralelo)
────────────────────────────────────────────────────
  4.1 Publicar Diligence catalog v2.0.0:
      • Gate.Passed, Gate.Failed, Impediment.Declared → Deprecated
      • Impediment.Resolved → Deprecated (replacement: Shared.Impediment.Resolved)
  4.2 Atualizar Skills de Diligence
  4.3 Publicar Assessment catalog v2.0.0 (idêntico ao Diligence em estrutura)
  4.4 Atualizar Skills de Assessment
  4.5 Critério de saída: ambos os catálogos publicados, Skills atualizadas

FASE 5 — Validação pós-migração
────────────────────────────────────────────────────
  5.1 Verificar que nenhuma nova emissão de tipos Deprecated está ocorrendo
  5.2 Confirmar que Consumers processam Timelines históricas corretamente
  5.3 Registrar data de conclusão da migração em cada catálogo
  5.4 Iniciar contagem para elegibilidade de remoção (Deprecated → Removed)
  5.5 Critério de saída: relatório de migração completo publicado
```

**Duração estimada por fase:**
- Fase 1: maior variação — depende da quantidade de Consumers
- Fases 2-5: podem ser executadas em sequência rápida uma vez que Fase 1 esteja completa

---

## 9. Confirmação de invariantes arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| OEM (README, Ontology, Taxonomy, Lifecycle, Schemas, Timeline) | Não alterado |
| Shared Types v1.0.0 | Não alterado |
| Delivery Event Catalog v1 | Não alterado |
| Diligence Event Catalog v1 | Não alterado |
| Assessment Event Catalog v1 | Não alterado |
| Cross-Journey Event Analysis | Não alterado |
| Nenhum novo Event Type criado | Confirmado |
| Nenhuma nova Event Category criada | Confirmado |
| Nenhum tipo renomeado | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 10. Arquivos criados e alterados

### Criados

| Arquivo | Conteúdo |
|---|---|
| `prodops/documentation-review-journey-catalogs-v2-migration.md` | Este documento |

### Alterados

Nenhum arquivo existente foi alterado.
