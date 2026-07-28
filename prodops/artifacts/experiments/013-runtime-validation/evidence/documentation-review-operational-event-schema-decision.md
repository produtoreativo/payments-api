# Decisão Arquitetural — Separação dos Schemas do OEM
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Decisão arquitetural — exclusivamente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/`

---

## 1. Executive Summary

**Decisão:** o Operational Event Model deve possuir **dois Schemas independentes**.

| Schema | Sujeito | Natureza |
|---|---|---|
| **Event Type Schema** | Event Type | Contrato — define o que pode ocorrer |
| **Operational Event Instance Schema** | Operational Event | Registro — captura o que ocorreu |

Os dois conceitos têm responsabilidades radicalmente distintas, públicos consumidores
diferentes, regras de mutabilidade assimétricas e atributos que não se sobrepõem —
tornando a separação arquiteturalmente necessária, não apenas conveniente.

Nenhuma decisão anterior foi alterada por esta análise.

---

## 2. Pergunta 1 — Existe justificativa arquitetural para a separação?

### 2.1 Resposta direta

Sim. A justificativa é ontológica antes de ser técnica: Event Type e Operational Event
pertencem a categorias fundamentalmente diferentes de existência.

**Event Type** é uma definição — existe fora do tempo, no espaço das possibilidades
operacionais. Define o contrato para que um evento de determinada classe possa ser emitido.

**Operational Event** é uma ocorrência — existe em um instante irreversível no tempo,
no espaço dos fatos registrados. É a materialização concreta de um Event Type em um
momento específico, sobre um Work Item específico.

A diferença não é de grau, é de tipo. Confundi-los em um único Schema seria o equivalente
a colocar a definição de uma classe e a instância de um objeto no mesmo contrato: os campos
têm significados, mutabilidades e consumidores radicalmente diferentes.

### 2.2 As cinco justificativas arquiteturais

---

**J1 — Assimetria de mutabilidade**

Event Types têm um ciclo de vida gerenciado: transitam por estados (Draft → Active →
Deprecated → Removed). Mesmo quando Active, suas propriedades críticas são imutáveis —
mas seu `lifecycle_status` muda.

Operational Events são absolutamente imutáveis desde o momento do registro (INV-01 e
INV-02 da Ontologia). Não há "ciclo de vida" de uma instância — ela acontece e permanece
exatamente como foi registrada para sempre.

Em um único Schema, seria necessário declarar que alguns campos (os do Event Type) são
mutáveis-com-regras e outros (os do Operational Event) são imutáveis-absolutamente. Essa
contradição interna é uma violação de coesão: um Schema deve governar campos com a mesma
natureza de mutabilidade.

---

**J2 — Separação temporal**

Event Types existem antes dos eventos que instanciam. O Event Type `Bootstrap.Started`
existe desde o momento em que foi aprovado — independentemente de qualquer Work Item ter
passado pelo Bootstrap. Ele é uma entidade atemporal: não tem timestamp de ocorrência,
não pertence a um Work Item, não está posicionado em uma Timeline.

Operational Events existem em um instante específico. `Bootstrap.Started` emitido às
2026-07-24T09:15:00Z para o Work Item WI-042 é um fato singular, irrepetível naquele
instante exato. Sua existência é inseparável do timestamp.

Um Schema que tenta capturar simultaneamente "o que pode ocorrer" (atemporal) e "o que
ocorreu" (temporal específico) mistura dois planos ontológicos distintos.

---

**J3 — Públicos consumidores disjuntos**

| Consumidor | Consome | Para quê |
|---|---|---|
| Journey architect | Event Type Schema | Definir novos tipos, verificar conformidade |
| Framework governance | Event Type Schema | Aprovar promoções, auditar catálogos |
| Skills / Steps | Event Type Schema | Saber *o que* emitir e *quando* (precondições) |
| Timeline processor | Instance Schema | Reconstruir Derived State a partir de eventos |
| Diligence engine | Instance Schema | Verificar consistência Timeline vs. COR |
| Metrics engine | Instance Schema | Calcular DORA e métricas derivadas |
| Assessment | Instance Schema | Analisar padrões históricos entre Timelines |
| Agents | Ambos | Consultar tipo para decidir emissão; registrar a instância |

O conjunto de consumidores do Event Type Schema e o conjunto de consumidores do Instance
Schema são quase disjuntos. Somente Agents consomem ambos — e eles os consomem em momentos
e propósitos distintos (consulta de contrato antes da emissão; registro da instância depois).

---

**J4 — Polimorfismo de payload**

O Operational Event tem um campo `payload` que é polimórfico: seu conteúdo depende do
Event Type emitido. `Bootstrap.Started` pode ter `{ branch: string, base_commit: string }`
enquanto `Gate.Failed` pode ter `{ gate_name: string, reason: string, evidence_url: string }`.

O Event Type Schema é quem define o shape do payload esperado para cada tipo — é parte do
contrato que o tipo representa.

O Instance Schema declara que `payload` existe e que é um objeto — mas não pode definir
sua estrutura específica sem referenciar o Event Type correspondente.

Esta dependência unidirecional (Instance Schema referencia Event Type Schema) é mais uma
evidência de que os dois são entidades distintas, onde uma é o contrato e a outra é a
instância que satisfaz o contrato.

---

**J5 — Governança independente**

A governança do Event Type é exercida pela Journey (para Journey Types) ou pelo Framework
(para Shared Types). O processo de aprovação envolve: verificação de duplicatas, análise
de nomenclatura, revisão de categoria, aprovação formal.

A governança do Operational Event é exercida pela Timeline: o evento é registrado uma vez,
de forma atômica, e nunca é alterado. Não há "aprovação" de uma instância — ela é emitida
por um Producer e append-only na Timeline.

Colocar ambos em um único Schema implica que um único conjunto de regras de governança se
aplicaria a entidades com processos de governança completamente diferentes.

### 2.3 Conclusão da Pergunta 1

A separação é arquiteturalmente necessária por cinco razões independentes, cada uma
suficiente por si só:

1. Assimetria de mutabilidade irreconciliável
2. Separação temporal ontológica
3. Conjuntos de consumidores quase disjuntos
4. Polimorfismo de payload que só pode ser definido no contrato (Type)
5. Regras de governança completamente distintas

---

## 3. Pergunta 2 — Comparação detalhada: Event Type vs. Operational Event

### 3.1 O que cada conceito representa

| Dimensão | Event Type | Operational Event |
|---|---|---|
| **Natureza** | Classe — abstração | Instância — concretização |
| **Existe em** | Catálogo | Timeline |
| **Posição no tempo** | Atemporal (definição) | Temporal (instante específico) |
| **Escopo** | Journey / Framework | Work Item específico |
| **Criado por** | Journey architect / Framework | Producer (Human, System, Agent) |
| **Aprovado por** | Governança (Journey ou Framework) | Ninguém — é registrado diretamente |
| **Mutabilidade** | Imutável após Active; lifecycle_status pode mudar | Absolutamente imutável |
| **Cardinalidade** | Um tipo → zero ou N eventos (instâncias) | Um evento → exatamente um tipo |
| **Propósito** | Descrever o que *pode* ocorrer | Registrar o que *ocorreu* |
| **Validade** | Termina com Removed (mas persiste como histórico) | Nunca termina (imutável) |

### 3.2 Analogia para clareza

Event Type está para Operational Event assim como:

- **Classe** está para **objeto** (POO)
- **Esquema de formulário** está para **formulário preenchido**
- **Regra** está para **fato jurídico**
- **Contrato** está para **transação que satisfaz o contrato**

Em todos esses casos, confundir o template com a instância seria um erro conceitual
fundamental. A separação não é apenas conveniente — é a consequência direta de reconhecer
que os dois conceitos existem em planos ontológicos diferentes.

### 3.3 A dependência unidirecional

```
Event Type Schema ──(define contrato para)──→ Operational Event Instance
```

A dependência é estritamente unidirecional. Uma instância referencia seu tipo por nome
(`event_type: "Bootstrap.Started"`). O tipo não conhece as instâncias que o satisfazem —
do ponto de vista do Schema, o tipo é um contrato aberto que pode ser instanciado zero
ou N vezes.

Esta unidirecionalidade é uma propriedade das linguagens tipadas: a classe define a
interface; o objeto carrega uma referência à classe — não o contrário.

---

## 4. Pergunta 3 — Arquitetura proposta

### 4.1 Arquitetura recomendada

```
OEM Foundation (README.md)
│  Define: motivação, princípios P-01 a P-10, scope
│
↓
Ontology (ontology.md)
│  Define: 8 conceitos, 16 relações, 12 cardinalidades, 10 invariantes
│  Inclui: Event Type e Operational Event como conceitos distintos
│
↓
Taxonomy (taxonomy.md)
│  Define: 8 Event Categories, naming convention, REG-01 a REG-10
│  Opera sobre: Event Types (não sobre instâncias)
│
↓
Lifecycle (lifecycle.md)
│  Define: como Event Types nascem, evoluem, são promovidos e removidos
│  Opera sobre: Event Types (não sobre instâncias)
│
↓
Event Type Schema (event-type-schema.md)
│  Define: a estrutura formal completa de um Event Type
│  Inclui: todos os campos de definição, governança e lifecycle
│  Consumido por: catálogos, revisões, ferramentas de lint
│
↓
Operational Event Instance Schema (event-instance-schema.md)
│  Define: a estrutura formal de uma ocorrência registrada
│  Inclui: todos os campos de registro, producer, timestamp, payload, evidence
│  Referencia: Event Type Schema (via event_type)
│  Consumido por: Timeline processor, Diligence, métricas, Assessment
│
↓
Shared Types (shared-types.md)
│  Aplica: Event Type Schema para os tipos gerenciados pelo Framework
│  Cada entrada: satisfaz completamente o Event Type Schema
│
↓
Journey Catalogs (journeys/*/events/catalog.md)
│  Aplica: Event Type Schema para os tipos de cada Journey
│  Cada entrada: satisfaz completamente o Event Type Schema
│
↓
Operational Timelines (runtime — não é um documento)
   Composta por: Operational Events que satisfazem o Instance Schema
   Cada evento: referencia um tipo do catálogo (Journey ou Shared)
```

### 4.2 Por que esta arquitetura é superior às alternativas

**Alternativa A — Schema único:**
- Mistura dois planos ontológicos distintos (ver Pergunta 2)
- Campos com regras de mutabilidade contraditórias
- Governança indistinguível entre atributos de definição e de registro
- Rejeitado pelas justificativas J1 a J5

**Alternativa B — Instance Schema depende diretamente dos Catálogos:**
- Cria dependência circular: catálogos precisam do Event Type Schema; Instance Schema
  dependeria dos catálogos para validar `event_type`
- Impede que o Instance Schema seja definido antes dos catálogos existirem
- A referência ao tipo deve ser por identificador (nome), não por estrutura — logo o
  Instance Schema precisa apenas conhecer o formato do identificador, não o catálogo inteiro
- Rejeitado

**Alternativa C — Event Type Schema e Instance Schema em um único documento, seções separadas:**
- Melhor que Schema único, mas ainda mistura governança de dois domínios distintos em
  um arquivo
- Dificulta referências externas ("o catálogo deve satisfazer a Seção 3.2 de events.md"
  é menos preciso que "o catálogo deve satisfazer event-type-schema.md")
- Rejeitado em favor de dois arquivos independentes

---

## 5. Pergunta 4 — Atributos exclusivos do Event Type

*Classificação apenas — sem definição de Schema.*

### 5.1 Atributos de identidade e classificação

| Atributo | Descrição |
|---|---|
| `name` | Identificador único do tipo; segue convenção `[Namespace.]Subject.Action` |
| `category` | Uma das 8 Event Categories da Taxonomia |
| `namespace` | Prefixo de Journey (opcional dentro do catálogo próprio; obrigatório em referências cross-Journey) |
| `description` | Descrição textual do acontecimento que o tipo representa |

### 5.2 Atributos de semântica e comportamento

| Atributo | Descrição |
|---|---|
| `alters_state` | Boolean — se a emissão deste tipo altera o Derived State do Work Item |
| `new_state` | O estado resultante no Derived State após emissão (quando `alters_state = true`) |
| `preconditions` | Condições que devem ser verdadeiras no momento da emissão |
| `postconditions` | Garantias que devem ser verdadeiras após a emissão |
| `producer_subtypes` | Quais subtipos de Producer podem emitir este tipo (Human, System, Agent — ou subconjunto) |
| `payload_shape` | Descrição dos campos esperados no payload da instância (referência ao shape, não ao payload em si) |

### 5.3 Atributos de governança e lifecycle

| Atributo | Descrição |
|---|---|
| `lifecycle_status` | Estado atual: Draft, Proposed, Active, Deprecated, Removed |
| `introduced_in` | Versão do catálogo em que o tipo foi adicionado |
| `deprecated_in` | Versão em que foi depreciado (quando aplicável) |
| `removed_in` | Versão em que foi removido (quando aplicável) |
| `deprecation_reason` | Justificativa textual da depreciação |
| `replacement_type` | Referência ao tipo substituto (quando depreciado ou promovido) |
| `promotion_origin` | Referência ao tipo Journey que originou o Shared Type (somente em tipos compartilhados) |
| `migration_deadline` | Ciclo até o qual emissão do tipo depreciado é tolerada |
| `promoted_by` | Quem aprovou a promoção (Framework) — apenas em Shared Types |
| `owner_journey` | Journey responsável — apenas em Journey Types |

### 5.4 Atributos de auditoria de lifecycle

| Atributo | Descrição |
|---|---|
| `lifecycle_history` | Sequência de transições de estado com data e responsável |

---

## 6. Pergunta 5 — Atributos exclusivos do Operational Event

*Classificação apenas — sem definição de Schema.*

### 6.1 Atributos de identidade

| Atributo | Descrição |
|---|---|
| `id` | Identificador único e imutável da instância — nunca reutilizado |
| `event_type` | Referência ao nome do Event Type que classifica esta instância |
| `sequence_number` | Posição ordinal do evento na Timeline do Work Item |

### 6.2 Atributos de ocorrência

| Atributo | Descrição |
|---|---|
| `timestamp` | Instante exato em que o evento ocorreu (ISO 8601 com timezone) |
| `work_item` | Identificador do Work Item ao qual este evento pertence |
| `timeline_id` | Identificador da Timeline — derivado do Work Item, mas explícito para eficiência |

### 6.3 Atributos de Producer

| Atributo | Descrição |
|---|---|
| `producer_type` | Subtipo do Producer: Human, System, Agent |
| `producer_identity` | Identidade específica do Producer (login, nome do sistema, nome do Agent) |

### 6.4 Atributos de payload e evidência

| Atributo | Descrição |
|---|---|
| `payload` | Dados específicos da ocorrência — estrutura definida pelo Event Type; imutável após registro |
| `evidence_intrinsic` | O próprio registro como evidência auto-gerada (todo evento) |
| `evidence_references` | Lista de artefatos externos referenciados como evidência adicional |

### 6.5 Atributos de integridade

| Atributo | Descrição |
|---|---|
| `schema_version` | Versão do Instance Schema usado no registro (para retrocompatibilidade) |
| `checksum` | Hash de integridade do registro — detecta corrupção sem alterar imutabilidade |

---

## 7. Pergunta 6 — Atributos potencialmente compartilhados

### 7.1 Candidatos identificados

| Campo candidato | Presente no Event Type | Presente no Operational Event | Análise |
|---|---|---|---|
| `name` / `event_type` | `name` (identifica o tipo) | `event_type` (referencia o tipo pelo nome) | **São campos diferentes**: o Type tem o nome como identidade; a instância tem o nome como chave estrangeira. Mesma string — propósitos completamente distintos. |
| `category` | Sim (atributo do tipo) | Derivado (pode ser obtido do tipo) | **Não precisa estar na instância**: `category` é derivável do Event Type referenciado. Incluí-lo na instância seria redundância desnecessária — e violaria DRY no modelo. |
| `alters_state` | Sim (atributo do tipo) | Derivado | Igual ao anterior: derivável do tipo. |
| `description` | Sim (do tipo) | Pode ter `notes` adicionais | São semânticas distintas: o Type tem descrição do acontecimento; a instância pode ter notas contextuais específicas da ocorrência. Não são o mesmo campo. |

### 7.2 Conclusão sobre atributos compartilhados

**Não existem atributos genuinamente compartilhados** — no sentido de que o mesmo campo
tenha exatamente o mesmo propósito nos dois Schemas.

O que existe é:

**Referência por valor:** a instância carrega `event_type: "Bootstrap.Started"` como
chave estrangeira lógica para o Type. O Event Type carrega `name: "Bootstrap.Started"`
como sua identidade. O valor string é o mesmo — o papel é diferente.

**Derivação:** campos como `category` e `alters_state` poderiam ser copiados na instância
por eficiência de leitura (desnormalização). Se isso ocorrer, devem ser marcados como
`[derived]` — não como atributos primários da instância — e o Event Type permanece como
a fonte de verdade.

A decisão de desnormalizar (copiar derivados na instância para eficiência) não é uma
decisão de Schema conceitual — é uma decisão de implementação que pertence a
`event-instance-schema.md`, não a esta análise.

---

## 8. Pergunta 7 — Impactos da separação

### 8.1 Impacto na Taxonomia

**Impacto: neutro — apenas clarificação de escopo.**

A Taxonomia já opera exclusivamente sobre Event Types: define como classificá-los por
Category, como nomeá-los, quais regras devem seguir. A separação formal dos Schemas
confirma que a Taxonomia é um documento do espaço do Event Type Schema — não toca o
Instance Schema.

*Nenhuma mudança necessária na Taxonomia.*

---

### 8.2 Impacto no Lifecycle

**Impacto: neutro — apenas clarificação de escopo.**

O Lifecycle é exclusivamente sobre como Event Types evoluem. A separação confirma que
`lifecycle_status`, `deprecated_in`, `replacement_type` são atributos do Event Type
Schema — não existem no Instance Schema.

A clarificação adicional que a separação traz: quando o Lifecycle diz "o tipo transita
para Removed", o que muda é o campo `lifecycle_status` no catálogo (Event Type Schema),
nunca os eventos registrados com esse tipo (Instance Schema, imutáveis por INV-01).

*Nenhuma mudança necessária no Lifecycle.*

---

### 8.3 Impacto nos Shared Types

**Impacto: positivo — define claramente o que shared-types.md é.**

`shared-types.md` é um catálogo de entradas que satisfazem o Event Type Schema, gerenciadas
pelo Framework. Cada entrada no arquivo é uma instância do Event Type Schema — não do
Instance Schema.

A separação formal clarifica que `shared-types.md` não contém ocorrências de eventos —
contém definições de tipos. Isso tem implicações diretas para quem escreve `shared-types.md`:
os campos obrigatórios são os do Event Type Schema (name, category, alters_state, etc.),
não os do Instance Schema (timestamp, producer, etc.).

*Impacto positivo: shared-types.md tem escopo claramente definido.*

---

### 8.4 Impacto nos Delivery Catalogs

**Impacto: positivo — cada entrada no catálogo é um Event Type, não uma instância.**

Os 83 Event Types identificados na análise da Delivery usam campos como:
- `category`: Phase Lifecycle, Gate, Rework, etc. → atributo do Event Type
- `alters_state`: true/false → atributo do Event Type
- `preconditions`: condições de emissão → atributo do Event Type
- `new_state`: HACKING, SYNCING, etc. → atributo do Event Type

Nenhum desses campos é um atributo de instância. A separação dos Schemas confirma que
os catálogos de Journey são documentos do espaço do Event Type Schema — não misturam
definição com registro.

*Impacto positivo: os 83 tipos propostos já usam corretamente apenas atributos de Event Type.*

---

### 8.5 Impacto na Diligence

**Impacto: significativo — a Diligence consome os dois Schemas em momentos distintos.**

A Diligence opera em dois planos:

**Plano 1 — Verificação de conformidade dos tipos (Event Type Schema):**
- Verificar se todos os Journey Types satisfazem REG-01 a REG-10 da Taxonomia
- Verificar se `lifecycle_status` está correto
- Verificar se tipos depreciados têm `replacement_type` definido
- Verificar se tipos Proposed foram respondidos pelo Framework

**Plano 2 — Verificação de conformidade das Timelines (Instance Schema):**
- Verificar se eventos em Timelines referenciam tipos existentes no catálogo (ativo ou histórico)
- Verificar se eventos emitidos após `deprecated_in` são anomalias
- Verificar se a sequência de eventos é consistente com o Derived State na COR
- Verificar se Producer está sempre presente (INV-04 da Ontologia)

Sem a separação formal, a Diligence teria dificuldade de articular claramente qual plano
está executando — ambos "lidam com eventos". Com a separação, o plano 1 é "verificação do
catálogo de tipos" e o plano 2 é "verificação das instâncias nas Timelines".

*Impacto positivo: separa claramente os dois planos de verificação da Diligence.*

---

### 8.6 Impacto no Assessment

**Impacto: positivo — Assessment opera sobre instâncias, não sobre definições.**

O Assessment analisa padrões históricos entre Timelines: tempo médio por Phase, frequência
de rework, correlação entre eventos de Blocking e atrasos de entrega. Todas essas análises
operam sobre Operational Events (Instance Schema) — não sobre definições de tipos.

A separação formal deixa claro que o Assessment consome exclusivamente o Instance Schema.
Os tipos (Event Type Schema) são usados apenas como metadados de classificação — para
agrupar instâncias por category, por alters_state, etc.

*Impacto positivo: Assessment tem escopo claramente definido no Instance Schema.*

---

## 9. Pergunta 8 — A sequência de documentos está correta?

### 9.1 Sequência proposta na pergunta

```
README → Ontology → Taxonomy → Lifecycle → Event Type Schema
→ Operational Event Instance Schema → Shared Types → Journey Catalogs
```

### 9.2 Avaliação da sequência

**README → Ontology → Taxonomy → Lifecycle:** ✓ Correto.
Esta é a ordem natural de dependência conceitual já estabelecida e canônica. Cada documento
depende do anterior para definições que utiliza.

**Lifecycle → Event Type Schema:** ✓ Correto.
O Event Type Schema define os campos que o Lifecycle já nomeia (`lifecycle_status`,
`deprecated_in`, etc.). Porém a dependência é de realização: o Lifecycle define as regras;
o Schema formaliza os campos que materializam essas regras. A ordem correta é Lifecycle
antes de Event Type Schema — o Lifecycle determina quais campos o Schema deve ter, não
o inverso.

**Event Type Schema → Operational Event Instance Schema:** ✓ Correto.
O Instance Schema referencia o Event Type Schema (via `event_type` como chave). A
dependência é unidirecional: instâncias referenciam tipos, tipos não referenciam instâncias.

**Instance Schema → Shared Types:** ✗ Precisa de ajuste.
Shared Types são entradas que satisfazem o **Event Type Schema** — não o Instance Schema.
A sequência correta é `Event Type Schema → Shared Types`, em paralelo com `Event Type
Schema → Journey Catalogs`.

**Shared Types → Journey Catalogs:** Parcialmente incorreto.
Journey Catalogs podem ser desenvolvidos em paralelo com Shared Types — ambos dependem
do Event Type Schema, mas não entre si. A dependência de Journey Catalogs em Shared Types
existe apenas no sentido de "verificar se o tipo Journey já existe como Shared antes de
criar um Journey Type" — o que é uma regra de governança (REG-01), não uma dependência
de Schema.

### 9.3 Sequência revisada

```
OEM Foundation (README.md)
│
↓
Ontology (ontology.md)
│
↓
Taxonomy (taxonomy.md)
│
↓
Lifecycle (lifecycle.md)
│
↓
Event Type Schema (event-type-schema.md)
│
├──────────────────────────────────────────────────┐
↓                                                  ↓
Operational Event Instance Schema       Shared Types (shared-types.md)
(event-instance-schema.md)                         │
│                                                  │ (em paralelo ou após)
↓                                                  ↓
Operational Timelines (runtime)         Journey Catalogs (journeys/*/events/catalog.md)
```

**A diferença principal:** Shared Types e Instance Schema são **irmãos** na hierarquia —
ambos dependem do Event Type Schema, mas não um do outro. Journey Catalogs dependem do
Event Type Schema (e verificam os Shared Types por governança, não por dependência de Schema).

### 9.4 Sequência definitiva com justificativas

| Posição | Documento | Depende de | Justificativa |
|---|---|---|---|
| 1 | README.md | — | Fundação motivacional e de princípios |
| 2 | ontology.md | README | Formaliza os conceitos que README motiva |
| 3 | taxonomy.md | ontology | Opera sobre Event Category e Event Type (conceitos da Ontologia) |
| 4 | lifecycle.md | taxonomy | Define como Event Types (conceito da Taxonomia) evoluem |
| 5 | event-type-schema.md | lifecycle | Formaliza os campos que Lifecycle e Taxonomy já nomeiam |
| 6a | event-instance-schema.md | event-type-schema | Instance referencia Type; dependência unidirecional |
| 6b | shared-types.md | event-type-schema | Catálogo que satisfaz o Event Type Schema |
| 7 | journey catalogs | event-type-schema + shared-types (verificação) | Catálogos por Journey que satisfazem o Event Type Schema |
| Runtime | Operational Timelines | event-instance-schema + journey catalogs | Compostas por eventos que satisfazem o Instance Schema e referenciam tipos do catálogo |

---

## 10. Pergunta 9 — Riscos e mitigações

### RIS-01 — Duplicação de campos derivados

**Descrição:** a tentação de copiar campos do Event Type na instância por eficiência
(ex.: incluir `category` e `alters_state` diretamente no evento registrado para evitar
lookup no catálogo durante leitura da Timeline).

**Probabilidade:** Alta — é uma otimização natural em implementações de event sourcing.

**Impacto:** Médio — se os campos derivados divergirem do tipo original (por erro ou
atualização descuidada), a consistência é comprometida.

**Mitigação:**
- O Instance Schema deve declarar explicitamente quais campos são primários (imutáveis
  como o evento) e quais são derivados (reproduzíveis do tipo)
- Campos derivados, se incluídos, devem ser marcados `[derived-from-event-type]` e
  tratados como read-only redundantes — não como fontes de verdade
- A Diligence deve verificar que campos derivados são consistentes com o tipo referenciado

---

### RIS-02 — Inconsistência entre catálogo e Timelines ao deprecar tipos

**Descrição:** o tipo é depreciado no catálogo (Event Type Schema muda `lifecycle_status`
para Deprecated), mas Skills continuam emitindo instâncias desse tipo após a `migration_deadline`.

**Probabilidade:** Alta — Skills não são atualizadas atomicamente.

**Impacto:** Médio — instâncias com tipo Deprecated após a deadline são anomalias válidas
para registro mas indesejadas operacionalmente.

**Mitigação:**
- INV-LC-04 já garante que a instância é válida (depreciação nunca altera eventos)
- O Instance Schema deve incluir campo `event_type_status_at_emission` como campo derivado
  opcional — calculado por Diligence ao verificar se o evento foi emitido antes ou depois
  da `migration_deadline`
- Diligence verifica timestamps de instâncias vs. `deprecated_in` do tipo

---

### RIS-03 — Referência a tipo Removed em novas emissões

**Descrição:** um Producer tenta emitir um evento de tipo Removed — seja por bug em
Skills não atualizadas, seja por referência a catálogo desatualizado.

**Probabilidade:** Baixa — o lifecycle.md exige critérios objetivos antes de remover.

**Impacto:** Alto — o Instance Schema deve rejeitar a emissão; se não rejeitar, a Timeline
conterá um evento inválido.

**Mitigação:**
- O Instance Schema deve incluir regra de validação: `event_type` deve referenciar um
  tipo com `lifecycle_status` Active no momento da emissão
- Esta regra é uma responsabilidade do Instance Schema — não do Type Schema
- Tipos Removed persistem no catálogo histórico para leitura; o Instance Schema distingue
  "tipo válido para emissão" (Active) de "tipo válido para leitura histórica" (qualquer status)

---

### RIS-04 — Governança ambígua entre os dois Schemas

**Descrição:** não está claro quem aprova mudanças no Event Type Schema vs. no Instance
Schema — o mesmo processo de governança se aplica a ambos?

**Probabilidade:** Média — enquanto os Schemas não existirem formalmente, a questão não
se coloca.

**Impacto:** Médio — mudanças no Event Type Schema afetam todos os catálogos; mudanças
no Instance Schema afetam todos os Producers e Consumers.

**Mitigação:**
- Event Type Schema: governado pelo Framework (mesma governança das Event Categories)
- Instance Schema: governado pelo Framework com consulta obrigatória à Diligence e aos
  Consumers ativos (mudanças no Instance Schema afetam o processamento de Timelines)
- Os dois Schemas têm processos de aprovação independentes — refletindo a independência
  dos domínios

---

### RIS-05 — Evolução do payload shape sem versionamento

**Descrição:** o `payload_shape` de um Event Type muda (novos campos obrigatórios adicionados)
sem que as Timelines históricas com instâncias do tipo antigo sejam invalidadas.

**Probabilidade:** Alta — payloads evoluem naturalmente.

**Impacto:** Alto — Consumers que esperam o payload shape novo falham ao processar eventos
históricos com o payload antigo.

**Mitigação:**
- A regra já está implícita em INV-TAX-01 (tipos imutáveis após Active): mudanças no
  `payload_shape` exigem deprecar o tipo e criar um novo
- O Event Type Schema deve tornar esta regra explícita: `payload_shape` é uma propriedade
  imutável após status Active
- Para evolução de payload, o caminho correto é: criar novo tipo com payload shape
  atualizado, deprecar o tipo antigo — assim a Timeline preserva a fidelidade histórica

---

### RIS-06 — Complexidade percebida como barreira de adoção

**Descrição:** dois Schemas + Shared Types + Journey Catalogs pode parecer excessivamente
complexo para Journeys que começam a implementar.

**Probabilidade:** Média.

**Impacto:** Baixo — a separação conceitual é clara; a complexidade percebida diminui com
uso e exemplos concretos.

**Mitigação:**
- O `event-type-schema.md` deve ser o documento de entrada para Journeys que criam novos
  tipos — um "formulário a preencher"
- O `event-instance-schema.md` é transparente para quem define tipos; é relevante para
  quem implementa Producers e Consumers
- A divisão de responsabilidade é uma redução de complexidade operacional (cada papel
  interage com apenas um Schema), não um aumento

---

## 11. Pergunta 10 — Organização recomendada dos documentos

### 11.1 Estrutura proposta

```
prodops/framework/events/
│
├── README.md                        ✓ (existe — fundação motivacional)
├── ontology.md                      ✓ (existe — 8 conceitos, relações, invariantes)
├── taxonomy.md                      ✓ (existe — Categories, naming, REG-01 a REG-10)
├── lifecycle.md                     ✓ (existe — ciclo de vida dos Event Types)
│
├── event-type-schema.md             → A criar — contrato dos Event Types
├── event-instance-schema.md         → A criar — estrutura das instâncias
│
├── shared-types.md                  → A criar — catálogo de tipos compartilhados
│
└── [futuro]
    ├── timeline.md                  → Comportamento formal da Timeline (opcional)
    └── categories.md                → Detalhamento das 8 Categories (opcional)
```

### 11.2 Justificativa da organização

**Todos os documentos OEM ficam em `framework/events/`** porque o OEM é um domínio
transversal do Framework — não pertence a nenhuma Journey específica.

**Catálogos de Journey ficam em `journeys/<journey>/events/catalog.md`** — fora de
`framework/events/` — porque são responsabilidade das Journeys, não do Framework.

**`shared-types.md` fica em `framework/events/`** porque os Shared Types são gerenciados
pelo Framework — é o Framework quem aprova, depreca e remove.

### 11.3 Nomes de arquivo: rationale

| Arquivo | Por que este nome |
|---|---|
| `event-type-schema.md` | `event-type` (snake-kebab) é inequívoco; `schema` indica que é a definição estrutural |
| `event-instance-schema.md` | `event-instance` distingue da definição; `schema` indica estrutura formal |
| `shared-types.md` | `shared-types` (plural) indica que é um catálogo; sem `schema` porque é um catálogo de entradas, não uma definição de estrutura |

### 11.4 Precedência de leitura para cada papel

| Papel | Documentos obrigatórios | Sequência |
|---|---|---|
| Journey architect (define tipos) | taxonomy → lifecycle → event-type-schema | Nesta ordem |
| Framework reviewer (aprova tipos) | taxonomy → lifecycle → event-type-schema → shared-types | Nesta ordem |
| Producer implementer (emite eventos) | event-type-schema → event-instance-schema → catálogo da Journey | Nesta ordem |
| Diligence engine | event-type-schema + event-instance-schema + lifecycle | Em paralelo |
| Assessment | event-instance-schema + catálogos de Journey | Instance Schema primeiro |

---

## 12. Decisão Arquitetural Final

### O Operational Event Model deve possuir um único Schema ou dois Schemas independentes?

**Dois Schemas independentes.**

**Justificativa técnica consolidada:**

Event Type e Operational Event são entidades de natureza ontologicamente distinta. O
primeiro é uma definição atemporal que governa o que pode ocorrer; o segundo é uma
ocorrência imutável que registra o que ocorreu em um instante específico.

Colocá-los em um único Schema criaria cinco incompatibilidades irreconciliáveis:

1. **Mutabilidade contraditória:** o Event Type tem campos que mudam com o lifecycle
   (`lifecycle_status`, `deprecated_in`); o Operational Event é absolutamente imutável.
   Um Schema coerente não pode governar campos com naturezas de mutabilidade opostas.

2. **Temporalidade distinta:** o Event Type é atemporal (não tem timestamp de ocorrência);
   o Operational Event é definido pelo seu timestamp. Fusão de atemporais e temporais em
   um Schema é categoricamente incorreta.

3. **Consumidores disjuntos:** quem precisa do Event Type Schema (architects, governance,
   Skills) raramente precisa do Instance Schema, e vice-versa. Um Schema único forçaria
   todos os consumidores a lidar com campos irrelevantes para seu papel.

4. **Polimorfismo de payload unidirecional:** o payload shape é definido no Event Type
   (contrato); a instância carrega o payload concreto. O Schema do Type define a estrutura
   esperada; o Schema da instância define que um payload existe e deve conformar ao contrato
   do tipo. Essa assimetria não pode existir em um Schema único sem circularidade.

5. **Governança independente:** Event Types são aprovados por Journeys ou Framework; Operational
   Events são registrados diretamente por Producers. Regras de aprovação de definições e
   regras de registro de ocorrências são regimes de governança completamente distintos.

A separação não é uma preferência de organização — é a consequência direta de reconhecer
que os dois conceitos pertencem a planos ontológicos diferentes, como já formalizado na
Ontologia (ontology.md). A Ontologia já os define como conceitos distintos com relações
e cardinalidades diferentes. Os Schemas devem refletir essa distinção formal.

---

## 13. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado |
| Derived State como projeção da Timeline | Preservado |
| Event Category como catálogo fixo do Framework | Preservado |
| Event Type como conceito formal da Ontologia | Preservado |
| Operational Event como conceito formal da Ontologia | Preservado |
| COR como consumidora do OEM | Preservado |
| Diligence como verificadora de consistência | Preservado |
| README.md não alterado | Confirmado |
| ontology.md não alterado | Confirmado |
| taxonomy.md não alterado | Confirmado |
| lifecycle.md não alterado | Confirmado |
| Nenhuma Journey alterada | Confirmado |
| Nenhum Skill alterado | Confirmado |
| Nenhum manifest alterado | Confirmado |
| Nenhum Schema criado | Confirmado |
| Nenhum catálogo criado | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 14. Arquivo criado

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/documentation-review-operational-event-schema-decision.md` | Este arquivo | Análise arquitetural e decisão sobre separação de Schemas |

Nenhum arquivo existente foi alterado. Nenhum Schema foi criado.
