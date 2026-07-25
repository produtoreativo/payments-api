# Relatório — Operational Timeline
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Formalização de comportamento — exclusivamente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/timeline.md`

---

## 1. Executive Summary

A Operational Timeline foi formalizada como o mecanismo central que transforma uma
sequência de Operational Events em uma representação operacional consistente de um Work Item.

| Item | Resultado |
|---|---|
| Seções do documento | 11 |
| Invariantes da Timeline (INV-TL) | 7 (INV-TL-01 a INV-TL-07) |
| Algoritmos conceituais definidos | 8 (derivedState, stateSequence, fullReplay, replayUntil, lookback, preBlockedState, etc.) |
| Métricas calculáveis sem campos adicionais | 12 |
| Consumidores documentados | 6 (COR, Diligence, Assessment, Métricas/Dashboards, Agentes, Humanos) |
| Limitações do catálogo Delivery resolvidas | 2 (Impediment.Resolved, Event.Corrected) |
| Documentos alterados | 0 |
| Conceitos arquiteturais novos introduzidos | 1 (Lookback — formalizando o que estava implícito) |
| Documentos criados | 2 (`timeline.md` + este relatório) |

---

## 2. Modelo da Timeline

### 2.1 Definição formal

```
Timeline(W) = [e₁, e₂, ..., eₙ]  onde:
  - W: Work Item proprietário
  - eᵢ: Operational Event válido
  - monotonicamente crescente: eᵢ.timestamp ≤ eⱼ.timestamp  (i < j)
  - estritamente crescente:   eᵢ.sequence_number < eⱼ.sequence_number (i < j)
  - n ≥ 0 (Timeline pode estar vazia)
```

### 2.2 Propriedades estruturais

| Propriedade | Valor |
|---|---|
| Escopo | Um Work Item |
| Cardinalidade com Work Item | 1:1 (INV-03 da Ontologia) |
| Mutabilidade | Somente append — nunca update, delete |
| Duração | Indefinida — nunca termina explicitamente |
| Estado inicial | Vazia, DerivedState = null |
| Estado final | Não existe — DONE é estado do Work Item, não da Timeline |

---

## 3. Regras de processamento

### 3.1 Regras de ordenação

| Critério | Ordem | Autoritativo? |
|---|---|---|
| `timestamp` | Crescente (≤) | Primário |
| `sequence_number` | Crescente (<) | Secundário (desempatador) |

O `≤` no timestamp (não `<`) permite eventos simultâneos. O `<` no sequence_number
(estritamente) garante desambiguação completa.

### 3.2 Regras de registro

| Condição | Ação |
|---|---|
| `id` já existe na Timeline | Rejeitado (duplicata) |
| `timestamp` < último evento | Rejeitado (fora de ordem) |
| `event_type` não é Active | Rejeitado (VAL-I-01) |
| `producer_type` não em `producer_subtypes` | Registrado com alerta (permissivo) |
| `payload` não satisfaz `payload_shape` | Rejeitado (VAL-I-08) |
| `schema_version` desconhecida | Registrado com alerta (permissivo) |

### 3.3 Regras de leitura

Toda leitura da Timeline é não-destrutiva. O Replay é idempotente (INV-TL-05). O Lookback
é somente leitura (INV-TL-06). Nenhuma operação de leitura altera a Timeline.

---

## 4. Algoritmo conceitual de reconstrução do Derived State

### 4.1 Estado atual

```
function derivedState(timeline):
  for event in reversed(timeline):
    if eventType(event.event_type).alters_state == true:
      return eventType(event.event_type).new_state
  return null
```

**Complexidade:** O(n) no pior caso, onde n é o tamanho da Timeline. Na prática, o último
evento `alters_state = true` está próximo do final da Timeline — a busca converge rapidamente.

**Invariante:** o resultado é sempre o `new_state` de um evento existente na Timeline,
ou `null`. Nunca é um valor computado externamente.

### 4.2 Estado histórico

```
function derivedStateAt(timeline, t):
  filtered = [e for e in timeline if e.timestamp <= t]
  return derivedState(filtered)
```

**Propriedade:** `derivedStateAt(timeline, now()) == derivedState(timeline)`.

**Uso:** reconstrução histórica, análise retroativa, auditoria de Diligence.

### 4.3 Sequência de estados

```
function stateSequence(timeline):
  result = []
  for event in timeline:
    type = eventType(event.event_type)
    if type.alters_state:
      result.append({
        state:      type.new_state,
        since:      event.timestamp,
        until:      null,  # preenchido pela próxima iteração
        caused_by:  event.event_type,
        producer:   event.producer_identity,
        event_id:   event.id
      })
      if len(result) > 1:
        result[-2].until = event.timestamp
  return result
```

**Saída:** sequência cronológica de todos os estados do Work Item com intervalos de tempo.
Permite calcular `time_per_state` sem nenhum campo adicional.

---

## 5. Mecanismo de Lookback

### 5.1 O Lookback como conceito formal

O Lookback é a principal contribuição arquitetural deste documento — a formalização de
um mecanismo que era implícito mas sem nome no OEM.

**Definição:** Lookback é uma consulta retroativa à Timeline a partir de uma posição âncora,
com um predicado, retornando o primeiro evento que satisfaz o predicado.

**Natureza:** operação de leitura — não modifica a Timeline, não cria eventos, não persiste resultados.

### 5.2 Algoritmo geral

```
function lookback(timeline, anchor_position, predicate):
  for event in reversed(timeline[:anchor_position]):
    if predicate(event):
      return event
  return null
```

### 5.3 Instâncias do Lookback no catálogo Delivery

| Caso de uso | Predicado | Ancora em |
|---|---|---|
| Estado pré-BLOCKED | `alters_state=true AND new_state != BLOCKED` | posição de Impediment.Declared |
| Evento corrigido | `e.id == corrected_event_id` | posição de Event.Corrected |
| Contexto do rework | `alters_state=true` | posição de Rework.Declared |
| Impedimento em aberto | `event_type == Impediment.Declared` sem Resolved | qualquer posição |

### 5.4 Resolução das limitações do catálogo Delivery MVP

**Limitação 1 — Impediment.Resolved retorna sempre a HACKING:**

O catálogo MVP documentou essa simplificação: `Impediment.Resolved` com `new_state = HACKING`
independente do estado pré-bloqueio.

O Lookback resolve isso nativamente:

```
preBlockedState(timeline, resolved_position):
  declared = lookback(timeline, resolved_position, Impediment.Declared)
  return lookback(timeline, declared.position, alters_state=true AND new_state != BLOCKED).new_state
```

Isso permite que versões futuras do catálogo declarem `Impediment.Resolved` com
`alters_state = false` — e o Consumer usa Lookback em vez de depender de um `new_state`
hardcoded. A Timeline preserva a informação; o Lookback a recupera.

**Limitação 2 — Event.Corrected sem mecanismo formal de aplicação:**

O catálogo MVP não descrevia como `Event.Corrected` seria aplicado durante o processamento.
A seção 7.1 do timeline.md formaliza o padrão completo de Replay com Corrections — um
dicionário de correções indexado por `corrected_event_id`, aplicado como overlay durante
o processamento de cada evento.

---

## 6. Confirmação das 12 métricas sem campos adicionais

| Métrica | Campos usados | Cálculo |
|---|---|---|
| Lead Time | Bootstrap.Started.timestamp, Promote.Completed.timestamp | Diferença |
| Cycle Time | Bootstrap.Completed.timestamp, Promote.Completed.timestamp | Diferença |
| Time per Phase | stateSequence(timeline) | Intervalos na sequência de estados |
| Block Time | Impediment.Declared.timestamp, Impediment.Resolved.timestamp | Soma de diferenças |
| Rework Rate | count(Rework.Declared) | Count por Work Item |
| Rework Time | Rework.Declared.timestamp, Rework.Completed.timestamp | Soma de diferenças |
| Deployment Frequency | count(Promote.Completed) por período | Count com filtro |
| Change Failure Rate | count(Promote.Rejected / Promote.Approved + Promote.Rejected) | Ratio |
| Gate Failure Rate | count(Gate.Failed / Gate.Passed + Gate.Failed) | Ratio |
| Review Cycles | count(Review.ChangesRequested) | Count por Work Item |
| Promote Approval Rate | count(Promote.Approved / total decisions) | Ratio |
| Rework Cycles | count(Rework.Declared) | Count por Work Item |

**Resultado:** todas as 12 métricas são deriváveis exclusivamente dos campos definidos no
Event Instance Schema (timestamp, event_type, producer_identity) e nos Event Types do
catálogo (alters_state, new_state, event_type name). Nenhum campo adicional foi necessário.

---

## 7. Principais Decisões

### DEC-TL-01 — A Timeline nunca termina (nem com DONE)

**Decisão:** a Timeline permanece aberta mesmo após o Work Item atingir DONE.

**Justificativa:** eventos de Correction podem ser registrados em qualquer momento — inclusive
anos após a entrega. A imutabilidade exige que o canal de append permaneça aberto. Fechar
a Timeline após DONE impossibilitaria a Correction e a auditoria histórica.

**Consequência prática:** implementações devem distinguir entre Timelines "quiescentes"
(DONE — poucas escritas esperadas) e "ativas" (qualquer outro estado — escritas frequentes).

---

### DEC-TL-02 — Lookback é uma operação de Consumer, não um campo do evento

**Decisão:** o Lookback não é implementado como campo adicional no evento (ex.: `pre_blocked_state`
como campo do `Impediment.Resolved`). É uma operação que o Consumer executa sobre a Timeline.

**Justificativa:** colocar o estado de retorno como campo no evento criaria redundância:
a informação já está implícita na Timeline — o Lookback a recupera sem armazenamento adicional.
Adicionar campos redundantes viola a imutabilidade semântica: se o campo e o Lookback
divergissem, qual seria a fonte de verdade?

**Consequência:** o catálogo Delivery MVP pode ter `Impediment.Resolved` com `new_state = HACKING`
(simplificação) OU com `alters_state = false` (Lookback como mecanismo). Ambas as abordagens
são válidas — a segunda é mais precisa e é a recomendação para catálogos maduros.

---

### DEC-TL-03 — Replay é sempre idempotente (INV-TL-05)

**Decisão:** o Replay é declarado idempotente como invariante formal — não como propriedade
incidental.

**Justificativa:** a idempotência do Replay é a garantia que permite falhas e recuperação
sem perda de consistência. Um Consumer que falha no meio do processamento pode reiniciar
do último checkpoint — o resultado final é idêntico ao que seria produzido sem a falha.

**Condição:** a idempotência é garantida somente para Consumers determinísticos (mesmo
input → mesmo output). Consumers com efeitos colaterais externos (ex.: enviar notificações)
precisam de lógica de deduplicação adicional.

---

### DEC-TL-04 — Eventos semanticamente incoerentes entram na Timeline

**Decisão:** a Timeline não valida coerência semântica — apenas validade estrutural. Uma
sequência semanticamente impossível (ex.: `Promote.Completed` seguido de `Bootstrap.Started`)
é aceita estruturalmente.

**Justificativa:** a verificação de coerência semântica é complexa e custosa para ser
feita no momento do registro. Além disso, há situações legítimas onde a coerência só pode
ser verificada retrospectivamente (ex.: uma precondição que depende de outro sistema).

A Diligence é o Consumer especializado em detectar incoerências semânticas após o registro.
Separar registro (rápido, estrutural) de verificação (retroativa, semântica) é mais robusto
que tentar fazer os dois no momento do append.

---

### DEC-TL-05 — O Derived State é derivado, nunca armazenado na Timeline

**Decisão:** `derivedState` é uma função sobre a Timeline — não um campo armazenado.

**Justificativa:** armazenar o Derived State na Timeline criaria uma segunda fonte de
verdade. Se o Derived State armazenado divergisse do calculado pela função (por bug ou
corrupção), qual prevaleceria? A resposta correta é sempre "o calculado pela função" — o
que torna o armazenamento desnecessário e potencialmente perigoso.

**Exceção de implementação:** caches do Derived State (em memória, em COR) são permitidos,
desde que sejam tratados como caches — invalidados quando novos eventos são registrados
e recalculados a partir da Timeline em caso de divergência.

---

## 8. Riscos

### RIS-TL-01 — Timelines longas aumentam o custo de Replay

**Descrição:** Work Items de longa duração ou com muitos ciclos de rework acumulam centenas
ou milhares de eventos. O Replay completo a partir do início pode ser custoso.

**Probabilidade:** Média.

**Mitigação:** checkpoints periódicos (snapshot do Derived State em um `sequence_number`
específico). O Consumer armazena o checkpoint e reinicia o Replay dali — não do início.
O checkpoint não viola a imutabilidade: é um dado computado pelo Consumer, não um evento
na Timeline.

---

### RIS-TL-02 — Timestamps imprecisos ou manipulados pelo Producer

**Descrição:** um Producer registra um `timestamp` que não reflete o instante real do
acontecimento — seja por relógio incorreto, seja por ajuste intencional.

**Probabilidade:** Baixa para sistemas (relógio NTP); Média para eventos humanos reportados com atraso.

**Mitigação:** o Instance Schema distingue `timestamp` (instante do registro) de timestamp
de ocorrência (campo no payload). Para sistemas, o timestamp é confiável. Para humanos,
o Producer deve usar o timestamp de registro e documentar o timestamp real no payload.
A Diligence pode detectar timestamps implausíveis (ex.: evento "futuro" ou muito antigo).

---

### RIS-TL-03 — Lookback com Timeline fragmentada ou incompleta

**Descrição:** se eventos foram rejeitados (por invalidade) ou se há lacunas na Timeline,
o Lookback pode retornar resultado incorreto — ex.: o evento pré-BLOCKED real não está
na Timeline por ter sido rejeitado.

**Probabilidade:** Baixa — eventos válidos raramente são rejeitados.

**Mitigação:** a Diligence verifica a integridade da Timeline como parte do ciclo de
verificação. Lacunas detectadas são sinalizadas como anomalias. O Consumer que usa Lookback
deve tratar o retorno `null` como anomalia — não como "ausência de estado anterior".

---

### RIS-TL-04 — Consumer que armazena estado externo e diverge da Timeline

**Descrição:** um Consumer (ex.: COR) armazena o Derived State externamente e falha em
atualizá-lo após novos eventos. A COR mostra um estado inconsistente com a Timeline.

**Probabilidade:** Média — falhas de atualização da COR são comuns em sistemas distribuídos.

**Mitigação:** INV-TL-07 estabelece que a Timeline prevalece. A Diligence verifica periodicamente
a consistência entre Timeline e COR — e sinaliza divergências para reparo. O Consumer
nunca deve tratar o estado externo como fonte de verdade.

---

## 9. Resolução das limitações do catálogo Delivery

| Limitação (do catálogo MVP) | Status após timeline.md |
|---|---|
| `Impediment.Resolved` retorna sempre a HACKING | **Resolvida** — Lookback `preBlockedState` recupera o estado pré-BLOCKED sem depender de `new_state` hardcoded |
| `Event.Corrected` sem mecanismo formal | **Resolvida** — seção 7.1 formaliza o padrão de Replay com overlay de correções |
| Sem `Hack.Started`, `Sync.Started` | Permanece como lacuna do catálogo (não é limitação do modelo de Timeline) |
| Sem `Validate.Completed` | Idem |
| Sem eventos System | Idem |
| Sem `Waiting.Declared/Resolved` | Idem |

As 4 lacunas restantes são decisões de catálogo — o modelo de Timeline suporta a adição
desses tipos sem nenhuma mudança.

---

## 10. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado e formalizado (INV-TL-07) |
| Derived State como projeção da Timeline | Preservado — algoritmo `derivedState` formaliza a projeção |
| Append-only (INV-02 da Ontologia) | Preservado (INV-TL-02) |
| Imutabilidade dos eventos (INV-01) | Preservado (INV-TL-03) |
| COR como consumidora do OEM | Preservado — COR é um dos 6 Consumers documentados |
| Diligence como verificadora | Preservado — Diligence é Consumer especializado |
| README.md não alterado | Confirmado |
| ontology.md não alterado | Confirmado |
| taxonomy.md não alterado | Confirmado |
| lifecycle.md não alterado | Confirmado |
| event-type-schema.md não alterado | Confirmado |
| event-instance-schema.md não alterado | Confirmado |
| Delivery Event Catalog não alterado | Confirmado |
| Shared Types não criados | Confirmado |
| Novos Event Types não criados | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 11. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/events/timeline.md` | ~430 | Modelo canônico da Operational Timeline |
| `prodops/documentation-review-operational-timeline.md` | Este arquivo | Relatório de formalização |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 12. Próximos Passos Sugeridos

Com a Timeline formalizada, o OEM está completo em todos os seus componentes conceituais:

```
README           ✓  Fundação
Ontology         ✓  8 conceitos, 10 invariantes
Taxonomy         ✓  8 categories, naming, REG-01–10
Lifecycle        ✓  6 estados, 8 INV-LC, 9 anti-padrões
Event Type Schema ✓  9 obrigatórios, 12 validações
Instance Schema  ✓  7 obrigatórios, 10 validações, imutabilidade
Timeline         ✓  Replay, Lookback, Derived State, 12 métricas
Delivery Catalog ✓  17 Event Types, MVP validado
```

| Documento | Prioridade | Raciocínio |
|---|---|---|
| `events/shared-types.md` | Alta | Gate.Passed, Gate.Failed prontos para formalização como Shared Types após segunda Journey confirmar necessidade |
| `journeys/delivery/events/catalog.md` v2 | Média | Adicionar tipos System, Waiting, Hack.Started; atualizar Impediment.Resolved para `alters_state=false` com Lookback |
| `journeys/diligence/events/catalog.md` | Média | Segunda Journey que valida o OEM e desbloqueia Gate.Passed como candidato real a Shared Type |
| Implementação da COR como Consumer | Baixa | Usar o modelo de Timeline para definir o protocolo de atualização do GitHub Project |
