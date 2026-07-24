# GitHub Workspace — Especificação Canônica da Diligence

> **Versão:** 1.0.0-draft
> **Criado em:** 2026-07-24
> **Status:** Especificação — não implementação
> **Fonte de verdade para:** Workspace Reconciliation (Capability)
> **Escopo:** Representa operações da Diligence no GitHub — não as entidades canônicas em si

---

## Seção 1 — Propósito

Este documento especifica como o Execution Space do GitHub (Issues, Pull Requests, Projects, Labels, Releases) deve ser configurado e utilizado para representar **operações** sobre entidades da jornada Diligence.

**O que este documento especifica:**

- Critérios para criação de Work Items de Diligence
- Schema de campos no GitHub Project
- Política de autoridade por campo
- Labels e sua semântica
- Uso de Pull Requests e Releases
- Views planejadas e suas limitações
- Anti-padrões a evitar

**O que este documento NÃO especifica:**

- Como as entidades canônicas são definidas internamente (ver `model/`)
- Como os ciclos diligence-sync e diligence-async executam suas fases (ver `diligence-sync.md`, `diligence-async.md`)
- Quais comandos GitHub CLI executar para criar campos, labels ou views
- Automações, GitHub Actions ou scripts de sincronização

**Este documento é uma especificação, não uma implementação.** Nenhuma ação no GitHub é executada pela existência deste arquivo. A Workspace Reconciliation (Capability) usará este documento como entrada para a fase Inspect e como estado esperado para a fase Reconcile.

---

## Seção 2 — Princípios

### Princípio 1 — O GitHub representa operações, não entidades canônicas

> **O GitHub representa operações sobre entidades da Diligence. Ele não representa as entidades canônicas em si.**

Finding, Evidence, Remediation, Waiver e Check são entidades do Knowledge Space. Elas existem como arquivos Markdown no repositório git com identidade permanente. O GitHub Project organiza e visualiza as **operações** que estão sendo executadas sobre essas entidades — não as entidades em si.

### Princípio 2 — Finding pode existir sem nenhum Work Item

Um Finding pode existir em `artifacts/diligence/findings/FND-YYYY-NNNN.md` sem que haja qualquer Issue, PR ou Project Item correspondente. Isso é o estado correto quando não há operação ativa sobre o Finding. A ausência de Work Item não é uma divergência.

### Princípio 3 — Knowledge Space é a fonte de verdade para entidades

O estado canônico de um Finding, sua severidade, seu status, seus campos obrigatórios — tudo vive no arquivo `FND-YYYY-NNNN.md`. O estado canônico de um Waiver (incluindo expiração) vive em `WVR-YYYY-NNNN.md`. Nenhum campo no GitHub Project pode substituir o arquivo canônico como fonte de verdade.

### Princípio 4 — GitHub Project organiza Work Items e operações visíveis

O GitHub Project é um espaço de organização e visualização de trabalho em andamento. Ele exibe Work Items que representam operações ativas sobre entidades da Diligence. Não substitui o Knowledge Space. Não é fonte de verdade do estado das entidades.

### Princípio 5 — Cardinalidade N:M é preservada

A relação entre entidades Diligence e Work Items é N:M:

- Um Finding pode ter zero, um ou múltiplos Work Items ao longo de sua vida (um por operação ativa)
- Um Work Item pode referenciar múltiplos Findings quando a operação trata vários em conjunto
- Uma Remediation pode ter múltiplos Work Items (investigação, implementação, verificação)
- Um Work Item pode endereçar múltiplas Remediations relacionadas

### Princípio 6 — Nenhuma Issue artificial criada para cobertura visual

Issues NÃO são criadas apenas para que um Finding apareça no GitHub Project. Se um Finding não tem operação ativa, ele não aparece no Project. Isso é correto. A visibilidade completa de Findings vem de `registry.yaml`, relatórios agregados e dashboards — não do Project.

### Princípio 7 — Edições manuais em campos do Knowledge Space criam drift

Campos que refletem estado de entidades do Knowledge Space (Finding Severity, Finding Status, Waiver Expiration) não devem ser editados manualmente no GitHub Project. Edição manual cria drift entre o Project e o arquivo canônico, o que é detectável por DIL-WSP-001 e pode gerar Finding estrutural ou operacional.

### Princípio 8 — Estado da entidade ≠ estado da operação

O status de um Work Item (Todo, In Progress, Done) representa o estado da **operação** sendo executada. O status de um Finding (Open, In Remediation, Resolved, Verified) representa o estado **canônico da condição** detectada. São independentes e nunca sincronizados automaticamente por status de Work Item.

### Princípio 9 — Sincronização com direção declarada por campo

Não existe sincronização bidirecional sem regras. Cada campo tem uma fonte de verdade declarada e uma direção de fluxo definida. Campos cujo dono é o Knowledge Space fluem `Knowledge → GitHub`. Campos cujo dono é o Execution Space ficam no GitHub (Execution-only). Campos derivados são calculados a partir das entidades canônicas.

### Princípio 10 — Workspace Reconciliation é a única via de reconciliação autorizada

Divergências entre este documento e o estado real do workspace GitHub são resolvidas pela Capability Workspace Reconciliation (Inspect → Reconcile → Verify). Correções manuais fora desse processo não são rastreáveis e podem criar novas divergências.

---

## Seção 3 — Entidades no Knowledge Space

As entidades canônicas da Diligence vivem no Knowledge Space como arquivos Markdown. Elas não são entidades do GitHub.

| Entidade | ID Canônico | Localização | Representação no GitHub |
|---|---|---|---|
| Check | `DIL-CATEGORY-NNN` | `prodops/framework/journeys/diligence/checks/catalog.yaml` | Referência em Issue/PR body; raramente Work Item |
| Finding | `FND-YYYY-NNNN` | `prodops/artifacts/diligence/findings/` | Work Item apenas quando há operação ativa |
| Evidence | `EVD-YYYY-NNNN` | `prodops/artifacts/diligence/evidence/` | Referência em body de Issue/PR; raramente Work Item próprio |
| Remediation | `RMD-YYYY-NNNN` | `prodops/artifacts/diligence/remediations/` | Work Item na maioria das operações ativas |
| Waiver | `WVR-YYYY-NNNN` | `prodops/artifacts/diligence/waivers/` | Work Item de revisão/aprovação; aprovação canônica no arquivo |

**Reforço:** Nenhuma dessas entidades É um GitHub Issue. Um Finding não é uma Issue. Uma Remediation não é uma Issue. Um Waiver não é um label ou status.

---

## Seção 4 — Operações no Execution Space

O diagrama abaixo ilustra a separação entre entidades canônicas (Knowledge Space) e operações representadas no GitHub (Execution Space):

```
Knowledge Space
Check ────────► definição em checks/catalog.yaml
Finding ──────► artifacts/diligence/findings/FND-*.md
Evidence ─────► artifacts/diligence/evidence/EVD-*.md
Remediation ──► artifacts/diligence/remediations/RMD-*.md
Waiver ───────► artifacts/diligence/waivers/WVR-*.md
                         │ referências
                         ▼
Execution Space
Work Item ───► investigar, corrigir, verificar ou aprovar
Pull Request ► alterar entidades ou implementar Remediation
Release ─────► entregar mudança e produzir Evidence
Project ─────► organizar e visualizar operações
```

A seta tem direção única: Knowledge Space gera operações no Execution Space. O Execution Space não gera entidades canônicas — ele referencia entidades existentes.

---

## Seção 5 — Critérios para criar Work Item

### Finding — Quando Work Item NÃO é necessário

- Finding informativo (severidade Info) detectado e registrado sem ação subsequente
- Finding detectado e resolvido na mesma execução (detectado e corrigido no mesmo ciclo)
- Finding não requer investigação — condição é autoevidente
- Finding não requer Remediation — aceito como estado permanente com justificativa registrada no arquivo
- Finding registrado apenas para histórico e rastreabilidade de auditoria
- Finding coberto por operação agregada existente (um Work Item de reconciliação que trata múltiplos Findings)

### Finding — Quando Work Item É necessário

- Finding requer investigação para determinar causa raiz
- Finding requer owner designado e responsabilidade operacional rastreável
- Finding requer ação futura com prazo
- Finding requer Remediation planejada ou aprovada
- Finding requer verificação independente após correção
- Finding bloqueia uma transição de estado ou promoção
- Finding requer rastreamento formal com histórico de decisões
- Finding requer decisão humana sobre estratégia (aceitar, remediar, dispensar)

### Remediation — Quando Work Item é normal

Uma Remediation normalmente tem Work Item quando está:
- Aprovada e aguardando início de implementação (status Approved)
- Em implementação ativa (status In Progress)
- Parcialmente implementada aguardando continuação
- Implementada aguardando verificação independente

Remediation documental simples (correção apenas de documentação sem impacto técnico) pode ser concluída na mesma PR que detectou o Finding, sem Issue separada, desde que a rastreabilidade seja mantida (referências no PR body).

### Waiver — Critérios

- Preparação ou revisão de Waiver pode ter Work Item próprio
- Aprovação canônica deve existir no arquivo `WVR-YYYY-NNNN.md` com Evidence referenciada
- Issue, status de Project ou label NÃO constituem aprovação de Waiver suficiente
- Um Work Item de revisão de Waiver pode existir para facilitar revisão por humano autorizado

### Evidence — Critérios

- Evidence não requer Work Item próprio por padrão
- Coleta complexa ou recorrente de Evidence pode ter Work Item quando a coleta é extensa, requer owner designado, tem prazo, ou deve ser auditada separadamente
- Work Item de verificação (que produz Evidence) é mais comum que Work Item especificamente para Evidence

### Check (execução manual) — Critérios

Work Item é apropriado quando:
- Execução manual extensiva que requer planejamento e rastreamento
- Requer investigação adicional além da simples verificação
- Tem owner designado e prazo
- É parte de Assessment ou reconciliação formal
- Deve ser auditada separadamente (ex: DIL-OPS-004 requer verificador independente)

Work Item NÃO deve ser criado para:
- Execução automatizada de Check (resultado Pass ou Not Applicable)
- Execução rotineira com resultado esperado
- Checks de status regular sem divergência detectada

---

## Seção 6 — Cardinalidades

A cardinalidade entre entidades canônicas e Work Items é N:M em todas as dimensões:

```
Finding      N ─── N  Work Item
Remediation  N ─── N  Work Item
Waiver       N ─── N  Work Item
Evidence     N ─── N  Work Item
Check        N ─── N  Work Item

Work Item    1 ─── N  Entity Reference
```

Um único Work Item pode endereçar:
- Múltiplos Findings relacionados (ex: reconciliação de workspace que detectou 3 Findings estruturais)
- Uma Remediation que trata múltiplos Findings (1 Remediation pode endereçar N Findings)
- Múltiplas Evidence em uma operação de coleta
- Verificação coletiva de múltiplos Findings após correção em lote
- Reconciliação de workspace que impacta múltiplas entidades

Uma entidade pode ter múltiplos Work Items ao longo de sua vida:
- `FND-2026-0007`: pode ter Work Item de investigação (fechado), Work Item de Remediation (fechado), Work Item de verificação (ativo)
- `RMD-2026-0003`: pode ter Work Item de aprovação (fechado) e Work Item de implementação (ativo)

---

## Seção 7 — Operações canônicas

As operações do catálogo existente (`work-item-schema.md`) foram avaliadas quanto à reutilização para Diligence:

| Necessidade da Diligence | Operação existente | Nova operação? | Justificativa |
|---|---|---|---|
| Investigar Finding | `Review` | Não | "Review" cobre investigação contextual de qualquer artefato |
| Implementar Remediation | `Repair` | Não | "Repair" é semanticamente a fase de Diligence Async — adequado |
| Verificar Remediation | `Validate` | Não | "Validate" cobre verificação pós-implementação contra critérios objetivos |
| Aprovar Waiver | `Approve Waiver` | Sim | "Approve" genérico pode ser ambíguo; operação específica de governança de Diligence é mais precisa |
| Revisar Waiver | `Review` | Não | "Review" cobre revisão de qualquer artefato incluindo Waiver |
| Reconciliar Workspace | `Reconcile` | Não | "Reconcile" já existe semanticamente em Workspace Reconciliation |
| Coletar Evidence | `Collect Evidence` | Sim | Coleta explícita de Evidence como operação primária não está coberta pelos enums existentes |
| Fechar Finding | `Close` | Não | "Close" na fase Close do diligence-sync |
| Capturar divergência | `Capture` | Não | "Capture" é a fase Capture do diligence-sync — já existe |
| Executar Check manual | `Review` | Não | "Review" cobre execução de Check manual quando há investigação envolvida |

**Operações a recomendar para adição em `work-item-schema.md`:**
- `Approve Waiver` — distinção importante de "Approve" genérico; é operação de governança específica
- `Collect Evidence` — quando coleta de Evidence é a operação primária (não derivada de outra operação)

**Nota:** Este documento NÃO modifica `work-item-schema.md`. As adições acima são recomendações para avaliação e decisão na próxima fase de evolução do schema.

---

## Seção 8 — Schema de Work Item

### Formato canônico de título

```
[Artifact ID]: descrição concisa
```

O título é orientado ao objeto de trabalho — a entidade canônica sendo operada. Operação e tipo de artefato são detalhes de processo que vão nos campos e labels, onde têm espaço para ser lidos com contexto.

**Exemplos:**

```
FND-2026-0007: investigar referência inválida no schema de Work Item
RMD-2026-0003: reconciliar campos do workspace após drift detectado
WVR-2026-0002: revisar expiração e controles compensatórios
DIL-TRC-001: executar Check manual na diligence trimestral
EVD-2026-0011: coletar evidence de verificação pós-implementação
```

**NÃO adicionar** prefixos como "Finding:", "Remediation:", "Waiver:", "[Review]", "[Investigate]" no título. Os campos estruturados já capturam essas informações.

### Campos do schema (herdados de `work-item-schema.md`)

Todos os campos canônicos do schema existente se aplicam a Work Items de Diligence:

**Campos obrigatórios:**

| Campo | Tipo | Exemplo para Diligence |
|---|---|---|
| `artifact_type` | enum | `Finding`, `Remediation`, `Waiver`, `Evidence`, `Check` |
| `artifact_id` | string | `FND-2026-0007`, `RMD-2026-0003`, `DIL-TRC-001` |
| `operation` | enum | `Review`, `Repair`, `Validate`, `Approve Waiver`, `Reconcile`, `Collect Evidence` |
| `journey` | enum | `Diligence` |

**Campos contextuais:**

| Campo | Tipo | Exemplo para Diligence |
|---|---|---|
| `execution_mode` | enum | `N/A` (Diligence é transversal) |
| `owner` | string | `Diligence Owner`, `Product Owner` |
| `status` | enum | `Open`, `In Progress`, `Done` |
| `priority` | enum | `Critical`, `High`, `Medium`, `Low` |
| `repository` | string | Repositório do produto |

**Campos de rastreabilidade (extensão para Diligence):**

| Campo | Tipo | Descrição |
|---|---|---|
| `cycle` | string | `diligence-sync`, `diligence-async` |
| `phase` | string | `Capture`, `Attach`, `Promote`, `Close`, `Scan`, `Flag`, `Repair` |
| `mode` | string | `Sync`, `Async` |

**Campos relacionados (para N:M):**

O campo `related_artifacts` (já existente) é usado para referenciar entidades adicionais além da primária:

```yaml
artifact_type: Remediation       # entidade primária
artifact_id: RMD-2026-0003
related_artifacts:
  - type: Finding
    id: FND-2026-0007
  - type: Finding
    id: FND-2026-0008
  - type: Check
    id: DIL-TRC-001
    version: 1
```

---

## Seção 9 — Referências

### Schema de referência primária

```yaml
primary_reference:
  type: Finding           # Finding | Remediation | Evidence | Waiver | Check
  id: FND-2026-0007
  path: prodops/artifacts/diligence/findings/FND-2026-0007.md

related_references:
  - type: Remediation
    id: RMD-2026-0003
  - type: Evidence
    id: EVD-2026-0011
  - type: Check
    id: DIL-TRC-001
    version: 1
```

### Representação por superfície

| Superfície | Como representar | Seção recomendada |
|---|---|---|
| Issue body | Referências estruturadas em Markdown | `## ProdOps References` |
| Project fields | `Artifact ID` (primário), `Artifact Type` (primário) | Campos customizados |
| PR body | Referências a entidades alteradas/criadas | `## Diligence References` |
| Release trail | IDs de Findings corrigidos e Remediations implementadas | Seção de Diligence no trail |

A referência primária não elimina as relações N:M — `related_references` acomodam múltiplas entidades associadas. A referência primária é a entidade que define o critério de conclusão do Work Item.

---

## Seção 10 — Campos do GitHub Project

### Campos base (herdados do schema existente)

| Campo | Classificação | Fonte de Verdade | Direção | Editável no Project | Uso |
|---|---|---|---|---|---|
| Status | Existing | GitHub | Execution-only | Sim | Estado da operação no Work Item |
| Repository | Existing | GitHub | Execution-only | Sim | Contexto de repositório |
| Journey | Existing | Work Item | Knowledge → GitHub | Não (sincronizar) | Filtro por jornada (valor: Diligence) |
| Cycle | Existing | Work Item | Knowledge → GitHub | Não | Filtro por ciclo (diligence-sync, diligence-async) |
| Phase | Existing | Work Item | Knowledge → GitHub | Não | Filtro por fase operacional |
| Operation | Existing/Extended | Work Item | Knowledge → GitHub | Sim (operacional) | Tipo de operação sendo executada |
| Mode | Existing | Work Item | Knowledge → GitHub | Não | Sync/Async |
| Owner | Existing | GitHub | Execution-only | Sim | Responsável operacional da operação |
| Artifact ID | Existing | Work Item | Knowledge → GitHub | Não | ID da entidade primária (FND-*, RMD-*, etc.) |
| Artifact Type | Existing | Work Item | Knowledge → GitHub | Não | Tipo da entidade (Finding, Remediation, etc.) |

### Campos específicos de Diligence — avaliação

| Campo | Classificação | Fonte de Verdade | Direção | Editável no Project | Decisão |
|---|---|---|---|---|---|
| Finding Severity | Derived | Arquivo Finding | Knowledge → GitHub | Não | Somente se necessário para filtro/agrupamento; `Artifact ID` + `Artifact Type` podem ser suficientes na v1 |
| Finding Status | Derived | Arquivo Finding | Knowledge → GitHub | Não | Separado de Work Item Status; drift alto se não sincronizado; avaliar necessidade antes de criar |
| Check ID | Derived | Referência no Issue body | Knowledge → GitHub | Não | `Artifact ID` cobre quando `Artifact Type = Check`; campo separado cria redundância |
| Remediation ID | Derived | Referência no Issue body | Knowledge → GitHub | Não | `Artifact ID` cobre; campo separado cria redundância |
| Waiver ID | Derived | Referência no Issue body | Knowledge → GitHub | Não | `Artifact ID` cobre |
| Check Result | Derived | Evidence + execução | Knowledge → GitHub | Não | Não recomendado na v1 — ver Seção 22 |
| Blocking | Derived | Check + Finding + Waiver | Knowledge → GitHub | Não | Campo derivado futuro; não editável manualmente — ver Seção 20 |
| Waiver Expiration | Derived | Arquivo Waiver | Knowledge → GitHub | Não | Campo derivado futuro para alertas — ver Seção 21 |

**Decisão para v1:** Usar `Artifact ID` (ID da entidade primária) e `Artifact Type` (Finding | Remediation | Waiver | Evidence | Check) como base. Campos específicos (Severity, Finding Status, Remediation ID, Check ID, Waiver ID) só são adicionados se houver necessidade demonstrada de filtro/agrupamento que não pode ser satisfeita pelos campos base.

---

## Seção 11 — Autoridade por campo

| Campo | Fonte de Verdade | GitHub pode editar? | Direção | Drift esperado |
|---|---|---|---|---|
| `artifact_id` | Work Item (preenchido na criação) | Não após criação | Knowledge → GitHub | Baixo se processo seguido |
| `artifact_type` | Work Item (preenchido na criação) | Não após criação | Knowledge → GitHub | Baixo se processo seguido |
| `operation` | Work Item | Sim (mudança de fase operacional) | Execution-only | Médio |
| `journey` | Work Item | Não | Knowledge → GitHub | Baixo |
| `cycle` | Work Item | Não | Knowledge → GitHub | Baixo |
| `phase` | Work Item | Não | Knowledge → GitHub | Médio (evolui com ciclo) |
| `mode` | Work Item | Não | Knowledge → GitHub | Baixo |
| Work Item `status` | GitHub | Sim | Execution-only | Nenhum (dono é GitHub) |
| `owner` (operacional) | GitHub | Sim | Execution-only | Nenhum (dono é GitHub) |
| Finding Severity | Arquivo Finding | **Não** | Knowledge → GitHub | Alto sem automação |
| Finding Status | Arquivo Finding | **Não** | Knowledge → GitHub | Alto sem automação |
| Waiver Expiration | Arquivo Waiver | **Não** | Knowledge → GitHub | Alto sem automação |
| Blocking (derivado) | Check + Finding + Waiver | **Não editável** | Derived | Médio sem automação |
| Check Result | Evidence | **Não editável** | Derived | Alto sem automação |

**Regra crítica:** Finding Severity, Finding Status, Waiver Expiration, Check ID/Version e qualquer ID canônico de entidade são campos cujo dono é o Knowledge Space. O GitHub Project exibe esses valores como reflexo das entidades canônicas, nunca como fonte de verdade.

---

## Seção 12 — Política de edição

### Campos cujo dono é o Knowledge Space — NÃO editar manualmente no Project

Os seguintes campos, se presentes no Project como campos derivados, não devem ser editados manualmente:

- Finding Severity (valor canônico vive em `FND-YYYY-NNNN.md`)
- Finding Status (transições canônicas vidas no arquivo Finding)
- Waiver Expiration (campo `expires_at` no arquivo `WVR-YYYY-NNNN.md`)
- Check ID / Check Version (definidos no `catalog.yaml`)
- Remediation Status (campo `status` no arquivo `RMD-YYYY-NNNN.md`)
- Qualquer campo que seja ID canônico de entidade

**Consequência de edição manual:** Criação de drift entre o Project e o arquivo canônico. O drift é detectável por DIL-WSP-001 e pode gerar Finding de tipo DIL-STR (estrutural) ou DIL-OPS (operacional).

### Campos cujo dono é o Execution Space — PODEM ser editados no GitHub

- Work Item Status (Todo / In Progress / Done)
- Assignee (responsável operacional)
- Operação corrente (quando muda de fase dentro do ciclo)
- Prioridade operacional (distinta de severidade de Finding)
- Data planejada de conclusão
- Link de PR relacionada

### Distinção crítica

| | Dono | Pode editar no Project? |
|---|---|---|
| Estado da entidade (Finding Status, Remediation Status, Waiver status) | Knowledge Space | Não |
| Estado da operação (Work Item Status = Todo/In Progress/Done) | GitHub | Sim |
| Severidade da condição (Finding Severity) | Knowledge Space | Não |
| Prioridade da operação | GitHub | Sim |

---

## Seção 13 — Finding Status × Work Item Status

**Finding Status e Work Item Status são independentes.** O estado de um Work Item não implica nem altera o estado canônico de um Finding.

### Matriz de relação

| Evento no Work Item | Pode alterar Finding automaticamente? | Condição |
|---|---|---|
| Issue criada | Não | Apenas registra que há operação em andamento |
| Issue In Progress | Não | Indica que a operação começou, não que o Finding mudou |
| Issue Done | Não | Indica que a operação terminou, não que o Finding foi resolvido |
| PR merged | Não isoladamente | Pode ser Evidence de implementação, mas não fecha Finding |
| Check Pass após Remediation | Potencial | Pode ser Evidence para transição para Verified, conforme política |
| Waiver aprovado | Potencial | Pode mover Finding para Waived conforme regras canônicas |

### Exemplo A — Estado consistente durante Remediation

```
Finding Status: In Remediation
Work Item Status: In Progress
Remediation Status: Approved

→ Encontrou-se e registrou-se a condição (Finding)
→ Remediation foi planejada e aprovada
→ Work Item rastreia a implementação em andamento
→ Finding permanece "In Remediation" — ainda não foi verificado
```

### Exemplo B — Implementação concluída, verificação pendente

```
Finding Status: Resolved         ← mudança canônica após implementação
Work Item (Implementação): Done  ← operação de implementação concluída
Remediation Status: Implemented  ← implementação registrada no arquivo

Verification Work Item Status: Todo   ← nova operação de verificação necessária

→ Finding está "Resolved" mas NÃO está "Verified"
→ Fechar a Issue de implementação NÃO fecha o Finding
→ É necessária verificação independente (DIL-OPS-004)
→ Somente após Evidence de verificação → Finding pode ir para Verified
```

---

## Seção 14 — Labels

### Labels propostas (classificação operacional — NÃO representam entidades)

| Label | Propósito | Uso |
|---|---|---|
| `diligence` | Identifica Work Items da Jornada de Diligence | Filtro base; todas as Issues de Diligence devem ter esta label |
| `diligence:investigation` | Operação de investigação de Finding | Subclassificação por tipo de operação |
| `diligence:remediation` | Operação de implementação de Remediation | Subclassificação por tipo de operação |
| `diligence:verification` | Operação de verificação pós-Remediation | Subclassificação por tipo de operação |
| `diligence:waiver-review` | Operação de revisão ou aprovação de Waiver | Subclassificação por tipo de operação |
| `diligence:reconciliation` | Operação de Workspace Reconciliation | Subclassificação por tipo de operação |
| `diligence:evidence-collection` | Coleta complexa ou explícita de Evidence | Subclassificação por tipo de operação |

### O que labels NÃO podem representar

- ID canônico de Finding ou de qualquer entidade
- Status canônico de Finding
- Severidade canônica de Finding
- Waiver ativo (somente o arquivo `WVR-YYYY-NNNN.md` é autoritativo)
- Data de expiração de Waiver
- Aprovação de qualquer entidade
- Resultado de Check

### Labels existentes reutilizadas

Labels existentes do schema de Work Item (`operation:*`, `artifact-type:*`, `journey:*`) se aplicam normalmente a Work Items de Diligence. Exemplos:
- `journey:diligence` — Journey Diligence
- `artifact-type:finding` — Work Item sobre Finding
- `operation:repair` — operação de Remediation/Repair

### Labels rejeitadas (com razão)

| Label rejeitada | Razão da rejeição |
|---|---|
| `finding:FND-2026-0007` | ID canônico como label cria dependência frágil; IDs são campos estruturados, não labels |
| `severity:high` | Severidade é propriedade do Finding no Knowledge Space; label cria drift |
| `waiver-active` | Waiver ativo é estado canônico no arquivo; label não é suficiente nem confiável |
| `verified` | Status canônico de Finding; label não substitui a transição no arquivo |
| `blocking` | Estado derivado calculado; não é atributo editável por label |

---

## Seção 15 — Pull Requests

### PR de Remediation

Um PR de Remediation pode alterar:
- Código do produto (correção técnica)
- Documentação ou artefatos
- Arquivos de entidade Diligence (o próprio arquivo `RMD-YYYY-NNNN.md` ou `FND-YYYY-NNNN.md`)

O PR deve incluir no body a seção `## Diligence References`:

```markdown
## Diligence References
- Remediation: `RMD-2026-0003`
- Findings:
  - `FND-2026-0007`
  - `FND-2026-0008`
- Verification Check: `DIL-TRC-001@1`
- Expected Evidence: `EVD-2026-0012`
```

### PR de Waiver

Um PR de Waiver materializa a aprovação formal do arquivo `WVR-YYYY-NNNN.md`:
- O PR é Evidence da aprovação (o aprovador é identificável como reviewer do PR)
- Deve referenciar o Finding correspondente
- Deve preservar o campo `expires_at` — não pode ser omitido
- NÃO deve incluir silenciosamente Remediation incompatível
- O merge do PR pode gerar `EVD-YYYY-NNNN` de aprovação

### PR de Verificação

Um PR de verificação pode registrar:
- Execução de Check, resultado, e Evidence coletada
- Transição de estado do Finding (de Resolved para Verified)
- Referência à Evidence de verificação

Não é obrigatório um PR por entidade — um PR pode verificar múltiplos Findings após correção em lote.

### Template conceitual de seção de PR body

```markdown
## Diligence References
- Primary: `[ID]` ([Tipo])
- Related:
  - [Tipo]: `[ID]`
  - [Tipo]: `[ID]`
- Verification Check: `[DIL-XXX-NNN]@[versão]` (quando aplicável)
- Expected Evidence: `[EVD-YYYY-NNNN]` (quando aplicável)
```

---

## Seção 16 — Releases

- Uma Release pode conter implementação de Remediation entre seus entregáveis
- O Release Trail referencia os Findings corrigidos e as Remediations implementadas
- Evidence pós-Release verifica o resultado operacional da correção
- Um Finding só é Verified após o Check de verificação retornar Pass, independente da Release
- Uma Release concluída NÃO implica que o Finding está Closed ou Verified

**Contribuição de Release para Evidence:**

Uma Release que implementa uma Remediation pode gerar ou constituir Evidence `EVD-*` referenciada no Finding. A referência ao Release Trail ou ao Release GitHub como Evidence é válida. Entretanto, a transição do Finding para Verified ainda requer execução independente do Check de verificação — a Release sozinha não constitui verificação.

---

## Seção 17 — Issue body

A seção canônica a adicionar no body de Work Items de Diligence:

```markdown
## ProdOps References
- Primary: `RMD-2026-0003` (Remediation)
- Related:
  - Finding: `FND-2026-0007`
  - Finding: `FND-2026-0008`
  - Check: `DIL-WSP-001@1`
  - Evidence: `EVD-2026-0011`

## Operation
- Journey: Diligence
- Cycle: diligence-async
- Phase: Repair
- Operation: Reconcile
- Mode: Async
```

Esta seção é conceitual — nenhum template de Issue do GitHub é criado neste documento. A compatibilidade com o schema de `work-item-schema.md` foi avaliada e confirmada: o body complementa os campos do Project com informações de referência que não cabem em campos únicos (ex: múltiplos IDs relacionados).

---

## Seção 18 — Views futuras

As Views descritas abaixo são planejadas. Nenhuma View é criada por este documento. A criação segue o anti-padrão oposto: schema e campos primeiro, Views depois.

### View 1 — Diligence Operations

**Propósito:** Todas as operações ativas da Jornada de Diligence  
**Filtro:** Journey = Diligence, Status ≠ Done  
**Agrupamento:** Por Artifact Type  
**Ordenação:** Por Priority, depois por criação  
**Campos visíveis:** Status, Artifact ID, Artifact Type, Operation, Phase, Owner  
**Fonte de dados:** Work Items no GitHub Project  
**Limitação:** Mostra apenas Work Items com operação ativa — não todos os Findings existentes  
**O que NÃO representa:** Lista completa de Findings; Findings sem Work Item ativo não aparecem

### View 2 — Active Remediations

**Propósito:** Work Items de implementação de Remediation em andamento  
**Filtro:** Artifact Type = Remediation, Status ∈ {Todo, In Progress}  
**Agrupamento:** Por Status  
**Campos visíveis:** Status, Artifact ID, Operation, Owner, Priority  
**Limitação:** Não mostra Remediations sem Work Item ativo; Remediations sem operação em andamento são invisíveis  
**O que NÃO representa:** Todas as Remediations existentes

### View 3 — Blocking Findings

**Propósito:** Work Items associados a Findings com blocking ativo  
**Filtro:** Blocking = true (campo derivado), Status ≠ Done  
**Agrupamento:** Por Phase  
**Campos visíveis:** Status, Artifact ID, Artifact Type, Operation, Phase, Owner, Blocking  
**Limitação:** Requer campo Blocking derivado implementado; visibilidade restrita a Findings com Work Item  
**O que NÃO representa:** Todos os Findings bloqueantes — apenas aqueles com operação ativa rastreada

### View 4 — Waiver Reviews

**Propósito:** Operações de revisão, aprovação ou alerta de expiração de Waivers  
**Filtro:** Artifact Type = Waiver OR Operation = Approve Waiver OR label = diligence:waiver-review  
**Agrupamento:** Por Status  
**Campos visíveis:** Status, Artifact ID, Operation, Owner, Waiver Expiration (se disponível)  
**Limitação:** Não representa o estado canônico do Waiver — apenas a operação  
**O que NÃO representa:** Lista de todos os Waivers ativos; Waivers sem Work Item são invisíveis

### View 5 — Workspace Reconciliation

**Propósito:** Operações de reconciliação do workspace GitHub  
**Filtro:** Operation = Reconcile OR label = diligence:reconciliation  
**Agrupamento:** Por Status  
**Campos visíveis:** Status, Artifact ID, Operation, Phase, Owner  
**Limitação:** Specific à Capability Workspace Reconciliation  
**O que NÃO representa:** Estado real do workspace; apenas operações de reconciliação em andamento

### View 6 — Verification Queue

**Propósito:** Work Items aguardando execução independente de Check após Remediation  
**Filtro:** Operation = Validate OR label = diligence:verification, Status = Todo  
**Agrupamento:** Por Priority  
**Campos visíveis:** Status, Artifact ID, Artifact Type, Operation, Owner, Phase  
**Limitação:** Representa apenas verificações pendentes com Work Item; quando a fila está vazia, não garante que todos os Findings foram verificados  
**O que NÃO representa:** Findings não verificados sem Work Item de verificação

### View 7 — Diligence History

**Propósito:** Registro histórico de operações de Diligence concluídas  
**Filtro:** Status = Done, Journey = Diligence  
**Agrupamento:** Por Artifact Type, depois por mês de fechamento  
**Campos visíveis:** Status, Artifact ID, Artifact Type, Operation, Phase, Owner  
**Limitação:** Histórico apenas de operações com Work Item; operações concluídas na mesma execução sem Work Item são invisíveis  
**O que NÃO representa:** Status atual das entidades canônicas; histórico de estados de Finding

---

## Seção 19 — Findings sem Work Item

Findings que não possuem operação ativa **não aparecem no GitHub Project**. Este é o comportamento correto — não é uma lacuna nem um problema a ser resolvido com Issues artificiais.

**Visibilidade completa de Findings vem de:**

1. Arquivos individuais em `prodops/artifacts/diligence/findings/FND-YYYY-NNNN.md`
2. `prodops/artifacts/diligence/registry.yaml` — índice estruturado de todas as entidades
3. Relatórios agregados em `prodops/artifacts/diligence/reports/`
4. Dashboards futuros gerados a partir de `registry.yaml`
5. Consultas diretas ao repositório (`find`, `grep`, scripts)

**O Project NÃO deve criar Issues artificiais para cobrir 100% dos Findings visualmente.**

### Solução para visibilidade completa de Findings (planejada)

| Solução | Abordagem | Status |
|---|---|---|
| Dashboard derivado | Gerado a partir de `registry.yaml`; read-only; não cria Work Items | Planejado |
| Relatório agregado | Gerado periodicamente; exportado como Markdown em `reports/` | Planejado |
| Página gerada | Geração estática a partir de entidades; sem automação GitHub | Planejado |
| Integração de leitura | Query sobre arquivos com resultado estruturado | Planejado |

**NÃO usar:** uma Issue por Finding para garantir visibilidade no Project.

---

## Seção 20 — Blocking

O campo `blocking_effective` é derivado — calculado a partir das entidades canônicas, não editável manualmente:

```
blocking_effective =
  check.blocking = true
  AND finding.status ∈ {Open, Acknowledged, In Remediation}
  AND check.scope aplicável ao contexto
  AND NOT (waiver.status = Active AND waiver.expires_at > now)
```

**Um usuário NÃO pode setar `Blocking = false` manualmente no Project para suspender uma regra.**

A suspensão de blocking requer um Waiver canônico:
- `waiver_allowed: true` no Check (`catalog.yaml`)
- Arquivo `WVR-YYYY-NNNN.md` com status Active, todos os campos obrigatórios preenchidos, `expires_at` no futuro
- Evidence de aprovação referenciada

Se o campo `Blocking` estiver presente no Project como campo derivado:
- É read-only — não editável no Project
- É atualizado por automação que lê as entidades canônicas
- Edição manual → drift → Finding DIL-STR ou DIL-OPS detectado por DIL-WSP-001

---

## Seção 21 — Waiver

O Waiver é uma entidade canônica do Knowledge Space (`WVR-YYYY-NNNN.md`). No GitHub:

- Um Work Item pode existir para a operação de revisão ou aprovação do Waiver
- O campo `Waiver Expiration` (se presente no Project) é derivado do campo `expires_at` no arquivo
- A expiração NÃO pode ser atualizada apenas no Project — requer mudança no arquivo canônico (com autorização) ou renovação formal (novo `WVR-YYYY-NNNN` com novo ID)
- Quando o Waiver expira: `blocking_effective` volta a `true` para o Finding associado
- O Project PODE sinalizar proximidade de expiração como alerta operacional
- O arquivo `WVR-YYYY-NNNN.md` permanece fonte de verdade — expirado, mas preservado

**Renovação de Waiver:**
- Renovação é criação de novo Waiver com novo ID (`WVR-YYYY-NNNN+1`)
- O Waiver anterior permanece com status `Expired` — nunca é modificado retroativamente
- O Work Item de revisão pode ser encerrado; um novo Work Item pode ser criado para o novo Waiver se necessário

---

## Seção 22 — Check Result

Um Check pode ser executado múltiplas vezes sobre o mesmo sujeito. Portanto:

- Check Result NÃO é uma propriedade permanente de um Finding ou Work Item
- Se representado como campo derivado, deve refletir: resultado mais recente + Check ID + versão + timestamp + referência à Evidence
- O histórico de execuções de Check está em arquivos Evidence (`EVD-YYYY-NNNN.md`), não em campos de Project
- O campo seria uma "janela" para a Evidence mais recente, não um registro histórico

**Decisão para v1:** Check Result como campo do Project **não é recomendado**. A referência à Evidence (`EVD-*`) no body da Issue é suficiente para rastrear a execução. Um campo dedicado pode ser adicionado quando houver necessidade demonstrada de filtro ou agrupamento por resultado de Check.

**Justificativa:**
- Histórico de execuções requer múltiplos valores — campo único não é adequado
- O valor muda com cada execução — alto risco de drift sem automação confiável
- A Evidence já captura resultado, timestamp, e contexto com estrutura adequada

---

## Seção 23 — Workspace Reconciliation

Este documento (`github-workspace.md`) é o **estado esperado** que a Capability Workspace Reconciliation usa como fonte de verdade para suas operações.

**Inspect:** Lê o estado atual do workspace GitHub (campos, labels, views, templates) e compara com este documento. Não modifica nada durante Inspect. Gera relatório de divergências.

**Reconcile:** Após autorização, cria ou corrige o que foi identificado no Inspect, usando o mecanismo Automation First (API → MCP → CLI → SDK → Browser Automation). Cada ação é rastreável.

**Verify:** Executa DIL-WSP-001 e demais Checks de workspace estrutural. Registra Evidence da verificação (`EVD-YYYY-NNNN`). Atualiza o Finding associado se houver.

**Este documento é o INPUT para Workspace Reconciliation, não o output.**

A ordem de precedência para Inspect:
1. Este documento (`github-workspace.md`) — especificação de design
2. `prodops/exec/manifest.yaml` — configuração legível por máquina declarada

Qualquer divergência entre este documento e o estado real do workspace é candidata a reconciliação autorizada.

---

## Seção 24 — Anti-padrões

Os anti-padrões abaixo representam violações do modelo canônico de representação de operações Diligence no GitHub:

1. **Finding como Issue** — Finding é entidade do Knowledge Space; Issue representa trabalho sobre ele. Criar uma Issue que "é" o Finding viola a separação KS/ES e torna o número da Issue o identificador da entidade.

2. **Issue criada para todo Finding** — Viola a cardinalidade N:M; polui o Project com work items fantasma; artefato passivo não requer Work Item.

3. **Evidence apenas em comentário** — Comentário de Issue não tem ID próprio, não é imutável, não é referenciável por ID canônico. Evidence com identidade própria requer arquivo `EVD-YYYY-NNNN.md`.

4. **Waiver apenas como label** — Label não constitui aprovação formal; não tem `expires_at`, `approved_by`, `risk_accepted` nem Evidence de aprovação. Waiver válido é arquivo canônico assinado por aprovador.

5. **Aprovação apenas por mudança de status** — Mudar status de Work Item de "In Review" para "Done" não aprova Waiver. Aprovação canônica exige arquivo `WVR-YYYY-NNNN.md` com todos os campos e Evidence de aprovação.

6. **Issue number como Finding ID** — Issue #42 não é o mesmo que `FND-2026-0007`. IDs canônicos são imutáveis e independentes de ferramenta. Se o repositório migrar, o ID da Issue muda; o ID do Finding não.

7. **Mesmo status para Finding e Work Item** — "Issue Done" não significa "Finding Resolved". São estados independentes com semânticas distintas.

8. **Fechar Finding quando Issue fecha** — Work Item fecha quando a operação termina. Finding transiciona de estado somente quando critérios canônicos são satisfeitos (Evidence, verificação independente, etc.).

9. **Marcar Verified quando PR faz merge** — PR merged pode ser Evidence de implementação de Remediation, mas não é verificação independente da condição original. Finding só é Verified após Check de verificação com resultado Pass e Evidence independente.

10. **Editar severidade apenas no Project** — Finding Severity no arquivo é a fonte de verdade. Editar o campo derivado no Project cria drift imediato e silencioso.

11. **Editar expiração apenas no Project** — `Waiver Expiration` no Project é derivado de `expires_at` no arquivo `WVR-YYYY-NNNN.md`. Editar apenas o Project não altera o Waiver canônico — cria drift que DIL-WSP-001 detecta.

12. **Criar campo por Check** — Um campo "Check ID" por tipo de Check no Project é anti-padrão. O campo genérico `Artifact ID` com `Artifact Type = Check` serve o mesmo propósito sem proliferação de campos.

13. **Criar campo por Finding** — Um campo "Finding ID" específico em adição a `Artifact ID` é redundante. Quando `Artifact Type = Finding`, o `Artifact ID` já carrega o ID do Finding.

14. **Registrar histórico de Check em campo textual** — Histórico de execuções de Check (múltiplos resultados, timestamps, Evidences) não cabe em campo de texto do Project. Evidence independente é o mecanismo correto.

15. **Usar View como fonte de verdade** — Views são filtros sobre Work Items. "A View de Blocking Findings está vazia" não significa que não há Findings bloqueantes — significa que não há Work Items ativos associados a eles.

16. **Exigir que todo Finding apareça no Project** — Finding sem operação ativa não deve aparecer no Project. Tentar criar 100% de cobertura visual via Issues viola o modelo N:M e polui o Execution Space.

17. **Usar label como ID** — `label:finding-FND-2026-0007` não é um identificador canônico. Labels mudam, são renomeadas, excluídas. IDs canônicos são permanentes.

18. **Representar Remediation e Finding no mesmo conceito** — Finding registra a condição; Remediation planeja a correção. São entidades distintas com estados distintos. "Este Finding está em Remediation" é um estado; "Esta Remediation está implementada" é outro estado — ambos coexistem com semânticas diferentes.

19. **Duplicar informações canônicas sem autoridade** — Copiar `Finding Status` para um campo do Project sem automação declarada cria dois registros do mesmo dado sem regra de precedência clara. Drift é garantido.

20. **Sincronização bidirecional sem regra por campo** — Sincronização bidirecional sem declaração de fonte de verdade por campo resulta em conflitos. Cada campo tem dono declarado (Seção 11). Sincronização bidirecional só é válida quando cada campo tem direção unívoca definida.

21. **Desativar Blocking manualmente** — O campo `Blocking` é derivado. Editá-lo diretamente no Project não altera a entidade canônica. A suspensão de blocking requer Waiver canônico — não edição de campo.

22. **Tratar Waiver expirado como ativo** — Um Waiver com `expires_at` no passado e status ainda `Active` é violação de DIL-TMP-001. Não é tolerável via Waiver (waiver_allowed: false para este Check). O Finding retorna ao fluxo normal imediatamente.

23. **Criar Views antes de schema** — Views são representações derivadas de campos. Criar View de "Blocking Findings" antes de ter o campo `Blocking` configurado resulta em View vazia ou inoperante. Schema primeiro, Views depois.

24. **Criar terceiro ciclo para Workspace Reconciliation** — Workspace Reconciliation é uma Capability invocada pelos ciclos existentes (diligence-sync, diligence-async) e pelo Bootstrap. Não é um terceiro ciclo independente. Tratá-la como ciclo cria confusão de orquestração.

---

## Seção 25 — Exemplos

### Exemplo 1 — Finding informativo sem Work Item

**Cenário:** DIL-CON-001 detecta uso do termo "Business Signal Issue" em um documento histórico durante diligence-async Scan.

**Estado canônico:**
- Finding criado: `FND-2026-0001.md` com `severity: Info`, `status: Open`, `dimension: Conceptual`
- Avaliação: documento histórico, não normativo — Finding pode ser classificado como Not Applicable ou registrado como Info para histórico
- Nenhum Work Item criado

**No Project:**
- `FND-2026-0001` não aparece no Project
- `registry.yaml` tem entrada do Finding
- Relatório periódico lista o Finding

**Lição:** Finding sem operação ativa = invisível no Project = correto. Visibilidade via `registry.yaml` e relatórios — não via Issue artificial.

---

### Exemplo 2 — Remediation ativa com múltiplos Findings

**Cenário:** DIL-TRC-001 detecta dois Work Items ativos sem `artifact_id` preenchido.

**Estado canônico:**
- `FND-2026-0007.md` — Finding sobre Work Item A sem referência
- `FND-2026-0008.md` — Finding sobre Work Item B sem referência
- `RMD-2026-0003.md` — Remediation que trata ambos: corrigir campos nos dois Work Items

**Work Item criado:**
```
Título: RMD-2026-0003: corrigir campos artifact_id em Work Items sem referência
Artifact Type: Remediation
Artifact ID: RMD-2026-0003
Operation: Repair
Journey: Diligence
Cycle: diligence-async
Phase: Repair
```

**No body:**
```markdown
## ProdOps References
- Primary: `RMD-2026-0003` (Remediation)
- Related:
  - Finding: `FND-2026-0007`
  - Finding: `FND-2026-0008`
  - Check: `DIL-TRC-001@1`
```

**No Project:** Work Item aparece com Artifact Type = Remediation, Artifact ID = RMD-2026-0003. O Project mostra a **operação**, não os Findings diretamente.

**Lição:** Remediation como referência primária; Findings como referências relacionadas. N:M preservado. Project mostra operação, não entidade canônica.

---

### Exemplo 3 — Vários Findings, uma Remediation, verificação coletiva

**Cenário:** Três Findings de drift no workspace (DIL-WSP-001) foram corrigidos em uma operação de reconciliação. Uma única Remediation cobre os três.

**Estado canônico:**
- `FND-2026-0010.md`, `FND-2026-0011.md`, `FND-2026-0012.md` — Findings de workspace
- `RMD-2026-0005.md` — Remediation coletiva: reconfigurar campos e labels do Project

**Work Items:**
1. Issue de implementação: `RMD-2026-0005: executar reconciliação de workspace` (Done)
2. Issue de verificação: `RMD-2026-0005: verificar resultado da reconciliação` (In Progress)

**Findings mantêm estados próprios:**
- `FND-2026-0010.md`: status = Resolved (após implementação)
- `FND-2026-0011.md`: status = Resolved
- `FND-2026-0012.md`: status = Resolved
- Nenhum está Verified — aguardam a verificação independente (Issue 2 acima)

**Lição:** Um Work Item pode endereçar múltiplos Findings. Findings mantêm estados próprios independentes. Verificação coletiva via segundo Work Item — não um Work Item por Finding.

---

### Exemplo 4 — Waiver com aproximação de expiração

**Cenário:** `WVR-2026-0002.md` foi aprovado para suspender DIL-OPS-004 por 90 dias. Faltam 15 dias para expirar.

**Estado canônico:**
- `WVR-2026-0002.md`: `status: Active`, `expires_at: 2026-09-01`
- Evidence de aprovação: `EVD-2026-0008.md` (PR de aprovação)
- `FND-2026-0005.md`: `status: Waived`, `waiver: WVR-2026-0002`

**No Project (se campo Waiver Expiration estiver configurado):**
- Work Item de revisão: `WVR-2026-0002: revisar expiração e controles compensatórios` (Todo)
- Campo `Waiver Expiration` = `2026-09-01` (derivado do arquivo)
- Label: `diligence:waiver-review`

**O que NÃO acontece:**
- Label `waiver-active` não substitui o arquivo canônico
- Campo de expiração no Project não pode ser atualizado manualmente para estender prazo
- Mudar status de Work Item para Done não renova o Waiver

**Quando expira:**
- `WVR-2026-0002.md` → status: Expired
- `FND-2026-0005.md` → status: Acknowledged (volta ao fluxo normal)
- `blocking_effective` volta a `true` se o Check é blocking
- Renovação = novo `WVR-2026-0003.md` com nova Evidence de aprovação

**Lição:** Waiver canônico vive no arquivo. Project pode sinalizar alerta. Aprovação e renovação sempre via arquivo com Evidence — nunca via label ou status.

---

### Exemplo 5 — Remediation implementada, verificação pendente

**Cenário:** `RMD-2026-0003` foi implementada via PR. O desenvolvedor fechou a Issue de implementação. O Finding ainda não está Verified.

**Estado canônico:**
- `FND-2026-0007.md`: `status: Resolved` (condição foi corrigida, aguarda verificação)
- `RMD-2026-0003.md`: `status: Implemented`
- PR merged com Evidence de implementação: `EVD-2026-0012.md`

**No Project:**
- Issue de implementação: Done (fechada)
- Issue de verificação: `RMD-2026-0003: verificar implementação de forma independente` (Todo)

**O que NÃO acontece:**
- `FND-2026-0007.md` NÃO vai para `status: Verified` porque a Issue de implementação fechou
- `FND-2026-0007.md` NÃO vai para `status: Verified` porque o PR foi merged
- A Verification Queue tem a Issue de verificação como pendente

**Para transicionar para Verified:**
1. Verificador independente (diferente de quem implementou) executa DIL-OPS-004
2. Check retorna Pass
3. Evidence coletada: `EVD-2026-0013.md`
4. `FND-2026-0007.md` → `status: Verified`, `verified_at: ...`, evidence: `[EVD-2026-0013]`

**Lição:** PR merged ≠ Finding Verified. Issue Done ≠ Finding Verified. Implemented ≠ Verified. Verificação independente com Evidence é mandatória.

---

## Seção 26 — Matriz de implementação futura

| Elemento | Estado atual | Mudança necessária | Pode ser automatizado? | Pré-condição |
|---|---|---|---|---|
| Campo: Artifact ID | Existing | Confirmar valores de tipo Finding/Remediation/etc. nos enums | Sim (WS Reconciliation) | Schema aprovado |
| Campo: Artifact Type | Existing | Adicionar valores Diligence (Finding, Remediation, Waiver, Evidence, Check) | Sim (WS Reconciliation) | Schema aprovado |
| Campo: Journey | Existing | Confirmar valor "Diligence" nos enums | Sim | Schema aprovado |
| Campo: Cycle | Existing | Adicionar valores diligence-sync, diligence-async | Sim | Schema aprovado |
| Campo: Operation | Extended | Adicionar Approve Waiver, Collect Evidence | Sim | Convergência de operações |
| Campo: Phase | Existing | Adicionar fases da Diligence (Capture, Attach, Promote, Close, Scan, Flag, Repair, Inspect) | Sim | Schema aprovado |
| Campo: Mode | Existing | Confirmar Sync/Async | Sim | Schema aprovado |
| Campo: Blocking | Derived/New | Criar como campo derivado (automação futura lê entidades e calcula) | Sim (futura) | Automação de derivação implementada |
| Campo: Waiver Expiration | Derived/New | Criar como campo derivado (sincronizado do arquivo WVR-*) | Sim (futura) | Automação de derivação implementada |
| Campo: Finding Severity | Derived | Avaliar necessidade — pode ser postergado; Artifact ID + Artifact Type cobrem roteamento | Parcial | Automação de sincronização + necessidade demonstrada |
| Campo: Finding Status | Derived | Avaliar necessidade — separado de WI Status; drift alto sem automação | Parcial | Automação de sincronização + necessidade demonstrada |
| Campo: Check Result | Not recommended | Não criar na v1; referência a Evidence no body é suficiente | Não aplicável | — |
| Label: diligence | New | Criar label base | Sim (WS Reconciliation) | Nomenclatura aprovada |
| Label: diligence:investigation | New | Criar subclassificação operacional | Sim (WS Reconciliation) | Labels aprovadas |
| Label: diligence:remediation | New | Criar subclassificação operacional | Sim (WS Reconciliation) | Labels aprovadas |
| Label: diligence:verification | New | Criar subclassificação operacional | Sim (WS Reconciliation) | Labels aprovadas |
| Label: diligence:waiver-review | New | Criar subclassificação operacional | Sim (WS Reconciliation) | Labels aprovadas |
| Label: diligence:reconciliation | New | Criar subclassificação operacional | Sim (WS Reconciliation) | Labels aprovadas |
| Label: diligence:evidence-collection | New | Criar subclassificação operacional | Sim (WS Reconciliation) | Labels aprovadas |
| View: Diligence Operations | Planned | Criar após campos Journey e Artifact Type configurados | Parcial | Campos implementados |
| View: Active Remediations | Planned | Criar após campos Artifact Type configurados | Parcial | Campos implementados |
| View: Blocking Findings | Planned | Criar após campo Blocking derivado disponível | Parcial | Campo Blocking implementado |
| View: Waiver Reviews | Planned | Criar após labels e campos configurados | Parcial | Labels + campos implementados |
| View: Verification Queue | Planned | Criar após labels diligence:verification disponíveis | Parcial | Labels implementadas |
| View: Diligence History | Planned | Criar após demais Views operacionais | Sim | Views operacionais criadas |
| Issue body template | Planned | Criar template conceitual para ProdOps References | Não (manual inicialmente) | Schema aprovado |
| PR body template | Planned | Criar template conceitual para Diligence References | Não (manual inicialmente) | Schema aprovado |
| WS Reconciliation: Inspect | Planned | Implementar leitura deste documento e comparação com workspace real | Parcial | github-workspace.md estabilizado |
| WS Reconciliation: Reconcile | Planned | Implementar criação controlada com Automation First | Sim | Inspect validado + autorização |
| WS Reconciliation: Verify | Planned | Executar DIL-WSP-001 e registrar Evidence | Sim | Reconcile validado |
| Dashboard de Findings | Planned | Criar relatório derivado de registry.yaml (independente do Project) | Sim (futura) | Registry estabilizado |
| Sincronização de campos derivados | Planned | Automação de leitura de entidades e escrita nos campos Project | Sim (futura) | Campos criados + schema estável |
| Expiração de Waiver (alerta) | Planned | Automação de verificação periódica de expires_at com alerta operacional | Sim (futura) | Campo Waiver Expiration + automação |

---

## Referências

→ [Knowledge Space vs. Execution Space](../../knowledge-vs-execution.md)
→ [Execution Mapping](../../execution-mapping/README.md)
→ [Schema de Work Item](../../execution-mapping/work-item-schema.md)
→ [Jornada Diligence](README.md)
→ [Modelo de entidades](model/)
→ [Finding](model/finding.md)
→ [Check](model/check.md)
→ [Evidence](model/evidence.md)
→ [Remediation](model/remediation.md)
→ [Waiver](model/waiver.md)
→ [Catálogo de Checks](checks/catalog.yaml)
→ [Workspace Reconciliation](workspace-reconciliation.md)
→ [manifest.yaml](../../../exec/manifest.yaml)
