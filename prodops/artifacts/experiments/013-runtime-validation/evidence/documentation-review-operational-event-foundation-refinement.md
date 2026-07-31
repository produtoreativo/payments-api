# Refinamento da Fundação do Operational Event Model
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Revisão arquitetural — análise e ajustes editoriais mínimos
> **Escopo:** `prodops/framework/events/README.md` exclusivamente
> **Status:** Concluído

---

## 1. Executive Summary

A fundação do Operational Event Model foi revisada em busca de conceitos arquiteturais
implícitos ainda não formalizados.

**Resultado:** dois conceitos foram promovidos a definições explícitas (`Derived State`
e a relação arquitetural entre OEM e COR). Sete candidatos foram avaliados e quatro
foram descartados como desnecessários ou pertencentes à camada de implementação.

A direção do documento não foi alterada. Nenhuma decisão arquitetural anterior foi
revertida ou modificada.

| Item | Status |
|---|---|
| Conceitos implícitos identificados | 7 candidatos avaliados |
| Conceitos promovidos a definições formais | 1 — Derived State |
| Relações arquiteturais explicitadas | 1 — OEM × COR |
| Conceitos descartados | 5 — desnecessários ou prematuros |
| Ajustes editoriais no README | 3 localizados |
| Nome do domínio `framework/events` | Mantido |
| Decisões arquiteturais anteriores alteradas | Nenhuma |

---

## 2. Conceitos Identificados

### 2.1 Candidatos avaliados

Leitura completa do documento fundacional identificou os seguintes candidatos para
formalização:

| Candidato | Onde aparece no README | Avaliação |
|---|---|---|
| **Derived State** | Seções 3.1 (diagrama), 4.3, P-05 | ✓ Promovido — conceito fundamental sem definição |
| **Audit Trail** | Seção 6.3 | Mantido como subordinado da Timeline — definição suficiente |
| **Operational History** | Seção 3.2 ("história operacional") | Descartado — ver Q2 |
| **Event Store** | Tabela seção 10 (tópico não tratado) | Descartado — é implementação, não arquitetura |
| **Projection Engine** | Ausente no documento | Descartado — ver Q3 |
| **State Projection** | Implícito em "projeção" | Descartado — subsumido por Derived State |
| **Event Producer** | Seções 2.1, P-03 | Mantido como atributo descritivo — não requer entidade própria |

### 2.2 Conceito promovido: Derived State

O conceito de "estado derivado" aparecia em 6 lugares distintos no documento usando termos
inconsistentes: "projeção", "estado derivado", "estado atual", "estado como projeção".
Nenhum deles tinha definição formal.

**Definição adotada:**

> **Derived State** é o estado atual de um Work Item computado a partir da sua Operational
> Timeline — especificamente, a projeção do último evento que altera estado.

A definição foi inserida como nova seção 4.3 ("Derived State"), substituindo o título
anterior "Estado como projeção da Timeline". O conteúdo anterior foi preservado e expandido
com a definição formal e a regra de derivação explícita.

**Por que Derived State e não State Projection?**

`State Projection` nomeia o mecanismo — o ato de projetar. `Derived State` nomeia o
resultado — o estado que existe porque foi derivado. Para um documento conceitual de nível
fundacional, o resultado é mais relevante que o mecanismo. A Projection Engine (o mecanismo
executor) pertence a documentos de implementação.

---

## 3. Respostas às 7 Questões Arquiteturais

### Q1 — Quais conceitos estruturais aparecem implicitamente no documento?

Dois conceitos estruturais existem de forma implícita e recorrente sem definição formal:

**1. Derived State** — o estado atual de um Work Item enquanto projeção da Timeline.
Aparece como "estado derivado", "projeção", "estado atual" de forma intercambiável. A
ausência de um nome canônico causava ambiguidade: "estado derivado" poderia ser confundido
com qualquer "estado atual que foi derivado de algo".

**2. A relação direcional OEM → COR** — o documento descrevia a relação, mas sem deixar
claro que COR é *consumidora* do OEM, não parte dele. Essa distinção importa porque COR
foi definida pela Diligence, antecede o OEM, e tem uma definição canônica própria.

Os demais candidatos avaliados (ver tabela 2.1) não representam conceitos estruturais
fundamentais para este nível de abstração.

---

### Q2 — Diferença entre Operational History e Operational Timeline?

**Conclusão: manter um único conceito — Operational Timeline.**

A distinção que poderia existir:
- `Timeline` = sequência de eventos de **um Work Item** (granularidade micro)
- `History` = agregação de Timelines de **múltiplos Work Items** ou Journeys (granularidade macro)

Porém, formalizar `Operational History` como conceito próprio traria mais custo que
benefício neste momento:

1. O documento já trata a análise macro ("padrões de eventos em múltiplas releases") com
   a linguagem "análise de padrões de eventos" sem precisar de um substantivo próprio.
2. Criar `Operational History` implicaria definir sua cardinalidade: é por OBC? Por Sprint?
   Por Journey? Por período? Essas perguntas pertencem à análise por Journey, não à fundação.
3. A palavra "história" permanece válida como linguagem informal: "a história operacional
   de um Work Item" é a sua Timeline. Não é necessário nomear o substantivo.

**Decisão:** `Operational History` é linguagem informal para `Operational Timeline`. Não
será formalizado como conceito separado neste documento.

---

### Q3 — Diferença entre State Projection e Projection Engine?

**Conclusão: State Projection é subsumido por Derived State. Projection Engine não pertence
a este documento.**

`State Projection` é o resultado do processo de projeção — o que chamamos de `Derived State`.
Os dois nomes para o mesmo conceito foram unificados em `Derived State` (ver Q1).

`Projection Engine` é o mecanismo que executa a derivação — o componente (humano, sistema
ou agente) que lê a Timeline e computa o Derived State. Este é um conceito de implementação,
não de arquitetura fundacional. Pertence a `events/schema.md` ou
`events/github-implementation.md` quando esses documentos forem criados.

**Decisão:** `State Projection` → subsumido por `Derived State`. `Projection Engine` →
descartado do escopo deste documento.

---

### Q4 — A COR é parte do OEM ou apenas uma consumidora?

**Conclusão: a COR é consumidora do OEM. Ela não é parte do OEM.**

A relação arquitetural correta:

```
OEM produz:
  Operational Events → Operational Timeline → Derived State

COR materializa:
  Derived State → GitHub Fields / Labels / Views

Diligence verifica:
  COR ↔ Timeline (consistência)
```

A COR foi definida pela Diligence como a materialização operacional do modelo conceitual
do Framework, implementada em GitHub Projects e Issues. Essa definição é anterior e
independente do OEM.

O OEM não altera a definição da COR. O que o OEM acrescenta é a clareza sobre de onde
o Derived State vem: ele é computado da Timeline. A COR continua sendo o lugar onde esse
estado é materializado para consumo operacional.

**Relação arquitetural:** `OEM → (produz Derived State) → COR (materializa como GitHub Fields)`

A Diligence verifica se a COR está sincronizada com o que a Timeline diz que o Derived
State deveria ser. Quando há divergência, a Timeline prevalece.

Esta relação foi explicitada no README com ajuste editorial na seção 3.2.

---

### Q5 — Diagrama conceitual de alto nível

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Operational Event Model (OEM)                           │
│                                                                             │
│   Skill / Step emite                                                        │
│          ↓                                                                  │
│   Operational Event    ← fato imutável com produtor e timestamp             │
│          ↓                                                                  │
│   Operational Timeline ← sequência ordenada de eventos (por Work Item)     │
│          ↓                                                                  │
│   Derived State        ← projeção do último evento que altera estado       │
│                                                                             │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │ materializa
                          ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│              Canonical Operational Representation (COR)                     │
│                                                                             │
│   GitHub Fields / Labels / Views   ← Derived State visível para humanos    │
│                                                                             │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │ verificada por
                          ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Diligence                                        │
│                                                                             │
│   Checks: COR ↔ Timeline consistentes?   ← verifica integridade            │
│   Checks: evento esperado ocorreu?        ← detecta ausências              │
│   Findings: abre Work Item se divergência detectada                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Transversal (deriva da Timeline):

   Audit Trail   ← subconjunto da Timeline focado em conformidade
   Métricas      ← funções de tempo sobre eventos da Timeline
   Assessment    ← análise de padrões em Timelines de múltiplas releases
```

**Nota sobre simplificação:** o diagrama proposto originalmente pelo usuário
(`Operational Event → Timeline → State Projection → Derived State → COR`) colocava
`State Projection` e `Derived State` como dois conceitos distintos. A análise desta
revisão consolidou os dois em `Derived State` — o diagrama final tem um passo a menos
e é mais preciso.

---

### Q6 — Ajustes editoriais necessários no README?

**Sim — três ajustes mínimos foram aplicados:**

**Ajuste 1 — Seção 4.3: Introdução de Derived State como conceito nomeado**

- **Antes:** título "Estado como projeção da Timeline" sem definição formal do conceito
- **Depois:** título "Derived State" com definição canônica explícita, propriedade de
  mutabilidade explicada, e regra de derivação enunciada
- **Extensão da mudança:** 10 linhas adicionadas; conteúdo anterior preservado

**Ajuste 2 — Seção 3.2 (COR): Relação direcional explicitada**

- **Antes:** "Os Operational Events são a fonte primária a partir da qual a COR é derivada
  e mantida sincronizada."
- **Depois:** "A COR é **consumidora** do OEM — não é parte dele. A COR materializa o
  Derived State produzido pelo OEM."
- **Extensão da mudança:** parágrafo reescrito (4 linhas)

**Ajuste 3 — Seção 10 (Escopo): Derived State adicionado ao inventário de conceitos definidos**

- **Antes:** lista de conceitos definidos não incluía Derived State
- **Depois:** Derived State adicionado explicitamente entre Operational Event e Operational
  Timeline
- **Extensão da mudança:** 1 linha adicionada

---

### Q7 — O domínio `framework/events` deve ser mantido?

**Decisão: manter `framework/events`.**

Avaliação dos critérios:

| Critério | Avaliação |
|---|---|
| Segue convenção de outros domínios (`framework/execution-model`, `framework/execution-mapping`) | Sim |
| "events" dentro de `framework/` é ambíguo? | Não — no contexto ProdOps, eventos são operacionais por definição |
| Alternativa `framework/operational-events` traz ganho? | Não — é redundante no contexto |
| Alternativa `framework/oem` traz ganho? | Não — acrônimo menos descobrível que o termo completo |
| Custo de renomear (referências em `ontology.md`, `knowledge-vs-execution.md`, `glossary.md`) | Alto sem benefício justificado |

Conclusão: não existe ganho arquitetural em renomear. O nome atual é preciso, convencional
e descobrível.

---

## 4. Conceitos Descartados

| Conceito | Motivo do descarte |
|---|---|
| **Operational History** | Linguagem informal para Timeline; formalizar implicaria decisões de cardinalidade que pertencem a documentos por Journey |
| **Event Store** | Mecanismo de armazenamento — pertence a `events/storage.md` (futuro) |
| **Projection Engine** | Mecanismo executor da projeção — pertence a `events/schema.md` (futuro) |
| **State Projection** | Subsumido por Derived State — dois nomes para o mesmo resultado |
| **Event Producer** | Atributo descritivo, não entidade própria — P-03 cobre a responsabilidade suficientemente |

---

## 5. Ajustes Realizados no README

| Seção | Tipo de ajuste | Extensão |
|---|---|---|
| 3.2 — COR | Parágrafo reescrito para explicitar direcionalidade (COR é consumidora) | 4 linhas |
| 4.3 — Derived State | Seção expandida com definição formal do conceito | 10 linhas adicionadas |
| 10 — Escopo | Item adicionado à lista de conceitos definidos | 1 linha |

**Total de linhas adicionadas:** ~15 (sobre 504 originais = ~3% de alteração)

**Nenhuma seção foi removida. Nenhum princípio foi alterado. Nenhuma decisão anterior
foi revertida.**

---

## 6. Confirmação de Invariantes

| Invariante | Status |
|---|---|
| Operational Event como conceito central do OEM | Preservado |
| Operational Timeline como sequência imutável | Preservado |
| Princípios P-01 a P-10 | Nenhum alterado |
| Diligence como verificadora (não parte) do OEM | Preservado |
| COR definida pela Diligence, não pelo OEM | Preservado e reforçado |
| Escopo de não-implementação do documento | Preservado |
| Relação do OEM com a ontologia (dimensão temporal, orthogonal) | Preservado |
| Nenhuma Journey foi alterada | Confirmado |
| Nenhum Skill foi alterado | Confirmado |
| Nenhum manifest foi alterado | Confirmado |
| Nenhum template foi alterado | Confirmado |
| Nenhuma documentação fora de `framework/events` foi modificada | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 7. Próximos Passos Sugeridos

Esta revisão conclui a fase de fundação conceitual. O próximo passo natural é a formalização
da Ontologia do OEM — que introduzirá os tipos canônicos de Operational Event, a estrutura
de um evento, e as categorias que se aplicam a qualquer Journey.

A fundação está pronta para suportar a Ontologia sem contradições.

| Próximo passo | Documento | Depende de |
|---|---|---|
| Ontologia do OEM | `events/ontology.md` | Este documento (fundação concluída) |
| Schema de eventos | `events/schema.md` | Ontologia |
| Catálogo de eventos da Delivery | `journeys/delivery/events/catalog.md` | Schema |
| Implementação em GitHub | `events/github-implementation.md` | Schema + Catálogo |
