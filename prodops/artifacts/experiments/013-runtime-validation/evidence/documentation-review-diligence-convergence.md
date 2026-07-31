# Relatório de Convergência Conceitual — Execução
# ProdOps Framework Documentation Convergence

> Executado em: 2026-07-23  
> Escopo: toda a documentação sob `prodops/framework/`, `prodops/skills/`, `AGENTS.md`  
> Status: **concluído — todos os arquivos normativos corrigidos**

---

## 1. Executive Summary

Foram aplicadas todas as 11 decisões canônicas (D1–D11) e resolvida a lacuna L-003. A execução corrigiu 7 bloqueadores críticos para a implementação consistente da Diligence, além de 9 divergências de média e baixa prioridade.

**Resultados:**

| Categoria | Total identificado | Corrigido | Deixado para fase futura |
|---|---|---|---|
| Divergências | 19 | 16 | 3 (ver seção 6) |
| Ambiguidades | 5 | 1 | 4 (ver seção 7) |
| Lacunas | 4 | 1 (L-003) | 3 (ver seção 6) |
| Bloqueadores para Diligence | 7 | 7 | 0 |

**Decisões aplicadas:** D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11

**Arquivos modificados:** 21 (PT + EN) — ver tabela completa na seção 3

**Nenhum commit foi feito.** Nenhuma nova capability, workflow, script ou reorganização de diretório foi introduzida.

---

## 2. Decisões Canônicas Aplicadas

| Decisão | Conceito | Interpretação anterior | Interpretação canônica | Arquivos corrigidos |
|---|---|---|---|---|
| **D1** | Work Item title format | `[Operation] — [Artifact Type] [Artifact ID]: descrição` | `[Artifact ID]: descrição concisa` | `AGENTS.md`, `diligence-sync.md` |
| **D2** | Workspace Reconciliation | Cycle em `ontology.md` e em seção de Ciclos do `diligence/README.md` | Capability — invocada por Bootstrap, Diligence Async e Diligence Sync | `ontology.md`, `workspace-reconciliation.md` |
| **D3** | Business Signal Issue / Business Intent Issue | Termos canônicos definidos no glossário | Anti-padrões. Substituídos por "Business Signal Work Item" e "Business Intent Work Item" | `glossary.md`, `glossary.en.md`, `backlogs.md`, `backlogs.en.md` |
| **D4** | Cardinalidade N:M artefato-Work Item | Ausência de Issue = divergência | Ausência de Issue só é divergência quando há operação ativa sem Work Item rastreável | `scan/SKILL.md`, `capture/SKILL.md`, `flow.md`, `flow.en.md` |
| **D5** | Product Backlog — conteúdo | Contém "OBCs (Local OBCs)" | Contém Business Intents (cada com Local OBC como contrato) | `glossary.md`, `glossary.en.md` |
| **D6** | OBC Partitioning — classificação | "capability" em `obc.md`, `backlogs.md`, `glossary.md` | "processo de governança" — atividade pontual de responsabilidade humana | `obc.md`, `backlogs.md`, `glossary.md`, `glossary.en.md`, `backlogs.en.md` |
| **D7** | Responsabilidade da Diligence | "aderência ao modelo operacional" em `journeys/README.md` | "Garantir a consistência do sistema de trabalho do ProdOps" | `journeys/README.md`, `journeys/README.en.md` |
| **D8** | Reliability Plan — gate | Gate universal sem condicional em `delivery/README.md` | Gate condicional: financeiro, integração externa, SLO, risco alto/crítico, persistência ou segurança | `delivery/README.md` |
| **D9** | Icebox — critério de entrada | "Local OBC em estado Draft" | "Local OBC transitioning de Draft para Refining — início do Discovery ativo" | `artifact-governance.md` |
| **D10** | Iteration Backlog — critério de entrada | "OBC Committed + BDD Feature draft" | "OBC Committed + Discovery suficiente + Riscos identificados" (BDD committed só é requisito do Iteration Plan) | `artifact-governance.md` |
| **D11** | Guardrail "Nunca inventar OBCs" | Proibia toda criação de OBC pela Diligence, gerando conflito com step Capture que cria OBCs | Esclarecido: Diligence PODE criar OBC quando há gatilho canônico documentado. Não pode inventar conteúdo, intenção ou comprometimento | `diligence/SKILL.md`, `capture/SKILL.md` |

---

## 3. Arquivos Modificados

| Arquivo | Razão | Decisões aplicadas | EN atualizado | Validação grep |
|---|---|---|---|---|
| `prodops/framework/ontology.md` | D2: remover workspace-reconciliation de Cycles; D13: adicionar Readiness Verification; D2: nota explicativa | D2, D13 | Via `ontology.en.md` (não existe — ontologia não tem EN companion) | ✓ |
| `prodops/framework/journeys/README.md` | D4, D7: reescrita completa com vocabulário canônico | D4, D7, + Portfolio/Product Tracking List | `README.en.md` | ✓ |
| `prodops/framework/journeys/README.en.md` | Companion EN — mesma correção | D4, D7 | — | ✓ |
| `prodops/framework/glossary.md` | D3, D5, D6 + Business Signal/Intent representação no Execution Space | D3, D5, D6 | `glossary.en.md` | ✓ |
| `prodops/framework/glossary.en.md` | D3, D5, D6 — companion EN | D3, D5, D6 | — | ✓ |
| `prodops/framework/flow.md` | D4: remover "Business Signal Issue" como output do registro de Business Signal | D4 | `flow.en.md` | ✓ |
| `prodops/framework/flow.en.md` | D4 — companion EN | D4 | — | ✓ |
| `prodops/framework/journeys/delivery/README.md` | D8: adicionar cláusula condicional ao Reliability Plan | D8 | Não existe companion EN identificado | ✓ |
| `prodops/framework/artifact-governance.md` | D9: critério Icebox; D10: critério Iteration Backlog | D9, D10 | Não existe companion EN | ✓ |
| `prodops/framework/obc.md` | D6: OBC Partitioning = processo de governança, não capability | D6 | Não existe companion EN | ✓ |
| `prodops/framework/backlogs.md` | D3, D6: entity table e OBC Partitioning | D3, D6 | `backlogs.en.md` | ✓ |
| `prodops/framework/backlogs.en.md` | D3, D6 — companion EN | D3, D6 | — | ✓ |
| `prodops/framework/journeys/diligence/workspace-reconciliation.md` | D2: reforçar classificação como Capability; link quebrado D15 | D2, D15 | Não existe companion EN | ✓ |
| `AGENTS.md` | D1: formato de título de Work Item | D1 | Não aplicável | ✓ |
| `prodops/framework/journeys/diligence/diligence-sync.md` | D1: formato de título e exemplo | D1 | Não existe companion EN | ✓ |
| `prodops/skills/diligence/diligence-sync/steps/capture/SKILL.md` | D4, D11: remover obrigação 1:1 Signal-Issue; esclarecer criação de OBC | D4, D11 | Companion EN não identificado | ✓ |
| `prodops/skills/diligence/diligence-async/steps/scan/SKILL.md` | D4: corrigir lógica de verificação de Business Signal | D4 | Companion EN não identificado | ✓ |
| `prodops/skills/diligence/SKILL.md` | D11: atualizar guardrail "Nunca inventar OBCs" | D11 | Companion EN não identificado | ✓ |
| `prodops/framework/execution-mapping/work-item-schema.md` | L-003: adicionar matriz de ciclo de vida do Work Item em transições do OBC | L-003 | Companion EN não identificado | ✓ |
| `prodops/framework/journeys/operation/README.md` | Vocabulário: "Repository Tracking List" → "Product Tracking List"; "Product Intent Backlog" → "Product Backlog" | D4, vocab | `README.en.md` | ✓ |
| `prodops/framework/journeys/operation/README.en.md` | Companion EN — mesma correção | D4, vocab | — | ✓ |

---

## 4. Resultados do Global Search (pós-edição)

### `[Operation] —` em documentos normativos

```
prodops/skills/diligence/diligence-async/steps/scan/SKILL.md:52:
  | Título começa com `[Operation] —` (padrão antigo) |
```

**Status:** CORRETO — este é o critério de detecção do padrão antigo no scan. A linha identifica divergências com o padrão antigo para que o Repair possa corrigi-las. Não é uso normativo do padrão.

### `Business Signal Issue` em documentos normativos

```
prodops/framework/knowledge-vs-execution.md:220:
  ❌ "Business Signal Issue" como tipo canônico de Issue
```

**Status:** CORRETO — está na seção "Incorreto", identificando o padrão como erro. Não é definição normativa.

Restantes: somente em `documentation-review-diligence.md` (histórico de auditoria — não corrigir) e em arquivos de trilha histórica (`trails/sessions/`).

### `Business Intent Issue` em documentos normativos

```
prodops/framework/knowledge-vs-execution.md:272:
  | "A Business Intent Issue #42" | Nomeia a Issue pelo artefato, estabelecendo 1:1 |
```

**Status:** CORRETO — está na tabela "Erros comuns", identificando o padrão como erro. Não é definição normativa.

### `Product Intent Backlog` em documentos normativos

Sem ocorrências em documentos normativos após as correções. Restam apenas em:
- `trails/sessions/2026-07-13-08117eda.md` — registro histórico de sessão (não corrigir)
- `trails/sessions/legacy.md` — registro histórico (não corrigir)

### `Repository Tracking List` em documentos de framework normativos

Sem ocorrências normativas problemáticas após as correções. Restam em:
- `framework/journeys/discovery/upstream-trail.md` e `.en.md` — trilhas históricas de discovery (não são documentos normativos do framework, são registros de sessão histórica)
- `framework/journeys/assessment/reliability-plans/setup/` — prompts/templates que referenciam o artefato local do produto pelo nome que ele tem no produto (`Repository Tracking List` é o nome real do arquivo `tracking-list.md` neste produto). Conservado conforme critério de conservadorismo.
- Arquivos de experimentos e artefatos de produto — content artifacts, fora do escopo.

### `Global Tracking List` em documentos normativos

Sem ocorrências após a correção do `journeys/README.md` e `journeys/README.en.md`.

---

## 5. Validações Executadas

```bash
# Verificação final dos padrões obsoletos em docs normativos
grep -rn "Business Signal Issue|Business Intent Issue|Product Intent Backlog|\[Operation\] —" \
  prodops/framework/ prodops/skills/ AGENTS.md --include="*.md" \
  | grep -v "documentation-review-diligence|knowledge-vs-execution|padrão antigo|old pattern"
```

**Resultado:** Sem ocorrências. Todos os documentos normativos estão limpos.

```bash
# Verificação de workspace-reconciliation como Cycle
grep -rn "workspace-reconciliation" prodops/framework/ontology.md
```

**Resultado:** workspace-reconciliation só aparece na nota explicativa, não mais na tabela de Cycles.

```bash
# Verificação de Readiness Verification na ontologia
grep -n "Readiness Verification" prodops/framework/ontology.md
```

**Resultado:** Presente na lista de Framework Capabilities da área Diligence.

```bash
# Verificação do formato de título em AGENTS.md e diligence-sync.md
grep -n "Artifact ID" AGENTS.md prodops/framework/journeys/diligence/diligence-sync.md
```

**Resultado:** Ambos usam o padrão canônico `[Artifact ID]: descrição concisa`.

---

## 6. Itens NÃO Alterados (deliberadamente)

### 6a. Divergências com correção parcial aplicada

**D-016 (parcialmente resolvida como D11)**
A correção do guardrail "Nunca inventar OBCs" foi aplicada em `diligence/SKILL.md` e `capture/SKILL.md`. O esclarecimento completo sobre "criar vs. sincronizar" (ver Ambiguidade A-002 aberta) permanece em aberto — requer decisão de produto.

---

### 6b. Ambiguidades em aberto

**A-001: "Exploration" — etapa do fluxo ou atividade contínua?**
Não resolvida. Requer decisão conceitual sobre se Exploration se aplica apenas ao período Icebox ou também durante Operation.

**A-002: Quando Diligence "sincroniza" vs. quando "cria"?**
Parcialmente resolvida pelo D11, mas o escopo exato de criação para casos edge permanece ambíguo. Requer decisão de produto.

**A-004: "Diligence sincroniza as decisões do Assessment" — o que significa?**
Não esclarecido se "sincronizar uma decisão" gera Work Items, atualiza estados de OBC, ou ambos. Requer decisão sobre protocolo operacional.

**A-005: Promoção de Upstream — pula o Icebox?**
O comportamento de item promovido de Upstream que satisfaz critérios Committed foi mantido como está (documentado em `backlogs.md`). Estados intermediários válidos para promoção de Upstream não foram formalizados.

---

### 6c. Lacunas em aberto

**L-001: Protocolo de transição de modo Upstream → Downstream**
Não documentado. Requer decisão de produto: quem documenta, onde registrar, qual critério mínimo para "transição explícita".

**L-002: Business Intents sem OBC associado**
Os ciclos de Diligence ainda assumem que toda Business Intent tem um Local OBC. O protocolo para estado pré-Draft (Intent sem OBC criado) não foi adicionado. Requer decisão de produto.

**L-004: Nível de automação nos steps do Workspace Reconciliation**
Os steps individuais (Inspect, Reconcile, Verify) não documentam qual nível de automação (API/MCP/CLI/SDK/Browser) deve ser tentado por ação específica. Deixado para quando os steps forem implementados.

---

### 6d. Conteúdo deliberadamente não alterado (fora de escopo)

**`artifacts/product/backlogs/tracking-list.md`** (content artifact de produto)
Contém "Business Signal Issue" na nota de cabeçalho. Arquivo de conteúdo de produto — fora do escopo. Requer atualização manual pelo Product Owner.

**Arquivos de experimentos e trails históricas**
`prodops/artifacts/experiments/` e `prodops/artifacts/trails/sessions/` usam "Repository Tracking List" e "Product Intent Backlog". São registros históricos de sessão — não são documentos normativos. Não corrigidos (trilhas históricas com vocabulário antigo não são divergências normativas).

**`framework/journeys/assessment/reliability-plans/setup/` prompts**
Referenciam "Repository Tracking List" como nome do artefato local do produto. Conservado — referência local ao produto, não afirmação normativa sobre vocabulário do framework.

---

## 7. Riscos Residuais

| Risco | Descrição | Impacto se não resolvido | Ação recomendada |
|---|---|---|---|
| **R-1** | `tracking-list.md` (content artifact) ainda tem "Business Signal Issue" na nota de cabeçalho | Agentes que lerem apenas o artefato podem criar Issues por Signal passivo | Atualizar manualmente a nota do tracking-list.md — requer decisão do Product Owner |
| **R-2** | Ambiguidade A-002: linha entre "criar" e "sincronizar" na Diligence ainda não está formalmente definida | Agents podem interpretar de forma diferente quando devem criar vs. apenas registrar | Documentar protocolo de criação em `execution-mapping/README.md` ou `knowledge-vs-execution.md` |
| **R-3** | A-005: promoção de Upstream que pula Icebox não tem estados intermediários documentados | Diligence pode bloquear incorretamente itens promovidos de Upstream | Adicionar seção sobre "promoção de Upstream" em `backlogs.md` ou `flow.md` |
| **R-4** | `framework/journeys/assessment/reliability-plans/setup/` usa "Repository Tracking List" | Agentes que usam os prompts de Reliability Plan podem usar o nome antigo | Atualizar os prompts de setup quando for atualizar a documentação de Assessment |
| **R-5** | L-001: protocolo de transição de modo Upstream → Downstream não documentado | Agentes que tentam mudar de modo não sabem onde registrar a decisão | Documentar protocolo de transição de modo em `execution-model/` |

---

## Apêndice: Estrutura de mudanças por decisão

### D1 — Work Item title format
- `AGENTS.md`: linha `"3. Usar o padrão de título:"` → `[Artifact ID]: descrição concisa`
- `diligence-sync.md`: seção Attach → título canônico e exemplo corrigidos

### D2 — Workspace Reconciliation é Capability, não Cycle
- `ontology.md`: removida da tabela de Cycles; adicionada nota explicativa; removida da tabela de Phases
- `ontology.md`: "Readiness Verification" adicionada à lista de Capabilities da área Diligence (resolve D-013)
- `workspace-reconciliation.md`: nota reforçando classificação como Capability e ausência de acionamento próprio

### D3 — Business Signal Issue / Business Intent Issue não são termos canônicos
- `glossary.md`: entradas removidas e substituídas por "Business Signal Work Item" e "Business Intent Work Item"
- `glossary.en.md`: idem em inglês
- Campos "Representação no GitHub" nas entradas Business Signal e Business Intent: substituídos por "Representação no Execution Space" com explicação N:M

### D4 — Cardinalidade N:M
- `flow.md` e `flow.en.md`: "Business Signal Issue" removido dos outputs do Step 2
- `scan/SKILL.md`: lógica de detecção de Business Signal sem Issue corrigida para detectar apenas quando há operação ativa
- `backlogs.md` e `backlogs.en.md`: tabela de entidades corrigida
- `capture/SKILL.md`: obrigatoriedade de Issue por Business Signal removida

### D5 — Product Backlog contém Business Intents
- `glossary.md`: definição de Product Backlog corrigida
- `glossary.en.md`: idem em inglês

### D6 — OBC Partitioning é processo de governança
- `glossary.md`: definição corrigida
- `obc.md`: definição corrigida
- `backlogs.md`: definição corrigida
- `glossary.en.md` e `backlogs.en.md`: idem em inglês

### D7 — Responsabilidade da Diligence
- `journeys/README.md` e `journeys/README.en.md`: "aderência ao modelo operacional" → "consistência do sistema de trabalho do ProdOps"

### D8 — Reliability Plan é gate condicional
- `journeys/delivery/README.md`: cláusula condicional adicionada

### D9 — Icebox entry criterion
- `artifact-governance.md`: "Draft" → "transitioning de Draft para Refining"

### D10 — Iteration Backlog entry
- `artifact-governance.md`: "OBC Committed + BDD Feature draft" → critérios de `backlogs.md`

### D11 — Guardrail "Nunca inventar OBCs"
- `diligence/SKILL.md`: guardrail esclarecido — Diligence PODE criar OBC com gatilho canônico
- `capture/SKILL.md`: obrigatoriedade de gatilho canônico para criação de OBC documentada

### L-003 — Ciclo de vida do Work Item em transições do OBC
- `work-item-schema.md`: seção "Ciclo de vida do Work Item em transições do OBC" adicionada com matriz completa e princípios

### Vocabulário adicional (operation/README.md)
- `framework/journeys/operation/README.md` e `README.en.md`: "Repository Tracking List" → "Product Tracking List"; "Product Intent Backlog" → "Product Backlog"
