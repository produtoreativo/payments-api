# Relatório — Event Type Schema
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Formalização de Schema — exclusivamente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/event-type-schema.md`

---

## 1. Executive Summary

O Event Type Schema foi formalizado como o contrato canônico que toda entrada de catálogo
de Event Types deve satisfazer — seja catálogo de Journey, seja catálogo de Shared Types.

| Item | Resultado |
|---|---|
| Campos obrigatórios | 9 |
| Campos condicionais | 6 (obrigatórios sob condição específica) |
| Campos opcionais | 4 |
| Campos derivados | 3 (computáveis, não escritos na entrada) |
| Regras de validação (VAL) | 12 (VAL-01 a VAL-12) |
| Mudanças compatíveis documentadas | 5 categorias |
| Mudanças breaking documentadas | 4 categorias |
| Exemplos canônicos | 4 (Draft, Active completo, Deprecated, Correction) |
| Documentos criados | 2 (`event-type-schema.md` + este relatório) |
| Documentos alterados | 0 |
| Conceitos arquiteturais novos introduzidos | 0 |
| Decisões anteriores alteradas | Nenhuma |

---

## 2. Principais Decisões

### DEC-ES-01 — Campos imutáveis e mutáveis são explicitamente declarados

**Decisão:** cada campo do Schema declara explicitamente se é imutável após Active ou não.

**Justificativa:** a imutabilidade dos campos é a materialização de INV-TAX-01 (Taxonomia)
no nível do Schema. Sem a declaração explícita por campo, a regra geral "tipos são imutáveis
após Active" seria aplicada de forma inconsistente — leitores do catálogo poderiam duvidar
se `lifecycle_status` (que nitidamente muda) é uma exceção intencional ou um erro.

**Resultado:** o Schema distingue claramente:
- Campos imutáveis após Active: `name`, `category`, `alters_state`, `new_state`,
  `preconditions`, `postconditions`, `producer_subtypes`, `introduced_in`, `description`,
  e todos os campos de lifecycle uma vez preenchidos (`deprecated_in`, `removed_in`, etc.)
- Campos mutáveis por design: `lifecycle_status` (muda seguindo o lifecycle.md)
- Campos explicativos mutáveis: `notes` (contexto explicativo, não contrato formal)

---

### DEC-ES-02 — Campos condicionais são um grupo separado dos opcionais

**Decisão:** os campos condicionais (`new_state`, `deprecated_in`, `migration_deadline`,
etc.) foram separados dos opcionais em um grupo próprio — "condicional" — com a condição
de obrigatoriedade explicitamente declarada.

**Justificativa:** confundir "condicional" com "opcional" seria um erro semântico relevante.
`new_state` não é opcional quando `alters_state = true` — é obrigatório sob essa condição.
A distinção evita que implementadores de catálogos omitam `new_state` em tipos que alteram
estado, acreditando que é opcional.

O grupo "condicional" força a leitura da condição antes de decidir se o campo está presente.

---

### DEC-ES-03 — `payload_shape` é opcional no Schema, não obrigatório

**Decisão:** o campo `payload_shape` é opcional no Event Type Schema — tipos podem ser
válidos sem ele.

**Justificativa:** existem tipos semanticamente completos cujo acontecimento não requer
dados adicionais além do próprio fato de ter ocorrido. Por exemplo, um tipo `Review.Started`
pode ter como payload apenas o registro da ocorrência — quem, quando, para qual Work Item
— dados que já existem nos campos obrigatórios da instância (producer, timestamp, work_item).

Tornar `payload_shape` obrigatório forçaria a criação de payloads vazios ou triviais,
adicionando ruído sem valor semântico.

**Contrapartida:** quando a emissão do tipo requer dados específicos (ex.: `Bootstrap.Completed`
precisa do `branch_name` para que Consumers possam operar), o `payload_shape` é altamente
recomendado — não é apenas documentação, é o contrato do payload.

---

### DEC-ES-04 — Compatibilidade de `payload_shape`: apenas campos opcionais são adicionáveis

**Decisão:** a regra de compatibilidade do `payload_shape` é análoga ao versionamento de
APIs: adicionar campo opcional = compatível; adicionar campo obrigatório ou remover campo
= breaking change.

**Justificativa:** Timelines são imutáveis (INV-01, INV-02). Se um tipo Active tem seu
`payload_shape` alterado para exigir um novo campo obrigatório, todos os eventos históricos
emitidos antes da mudança ficariam com payloads que não satisfazem o contrato novo. Isso
seria retroativamente inconsistente — violaria a integridade histórica da Timeline.

O caminho correto para mudança breaking de payload é criar um novo tipo (com novo `name`)
e deprecar o antigo. Isso preserva a Timeline histórica com o payload original e cria
uma nova classe de eventos com o payload atualizado.

---

### DEC-ES-05 — `notes` é o único campo mutável após Active (exceto `lifecycle_status`)

**Decisão:** `notes` pode ser atualizado mesmo após o tipo estar Active.

**Justificativa:** `notes` é contexto explicativo — não é parte do contrato formal. Corrigir
uma nota imprecisa, adicionar clarificação sobre uma decisão de design, ou atualizar uma
referência a outro documento não altera a semântica do tipo. A imutabilidade deve proteger
o contrato — não os comentários explicativos.

**Restrição:** `notes` não pode contradizer campos imutáveis. Se uma nota diz "este tipo
altera o estado para DONE" mas `new_state` diz `HACKING`, a contradição é um erro de
catálogo — não uma justificativa para alterar `new_state`.

---

### DEC-ES-06 — Validação VAL-11 pertence ao Event Type Schema mesmo sendo executada no Instance Schema

**Decisão:** a regra "somente tipos Active podem ser emitidos" (VAL-11) foi incluída no
Event Type Schema, mesmo que sua execução ocorra no momento da emissão — o que é domínio
do Instance Schema.

**Justificativa:** VAL-11 é uma propriedade do Event Type (`lifecycle_status = Active` é
condição para emissão) — não uma propriedade intrínseca do evento registrado. O Instance
Schema vai referenciar VAL-11 do Event Type Schema, não defini-la. Incluir VAL-11 no
Event Type Schema evita que o Instance Schema precise duplicar a lógica de validação —
ela existe uma vez, no Schema do contrato.

---

### DEC-ES-07 — Exemplos canônicos no Schema (não apenas no catálogo)

**Decisão:** o Event Type Schema inclui 4 exemplos canônicos de entradas válidas: Draft
mínimo, Active completo, Deprecated com substituto, e Correction (alters_state = false).

**Justificativa:** um Schema sem exemplos é mais difícil de implementar corretamente. Os
exemplos não são catálogo — são demonstrações do Schema. Eles cobrem os 4 casos mais
importantes: tipo em elaboração, tipo completo e em uso, tipo sendo substituído, e tipo
que nunca altera estado. Qualquer implementador de catálogo pode usar esses exemplos como
referência sem precisar consultar documentação adicional.

---

## 3. Os 12 campos e sua coerência interna

### 3.1 Campos que formam o "contrato de semântica"

Os campos `preconditions`, `postconditions`, `alters_state`, `new_state` e `producer_subtypes`
formam juntos o contrato de semântica do tipo — o que deve ser verdadeiro antes, quem pode
fazê-lo, e o que será verdadeiro depois.

A coerência entre esses campos é verificada por VAL-05 e VAL-06, mas a responsabilidade
semântica é do Journey architect: as precondições devem ser verificáveis, as pós-condições
devem ser consequências necessárias, e o `producer_subtypes` deve refletir quem naturalmente
origina o acontecimento.

### 3.2 Campos que formam o "contrato de lifecycle"

Os campos `lifecycle_status`, `introduced_in`, `deprecated_in`, `deprecation_reason`,
`migration_deadline`, `replacement_type`, `removed_in` formam o contrato de lifecycle.

Estes campos são governados pelo `lifecycle.md` — o Event Type Schema apenas os formaliza
como estrutura de dados. A lógica de quando preenchê-los e quem deve preenchê-los está
no Lifecycle.

### 3.3 Campos que formam o "contrato de governança"

Os campos `owner_journey` e `promotion_origin` permitem rastrear a responsabilidade do tipo
— quem o criou e de onde veio (para Shared Types). São opcionais porque a responsabilidade
pode ser implícita pelo catálogo em que o tipo está registrado.

---

## 4. Validações — Mapa de Dependências

| Validação | Campos envolvidos | Quando executada |
|---|---|---|
| VAL-01 (unicidade de name) | `name` | Na transição Draft → Active |
| VAL-02 (convenção de nome) | `name` | Na transição Draft → Active |
| VAL-03 (category válida) | `category` | Na transição Draft → Active |
| VAL-04 (alters_state declarado) | `alters_state` | Em qualquer estado exceto Draft |
| VAL-05 (new_state obrigatório se alters_state = true) | `alters_state` + `new_state` | Na transição Draft → Active |
| VAL-06 (category × alters_state) | `category` + `alters_state` | Na transição Draft → Active |
| VAL-07 (lifecycle_status válido) | `lifecycle_status` | Em qualquer mudança de estado |
| VAL-08 (campos de deprecação) | `deprecated_in` + `deprecation_reason` + `migration_deadline` | Na transição Active → Deprecated |
| VAL-09 (campos de remoção) | `removed_in` | Na transição Deprecated → Removed |
| VAL-10 (producer_subtypes não vazio) | `producer_subtypes` | Na transição Draft → Active |
| VAL-11 (emissão somente Active) | `lifecycle_status` | No momento da emissão (Instance Schema referencia) |
| VAL-12 (payload_shape imutável após Active) | `payload_shape` | Em qualquer modificação após Active |

### 4.1 Validações que nunca são executadas em Draft

Um tipo em Draft pode existir com campos faltando — ele está sendo elaborado. As
validações VAL-01 a VAL-06 e VAL-10 a VAL-12 são executadas na transição para Active,
não na criação do Draft. Isso permite que o elaborador trabalhe incrementalmente sem
precisar de um tipo completo desde o início.

VAL-07 é executada em qualquer mudança de `lifecycle_status` — incluindo a criação
inicial (o valor inicial Draft deve ser um valor válido).

---

## 5. Compatibilidade — Análise de Cenários Concretos

### Cenário A — Adicionar campo opcional ao Schema

**Situação:** o Framework adiciona o campo opcional `tags` ao Event Type Schema (para
permitir busca por palavras-chave nos catálogos).

**Impacto:** todos os catálogos existentes continuam válidos. Entradas sem `tags` são
válidas — o campo é opcional. Nenhuma migração necessária.

**Processo:** publicar nova versão do Schema (ex.: 1.1.0); comunicar o novo campo às
Journeys; cada Journey pode adicionar `tags` no seu próprio ritmo.

---

### Cenário B — Tornar campo opcional em obrigatório

**Situação:** o Framework decide que `owner_journey` deve ser obrigatório em Journey Types
(hoje é opcional).

**Impacto:** todos os catálogos de Journey com entradas sem `owner_journey` ficam inválidos
segundo o novo Schema.

**Processo:** publicar nova versão do Schema (ex.: 2.0.0 — versão major por breaking change);
comunicar deadline de migração; cada Journey tem o prazo para adicionar `owner_journey` a
todas as suas entradas Active; entradas históricas (Deprecated, Removed) são isentas —
o catálogo histórico preserva a definição original.

---

### Cenário C — Renomear campo

**Situação:** o Framework decide renomear `deprecation_reason` para `lifecycle_note`
para maior generalidade.

**Impacto:** breaking change — todos os catálogos com `deprecation_reason` ficam com um
campo sem correspondência no novo Schema.

**Processo:** adicionar `lifecycle_note` como novo campo opcional (versão 1.1.0); deprecar
`deprecation_reason` com nota de que `lifecycle_note` é o substituto; na versão 2.0.0,
remover `deprecation_reason` e tornar `lifecycle_note` obrigatório sob as mesmas condições.
As Journeys migram em duas etapas sem período de invalidade.

---

## 6. Impacto nos Documentos Futuros

| Documento | Como usa o Event Type Schema |
|---|---|
| `event-instance-schema.md` | Referencia o Event Type Schema para VAL-11; o campo `event_type` da instância é uma chave que aponta para `name` do tipo no catálogo |
| `shared-types.md` | Cada entrada deve satisfazer o Event Type Schema; Framework usa as VALs para revisar propostas de promoção |
| `journeys/*/events/catalog.md` | Cada entrada deve satisfazer o Event Type Schema; Journey usa as VALs para aprovar novos tipos |
| `events/categories.md` (futuro) | Expande a descrição das 8 categorias em VAL-03 com exemplos detalhados |
| `events/timeline.md` (futuro) | Referencia `alters_state` e `new_state` do Event Type Schema para descrever como Derived State é computado |

---

## 7. Posição na Sequência Documental

O Event Type Schema ocupa a posição 5 na sequência definitiva do OEM:

| Posição | Documento | Depende de |
|---|---|---|
| 1 | README.md | — |
| 2 | ontology.md | README |
| 3 | taxonomy.md | ontology |
| 4 | lifecycle.md | taxonomy |
| **5** | **event-type-schema.md** | **lifecycle** |
| 6a | event-instance-schema.md | event-type-schema |
| 6b | shared-types.md | event-type-schema |
| 7 | journey catalogs | event-type-schema + shared-types |

Esta posição está correta porque:
- O Schema usa os 8 valores de `category` definidos pela Taxonomy → depende de taxonomy.md
- O Schema usa os estados de `lifecycle_status` definidos pelo Lifecycle → depende de lifecycle.md
- O Schema formaliza os campos que lifecycle.md e taxonomy.md já nomeiam informalmente

---

## 8. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado |
| Derived State como projeção da Timeline | Preservado |
| Event Category como catálogo fixo do Framework (8 categorias) | Preservado — VAL-03 confirma |
| Event Type como conceito formal da Ontologia | Preservado e materializado neste Schema |
| INV-TAX-01 (tipos imutáveis após Active) | Preservado — cada campo declara mutabilidade |
| INV-TAX-04 (category × alters_state) | Preservado — VAL-06 confirma |
| Separação Event Type Schema / Instance Schema | Preservado — este Schema cobre somente o Type |
| COR como consumidora do OEM | Preservado |
| Diligence como verificadora de consistência | Preservado |
| README.md não alterado | Confirmado |
| ontology.md não alterado | Confirmado |
| taxonomy.md não alterado | Confirmado |
| lifecycle.md não alterado | Confirmado |
| Nenhuma Journey alterada | Confirmado |
| Nenhum Skill alterado | Confirmado |
| Nenhum manifest alterado | Confirmado |
| Event Instance Schema não criado | Confirmado |
| Shared Types não criados | Confirmado |
| Catálogos de Journey não criados | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 9. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/events/event-type-schema.md` | ~380 | Contrato canônico do Event Type |
| `prodops/documentation-review-event-type-schema.md` | Este arquivo | Relatório de formalização |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 10. Próximos Passos Sugeridos

| Documento | Prioridade | Raciocínio |
|---|---|---|
| `events/event-instance-schema.md` | Alta | Complementa o Event Type Schema; define a estrutura das ocorrências registradas; desbloqueia o desenvolvimento de Producers e Consumers |
| `events/shared-types.md` | Alta | O catálogo de tipos compartilhados pode começar a ser preenchido agora que o Schema está definido |
| `journeys/delivery/events/catalog.md` | Alta | 83 tipos propostos; o Schema está pronto para ser aplicado; é o caso de uso mais maduro |
| `events/categories.md` | Média | Expande VAL-03 com exemplos detalhados por Category |
