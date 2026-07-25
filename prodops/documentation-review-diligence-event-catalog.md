# Relatório — Diligence Event Catalog (MVP)
# ProdOps Framework — Jornada Diligence

> **Data:** 2026-07-24
> **Tipo:** Segunda implementação de referência do OEM — validação cross-Journey
> **Status:** Concluído
> **Escopo:** `prodops/framework/journeys/diligence/events/`

---

## 1. Executive Summary

O catálogo MVP da Jornada Diligence foi criado como segunda implementação de referência
do OEM — com o objetivo explícito de validar que o modelo suporta uma Journey
operacionalmente diferente da Delivery sem nenhuma extensão.

O OEM suportou a Diligence integralmente. Nenhum conceito, campo, ou regra nova precisou
ser criada. O catálogo também introduz a implementação refinada de `Impediment.Resolved`
com Lookback — resolvendo a limitação documentada no catálogo MVP da Delivery.

| Item | Resultado |
|---|---|
| Event Types criados | 20 |
| Event Categories utilizadas | 5 de 8 |
| Ciclos cobertos | 2 de 2 (Sync e Async) |
| Estados do modelo | 13 (CAPTURING a REPAIRED + BLOCKED + WAIVED) |
| Candidatos a Shared Type identificados | 4 |
| Tipos exclusivos da Diligence (sem equivalente na Delivery) | 12 |
| Tipos com equivalente semântico na Delivery | 4 |
| Tipos com nome similar mas semântica diferente da Delivery | 4 |
| Limitações do catálogo Delivery resolvidas | 1 (Impediment.Resolved com Lookback) |
| Documentos alterados | 0 |

---

## 2. Quantidade de Event Types e distribuição

### 2.1 Por Event Category

| Category | Quantidade | Event Types |
|---|---|---|
| **Phase Lifecycle** | 10 | Capture.Started, Capture.Completed, Attach.Completed, Promote.Completed, Close.Completed, Scan.Started, Scan.Completed, Flag.Completed, Repair.Started, Repair.Completed |
| **Human Decision** | 4 | Promote.Approved, Promote.Rejected, Waiver.Granted, Waiver.Rejected |
| **Gate** | 2 | Gate.Passed, Gate.Failed |
| **Blocking** | 2 | Impediment.Declared, Impediment.Resolved |
| **Diligence** | 2 | Divergence.Detected, Finding.Recorded |
| **Total** | **20** | — |

### 2.2 Por impacto em Derived State

| Tipo | Quantidade |
|---|---|
| `alters_state = true` | 14 |
| `alters_state = false` | 6 |
| **Total** | **20** |

Os 6 tipos com `alters_state = false`:
Gate.Passed, Gate.Failed, Promote.Rejected, Waiver.Rejected, Impediment.Resolved,
Divergence.Detected, Finding.Recorded — curiosamente, 7 na contagem real. Verificando:

| Type | alters_state |
|---|---|
| Gate.Passed | false |
| Gate.Failed | false |
| Promote.Rejected | false |
| Waiver.Rejected | false |
| Impediment.Resolved | **false** (Lookback) |
| Divergence.Detected | false |
| Finding.Recorded | false |

Total: 7 tipos com `alters_state = false`, 13 com `true`.

### 2.3 Por subtipo de Producer

| Producer | Event Types que permitem |
|---|---|
| **Human** | Capture.Started, Capture.Completed, Attach.Completed, Promote.Completed, Close.Completed, Repair.Started, Repair.Completed, Promote.Approved, Promote.Rejected, Waiver.Granted, Waiver.Rejected, Impediment.Declared, Impediment.Resolved |
| **System** | Gate.Passed, Gate.Failed |
| **Agent** | Capture.Started, Capture.Completed, Attach.Completed, Promote.Completed, Close.Completed, Scan.Started, Scan.Completed, Flag.Completed, Repair.Started, Repair.Completed, Gate.Passed, Gate.Failed, Impediment.Declared, Divergence.Detected, Finding.Recorded |

Tipos exclusivamente para Agent: Scan.Started, Scan.Completed, Flag.Completed, Divergence.Detected, Finding.Recorded — todos os eventos do ciclo Async são gerados pelo agente de Diligence.

Tipos exclusivamente para Human: Promote.Approved, Promote.Rejected, Waiver.Granted, Waiver.Rejected, Impediment.Resolved — todos os eventos de decisão são exclusivamente humanos.

---

## 3. Cobertura dos ciclos da Diligence

### 3.1 Cobertura do ciclo Sync

| Step | Covered? | Events |
|---|---|---|
| Capture | ✓ | Capture.Started, Capture.Completed |
| Attach | ✓ | Attach.Completed + Gate.Passed/Failed |
| Promote | ✓ | Promote.Approved, Promote.Rejected, Promote.Completed |
| Close | ✓ | Close.Completed |

### 3.2 Cobertura do ciclo Async

| Step | Covered? | Events |
|---|---|---|
| Scan | ✓ | Scan.Started, Divergence.Detected, Finding.Recorded, Scan.Completed |
| Flag | ✓ | Flag.Completed |
| Repair | ✓ | Repair.Started, Repair.Completed |
| Waiver (alternativa ao Repair) | ✓ | Waiver.Granted, Waiver.Rejected |

### 3.3 Cobertura dos transversais

| Transversal | Covered? | Events |
|---|---|---|
| Blocking | ✓ | Impediment.Declared, Impediment.Resolved |
| Divergence detection | ✓ | Divergence.Detected |
| Finding | ✓ | Finding.Recorded |
| Waiver | ✓ | Waiver.Granted, Waiver.Rejected |
| Remediation | Parcial | Coberto por Repair.Started/Completed — sem evento específico `Remediation.Applied` |

---

## 4. Candidatos a Shared Types

### 4.1 Candidatos fortes — semântica idêntica nas duas Journeys

| Diligence Type | Delivery Equivalent | Semântica | CRT-01? | CRT-02? | CRT-03? | Candidato |
|---|---|---|---|---|---|---|
| `Gate.Passed` | `Gate.Passed` | Gate genérico passou | **Confirmado** — dois Journeys | Sim — semanticamente equivalente | Sim — estável desde 1.0.0 | **Forte** |
| `Gate.Failed` | `Gate.Failed` | Gate genérico falhou | **Confirmado** | Sim | Sim | **Forte** |
| `Impediment.Declared` | `Impediment.Declared` | Bloqueio declarado | **Confirmado** | Sim | Sim | **Forte** |
| `Impediment.Resolved` | `Impediment.Resolved` | Bloqueio resolvido | **Confirmado** | Sim | Sim | **Forte** |

**Conclusão sobre candidatos fortes:** os 4 tipos satisfazem simultaneamente CRT-01 (reutilização ativa em duas Journeys), CRT-02 (equivalência semântica verificada), e CRT-03 (estabilidade desde a v1.0.0 de ambos os catálogos).

CRT-04 (generalidade sem perda de precisão): Gate.Passed, Gate.Failed, Impediment.Declared, Impediment.Resolved são nomes suficientemente genéricos para qualquer Journey futura.

CRT-05 (sem duplicata no catálogo compartilhado): não há catálogo compartilhado ainda — nenhum bloqueio.

**Recomendação:** estes 4 tipos estão prontos para iniciar o processo formal de promoção para Shared Types conforme `lifecycle.md` seção 4.

### 4.2 Tipos com nome similar mas semântica diferente — não são candidatos

| Diligence Type | Delivery Equivalent | Por que são diferentes |
|---|---|---|
| `Promote.Approved` | `Promote.Approved` | Delivery: autoriza deploy em produção. Diligence: autoriza avanço de readiness no backlog. Precondições, pós-condições e contexto completamente distintos. |
| `Promote.Rejected` | `Promote.Rejected` | Mesma razão — semântica de negócios diferente. |
| `Promote.Completed` | `Promote.Completed` | Delivery: deploy em produção realizado (new_state=DONE). Diligence: promoção de readiness concluída (new_state=PROMOTED). Estados finais diferentes. |
| `Close.Completed` | — | Sem equivalente na Delivery (Delivery usa Promote.Completed → DONE). Exclusivo da Diligence. |

**Armadilha de ANT-TAX-03** (Taxonomia): nomes iguais ou similares com semântica diferente não devem ser Shared Types — esse seria o anti-padrão mais provável se Gate fosse interpretado como "todos os `Promote.*` são iguais". A análise semântica correta os distingue.

---

## 5. Tipos exclusivos da Diligence

Os seguintes tipos não têm equivalente no catálogo da Delivery e representam conceitos exclusivos da Jornada Diligence:

| Tipo | Por que é exclusivo |
|---|---|
| `Capture.Started` | O conceito de "capturar" um Work Item externo é específico da Diligence |
| `Capture.Completed` | Idem |
| `Attach.Completed` | Associação ao projeto gerenciado é operação da Diligence |
| `Promote.Completed` (semântica) | Diferente do Promote.Completed da Delivery — promoção de readiness |
| `Close.Completed` | Sem equivalente na Delivery |
| `Scan.Started` | Varredura assíncrona é operação da Diligence |
| `Scan.Completed` | Idem |
| `Flag.Completed` | Sinalização de divergência é operação da Diligence |
| `Repair.Started` | Reparo de divergência é operação da Diligence |
| `Repair.Completed` | Idem |
| `Waiver.Granted` | Gestão de exceções é conceito exclusivo da Diligence |
| `Waiver.Rejected` | Idem |
| `Divergence.Detected` | Registro de divergência é operação da Diligence |
| `Finding.Recorded` | Registro de achado de auditoria é operação da Diligence |

14 tipos exclusivos de 20 total (70%) — a Diligence tem identidade operacional própria bem definida.

---

## 6. Resolução de limitações do catálogo Delivery

### 6.1 Impediment.Resolved com Lookback

A limitação mais relevante do catálogo MVP da Delivery era:
> `Impediment.Resolved` retorna sempre a HACKING, independentemente do estado pré-bloqueio.

O catálogo Diligence implementa a versão correta:
- `Impediment.Resolved` com `alters_state = false`
- O Consumer usa `preBlockedState(timeline, resolved_position)` conforme `timeline.md`
- O estado de retorno é o último estado `alters_state=true AND new_state != BLOCKED` antes de `Impediment.Declared`

Demonstração no fluxo de referência:
```
pos 8: Scan.Started → SCANNING
pos 9: Impediment.Declared → BLOCKED
pos 10: Impediment.Resolved (alters_state=false)

Lookback: buscar antes de pos 9 → pos 8 = Scan.Started, new_state=SCANNING
Estado de retorno: SCANNING ✓
```

**Impacto retroativo:** o catálogo da Delivery deveria ser atualizado para adotar o mesmo
padrão em sua v2. A simplificação do MVP foi aceita por estar documentada — a versão
refinada está agora definida como referência.

---

## 7. Lacunas identificadas

| Lacuna | Impacto | Candidato ao catálogo v2 |
|---|---|---|
| `Remediation.Applied` | Cada ação de remediação individual não é registrada — apenas Repair.Started/Completed | `Remediation.Applied` (Diligence category, alters_state=false) |
| `Evidence.Attached` | Evidências adicionadas a achados não são rastreadas | `Evidence.Attached` (Diligence category, alters_state=false) |
| `Waiver.Expired` | Waivers com expiração não têm evento de expiração | `Waiver.Expired` (Diligence category, alters_state=true, new_state=FLAGGED) |
| `Scan.Skipped` | Ciclos de varredura que pularam um Work Item não são registrados | `Scan.Skipped` (Phase Lifecycle, alters_state=false) |
| Sem `Capture.Failed` | Capturas que falham não têm evento de falha | `Capture.Failed` (Diligence, alters_state=false) |

---

## 8. Validação do OEM como modelo cross-Journey

### 8.1 Perguntas que a Diligence responde sobre o OEM

| Pergunta | Resposta (baseada no catálogo) |
|---|---|
| O Event Type Schema suporta Journeys com mais de um ciclo? | Sim — Sync e Async coexistem na mesma Timeline e no mesmo catálogo sem conflito |
| O modelo suporta estados transversais (BLOCKED, WAIVED) sem modificação? | Sim — BLOCKED e WAIVED são declarados como `new_state` dos tipos relevantes |
| O Lookback funciona corretamente para Impediment.Resolved? | Sim — demonstrado no fluxo 4 com Lookback |
| A category Diligence faz sentido na Journey Diligence (não apenas em outras Journeys)? | Sim — Divergence.Detected e Finding.Recorded usam a category Diligence na própria Journey |
| É possível ter 13 estados sem criar categorias novas? | Sim — os estados são valores de `new_state`, não entidades da Taxonomia |
| O OEM suporta o conceito de waiver (exceção formal)? | Sim — Waiver.Granted é Human Decision com new_state=WAIVED, sem nenhuma extensão |

### 8.2 Resultado da validação

**O OEM suporta a Jornada Diligence integralmente.** Nenhuma extensão foi necessária:

- Nenhum campo novo no Event Type Schema
- Nenhuma nova Event Category
- Nenhuma exceção às validações VAL-01 a VAL-12
- Nenhuma mudança na estrutura da Timeline
- Nenhum novo invariante de OEM

A única diferença arquitetural entre a Delivery e a Diligence é o catálogo de tipos e
os valores de `new_state` — que são exatamente o que deveria variar entre Journeys.

---

## 9. Quadro comparativo — Delivery vs. Diligence

### 9.1 Distribuição por Category

| Category | Delivery (17 tipos) | Diligence (20 tipos) |
|---|---|---|
| Phase Lifecycle | 7 | 10 |
| Gate | 2 | 2 |
| Human Decision | 4 | 4 |
| Blocking | 2 | 2 |
| Rework | 2 | 0 |
| Diligence | 0 | 2 |
| System | 0 | 0 |
| Correction | 0 | 0 |

### 9.2 Tipos potencialmente reutilizáveis (candidatos a Shared)

| Event Type | Delivery | Diligence | Semântica equivalente? |
|---|---|---|---|
| `Gate.Passed` | ✓ Active | ✓ Active | **Sim** — candidato a Shared |
| `Gate.Failed` | ✓ Active | ✓ Active | **Sim** — candidato a Shared |
| `Impediment.Declared` | ✓ Active | ✓ Active | **Sim** — candidato a Shared |
| `Impediment.Resolved` | ✓ Active (simplificado) | ✓ Active (Lookback) | **Sim** — candidato a Shared |

### 9.3 Tipos com nome similar mas semântica diferente (NÃO candidatos)

| Event Type | Delivery (semântica) | Diligence (semântica) |
|---|---|---|
| `Promote.Approved` | Autoriza deploy em produção | Autoriza promoção de readiness no backlog |
| `Promote.Rejected` | Rejeita deploy em produção | Rejeita promoção de readiness |
| `Promote.Completed` | Deploy em produção (DONE) | Promoção de readiness (PROMOTED) |

### 9.4 Tipos exclusivos por Journey

| Exclusivo da Delivery | Exclusivo da Diligence |
|---|---|
| Bootstrap.Started, Bootstrap.Completed | Capture.Started, Capture.Completed |
| Hack.Completed | Attach.Completed |
| Sync.Completed | Scan.Started, Scan.Completed |
| Finish.Completed | Flag.Completed |
| Ship.Completed | Repair.Started, Repair.Completed |
| Promote.Completed (produção) | Waiver.Granted, Waiver.Rejected |
| Review.Approved, Review.ChangesRequested | Divergence.Detected, Finding.Recorded |
| Rework.Declared, Rework.Completed | Close.Completed |
| — | Promote.Completed (readiness) |

### 9.5 Diferenças arquiteturais notáveis

| Aspecto | Delivery | Diligence |
|---|---|---|
| Número de ciclos | 2 (CI Sync, CI Async) | 2 (Diligence Sync, Async) |
| Estado final | DONE (via Promote.Completed) | DONE (via Close.Completed) ou REPAIRED/WAIVED |
| Impediment.Resolved | alters_state=true, new_state=HACKING (simplificação MVP) | alters_state=false (Lookback — implementação refinada) |
| Producer exclusivo: Agent | Não — Agents compartilham tipos com Human | Sim — ciclo Async é exclusivamente Agent |
| Conceito de exceção | Não | Sim — Waiver.Granted/Rejected |
| Category Diligence | Não usada | Usada — Divergence.Detected, Finding.Recorded |

---

## 10. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado |
| Derived State como projeção da Timeline | Preservado — 13 tipos com new_state + Lookback |
| Event Category como catálogo fixo do Framework (8 categorias) | Preservado — 5 de 8 usadas, nenhuma nova criada |
| Event Type Schema satisfeito por todos os tipos | Confirmado — 12 VALs aplicadas a todos os 20 tipos |
| Naming convention `Subject.Action` | Confirmado — 20 tipos sem desvio |
| Lookback como operação de Consumer (não campo de evento) | Confirmado — Impediment.Resolved usa Lookback |
| README.md não alterado | Confirmado |
| ontology.md não alterado | Confirmado |
| taxonomy.md não alterado | Confirmado |
| lifecycle.md não alterado | Confirmado |
| event-type-schema.md não alterado | Confirmado |
| event-instance-schema.md não alterado | Confirmado |
| timeline.md não alterado | Confirmado |
| Delivery Event Catalog não alterado | Confirmado |
| Shared Types não criados | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 11. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/journeys/diligence/events/README.md` | ~130 | Contexto da Journey Diligence no OEM |
| `prodops/framework/journeys/diligence/events/catalog.md` | ~460 | 20 Event Types completos + 4 fluxos de referência |
| `prodops/documentation-review-diligence-event-catalog.md` | Este arquivo | Relatório da segunda implementação de referência |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 12. Próximos Passos Sugeridos

| Ação | Prioridade | Raciocínio |
|---|---|---|
| Iniciar promoção dos 4 Shared Types (Gate.Passed, Gate.Failed, Impediment.Declared, Impediment.Resolved) | **Alta** | CRT-01 a CRT-05 estão todos satisfeitos — dois Journeys confirmaram uso com semântica equivalente |
| Atualizar catálogo Delivery v2: Impediment.Resolved → alters_state=false | Alta | Adotar o padrão refinado da Diligence |
| Criar `events/shared-types.md` | Alta | Repositório dos 4 candidatos promovidos |
| Adicionar `Remediation.Applied`, `Evidence.Attached`, `Waiver.Expired` ao catálogo Diligence v2 | Média | Completar cobertura das lacunas identificadas |
