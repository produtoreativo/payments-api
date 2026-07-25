# Relatório — Ontologia do Operational Event Model
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Formalização de ontologia — somente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/ontology.md`

---

## 1. Executive Summary

A Ontologia do Operational Event Model foi formalizada com 8 conceitos canônicos avaliados,
6 conceitos descartados e 10 invariantes definidos.

O documento produzido é exclusivamente conceitual — sem schema, sem implementação, sem
menção a GitHub ou ferramentas. Nenhuma decisão arquitetural anterior foi alterada.

| Item | Resultado |
|---|---|
| Conceitos canônicos formalizados | 8 (todos os candidatos avaliados) |
| Relações definidas | 16 relações bilaterais |
| Cardinalidades especificadas | 12 (com justificativa para as críticas) |
| Invariantes definidos | 10 (INV-01 a INV-10) |
| Fronteiras de responsabilidade mapeadas | 5 domínios (OEM, Diligence, COR, Journeys, Implementação) |
| Dependências futuras identificadas | 13 documentos |
| Conceitos descartados | 7 candidatos com justificativa |
| Documentos modificados (existentes) | 0 |
| Documentos criados | 2 (`ontology.md` + este relatório) |

---

## 2. Conceitos Formalizados

### 2.1 Status de cada candidato

| Conceito | Status | Decisão |
|---|---|---|
| **Operational Event** | ✓ Formalizado | Unidade atômica fundamental — sem discussão |
| **Operational Timeline** | ✓ Formalizado | Estrutura primária — já aprovada na fundação |
| **Derived State** | ✓ Formalizado | Promovido a conceito formal no refinamento anterior |
| **Event Producer** | ✓ Formalizado como papel | Atributo obrigatório de todo evento; 3 subtipos |
| **Event Consumer** | ✓ Formalizado como papel | Papel simétrico ao Producer; consumidores concretos definidos em seus domínios |
| **Event Category** | ✓ Formalizado | Taxonomia de 8 categorias fixas no Framework |
| **Event Type** | ✓ Formalizado | Classe de evento; instâncias são Operational Events |
| **Event Evidence** | ✓ Formalizado | Dois níveis: intrínseca (todo evento) e referenciada (críticos) |

Todos os 8 candidatos foram mantidos como conceitos formais. Nenhum foi descartado da lista
original — porém dois (Event Producer e Event Consumer) foram formalizados como **papéis**
(roles), não como entidades com identidade própria e ciclo de vida no OEM.

### 2.2 Decisão sobre Event Producer e Event Consumer como papéis

**Por que papel e não entidade?**

Uma entidade teria identidade própria, ciclo de vida gerenciado pelo OEM e cardinalidade
independente dos eventos. Isso criaria um "registro de Producers" e um "registro de
Consumers" — infraestrutura de implementação desnecessária no nível conceitual.

Como papéis:
- Event Producer existe como atributo obrigatório de cada Operational Event (quem o originou)
- Event Consumer existe como classificação de quem lê eventos (Diligence, métricas, agentes)
- Ambos têm definição formal e taxonomia — mas não têm instância própria fora do contexto
  de um evento

### 2.3 Decisão sobre Event Evidence como conceito formal

Event Evidence poderia ser visto como redundante — "o evento é evidência de si mesmo."
A formalização como conceito serve para:

1. Tornar explícito que existem dois níveis de evidência (intrínseca e referenciada)
2. Permitir que a Diligence verifique a **qualidade** da evidência, não apenas a existência
   do evento
3. Criar o gancho conceitual para o futuro `events/schema.md` que definirá o que constitui
   evidência suficiente por tipo de evento

---

## 3. Relações Definidas

### 3.1 Relações principais

| Relação | Tipo | Cardinalidade |
|---|---|---|
| Work Item → Operational Timeline | 1:1 | Cada Work Item tem exatamente uma Timeline |
| Operational Timeline → Operational Event | 1:N | Uma Timeline contém zero ou mais eventos |
| Operational Event → Operational Timeline | N:1 | Todo evento pertence a exatamente uma Timeline |
| Operational Event → Event Type | N:1 | Todo evento é tipado por exatamente um Type |
| Operational Event → Event Producer | N:1 | Todo evento tem exatamente um Producer |
| Operational Event → Event Evidence | 1:1 | Todo evento auto-produz uma evidência intrínseca |
| Operational Event → Artefatos | N:M | Um evento pode referenciar N artefatos; um artefato pode ser referenciado por N eventos |
| Operational Timeline → Derived State | 1:1 | Uma Timeline produz exatamente um Derived State (o atual) |
| Event Category → Event Type | 1:N | Uma Category agrupa um ou mais Types |
| Event Type → Event Category | N:1 | Um Type pertence a exatamente uma Category |
| Event Type → Operational Event | 1:N | Um Type é instanciado por zero ou mais eventos |
| Derived State → COR | 1:1 (materialização) | O Derived State atual é materializado pela COR |

### 3.2 Relação OEM × COR: confirmação arquitetural

A relação foi intencionalmente definida como **materialização**, não como dependência.

- OEM **produz** Derived State
- COR **materializa** Derived State
- Diligence **verifica** consistência entre COR e Timeline

A COR não pertence ao OEM — é uma consumidora especializada que materializa um único
ponto da Timeline (o estado atual). A Timeline completa não é materializada pela COR.

Essa distinção preserva a autonomia das definições: COR continua sendo definida pela
Diligence; OEM não altera essa definição.

---

## 4. Cardinalidades — Justificativas para as Críticas

### 4.1 Por que 1:1 entre Work Item e Operational Timeline?

Porque a Timeline é a identidade operacional de um Work Item. Ter duas Timelines
equivaleria a ter duas histórias simultâneas — o que tornaria impossível derivar
um único Derived State consistente.

Se um Work Item é dividido (split), dois novos Work Items surgem. Cada um tem
sua própria Timeline. A Timeline do item original permanece como está.

### 4.2 Por que N:1 entre Operational Event e Event Type (não 1:1)?

O mesmo tipo de evento pode ocorrer múltiplas vezes para o mesmo Work Item.
Exemplo: `Hack.PROpened` pode ocorrer 3 vezes se o item passou por rework e
novos PRs foram abertos. O Event Type define a classe — a Timeline contém
todas as instâncias.

### 4.3 Por que 0..N eventos na Timeline (mínimo zero)?

A Timeline existe desde a criação do Work Item. No momento de criação, ela
está vazia — nenhum evento ocorreu ainda. A cardinalidade mínima é zero para
permitir esse estado inicial válido.

### 4.4 Por que 1:1 entre Timeline e Derived State?

O Derived State é um snapshot — o estado *agora*. Não é uma lista de estados
históricos (isso é o papel da Timeline). Sempre há exatamente um estado atual
por Work Item.

---

## 5. Invariantes — Análise

### 5.1 Invariantes confirmados da fundação (já presentes nos Princípios)

| Invariante | Princípio correspondente | Adição ao INV |
|---|---|---|
| INV-01 (imutabilidade) | P-02 | Protocolo de correção explicitado (Event.Corrected) |
| INV-02 (append-only) | P-02 (implícito) | Formalizou como regra estrutural da Timeline |
| INV-04 (producer obrigatório) | P-03 | Adicionou "invalida o registro" como consequência |
| INV-05 (Derived State via eventos) | P-05 | Explicitou "nenhum agente, humano ou sistema externo" |
| INV-06 (COR não é fonte) | P-05 | Explicitou consequência: corrigir COR, não Timeline |
| INV-08 (ausência é dado) | P-06 | Atribuiu responsabilidade à Diligence |
| INV-09 (Timeline prevalece) | P-05 | Explicitou a direção de resolução de conflitos |
| INV-10 (correções são eventos) | P-02 | Explicitou "não edições retroativas" |

### 5.2 Invariantes novos introduzidos pela Ontologia

| Invariante | Por que não estava na fundação |
|---|---|
| INV-03 (unicidade de Timeline por Work Item) | Decorreu da cardinalidade 1:1 — não era necessário antes |
| INV-07 (Event Types do catálogo) | Decorreu da formalização do Event Type — não existia antes |

---

## 6. Fronteiras — Ambiguidades Resolvidas

### 6.1 Ambiguidade: "quem define os Event Types?"

**Resolução:** Event Types concretos são definidos por cada Journey em seu catálogo
(`journeys/<journey>/events/catalog.md`). A estrutura do Event Type (campos obrigatórios,
convenções de nomenclatura, relação com Category) é definida pelo OEM.

Essa separação preserva a autonomia das Journeys enquanto mantém a padronização central.

### 6.2 Ambiguidade: "a COR faz parte do OEM?"

**Resolução explicitada nas fronteiras:** COR é consumidora e materializadora do OEM —
não parte dele. Ela tem definição própria (Diligence) e antecede o OEM. O OEM apenas
esclarece que o Derived State que a COR materializa vem da Timeline.

### 6.3 Ambiguidade: "Diligence é produtora ou consumidora?"

**Resolução:** a Diligence é **consumidora** da Timeline (para verificação) e também
**produtora** de eventos da categoria `Diligence` (quando detecta anomalias). Ambos
os papéis coexistem — não há conflito porque são papéis, não entidades.

---

## 7. Conceitos Descartados

| Conceito candidato | Motivo do descarte |
|---|---|
| **Operational History** | Linguagem informal para "análise de padrões entre Timelines" — formalizar exigiria cardinalidade ambígua |
| **Event Stream** | Sinônimo de Timeline com conotação de implementação (streaming real-time) — desnecessário |
| **Event Aggregate** | DDD pattern — pertence à implementação |
| **Projection Engine** | Mecanismo executor — pertence a `events/timeline.md` |
| **Event Subscriber** | Sinônimo técnico de Event Consumer — termo Consumer é suficiente |
| **Event Schema** | Schema é implementação — pertence a `events/schema.md` |
| **Timeline Version** | Versionamento é implementação — a Timeline é append-only por definição |

---

## 8. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| OEM é domínio transversal do Framework | Preservado |
| Operational Event como unidade fundamental | Preservado e formalizado |
| Operational Timeline como sequência imutável | Preservado e formalizado com propriedades explícitas |
| Derived State como projeção da Timeline | Preservado e formalizado com regra de derivação |
| COR é consumidora do OEM, não parte dele | Preservado e explicitado nas fronteiras |
| Diligence verifica consistência Timeline×COR | Preservado |
| Timeline como fonte primária de verdade | Preservado como INV-09 |
| Estado como projeção derivada | Preservado como INV-05 |
| Nenhuma Journey foi alterada | Confirmado |
| Nenhum Skill foi alterado | Confirmado |
| Nenhum manifest foi alterado | Confirmado |
| Nenhum template foi alterado | Confirmado |
| README do OEM não alterado | Confirmado |
| Ontologia geral do Framework não alterada | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 9. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/events/ontology.md` | ~380 | Ontologia completa do OEM |
| `prodops/documentation-review-operational-event-ontology.md` | Este arquivo | Relatório de formalização |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 10. Próximos Passos Sugeridos

A ontologia está completa e estável. Os próximos documentos podem ser produzidos
independentemente ou em paralelo:

| Documento | Prioridade | Depende de |
|---|---|---|
| `events/schema.md` | Alta — desbloqueia catálogos | Ontologia (estrutura de Event Type) |
| `journeys/delivery/events/catalog.md` | Alta — caso de uso mais maduro | Schema |
| `events/categories.md` | Média — enriquece a taxonomia | Ontologia (Event Category) |
| `events/timeline.md` | Média — formaliza comportamento | Ontologia + Schema |
| `events/github-implementation.md` | Baixa — implementação | Schema + Catálogo Delivery |
| `events/metrics.md` | Média — conecta OEM ao DORA | Catálogo Delivery + Ontologia |

**Recomendação:** o próximo passo natural é `events/schema.md`, pois desbloqueia todos
os catálogos de eventos por Journey. O catálogo da Delivery é o mais urgente — é o caso
de uso mais documentado e já possui 83 Event Types propostos no documento de análise.
