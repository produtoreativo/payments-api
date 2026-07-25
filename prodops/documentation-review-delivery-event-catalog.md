# Relatório — Delivery Event Catalog (MVP)
# ProdOps Framework — Jornada Delivery

> **Data:** 2026-07-24
> **Tipo:** Implementação de referência do OEM — catálogo de Journey
> **Status:** Concluído
> **Escopo:** `prodops/framework/journeys/delivery/events/`

---

## 1. Executive Summary

O catálogo MVP da Jornada Delivery foi criado como primeira implementação de referência
do Operational Event Model. O catálogo cobre o fluxo completo da Journey — CI Sync e CI
Async — com eventos transversais de Blocking e Rework.

| Item | Resultado |
|---|---|
| Event Types criados | 17 |
| Event Categories utilizadas | 5 de 8 |
| Fases cobertas | 7 de 7 (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) |
| Estados do modelo | 9 (BOOTSTRAPPING a DONE + BLOCKED) |
| Candidatos a Shared Type | 6 |
| Limitações documentadas intencionalmente | 5 |
| Documentos criados | 3 (README, catalog, este relatório) |
| Documentos alterados | 0 |

---

## 2. Event Types criados — quantidade e distribuição

### 2.1 Por Event Category

| Category | Quantidade | Event Types |
|---|---|---|
| **Phase Lifecycle** | 7 | Bootstrap.Started, Bootstrap.Completed, Hack.Completed, Sync.Completed, Finish.Completed, Ship.Completed, Promote.Completed |
| **Gate** | 2 | Gate.Passed, Gate.Failed |
| **Human Decision** | 4 | Review.Approved, Review.ChangesRequested, Promote.Approved, Promote.Rejected |
| **Blocking** | 2 | Impediment.Declared, Impediment.Resolved |
| **Rework** | 2 | Rework.Declared, Rework.Completed |
| **Total** | **17** | — |

### 2.2 Por impacto em Derived State

| Tipo | Quantidade | Event Types |
|---|---|---|
| `alters_state = true` | 11 | Bootstrap.Started, Bootstrap.Completed, Hack.Completed, Sync.Completed, Finish.Completed, Ship.Completed, Promote.Completed, Promote.Approved, Promote.Rejected, Impediment.Declared, Impediment.Resolved, Rework.Declared, Rework.Completed |
| `alters_state = false` | 4 | Gate.Passed, Gate.Failed, Review.Approved, Review.ChangesRequested |

*Nota: 11 + 4 = 15. A divergência se explica porque Rework.Declared e Rework.Completed aparecem na primeira coluna mas não foram listados individualmente — total correto é 13 tipos com alters_state=true e 4 com false.*

Corrigindo:

| Tipo | Quantidade |
|---|---|
| `alters_state = true` | 13 |
| `alters_state = false` | 4 |
| **Total** | **17** |

### 2.3 Por subtipo de Producer autorizado

| Producer | Event Types que permitem |
|---|---|
| **Human** | Bootstrap.Started, Bootstrap.Completed, Hack.Completed, Finish.Completed, Review.Approved, Review.ChangesRequested, Promote.Approved, Promote.Rejected, Impediment.Declared, Impediment.Resolved, Rework.Declared, Rework.Completed |
| **System** | Gate.Passed, Gate.Failed, Sync.Completed, Ship.Completed, Promote.Completed |
| **Agent** | Bootstrap.Started, Bootstrap.Completed, Hack.Completed, Finish.Completed, Gate.Passed, Gate.Failed, Impediment.Declared, Rework.Declared, Rework.Completed |

Tipos onde Human é o único produtor autorizado: Review.Approved, Review.ChangesRequested,
Promote.Approved, Promote.Rejected, Impediment.Resolved — todos eventos de decisão ou
responsabilidade explicitamente humana.

---

## 3. Cobertura da Jornada

### 3.1 Cobertura por Phase

| Phase | Events que abrem | Events que fecham | Covered? |
|---|---|---|---|
| Bootstrap | Bootstrap.Started | Bootstrap.Completed | ✓ |
| Hack | Bootstrap.Completed (implícito) | Hack.Completed | ✓ |
| Sync | Hack.Completed (implícito) | Sync.Completed | ✓ |
| Finish | Sync.Completed (implícito) | Finish.Completed | ✓ |
| Ship | Finish.Completed (implícito) | Ship.Completed | ✓ |
| Validate | Ship.Completed (implícito) | Promote.Approved (decisão) | ✓ (parcial) |
| Promote | Promote.Approved | Promote.Completed | ✓ |

### 3.2 Cobertura por modelo de estado

Todos os 9 estados do modelo estão cobertos:

| Estado | Event Type que transita para ele | Event Type que sai dele |
|---|---|---|
| BOOTSTRAPPING | Bootstrap.Started | Bootstrap.Completed |
| HACKING | Bootstrap.Completed, Impediment.Resolved, Rework.Declared | Hack.Completed |
| SYNCING | Hack.Completed, Rework.Completed | Sync.Completed |
| FINISHING | Sync.Completed | Finish.Completed |
| SHIPPING | Finish.Completed | Ship.Completed |
| VALIDATING | Ship.Completed, Promote.Rejected | Promote.Approved |
| PROMOTING | Promote.Approved | Promote.Completed |
| DONE | Promote.Completed | — (estado final) |
| BLOCKED | Impediment.Declared | Impediment.Resolved |

O modelo de estados é completo e sem estados órfãos.

---

## 4. Candidatos a Shared Types

Os seguintes tipos foram identificados como candidatos a promoção para o catálogo de Shared
Types. A promoção deve seguir o processo definido em `lifecycle.md` (seção 4) com
satisfação dos critérios CRT-01 a CRT-05.

### Candidatos primários (alta generalidade semântica)

| Event Type | Justificativa |
|---|---|
| **Gate.Passed** | Gates de qualidade existem em qualquer Journey que implemente verificações automatizadas. A semântica "um gate passou" é completamente independente de Delivery. |
| **Gate.Failed** | Par complementar de Gate.Passed — mesma justificativa. |

### Candidatos secundários (generalidade verificável com outras Journeys)

| Event Type | Justificativa |
|---|---|
| **Impediment.Declared** | Bloqueios por impedimentos externos são transversais a qualquer Journey que tenha Work Items que podem ser suspensos. Diligence, Assessment, e potencialmente Product Lifecycle precisariam do mesmo conceito. |
| **Impediment.Resolved** | Par complementar de Impediment.Declared. |
| **Rework.Declared** | O conceito de "retorno ao desenvolvimento por qualidade insuficiente" pode ocorrer em outras Journeys. |
| **Rework.Completed** | Par complementar de Rework.Declared. |

### Critérios que impedem promoção imediata

Todos os 6 candidatos não satisfazem CRT-01 (reutilização ativa comprovada) neste momento
— não existe evidência de que outra Journey requereria esses tipos com semântica equivalente.
A promoção deve ser iniciada quando:

1. Outra Journey (Discovery, Assessment, ou Diligence como Journey) identificar a mesma
   necessidade
2. A semântica cross-Journey for verificada (CRT-02)
3. Os tipos tiverem pelo menos um ciclo de Journey de estabilidade (CRT-03)

---

## 5. Lacunas identificadas

### 5.1 Lacunas intencionais do MVP

Estas lacunas foram documentadas como limitações conscientes — o MVP prioriza cobertura
mínima viável do fluxo completo sobre exaustividade.

| Lacuna | Impacto | Candidato ao catálogo v2 |
|---|---|---|
| **Hack.Started explícito** | O início do Hack não é registrado explicitamente — é implícito em Bootstrap.Completed | `Hack.Started` (Phase Lifecycle, alters_state=false) |
| **Sync.Started explícito** | O início do Sync não é registrado explicitamente | `Sync.Started` (Phase Lifecycle, alters_state=false) |
| **Validate.Completed** | O fim da validação não é registrado separadamente de Promote.Approved | `Validate.Completed` (Phase Lifecycle, alters_state=true, new_state=PROMOTING?) |
| **Pipeline.Failed** | Falhas de infraestrutura (deploy, CI) não são rastreadas | `Pipeline.Failed` (System, alters_state=false) |
| **Pipeline.Completed** | Execuções bem-sucedidas de pipeline não são registradas | `Pipeline.Completed` (System, alters_state=false) |
| **Waiting.Declared/Resolved** | Dependências externas agendadas são agregadas em Impediment | `Waiting.Declared`, `Waiting.Resolved` (Blocking) |

### 5.2 Limitação arquitetural: Impediment.Resolved → HACKING

A maior limitação do MVP é que `Impediment.Resolved` retorna sempre para o estado HACKING,
independentemente do estado em que o Work Item estava quando o impedimento foi declarado.

**O problema:** se o Work Item estava em FINISHING quando Impediment.Declared foi emitido,
após Impediment.Resolved ele vai para HACKING — retroagindo duas fases sem evidência de
que isso é necessário.

**O caminho correto (v2):** `Impediment.Resolved` deveria ter `alters_state = false` e o
Consumer deveria reconstruir o estado pré-BLOCKED buscando o último evento `alters_state = true`
com `new_state ≠ BLOCKED` na Timeline. Isso exige que o Consumer implemente lógica de
"lookback" na Timeline.

A simplificação foi mantida no MVP para não introduzir dependências de implementação no
Schema conceitual.

### 5.3 Lacunas não planejadas para v2

Por restrição do escopo declarado no Prompt 6, os seguintes tipos não serão adicionados
mesmo em v2 deste catálogo:

- Eventos de Diligence (fora de escopo — catálogo próprio)
- Eventos de Assessment (fora de escopo — catálogo próprio)
- Eventos de Discovery (fora de escopo — Journey diferente)

---

## 6. Validação do OEM — o catálogo como caso de teste

O catálogo MVP serve como primeiro caso de teste do Event Type Schema. As validações
VAL-01 a VAL-12 foram aplicadas a cada tipo:

| Validação | Status nos 17 tipos |
|---|---|
| VAL-01 (unicidade de name) | ✓ — nenhum nome duplicado |
| VAL-02 (convenção de nome) | ✓ — todos seguem `Subject.Action` PascalCase |
| VAL-03 (category válida) | ✓ — todas as 5 categories usadas são das 8 canônicas |
| VAL-04 (alters_state declarado) | ✓ — todos os 17 tipos declaram explicitamente |
| VAL-05 (new_state quando alters_state=true) | ✓ — todos os 13 tipos com alters_state=true declaram new_state |
| VAL-06 (category × alters_state) | ✓ — nenhum tipo Correction com alters_state=true |
| VAL-07 (lifecycle_status válido) | ✓ — todos `Active` |
| VAL-08 (campos de deprecação) | ✓ — nenhum tipo Deprecated no MVP |
| VAL-09 (campos de remoção) | ✓ — nenhum tipo Removed no MVP |
| VAL-10 (producer_subtypes não vazio) | ✓ — todos os 17 tipos têm ao menos um subtipo |
| VAL-11 (somente Active pode ser emitido) | ✓ — todos os 17 tipos estão Active |
| VAL-12 (payload_shape imutável) | ✓ — declaração de payload_shape presente e estável |

**Resultado:** todos os 17 tipos passam em todas as 12 validações do Event Type Schema.
O Schema está funcionando como contrato efetivo.

---

## 7. Observações sobre a convenção de nomenclatura

A Taxonomia (REG-01 a REG-10) foi satisfeita por todos os tipos. Observações específicas:

**Pares complementares encontrados no catálogo:**

| Par | Category | Justificativa |
|---|---|---|
| Bootstrap.Started / Bootstrap.Completed | Phase Lifecycle | Abertura e fechamento explícitos da Phase |
| Gate.Passed / Gate.Failed | Gate | Resultado binário de verificação |
| Review.Approved / Review.ChangesRequested | Human Decision | Decisões complementares de code review |
| Promote.Approved / Promote.Rejected | Human Decision | Decisões complementares de promoção |
| Impediment.Declared / Impediment.Resolved | Blocking | Par de evento transversal |
| Rework.Declared / Rework.Completed | Rework | Par de ciclo de retorno |

Dos 17 tipos, 12 formam 6 pares complementares — o que reflete a natureza do fluxo
operacional, que tem eventos de abertura e fechamento para cada acontecimento relevante.

**Tipos sem par explícito:**

| Tipo | Razão |
|---|---|
| Hack.Completed | O início do Hack é implícito (Bootstrap.Completed → HACKING) |
| Sync.Completed | O início do Sync é implícito (Hack.Completed → SYNCING) |
| Finish.Completed | Idem — sem Finish.Started no MVP |
| Ship.Completed | Idem — sem Ship.Started no MVP |
| Promote.Completed | Tem par parcial em Promote.Approved — mas não há Promote.Failed no MVP |

---

## 8. Impacto nas métricas DORA

Com os 17 tipos do MVP é possível calcular as 4 métricas DORA básicas:

| Métrica DORA | Cálculo com tipos do MVP |
|---|---|
| **Deployment Frequency** | Contagem de Promote.Completed por período |
| **Lead Time for Changes** | `Promote.Completed.timestamp - Bootstrap.Started.timestamp` |
| **Change Failure Rate** | `count(Promote.Rejected) / count(Promote.Approved + Promote.Rejected)` |
| **Time to Restore** | Não calculável com MVP — requer eventos de Incident (fora de escopo) |

Métricas adicionais calculáveis com o MVP:

| Métrica | Cálculo |
|---|---|
| **Time per Phase** | Diferença de timestamp entre eventos Phase.Started implícito e Phase.Completed |
| **Rework Rate** | `count(Rework.Declared) / count(Work Items)` |
| **Gate Failure Rate** | `count(Gate.Failed) / count(Gate.Passed + Gate.Failed)` |
| **Block Time** | `Impediment.Resolved.timestamp - Impediment.Declared.timestamp` |
| **Review Cycle Count** | Contagem de pares Review.ChangesRequested + Review.Approved por Work Item |
| **Reject Rate (Promote)** | `count(Promote.Rejected) / count(Promote.Approved + Promote.Rejected)` |

---

## 9. Próximos Passos

| Documento | Prioridade | Raciocínio |
|---|---|---|
| `events/shared-types.md` | Alta | Gate.Passed, Gate.Failed são prontos para promoção quando uma segunda Journey confirmar necessidade |
| `journeys/delivery/events/catalog.md` v2 | Média | Adicionar tipos System (Pipeline.Failed), Hack.Started, Validate.Completed, Waiting.Declared/Resolved |
| `events/timeline.md` | Média | Formalizar o comportamento do "lookback" para Impediment.Resolved e similares |
| `journeys/diligence/events/catalog.md` | Baixa | Após a v2 do catálogo Delivery estar estável |

---

## 10. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado — fluxos de referência demonstram uso correto |
| Derived State como projeção da Timeline | Preservado — 13 tipos declaram new_state explícito |
| Event Category como catálogo fixo do Framework | Preservado — 5 de 8 categorias usadas; nenhuma nova criada |
| Event Type Schema satisfeito por todos os tipos | Confirmado — 12 VALs aplicadas a todos os 17 tipos |
| Naming convention `Subject.Action` seguida | Confirmado — 17 tipos, sem desvios |
| README.md não alterado | Confirmado |
| ontology.md não alterado | Confirmado |
| taxonomy.md não alterado | Confirmado |
| lifecycle.md não alterado | Confirmado |
| event-type-schema.md não alterado | Confirmado |
| event-instance-schema.md não alterado | Confirmado |
| Shared Types não criados | Confirmado |
| Timeline não criada | Confirmado |
| Event Store não criado | Confirmado |
| Diligence Events não criados | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 11. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/journeys/delivery/events/README.md` | ~130 | Contexto da Journey Delivery no OEM |
| `prodops/framework/journeys/delivery/events/catalog.md` | ~400 | 17 Event Types completos + 3 fluxos de referência |
| `prodops/documentation-review-delivery-event-catalog.md` | Este arquivo | Relatório da implementação de referência |

### Alterados

Nenhum arquivo existente foi alterado.
