# Relatório — Taxonomia do Operational Event Model
# ProdOps Framework

> **Data:** 2026-07-24
> **Tipo:** Formalização de taxonomia — exclusivamente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/taxonomy.md`

---

## 1. Executive Summary

A Taxonomia do Operational Event Model foi formalizada como contrato entre o Framework e
as Journeys, cobrindo: classificação por Event Category, nomeação por Event Type, convenção
de nomenclatura, ciclo de vida, governança e anti-padrões.

| Item | Resultado |
|---|---|
| Event Categories formalizadas | 8 (catálogo canônico completo) |
| Regras para Journeys (REG) | 10 regras (REG-01 a REG-10) |
| Invariantes de taxonomia (INV-TAX) | 4 (INV-TAX-01 a INV-TAX-04) |
| Anti-padrões documentados | 11 (ANT-01 a ANT-11) |
| Convenção de nomenclatura | `[Namespace.]Subject.Action` |
| Tipos compartilhados | Conceito formalizado; catálogo (`shared-types.md`) = futuro |
| Documentos criados | 2 (`taxonomy.md` + este relatório) |
| Documentos alterados | 0 |
| Decisões arquiteturais anteriores alteradas | Nenhuma |

---

## 2. Taxonomia Definida

### 2.1 Estrutura da Taxonomia

```
OEM Taxonomy
├── Event Category     → Framework — fixo, 8 categorias, não extensível por Journey
│   ├── Phase Lifecycle
│   ├── Gate
│   ├── Human Decision
│   ├── Blocking
│   ├── Rework
│   ├── System
│   ├── Diligence
│   └── Correction
│
└── Event Type         → Dois registros possíveis
    ├── Shared Types   → Framework define; qualquer Journey usa
    └── Journey Types  → Journey define; uso restrito à Journey (até promoção)
```

### 2.2 Event Categories — tabela consolidada

| Category | `alters_state` | Producer | Frequência típica |
|---|---|---|---|
| Phase Lifecycle | Sim | Human, Agent | Alta — 2 por Phase |
| Gate | Condicional | System, Agent | Alta — 1+ por Phase |
| Human Decision | Condicional | Human | Baixa — só em aprovações |
| Blocking | Condicional | Human, Agent | Baixa — exceção ao fluxo |
| Rework | Sim | Human, Agent | Baixa — exceção ao fluxo |
| System | Raramente | System | Variável — depende do pipeline |
| Diligence | Raramente | Agent (Diligence) | Baixa — anomalia detectada |
| Correction | Não | Human, Agent | Mínima — erro é exceção |

---

## 3. Decisões Tomadas

### DEC-01 — Categories são fixas no Framework; Journeys não podem criar novas

**Decisão:** Event Categories são definidas exclusivamente pelo Framework. Journeys não
podem criar, modificar ou depreciar Categories.

**Justificativa:** se Journeys pudessem criar Categories, a fragmentação da taxonomia seria
inevitável. Event Consumers (Diligence, métricas, Assessment) dependem de Categories para
filtros cross-Journey. Categories criadas por Journeys individuais seriam invisíveis para
outros consumidores.

**Processo para nova Category:** proposta formal ao Framework, revisão de impacto em todos
os catálogos existentes, aprovação centralizada.

---

### DEC-02 — Tipos compartilhados existem como terceiro nível de catálogo

**Decisão:** além dos catálogos por Journey, existe um catálogo de Shared Event Types,
definido e gerenciado pelo Framework.

**Justificativa:** acontecimentos genéricos como `Phase.Started`, `Gate.Passed`,
`Impediment.Declared` são semanticamente idênticos em qualquer Journey. Forçar cada Journey
a criar seu próprio tipo equivalente violaria REG-01 e fragmentaria as análises.

**Impacto:** cada Journey pode usar tipos compartilhados diretamente, sem criar variações.
Tipos usados por mais de uma Journey e com semântica equivalente devem ser promovidos a
compartilhados.

---

### DEC-03 — Convenção de nomenclatura: `[Namespace.]Subject.Action`

**Decisão:** a convenção adotada é `[Namespace.]Subject.Action` com PascalCase em todos
os componentes. O Namespace (Journey ID) é opcional dentro do catálogo da Journey e
obrigatório em referências cross-Journey.

**Justificativa:** `Phase.Subject.Action` (três componentes fixos) seria verboso e
redundante dentro de um catálogo de Journey onde a Phase já é contexto. `Subject.Action`
com Namespace opcional oferece legibilidade local e precisão quando necessário.

**Alternativas descartadas:**
- `Journey.Phase.Action` — obrigatório sempre, verboso demais dentro do catálogo
- `Category.Subject.Action` — Category já é atributo do tipo; repetir no nome seria redundante
- `Phase.Action` puro — ambíguo em contexto cross-Journey (Deliver.Promote ≠ Diligence.Promote)

---

### DEC-04 — Event Types são imutáveis após aprovação

**Decisão:** propriedades críticas de um Event Type (Category, `alters_state`, `new_state`)
são imutáveis após status Active. Mudanças exigem deprecar o tipo e criar um novo.

**Justificativa:** Timelines são imutáveis (INV-02). Se um tipo ativo mudasse `alters_state`
de false para true, todos os eventos históricos desse tipo teriam seu impacto no Derived
State reinterpretado retroativamente — tornando a Timeline inconsistente sem que nenhum
novo evento fosse registrado.

---

### DEC-05 — Tipos depreciados permanecem referenciáveis em Timelines históricas

**Decisão:** um Event Type com status `Removed` continua sendo reconhecido para leitura
de Timelines históricas. A remoção é do catálogo de emissão (novos eventos não podem usar
o tipo), não do catálogo histórico.

**Justificativa:** Timelines são imutáveis. Um evento histórico com um tipo removido não
pode ser apagado ou alterado. Os Event Consumers devem tratar tipos removidos como válidos
para leitura histórica.

---

### DEC-06 — INV-TAX-04: consistência entre `alters_state` do tipo e da categoria

**Decisão:** um Event Type com `alters_state = true` deve pertencer a uma Category cujo
`alters_state` seja `Sim` ou `Condicional`. Não pode pertencer a uma Category com
`alters_state = Não`.

**Justificativa:** sem essa regra, um Event Consumer que filtra por Category para processar
mudanças de estado perderia eventos que alteram estado mas estão em Categories inesperadas.
A consistência é necessária para que Consumers possam otimizar o processamento.

---

## 4. Regras de Governança

### Mapa de responsabilidades

| Ação | Framework | Journey |
|---|---|---|
| Criar Event Category | Sim | Não |
| Deprecar Event Category | Sim | Não |
| Criar Shared Event Type | Sim (com proposta de Journey) | Proposta apenas |
| Criar Journey Event Type | Não (exceto tipos compartilhados) | Sim |
| Deprecar Journey Event Type | Não | Sim |
| Auditar conformidade cross-Journey | Sim | Não |
| Manter versionamento do catálogo | Framework (Taxonomy) | Journey (catálogo próprio) |

---

## 5. Convenção de Nomenclatura — Síntese

### Formato

```
[Namespace.]Subject.Action
```

### Exemplos canônicos por Category

```
Phase Lifecycle:    Bootstrap.Started / Bootstrap.Completed
                    Validate.Started / Validate.Completed

Gate:               Gate.Passed / Gate.Failed
                    (ou específico: Validate.Gate.Passed)

Human Decision:     Promote.Approved / Promote.Rejected
                    Review.Approved / Review.ChangesRequested

Blocking:           Impediment.Declared / Impediment.Resolved
                    Waiting.Declared / Waiting.Resolved

Rework:             Rework.Declared / Rework.Resolved

System:             Pipeline.Failed / Pipeline.Completed
                    Deploy.Completed / Deploy.Failed

Diligence:          Stale.Detected / Drift.Detected
                    MissingEvent.Detected

Correction:         Event.Corrected
```

### Referência cross-Journey (com Namespace)

```
Delivery.Bootstrap.Started
Diligence.Scan.DriftDetected
Assessment.Analysis.Completed
Shared.Gate.Failed
```

---

## 6. Conceitos Descartados ou Não Formalizados

| Conceito candidato | Decisão | Motivo |
|---|---|---|
| **Event Namespace como entidade** | Descartado | O Namespace é apenas um prefixo de nomenclatura, não uma entidade com vida própria |
| **Sub-categoria** | Descartado | Criaria hierarquia de classificação desnecessariamente complexa; especificidade deve viver no Event Type, não na Category |
| **Category herança** | Descartado | Categories são orthogonais por design; herança criaria ambiguidade |
| **Tipo versionado** | Descartado | Versão muda semântica → criar novo tipo, não versionar o existente |
| **Tipo genérico de Journey** | Descartado | Viola REG-01; todo tipo deve ter semântica precisa |

---

## 7. Ambiguidades Encontradas e Resoluções

### Amb-01 — `Phase.Completed` vs. evento específico de Phase

**Ambiguidade:** quando usar `Phase.Completed` (tipo compartilhado genérico) vs.
`Bootstrap.Completed` (tipo específico da Journey)?

**Resolução:** a Journey escolhe com base na necessidade de semântica adicional. Se
`Phase.Completed` carrega toda a informação necessária, use o compartilhado. Se a Journey
precisa de pré/pós-condições específicas de Bootstrap, crie `Bootstrap.Completed` na
Journey.

Os dois tipos podem coexistir — um compartilhado genérico e um específico mais rico — desde
que a Journey documente qual usa em cada Step.

---

### Amb-02 — Dois `Promote` nas Journeys

**Ambiguidade:** Delivery tem `Promote` (CI Async — promoção para produção) e Diligence
tem `Promote` (diligence-sync — promoção de OBC no backlog). O Event Type `Promote.Completed`
seria o mesmo?

**Resolução:** são tipos diferentes com semânticas distintas. Cada Journey define seu
`Promote.Completed` com pré e pós-condições específicas. Em referências cross-Journey:
`Delivery.Promote.Completed` e `Diligence.Promote.Completed` são inequívocos.

Não devem ser promovidos a tipo compartilhado — a semântica é genuinamente diferente.

---

### Amb-03 — Eventos de Category `System` que alteram estado

**Ambiguidade:** `Deploy.Completed` (System) claramente altera o Derived State (o item
passou para o estado pós-deploy). Mas Category System tem `alters_state = Raramente`.

**Resolução:** `Condicional` na Category não significa "nunca" — significa que nem todos
os tipos da Category alteram estado. Cada Event Type declara individualmente seu
`alters_state`. A consistência INV-TAX-04 exige apenas que um tipo `alters_state = true`
NÃO pertença a Category com `alters_state = Não`. System com `alters_state = Raramente`
é compatível com um tipo específico que tem `alters_state = true`.

---

## 8. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| **Journeys criam tipos sem verificar duplicatas** | Alta | Alto | REG-01 obrigatório; revisão de catálogos antes de aprovação |
| **Nomenclatura inconsistente entre catálogos** | Média | Médio | REG-04 obrigatório; lint automático no futuro (`events/schema.md`) |
| **Pressão para criar novas Categories ad-hoc** | Baixa | Alto | Processo de proposta formal; recusa padrão com alternativa nas existentes |
| **Tipos depreciados nunca removidos** | Média | Baixo | Ciclo de vida com critérios objetivos de remoção (seção 6.5) |
| **Tipos compartilhados sendo subutilizados** | Alta | Médio | Auditoria cross-Journey ao revisar novos catálogos |

---

## 9. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado |
| Derived State como projeção da Timeline | Preservado |
| Event Category como conceito formal da Ontologia | Preservado e expandido |
| Event Type como conceito formal da Ontologia | Preservado e expandido |
| Event Producer e Consumer como papéis | Preservado |
| COR como consumidora do OEM | Preservado |
| Diligence como verificadora de consistência | Preservado |
| Nenhuma Journey foi alterada | Confirmado |
| Nenhum Skill foi alterado | Confirmado |
| Nenhum manifest foi alterado | Confirmado |
| Nenhuma ontologia do Framework foi alterada | Confirmado |
| README e Ontologia do OEM não alterados | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 10. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas |
|---|---|
| `prodops/framework/events/taxonomy.md` | ~520 |
| `prodops/documentation-review-operational-event-taxonomy.md` | Este arquivo |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 11. Próximos Passos Sugeridos

| Documento | Depende de | Prioridade |
|---|---|---|
| `events/shared-types.md` | Taxonomia | Alta — formaliza os tipos compartilhados usados por todas as Journeys |
| `events/schema.md` | Taxonomia + Ontologia | Alta — define a estrutura técnica de um Event Type; desbloqueia catálogos |
| `journeys/delivery/events/catalog.md` | Schema + Taxonomy | Alta — caso de uso mais maduro; 83 tipos propostos no documento de análise |
| `events/categories.md` | Taxonomia | Média — expande cada Category com exemplos detalhados |
| `events/timeline.md` | Taxonomia + Ontologia | Média — formaliza o comportamento da Timeline |
| `journeys/diligence/events/catalog.md` | Schema + Taxonomy | Baixa — após Delivery estar estável |
