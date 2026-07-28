# Relatório — Operational Event Instance Schema
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Formalização de Schema — exclusivamente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/event-instance-schema.md`

---

## 1. Executive Summary

O Operational Event Instance Schema foi formalizado como o contrato que define a estrutura
de todo evento registrado em uma Operational Timeline.

| Item | Resultado |
|---|---|
| Campos obrigatórios | 7 |
| Campos opcionais | 4 |
| Campos derivados | 5 (computáveis, não armazenados no evento) |
| Validações (VAL-I) | 10 (VAL-I-01 a VAL-I-10) |
| Padrões de correção documentados | 2 (Correction event; revisão de estado) |
| Exemplos canônicos | 5 (mínimo, completo, gate, correção, sequência de Timeline) |
| Documentos criados | 2 (`event-instance-schema.md` + este relatório) |
| Documentos alterados | 0 |
| Conceitos arquiteturais novos introduzidos | 0 |
| Decisões anteriores alteradas | Nenhuma |

---

## 2. Principais Decisões

### DEC-EI-01 — `id` deve ser globalmente único (não apenas por Timeline)

**Decisão:** o `id` de um Operational Event deve ser único entre todos os eventos de todas
as Timelines — não apenas dentro da Timeline do Work Item corrente.

**Justificativa:** Events de Timelines diferentes podem ser referenciados em contextos
cross-Timeline — por eventos de Correction que corrigem registros em outra sessão, por
métricas que agregam eventos de múltiplos Work Items, por investigações da Diligence que
cruzam Timelines. Se `id` fosse único apenas dentro da Timeline, um `id` como `ev-001`
existiria em dezenas de Timelines simultaneamente — tornando referências cross-Timeline
ambíguas.

A unicidade global elimina a ambiguidade sem custo adicional: a geração de identificadores
únicos globais (UUID v4, ULID) é trivial.

---

### DEC-EI-02 — `timestamp` admite igualdade com o último evento (≥, não >)

**Decisão:** o `timestamp` de um novo evento deve ser ≥ ao `timestamp` do último evento
registrado na Timeline — não necessariamente estritamente maior.

**Justificativa:** acontecimentos simultâneos ou em rápida sucessão dentro da resolução
do relógio do sistema (ex.: dois eventos no mesmo segundo) devem ser registráveis. Exigir
estritamente maior forçaria a inserção de latência artificial ou a falsificação de
timestamps para garantir unicidade temporal — o que violaria a fidelidade histórica.

**Como a ordem é resolvida:** o `sequence_number` é o desempatador autoritativo quando
dois eventos têm o mesmo `timestamp`. Sequence_number é atribuído pela infraestrutura de
registro no momento da inserção — não é falsificável pelo Producer.

---

### DEC-EI-03 — `producer_identity` e `producer_type` são campos separados

**Decisão:** o Producer é representado por dois campos distintos: `producer_type` (enum
categórico) e `producer_identity` (string de identidade específica).

**Justificativa:** os dois campos têm propósitos distintos:

- `producer_type` é usado por Consumers para filtrar e agregar eventos por categoria de
  origem (ex.: "quantos eventos foram emitidos por Agents vs. Humans em determinada Phase?").
  Requer valor de enum estável e limitado.

- `producer_identity` é usado para auditoria e rastreabilidade específica (ex.: "qual
  usuário específico aprovou este Gate?"). Requer string livre para acomodar qualquer
  formato de identidade — login, email, nome de sistema.

Combinar os dois em um campo único (`producer: "Human:christiano.milfont"`) forçaria
parsing adicional em todos os Consumers que precisam de apenas um dos dois aspectos.

---

### DEC-EI-04 — `schema_version` é obrigatório no evento registrado

**Decisão:** o `schema_version` é um campo obrigatório de todo evento — não um metadado
externo inferível do contexto de registro.

**Justificativa:** Timelines são imutáveis e podem conter eventos registrados ao longo de
anos. Quando o Instance Schema evolui, Consumers que leem Timelines antigas precisam saber
qual versão do Schema estava em vigor para interpretar os campos corretamente.

Se `schema_version` fosse inferível apenas do período de registro (ex.: "eventos registrados
antes de 2026-10 usam v1.0.0"), qualquer imprecisão de data tornaria a interpretação
histórica ambígua. Ter o `schema_version` inline no evento elimina a ambiguidade — o
evento carrega seu próprio contrato de interpretação.

---

### DEC-EI-05 — Campos derivados não são armazenados no evento

**Decisão:** `timeline_id`, `category`, `alters_state`, `new_state` e `evidence_intrinsic`
são derivados — não são armazenados no evento registrado.

**Justificativa:** armazenar campos derivados no evento cria dois problemas:

1. **Duplicação com risco de divergência:** se `category` estiver no evento e o catálogo
   de Event Types for atualizado (por migration de Schema), o campo no evento pode divergir
   do catálogo. Qual prevalece? A Ontologia diz que o catálogo é a fonte de verdade — mas
   o evento é imutável. A contradição não tem resolução limpa.

2. **Desnecessidade:** Consumers que precisam de `category` fazem um lookup pelo `event_type`
   no catálogo. Esse lookup é a operação natural — não um overhead. Desnormalizar é uma
   otimização de implementação, não uma necessidade de Schema.

**Permissão de desnormalização:** o Schema **permite** que implementações desnormalizem
campos derivados por eficiência, desde que os campos sejam marcados como `[derived]` e
tratados como read-only redundantes. A fonte de verdade permanece o catálogo.

---

### DEC-EI-06 — `sequence_number` é opcional (não obrigatório)

**Decisão:** `sequence_number` é opcional — recomendado, mas não exigido para validade.

**Justificativa:** o `sequence_number` é derivável da posição do evento na Timeline. Torná-lo
obrigatório exigiria que toda implementação de Producer — incluindo as mais simples —
rastreasse a posição atual da Timeline antes de cada emissão. Isso introduziria acoplamento
entre o Producer e o estado da Timeline no momento da emissão.

Ao torná-lo opcional, o Schema permite implementações onde a ordenação é resolvida
inteiramente pelo `timestamp` (em Timelines de baixo volume onde colisões de timestamp
são improváveis) e implementações que o atribuem explicitamente para resolver colisões.

**Recomendação:** em implementações onde múltiplos Producers podem emitir para a mesma
Timeline simultaneamente (risco de colisão de timestamp), o `sequence_number` é fortemente
recomendado.

---

### DEC-EI-07 — VAL-I-09 pode ser permissiva (alerta, não rejeição)

**Decisão:** a validação de que `producer_type` está em `producer_subtypes` do Event Type
(VAL-I-09) pode ser executada de forma permissiva — registrar o evento com alerta em vez
de rejeitá-lo — quando o sistema não tem acesso ao catálogo no momento da emissão.

**Justificativa:** em cenários onde o Producer emite eventos de forma assíncrona ou
offline, o catálogo pode não estar acessível no momento da emissão. Rejeitar o evento
nesses casos causaria lacunas na Timeline — o que viola P-07 (toda ocorrência relevante
deve ser registrada).

A Diligence detecta anomalias de `producer_type` retroativamente ao auditar a Timeline.
O registro do evento com alerta é preferível ao não-registro.

---

### DEC-EI-08 — Dois padrões de correção: Correction event e revisão de estado

**Decisão:** o documento formaliza dois padrões distintos de correção — não um único
mecanismo.

**Justificativa:** os erros que podem ocorrer têm naturezas distintas:

**Padrão A (Correction event):** para erros em `payload` ou `notes` — campos que não
afetam o Derived State. O evento `Event.Corrected` registra o que estava errado e o valor
correto, sem emitir um novo evento de mudança de estado. O Derived State não é afetado
pela correção.

**Padrão B (revisão de estado):** para erros que afetaram o Derived State — ex.: um Work
Item foi fechado (estado DONE) antes de satisfazer os critérios de done. A correção não
é um `Event.Corrected` (que não altera estado) — é um novo evento funcional (ex.:
`Rework.Declared`) que move o Work Item de volta ao estado correto.

A distinção é importante porque o Padrão B preserva a realidade: o Work Item esteve no
estado DONE por um período — isso é parte da história. O novo evento registra a transição
de volta — não apaga o erro.

---

## 3. Comparação com o Event Type Schema

| Dimensão | Event Type Schema | Instance Schema |
|---|---|---|
| Sujeito | Event Type (definição) | Operational Event (ocorrência) |
| Campos que definem identidade | `name` | `id` |
| Campos de governança | `lifecycle_status`, `introduced_in`, `deprecated_in` | `schema_version` |
| Campos de semântica | `preconditions`, `postconditions`, `alters_state` | `payload`, `evidence_references` |
| Campos temporais | `introduced_in` (versão do catálogo, não timestamp) | `timestamp` (ISO 8601) |
| Campos de Producer | `producer_subtypes` (quem *pode* emitir) | `producer_type` + `producer_identity` (quem *emitiu*) |
| Mutabilidade geral | `lifecycle_status` muda; restante imutável | Absolutamente imutável |
| Quantidade de validações | 12 (VAL-01 a VAL-12) | 10 (VAL-I-01 a VAL-I-10) |

---

## 4. Mapa das 10 Validações

| Validação | Campo(s) | Momento de execução | Permissiva? |
|---|---|---|---|
| VAL-I-01 (event_type ativo) | `event_type` | Pré-registro | Não |
| VAL-I-02 (work_item_id existe) | `work_item_id` | Pré-registro | Não |
| VAL-I-03 (timestamp com timezone) | `timestamp` | Pré-registro | Não |
| VAL-I-04 (producer_type válido) | `producer_type` | Pré-registro | Não |
| VAL-I-05 (producer_identity não vazio) | `producer_identity` | Pré-registro | Não |
| VAL-I-06 (id globalmente único) | `id` | Pré-registro | Não |
| VAL-I-07 (timestamp append-only) | `timestamp` + Timeline | Pré-registro | Não |
| VAL-I-08 (payload satisfaz payload_shape) | `payload` | Pré-registro | Não |
| VAL-I-09 (producer_type em producer_subtypes) | `producer_type` + Event Type | Pré-registro | Sim (alerta) |
| VAL-I-10 (schema_version conhecido) | `schema_version` | Pré-registro + leitura | Sim (alerta) |

### 4.1 Validações que não rejeitem o evento

VAL-I-09 e VAL-I-10 são as únicas validações permissivas — elas geram alertas mas não
rejeitam o evento. A razão em ambos os casos é que a rejeição causaria lacunas na Timeline
quando a causa do problema é externa ao Producer (catálogo inacessível, Schema desconhecido).

A Diligence é responsável por detectar e sinalizar as anomalias decorrentes dessas validações
permissivas.

---

## 5. Relação com a Imutabilidade da Ontologia

Os invariantes INV-01 e INV-02 da Ontologia são materializados neste Schema da seguinte forma:

| Invariante da Ontologia | Materialização no Instance Schema |
|---|---|
| **INV-01** (eventos imutáveis) | Todos os campos são `Pode ser alterado: não`; Seção 5 explica o protocolo de correção por novos eventos |
| **INV-02** (Timeline append-only) | VAL-I-07 exige `timestamp >= último evento`; `sequence_number` é estritamente crescente |
| **INV-03** (Timeline única por Work Item) | `work_item_id` é chave do evento — um evento pertence a exatamente um Work Item |
| **INV-04** (Producer obrigatório) | `producer_type` e `producer_identity` são obrigatórios; VAL-I-05 garante não-nulidade |
| **INV-06** (COR não é fonte de verdade) | Não referenciado no Instance Schema — a Timeline é a fonte de verdade, COR é materialização |
| **INV-09** (Timeline prevalece) | Em conflito entre `evidence_references` e Timeline, a Timeline prevalece |
| **INV-10** (correções são eventos) | Seção 5 formaliza os dois padrões de correção como eventos — nunca edições |

---

## 6. Relação com os Documentos Futuros

| Documento | Como usa o Instance Schema |
|---|---|
| `events/shared-types.md` | Não usa diretamente — Shared Types são Event Types (Event Type Schema) |
| `journeys/*/events/catalog.md` | Não usa diretamente — catálogos são conjuntos de Event Types |
| `events/timeline.md` (futuro) | Usa o Instance Schema para descrever formalmente a composição de uma Timeline (sequência de Operational Events) |
| Diligence engine | Usa VAL-I-01 a VAL-I-10 para auditar Timelines; usa `event_type` para cruzar com catálogo |
| Producers (Skills, Steps) | Usam o Instance Schema para saber o que preencher ao emitir um evento |
| Assessment | Usa o Instance Schema para processar Timelines e calcular métricas |

---

## 7. Posição na Sequência Documental

O Instance Schema ocupa a posição 6a na sequência definitiva (em paralelo com Shared Types):

| Posição | Documento | Depende de |
|---|---|---|
| 1 | README.md | — |
| 2 | ontology.md | README |
| 3 | taxonomy.md | ontology |
| 4 | lifecycle.md | taxonomy |
| 5 | event-type-schema.md | lifecycle |
| **6a** | **event-instance-schema.md** | **event-type-schema** |
| 6b | shared-types.md | event-type-schema |
| 7 | journey catalogs | event-type-schema + shared-types |

Com os dois Schemas definidos (posições 5 e 6a), a base conceitual do OEM está completa.
Os documentos restantes (6b e 7) são catálogos — instâncias do Event Type Schema.

---

## 8. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado e materializado neste Schema |
| Operational Timeline como fonte primária de verdade | Preservado — Timeline é sequência de instâncias deste Schema |
| Derived State como projeção da Timeline | Preservado — `alters_state` e `new_state` são derivados do Event Type referenciado |
| Event Category como catálogo fixo do Framework | Preservado — `category` é campo derivado do Event Type |
| Separação Event Type Schema / Instance Schema | Concluída — Instance Schema define ocorrências; Event Type Schema define contratos |
| Imutabilidade dos eventos (INV-01, INV-02) | Preservado — todos os campos são imutáveis; protocolo de correção por novos eventos |
| Producer obrigatório (INV-04, P-03) | Preservado — `producer_type` e `producer_identity` são obrigatórios |
| COR como consumidora do OEM | Preservado — não referenciada no Instance Schema |
| Diligence como verificadora de consistência | Preservado — VAL-I-09 permissiva é detectada retroativamente pela Diligence |
| README.md não alterado | Confirmado |
| ontology.md não alterado | Confirmado |
| taxonomy.md não alterado | Confirmado |
| lifecycle.md não alterado | Confirmado |
| event-type-schema.md não alterado | Confirmado |
| Nenhuma Journey alterada | Confirmado |
| Nenhum Skill alterado | Confirmado |
| Nenhum manifest alterado | Confirmado |
| Shared Types não criados | Confirmado |
| Delivery Catalog não criado | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 9. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/events/event-instance-schema.md` | ~350 | Contrato canônico do Operational Event |
| `prodops/documentation-review-event-instance-schema.md` | Este arquivo | Relatório de formalização |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 10. Próximos Passos Sugeridos

Com os dois Schemas concluídos, a base do OEM está completa:

| Documento | Prioridade | Raciocínio |
|---|---|---|
| `events/shared-types.md` | Alta | Catálogo de tipos compartilhados — agora existe o Schema para preenchê-lo |
| `journeys/delivery/events/catalog.md` | Alta | 83 tipos propostos — o Schema está pronto; é o caso de uso mais maduro |
| `events/timeline.md` | Média | Formaliza a composição e comportamento da Timeline (projeção de Derived State, processamento de Correction) |
| `journeys/diligence/events/catalog.md` | Média | Após o catálogo Delivery estar estável |
