# Diligence Journey — Operational Event Model
# ProdOps Framework

> **Domínio:** Journey — Diligence
> **Status:** Canônico
> **Versão:** 1.0.0 (MVP)
> **Depende de:** [OEM README](../../../../events/README.md) · [Event Type Schema](../../../../events/event-type-schema.md) · [Timeline OEM](../../../../events/timeline.md) · [Delivery Catalog](../../delivery/events/catalog.md)

---

## Sobre este documento

Este documento explica como a Jornada Diligence utiliza o Operational Event Model (OEM).
Define o modelo de estados operacionais, os dois ciclos da Diligence, e a estrutura do
catálogo de Event Types.

O catálogo concreto dos tipos está em [catalog.md](catalog.md).

Este documento também registra onde a Diligence confirma a viabilidade cross-Journey do
OEM — validando que o mesmo modelo suporta uma Journey operacionalmente diferente da Delivery.

---

## 1. A Jornada Diligence no ProdOps

A Jornada Diligence garante a integridade e a conformidade do sistema operacional do
ProdOps. Ela opera em dois ciclos independentes que podem afetar o mesmo Work Item em
momentos diferentes:

**Diligence Sync** — ciclo síncrono de captura e gestão:
```
Capture → Attach → Promote → Close
```

**Diligence Async** — ciclo assíncrono de verificação e reparação:
```
Scan → Flag → Repair
```

Um Work Item pode passar pelo Sync (para ser registrado e gerenciado) e, em seguida,
pelo Async (quando divergências são detectadas em iterações posteriores de verificação).

---

## 2. Modelo de Estados Operacionais

O Derived State de um Work Item na Jornada Diligence evolui em duas progressões distintas:

### 2.1 Progressão do ciclo Sync

```
CAPTURING → CAPTURED → ATTACHED → PROMOTING → PROMOTED → DONE
```

### 2.2 Progressão do ciclo Async

```
SCANNING → SCANNED → FLAGGED → REPAIRING → REPAIRED
```

Estados transversais (qualquer ciclo):
```
BLOCKED  — declarado por Impediment.Declared; resolvido por Impediment.Resolved (Lookback)
WAIVED   — declarado por Waiver.Granted; representa exceção formal aprovada
```

### 2.3 Significado de cada estado

| Estado | Ciclo | O que representa |
|---|---|---|
| **CAPTURING** | Sync | O Work Item está sendo registrado no sistema |
| **CAPTURED** | Sync | O Work Item foi registrado; aguarda attach ao projeto |
| **ATTACHED** | Sync | O Work Item está associado ao projeto gerenciado; aguarda revisão para promoção |
| **PROMOTING** | Sync | A aprovação de promoção foi concedida; promoção em execução |
| **PROMOTED** | Sync | O Work Item foi promovido à condição de readiness; aguarda fechamento formal |
| **DONE** | Sync | O Work Item foi fechado com sucesso — ciclo Sync encerrado |
| **SCANNING** | Async | O ciclo de varredura está em execução para o Work Item |
| **SCANNED** | Async | A varredura foi concluída; resultado disponível para análise |
| **FLAGGED** | Async | Divergências foram encontradas e sinalizadas; aguarda reparo ou waiver |
| **REPAIRING** | Async | Reparo das divergências está em execução |
| **REPAIRED** | Async | As divergências foram reparadas — ciclo Async encerrado para esta iteração |
| **BLOCKED** | Qualquer | Work Item bloqueado por impedimento externo |
| **WAIVED** | Async | Divergência recebeu waiver formal — exceção aprovada |

### 2.4 Derivação de estado

O Derived State é o `new_state` do último evento com `alters_state = true` na Timeline
do Work Item (algoritmo definido em `timeline.md`).

**Uso de Lookback:** `Impediment.Resolved` nesta Journey tem `alters_state = false` —
o Consumer usa o mecanismo de Lookback (`preBlockedState`) para determinar o estado de
retorno após resolução do impedimento. Esta é a implementação refinada do mecanismo
formalizado no `timeline.md`, e é uma melhoria em relação à simplificação do catálogo
MVP da Delivery.

---

## 3. Os dois ciclos da Diligence

### 3.1 Diligence Sync

O Diligence Sync é o ciclo de captura e promoção — registra novos Work Items e os
conduz até readiness.

```
Capture.Started (CAPTURING)
    ↓
Capture.Completed (CAPTURED)
    ↓
Attach.Completed (ATTACHED) — Work Item associado ao projeto gerenciado
    ↓ [revisão humana]
Gate events + Promote.Approved → PROMOTING
    ↓
Promote.Completed (PROMOTED)
    ↓
Close.Completed (DONE)
```

### 3.2 Diligence Async

O Diligence Async é o ciclo de verificação — detecta e repara divergências.

```
Scan.Started (SCANNING)
    ↓
Divergence.Detected  (alters_state=false — divergências registradas durante varredura)
Finding.Recorded     (alters_state=false — achados específicos documentados)
    ↓
Scan.Completed (SCANNED)
    ↓ [verificação de resultado]
Flag.Completed (FLAGGED)  ← somente se divergências foram detectadas
    ↓
Repair.Started (REPAIRING)
    ↓ [ou]  Waiver.Granted (WAIVED) ← exceção aprovada
    ↓
Repair.Completed (REPAIRED)
```

Se nenhuma divergência for detectada, a Timeline termina em SCANNED — não há Flag nem Repair.

### 3.3 Interação entre os ciclos

Um Work Item pode ter eventos de ambos os ciclos em sua Timeline:

```
Timeline: OBC-Checkout
  1. Capture.Started         → CAPTURING
  2. Capture.Completed       → CAPTURED
  3. Attach.Completed        → ATTACHED
  4. Promote.Approved        → PROMOTING
  5. Promote.Completed       → PROMOTED
  6. Close.Completed         → DONE
  ...semanas depois, ciclo Async detecta divergência...
  7. Scan.Started            → SCANNING
  8. Divergence.Detected     (alters_state=false)
  9. Scan.Completed          → SCANNED
 10. Flag.Completed          → FLAGGED
 11. Repair.Started          → REPAIRING
 12. Repair.Completed        → REPAIRED
```

---

## 4. Event Categories utilizadas

A Jornada Diligence utiliza 5 das 8 Event Categories:

| Category | Uso na Diligence |
|---|---|
| **Phase Lifecycle** | Início e conclusão de cada step dos ciclos Sync e Async |
| **Gate** | Verificações de readiness antes de promoção |
| **Human Decision** | Aprovação de promoção; concessão ou rejeição de waiver |
| **Blocking** | Impedimentos externos que suspendem a operação |
| **Diligence** | Divergências detectadas e achados registrados durante varredura |

As categories **Rework**, **System** e **Correction** não estão representadas no MVP.

---

## 5. Uso de Lookback

Esta Journey implementa `Impediment.Resolved` com `alters_state = false` — diferentemente
do catálogo MVP da Delivery (onde estava `alters_state = true, new_state = HACKING`).

O Consumer usa `preBlockedState(timeline, resolved_position)` conforme formalizado no
`timeline.md` para determinar o estado de retorno após resolução do impedimento.

Esta decisão foi tomada porque:
1. O catálogo Delivery documentou a simplificação como limitação conhecida
2. O `timeline.md` formalizou o Lookback como mecanismo canônico
3. A Diligence é o segundo catálogo — implementa a versão refinada

---

## 6. Candidatos a Shared Types identificados

| Journey Type (Diligence) | Journey Type (Delivery) | Semântica equivalente? | Candidato? |
|---|---|---|---|
| Gate.Passed | Gate.Passed | Sim — gate genérico | Forte |
| Gate.Failed | Gate.Failed | Sim — gate genérico | Forte |
| Impediment.Declared | Impediment.Declared | Sim — bloqueio genérico | Forte |
| Impediment.Resolved | Impediment.Resolved | Sim — resolução de bloqueio | Forte |
| Promote.Approved | Promote.Approved | Não — semânticas distintas | Não |
| Promote.Completed | Promote.Completed | Não — semânticas distintas | Não |

A promoção formal destes tipos para Shared Types deve seguir o processo do `lifecycle.md`
quando pelo menos duas Journeys confirmarem uso ativo com semântica equivalente.

---

## 7. Versão e lifecycle

| Campo | Valor |
|---|---|
| Versão do catálogo | 1.0.0 (MVP) |
| Todos os tipos | Active |
| Shared Types utilizados | Nenhum neste MVP |
| Namespace para referências cross-Journey | `Diligence` |

---

## Referências

- [OEM Fundação](../../../../events/README.md)
- [Ontologia OEM](../../../../events/ontology.md)
- [Taxonomia OEM](../../../../events/taxonomy.md)
- [Lifecycle OEM](../../../../events/lifecycle.md)
- [Event Type Schema](../../../../events/event-type-schema.md)
- [Event Instance Schema](../../../../events/event-instance-schema.md)
- [Timeline OEM](../../../../events/timeline.md)
- [Delivery Event Catalog](../../delivery/events/catalog.md)
- [Catálogo Diligence MVP](catalog.md)
