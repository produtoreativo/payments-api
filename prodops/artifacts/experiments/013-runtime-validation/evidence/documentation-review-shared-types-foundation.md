# Relatório — Shared Types Foundation
# ProdOps Framework — Primeiro catálogo de Shared Types do OEM

> **Data:** 2026-07-25
> **Tipo:** Formalização do primeiro catálogo de Shared Types
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/shared-types.md`

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Shared Types promovidos (Active) | 3 |
| Shared Types pendentes (Proposed) | 1 |
| Shared Types rejeitados | 0 (3 descartados como não-candidatos) |
| Journeys que confirmam os 4 candidatos | 3 (Delivery, Diligence, Assessment) |
| CRT violado que bloqueia promoção de Impediment.Resolved | CRT-02 (divergência técnica em alters_state) |
| Catálogos de Journey alterados | 0 |
| Decisões arquiteturais anteriores alteradas | 0 |
| Modelo de governança definido | Sim |

---

## 2. Shared Types promovidos

### 2.1 Gate.Passed — Active

**Evidência de reutilização:**

| Journey | Tipo origin | alters_state | Payload | Semântica |
|---|---|---|---|---|
| Delivery | Delivery.Gate.Passed | false | gate_name, duration_ms | Gate automatizado passou |
| Diligence | Diligence.Gate.Passed | false | gate_name, duration_ms | Gate automatizado passou |
| Assessment | Assessment.Gate.Passed | false | gate_name, duration_ms | Gate automatizado passou |

**Verificação CRT:**

| CRT | Status | Detalhe |
|---|---|---|
| CRT-01 | ✓ | 3 Journeys com uso ativo |
| CRT-02 | ✓ | Semântica, precondições, pós-condições e payload idênticos nas 3 Journeys |
| CRT-03 | ✓ | Active em todas as Journeys desde v1.0.0 sem mudança |
| CRT-04 | ✓ | "Gate automatizado passou" — preciso e auto-descritivo sem contexto de Journey |
| CRT-05 | ✓ | Catálogo Shared estava vazio antes desta promoção |

**Decisão:** Promovido. Todos os 5 CRTs satisfeitos com evidência documentada em três Journeys.

---

### 2.2 Gate.Failed — Active

**Evidência de reutilização:**

| Journey | Tipo origin | alters_state | Payload | Semântica |
|---|---|---|---|---|
| Delivery | Delivery.Gate.Failed | false | gate_name, reason, duration_ms | Gate automatizado falhou |
| Diligence | Diligence.Gate.Failed | false | gate_name, reason, duration_ms | Gate automatizado falhou |
| Assessment | Assessment.Gate.Failed | false | gate_name, reason, duration_ms | Gate automatizado falhou |

**Verificação CRT:** Todos satisfeitos — idêntico ao Gate.Passed.

**Nota sobre comportamento pós-falha:** a ação corretiva após Gate.Failed varia por Journey
(Rework.Declared em Delivery, avaliação de rejeição em Diligence e Assessment). Esta variação
é responsabilidade do Producer — não altera a semântica do tipo, que é "gate falhou". CRT-02 satisfeito.

**Decisão:** Promovido. Par natural e complemento de Gate.Passed — promoção simultânea é a decisão correta.

---

### 2.3 Impediment.Declared — Active

**Evidência de reutilização:**

| Journey | Tipo origin | alters_state | new_state | Payload | Semântica |
|---|---|---|---|---|---|
| Delivery | Delivery.Impediment.Declared | true | BLOCKED | impediment_description, blocking_since | Bloqueio externo declarado |
| Diligence | Diligence.Impediment.Declared | true | BLOCKED | impediment_description, blocking_since | Bloqueio externo declarado |
| Assessment | Assessment.Impediment.Declared | true | BLOCKED | impediment_description, blocking_since | Bloqueio externo declarado |

**Verificação CRT:** Todos satisfeitos. `alters_state=true, new_state=BLOCKED` é idêntico nas 3 Journeys — sem nenhuma variação técnica ou semântica.

**Decisão:** Promovido. O tipo mais fortemente equivalente de todos — zero variação técnica ou semântica nas três implementações.

---

## 3. Shared Types pendentes

### 3.1 Impediment.Resolved — Proposed

**Evidência de reutilização:**

| Journey | Tipo origin | alters_state | new_state | Semântica |
|---|---|---|---|---|
| Delivery v1 | Delivery.Impediment.Resolved | **true** | HACKING (hardcoded) | Impedimento resolvido |
| Diligence | Diligence.Impediment.Resolved | **false** | — (Lookback) | Impedimento resolvido |
| Assessment | Assessment.Impediment.Resolved | **false** | — (Lookback) | Impedimento resolvido |

**Verificação CRT:**

| CRT | Status | Detalhe |
|---|---|---|
| CRT-01 | ✓ | 3 Journeys com uso ativo |
| CRT-02 | **⚠ Parcial** | Semântica idêntica. Implementação técnica diverge: Delivery usa `alters_state=true` (simplificação MVP); Diligence e Assessment usam `alters_state=false` com Lookback (padrão canônico) |
| CRT-03 | ✓ | Active desde v1.0.0 em todas as Journeys |
| CRT-04 | ✓ | "Impedimento resolvido" — preciso e genérico |
| CRT-05 | ✓ | Nenhum equivalente no catálogo Shared |

**Por que CRT-02 é bloqueante:**

O `alters_state` conflitante cria um problema arquitetural real. O Shared Type define o
padrão canônico como `alters_state=false` (Lookback). O catálogo Delivery v1 declara
`alters_state=true, new_state=HACKING`. Se promovido agora, um Consumer que lê ambos
os catálogos encontraria:
- Shared Type: `Impediment.Resolved.alters_state = false`
- Delivery Catalog: `Impediment.Resolved.alters_state = true`

Esta inconsistência quebra a garantia de que um Shared Type possui uma única definição
canônica. A promoção só pode ocorrer quando a Delivery convergir para `alters_state=false`.

**Condição de desbloqueio:**

1. Delivery v2 atualiza `Impediment.Resolved` → `alters_state=false` (Lookback)
2. Delivery v2 confirma que nenhuma dependência em `new_state=HACKING` existe nos Consumers
3. Revisão de CRT-02 confirma convergência técnica
4. Promoção formalizada em shared-types.md v1.1.0

**Prioridade:** Alta. Dois de três catálogos já implementam o padrão correto. A Delivery v2 é o único trabalho pendente.

---

## 4. Candidatos descartados

### 4.1 Promote.Approved — descartado (CRT-02 não satisfeito)

| Delivery | Diligence |
|---|---|
| Autoriza deploy em produção (VALIDATING → PROMOTING) | Autoriza promoção de readiness (ATTACHED → PROMOTING) |

**Decisão de descarte:** colisão de naming — o mesmo token representa objetos de negócio
diferentes em cada Journey. Um Consumer genérico não consegue distinguir os contextos.
Promover criaria um Shared Type semanticamente ambíguo. CRT-02 falhou.

### 4.2 Promote.Rejected — descartado (CRT-02 + alters_state conflitante)

| Delivery | Diligence |
|---|---|
| alters_state=true, new_state=VALIDATING | alters_state=false (permanece ATTACHED) |

**Decisão de descarte:** além da colisão de naming, o comportamento técnico diverge. Dois
CRTs falham: CRT-02 (semântica diferente) e CRT-03 poderia ser questionado por instabilidade
de contrato.

### 4.3 Promote.Completed — descartado (CRT-02 não satisfeito)

| Delivery | Diligence |
|---|---|
| new_state=DONE (estado terminal) | new_state=PROMOTED (não-terminal) |

**Decisão de descarte:** estados finais incompatíveis — DONE indica terminalidade em Delivery;
PROMOTED é um passo intermediário em Diligence. CRT-02 falhou.

---

## 5. Impactos nas Journeys

### 5.1 O que muda imediatamente

**Nada nos catálogos existentes.** Os catálogos MVP de Delivery, Diligence e Assessment
não foram alterados. O `shared-types.md` define a referência canônica — os catálogos Journey
atuais continuam válidos.

### 5.2 O que deve mudar nos catálogos v2

A Fase 6 do processo de promoção (`lifecycle.md` seção 4.1) exige que as Journeys depreciem
seus tipos Journey de origem após a promoção do Shared Type. Isso é trabalho dos catálogos v2:

| Journey | Ação pendente no catálogo v2 |
|---|---|
| Delivery | Marcar `Gate.Passed`, `Gate.Failed`, `Impediment.Declared` como Deprecated com referência ao Shared Type |
| Delivery | Atualizar `Impediment.Resolved` para `alters_state=false` (pré-requisito para promoção) |
| Diligence | Marcar `Gate.Passed`, `Gate.Failed`, `Impediment.Declared` como Deprecated com referência ao Shared Type |
| Assessment | Marcar `Gate.Passed`, `Gate.Failed`, `Impediment.Declared` como Deprecated com referência ao Shared Type |

**Por que não foi feito agora:** a restrição explícita do Prompt 12 é "Não alterar: OEM, Delivery, Diligence, Assessment." A deprecação dos tipos Journey é trabalho do próximo ciclo.

### 5.3 Compatibilidade retroativa garantida

A promoção dos Shared Types não quebra nenhuma Timeline existente:

- Timelines históricas com `Delivery.Gate.Passed`, `Diligence.Gate.Passed`, `Assessment.Gate.Passed` permanecem válidas
- Event Consumers devem continuar reconhecendo os tipos Journey deprecated para leitura histórica
- A promoção não é retroativa — não converte eventos passados

---

## 6. Modelo de governança definido

O `shared-types.md` seção 3 define a governança completa:

| Aspecto | Decisão |
|---|---|
| **Quem pode propor** | Qualquer Journey owner ou contribuidor do Framework com evidência de uso em ≥2 Journeys |
| **Formato da proposta** | Documento `documentation-review-[tipo]-shared-promotion.md` com análise dos 5 CRTs |
| **Quem aprova** | Exclusivamente o Framework (mantenedor do OEM) |
| **Critério de aprovação** | Todos os 5 CRTs satisfeitos + ausência de conflito identificado pelas Journeys consultadas |
| **Quando depreciar** | Substituição por tipo mais preciso confirmada pelas Journeys; ou uso zero por ≥2 ciclos completos; ou refatoração do OEM |
| **O que não justifica depreciação** | Nome poderia ser melhor; baixo uso; desejo de consolidação sem substituto |
| **Migração de Journey** | 3 passos: (1) Deprecar tipo Journey com referência ao Shared; (2) Atualizar Skills; (3) Preservar histórico |

---

## 7. Confirmação de invariantes arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| OEM (README, Ontology, Taxonomy, Lifecycle, Schemas, Timeline) | Não alterado |
| Delivery Event Catalog | Não alterado |
| Diligence Event Catalog | Não alterado |
| Assessment Event Catalog | Não alterado |
| Cross-Journey Event Analysis | Não alterado |
| Assessment Foundation (README) | Não alterado |
| Nenhum novo Event Type criado | Confirmado |
| Nenhuma nova Event Category criada | Confirmado |
| Nenhum tipo renomeado | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 8. Arquivos criados e alterados

### Criados

| Arquivo | Conteúdo |
|---|---|
| `prodops/framework/events/shared-types.md` | Catálogo canônico de Shared Types v1.0.0 — 3 Active, 1 Proposed, governança |
| `prodops/documentation-review-shared-types-foundation.md` | Este documento |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 9. Estado do OEM após esta entrega

O OEM está agora formalmente completo em sua estrutura canônica de nível Framework:

| Documento | Status |
|---|---|
| `events/README.md` | Fundação do OEM |
| `events/ontology.md` | Ontologia canônica |
| `events/taxonomy.md` | Taxonomia canônica |
| `events/lifecycle.md` | Modelo de ciclo de vida |
| `events/event-type-schema.md` | Schema de Event Type |
| `events/event-instance-schema.md` | Schema de Event Instance |
| `events/timeline.md` | Modelo de Timeline |
| **`events/shared-types.md`** | **Catálogo de Shared Types — criado nesta entrega** |
| Journey catalogs | Delivery, Diligence, Assessment (MVP) |

O OEM atingiu o nível de maturidade necessário para ser utilizado como referência por
novas Journeys (Discovery, Operation) sem extensões adicionais.

---

## 10. Próximos Passos

| Ação | Prioridade | Raciocínio |
|---|---|---|
| Delivery v2: atualizar Impediment.Resolved → alters_state=false | **Alta** | Desbloqueia promoção de Impediment.Resolved para Active |
| Catálogos v2 (Delivery, Diligence, Assessment): deprecar tipos Journey de Gate.* e Impediment.Declared | Alta | Fase 6 do processo de promoção — catálogos devem referenciar Shared Types |
| shared-types.md v1.1.0: promover Impediment.Resolved após Delivery v2 | Alta | Conclusão do processo iniciado nesta entrega |
| Propor revisão de Taxonomy: category Observation | Média | Atende lacuna identificada no catálogo Assessment |
| Iniciar catálogos para Discovery e/ou Operation | Baixa | Quarta e quinta implementações de referência do OEM |
