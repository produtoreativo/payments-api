# Operational Timeline — Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [README.md](README.md) · [ontology.md](ontology.md) · [event-type-schema.md](event-type-schema.md) · [event-instance-schema.md](event-instance-schema.md)

---

## Sobre este documento

Este documento formaliza o comportamento da **Operational Timeline** — o mecanismo que
transforma uma sequência de Operational Events em uma representação operacional consistente
de um Work Item.

A Timeline não é um log, um banco de dados, nem uma fila. É uma estrutura com semântica
formal: ordenada, imutável, append-only, com regras precisas de processamento que permitem
derivar estado, calcular métricas e reconstruir a história completa de um Work Item em
qualquer ponto do tempo.

Este documento é exclusivamente conceitual. Não trata de armazenamento, implementação,
formato de serialização, ou tecnologia de persistência.

→ [Event Type Schema](event-type-schema.md) · [Event Instance Schema](event-instance-schema.md) · [Ontologia OEM](ontology.md)

---

## 1. O que é uma Operational Timeline

Uma Operational Timeline é a **sequência imutável e ordenada de todos os Operational Events
registrados para um Work Item**.

### 1.1 Definição formal

```
Timeline(W) = [e₁, e₂, ..., eₙ]  onde:
  - W é o Work Item ao qual a Timeline pertence
  - eᵢ é um Operational Event válido (satisfaz o Event Instance Schema)
  - para todo i < j: eᵢ.timestamp ≤ eⱼ.timestamp  [monotonicamente crescente]
  - para todo i < j: eᵢ.sequence_number < eⱼ.sequence_number  [estritamente crescente]
  - n ≥ 0  [Timeline pode estar vazia]
```

### 1.2 Responsabilidade

A Timeline é a **fonte primária de verdade** sobre o Work Item. Ela registra:

- todos os acontecimentos operacionais relevantes em ordem cronológica
- o estado atual e todo estado histórico do Work Item
- a evidência intrínseca de cada acontecimento registrado
- o contexto necessário para calcular qualquer métrica operacional

A Timeline não é responsável por:

- armazenar estados calculados (o Derived State é derivado, não armazenado)
- decidir o que deve ser emitido (responsabilidade dos Producers)
- sincronizar com a COR (responsabilidade da Diligence)
- validar a correção semântica das precondições (responsabilidade do Producer)

### 1.3 Limites da Timeline

| Dentro dos limites | Fora dos limites |
|---|---|
| Registrar eventos de um único Work Item | Registrar eventos de múltiplos Work Items |
| Ordenar eventos cronologicamente | Reordenar eventos depois de registrados |
| Ser lida por qualquer Consumer | Ser modificada por qualquer Consumer |
| Crescer com novos eventos | Ser truncada ou ter eventos removidos |
| Existir enquanto o Work Item existir | Expirar automaticamente |

### 1.4 Relação com Work Item

Cada Work Item possui **exatamente uma** Timeline — criada no momento em que o Work Item
é criado e aberta enquanto o Work Item existir (INV-03 da Ontologia).

```
Work Item 1:1 Timeline
```

A Timeline é a identidade operacional do Work Item. Dois Work Items nunca compartilham
uma Timeline. Se um Work Item é dividido (split), dois novos Work Items são criados —
cada um com sua própria Timeline vazia. A Timeline do Work Item original permanece intacta.

### 1.5 Relação com Operational Events

Cada Operational Event pertence a exatamente uma Timeline (INV-03 da Ontologia):

```
Timeline 1:N Operational Events
Operational Event N:1 Timeline
```

Um Operational Event isolado não tem significado operacional sem a Timeline que o posiciona.
É a posição do evento na Timeline — em relação aos outros eventos — que determina seu
impacto sobre o Derived State e sobre as métricas do Work Item.

### 1.6 Relação com Derived State

O Derived State é a **projeção do estado atual do Work Item**, calculado exclusivamente
a partir dos eventos da Timeline com `alters_state = true`:

```
DerivedState(Timeline) = new_state do último evento onde alters_state = true
```

O Derived State não é armazenado na Timeline. É derivado — calculado sob demanda por
Consumers. A Timeline é a fonte de verdade; o Derived State é uma leitura dela.

---

## 2. Estrutura da Timeline

### 2.1 Como uma Timeline nasce

Uma Timeline nasce **vazia** no momento em que o Work Item é criado. Não existe Timeline
sem Work Item, e não existe Work Item sem Timeline.

O estado inicial de uma Timeline vazia é `null` — nenhum evento foi registrado, portanto
nenhum Derived State existe ainda. O primeiro evento com `alters_state = true` será o
primeiro Derived State da Timeline.

```
Timeline nasce:     []  →  DerivedState = null
Após Bootstrap.Started: [Bootstrap.Started]  →  DerivedState = BOOTSTRAPPING
```

### 2.2 Como uma Timeline cresce

Uma Timeline cresce exclusivamente pelo **registro de novos Operational Events** (append).
Cada novo evento é adicionado ao final da sequência — nunca no meio, nunca no início.

O append é o único mecanismo de escrita válido. Não existem operações de update ou delete
sobre eventos já registrados.

```
Antes:  [e₁, e₂, e₃]
Append: [e₁, e₂, e₃, e₄]  ← e₄ é sempre o mais recente
```

### 2.3 Quando uma Timeline termina

**Uma Timeline nunca termina.** A Timeline de um Work Item permanece aberta mesmo após
o Work Item atingir o estado DONE.

A razão é que eventos de Correction podem ser registrados em qualquer momento — inclusive
após o Work Item estar DONE. A imutabilidade exige que o histórico seja sempre acessível
e que correções sejam registradas como novos eventos, não como edições.

Um Work Item em estado DONE tem sua Timeline "quiescente" — nenhum novo evento operacional
é esperado, mas a Timeline permanece como registro histórico permanente e pode receber
eventos de Correction.

### 2.4 Quando uma Timeline permanece aberta

Uma Timeline permanece ativamente em uso enquanto o Work Item estiver em qualquer estado
diferente de DONE. Os estados BOOTSTRAPPING, HACKING, SYNCING, FINISHING, SHIPPING,
VALIDATING, PROMOTING, e BLOCKED são estados ativos — novos eventos são esperados.

---

## 3. Ordem dos eventos

### 3.1 Ordenação primária: timestamp

Os eventos são ordenados primariamente pelo campo `timestamp` em ordem crescente. O
timestamp mais antigo vem primeiro na sequência.

```
[e₁.timestamp ≤ e₂.timestamp ≤ ... ≤ eₙ.timestamp]
```

A ordenação usa `≤` (menor ou igual), não `<` — dois eventos podem ter o mesmo timestamp.

### 3.2 Ordenação secundária: sequence_number

Quando dois eventos têm o mesmo `timestamp`, o `sequence_number` é o desempatador
autoritativo. O evento com `sequence_number` menor precede o evento com `sequence_number`
maior.

```
se eᵢ.timestamp == eⱼ.timestamp:
  ordem é determinada por eᵢ.sequence_number < eⱼ.sequence_number
```

O `sequence_number` é atribuído pela infraestrutura de registro no momento da inserção —
não pelo Producer. Isso garante que a ordem seja determinística mesmo quando dois Producers
emitem eventos com o mesmo timestamp.

### 3.3 Empates de timestamp

Dois eventos na mesma Timeline podem ter o mesmo timestamp quando:

- dois Producers emitem eventos simultaneamente (dentro da resolução do relógio do sistema)
- um Agent emite múltiplos eventos em sequência rápida

Nesses casos, o `sequence_number` resolve o empate. A ordem dos eventos com mesmo
timestamp é determinada pela ordem de chegada à infraestrutura de registro.

### 3.4 Eventos simultâneos e seus efeitos

Quando dois eventos com o mesmo timestamp são processados em sequência, o Derived State
resultante é o `new_state` do evento com maior `sequence_number` (o último da sequência).

```
t=09:15:00: [Bootstrap.Completed (seq=5), Gate.Passed (seq=6)]
DerivedState = new_state de Bootstrap.Completed (seq=5, alters_state=true)
               Gate.Passed (seq=6, alters_state=false) não afeta o estado
```

### 3.5 Eventos fora de ordem

Eventos cujo `timestamp` é anterior ao `timestamp` do último evento registrado na Timeline
são **rejeitados** (VAL-I-07 do Instance Schema). A Timeline é estritamente append-only
no tempo.

Se um evento ocorreu fisicamente antes mas chegou atrasado à infraestrutura de registro,
o timestamp usado deve ser o do momento de registro — não o momento original de ocorrência.
O Producer pode incluir o timestamp original de ocorrência no `payload` ou em `notes`.

---

## 4. Derived State

### 4.1 Definição

O Derived State é o **estado atual do Work Item**, derivado exclusivamente pela Timeline.
É a única fonte válida de estado — estados armazenados externamente (como na COR) são
materializações do Derived State, não fontes primárias.

### 4.2 Algoritmo de cálculo

O Derived State é calculado percorrendo a Timeline em ordem reversa (do evento mais
recente ao mais antigo) e retornando o `new_state` do primeiro evento encontrado com
`alters_state = true`:

```
function derivedState(timeline):
  for event in reversed(timeline):
    if eventType(event.event_type).alters_state == true:
      return eventType(event.event_type).new_state
  return null
```

O resultado `null` indica que nenhum evento de alteração de estado foi registrado ainda —
o Work Item ainda não tem estado derivado (Timeline vazia ou com apenas eventos de
`alters_state = false`).

### 4.3 Estado em um ponto do tempo

O Derived State pode ser calculado para qualquer ponto do tempo `t`, restringindo a
Timeline aos eventos com `timestamp ≤ t`:

```
function derivedStateAt(timeline, t):
  filtered = [e for e in timeline if e.timestamp <= t]
  return derivedState(filtered)
```

Isso permite reconstituir o estado histórico do Work Item em qualquer instante — sem
armazenar snapshots.

### 4.4 Sequência de estados

A sequência completa de estados do Work Item pode ser reconstruída listando todos os
eventos com `alters_state = true` em ordem:

```
function stateSequence(timeline):
  result = []
  for event in timeline:
    if eventType(event.event_type).alters_state == true:
      result.append({
        state: eventType(event.event_type).new_state,
        since: event.timestamp,
        caused_by: event.event_type,
        producer: event.producer_identity
      })
  return result
```

A sequência de estados é o histórico completo de transições do Work Item — sem nenhum
dado adicional além dos eventos da Timeline.

### 4.5 Imutabilidade do Derived State

O Derived State é imutável no passado: o estado do Work Item em qualquer ponto do tempo
passado nunca muda, porque a Timeline é imutável. Novos eventos podem alterar o estado
atual, mas nunca o histórico.

---

## 5. Replay

### 5.1 O que é Replay

Replay é o processamento da Timeline do início ao fim para reconstruir qualquer representação
derivada — estado atual, histórico de estados, métricas, auditoria. Todo Consumer de
Timeline opera conceitualmente por Replay.

O Replay é a consequência direta da imutabilidade: como eventos não são alterados, qualquer
representação derivada pode sempre ser reconstruída a partir do início.

### 5.2 Replay completo

O Replay completo processa todos os eventos da Timeline em ordem:

```
function fullReplay(timeline, processor):
  state = null
  for event in timeline:
    type = eventType(event.event_type)
    if type.alters_state:
      state = type.new_state
    processor.process(event, state)
  return processor.result()
```

O `processor` é o Consumer específico — pode ser um calculador de métricas, um verificador
de Diligence, um atualizador de COR, ou qualquer outro.

### 5.3 Replay parcial (a partir de checkpoint)

Para Timelines longas, o Consumer pode armazenar checkpoints — snapshots do resultado
parcial do Replay em um ponto específico da Timeline (por `sequence_number`). Ao precisar
recalcular, o Consumer reinicia do checkpoint mais recente em vez de recomeçar do início.

O checkpoint inclui: o `sequence_number` do último evento processado, o Derived State
naquele ponto, e o estado parcial do Consumer.

### 5.4 Reconstrução após falha

Quando um Consumer falha durante o processamento, ele retoma do último checkpoint
persistido e reprocesa a partir daquele ponto. Porque a Timeline é imutável, o resultado
do Replay é sempre idêntico independentemente de quantas vezes é executado — o Replay
é idempotente.

```
propriedade de idempotência:
  fullReplay(timeline) == fullReplay(timeline) para qualquer Consumer determinístico
```

### 5.5 Replay histórico

O Replay histórico reconstrói o estado do Work Item em qualquer ponto passado:

```
function replayUntil(timeline, target_timestamp, processor):
  for event in timeline:
    if event.timestamp > target_timestamp:
      break
    type = eventType(event.event_type)
    if type.alters_state:
      state = type.new_state
    processor.process(event, state)
  return processor.result()
```

O Replay histórico é o mecanismo que permite responder perguntas como "qual era o estado
do Work Item na data X?" e "qual era a taxa de rework no trimestre anterior?" — sem
snapshots armazenados.

---

## 6. Lookback

### 6.1 O que é Lookback

Lookback é o mecanismo de **consulta retroativa à Timeline** — ler eventos anteriores
a uma posição específica para obter informação que não está explícita no evento corrente.

O Lookback é uma operação de Consumer — não é armazenado na Timeline e não altera nenhum
evento. É a solução formal para situações onde o significado de um evento depende do
contexto histórico da Timeline.

### 6.2 Algoritmo geral de Lookback

```
function lookback(timeline, anchor_position, predicate):
  for event in reversed(timeline[:anchor_position]):
    if predicate(event):
      return event
  return null
```

O `anchor_position` é o índice do evento a partir do qual a busca retroativa começa.
O `predicate` é a condição que o evento buscado deve satisfazer.

### 6.3 Lookback para estado pré-BLOCKED

O caso de uso mais importante de Lookback — e a solução para a limitação do catálogo
MVP da Delivery — é recuperar o estado em que o Work Item estava antes de entrar em BLOCKED.

**Problema:** quando `Impediment.Declared` é registrado, o Work Item entra em BLOCKED.
Quando `Impediment.Resolved` é registrado, o Work Item deve retornar ao estado anterior
ao bloqueio — mas esse estado não está explícito no evento `Impediment.Resolved`.

**Solução via Lookback:**

```
function preBlockedState(timeline, impediment_resolved_position):
  # Encontrar o Impediment.Declared correspondente
  declared = lookback(
    timeline,
    impediment_resolved_position,
    e => e.event_type == "Impediment.Declared"
  )

  if declared is null:
    return null  # anomalia — não há Impediment.Declared correspondente

  declared_position = timeline.indexOf(declared)

  # Retornar ao estado antes do bloqueio
  return lookback(
    timeline,
    declared_position,
    e => eventType(e.event_type).alters_state
         and eventType(e.event_type).new_state != "BLOCKED"
  ).new_state
```

**Exemplo concreto:**

```
Timeline: WI-033
pos 1: Bootstrap.Started    → BOOTSTRAPPING  [alters_state=true]
pos 2: Bootstrap.Completed  → HACKING        [alters_state=true]
pos 3: Hack.Completed       → SYNCING        [alters_state=true]
pos 4: Impediment.Declared  → BLOCKED        [alters_state=true]
pos 5: Impediment.Resolved  → ?

Lookback em pos 5:
  buscar Impediment.Declared → encontrado em pos 4
  buscar antes de pos 4 onde alters_state=true e new_state != BLOCKED
  → pos 3: Hack.Completed com new_state=SYNCING

Estado de retorno após Impediment.Resolved: SYNCING
```

Este mecanismo permite que `Impediment.Resolved` tenha `alters_state = false` em versões
futuras do catálogo — o Consumer usa Lookback para calcular o estado de retorno sem
que o tipo precise declará-lo explicitamente.

### 6.4 Lookback para interpretação de Rework

O Rework pode ocorrer de um estado não-HACKING (ex.: o Work Item está em SYNCING e
`Rework.Declared` o leva de volta a HACKING). Para calcular o custo do rework (tempo
perdido), o Consumer usa Lookback para encontrar o estado que precedeu o Rework:

```
function priorStateBeforeRework(timeline, rework_declared_position):
  return lookback(
    timeline,
    rework_declared_position,
    e => eventType(e.event_type).alters_state
  ).new_state
```

Com o estado pré-Rework e o timestamp de `Rework.Declared`, é possível calcular o tempo
que o Work Item passou no estado que foi descartado.

### 6.5 Lookback para interpretação de Correction

Quando um Consumer encontra `Event.Corrected` na Timeline, usa Lookback para localizar
o evento corrigido pelo `corrected_event_id` no payload:

```
function findCorrectedEvent(timeline, correction_position):
  corrected_id = timeline[correction_position].payload.corrected_event_id
  return lookback(
    timeline,
    correction_position,
    e => e.id == corrected_id
  )
```

O Consumer então aplica a correção do payload ao processar semanticamente o evento original.
O evento original permanece imutável — o Consumer mantém uma visão "corrigida" em memória
durante o processamento.

### 6.6 Lookback para pares complementares abertos

Quando `Impediment.Declared` não tem um `Impediment.Resolved` correspondente, o Work Item
está genuinamente bloqueado. O Lookback para Impediment.Resolved retorna `null` — o Consumer
interpreta como "impedimento em aberto".

```
function openImpediments(timeline):
  return [
    e for e in timeline
    if e.event_type == "Impediment.Declared"
    and not hasMatchingResolved(timeline, e)
  ]
```

Este padrão é a base da verificação de Diligence: pares complementares sem resolução são
anomalias.

---

## 7. Correções, duplicatas e anomalias

### 7.1 Event.Corrected

`Event.Corrected` é o único mecanismo válido para registrar que um evento anterior contém
dados incorretos. O evento original permanece imutável — a correção é um novo evento que
referencia o original.

**Processamento durante Replay:**

```
function replayWithCorrections(timeline, processor):
  corrections = {
    c.payload.corrected_event_id: c
    for c in timeline if c.event_type == "Event.Corrected"
  }

  for event in timeline:
    if event.event_type == "Event.Corrected":
      continue  # processado como overlay, não como evento primário

    corrected_view = applyCorrectionOverlay(event, corrections.get(event.id))
    processor.process(corrected_view, currentState)
```

O overlay aplica o conteúdo corrigido apenas para a visão do Consumer — o evento original
não é modificado.

**O que `Event.Corrected` pode corrigir:**
- Campos do `payload` com valores incorretos
- O campo `notes`
- O campo `producer_identity` (se registrado incorretamente)

**O que `Event.Corrected` não pode corrigir:**
- `event_type` — o tipo de evento é imutável; se o tipo estava errado, o evento inteiro
  é conceitualmente inválido e deve ser tratado como anomalia
- `timestamp` — a posição temporal é imutável
- `work_item_id` — o pertencimento a uma Timeline é imutável
- `alters_state`, `new_state` — esses são atributos do Event Type, não do evento

### 7.2 Eventos duplicados

Um evento duplicado é um evento com o mesmo `id` de um evento já registrado na Timeline.

**Comportamento:** o duplicado é **rejeitado** antes do registro — não entra na Timeline.
O registro idempotente de eventos (tentar registrar o mesmo evento duas vezes) deve resultar
no primeiro sendo persistido e o segundo sendo descartado silenciosamente.

**Detecção:** a unicidade de `id` é verificada antes da inserção (VAL-I-06 do Instance Schema).

### 7.3 Eventos inválidos

Um evento inválido é aquele que falha em qualquer das validações VAL-I-01 a VAL-I-10 do
Instance Schema.

**Comportamento:** eventos inválidos são **rejeitados** antes de entrar na Timeline. Nunca
são persistidos — a Timeline contém somente eventos que passaram em todas as validações.

**Exceção permissiva:** VAL-I-09 (producer_type autorizado) pode ser permissiva — o evento
entra com alerta. A Diligence detecta a anomalia retroativamente.

### 7.4 Eventos fora de ordem cronológica

Um evento cujo `timestamp` é anterior ao `timestamp` do último evento da Timeline é
rejeitado por VAL-I-07. Não existe mecanismo de "inserção retroativa" na Timeline.

**Tratamento do timestamp:** quando um evento ocorreu antes do momento de registro (ex.:
um evento humano que foi reportado com atraso), o timestamp deve refletir o momento do
registro. O Producer documenta o timestamp original de ocorrência no `payload` ou em
`notes`, se relevante.

### 7.5 Sequência de eventos semanticamente incoerente

A Timeline não valida a coerência semântica dos eventos — apenas a validade estrutural.
Uma Timeline pode conter `Hack.Completed → SYNCING` seguido imediatamente de
`Bootstrap.Started → BOOTSTRAPPING` (semanticamente inconsistente) desde que os timestamps
sejam válidos.

A verificação de coerência semântica (precondições e pós-condições dos Event Types) é
responsabilidade da **Diligence** durante o ciclo de verificação — não do mecanismo de
registro da Timeline.

---

## 8. Métricas

A Timeline é a fonte de todas as métricas operacionais. Nenhum campo adicional é necessário
— todas as métricas são derivadas dos eventos já presentes.

### 8.1 Lead Time

Tempo total desde o início do trabalho até a entrega em produção:

```
LeadTime(W) = Promote.Completed.timestamp - Bootstrap.Started.timestamp
```

Inclui todo o tempo de espera, bloqueios e rework. É a métrica mais abrangente.

### 8.2 Cycle Time

Tempo de desenvolvimento ativo — do início da implementação até a entrega:

```
CycleTime(W) = Promote.Completed.timestamp - Bootstrap.Completed.timestamp
```

Exclui o tempo de setup (Bootstrap). Mede a eficiência do ciclo de desenvolvimento.

### 8.3 Time per Phase

Tempo gasto em cada estado do Work Item, calculado pela sequência de estados:

```
function timePerState(timeline):
  sequence = stateSequence(timeline)
  result = {}
  for i, entry in enumerate(sequence):
    state = entry.state
    start = entry.since
    end = sequence[i+1].since if i+1 < len(sequence) else now()
    result[state] = result.get(state, 0) + (end - start)
  return result
```

### 8.4 Block Time

Tempo total que o Work Item permaneceu no estado BLOCKED:

```
BlockTime(W) = sum(
  Impediment.Resolved.timestamp - Impediment.Declared.timestamp
  for each pair (Impediment.Declared, Impediment.Resolved) in timeline
)
```

Para impedimentos ainda em aberto, `end = now()`.

### 8.5 Rework Rate

Proporção de Work Items que tiveram pelo menos um ciclo de rework:

```
ReworkRate = count(W : exists Rework.Declared in Timeline(W)) / count(all W)
```

Por Work Item, o número de ciclos de rework:

```
ReworkCycles(W) = count(Rework.Declared in Timeline(W))
```

### 8.6 Rework Time

Tempo total gasto em ciclos de rework (do Rework.Declared ao Rework.Resolved):

```
ReworkTime(W) = sum(
  Rework.Resolved.timestamp - Rework.Declared.timestamp
  for each pair in timeline
)
```

### 8.7 DORA — Deployment Frequency

```
DeploymentFrequency(period) = count(Promote.Completed in period) / duration(period)
```

### 8.8 DORA — Change Failure Rate

```
ChangeFailureRate(period) =
  count(Promote.Rejected in period) /
  count(Promote.Approved + Promote.Rejected in period)
```

### 8.9 DORA — Time to Restore

Não calculável com os tipos do catálogo MVP da Delivery — requer eventos de Incident
(fora do escopo do catálogo atual). Quando adicionados, o cálculo seria:

```
TimeToRestore = Incident.Resolved.timestamp - Incident.Declared.timestamp
```

### 8.10 Gate Failure Rate

```
GateFailureRate(W) =
  count(Gate.Failed in Timeline(W)) /
  count(Gate.Passed + Gate.Failed in Timeline(W))
```

### 8.11 Review Cycle Count

Número de iterações de revisão de código por Work Item:

```
ReviewCycles(W) = count(Review.ChangesRequested in Timeline(W))
```

### 8.12 Promote Approval Rate

```
PromoteApprovalRate(period) =
  count(Promote.Approved in period) /
  count(Promote.Approved + Promote.Rejected in period)
```

### 8.13 Princípio geral de derivação de métricas

Toda métrica pode ser expressa como uma das seguintes operações sobre a Timeline:

| Operação | Exemplo |
|---|---|
| **Count** de eventos por tipo | Deployment Frequency, Rework Cycles |
| **Diferença de timestamp** entre dois eventos | Lead Time, Cycle Time, Block Time |
| **Soma** de diferenças de timestamp | Rework Time, Total Block Time |
| **Ratio** entre contagens | Gate Failure Rate, Change Failure Rate |
| **Agregação** sobre múltiplas Timelines | DORA cross-Work Item |
| **Filtro** por período | Métricas por trimestre, por sprint |

Não existe métrica que requeira campos além dos já definidos no Event Instance Schema.

---

## 9. Consumidores da Timeline

### 9.1 Canonical Operational Representation (COR)

A COR — materializada em GitHub Projects e GitHub Issues — é o Consumer mais visível da
Timeline. Ela lê o Derived State e o materializa como o estado do Work Item no GitHub Project.

**O que a COR lê:**
- O Derived State atual: `derivedState(Timeline)` — para atualizar o campo de estado do Issue
- O evento mais recente: para identificar o último produtor e o timestamp da última atividade

**Frequência de leitura:** após cada novo evento registrado na Timeline do Work Item.

**Escrita:** a COR não escreve na Timeline — apenas lê e materializa.

### 9.2 Diligence

A Diligence é o Consumer verificador. Ela audita a Timeline para garantir consistência
entre o que foi registrado e o que deveria ter sido registrado.

**O que a Diligence verifica:**
- Pares de eventos complementares sem resolução (ex.: Impediment.Declared sem Impediment.Resolved)
- Eventos emitidos com tipo Deprecated após a `migration_deadline`
- Eventos com `producer_type` não autorizado pelo Event Type (VAL-I-09 permissiva)
- Consistência entre Derived State na Timeline e estado na COR
- Ausência de eventos esperados para o estado atual (ex.: Work Item em HACKING por mais de X ciclos sem atividade)

**Mecanismo:** a Diligence executa Replay completo da Timeline e verifica cada invariante.

### 9.3 Assessment

O Assessment analisa padrões históricos entre múltiplas Timelines. Ele agrega métricas,
identifica anomalias estruturais, e produz recomendações baseadas em evidência.

**O que o Assessment lê:**
- Sequências de estados de múltiplas Timelines
- Lead Time, Cycle Time, Rework Rate entre Work Items comparáveis
- Correlação entre eventos e métricas de entrega

**Mecanismo:** o Assessment executa Replay sobre um conjunto de Timelines e aplica
análise estatística sobre os resultados.

### 9.4 Métricas e Dashboards

Consumers de métricas e dashboards leem Timelines para calcular indicadores operacionais
em tempo real ou histórico. Eles podem processar Timelines individuais (por Work Item)
ou agregações (por equipe, por Journey, por período).

**Mecanismo:** Replay parcial ou completo com processador de métricas específico.

### 9.5 Agentes

Agentes de IA ou automação leem a Timeline para tomar decisões ou emitir novos eventos.
Um agente lê o Derived State atual, analisa os eventos recentes, e decide se deve emitir
um novo evento (ex.: o Diligence Agent detecta uma anomalia e emite um evento da category
Diligence).

**Padrão:** o agente é tanto Consumer (lê) quanto Producer (emite novos eventos na Timeline).

### 9.6 Humanos

Humanos leem Timelines através de interfaces (dashboards, CLIs, ferramentas de OKR) para
entender o estado e histórico de Work Items. A Timeline é a base de toda narrativa
operacional do Work Item.

---

## 10. Relação com as Journeys

### 10.1 O modelo da Timeline é universal

O modelo da Operational Timeline é definido no nível do Framework — independentemente de
qualquer Journey. Toda Journey que usa o OEM usa exatamente o mesmo modelo de Timeline.

O que varia entre Journeys são os **Event Types** registrados — cada Journey tem seu catálogo.
A estrutura, as regras de ordenação, o algoritmo de Derived State, o Replay, o Lookback
e as validações são idênticos.

```
Framework:  Timeline model (universal)
Journey A:  Delivery Event Types  →  Timeline de Work Items de Delivery
Journey B:  Diligence Event Types →  Timeline de Work Items de Diligence
Journey C:  Discovery Event Types →  Timeline de Work Items de Discovery
```

### 10.2 Interoperabilidade cross-Journey

Porque o modelo é universal, um Consumer pode processar Timelines de múltiplas Journeys
com o mesmo algoritmo — apenas o Event Type Schema referenciado varia.

Para métricas cross-Journey (ex.: Lead Time comparado entre Delivery e Discovery), o
Consumer usa o mesmo algoritmo de Replay aplicado a Timelines de Journeys diferentes.

### 10.3 Cada Journey define seus estados

O Derived State é calculado pelo mesmo algoritmo em todas as Journeys — mas o conjunto
de valores possíveis de `new_state` é definido pelo catálogo de cada Journey.

A Delivery tem: BOOTSTRAPPING, HACKING, SYNCING, FINISHING, SHIPPING, VALIDATING, PROMOTING, DONE, BLOCKED.

Uma Journey futura de Discovery teria seus próprios estados (ex.: RESEARCHING, VALIDATING, CONCLUDED).

O algoritmo de `derivedState(timeline)` é idêntico — apenas os valores de `new_state`
diferem.

---

## 11. Invariantes da Timeline

### INV-TL-01 — A Timeline de um Work Item nunca é destruída

Enquanto o Work Item existir, sua Timeline existe. Não existe operação de destruição de
Timeline — apenas arquivamento.

### INV-TL-02 — Novos eventos são sempre adicionados ao final

O append é o único mecanismo de escrita. Não existem operações de inserção no meio da
Timeline.

### INV-TL-03 — Eventos na Timeline nunca são removidos ou modificados

Uma vez registrado, um evento permanece na Timeline exatamente como foi registrado para
sempre. A imutabilidade é absoluta (INV-01 da Ontologia).

### INV-TL-04 — O Derived State é sempre derivado da Timeline

Nunca é armazenado diretamente na Timeline nem nas entradas da Timeline. É calculado sob
demanda pelos Consumers.

### INV-TL-05 — O Replay é idempotente

Executar o mesmo Replay sobre a mesma Timeline, com o mesmo Consumer determinístico,
produz sempre o mesmo resultado.

### INV-TL-06 — Lookback é somente leitura

O Lookback é uma operação de leitura — nunca modifica a Timeline, nunca cria novos eventos,
nunca persiste resultados na Timeline.

### INV-TL-07 — A Timeline é a única fonte de verdade para estado histórico

Nenhuma representação externa (COR, banco de dados, cache) pode ser usada como fonte de
verdade para o estado histórico de um Work Item. Em caso de conflito, a Timeline prevalece
(INV-09 da Ontologia).

---

## Referências

- [Fundação OEM](README.md)
- [Ontologia OEM](ontology.md)
- [Taxonomia OEM](taxonomy.md)
- [Lifecycle OEM](lifecycle.md)
- [Event Type Schema](event-type-schema.md)
- [Event Instance Schema](event-instance-schema.md)
- [Delivery Event Catalog](../journeys/delivery/events/catalog.md)

---

*Este documento é a fonte canônica do comportamento da Operational Timeline no OEM.
Todo Consumer que processa Timelines e toda Journey que registra eventos deve aderir
ao modelo definido aqui.*
