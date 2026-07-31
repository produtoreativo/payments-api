# Event Type Schema — Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [README.md](README.md) · [ontology.md](ontology.md) · [taxonomy.md](taxonomy.md) · [lifecycle.md](lifecycle.md)

---

## Sobre este documento

Este documento define o contrato formal de um **Event Type** no Operational Event Model.

Um Event Type é uma definição — não uma ocorrência. Ele especifica o que pode acontecer,
quem pode fazê-lo acontecer, como classificar o acontecimento e qual o impacto sobre o
Derived State do Work Item.

Todo catálogo de Event Types — seja o catálogo de uma Journey, seja o catálogo de tipos
compartilhados — é um conjunto de entradas que satisfazem este Schema.

Este documento não define o schema de Operational Events (instâncias). Esse contrato
é definido em `event-instance-schema.md`.

→ [Taxonomia OEM](taxonomy.md) · [Lifecycle OEM](lifecycle.md) · [Ontologia OEM](ontology.md)

---

## 1. O que é um Event Type

Um Event Type é um **contrato** que define a classe de um acontecimento operacional:

- o **nome** que identifica o acontecimento inequivocamente em qualquer contexto
- a **categoria** que o classifica dentro da Taxonomia do Framework
- a **semântica** — o que deve ser verdadeiro antes, o que será verdadeiro depois
- o **impacto** sobre o estado derivado do Work Item
- quem pode **produzir** o acontecimento
- o **estado** do tipo no seu ciclo de vida

Um Event Type não contém:

- timestamp de ocorrência (isso pertence à instância — Operational Event)
- referência a um Work Item (isso pertence à instância)
- payload concreto de uma ocorrência (isso pertence à instância)
- produtor específico de uma ocorrência (isso pertence à instância)

A separação é fundamental: o Event Type é o contrato; o Operational Event é a instância
que satisfaz o contrato.

---

## 2. Estrutura de campos

Os campos do Event Type estão organizados em três grupos:

| Grupo | Definição |
|---|---|
| **Obrigatório** | Deve estar presente em toda entrada do catálogo para que o tipo seja válido |
| **Condicional** | Obrigatório apenas quando uma condição específica é satisfeita |
| **Opcional** | Pode estar presente; não é necessário para a validade mínima |
| **Derivado** | Não é escrito na entrada do catálogo; pode ser calculado a partir de outros campos ou do contexto |

### 2.1 Campos obrigatórios

| Campo | Tipo | Imutável após Active? |
|---|---|---|
| `name` | string | Sim |
| `category` | enum (8 valores) | Sim |
| `alters_state` | boolean | Sim |
| `preconditions` | lista de strings | Sim |
| `postconditions` | lista de strings | Sim |
| `producer_subtypes` | lista de enum (Human, System, Agent) | Sim |
| `lifecycle_status` | enum (Draft, Proposed, Active, Deprecated, Removed) | Não |
| `introduced_in` | string (versão do catálogo) | Sim |
| `description` | string | Sim |

### 2.2 Campos condicionais

| Campo | Condição de obrigatoriedade | Imutável após Active? |
|---|---|---|
| `new_state` | Obrigatório quando `alters_state = true` | Sim |
| `deprecated_in` | Obrigatório quando `lifecycle_status = Deprecated ou Removed` | Sim (após preenchido) |
| `deprecation_reason` | Obrigatório quando `lifecycle_status = Deprecated ou Removed` | Sim (após preenchido) |
| `removed_in` | Obrigatório quando `lifecycle_status = Removed` | Sim (após preenchido) |
| `replacement_type` | Obrigatório quando `lifecycle_status = Deprecated` e existe substituto direto | Sim (após preenchido) |
| `migration_deadline` | Obrigatório quando `lifecycle_status = Deprecated` | Sim (após preenchido) |

### 2.3 Campos opcionais

| Campo | Quando usar |
|---|---|
| `payload_shape` | Quando a emissão requer campos específicos no payload — documenta o contrato do payload esperado |
| `promotion_origin` | Apenas em Shared Types — referência ao Journey Type que originou a promoção |
| `owner_journey` | Apenas em Journey Types — identifica a Journey responsável |
| `notes` | Contexto adicional, esclarecimentos, decisões de design relevantes para leitores do catálogo |

### 2.4 Campos derivados

Campos derivados não são escritos nas entradas do catálogo. São computáveis a partir dos
campos primários ou do contexto.

| Campo derivado | Como derivar |
|---|---|
| `namespace` | Prefixo do `name` antes do primeiro ponto, quando presente (ex.: `Delivery` em `Delivery.Bootstrap.Started`). Dentro do catálogo próprio da Journey, o namespace pode ser omitido do `name`. |
| `is_shared` | Verdadeiro se a entrada pertence ao catálogo `shared-types.md`; falso se pertence ao catálogo de uma Journey. |
| `lifecycle_history` | Sequência de transições de `lifecycle_status` com data e responsável — mantida como log de auditoria do catálogo, não como campo inline da entrada. |

---

## 3. Regras de cada campo

### `name`

**Significado:** identificador único e canônico do Event Type. É a chave que conecta
o tipo ao Operational Event registrado na Timeline.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** imutável após status Active (INV-TAX-01 da Taxonomia).

**Responsável por definir:** a Journey (para Journey Types) ou o Framework (para Shared Types).

**Regras:**
- Deve seguir a convenção `[Namespace.]Subject.Action` da Taxonomia
- Todos os componentes em PascalCase
- O Namespace é opcional dentro do catálogo próprio da Journey; obrigatório em referências
  cross-Journey
- Deve ser único dentro do catálogo em que está registrado — e deve ser verificado contra
  todos os outros catálogos (REG-01)
- Nomes de tipos Deprecated e Removed são reservados — não podem ser reutilizados por
  novos tipos
- Deve ser livre de referências a tecnologia, implementação ou ferramentas

---

### `category`

**Significado:** classifica o Event Type dentro das 8 Event Categories fixas da Taxonomia.
Determina o comportamento esperado pelos Event Consumers que processam por categoria.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey (para Journey Types) ou o Framework (para Shared Types),
com base nas 8 categorias fixas. Journeys não podem criar categorias novas (INV-TAX-02).

**Valores válidos:**

| Valor | Descrição |
|---|---|
| `Phase Lifecycle` | Início e conclusão de Phases; altera estado na maioria dos casos |
| `Gate` | Verificações de qualidade ou critérios; pode ou não alterar estado |
| `Human Decision` | Aprovações, rejeições, revisões humanas; pode ou não alterar estado |
| `Blocking` | Declaração e resolução de impedimentos; pode ou não alterar estado |
| `Rework` | Ciclos de retorno e correção; altera estado |
| `System` | Eventos gerados por sistemas ou pipelines; raramente altera estado |
| `Diligence` | Anomalias detectadas pela Diligence; raramente altera estado |
| `Correction` | Correções de erros de registro; nunca altera estado |

**Regra de consistência com `alters_state`:** um tipo com `alters_state = true` não pode
pertencer à categoria `Correction` (INV-TAX-04 da Taxonomia).

---

### `alters_state`

**Significado:** declara se a emissão deste tipo altera o Derived State do Work Item.
É o campo que os Consumers usam para determinar quais eventos precisam ser processados
para reconstruir o estado atual.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey ou o Framework, com base na semântica do tipo.

**Valores válidos:** `true` | `false`

**Consequência de `alters_state = true`:** o campo `new_state` torna-se obrigatório.

**Regra de consistência:** não pode ser `true` em tipos da categoria `Correction`.

---

### `new_state`

**Significado:** o valor para o qual o Derived State do Work Item transita quando este
tipo é emitido. É o campo que permite a reconstrução do estado atual sem processar toda
a Timeline.

**Obrigatoriedade:** condicional — obrigatório quando `alters_state = true`; ausente quando
`alters_state = false`.

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey ou o Framework, com base no modelo de estados da Journey.

**Regras:**
- Deve ser um valor válido no modelo de estados da Journey (ex.: `HACKING`, `BLOCKED`,
  `DONE` para a Delivery Journey)
- O conjunto de valores possíveis de `new_state` deve ser consistente dentro de uma Journey —
  o catálogo da Journey é a fonte de verdade dos estados possíveis

---

### `preconditions`

**Significado:** lista de condições que devem ser verdadeiras no momento da emissão para
que o evento seja válido. Define a semântica de quando o tipo deve ser emitido.

**Obrigatoriedade:** obrigatório (pode ser uma lista vazia somente se não existir nenhuma
precondição — o que deve ser explicitamente declarado, não omitido).

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey ou o Framework.

**Formato:** lista de strings em linguagem natural, cada item representando uma condição
verificável. Exemplo:
```
- O Work Item está no estado HACKING
- Pelo menos um Pull Request está aberto para o Work Item
- O autor do PR é o mesmo que está com o Work Item em progresso
```

---

### `postconditions`

**Significado:** lista de garantias que devem ser verdadeiras após a emissão do evento.
Define o que pode ser assumido pelos Consumers que processam este tipo.

**Obrigatoriedade:** obrigatório (mesma regra de lista vazia que `preconditions`).

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey ou o Framework.

**Formato:** lista de strings em linguagem natural. Exemplo:
```
- O Work Item transita para o estado SYNCING
- A Timeline contém pelo menos um evento Bootstrap.Completed antes deste
- O Derived State na COR reflete o novo estado após sincronização
```

---

### `producer_subtypes`

**Significado:** declara quais subtipos de Producer podem emitir eventos deste tipo.
Delimita o contrato de quem é o responsável pela emissão.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey ou o Framework, com base em quem naturalmente
origina o acontecimento representado.

**Valores válidos (lista — ao menos um deve estar presente):**

| Valor | Descrição |
|---|---|
| `Human` | Um ser humano que interage com o processo (ex.: developer, reviewer, manager) |
| `System` | Um sistema automatizado, pipeline, ou ferramenta externa (ex.: CI/CD, GitHub Actions) |
| `Agent` | Um agente de IA ou automação no contexto do ProdOps (ex.: Diligence engine, Assessment agent) |

---

### `lifecycle_status`

**Significado:** estado atual do tipo no seu ciclo de vida — reflete se o tipo está sendo
elaborado, disponível para emissão, depreciado ou removido.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** muda conforme o ciclo de vida (este é o único campo obrigatório
mutável após Active — mas as transições seguem as regras do `lifecycle.md`).

**Responsável por definir:** quem governa o tipo (Journey para Journey Types; Framework
para Shared Types e para a transição `Proposed → Active`).

**Valores válidos:** `Draft` | `Proposed` | `Active` | `Deprecated` | `Removed`

**Regras de transição:** definidas em `lifecycle.md`.

---

### `introduced_in`

**Significado:** versão do catálogo em que o tipo foi adicionado. Permite rastrear quando
o tipo se tornou parte do catálogo e auditar compatibilidade retroativa.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** imutável após preenchimento.

**Responsável por definir:** quem aprova a transição Draft → Active (Journey ou Framework).

**Formato:** string que identifica a versão do catálogo (ex.: `"1.0.0"`, `"2026-Q3"` — o
formato é definido pelo catálogo da Journey ou pelo Framework para Shared Types).

---

### `description`

**Significado:** descrição textual do acontecimento que o tipo representa. Deve ser
suficiente para que um leitor do catálogo compreenda o propósito do tipo sem precisar
consultar documentação adicional.

**Obrigatoriedade:** obrigatório.

**Mutabilidade:** imutável após status Active.

**Responsável por definir:** a Journey ou o Framework.

**Regras:**
- Deve descrever o acontecimento, não a implementação
- Deve ser auto-suficiente — um leitor sem contexto de implementação deve compreendê-la
- Deve descrever o acontecimento na voz que representa o fato (ex.: "O Work Item iniciou
  a Phase de Bootstrap", não "Quando o Bootstrap começa")

---

### `deprecated_in`

**Significado:** versão do catálogo em que o tipo foi depreciado.

**Obrigatoriedade:** condicional — obrigatório quando `lifecycle_status = Deprecated ou Removed`.

**Mutabilidade:** imutável após preenchimento.

**Responsável por definir:** quem depreciou o tipo.

---

### `deprecation_reason`

**Significado:** justificativa textual da depreciação. Explica por que o tipo foi depreciado
e orienta quem está migrando Skills que o emitiam.

**Obrigatoriedade:** condicional — obrigatório quando `lifecycle_status = Deprecated ou Removed`.

**Mutabilidade:** imutável após preenchimento.

---

### `removed_in`

**Significado:** versão do catálogo em que o tipo foi removido do catálogo ativo.

**Obrigatoriedade:** condicional — obrigatório quando `lifecycle_status = Removed`.

**Mutabilidade:** imutável após preenchimento.

---

### `replacement_type`

**Significado:** referência ao tipo substituto. Deve estar presente quando existe um
tipo direto que substitui o depreciado — orienta a migração de Skills e Consumers.

**Obrigatoriedade:** condicional — obrigatório quando `lifecycle_status = Deprecated` e
existe substituto direto. Pode ser omitido em depreciações por obsolescência sem substituto.

**Mutabilidade:** imutável após preenchimento.

**Formato:** string com o nome completo do tipo substituto (com Namespace quando cross-Journey).
Exemplo: `"Shared.Gate.Failed"` ou `"Bootstrap.SmokeGate.Failed"`.

---

### `migration_deadline`

**Significado:** ciclo da Journey até o qual emissão do tipo depreciado ainda é tolerada.
Após este ciclo, emissões do tipo depreciado são anomalias a serem detectadas pela Diligence.

**Obrigatoriedade:** condicional — obrigatório quando `lifecycle_status = Deprecated`.

**Mutabilidade:** imutável após preenchimento.

---

### `payload_shape`

**Significado:** descrição dos campos esperados no payload de uma instância deste tipo.
Define o contrato de dados que o Producer deve incluir ao emitir o evento.

**Obrigatoriedade:** opcional — mas altamente recomendado para tipos com semântica
específica que exige dados estruturados.

**Mutabilidade:** imutável após status Active (qualquer adição de campo obrigatório ao
payload shape é uma mudança semântica — exige deprecação e criação de novo tipo).
Campos opcionais no payload shape podem ser adicionados sem deprecação.

**Responsável por definir:** a Journey ou o Framework.

**Formato:** lista de campos com nome, tipo e obrigatoriedade. Exemplo:
```
- branch_name (string, obrigatório): nome do branch criado para o Work Item
- base_commit (string, obrigatório): hash do commit base do branch
- smoke_gate_passed (boolean, opcional): resultado do smoke gate inicial
```

**Regra de compatibilidade de payload:**
- Adicionar campo **opcional** ao payload shape: compatível com versões anteriores
- Adicionar campo **obrigatório** ao payload shape: breaking change — deprecar tipo e criar novo
- Remover campo: breaking change — deprecar tipo e criar novo

---

### `promotion_origin`

**Significado:** referência ao Journey Type que originou este Shared Type. Presente apenas
em tipos do catálogo compartilhado que foram promovidos de um catálogo de Journey.

**Obrigatoriedade:** opcional — presente apenas em Shared Types que foram criados por
promoção.

**Mutabilidade:** imutável após preenchimento.

**Responsável por definir:** o Framework, no momento de aprovação da promoção.

---

### `owner_journey`

**Significado:** identifica a Journey responsável pelo tipo. Presente apenas em Journey Types.

**Obrigatoriedade:** opcional — recomendado em Journey Types para clareza de responsabilidade.

**Mutabilidade:** imutável após preenchimento (se a Journey muda, é um indicativo de que
o tipo deveria ser promovido a Shared — não de que o `owner_journey` deve ser alterado).

---

### `notes`

**Significado:** contexto adicional relevante para leitores do catálogo. Decisões de design
não óbvias, esclarecimentos de ambiguidades, justificativas de escolhas de nomenclatura.

**Obrigatoriedade:** opcional.

**Mutabilidade:** pode ser atualizado — notes não fazem parte do contrato formal do tipo,
são contexto explicativo. Porém notes não devem contradizer os campos imutáveis do tipo.

---

## 4. Validações

As validações abaixo definem o que torna uma entrada do catálogo **válida**. Uma entrada
inválida não pode transitar de Draft para Active.

### VAL-01 — Unicidade do nome

O `name` de um tipo deve ser único dentro do catálogo em que está registrado.
Além disso, deve ser verificado contra todos os outros catálogos (Journeys e Shared Types)
para garantir que não existe tipo com o mesmo nome e semântica diferente.

Nomes de tipos em status Deprecated ou Removed são **reservados** — não podem ser
reutilizados por novos tipos.

### VAL-02 — Conformidade da convenção de nome

O `name` deve seguir a convenção `[Namespace.]Subject.Action` com PascalCase em todos
os componentes. Nomes que não conformam devem ser rejeitados na transição Draft → Active.

**Exemplos válidos:** `Bootstrap.Started`, `Gate.Failed`, `Delivery.Promote.Completed`

**Exemplos inválidos:** `bootstrap_started`, `GATE-FAILED`, `started` (sem Subject), `Bootstrap`
(sem Action)

### VAL-03 — Category válida

O `category` deve ser um dos 8 valores fixos da Taxonomia. Valores fora desta lista são
inválidos — Journeys não podem criar categorias novas.

### VAL-04 — `alters_state` declarado

O campo `alters_state` deve estar presente e ter valor explícito (`true` ou `false`).
A ausência do campo invalida a entrada.

### VAL-05 — `new_state` presente quando `alters_state = true`

Quando `alters_state = true`, o campo `new_state` é obrigatório. Sua ausência invalida
a entrada independentemente do `lifecycle_status`.

### VAL-06 — Consistência `alters_state` × `category` (INV-TAX-04)

Um tipo com `alters_state = true` não pode pertencer à categoria `Correction`. Esta é a
única Category onde `alters_state = true` é estruturalmente inválido — `Correction` representa
o registro de uma correção de erro, que não altera o fluxo do Work Item.

### VAL-07 — `lifecycle_status` válido

O `lifecycle_status` deve ser um dos 6 valores canônicos: `Draft`, `Proposed`, `Active`,
`Deprecated`, `Removed`. Transições entre estados devem seguir as regras de `lifecycle.md`.

### VAL-08 — Campos de depreciação presentes quando `lifecycle_status = Deprecated`

Quando `lifecycle_status = Deprecated`, os campos `deprecated_in`, `deprecation_reason` e
`migration_deadline` são obrigatórios. A ausência de qualquer um invalida a entrada.

### VAL-09 — Campos de remoção presentes quando `lifecycle_status = Removed`

Quando `lifecycle_status = Removed`, os campos `deprecated_in`, `deprecation_reason` e
`removed_in` são obrigatórios (o tipo passou por Deprecated antes de Removed).

### VAL-10 — `producer_subtypes` não vazio

A lista `producer_subtypes` deve conter ao menos um valor válido. Uma lista vazia invalida
a entrada — todo Event Type deve ter ao menos um tipo de Producer autorizado.

### VAL-11 — Emissão proibida para tipos não-Active

Somente tipos com `lifecycle_status = Active` podem ser emitidos por Skills e Steps.
Tipos em Draft, Proposed, Deprecated ou Removed não podem ser referenciados por novas
emissões. Esta validação é executada no momento da emissão (Instance Schema), mas deriva
do `lifecycle_status` do Event Type Schema.

### VAL-12 — `payload_shape` imutável após Active

Se `payload_shape` está presente em um tipo Active, seus campos obrigatórios não podem
ser alterados ou removidos. Adição de campos opcionais é compatível; qualquer mudança
breaking exige deprecação do tipo e criação de novo.

---

## 5. Compatibilidade do Schema

### 5.1 Princípio de evolução compatível

O Event Type Schema deve poder evoluir sem forçar a reescrita de catálogos existentes.
Catálogos válidos antes de uma evolução do Schema devem permanecer válidos após a evolução
— ou receber um período de migração com comunicação clara.

### 5.2 Mudanças compatíveis com versões anteriores

As seguintes mudanças no Schema não quebram catálogos existentes:

| Mudança | Por que é compatível |
|---|---|
| Adicionar campo opcional | Catálogos existentes não têm o campo — isso é válido pela definição de opcional |
| Adicionar novo valor possível de `category` | Catálogos existentes usam os valores antigos — continuam válidos |
| Adicionar nota explicativa a um campo existente | Não altera a estrutura formal |
| Adicionar novo enum para `producer_subtypes` | Catálogos existentes usam os valores antigos — continuam válidos |
| Alterar descrição de um campo (sem alterar sua semântica) | Esclarecimento, não breaking change |

### 5.3 Mudanças breaking (exigem migração)

As seguintes mudanças no Schema quebram catálogos existentes e exigem período de migração:

| Mudança | Por que é breaking | Processo |
|---|---|---|
| Tornar campo opcional em obrigatório | Entradas existentes sem o campo ficam inválidas | Versionar o Schema; comunicar deadline de migração para todos os catálogos |
| Remover campo existente | Entradas existentes com o campo ficam com dados sem contrato | Deprecar o campo primeiro; remover na versão seguinte |
| Alterar semântica de um campo | Entradas existentes satisfazem formalmente mas não semanticamente o Schema novo | Deprecar o campo, criar campo novo com nome diferente |
| Alterar valor de enum possível | Entradas existentes com o valor antigo ficam inválidas | Versionar o Schema; comunicar prazo |

### 5.4 Versionamento do Schema

O Schema é versionado em `event-type-schema.md` com campo `Versão:` no cabeçalho.

Cada catálogo de Journey e o catálogo de Shared Types deve declarar a versão do Schema
que está satisfazendo. Quando o Schema evolui com mudança breaking, os catálogos existentes
declaram a versão anterior — e têm um período para migrar para a versão nova.

O Framework é responsável por comunicar evoluções breaking do Schema a todas as Journeys
e estabelecer o deadline de migração.

### 5.5 Garantia de retrocompatibilidade histórica

Independentemente de qualquer evolução do Schema, tipos em status Removed permanecem
legíveis no catálogo histórico com a estrutura que tinham no momento da remoção. O catálogo
histórico não é migrado — preserva a definição original para que Consumers possam decodificar
Timelines históricas.

---

## 6. Exemplos

Os exemplos abaixo ilustram entradas válidas do catálogo. O formato de serialização concreto
(YAML, JSON, Markdown table) é definido pelo catálogo que implementa este Schema — não por
este documento.

### 6.1 Tipo mínimo válido em Draft

```
name:              Phase.Started
category:          Phase Lifecycle
alters_state:      true
new_state:         [a ser definido pela Journey]
preconditions:     []
postconditions:    []
producer_subtypes: [Human, Agent]
lifecycle_status:  Draft
introduced_in:     (a ser preenchido quando transitar para Active)
description:       Uma Phase foi iniciada para o Work Item.
```

### 6.2 Tipo Active completo

```
name:              Bootstrap.Completed
category:          Phase Lifecycle
alters_state:      true
new_state:         HACKING
preconditions:
  - O Work Item está no estado BOOTSTRAPPING
  - O branch de trabalho foi criado com sucesso
  - O smoke gate passou
postconditions:
  - O Work Item transita para o estado HACKING
  - A Timeline registra Bootstrap.Completed antes de qualquer evento da Phase Hack
producer_subtypes: [Human, Agent]
lifecycle_status:  Active
introduced_in:     1.0.0
description:       A Phase de Bootstrap foi concluída com sucesso. O Work Item está
                   pronto para iniciar o desenvolvimento na Phase Hack.
payload_shape:
  - branch_name (string, obrigatório): nome do branch criado
  - base_commit  (string, obrigatório): hash do commit base
  - smoke_passed (boolean, obrigatório): resultado do smoke gate
owner_journey:     Delivery
```

### 6.3 Tipo Deprecated com substituto

```
name:              Phase.Finished
category:          Phase Lifecycle
alters_state:      true
new_state:         (obsoleto — ver replacement_type)
preconditions:     [obsoleto — ver replacement_type]
postconditions:    [obsoleto — ver replacement_type]
producer_subtypes: [Human, Agent]
lifecycle_status:  Deprecated
introduced_in:     1.0.0
deprecated_in:     1.2.0
deprecation_reason: Tipo renomeado para Bootstrap.Completed para maior precisão semântica.
                    O nome genérico Phase.Finished criava ambiguidade entre as Phases.
replacement_type:  Bootstrap.Completed
migration_deadline: Ciclo 2026-Q4
description:       [DEPRECATED] Uma Phase foi concluída. Use Bootstrap.Completed.
owner_journey:     Delivery
```

### 6.4 Tipo de correção (alters_state = false)

```
name:              Event.Corrected
category:          Correction
alters_state:      false
preconditions:
  - Existe um evento anterior na Timeline com dado incorreto
  - A correção foi autorizada e documentada
  - O evento original permanece imutável na Timeline
postconditions:
  - A Timeline contém o evento de correção após o evento original
  - O evento de correção referencia o id do evento corrigido no payload
producer_subtypes: [Human]
lifecycle_status:  Active
introduced_in:     1.0.0
description:       Um erro de registro em um evento anterior foi corrigido. A correção
                   não altera o Derived State — é um registro de auditoria.
payload_shape:
  - corrected_event_id (string, obrigatório): id do evento com dado incorreto
  - correction_note    (string, obrigatório): descrição do que foi corrigido e por quê
```

---

## Referências

- [Fundação OEM](README.md)
- [Ontologia OEM](ontology.md)
- [Taxonomia OEM](taxonomy.md)
- [Lifecycle OEM](lifecycle.md)
- [Decisão de separação dos Schemas](../../documentation-review-operational-event-schema-decision.md)

---

*Este documento é a fonte canônica do contrato de um Event Type no OEM. Todo catálogo
de eventos — por Journey ou compartilhado — deve satisfazer este Schema em todas as suas
entradas com status Active.*
