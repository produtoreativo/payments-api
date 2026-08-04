# Assessment Journey — Operational Event Model
# ProdOps Framework

> **Domínio:** Journey — Assessment
> **Status:** Canônico
> **Versão:** 1.0.0 (MVP)
> **Depende de:** [OEM README](../../../events/README.md) · [Event Type Schema](../../../events/event-type-schema.md) · [Timeline OEM](../../../events/timeline.md) · [Delivery Catalog](../../delivery/events/catalog.md) · [Diligence Catalog](../../diligence/events/catalog.md)

---

## Sobre este documento

Este documento explica como a Jornada Assessment utiliza o Operational Event Model (OEM).
Define o modelo de estados operacionais, os dois ciclos da Assessment, e a estrutura do
catálogo de Event Types.

O catálogo concreto dos tipos está em [catalog.md](catalog.md).

Esta é a **terceira implementação de referência** do OEM. Seu objetivo é confirmar que o
modelo suporta uma Journey analítica e retrospectiva — fundamentalmente diferente das
Journeys de execução (Delivery) e verificação (Diligence) — sem nenhuma extensão.

---

## 1. A Jornada Assessment no contexto do OEM

A Assessment opera de forma singular em relação às demais Journeys:

| Aspecto | Delivery | Diligence | Assessment |
|---|---|---|---|
| Papel OEM | **Produtor** | **Produtor** | **Consumidor read-only** |
| Emite eventos? | Sim | Sim | **Sim — mas apenas nos seus próprios Work Items** |
| Lê Timelines externas? | Não | Não | **Sim — Delivery e Diligence** |
| Altera Timelines externas? | — | — | **Não — jamais** |

A Assessment **emite seus próprios eventos** (nos Work Items de cada ciclo de Assessment).
Ela **lê** Timelines de Delivery e Diligence como entradas de análise.
Ela **nunca escreve** em Timelines que não sejam as suas próprias.

---

## 2. Modelo de Estados Operacionais

O Derived State de um Work Item da Assessment evolui em duas progressões independentes:

### 2.1 Progressão do ciclo Sync (Assessment estruturada)

```
COLLECTING → COLLECTED → ANALYZING → ANALYZED → SYNTHESIZED → REPORTING → DONE
```

### 2.2 Progressão do ciclo Async (Monitoramento contínuo)

```
MONITORING → ALERTED
```

Após `Alert.Raised → ALERTED`, um novo ciclo de Assessment Sync é acionado. Um novo
`Monitor.Activated` reinicia o ciclo Async.

### 2.3 Estado transversal

```
BLOCKED — declarado por Impediment.Declared; resolvido por Impediment.Resolved (Lookback)
```

### 2.4 Significado de cada estado

| Estado | Ciclo | O que representa |
|---|---|---|
| **COLLECTING** | Sync | O ciclo de coleta de evidências está em execução |
| **COLLECTED** | Sync | O corpus de evidências está completo e indexado |
| **ANALYZING** | Sync | O cálculo de métricas e identificação de padrões está em execução |
| **ANALYZED** | Sync | Métricas e padrões estão calculados — prontos para síntese |
| **SYNTHESIZED** | Sync | Insights foram consolidados — prontos para aprovação do Report |
| **REPORTING** | Sync | A aprovação foi concedida — publicação em execução |
| **DONE** | Sync | O Assessment Report foi publicado — ciclo encerrado |
| **MONITORING** | Async | O ciclo de monitoramento contínuo está ativo |
| **ALERTED** | Async | Um alerta formal foi levantado — Assessment Sync deve ser acionada |
| **BLOCKED** | Qualquer | Work Item bloqueado por impedimento externo |

### 2.5 Derivação de estado

O Derived State é o `new_state` do último evento com `alters_state = true` na Timeline
do Work Item. Algoritmo definido em `timeline.md`.

**Uso de Lookback:** `Impediment.Resolved` nesta Journey tem `alters_state = false` —
o Consumer usa o mecanismo de Lookback (`preBlockedState`) para determinar o estado de
retorno após resolução do impedimento. Implementação refinada — consistente com Diligence.

---

## 3. Os dois ciclos da Assessment

### 3.1 Assessment Sync — Revisão Estruturada

```
Collect.Started (COLLECTING)
    ↓
Collect.Completed (COLLECTED)
    ↓
Analyze.Started (ANALYZING)
    ↓
Analyze.Completed (ANALYZED)
    ↓
Synthesize.Completed (SYNTHESIZED)
    ↓ [revisão humana + gates de qualidade]
Gate.Passed → Gate.Passed → Report.Approved → REPORTING
    ↓
Report.Published (DONE)
```

Caminho alternativo com rejeição:

```
Synthesize.Completed (SYNTHESIZED)
    ↓
Gate.Failed (alters_state=false)
    ↓
Report.Rejected → SYNTHESIZED [re-síntese necessária]
    ↓
[novo ciclo de síntese...]
```

### 3.2 Assessment Async — Monitoramento Contínuo

```
Monitor.Activated (MONITORING)
    ↓
Threshold.Crossed (alters_state=false — métricas registradas)
Recommendation.Issued (alters_state=false — propostas incrementais)
Evolve.Proposed (alters_state=false — evoluções identificadas)
    ↓ [limiar crítico atingido]
Alert.Raised (ALERTED)
    ↓ [aciona Assessment Sync]
    [novo Monitor.Activated no próximo ciclo]
```

### 3.3 Eventos de observação (alters_state=false)

Durante os ciclos, múltiplos eventos de observação são registrados sem alterar o Derived State:

| Evento | Quando ocorre |
|---|---|
| `Gate.Passed` | Gate de qualidade passou durante Collect, Analyze, ou antes de Report.Approved |
| `Gate.Failed` | Gate de qualidade falhou — Producer avalia se Report.Rejected deve ser emitido |
| `Threshold.Crossed` | Uma métrica cruzou um limiar definido durante o monitoramento |
| `Recommendation.Issued` | Uma recomendação formal foi produzida durante Analyze ou Synthesize |
| `Risk.Identified` | Um risco foi formalmente identificado durante a análise |
| `Opportunity.Identified` | Uma oportunidade foi formalmente identificada durante a análise |
| `Evolve.Proposed` | Uma proposta de evolução incremental foi gerada durante o monitoramento |

---

## 4. Event Categories utilizadas

A Jornada Assessment utiliza 5 das 8 Event Categories:

| Category | Uso na Assessment |
|---|---|
| **Phase Lifecycle** | Início e conclusão de cada Step dos ciclos Sync e Async |
| **Human Decision** | Aprovação/rejeição do Report; recomendações, riscos e oportunidades formalizados |
| **Gate** | Verificações de qualidade antes da publicação do Report |
| **Blocking** | Impedimentos externos que suspendem o ciclo de Assessment |
| **System** | Detecção automática de threshold; propostas de evolução geradas por agente |

As categories **Rework**, **Diligence** e **Correction** não estão representadas no MVP.

---

## 5. Uso de Lookback

Esta Journey implementa `Impediment.Resolved` com `alters_state = false` — consistente
com Diligence e com o padrão canônico do OEM (`timeline.md`).

Esta é a **terceira Journey** confirmando o padrão Lookback para `Impediment.Resolved`.
O padrão de Delivery (alters_state=true, new_state=HACKING) é confirmado como a exceção
— não a regra. Delivery v2 deve adotar o padrão refinado.

---

## 6. Candidatos a Shared Types identificados

| Journey Type (Assessment) | Journeys confirmadas | Semântica equivalente | Confiança |
|---|---|---|---|
| `Gate.Passed` | Delivery, Diligence, **Assessment** | Sim — gate automatizado passou | **Alta** |
| `Gate.Failed` | Delivery, Diligence, **Assessment** | Sim — gate automatizado falhou | **Alta** |
| `Impediment.Declared` | Delivery, Diligence, **Assessment** | Sim — bloqueio por impedimento externo | **Alta** |
| `Impediment.Resolved` | Delivery (simplif.), Diligence, **Assessment** | Sim — resolução de bloqueio | **Alta** (3 Journeys) |

A confirmação em três Journeys eleva `Impediment.Resolved` de confiança Média para Alta.
O único bloqueio remanescente é a inconsistência técnica no catálogo Delivery v1 — que
deve ser resolvida em Delivery v2.

Nenhum tipo exclusivo da Assessment é candidato a Shared Type neste MVP — são tipos
específicos desta Journey que precisariam de confirmação em pelo menos uma segunda Journey.

---

## 7. Versão e lifecycle

| Campo | Valor |
|---|---|
| Versão do catálogo | 1.0.0 (MVP) |
| Todos os tipos | Active |
| Shared Types utilizados | Nenhum neste MVP |
| Namespace para referências cross-Journey | `Assessment` |

---

## Referências

- [OEM Fundação](../../../events/README.md)
- [Ontologia OEM](../../../events/ontology.md)
- [Taxonomia OEM](../../../events/taxonomy.md)
- [Lifecycle OEM](../../../events/lifecycle.md)
- [Event Type Schema](../../../events/event-type-schema.md)
- [Event Instance Schema](../../../events/event-instance-schema.md)
- [Timeline OEM](../../../events/timeline.md)
- [Delivery Event Catalog](../../delivery/events/catalog.md)
- [Diligence Event Catalog](../../diligence/events/catalog.md)
- [Catálogo Assessment MVP](catalog.md)
