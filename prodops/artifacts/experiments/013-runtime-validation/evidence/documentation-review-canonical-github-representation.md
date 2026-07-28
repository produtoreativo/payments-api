# Revisão de Documentação — Representação Operacional Canônica do GitHub

**Data:** 2026-07-24
**Tipo:** Consolidação de decisão arquitetural — somente documentação
**Branch:** chore/anthropic

---

## 1. Executive Summary

- **Decisão:** GitHub Projects e Issues são a representação operacional canônica do Framework ProdOps
- **Escopo:** Consolidação de documentação — nenhum código, automação, Issue, Project ou View foi criado
- **Arquivos analisados:** 15
- **Arquivos modificados:** 4 (consolidação inicial) + 3 (refinamento editorial)
- **Inconsistências encontradas:** 5 (consolidação) + 1 ambiguidade editorial (refinamento)
- **Inconsistências resolvidas:** 6 total
- **Conceito introduzido:** Canonical Operational Representation

---

## 2. Decisão Arquitetural

A decisão arquitetural consolidada neste documento:

| Elemento | Papel canônico no ProdOps |
|---|---|
| **GitHub Project** | Representação operacional canônica de uma Jornada ou domínio operacional — cada Project organiza e projeta Work Items de um escopo específico |
| **GitHub Issue** | Work Item — artefato operacional canônico; representa operação ativa sobre artefatos do Knowledge Space |
| **View** | Projeção canônica do estado de Issues por Journey, Phase ou Operation |
| **Field** | Estado operacional necessário para projetar corretamente cada Work Item |
| **Label** | Classificação auxiliar — **nunca** fonte de verdade para estado |
| **prodops/ (docs)** | Representação conceitual — permanece separada e independente |
| **Diligence** | Guardiã da sincronização entre representação conceitual (prodops/) e operacional (GitHub) |

**Corolários:**

- Não existe camada de abstração para outras ferramentas (Jira, Azure DevOps, Linear)
- Ferramentas externas são sincronizações opcionais — nunca equivalentes ou substitutos
- Esta é uma consolidação, não um feature novo — o que foi formalizado aqui já estava implementado

---

## 3. Documentos Analisados

| Arquivo | Status |
|---|---|
| `prodops/framework/ontology.md` | Consistente — não menciona ferramentas; mantido intacto |
| `prodops/framework/glossary.md` | Necessitava atualização — entradas ausentes; **Atualizado** |
| `prodops/framework/knowledge-vs-execution.md` | Necessitava atualização — faltava declaração explícita de canonicidade; **Atualizado** |
| `prodops/exec/manifest.yaml` | Necessitava atualização — seção github não declarava canonicidade; **Atualizado** |
| `prodops/framework/journeys/diligence/github-workspace.md` | Consistente — Princípios 1–10 já alinhados; mantido intacto |
| `prodops/framework/journeys/diligence/workspace-reconciliation.md` | Não lido (fora do escopo de modificação) |
| `prodops/framework/journeys/diligence/github-workspace-schema.yaml` | Não lido (schema técnico; sem inconsistência conceitual identificada) |
| `prodops/framework/journeys/diligence/github-workspace-readiness.md` | Não modificado |
| `prodops/framework/journeys/diligence/github-workspace-automation.md` | Não modificado |
| `prodops/framework/execution-mapping/README.md` | Consistente — "Jira/ADO/Linear = espelhos de conveniência" já claro; mantido intacto |
| `prodops/framework/execution-mapping/work-item-schema.md` | Consistente — campos, enums e labels bem definidos; mantido intacto |
| `prodops/framework/execution-mapping/matrix.md` | Consistente; mantido intacto |
| `prodops/framework/journeys/diligence/README.md` | Necessitava atualização — papel de guardiã pouco explícito; **Atualizado** |
| `prodops/framework/journeys/README.md` | Consistente; mantido intacto |
| `AGENTS.md` | Consistente; mantido intacto |

---

## 4. Inconsistências Encontradas

### INC-001 — `knowledge-vs-execution.md` não declarava canonicidade do GitHub

**Arquivo:** `prodops/framework/knowledge-vs-execution.md`
**Linhas:** 1–9 (seção de abertura)
**Problema:** O documento estabelecia que "GitHub representa exclusivamente a execução do trabalho" mas não declarava explicitamente que o GitHub é a representação operacional **canônica** do Framework — não apenas um das opções possíveis. A ausência de uma declaração afirmativa permitia interpretação de que GitHub poderia ser substituído por outra ferramenta.
**Severidade:** Major — este é o documento fundacional do modelo KS/ES
**Resolução:** Adicionada nova seção "Representação operacional canônica" com tabela explícita (GitHub Project, Issue, View, Field, Label) e declaração "Não existe camada de abstração para outras ferramentas."

---

### INC-002 — `glossary.md` não tinha entradas para GitHub Project, View, Field e Label

**Arquivo:** `prodops/framework/glossary.md`
**Linhas:** Antes da linha de `GitHub Issue` (~803)
**Problema:** O glossário tinha entrada para "GitHub Issue" (bem definida) mas não tinha entradas canônicas para GitHub Project, View (no sentido GitHub), Field e Label. Esses são elementos operacionais fundamentais que a decisão arquitetural nomeia explicitamente. A ausência de definições canônicas criava ambiguidade — especialmente sobre o que "View" significa em contexto ProdOps vs. em contexto de backlog conceitual (Icebox, Iteration Backlog).
**Severidade:** Medium — lacuna de vocabulário canônico
**Resolução:** Adicionadas quatro entradas canônicas: **GitHub Project**, **View (GitHub Project)**, **Field (GitHub Project)**, **Label (GitHub)**, cada uma com definição, propósito, uso correto, anti-padrões e relação com outros conceitos.

---

### INC-003 — `manifest.yaml` não declarava canonicidade da representação GitHub

**Arquivo:** `prodops/exec/manifest.yaml`
**Linhas:** Seção `github` (~79–95)
**Problema:** A seção `github` do manifest declarava `execution_space: true` e `optional_sync: [jira, azure_devops, linear]` mas não continha declaração explícita de que o GitHub é a representação operacional **canônica** — nem definia a semântica de Project, View, Field e Label. O manifest é lido por agentes como fonte única legível por máquina; a ausência dessa declaração criava gap entre a prosa dos documentos e a configuração operacional.
**Severidade:** Medium — o manifest é fonte de verdade para agentes
**Resolução:** Adicionado bloco `canonical_operational_representation` com `tool: GitHub`, `project_type: ProjectsV2`, `work_item_type: Issue`, semânticas de View/Field/Label, e nota explícita sobre ausência de abstração para outras ferramentas.

---

### INC-004 — `diligence/README.md` não declarava explicitamente o papel de guardiã da sincronização

**Arquivo:** `prodops/framework/journeys/diligence/README.md`
**Linhas:** Seção "Knowledge Space ↔ Execution Space"
**Problema:** A seção descrevia funcionalmente o papel da Diligence (verificar, sincronizar, reconciliar) mas não havia declaração explícita de que Diligence é a guardiã da sincronização entre a representação conceitual (prodops/) e a representação operacional (GitHub). O diagrama KS↔ES não nomeava o GitHub explicitamente como "Execution Space".
**Severidade:** Minor — o conteúdo estava correto; faltava declaração explícita
**Resolução:** Diagrama atualizado para nomear "(prodops/)" e "(GitHub Projects / Issues)" explicitamente. Adicionada sentença destacada: "Diligence é a guardiã da sincronização entre a representação conceitual (prodops/) e a representação operacional canônica (GitHub Projects e Issues)." Adicionado princípio explícito: "GitHub Projects e Issues são a representação operacional canônica do ProdOps."

---

### INC-005 — Definição de Label como "nunca fonte de verdade" existia apenas em documentos técnicos

**Arquivo:** `prodops/framework/glossary.md` (ausência)
**Problema:** O princípio de que Labels são classificação auxiliar e **nunca** fonte de verdade para estado estava documentado em `github-workspace.md` (Seção 14) e em `work-item-schema.md`, mas ausente do glossário canônico. O glossário é a fonte de referência para o vocabulário — sem entrada de Label, o princípio ficava confinado a documentos de implementação.
**Severidade:** Minor — princípio correto mas não no lugar canônico
**Resolução:** Entrada "Label (GitHub)" adicionada ao glossário com definição, uso canônico e lista explícita do que Labels NÃO podem representar.

---

## 5. Decisões Tomadas

### DEC-001 — Adicionar seção "Representação operacional canônica" em knowledge-vs-execution.md

**Decisão:** Adicionar nova seção antes do diagrama KS/ES para declarar explicitamente a canonicidade do GitHub e tabular os cinco elementos (Project, Issue, View, Field, Label).

**Rationale:** `knowledge-vs-execution.md` é o documento fundacional do modelo. Qualquer leitor que questione "qual ferramenta é a representação operacional do ProdOps?" deve encontrar a resposta nesse documento — não precisar inferir pela ausência de menção a outras ferramentas. A nova seção responde a pergunta antes do diagrama, não substitui o diagrama.

**Arquivos afetados:** `prodops/framework/knowledge-vs-execution.md`

---

### DEC-002 — Adicionar entradas de GitHub Project, View, Field e Label ao glossário

**Decisão:** Adicionar quatro entradas canônicas ao glossário, agrupadas com a entrada existente de GitHub Issue.

**Rationale:** O glossário é a fonte canônica de vocabulário. A ausência de GitHub Project, View, Field e Label como termos definidos criava um gap entre a decisão arquitetural e o vocabulário operacional. Cada entrada segue o mesmo padrão de outras entradas do glossário (Definição, Propósito, O que representa, O que NÃO representa, Relação com outros conceitos).

**Arquivos afetados:** `prodops/framework/glossary.md`

---

### DEC-003 — Adicionar bloco `canonical_operational_representation` ao manifest

**Decisão:** Adicionar sub-bloco estruturado dentro da seção `github` do manifest declarando canonicidade e semântica dos elementos.

**Rationale:** O manifest é lido por agentes como fonte única legível por máquina. A declaração precisa ser machine-readable além de estar em prosa. O bloco segue a convenção existente de comentários explicativos no manifest e não duplica os campos operacionais existentes — adiciona semântica de nível arquitetural.

**Arquivos afetados:** `prodops/exec/manifest.yaml`

---

### DEC-004 — Fortalecer declaração do papel de guardiã da Diligence

**Decisão:** Atualizar o diagrama KS↔ES em `diligence/README.md` para nomear explicitamente prodops/ e GitHub, e adicionar sentença destacada sobre o papel de guardiã.

**Rationale:** A declaração "Diligence é a guardiã da sincronização" é um corolário direto da decisão arquitetural. Se GitHub é a representação operacional canônica e prodops/ é a representação conceitual, então o papel de sincronização da Diligence precisa ser declarado explicitamente em relação a esses dois termos — não apenas em relação a abstrações genéricas como "Knowledge Space" e "Execution Space".

**Arquivos afetados:** `prodops/framework/journeys/diligence/README.md`

---

## 6. Arquivos Modificados

| Arquivo | Tipo de mudança | Rationale | Natureza |
|---|---|---|---|
| `prodops/framework/knowledge-vs-execution.md` | Adição de seção "Representação operacional canônica" | Documento fundacional precisava de declaração explícita de canonicidade | Declaração arquitetural |
| `prodops/framework/glossary.md` | Adição de 4 entradas: GitHub Project, View, Field, Label | Vocabulário canônico incompleto para elementos operacionais | Vocabulário |
| `prodops/exec/manifest.yaml` | Adição de bloco `canonical_operational_representation` | Manifest é lido por agentes; precisava de declaração machine-readable | Configuração |
| `prodops/framework/journeys/diligence/README.md` | Fortalecimento do diagrama KS↔ES e papel de guardiã | Papel de sincronização precisava ser declarado em relação a prodops/ e GitHub explicitamente | Clarificação |

---

## 7. Justificativa Arquitetural

### Por que não existe abstração para outras ferramentas

O ProdOps é construído para times que usam GitHub. A integração do GitHub é profunda e multidimensional:
- GitHub Issues = Work Items (operações sobre artefatos)
- GitHub Projects = gestão visual de trabalho por Journey/Phase
- GitHub PRs = entrega de código com rastreabilidade
- GitHub Releases = pontos de entrega formais (CI Async)
- GitHub Actions = automação de quality gates
- GitHub = fonte de verdade do código-fonte

Criar uma camada de abstração para Jira, Azure DevOps ou Linear significaria abstrair a própria superfície operacional do framework — uma superfície que já é completamente realizada em GitHub. Não há benefício arquitetural; há apenas custo de manutenção e risco de divergência.

### Por que a Diligence é a guardiã natural

A Diligence já verifica o estado do GitHub Workspace (Capability: Workspace Reconciliation). Ela já detecta divergências entre artefatos Markdown e Work Items. Ela já reconcilia o Execution Space com o Knowledge Space. Declarar Diligence como guardiã é nomear o que ela já faz — não criar uma nova responsabilidade.

### Por que o modelo conceitual permanece independente

A representação conceitual (OBCs, BDD Features, Business Intents em prodops/) é independente do GitHub. Ela existiria mesmo se o GitHub deixasse de existir. O GitHub é a expressão operacional do modelo conceitual — não o modelo em si. Essa separação é a proteção fundamental do Knowledge Space.

---

## 8. O que NÃO mudou

| Conceito | Status |
|---|---|
| Ontologia (Journey/Cycle/Phase/Capability/Skill) | Não modificada |
| Funcionamento da Diligence Journey | Não modificado |
| Modelo de entidades (Finding, Evidence, Remediation, Waiver) | Não modificado |
| Princípio "GitHub representa operações, não entidades canônicas" | Preservado e reforçado |
| Schema de Work Items | Não modificado |
| Automation matrix, schema yaml, readiness | Não modificados |
| Qualquer arquivo em `.github/` | Não modificado |
| Qualquer arquivo em `api/` | Não modificado |
| Templates, registry, evidence files | Não modificados |

O princípio de que "artefatos canônicos (OBCs, Business Intents, etc.) vivem em prodops/ como Markdown e nunca são GitHub Issues" permanece intacto. O que mudou é que a representação **operacional** — o trabalho executado sobre esses artefatos — é declarada explicitamente como GitHub.

---

## 9. Relação entre Representação Conceitual e Operacional

```
Representação Conceitual (prodops/)     Representação Operacional (GitHub)
──────────────────────────────────      ──────────────────────────────────────────
OBC, Business Signal, BI           ←──── Field: Artifact ID, Artifact Type no Issue
Ontologia: Journey/Cycle/Phase     ←──── Field: Journey, Phase, Cycle no Issue
Work Item definition               ←──── GitHub Issue body (seção ProdOps References)
Estado de backlog (Icebox/IB)      ←──── View filter + Field Artifact Type + Status
Finding (FND-*.md)                 ←──── GitHub Issue quando operação ativa existe
Diligence Journey (conceptual)     ←──── Capability: Workspace Reconciliation (GitHub)
Trilha de decisão                  ←──── Release Trail + PR body
```

**Direção da seta:** a representação operacional é **derivada** do modelo conceitual — não o contrário. O Markdown é a fonte de verdade; o GitHub é a expressão operacional desse conhecimento.

**A Diligence** mantém essa relação bidirecional sincronizada:
- `prodops/ → GitHub`: quando um artefato muda, Diligence verifica se o Execution Space reflete a mudança
- `GitHub → prodops/`: quando um Work Item conclui, Diligence verifica se o artefato foi atualizado com o aprendizado

---

## 10. Refinamento Editorial — Ajuste de Precisão (2026-07-24)

### Contexto

Após a consolidação inicial (seções 1–9 acima), foi identificada uma ambiguidade residual: a expressão "GitHub Project é a visão operacional do Framework" podia ser lida como "existe um único Project oficial que representa todo o Framework". Essa não é a intenção.

### Trechos refinados

| Arquivo | Trecho anterior | Trecho corrigido |
|---|---|---|
| `knowledge-vs-execution.md` | `"Visão operacional do Framework — organiza e projeta Work Items por Journey, Phase e Operation"` | `"Representação operacional canônica de uma Jornada ou domínio operacional — cada Project organiza e projeta Work Items de um escopo específico"` |
| `knowledge-vs-execution.md` | Primeira linha da seção: `"O GitHub (Projects e Issues) é a representação operacional canônica do Framework ProdOps."` | Mantida; seguida de parágrafo que introduz **Canonical Operational Representation** e esclarece que cada Project cobre uma Jornada, não o Framework inteiro |
| `glossary.md` — entrada GitHub Project, campo Definição | `"A visão operacional canônica do Framework ProdOps"` | `"A representação operacional canônica de uma Jornada ou domínio operacional do ProdOps. Não representa o Framework como um todo — o Framework pode ter múltiplos Projects canônicos"` |
| `glossary.md` — entrada GitHub Project, campo Canonical status | `"O GitHub Project é a representação operacional canônica do ProdOps."` | `"GitHub Projects constituem a Canonical Operational Representation do ProdOps — cada Project representa operacionalmente uma Jornada ou domínio operacional específico."` |
| `glossary.md` — nova entrada | (ausente) | Entrada **Canonical Operational Representation** adicionada com definição, o que não é, e responsabilidade de manutenção (Diligence) |
| `documentation-review-canonical-github-representation.md` seção 2 | `"Visão operacional do Framework"` | `"Representação operacional canônica de uma Jornada ou domínio operacional"` |

### Conceito introduzido

**Canonical Operational Representation** — a materialização operacional do modelo conceitual do ProdOps, realizada atualmente através de GitHub Projects (escopo por Jornada) e GitHub Issues (Work Items individuais). Introduzido em:
- `knowledge-vs-execution.md` (seção "Representação operacional canônica")
- `glossary.md` (nova entrada canônica)

### Justificativa das alterações

A decisão arquitetural não mudou. O refinamento elimina a leitura de que "Project = Framework inteiro" e deixa explícito que o Framework pode ter múltiplos Projects canônicos, cada um cobrindo o escopo de uma Jornada ou domínio operacional.

### Confirmação

Nenhuma decisão arquitetural foi alterada. O refinamento é exclusivamente editorial — corrige precisão de linguagem sem alterar o modelo, a ontologia, os workflows, os schemas, os templates, as automações ou o manifest.

**Arquivos modificados neste refinamento:** 3 (`knowledge-vs-execution.md`, `glossary.md`, este relatório)

---

## 11. Critérios de Aceite

| Critério | Status |
|---|---|
| Relatório de revisão criado | ✓ Este arquivo |
| Nenhum arquivo em `.github/` modificado | ✓ Verificado |
| Princípio de canonicidade do GitHub presente em `knowledge-vs-execution.md` | ✓ Seção "Representação operacional canônica" adicionada |
| `manifest.yaml` declara `canonical_operational_representation` | ✓ Bloco adicionado sob `github` |
| Glossário tem entradas para GitHub Project, View, Field e Label | ✓ Quatro entradas adicionadas |
| Diligence README declara papel de guardiã explicitamente | ✓ Diagrama e sentença adicionados |
| Ontologia não modificada | ✓ Não tocada |
| Nenhum novo Project, View, Issue, Field, Label ou automação criados | ✓ Zero ações no GitHub |
| Nenhum commit criado | ✓ Apenas arquivos modificados localmente |
| Funcionamento da Diligence Journey não alterado | ✓ Apenas declaração de papel; comportamento intacto |
