# Protocolo de Readiness — GitHub Workspace
# Jornada de Diligence — ProdOps Framework

> **Versão:** 1.0.0
> **Criado em:** 2026-07-24
> **Status:** Especificação — não implementação
> **Escopo:** Prepara a Capability Workspace Reconciliation para execução
> **Idioma normativo:** Português Brasileiro
> **Fonte de verdade para:** sequência Inspect → Plan → Authorize → Reconcile → Verify

---

## Seção 1 — Propósito

Este documento prepara a Capability Workspace Reconciliation para execução.
Ele define os protocolos canônicos de Inspect, Plan, Reconcile e Verify,
a matriz de readiness de todos os elementos do workspace, as fases de
implementação e os anti-padrões a evitar.

**O que este documento especifica:**
- A sequência canônica obrigatória antes de qualquer criação no workspace
- O protocolo de Inspect como operação read-only
- O plano de Reconcile como processo autorizado e documentado
- O protocolo de Verify como confirmação com Evidence
- A matriz de readiness de todos os campos, labels, views e templates
- Os anti-padrões que violam a sequência ou o processo canônico

**O que este documento NÃO especifica:**
- Comandos GitHub CLI para executar — esses pertencem ao Plano de Reconcile autorizado
- O estado real do workspace — esse é o output do Inspect
- Automações ou GitHub Actions — esses pertencem à Fase E
- Entidades canônicas (Finding, Waiver, etc.) — essas vivem em `artifacts/diligence/`

**A sequência canônica de implementação proíbe qualquer criação antes do Inspect.**

Nenhum label, campo, view ou template deve ser criado no workspace GitHub antes
de um Inspect formal ter sido executado e produzido um relatório. Criar antes de
Inspecionar gera risco de conflito com elementos existentes, duplicação de labels,
e drift não rastreável.

---

## Seção 2 — Sequência canônica

A sequência de implementação é obrigatória e não admite inversão:

```
Specify   ← github-workspace.md (concluído)
   ↓         github-workspace-schema.yaml (concluído — este step)
   ↓
Inspect   ← leitura read-only do estado real do workspace GitHub
   ↓         produz: relatório de drift (Compliant / Missing / Different / etc.)
   ↓         NÃO cria, NÃO modifica, NÃO remove nada
   ↓
Plan      ← calcular drift a partir do Inspect
   ↓         produz: plano de ações autorizado (Create / Update / Deferred / etc.)
   ↓         cada ação tem: mecanismo, risco, reversibilidade, rollback
   ↓
Authorize ← aprovação humana explícita é OBRIGATÓRIA antes de qualquer criação
   ↓         o plano é aprovado linha por linha ou como conjunto
   ↓         sem autorização = sem Reconcile
   ↓
Reconcile ← criação ou correção de elementos conforme plano autorizado
   ↓         Automation First: API → SDK → CLI → MCP → Web-Assisted → Manual
   ↓         cada ação é rastreável com Evidence
   ↓
Verify    ← DIL-WSP-001 + comparação pós-Reconcile com schema
   ↓         produz: Evidence (EVD-YYYY-NNNN) com snapshot antes e depois
   ↓         qualquer Fail → Finding antes de marcar Verify completo
```

### Por que esta ordem importa

**Criar antes de Inspecionar** é um anti-padrão de alto risco porque:

1. **Conflito com elementos existentes** — O workspace pode já ter labels com nomes
   similares usados por outros times em outros fluxos. Criar sem Inspecionar gera
   duplicidade ou sobrescreve convenções existentes sem rastreabilidade.

2. **Unexpected ≠ Inválido** — Elementos que existem no workspace mas não estão no
   schema esperado podem pertencer a fluxos legítimos de outros journeys. Inspecionar
   primeiro revela esses elementos para decisão consciente.

3. **Risco de rollback sem Evidence** — Sem snapshot do estado anterior ao Inspect,
   não é possível reverter criações indevidas com confiança. A Evidence de rollback
   começa no snapshot pré-Reconcile.

4. **Autorização sem base** — Autorizar um Reconcile sem dados reais do workspace é
   autorizar sobre premissas, não sobre fatos. O Inspect produz os fatos.

5. **DIL-WSP-001 requer estado declarado** — O Check de verificação compara estado
   observado com estado esperado (este schema). Sem Inspect intermediário, não há
   como produzir Evidence de conformidade comparável.

---

## Seção 3 — Protocolo de Inspect

### O que Inspect É

O Inspect é uma operação estritamente **read-only** que lê o estado real do
GitHub workspace e compara com o estado esperado declarado em
`prodops/framework/journeys/diligence/github-workspace-schema.yaml`.

O Inspect produz um relatório de divergências que serve como input obrigatório
para o Plano de Reconcile.

### O que Inspect NÃO É

- **Não é criação** — nenhum label, campo, view ou template é criado durante Inspect
- **Não é modificação** — nenhum elemento existente é alterado
- **Não é remoção** — nenhum elemento é removido, mesmo que seja Unexpected
- **Não é autorização** — Inspect identifica divergências; a decisão de agir é humana
- **Não é Reconcile** — identifica drift, não o corrige

### Escopo completo do Inspect

| Categoria | O que verificar |
|---|---|
| Campos do Project | Existência, tipos, opções de single_select |
| Opções de campos | Valores exatos de enums (Journey, Cycle, Phase, Operation, etc.) |
| Views | Existência, filtros, agrupamentos, ordenações, campos visíveis |
| Labels | Existência e configuração de labels do repositório |
| Templates de Issue | Existência e estrutura de body templates |
| Templates de PR | Existência e estrutura de PR body templates |
| Automações | GitHub Actions e workflows relacionados ao workspace |
| Entradas no manifest | Referências em `prodops/exec/manifest.yaml` |
| Permissões | Permissões de acesso ao Project |

### Output do Inspect

O output do Inspect é um arquivo Markdown no diretório de relatórios:

```
prodops/artifacts/diligence/reports/github-workspace-inspection-YYYY-MM-DD.md
```

### Taxonomia de drift

| Classificação | Definição | Implica remoção automática? |
|---|---|---|
| **Compliant** | Estado observado corresponde ao estado esperado no schema | N/A |
| **Missing** | Elemento esperado no schema não existe no workspace real | Não — ação: Create após autorização |
| **Unexpected** | Elemento existe no workspace mas não está no schema esperado | Não — investigar uso antes de decidir |
| **Different** | Elemento existe com configuração divergente do schema esperado | Não — Update após autorização |
| **Unsupported** | Estado esperado não pode ser implementado com a API disponível | Não — Deferred + documento de limitação |
| **Unverifiable** | Inspect não confirmou o estado (API inacessível, permissão ausente) | Não — tratar como Missing para planejamento |

**Regra crítica sobre Unexpected:** Elementos Unexpected podem pertencer a fluxos
legítimos de outros journeys, outros times ou outros projetos. Unexpected não significa
inválido. Antes de propor remoção de qualquer elemento Unexpected, investigar:
1. Quais Issues, PRs ou Actions referenciam o elemento
2. Qual time é owner do elemento
3. Se há dependências de outros fluxos
4. O histórico git do arquivo de configuração

### Template do relatório de Inspect

O relatório gerado deve seguir esta estrutura conceitual:

```markdown
# GitHub Workspace Inspection Report
Date: YYYY-MM-DD
Executor: {name}
Schema: prodops/framework/journeys/diligence/github-workspace-schema.yaml
Specification: prodops/framework/journeys/diligence/github-workspace.md

## Summary
- Compliant: N
- Missing: N
- Unexpected: N
- Different: N
- Unsupported: N
- Unverifiable: N
- Total elements inspected: N

## Fields
### Expected: {field_name}
- Classification: work_item_canonical | base_existing | derived | rejected
- Status: Compliant | Missing | Different | Unsupported | Unverifiable
- Expected type: single_select | text | date | boolean
- Expected options: [list if single_select]
- Observed: {config or "NOT FOUND"}
- Notes: ...

## Labels
### Expected: {label_name}
- Status: Compliant | Missing | Different
- Expected color: {color}
- Observed: {color or "NOT FOUND"}

## Views
### Expected: {view_name}
- Status: Compliant | Missing | Different | Unsupported | Unverifiable
- Expected filter: {filter}
- Observed filter: {filter or "NOT FOUND"}
- Notes: ...

## Templates
### Expected: {template_name}
- Status: Compliant | Missing | Different
- Notes: ...

## Drift Summary
| Elemento | Categoria | Status | Ação Recomendada |
|---|---|---|---|
| Campo: Journey | work_item_canonical | Missing | Create após autorização |
| Campo: Blocking | derived | Deferred | Não criar — aguarda Fase E |
| Label: diligence | approved | Missing | Create após autorização |
| ... | ... | ... | ... |

## Unexpected Elements
| Elemento | Tipo | Uso Identificado | Recomendação |
|---|---|---|---|
| label: xyz | Label | Issues de outro fluxo | Não remover — investigar |

## API Limitations Identified
- {limitation_1}
- {limitation_2}

## Evidence References
- EVD-{YYYY}-{NNNN} — snapshot do workspace via GitHub API em {timestamp}

## Next Step
Produzir Plano de Reconcile baseado neste Drift Summary.
```

---

## Seção 4 — Plano de Reconcile

### Inputs obrigatórios

O Plano de Reconcile requer:

1. **Schema declarado** — `github-workspace-schema.yaml` (estado esperado)
2. **Relatório de Inspect** — drift entre esperado e real
3. **Autorização humana** — aprovação explícita antes de qualquer criação
4. **Conformidade com Automation First** — mecanismo declarado por ação

Sem esses quatro inputs, o Reconcile não deve ser iniciado.

### Classificação de ações

| Ação | Definição | Requer autorização |
|---|---|---|
| **Create** | Elemento Missing — criar conforme schema | Sim |
| **Update** | Elemento Different — atualizar para conformar ao schema | Sim |
| **Rename** | Elemento existe com nome diferente — renomear com cautela | Sim (risco médio) |
| **Deprecate** | Elemento não mais necessário — sinalizar, não remover | Sim |
| **Remove** | Elemento Unexpected confirmado como inválido — remover com rollback | Sim (alto risco) |
| **No Action** | Compliant — não tocar | N/A |
| **Manual Required** | API não suporta criação programática — instrução documentada | Sim |
| **Unsupported** | Não pode ser implementado com API/CLI disponível | N/A — Deferred |
| **Deferred** | Implementação adiada (ex: campos derivados precisam de automação) | N/A |

### Estrutura de cada ação no plano

Para cada ação no plano de Reconcile, documentar:

```yaml
- target: "{nome do elemento}"
  category: field | label | view | template | manifest
  action: Create | Update | Rename | Deprecate | Remove | No Action | Manual Required | Unsupported | Deferred
  current_state: "{estado observado no Inspect ou NOT FOUND}"
  expected_state: "{estado declarado no schema}"
  reason: "{por que esta ação é necessária}"
  risk: Low | Medium | High
  reversible: true | false
  automation_mechanism: "gh api graphql | GitHub CLI project field-create | GitHub CLI label command | web-assisted | manual"
  approval_required: true
  validation_check: DIL-WSP-001
  rollback: "{como reverter se necessário}"
  evidence_required: "{EVD-YYYY-NNNN — snapshot antes + resposta da API}"
```

### Política de remoção conservadora

Antes de incluir qualquer ação de remoção no plano:

1. Identificar uso — buscar Issues, PRs e Actions que referenciam o elemento
2. Identificar owner — qual time usa o elemento e em qual fluxo
3. Verificar dependências — outros elementos que dependem do elemento
4. Produzir Evidence — registrar a análise de impacto como EVD-*
5. Obter autorização explícita do owner do elemento
6. Definir rollback com passos verificáveis
7. Verificar histórico git para entender a origem do elemento

### Ordem de Automation First

Para cada ação de Reconcile, tentar nesta ordem:

1. **GitHub official API** — `gh api graphql` (Project v2) ou REST API
2. **GitHub official SDK** — SDK JavaScript, Go ou equivalente autorizado
3. **GitHub CLI** — comandos de criação de campo, label e view do Project via `gh`
4. **MCP integration** — integração MCP autorizada com escopo de criação
5. **Web-assisted** — humano executa instruções passo a passo documentadas
6. **Manual instruction** — documentado step-by-step; último recurso; sempre com
   Issue de rastreamento aberta para confirmação posterior

Nenhuma ação deve pular etapas desta ordem sem documentar a razão.

### Limitações conhecidas a verificar durante Inspect

As seguintes limitações são conhecidas ou suspeitas e devem ser verificadas durante Inspect:

| Limitação potencial | O que verificar | Impacto se confirmado |
|---|---|---|
| Views via API | Se GitHub API suporta criação programática de Views em Project v2 | Views precisam de criação Web-Assisted |
| Campo tipo formula | Se campos com fórmulas (ex: Blocking derivado) são suportados | Campo Blocking pode precisar de automação externa |
| Opções de campo single_select via CLI | Se `gh project field-create` suporta opções de single_select | Criação de opções pode precisar de API direta |
| Permissões para criar campos | Se o token tem permissão para criar custom fields no Project | Pode requerer permissão de admin no Project |
| Templates via API | Se templates de Issue e PR são programáveis via API | Templates podem precisar de criação Web-Assisted |

---

## Seção 5 — Protocolo de Verify

### O que Verify É

O Verify é a confirmação formal de que o Reconcile produziu o estado esperado.
Não é verificar se os comandos retornaram exit code 0 — é confirmar que o estado
real do workspace corresponde ao schema declarado.

O Verify:
- Executa um novo Inspect (snapshot pós-Reconcile)
- Compara com o schema — cada elemento deve estar Compliant
- Para cada elemento Deferred: documenta explicitamente o que foi adiado e por quê
- Executa DIL-WSP-001 (Workspace Schema Conforms to Declared Configuration)
- Registra Evidence (EVD-YYYY-NNNN) com todos os componentes obrigatórios
- Atualiza `registry.yaml` se necessário

### O que Verify NÃO É

- **Não é correção** — se algo está errado após Reconcile, abrir Finding e novo Reconcile
- **Não é tolerância** — elementos Missing após Reconcile = Fail no DIL-WSP-001
- **Não é superficial** — verificar estado real via API, não apenas retorno de comandos
- **Não é automático** — Verify requer Evidence com snapshots e resultado explícito

### Passos do Verify

1. Executar Inspect novamente (snapshot pós-Reconcile)
2. Comparar cada elemento com o schema — todos devem ser Compliant
3. Para cada elemento ainda Missing ou Different: Fail em DIL-WSP-001
4. Para cada elemento Deferred: documentar explicitamente com justificativa
5. Executar DIL-WSP-001 e registrar resultado (Pass / Fail / Warning)
6. Se Fail ou Warning: criar Finding antes de marcar Verify completo
7. Registrar Evidence (EVD-YYYY-NNNN) com os componentes abaixo
8. Atualizar `registry.yaml` com referência à Evidence

### Evidence mínima obrigatória para Verify

| Componente | Descrição |
|---|---|
| `snapshot_before` | Output do Inspect pré-Reconcile (estado do workspace antes) |
| `authorized_plan` | Documento do plano aprovado com ações executadas |
| `commands_or_mechanism` | Mecanismo usado (API calls, CLI commands, web-assisted steps) |
| `api_responses` | Respostas reais das chamadas de API |
| `snapshot_after` | Output do Inspect pós-Reconcile (estado do workspace depois) |
| `dil_wsp_001_result` | Resultado explícito: Pass / Fail / Warning |
| `limitations_noted` | O que não foi possível verificar e por quê |
| `deferred_items` | O que foi explicitamente adiado (campos derivados, etc.) |
| `approver` | Quem autorizou o Reconcile |

### Finding vs. Verify

Se DIL-WSP-001 retornar Fail ou Warning após o Reconcile:

1. **Não marcar Verify como concluído** — Verify incompleto não é Verify
2. **Criar Finding** — `FND-YYYY-NNNN.md` documentando a divergência residual
3. **Decidir:** remediar imediatamente (novo mini-Reconcile) ou Waiver temporário
4. **Somente após divergências resolvidas:** marcar Verify como completo
5. **Exceção:** elementos Deferred com justificativa documentada não geram Fail

---

## Seção 6 — Fases de implementação

### Fase A — Schema canônico (concluído)

Fase atual — preparação do estado esperado:

- ✓ Operações convergidas (`work-item-schema.md` atualizado com `Reconcile`)
- ✓ Artifact types para Diligence adicionados (Finding, Remediation, Waiver, Check)
- ✓ Campos classificados no schema (base_existing, work_item_canonical, derived, rejected)
- ✓ Labels avaliadas (approved, rejected, deferred)
- ✓ Views planejadas por fase de implementação
- ✓ Templates especificados (conceituais)
- ✓ `github-workspace-schema.yaml` criado
- ✓ `github-workspace-readiness.md` criado
- ✓ `manifest.yaml` atualizado

### Fase B — Inspect (próxima etapa)

Snapshot read-only do workspace GitHub real:

- Executar Inspect contra workspace GitHub com autenticação adequada
- Cobrir todos os escopos declarados no schema (campos, labels, views, templates)
- Produzir relatório em `prodops/artifacts/diligence/reports/`
- Nenhuma criação ou modificação permitida nesta fase

### Fase C — Reconcile sem automação derivada

Elementos elegíveis para Fase C (não requerem automação):

**Campos:**
- Opções de Operation: Review, Implement, Validate, Approve, Capture, Attach, Reconcile, Promote, Close, Create, Update
- Opções de Artifact Type: Finding, Remediation, Waiver, Evidence, Check (adicionar se Missing)
- Opção de Journey: Diligence (confirmar se Missing)
- Opções de Cycle: diligence-sync, diligence-async, workspace-reconciliation
- Opções de Phase: Capture, Attach, Promote, Close, Scan, Flag, Repair, Inspect, Reconcile, Verify
- Opções de Mode: Sync, Async, Manual

**Labels:**
- `diligence`
- `diligence:investigation`
- `diligence:remediation`
- `diligence:verification`
- `diligence:waiver-review`
- `diligence:reconciliation`

**Templates:**
- Issue body template (seção ProdOps References)
- PR Remediation body template
- PR Waiver body template
- PR Verification body template

**Views:**
- Diligence Operations
- Active Remediations
- Workspace Reconciliation
- Verification Queue
- Diligence History
- Waiver Reviews (sem campo Waiver Expiration — aceitável para v1)

**Elementos NÃO elegíveis para Fase C:**
- Campo `Blocking` (requer automação de derivação)
- Campo `Waiver Expiration` (requer automação de sincronização)
- Campo `Finding Status` (requer automação de sincronização)
- Campo `Finding Severity` (requer automação de sincronização)
- View `Blocking Findings` (requer campo Blocking derivado)

### Fase D — Verify

Após Reconcile da Fase C:

1. Executar Inspect novamente (snapshot pós-Reconcile)
2. Comparar com schema — todos os elementos da Fase C devem ser Compliant
3. Para cada elemento Deferred (campos derivados): documentar explicitamente
4. Executar DIL-WSP-001 e registrar resultado
5. Registrar Evidence (EVD-YYYY-NNNN) com componentes completos
6. Se Fail: criar Finding antes de concluir

### Fase E — Automação derivada

Somente após Fase D estar verificada e concluída:

- Campo `Blocking` — automação que lê Check + Finding + Waiver e calcula blocking_effective
- Campo `Waiver Expiration` — sincronização de `expires_at` do arquivo WVR-* para Project
- Campo `Finding Status` — sincronização de `status` do arquivo FND-* para Project
- Campo `Finding Severity` — sincronização de `severity` do arquivo FND-* para Project
- View `Blocking Findings` — disponível após campo Blocking derivado implementado
- Alertas de expiração de Waiver — verificação periódica de proximidade de `expires_at`
- Dashboard de Findings — ferramenta independente que lê `registry.yaml`; sem relação com Project

---

## Seção 7 — Matriz de readiness

| Elemento | Especificado | Depende de Inspect | Depende de aprovação | Depende de automação | Ready para Reconcile |
|---|---|---|---|---|---|
| Campo: Status | Sim (base_existing) | Sim | Sim | Não | Fase C |
| Campo: Repository | Sim (base_existing) | Sim | Sim | Não | Fase C |
| Campo: Owner | Sim (base_existing) | Sim | Sim | Não | Fase C |
| Campo: Journey | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Cycle | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Phase | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Operation | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Mode | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Artifact ID | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Artifact Type | Sim (work_item_canonical) | Sim | Sim | Não | Fase C |
| Campo: Blocking | Sim (derived) | Sim | Sim | Sim | Fase E |
| Campo: Waiver Expiration | Sim (derived) | Sim | Sim | Sim | Fase E |
| Campo: Finding Status | Sim (derived) | Sim | Sim | Sim | Fase E |
| Campo: Finding Severity | Sim (derived) | Sim | Sim | Sim | Fase E |
| Campo: Check Result | Rejeitado (v1) | N/A | N/A | N/A | Não |
| Campo: Finding ID | Rejeitado | N/A | N/A | N/A | Não |
| Campo: Remediation ID | Rejeitado | N/A | N/A | N/A | Não |
| Campo: Waiver ID | Rejeitado | N/A | N/A | N/A | Não |
| Campo: Check ID | Rejeitado | N/A | N/A | N/A | Não |
| Label: diligence | Sim | Sim | Sim | Não | Fase C |
| Label: diligence:investigation | Sim | Sim | Sim | Não | Fase C |
| Label: diligence:remediation | Sim | Sim | Sim | Não | Fase C |
| Label: diligence:verification | Sim | Sim | Sim | Não | Fase C |
| Label: diligence:waiver-review | Sim | Sim | Sim | Não | Fase C |
| Label: diligence:reconciliation | Sim | Sim | Sim | Não | Fase C |
| Label: diligence:evidence-collection | Adiado | N/A | N/A | N/A | Adiado |
| Label: journey:diligence | Rejeitado | N/A | N/A | N/A | Não |
| Label: artifact-type:* | Rejeitado | N/A | N/A | N/A | Não |
| Label: operation:* | Adiado | N/A | N/A | N/A | Adiado |
| Template: Issue body | Especificado | Sim | Sim | Não | Fase C |
| Template: PR Remediation | Especificado | Sim | Sim | Não | Fase C |
| Template: PR Waiver | Especificado | Sim | Sim | Não | Fase C |
| Template: PR Verification | Especificado | Sim | Sim | Não | Fase C |
| View: Diligence Operations | Especificado | Sim | Sim | Não | Fase C |
| View: Active Remediations | Especificado | Sim | Sim | Não | Fase C |
| View: Workspace Reconciliation | Especificado | Sim | Sim | Não | Fase C |
| View: Verification Queue | Especificado | Sim | Sim | Não | Fase C |
| View: Diligence History | Especificado | Sim | Sim | Não | Fase C |
| View: Waiver Reviews | Especificado | Sim | Sim | Não | Fase C |
| View: Blocking Findings | Especificado | Sim | Sim | Sim | Fase E |
| Operations enum (Reconcile) | Sim | Sim | Sim | Não | Fase C |
| Artifact Type enum (Finding, etc.) | Sim | Sim | Sim | Não | Fase C |
| Capability: Workspace Reconciliation | Sim (Capability) | Sim | Sim | Não | Fase B/C |
| Dashboard de Findings | Não especificado | N/A | N/A | Sim | Fase E+ |

**Resumo:** 30 elementos prontos para Fase C, 5 elementos para Fase E, 8 elementos rejeitados, 3 elementos adiados.

---

## Seção 8 — Anti-padrões

Os anti-padrões abaixo representam violações do processo canônico de readiness
e implementação do GitHub Workspace. Cada um tem consequência documentada.

1. **Criar labels antes do Inspect** — Criar labels sem Inspecionar o estado real
   gera risco de duplicação com labels existentes de outros fluxos. O Inspect revela
   o estado real; a criação sem Inspect é uma aposta, não um processo.

2. **Tratar Inspect como Reconcile** — Inspect é read-only. Qualquer criação, modificação
   ou remoção executada durante o Inspect contamina o processo e torna o relatório
   não confiável como snapshot do estado real.

3. **Pular autorização humana** — Executar Reconcile sem aprovação humana explícita
   cria mudanças não autorizadas no workspace. Autorização não é burocracia — é o
   contrato de responsabilidade por cada ação executada.

4. **Remover elementos Unexpected automaticamente** — Unexpected não significa inválido.
   Remover automaticamente elementos Unexpected destrói configurações de outros fluxos
   legítimos. A política é sempre conservadora: investigar antes de decidir.

5. **Criar campos derivados antes da automação** — Criar campos como Blocking, Waiver
   Expiration ou Finding Status sem a automação de sincronização cria campos com valores
   estáticos que imediatamente entram em drift com as entidades canônicas.

6. **Editar campo Blocking manualmente** — Blocking é derivado. Editá-lo no Project
   não altera a entidade canônica. A suspensão de blocking requer Waiver canônico válido.
   Edição manual = drift imediato e Finding por DIL-WSP-001.

7. **Criar Views antes de campos** — Views filtram sobre campos. Criar View de
   "Blocking Findings" antes de ter o campo Blocking configurado resulta em View
   inoperante. Schema de campos primeiro, Views depois.

8. **Confundir Workspace Reconciliation com Cycle** — Workspace Reconciliation é uma
   Capability invocada pelos ciclos existentes, não um terceiro Cycle independente.
   Classificar Work Items de reconciliação com Journey = "WorkspaceReconciliation"
   é violação de DIL-CON-001 (vocabulário não canônico).

9. **Verificar apenas exit codes de comandos** — Verify não é confirmar que o comando CLI
   de criação retornou exit 0. É confirmar via API que o elemento existe com a configuração
   exata esperada pelo schema. Exit 0 pode mascarar configuração incorreta.

10. **Marcar Verify completo com Fail no DIL-WSP-001** — Verify incompleto é Fail.
    Se DIL-WSP-001 retornar Fail ou Warning, criar Finding antes de marcar Verify
    como concluído. Um Fail silencioso não é Verify — é ignorar evidência.

11. **Tratar elementos Deferred como Missing** — Elementos explicitamente Deferred
    (como campos derivados que aguardam automação) são diferentes de Missing.
    Misturar as classificações infla o número de itens pendentes e confunde o plano.

12. **Planejar Reconcile sem Inspect** — Planejar ações de criação com base apenas
    no schema, sem Inspect do estado real, é planejar com pressupostos. O Inspect
    pode revelar que elementos já existem, existem com configuração diferente, ou
    conflitam com elementos existentes.

13. **Não documentar limitações de API** — Quando a API não suporta uma criação
    programática (ex: Views via REST), não documentar a limitação significa que
    o próximo executor vai tentar novamente e falhar novamente. Cada limitação
    identificada deve ser documentada no relatório de Inspect.

14. **Autorizar plano sem granularidade** — "Autorizo o Reconcile completo" sem revisar
    cada ação é autorização cega. O plano deve ser revisado ação por ação, especialmente
    para remoções e atualizações que afetam elementos existentes.

15. **Criar múltiplas labels para o mesmo conceito** — Criar `diligence`, `journey:diligence`
    e `journey-diligence` para o mesmo propósito é proliferação que confunde operadores
    e fragmenta filtros. Um conceito = uma label. A lista aprovada no schema é canônica.

16. **Sincronizar bidirecional sem regra por campo** — Cada campo tem uma fonte de
    verdade declarada no schema. Sincronização bidirecional sem regras por campo
    resulta em conflito de autoridade. O schema declara direção unívoca por campo.

17. **Criar Evidence de Verify sem snapshot antes** — Evidence de Verify sem o snapshot
    pré-Reconcile não prova que o Reconcile foi necessário ou que o estado melhorou.
    O componente `snapshot_before` é obrigatório — não opcional.

18. **Tratar Workspace Reconciliation como etapa única** — Workspace Reconciliation é
    Inspect → Plan → Authorize → Reconcile → Verify. Executar como etapa única sem
    separar as fases elimina pontos de verificação e rastreabilidade.

19. **Ignorar Riscos Residuais durante Inspect** — Riscos identificados neste documento
    (como suporte da API para Views, ou tipos de campos) devem ser verificados durante
    Inspect. Ignorá-los pode resultar em plano de Reconcile com ações impossíveis de
    executar automaticamente.

20. **Confundir estado de operação com estado de entidade** — Work Item Status = Done
    não significa Finding Status = Verified. Labels de Diligence identificam operações,
    não estados canônicos de entidades. O schema é claro: estado de entidade vive no
    arquivo canônico; estado de operação vive no Work Item do GitHub.

---

## Seção 9 — Riscos residuais antes do Inspect

Os seguintes riscos existem antes de um Inspect real ser executado:

| ID | Risco | Nível | Mitigação |
|---|---|---|---|
| RR-1 | GitHub API pode não suportar criação de Views programaticamente | Médio | Verificar durante Inspect; documentar como Unsupported se confirmado; usar Web-Assisted |
| RR-2 | Campos do Project podem existir com nomes diferentes dos esperados | Médio | Inspect com busca case-insensitive e por sinônimos; classificar como Different, não Missing |
| RR-3 | Labels podem conflitar com labels existentes de outros times | Alto | Inspect com busca exaustiva de labels; política conservadora de remoção de Unexpected |
| RR-4 | Campo tipo formula (Blocking derivado) pode não ser suportado natively | Alto | Verificar tipos disponíveis no Project v2 durante Inspect; pode requerer automação externa |
| RR-5 | Permissões insuficientes para criar custom fields no Project | Alto | Verificar permissões como parte do Inspect; obter permissões de admin antes do Reconcile |
| RR-6 | Autenticação GitHub necessária com escopo correto | Alto | Garantir token com scopes: project, repo, write:org antes de iniciar Inspect |
| RR-7 | Decisão sobre vocabulário de operações pode precisar de alinhamento com time | Médio | Revisar schema de operações com time antes de Reconcile; Inspect não cria — dá tempo para discussão |

---

## Referências

→ [Especificação do Workspace](github-workspace.md)
→ [Schema declarativo](github-workspace-schema.yaml)
→ [Workspace Reconciliation](workspace-reconciliation.md)
→ [Schema de Work Item](../../execution-mapping/work-item-schema.md)
→ [manifest.yaml](../../../exec/manifest.yaml)
→ [Catálogo de Checks](checks/catalog.yaml)
→ [Ontologia](../../ontology.md)
→ [Glossário](../../glossary.md)
