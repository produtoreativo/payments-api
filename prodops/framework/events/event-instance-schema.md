# Operational Event Instance Schema — Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [README.md](README.md) · [ontology.md](ontology.md) · [event-type-schema.md](event-type-schema.md)

---

## Sobre este documento

Este documento define a estrutura de um **Operational Event** registrado em uma Operational
Timeline.

Um Operational Event é uma ocorrência — não uma definição. Ele registra o que aconteceu,
quando aconteceu, quem o originou, e qual evidência suporta o registro. É a instância
concreta que satisfaz o contrato definido pelo Event Type.

Este documento não define o contrato de Event Types. Esse contrato está em
`event-type-schema.md`.

→ [Event Type Schema](event-type-schema.md) · [Ontologia OEM](ontology.md) · [Fundação OEM](README.md)

---

## 1. O que representa uma instância de Operational Event

Um Operational Event representa um **fato operacional ocorrido** — uma mudança de estado,
uma decisão tomada, um gate verificado, um impedimento declarado. É atômico: representa
um único acontecimento, indivisível, em um instante específico do tempo.

O Operational Event tem três propriedades fundamentais que o distinguem de outros tipos
de registro:

**Imutabilidade:** uma vez registrado, nunca é alterado. O registro é o fato. Modificar
o registro seria alterar a história — o que corrompe a integridade da Timeline.

**Pertencimento único:** pertence a exatamente uma Operational Timeline, que pertence a
exatamente um Work Item. Um Operational Event não existe fora de uma Timeline.

**Autoevidência:** o próprio registro é evidência de que o acontecimento ocorreu (evidência
intrínseca). Evidence adicional pode ser referenciada, mas não é necessária para que o
registro seja válido.

---

## 2. Estrutura de campos

| Grupo | Definição |
|---|---|
| **Obrigatório** | Deve estar presente em todo evento registrado |
| **Opcional** | Pode estar presente; não é exigido para que o registro seja válido |
| **Derivado** | Não é armazenado no evento; computável a partir dos campos obrigatórios ou do contexto |

### 2.1 Campos obrigatórios

| Campo | Tipo |
|---|---|
| `id` | string (identificador único global) |
| `event_type` | string (nome do Event Type — chave para o catálogo) |
| `work_item_id` | string (identificador do Work Item) |
| `timestamp` | string (ISO 8601 com timezone) |
| `producer_type` | enum: `Human` \| `System` \| `Agent` |
| `producer_identity` | string (identidade específica do Producer) |
| `schema_version` | string (versão do Instance Schema usado no registro) |

### 2.2 Campos opcionais

| Campo | Tipo |
|---|---|
| `payload` | objeto — campos específicos da ocorrência conforme `payload_shape` do Event Type |
| `evidence_references` | lista de referências a artefatos externos |
| `sequence_number` | inteiro — posição ordinal do evento na Timeline |
| `notes` | string — contexto adicional sobre a ocorrência específica |

### 2.3 Campos derivados

| Campo derivado | Como derivar |
|---|---|
| `timeline_id` | Derivado de `work_item_id` — a Timeline é 1:1 com o Work Item |
| `category` | Derivado do Event Type referenciado em `event_type` |
| `alters_state` | Derivado do Event Type referenciado em `event_type` |
| `new_state` | Derivado do Event Type quando `alters_state = true` |
| `evidence_intrinsic` | O próprio registro (`id` + `timestamp` + `producer_type` + `producer_identity` + `event_type`) |

Campos derivados **não são armazenados no evento**. Consumers que precisam deles os
calculam consultando o Event Type referenciado. Se forem desnormalizados por eficiência de
leitura (copiados no evento), devem ser marcados como `[derived]` e nunca tratados como
fonte de verdade — a fonte de verdade permanece o Event Type.

---

## 3. Regras de cada campo

### `id`

**Significado:** identificador único e imutável desta ocorrência específica. Distingue este
evento de todos os outros eventos em todas as Timelines — inclusive eventos do mesmo Event
Type emitidos para o mesmo Work Item em momentos diferentes.

**Quem preenche:** o Producer no momento da emissão, ou a infraestrutura que registra o
evento (dependendo da implementação — o `event-instance-schema.md` não prescreve quem
gera o `id`, apenas exige que ele seja único e imutável).

**Quando é preenchido:** no momento do registro — antes de qualquer persistência na Timeline.

**Pode ser alterado:** não. O `id` é a identidade do registro. Alterar o `id` equivale
a criar um evento diferente.

**Regras:**
- Deve ser único globalmente — não apenas dentro da Timeline do Work Item. Eventos de
  Timelines diferentes não podem compartilhar o mesmo `id`.
- Uma vez emitido, o `id` é reservado — não pode ser reutilizado mesmo após o evento
  ser referenciado por um `Event.Corrected`.
- O formato do `id` não é prescrito por este Schema (UUID v4, ULID, hash — qualquer
  formato que garanta unicidade global é válido).

---

### `event_type`

**Significado:** o nome do Event Type que classifica esta ocorrência. É a chave lógica
que conecta o evento registrado ao seu contrato — o Event Type define o que o evento
representa, o que deve ter sido verdadeiro antes, o que é verdadeiro depois.

**Quem preenche:** o Producer, no momento da emissão.

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não. O tipo de um evento é imutável: se um evento foi emitido como
`Bootstrap.Completed`, ele é e sempre foi um `Bootstrap.Completed` — mesmo que o tipo
seja posteriormente depreciado ou removido do catálogo ativo.

**Regras:**
- Deve referenciar um Event Type com `lifecycle_status = Active` no momento da emissão
  (VAL-I-01). Eventos emitidos com tipo Deprecated são anomalias detectáveis pela Diligence.
- O nome deve ser o nome completo do tipo conforme o catálogo — com Namespace quando
  o tipo é de outro catálogo (ex.: `Delivery.Bootstrap.Completed` para referência cross-Journey).
- Mesmo que o tipo referenciado transite para Deprecated ou Removed após a emissão, o
  `event_type` do registro permanece o nome original — o histórico é imutável.

---

### `work_item_id`

**Significado:** identifica o Work Item ao qual este evento pertence e, por consequência,
a Timeline em que o evento será registrado. Define o escopo do evento dentro do modelo.

**Quem preenche:** o Producer ou a infraestrutura de registro.

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não. Um evento pertence a exatamente uma Timeline (INV-03 da
Ontologia). Alterar o `work_item_id` após o registro equivale a mover o evento de uma
Timeline para outra — o que é estruturalmente proibido.

**Regras:**
- O Work Item referenciado deve existir no momento do registro.
- Um evento não pode ser registrado em uma Timeline que pertence a um Work Item diferente
  do que o originou.

---

### `timestamp`

**Significado:** o instante exato em que o acontecimento ocorreu — não o instante em que
o evento foi registrado na Timeline (que pode ser ligeiramente posterior). Quando não é
possível distinguir o instante da ocorrência do instante do registro, o instante do
registro é usado.

**Quem preenche:** o Producer no momento da emissão.

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não.

**Formato:** ISO 8601 com timezone explícito. Exemplos válidos:
```
2026-07-24T09:15:00Z
2026-07-24T09:15:00-03:00
2026-07-24T09:15:00.123Z
```

**Regras:**
- Deve incluir timezone — timestamps sem timezone são inválidos (ambiguidade entre
  fusos impede ordenação confiável da Timeline).
- O `timestamp` de um novo evento deve ser maior ou igual ao `timestamp` do último
  evento registrado na mesma Timeline (propriedade append-only — VAL-I-07). Eventos
  com timestamp anterior ao último evento da Timeline são rejeitados.
- Dois eventos na mesma Timeline podem ter o mesmo `timestamp` (quando ocorrem
  simultaneamente ou em rápida sucessão dentro da resolução do relógio). Nesse caso, o
  `sequence_number` define a ordem.

---

### `producer_type`

**Significado:** classifica a categoria do Producer que originou o evento — para fins de
rastreabilidade, auditoria e verificação de conformidade com o `producer_subtypes`
declarado pelo Event Type.

**Quem preenche:** o Producer (ou a infraestrutura de registro, quando o tipo é inferível
pelo contexto).

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não.

**Valores válidos:** `Human` | `System` | `Agent`

**Regras:**
- O `producer_type` registrado deve estar na lista `producer_subtypes` do Event Type
  referenciado (VAL-I-09).
- Um evento emitido por um Producer não autorizado pelo Event Type é uma anomalia —
  tecnicamente pode ser registrado, mas é detectado pela Diligence.

---

### `producer_identity`

**Significado:** identifica especificamente quem originou o evento dentro do subtipo
declarado em `producer_type`. Permite rastrear a autoria de cada acontecimento na Timeline.

**Quem preenche:** o Producer.

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não.

**Formato e exemplos por subtipo:**

| `producer_type` | Exemplos de `producer_identity` |
|---|---|
| `Human` | `"christiano.milfont"`, `"@usuario"`, nome completo |
| `System` | `"github-actions"`, `"jenkins-pipeline"`, nome do sistema |
| `Agent` | `"diligence-agent"`, `"assessment-agent"`, nome do agente |

**Regras:**
- Deve ser não-vazio (VAL-I-05). Um evento sem identidade de Producer não atende ao
  princípio P-03 (Producer obrigatório) e invalida INV-04 da Ontologia.
- Não é necessário que o formato seja padronizado entre Journeys — cada Journey pode
  usar o formato que melhor identifica seus Producers.

---

### `schema_version`

**Significado:** versão do Instance Schema que estava em vigor no momento do registro. Permite
que Consumers leiam Timelines históricas corretamente, mesmo quando o Schema evoluiu após
o registro dos eventos.

**Quem preenche:** a infraestrutura de registro (automaticamente, com base na versão atual
do Schema).

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não.

**Regras:**
- O valor deve corresponder a uma versão existente deste documento (`event-instance-schema.md`).
- Consumers que encontrarem um `schema_version` desconhecido devem tratar o evento com
  caution — não descartar, mas sinalizar para revisão.
- A versão `1.0.0` corresponde a este documento.

---

### `payload`

**Significado:** dados específicos desta ocorrência — informações que complementam o
registro com contexto que não existe nos campos obrigatórios. A estrutura do payload é
definida pelo `payload_shape` do Event Type referenciado.

**Quem preenche:** o Producer.

**Quando é preenchido:** no momento do registro, quando o Event Type declara `payload_shape`.

**Pode ser alterado:** não. O payload é parte do registro imutável. Se um campo do payload
foi registrado incorretamente, a correção ocorre por emissão de um evento `Event.Corrected`
(ver seção 5).

**Regras:**
- Quando o Event Type declara `payload_shape`, o payload deve incluir todos os campos
  marcados como obrigatórios no `payload_shape` (VAL-I-08).
- Campos opcionais do `payload_shape` podem estar ausentes.
- Campos adicionais não declarados no `payload_shape` são tolerados mas não garantidos
  para processamento por Consumers.
- O payload não pode conter campos que contradizem os campos obrigatórios do evento
  (ex.: um campo `timestamp` no payload com valor diferente do `timestamp` do evento).

---

### `evidence_references`

**Significado:** lista de referências a artefatos externos que suportam o registro como
evidência adicional. Complementa a evidência intrínseca (o próprio registro) com ponteiros
para documentação, links, artefatos ou decisões externas que validam o acontecimento.

**Quem preenche:** o Producer.

**Quando é preenchido:** no momento do registro, quando existem artefatos externos relevantes.

**Pode ser alterado:** não.

**Estrutura de cada referência:**
- `uri`: endereço ou identificador do artefato externo
- `description`: descrição do que o artefato representa e por que é evidência do acontecimento

**Exemplos:**
```
- uri: https://github.com/org/repo/pull/42
  description: "PR aprovado pelo reviewer — evidência do Gate de Code Review"

- uri: prodops/artifacts/obcs/feature-checkout.md
  description: "OBC do Work Item — evidência de que o item tinha definição de done"
```

**Regras:**
- A lista pode estar vazia ou ausente quando a evidência intrínseca é suficiente.
- Referências externas não são validadas por este Schema — a responsabilidade pela
  acessibilidade e integridade dos artefatos externos é do Producer.

---

### `sequence_number`

**Significado:** posição ordinal do evento na Timeline do Work Item. Resolve ambiguidades
de ordenação quando dois eventos têm o mesmo `timestamp`.

**Quem preenche:** a infraestrutura de registro (atribuído automaticamente com base na
posição de inserção na Timeline).

**Quando é preenchido:** no momento do registro.

**Pode ser alterado:** não.

**Regras:**
- Deve ser estritamente crescente dentro de uma Timeline — o próximo evento sempre tem
  `sequence_number` maior que o anterior.
- É derivável da posição do evento na Timeline — mas é recomendado armazená-lo
  explicitamente para facilitar o processamento de Consumers sem necessidade de reordenar.
- Em caso de conflito entre `timestamp` e `sequence_number`, o `sequence_number` é
  autoritativo para ordenação dentro de uma Timeline.

---

### `notes`

**Significado:** contexto adicional sobre esta ocorrência específica — não sobre o Event
Type em geral. Observações que o Producer julgou relevantes no momento da emissão e que
não cabem nos campos estruturados.

**Quem preenche:** o Producer.

**Quando é preenchido:** no momento do registro, quando relevante.

**Pode ser alterado:** não. Notes são parte do registro imutável.

**Regras:**
- Deve registrar contexto sobre a ocorrência, não sobre o Event Type.
- Não pode contradizer o `event_type` ou os campos do `payload`.
- Não é processado por Consumers automatizados — é contexto humano.

---

## 4. Validações

As validações abaixo definem o que torna um Operational Event **registrável** em uma
Timeline. Um evento inválido deve ser rejeitado antes de ser persistido.

### VAL-I-01 — `event_type` referencia tipo Active

O Event Type referenciado em `event_type` deve existir no catálogo (Journey ou Shared) e
ter `lifecycle_status = Active` no momento da emissão. Emitir um evento de tipo Draft,
Proposed, Deprecated ou Removed é inválido.

**Exceção de leitura:** ao processar Timelines históricas, Consumers devem reconhecer
eventos com tipos Deprecated ou Removed como válidos — a validação se aplica somente
ao momento da emissão, não à leitura histórica.

### VAL-I-02 — `work_item_id` referencia Work Item existente

O Work Item identificado por `work_item_id` deve existir. Um evento não pode ser registrado
para um Work Item inexistente.

### VAL-I-03 — `timestamp` com formato e timezone válidos

O `timestamp` deve estar em formato ISO 8601 com timezone explícito. Timestamps sem
timezone são inválidos.

### VAL-I-04 — `producer_type` é valor válido

O `producer_type` deve ser um dos três valores canônicos: `Human`, `System`, `Agent`.

### VAL-I-05 — `producer_identity` não é vazio

O campo `producer_identity` deve estar presente e não ser uma string vazia. Todo evento
deve ter uma identidade de Producer rastreável (P-03 da Fundação OEM; INV-04 da Ontologia).

### VAL-I-06 — `id` é globalmente único

O `id` do evento deve ser único entre todos os eventos de todas as Timelines — não apenas
dentro da Timeline do Work Item corrente.

### VAL-I-07 — `timestamp` respeita a propriedade append-only

O `timestamp` do novo evento deve ser maior ou igual ao `timestamp` do último evento
registrado na mesma Timeline. Eventos com timestamp anterior ao último evento são rejeitados
— a Timeline é append-only e cronologicamente ordenada.

### VAL-I-08 — `payload` satisfaz `payload_shape` do Event Type

Quando o Event Type declara `payload_shape`, o payload do evento deve incluir todos os
campos obrigatórios do `payload_shape`. Campos ausentes que são obrigatórios invalidam
o registro.

### VAL-I-09 — `producer_type` está em `producer_subtypes` do Event Type

O `producer_type` registrado deve ser um dos valores declarados em `producer_subtypes`
pelo Event Type referenciado. Um evento emitido por Producer não autorizado viola o contrato
do Event Type.

**Nota:** esta validação pode ser executada de forma permissiva (registrar com alerta em
vez de rejeitar) quando o sistema não tem acesso ao catálogo no momento da emissão — nesse
caso, a Diligence detecta a anomalia retroativamente.

### VAL-I-10 — `schema_version` corresponde a versão conhecida

O `schema_version` deve corresponder a uma versão publicada do Instance Schema. Versões
desconhecidas não são necessariamente inválidas — mas devem ser tratadas com caution por
Consumers.

---

## 5. Imutabilidade

### 5.1 Por que um Operational Event nunca pode ser alterado

A imutabilidade dos eventos é a propriedade mais fundamental do Operational Event Model —
mais fundamental que qualquer outra regra deste Schema.

O motivo é ontológico: um Operational Event registra um **fato que ocorreu**. Fatos não
podem ser desfeitos. `Bootstrap.Completed` ocorreu às 09:15:00 do dia 24 de julho de 2026
para o Work Item WI-042. Esse fato é parte permanente da história operacional do Work Item.
Modificar o registro seria criar uma história falsa — uma Timeline que afirma que o
acontecimento ocorreu de forma diferente do que realmente ocorreu.

Além do aspecto ontológico, a imutabilidade tem três consequências práticas fundamentais:

**1. Integridade do Derived State:** o Derived State é uma projeção da Timeline. Se um
evento puder ser alterado, o Derived State calculado antes da alteração pode diferir do
calculado depois — tornando o estado passado irreconstruível de forma confiável.

**2. Confiabilidade da auditoria:** a Diligence verifica consistência entre a Timeline e
a COR. Se eventos puderem ser alterados, a Diligence não pode garantir que a Timeline
que verifica é a mesma que produziu o estado que está na COR.

**3. Equivalência entre registro e evidência:** a evidência intrínseca de um evento é o
próprio registro. Se o registro puder ser alterado, a evidência pode ser alterada — o
que invalida a trilha de auditoria.

### 5.2 Como lidar com erros de registro

Quando um evento foi registrado com dados incorretos, o caminho correto é **emitir um
novo evento** — nunca editar o original. Existem dois padrões:

---

**Padrão A — Evento de Correction**

Para erros em campos do `payload` ou em `notes`, o Producer emite um evento do tipo
`Event.Corrected` (Category: Correction, `alters_state = false`).

O `Event.Corrected` referencia o `id` do evento com erro em seu payload e documenta
o que estava incorreto e qual o valor correto:

```
id:                ev-corrected-789
event_type:        Event.Corrected
work_item_id:      WI-042
timestamp:         2026-07-24T09:30:00Z
producer_type:     Human
producer_identity: christiano.milfont
schema_version:    1.0.0
payload:
  corrected_event_id: ev-original-456
  correction_note:    "branch_name registrado como 'main' — correto é 'feat/checkout-redesign'"
```

O evento original (`ev-original-456`) permanece imutável na Timeline. Consumers que
processam a Timeline devem verificar a presença de eventos `Event.Corrected` e aplicar
a correção semanticamente no processamento.

---

**Padrão B — Evento de revisão de estado**

Para erros que afetaram o Derived State (ex.: o evento declarou `new_state = DONE` mas
o Work Item não deveria ter fechado), o Producer emite um novo evento que reverte o estado:

```
id:                ev-reopen-890
event_type:        Rework.Declared
work_item_id:      WI-042
timestamp:         2026-07-24T09:35:00Z
producer_type:     Human
producer_identity: christiano.milfont
schema_version:    1.0.0
payload:
  reason: "Fechamento prematuro — critérios de done não satisfeitos"
notes:             "Reverte o DONE incorreto registrado em ev-original-456"
```

O estado errado (`DONE`) foi o Derived State por um período — isso é parte da história.
O novo evento (`Rework.Declared`) registra que o estado mudou novamente — a Timeline
preserva a realidade: o Work Item passou por DONE, mas foi reaberto.

---

**O que nunca é válido:**
- Editar qualquer campo de um evento já registrado
- Deletar um evento da Timeline
- Reordenar eventos na Timeline
- Substituir o `id` de um evento por outro

---

## 6. Relação com o Event Type

### 6.1 Contrato × Ocorrência

O Event Type e o Operational Event existem em planos diferentes e têm responsabilidades
complementares:

| Dimensão | Event Type (contrato) | Operational Event (ocorrência) |
|---|---|---|
| **O que define** | O que *pode* acontecer | O que *aconteceu* |
| **Existe em** | Catálogo (atemporal) | Timeline (posicionado no tempo) |
| **Criado por** | Journey architect / Framework | Producer (Human, System, Agent) |
| **Aprovado por** | Governança da Journey ou Framework | Não precisa de aprovação |
| **Quantidade** | Um por classe de acontecimento | Zero ou N por Event Type |
| **Mutabilidade** | Campos imutáveis após Active; `lifecycle_status` muda | Absolutamente imutável |

### 6.2 Como a instância satisfaz o contrato

Um Operational Event satisfaz o contrato do Event Type quando:

1. **`event_type`** referencia o nome do tipo corretamente
2. **`producer_type`** está na lista `producer_subtypes` do tipo (VAL-I-09)
3. **`payload`** satisfaz o `payload_shape` do tipo (VAL-I-08)
4. As **precondições** do tipo eram verdadeiras no momento da emissão — verificação
   de responsabilidade do Producer; a Diligence pode verificar retroativamente
5. As **pós-condições** do tipo passam a ser verdadeiras após o registro — verificação
   de responsabilidade da Diligence e dos Consumers

### 6.3 Dependência unidirecional

A dependência entre os Schemas é estritamente unidirecional:

```
Event Type Schema ──(define contrato para)──→ Operational Event Instance
```

O Event Type Schema não conhece as instâncias. O Operational Event referencia o tipo pelo
nome — e o tipo permanece válido como referência mesmo que venha a ser Deprecated ou
Removed (a Timeline é imutável; o histórico é preservado).

### 6.4 O Event Type é consultado, nunca copiado

Quando um Consumer processa uma Timeline e precisa de `category`, `alters_state` ou
`new_state` de um evento, ele consulta o catálogo usando o `event_type` do evento como
chave — ele não espera encontrar esses campos no evento registrado.

Se um Consumer desnormalizar campos derivados por eficiência (copiar `category` e
`alters_state` no evento), esses campos são cópias de leitura — a fonte de verdade
permanece o catálogo de Event Types. Em caso de conflito, o catálogo prevalece.

---

## 7. Exemplos

Os exemplos ilustram Operational Events válidos. O formato de serialização concreto
é definido pela implementação — não por este Schema.

### 7.1 Evento mínimo válido

```
id:                ev-bs-001-started
event_type:        Bootstrap.Started
work_item_id:      WI-042
timestamp:         2026-07-24T09:00:00Z
producer_type:     Human
producer_identity: christiano.milfont
schema_version:    1.0.0
```

### 7.2 Evento completo com payload e evidência

```
id:                ev-bs-001-completed
event_type:        Bootstrap.Completed
work_item_id:      WI-042
timestamp:         2026-07-24T09:15:00Z
producer_type:     Agent
producer_identity: hack-start-agent
schema_version:    1.0.0
sequence_number:   2
payload:
  branch_name:   feat/checkout-redesign
  base_commit:   a3f9c12
  smoke_passed:  true
evidence_references:
  - uri:         https://github.com/org/repo/tree/feat/checkout-redesign
    description: "Branch criado com sucesso para o Work Item WI-042"
notes:             "Smoke gate passou em 3s — dentro do threshold aceitável"
```

### 7.3 Evento de gate que não altera estado

```
id:                ev-gate-smoke-001
event_type:        Gate.Passed
work_item_id:      WI-042
timestamp:         2026-07-24T09:14:57Z
producer_type:     System
producer_identity: github-actions
schema_version:    1.0.0
sequence_number:   1
payload:
  gate_name: smoke-test
  duration_ms: 3241
evidence_references:
  - uri:         https://github.com/org/repo/actions/runs/12345
    description: "Execução do workflow de smoke test"
```

### 7.4 Evento de correção

```
id:                ev-correction-001
event_type:        Event.Corrected
work_item_id:      WI-042
timestamp:         2026-07-24T10:00:00Z
producer_type:     Human
producer_identity: christiano.milfont
schema_version:    1.0.0
payload:
  corrected_event_id: ev-bs-001-completed
  correction_note:    "branch_name registrado como 'main' — correto é 'feat/checkout-redesign'"
```

### 7.5 Sequência mínima de Timeline (três eventos)

```
Timeline: WI-042
──────────────────────────────────────────────────────────────
seq 1 | 09:00:00Z | Bootstrap.Started   | Human: christiano
seq 2 | 09:14:57Z | Gate.Passed         | System: github-actions
seq 3 | 09:15:00Z | Bootstrap.Completed | Agent:  hack-start-agent
──────────────────────────────────────────────────────────────
Derived State atual: HACKING (last alters_state = true → Bootstrap.Completed)
```

---

## Referências

- [Fundação OEM](README.md)
- [Ontologia OEM](ontology.md)
- [Taxonomia OEM](taxonomy.md)
- [Lifecycle OEM](lifecycle.md)
- [Event Type Schema](event-type-schema.md)
- Decisão de separação dos Schemas

---

*Este documento é a fonte canônica da estrutura de um Operational Event registrado em uma
Operational Timeline. Todo Producer que emite eventos e todo Consumer que processa Timelines
deve satisfazer este Schema.*
