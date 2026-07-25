# Shared Types — Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [Event Type Schema](event-type-schema.md) · [Lifecycle](lifecycle.md) · [Taxonomy](taxonomy.md)
> **Evidências de promoção:** [Cross-Journey Analysis](../../documentation-review-cross-journey-event-analysis.md)

---

## Sobre este documento

Este é o catálogo canônico dos **Shared Event Types** do Operational Event Model — tipos
de evento promovidos ao nível de Framework e reutilizáveis por qualquer Journey, presente
ou futura.

Um tipo só entra neste catálogo após satisfazer todos os cinco critérios de promoção
(CRT-01 a CRT-05) definidos em `lifecycle.md` seção 3, com evidência documentada.

Este documento não define catálogos de Journey. Não altera nenhum catálogo existente.

---

## 1. Tipos neste catálogo

| # | Event Type | Status | Journeys confirmadas | Data de promoção |
|---|---|---|---|---|
| 1 | **Gate.Passed** | Active | Delivery · Diligence · Assessment | 2026-07-25 |
| 2 | **Gate.Failed** | Active | Delivery · Diligence · Assessment | 2026-07-25 |
| 3 | **Impediment.Declared** | Active | Delivery · Diligence · Assessment | 2026-07-25 |
| 4 | **Impediment.Resolved** | Proposed | Delivery (simplif.) · Diligence · Assessment | Pendente Delivery v2 |

---

## 2. Critérios de promoção

Os critérios abaixo, definidos em `lifecycle.md` seção 3.2, **devem ser satisfeitos na
totalidade** para que um tipo seja promovido:

| Critério | Descrição |
|---|---|
| **CRT-01** | Reutilização ativa ou comprovada em duas ou mais Journeys |
| **CRT-02** | Equivalência semântica verificada — precondições e pós-condições fazem sentido em todas as Journeys que o usariam |
| **CRT-03** | Estabilidade demonstrada — sem mudanças em Category, alters_state, ou new_state desde a introdução |
| **CRT-04** | Generalidade sem perda de precisão — o nome do tipo permanece preciso e auto-descritivo fora da Journey de origem |
| **CRT-05** | Sem duplicata no catálogo compartilhado |

---

## 3. Governança

### 3.1 Quem pode propor um novo Shared Type

Qualquer **Journey owner** ou **contribuidor do Framework** pode propor um tipo para promoção, desde que:

1. O tipo Journey origem esteja em status **Active** (não é possível propor um Draft)
2. Exista evidência documentada de uso em **pelo menos duas Journeys** com semântica equivalente
3. A proposta inclua análise formal dos CRT-01 a CRT-05 com evidências citadas
4. A análise confirme que não existe tipo equivalente já no catálogo Shared

**Formato de proposta:** documento `prodops/documentation-review-[tipo]-shared-promotion.md`
contendo a análise completa dos cinco critérios, lista das Journeys envolvidas, e proposta
de definição canônica.

### 3.2 Quem aprova

**Exclusivamente o Framework** — representado pelo mantenedor do OEM.

A aprovação é concedida quando:
- Todos os CRT satisfeitos com evidências documentadas
- Nenhuma Journey consultada identificou conflito semântico ou técnico
- A definição canônica está completa (todos os campos obrigatórios do Event Type Schema)
- O nome do tipo não colide com nenhum tipo existente em nenhum catálogo

O Framework pode aprovar, recusar, ou aprovar com ajustes. Em caso de recusa, feedback
estruturado é registrado para que a Journey possa re-submeter ou manter o tipo como
Journey Type.

### 3.3 Quando um Shared Type pode ser depreciado

Um Shared Type pode ser depreciado pelo Framework quando:

| Situação | Critério |
|---|---|
| **Substituição** | Um tipo mais preciso está disponível e as Journeys confirmaram migração |
| **Obsolescência** | Nenhuma Journey emitiu eventos do tipo por pelo menos dois ciclos completos |
| **Refatoração do modelo** | Uma revisão do OEM torna o tipo conceitualmente inadequado |

Um Shared Type **não deve ser depreciado** por:
- "O nome poderia ser melhor" — names de tipos Active são imutáveis (INV-LC-05)
- "Poucas Journeys usam" — baixo uso não é critério; uso zero por múltiplos ciclos pode ser

### 3.4 Como uma Journey deve migrar para um Shared Type promovido

Quando um tipo é promovido a Shared, as Journeys que o utilizavam devem:

**Passo 1 — Deprecar o tipo Journey:** no catálogo da Journey, marcar o tipo Journey
original como `Deprecated` com:
- `deprecated_in`: versão do catálogo Journey em que ocorre a depreciação
- `deprecation_reason`: "Promovido a Shared Type. Ver `framework/events/shared-types.md`."
- `replacement_type`: referência ao Shared Type (ex.: `Shared.Gate.Passed`)

**Passo 2 — Atualizar as Skills:** Skills que emitiam o tipo Journey passam a emitir
o Shared Type. O `event_type` nas Event Instances passa a referenciar o nome Shared.

**Passo 3 — Preservar o histórico:** Timelines históricas que contêm o tipo Journey
original permanecem válidas e imutáveis. Event Consumers devem continuar reconhecendo
o tipo Journey deprecated para processamento de histórico.

**Nota sobre os catálogos atuais:** os catálogos MVP de Delivery, Diligence e Assessment
não foram alterados por este documento. A depreciação dos tipos Journey de origem é
trabalho dos catálogos v2 de cada Journey. As Timelines históricas com os tipos Journey
permanecem inteiramente válidas.

---

## 4. Active Shared Types

---

### 4.1 Gate.Passed

| Campo | Valor |
|---|---|
| **name** | `Gate.Passed` |
| **namespace** | `Shared` (derivado de `is_shared = true`) |
| **category** | Gate |
| **alters_state** | `false` |
| **new_state** | — |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | **Active** |
| **introduced_in** | shared-types 1.0.0 |
| **is_shared** | `true` |
| **promotion_origin** | `Delivery.Gate.Passed` · `Diligence.Gate.Passed` · `Assessment.Gate.Passed` |

**Definição canônica:**
Um gate automatizado de qualidade passou com sucesso. O gate verifica um critério específico
de qualidade sem alterar o estado do Work Item. O Producer registra o resultado positivo na
Timeline. Múltiplos Gate.Passed podem ocorrer na mesma Timeline em fases diferentes.

**Precondições canônicas:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado e produziu resultado positivo

**Pós-condições canônicas:**
- O resultado positivo do gate está registrado na Timeline
- O Derived State do Work Item não é alterado

**Payload mínimo garantido:**

| Campo | Tipo | Obrigatoriedade | Descrição |
|---|---|---|---|
| `gate_name` | string | Obrigatório | Identificador do gate executado (ex.: `smoke-test`, `lint`, `readiness-check`, `data-completeness`) |
| `duration_ms` | integer | Obrigatório | Duração da execução do gate em milissegundos |

Journeys podem adicionar campos adicionais ao payload — mas `gate_name` e `duration_ms`
são obrigatórios em qualquer implementação.

**Journeys que utilizam:**

| Journey | Tipo Journey (origin) | Introduzido em | Notas |
|---|---|---|---|
| Delivery | `Delivery.Gate.Passed` | 1.0.0 | Verifica lint, testes, cobertura, segurança |
| Diligence | `Diligence.Gate.Passed` | 1.0.0 | Verifica readiness, labels canônicas, conformidade |
| Assessment | `Assessment.Gate.Passed` | 1.0.0 | Verifica completude de dados, cobertura de métricas |

**Verificação dos critérios de promoção:**

| Critério | Satisfeito? | Evidência |
|---|---|---|
| CRT-01 | **Sim** | Uso ativo em 3 Journeys (Delivery, Diligence, Assessment) |
| CRT-02 | **Sim** | Semântica idêntica: "gate automatizado passou"; precondições e pós-condições equivalentes nas 3 Journeys; variação legítima apenas em `gate_name` |
| CRT-03 | **Sim** | Active desde 1.0.0 em todas as Journeys — sem mudança em Category, alters_state, producers, ou payload |
| CRT-04 | **Sim** | `Gate.Passed` é preciso e auto-descritivo fora de qualquer Journey |
| CRT-05 | **Sim** | Nenhum tipo equivalente existia no catálogo Shared antes desta promoção |

**Histórico de promoção:**

| Data | Evento | Referência |
|---|---|---|
| 2026-07-24 | Identificado como candidato em cross-journey analysis | [Cross-Journey Analysis](../../documentation-review-cross-journey-event-analysis.md) |
| 2026-07-25 | Confirmado pela terceira Journey (Assessment) | [Assessment Event Catalog](../../documentation-review-assessment-event-catalog.md) |
| 2026-07-25 | Promovido a Shared Type — todos os CRTs satisfeitos | Este documento v1.0.0 |

---

### 4.2 Gate.Failed

| Campo | Valor |
|---|---|
| **name** | `Gate.Failed` |
| **namespace** | `Shared` |
| **category** | Gate |
| **alters_state** | `false` |
| **new_state** | — |
| **producer_subtypes** | `[System, Agent]` |
| **lifecycle_status** | **Active** |
| **introduced_in** | shared-types 1.0.0 |
| **is_shared** | `true` |
| **promotion_origin** | `Delivery.Gate.Failed` · `Diligence.Gate.Failed` · `Assessment.Gate.Failed` |

**Definição canônica:**
Um gate automatizado de qualidade falhou. O critério verificado não foi satisfeito. O Work
Item permanece no estado atual — a falha do gate é um sinal para que o Producer tome ação
corretiva. O Producer é responsável por declarar Rework (Delivery) ou emitir a rejeição
apropriada (Diligence, Assessment) se a falha exigir retorno ao passo anterior.

**Precondições canônicas:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um gate automatizado foi executado e produziu resultado de falha

**Pós-condições canônicas:**
- A falha do gate está registrada na Timeline
- O Derived State do Work Item não é alterado
- O Producer determina a ação corretiva apropriada à Journey

**Payload mínimo garantido:**

| Campo | Tipo | Obrigatoriedade | Descrição |
|---|---|---|---|
| `gate_name` | string | Obrigatório | Identificador do gate executado |
| `reason` | string | Obrigatório | Descrição da causa da falha ou do critério não satisfeito |
| `duration_ms` | integer | Obrigatório | Duração da execução do gate em milissegundos |

**Journeys que utilizam:**

| Journey | Tipo Journey (origin) | Introduzido em | Comportamento pós-falha |
|---|---|---|---|
| Delivery | `Delivery.Gate.Failed` | 1.0.0 | Producer declara `Rework.Declared` se a falha exigir retorno |
| Diligence | `Diligence.Gate.Failed` | 1.0.0 | Producer avalia se `Promote.Rejected` deve ser emitido |
| Assessment | `Assessment.Gate.Failed` | 1.0.0 | Producer avalia se `Report.Rejected` deve ser emitido |

**Verificação dos critérios de promoção:**

| Critério | Satisfeito? | Evidência |
|---|---|---|
| CRT-01 | **Sim** | Uso ativo em 3 Journeys |
| CRT-02 | **Sim** | Semântica idêntica: "gate automatizado falhou"; a ação corretiva pós-falha varia por Journey mas é responsabilidade do Producer — não altera a semântica do tipo |
| CRT-03 | **Sim** | Active desde 1.0.0 em todas as Journeys — sem mudança em propriedades críticas |
| CRT-04 | **Sim** | `Gate.Failed` é preciso e auto-descritivo fora de qualquer Journey |
| CRT-05 | **Sim** | Nenhum tipo equivalente existia no catálogo Shared |

**Histórico de promoção:**

| Data | Evento | Referência |
|---|---|---|
| 2026-07-24 | Identificado como candidato | [Cross-Journey Analysis](../../documentation-review-cross-journey-event-analysis.md) |
| 2026-07-25 | Confirmado pela terceira Journey | [Assessment Event Catalog](../../documentation-review-assessment-event-catalog.md) |
| 2026-07-25 | Promovido a Shared Type | Este documento v1.0.0 |

---

### 4.3 Impediment.Declared

| Campo | Valor |
|---|---|
| **name** | `Impediment.Declared` |
| **namespace** | `Shared` |
| **category** | Blocking |
| **alters_state** | `true` |
| **new_state** | `BLOCKED` |
| **producer_subtypes** | `[Human, Agent]` |
| **lifecycle_status** | **Active** |
| **introduced_in** | shared-types 1.0.0 |
| **is_shared** | `true` |
| **promotion_origin** | `Delivery.Impediment.Declared` · `Diligence.Impediment.Declared` · `Assessment.Impediment.Declared` |

**Definição canônica:**
Um impedimento externo foi declarado para o Work Item. O trabalho não pode progredir até
que o impedimento seja resolvido. Um impedimento é uma causa externa ao Work Item que bloqueia
a sua progressão — não é uma decisão de rejeição, não é uma falha de qualidade, e não é
uma pausa voluntária. O Work Item transita para o estado BLOCKED e permanece neste estado
até que Impediment.Resolved seja emitido.

**Precondições canônicas:**
- O Work Item está em qualquer estado ativo (não DONE, não BLOCKED)
- Um impedimento externo foi identificado que impede a progressão do Work Item

**Pós-condições canônicas:**
- O Work Item transita para o estado `BLOCKED`
- O impedimento está descrito e registrado na Timeline
- O trabalho é suspenso até `Impediment.Resolved`

**Payload mínimo garantido:**

| Campo | Tipo | Obrigatoriedade | Descrição |
|---|---|---|---|
| `impediment_description` | string | Obrigatório | Descrição do impedimento e de quem ou o que pode resolvê-lo |
| `blocking_since` | string | Obrigatório | Timestamp (ISO 8601) em que o impedimento foi identificado — pode ser anterior ao timestamp do evento |

**Journeys que utilizam:**

| Journey | Tipo Journey (origin) | Introduzido em | Contexto de uso |
|---|---|---|---|
| Delivery | `Delivery.Impediment.Declared` | 1.0.0 | Dependências externas de infraestrutura, acesso negado |
| Diligence | `Diligence.Impediment.Declared` | 1.0.0 | Acesso a sistemas externos, pendências de terceiros |
| Assessment | `Assessment.Impediment.Declared` | 1.0.0 | Acesso a Timelines, indisponibilidade de sistemas de análise |

**Verificação dos critérios de promoção:**

| Critério | Satisfeito? | Evidência |
|---|---|---|
| CRT-01 | **Sim** | Uso ativo em 3 Journeys |
| CRT-02 | **Sim** | Semântica idêntica: "impedimento externo declarado, Work Item BLOCKED"; o contexto varia por Journey mas o fenômeno operacional é o mesmo |
| CRT-03 | **Sim** | Active desde 1.0.0 em todas as Journeys — sem mudança em alters_state, new_state, ou payload |
| CRT-04 | **Sim** | `Impediment.Declared` é preciso e genérico — "declaração de bloqueio" faz sentido em qualquer Journey |
| CRT-05 | **Sim** | Nenhum tipo equivalente existia no catálogo Shared |

**Histórico de promoção:**

| Data | Evento | Referência |
|---|---|---|
| 2026-07-24 | Identificado como candidato | [Cross-Journey Analysis](../../documentation-review-cross-journey-event-analysis.md) |
| 2026-07-25 | Confirmado pela terceira Journey | [Assessment Event Catalog](../../documentation-review-assessment-event-catalog.md) |
| 2026-07-25 | Promovido a Shared Type | Este documento v1.0.0 |

---

## 5. Pending Promotion

---

### 5.1 Impediment.Resolved

| Campo | Valor |
|---|---|
| **name** | `Impediment.Resolved` |
| **namespace** | `Shared` (pendente) |
| **category** | Blocking |
| **alters_state** | `false` |
| **new_state** | — (Consumer usa Lookback: `preBlockedState`) |
| **producer_subtypes** | `[Human]` |
| **lifecycle_status** | **Proposed** |
| **introduced_in** | — (pendente aprovação) |
| **is_shared** | pendente |
| **promotion_origin** | `Delivery.Impediment.Resolved` (simplif.) · `Diligence.Impediment.Resolved` · `Assessment.Impediment.Resolved` |

**Definição canônica proposta:**
O impedimento externo foi resolvido e o Work Item pode retomar o trabalho. O estado de
retorno não está hardcoded no tipo — o Consumer usa o mecanismo de Lookback (`preBlockedState`)
definido em `timeline.md` para determinar o estado anterior ao BLOCKED. Esta definição
reflete o padrão canônico do OEM: `Impediment.Resolved` nunca deve assumir um estado
de retorno fixo, pois o impedimento pode ter sido declarado em qualquer fase do ciclo.

**Precondições canônicas:**
- O Work Item está no estado BLOCKED
- O impedimento declarado em `Impediment.Declared` foi resolvido

**Pós-condições canônicas:**
- `alters_state = false` — o Derived State não é alterado diretamente por este evento
- O Consumer usa `preBlockedState(timeline, resolved_position)` para determinar o estado de retorno
- A resolução do impedimento está registrada na Timeline

**Payload mínimo proposto:**

| Campo | Tipo | Obrigatoriedade | Descrição |
|---|---|---|---|
| `resolution_description` | string | Obrigatório | Descrição de como o impedimento foi resolvido |

**Verificação dos critérios de promoção:**

| Critério | Satisfeito? | Status |
|---|---|---|
| CRT-01 | **Sim** | Uso ativo em 3 Journeys (Delivery, Diligence, Assessment) |
| CRT-02 | **Parcialmente** | **BLOQUEANTE:** Semântica idêntica nas 3 Journeys. Porém, implementação técnica diverge: Delivery v1 usa `alters_state=true, new_state=HACKING` (simplificação MVP documentada); Diligence e Assessment usam `alters_state=false` com Lookback (padrão canônico). O `alters_state` conflitante impede a promoção — o Shared Type define `alters_state=false` como canônico, mas o catálogo Delivery v1 declara `true`. Um Consumer lendo a Timeline da Delivery encontraria inconsistência. |
| CRT-03 | **Sim** | Active desde 1.0.0 em todas as Journeys sem mudança na semântica |
| CRT-04 | **Sim** | `Impediment.Resolved` é preciso e genérico |
| CRT-05 | **Sim** | Nenhum tipo equivalente no catálogo Shared |

**Condição de desbloqueio:**
A promoção pode ser completada quando:

1. O catálogo **Delivery v2** atualizar `Impediment.Resolved` para `alters_state=false` (Lookback)
2. A verificação confirmar que nenhuma Timeline de Delivery existente contém dependências
   hardcoded no `new_state=HACKING` de `Impediment.Resolved`
3. O CRT-02 for reavaliado e confirmado como satisfeito

**Histórico:**

| Data | Evento | Referência |
|---|---|---|
| 2026-07-24 | Identificado como candidato com confiança Média | [Cross-Journey Analysis](../../documentation-review-cross-journey-event-analysis.md) |
| 2026-07-25 | Confirmado pela Assessment (alters_state=false) — confiança elevada para Alta | [Assessment Event Catalog](../../documentation-review-assessment-event-catalog.md) |
| 2026-07-25 | Status Proposed registrado — bloqueado por Delivery v2 | Este documento v1.0.0 |

---

## 6. Registro de candidatos rejeitados

Nenhum candidato foi formalmente rejeitado até esta versão.

Candidatos analisados e descartados (não são candidatos a Shared Type):

| Tipo analisado | Razão do descarte |
|---|---|
| `Promote.Approved` | Colisão de naming — Delivery e Diligence usam o nome para semânticas diferentes (deploy em produção vs. promoção de readiness). CRT-02 não satisfeito. |
| `Promote.Rejected` | Colisão de naming + alters_state conflitante. CRT-02 não satisfeito. |
| `Promote.Completed` | Colisão de naming + new_state incompatível (DONE vs. PROMOTED). CRT-02 não satisfeito. |

Referência da análise: [Cross-Journey Event Analysis](../../documentation-review-cross-journey-event-analysis.md) seção 4.

---

## 7. Como usar um Shared Type em uma nova Journey

Para uma Journey nova que precise de `Gate.Passed`, `Gate.Failed`, ou `Impediment.Declared`:

**No catálogo da Journey:**
```
### Gate.Passed

| Campo | Valor |
|---|---|
| name        | Gate.Passed                                      |
| namespace   | Shared                                           |
| category    | Gate                                             |
| alters_state| false                                            |
| lifecycle_status | Active                                      |
| is_shared   | true                                             |

Definição: ver prodops/framework/events/shared-types.md

payload_shape (extensão Journey-specific):
- gate_name   (herdado do Shared — obrigatório)
- duration_ms (herdado do Shared — obrigatório)
- [campos adicionais específicos da Journey, se necessário]
```

A Journey referencia o Shared Type sem redefini-lo. Campos adicionais no payload
são permitidos desde que não conflitem com os campos mínimos do Shared Type.

---

## Referências

- [Event Type Schema](event-type-schema.md)
- [Lifecycle OEM](lifecycle.md)
- [Taxonomy OEM](taxonomy.md)
- [Timeline OEM](timeline.md)
- [Cross-Journey Event Analysis](../../documentation-review-cross-journey-event-analysis.md)
- [Delivery Event Catalog](../journeys/delivery/events/catalog.md)
- [Diligence Event Catalog](../journeys/diligence/events/catalog.md)
- [Assessment Event Catalog](../journeys/assessment/events/catalog.md)
