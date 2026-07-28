# Relatório de Execução — GitHub Workspace Readiness
# ProdOps Framework — Diligence GitHub Workspace Schema & Readiness v1.0.0

> Executado em: 2026-07-24
> Escopo: Preparação do Framework para implementação futura do Diligence GitHub Workspace
> Input: github-workspace.md (especificação), work-item-schema.md, catalog.yaml, manifest.yaml
> Status: **concluído — schema criado, readiness criado, schema atualizado, validações executadas**

---

## 1. Executive Summary

### Objetivo

Preparar o Framework ProdOps para a implementação futura do Diligence GitHub Workspace através de:
1. Análise de convergência de operações (o que já existe vs. o que é necessário)
2. Schema declarativo machine-readable do estado esperado do workspace
3. Protocolo formal de Inspect → Plan → Authorize → Reconcile → Verify
4. Matriz de readiness de todos os 41 elementos planejados
5. Correção da sequência de implementação do relatório anterior

### Arquivos criados

| Arquivo | Função |
|---|---|
| `prodops/framework/journeys/diligence/github-workspace-schema.yaml` | Schema declarativo do estado esperado — 865 linhas, machine-readable AND human-readable |
| `prodops/framework/journeys/diligence/github-workspace-readiness.md` | Protocolo de readiness — 638 linhas, 9 seções, 20 anti-padrões, 7 riscos residuais |
| `prodops/documentation-review-diligence-github-readiness.md` | Este relatório de execução |

### Arquivos modificados

| Arquivo | O que mudou |
|---|---|
| `prodops/exec/manifest.yaml` | Adicionados `readiness` e `schema` ao bloco `github_workspace` |
| `prodops/framework/execution-mapping/work-item-schema.md` | Adicionado `Reconcile` ao enum de operações; adicionados Finding, Remediation, Waiver, Check ao enum artifact_type; adicionados exemplos Diligence; adicionado rationale de convergência |
| `prodops/framework/execution-mapping/matrix.md` | Adicionada seção "Diligence — Entidades Canônicas" com mapeamento de Finding, Remediation, Waiver e Check; atualizado resumo por recurso GitHub |

### Decisões-chave

1. **Apenas `Reconcile` adicionado ao work-item-schema.md** — Análise de convergência determinou que 6 das 7 necessidades da Diligence são cobertas por operações existentes
2. **`Approve Waiver` NÃO adicionado** — `Approve + Artifact Type = Waiver` é suficiente; operações compostas criam inconsistência de vocabulário
3. **`Collect Evidence` NÃO adicionado** — `Capture + Artifact Type = Evidence` é suficiente; Capture já existe para "registrar observação"
4. **Sequência canônica corrigida** — A sequência correta é Inspect → Plan → Authorize → Reconcile → Verify, não criar labels primeiro e Inspecionar depois
5. **Workspace Reconciliation como Capability** — confirmado e documentado; "workspace-reconciliation" como VALUE no campo Cycle é prático e aceitável

### Critérios atendidos

| Critério | Status |
|---|---|
| Convergência de operações analisada e documentada | ✓ |
| Decisão explícita para Approve Waiver | ✓ (Reutilizar Approve) |
| Decisão explícita para Collect Evidence | ✓ (Reutilizar Capture) |
| Apenas operação genuinamente nova adicionada | ✓ (somente Reconcile) |
| work-item-schema.md atualizado com Reconcile | ✓ |
| Finding, Remediation, Waiver, Check no artifact_type | ✓ |
| matrix.md atualizado com entidades Diligence | ✓ |
| github-workspace-schema.yaml criado e válido | ✓ |
| Campos derivados → Fase E apenas | ✓ |
| Campos derivados não editáveis | ✓ |
| Views com automação marcadas deferred | ✓ |
| Inspect marcado read_only = true, enabled = false | ✓ |
| Reconcile marcado requires_authorization = true | ✓ |
| github-workspace-readiness.md criado com 9 seções | ✓ |
| 20 anti-padrões documentados | ✓ |
| manifest.yaml atualizado com readiness + schema | ✓ |
| Sequência canônica corrigida vs. relatório anterior | ✓ |
| Sem comandos gh create/config nos novos arquivos | ✓ |
| Sem entidades GitHub reais criadas | ✓ |
| Nenhum código de produto modificado | ✓ |
| Nenhum commit realizado | ✓ |

---

## 2. Operações convergidas

### Análise completa de convergência

| Necessidade da Diligence | Operação existente | Adequada? | Decisão | Rationale |
|---|---|---|---|---|
| Investigar Finding | `Review` | Sim | **Reutilizar `Review`** | Review cobre avaliação contextual e investigação de qualquer artefato do Knowledge Space |
| Implementar Remediation | `Implement` | Sim | **Reutilizar `Implement`** | Implement cobre implementação de correções; Repair é nome de fase do Diligence Async, não operação de Work Item |
| Verificar Remediation | `Validate` | Sim | **Reutilizar `Validate`** | Validate cobre verificação contra critérios objetivos com independência de quem implementou |
| Aprovar Waiver | `Approve` | Sim (com filtro) | **Reutilizar `Approve`** | Ver análise abaixo |
| Revisar Waiver | `Review` | Sim | **Reutilizar `Review`** | Review cobre revisão de qualquer artefato incluindo Waiver antes de aprovação |
| Coletar Evidence | `Capture` | Sim (com filtro) | **Reutilizar `Capture`** | Ver análise abaixo |
| Reconciliar Workspace | (nenhuma) | Não | **CRIAR `Reconcile`** | Nenhuma operação existente cobre "alinhar estado real ao estado canônico declarado" |

### Decisão detalhada: Aprovar Waiver

**Opções avaliadas:**
1. Nova operação canônica `Approve Waiver` — composta, inconsistente com padrão monossilábico
2. Especialização de `Approve` — desnecessária; `Approve` já é semântico o suficiente
3. `Approve + Artifact Type = Waiver` — suficiente para filtro e governança
4. Decisão fora do campo Operation — perderia rastreabilidade no Project

**Decisão: `Approve + Artifact Type = Waiver`**

Justificativa:
- `Approve` existe e significa "artefato recebe aprovação formal (muda estado)" — semântica exata da aprovação de Waiver
- A combinação `Approve + Artifact Type = Waiver` é suficiente para filtro no Project e Views
- Para roteamento fora do Project, a label `diligence:waiver-review` cobre a identificação global
- Operações compostas como `Approve Waiver` criariam inconsistência com o padrão existente de operações em verbo singular
- O PR body template para Waiver (com campo `Required Approver`) já documenta a autoridade necessária

### Decisão detalhada: Coletar Evidence

**Opções avaliadas:**
1. `Capture` (existente para "sinal ou observação registrada") — cobre a semântica
2. `Attach` (existente para "link adicionado ao OBC ou Trail") — cobre caso de evidence existente
3. Nova operação `Collect Evidence` — redundante com Capture + Artifact Type = Evidence
4. Evidence representada apenas como entidade, sem Work Item próprio — correto por padrão

**Decisão: `Capture + Artifact Type = Evidence`**

Justificativa:
- `Capture` já existe no enum e cobre "registrar/capturar observação"
- A combinação `Capture + Artifact Type = Evidence` identifica precisamente a operação
- Em contexto de Diligence, Capture já aparece em matrix.md para Evidence (Diligence + Both)
- `Attach` cobre o caso onde a Evidence já existe e está sendo vinculada a um artefato
- Adicionar `Collect Evidence` como nova operação aumenta vocabulário sem adicionar semântica nova

### Operação criada: `Reconcile`

**Necessidade:** Work Items de Workspace Reconciliation precisam de uma Operation que represente "alinhar estado real ao estado canônico declarado". Nenhuma operação existente cobre esta semântica:
- `Update` → atualiza conteúdo com nova informação; não implica detecção de drift
- `Implement` → desenvolve código; não implica comparação com especificação
- `Validate` → verifica contra critérios; é o step Verify (pós-Reconcile), não o Reconcile em si

**Família:** Execução (ao lado de Implement, Experiment, Release)
**Adicionado em:** `work-item-schema.md` com rationale completo e exemplos de uso

---

## 3. Schema proposto

### Campos — classificação completa

| Campo | Classificação | Fase | Editável | Notas |
|---|---|---|---|---|
| Status | base_existing | A | Sim | Estado da operação, não da entidade |
| Repository | base_existing | A | Não | Contexto de repo |
| Owner | base_existing | A | Sim | Responsável operacional |
| Journey | work_item_canonical | C | Não | Filtro por jornada |
| Cycle | work_item_canonical | C | Não | Inclui workspace-reconciliation como valor prático |
| Phase | work_item_canonical | C | Não | 10 fases entre 3 ciclos/capability |
| Operation | work_item_canonical | C | Sim (operacional) | 11 operações Diligence-relevantes |
| Mode | work_item_canonical | C | Não | Sync / Async / Manual |
| Artifact ID | work_item_canonical | C | Não | Âncora de traceabilidade primária |
| Artifact Type | work_item_canonical | C | Não | Inclui Finding, Remediation, Waiver, Evidence, Check |
| Blocking | derived | E | Não | Calculado de Check + Finding + Waiver |
| Waiver Expiration | derived | E | Não | Sincronizado de WVR-*.expires_at |
| Finding Status | derived | E | Não | Sincronizado de FND-*.status |
| Finding Severity | derived | E | Não | Sincronizado de FND-*.severity |
| Check Result | rejected | N/A | N/A | Referência a EVD-* no body é suficiente para v1 |
| Finding ID | rejected | N/A | N/A | Redundante com Artifact ID + Artifact Type = Finding |
| Remediation ID | rejected | N/A | N/A | Redundante com Artifact ID + Artifact Type = Remediation |
| Waiver ID | rejected | N/A | N/A | Redundante com Artifact ID + Artifact Type = Waiver |
| Check ID | rejected | N/A | N/A | Redundante com Artifact ID + Artifact Type = Check |

### Labels — decisões

| Label | Status | Rationale |
|---|---|---|
| `diligence` | Aprovada | Identificação global de Work Items de Diligence; útil em PRs e buscas |
| `diligence:investigation` | Aprovada | Operação de investigação fora do Project |
| `diligence:remediation` | Aprovada | Operação de implementação fora do Project |
| `diligence:verification` | Aprovada | Operação de verificação fora do Project |
| `diligence:waiver-review` | Aprovada | Roteamento de PRs de Waiver para aprovadores com autoridade |
| `diligence:reconciliation` | Aprovada | Operações de Workspace Reconciliation fora do Project |
| `diligence:evidence-collection` | Adiada | Aguarda validação de Capture + Artifact Type como suficiente |
| `journey:diligence` | Rejeitada | Redundante com campo Journey e label 'diligence' — três formas do mesmo conceito |
| `artifact-type:*` | Rejeitada | Redundante com campo Artifact Type; prefixo ID (FND-, RMD-, etc.) já identifica tipo |
| `operation:*` | Adiada | Avaliar após Fase C; labels diligence:* podem ser suficientes |

### Views — readiness

| View | Status | Fase | Dependência |
|---|---|---|---|
| Diligence Operations | Pronta | C | Journey + Status |
| Active Remediations | Pronta | C | Artifact Type + Status |
| Workspace Reconciliation | Pronta | C | Cycle + Status |
| Verification Queue | Pronta | C | Operation + Status |
| Diligence History | Pronta | C | Journey + Status |
| Waiver Reviews | Pronta | C | Artifact Type + Status (sem Waiver Expiration) |
| Blocking Findings | Adiada | E | Campo Blocking derivado |

---

## 4. Readiness

### Resumo da matriz de readiness

| Categoria | Fase C | Fase E | Rejeitado | Adiado | Total |
|---|---|---|---|---|---|
| Campos | 10 | 4 | 5 | 0 | 19 |
| Labels | 6 | 0 | 4 | 3 | 13 |
| Templates | 4 | 0 | 0 | 0 | 4 |
| Views | 6 | 1 | 0 | 0 | 7 |
| Operações/Enums | 2 | 0 | 0 | 0 | 2 |
| Capabilities | 1 | 0 | 0 | 0 | 1 |
| **Total** | **29** | **5** | **9** | **3** | **46** |

**29 elementos prontos para Fase C** (após Inspect + autorização)
**5 elementos para Fase E** (requerem automação de derivação)
**9 elementos rejeitados** (com razão documentada)
**3 elementos adiados** (aguardam validação de necessidade)

---

## 5. Inspect

### Protocolo

O Inspect é **estritamente read-only**. Não cria, não modifica, não remove nada.

**Escopo:** 9 categorias — campos do Project (tipos, opções), views (filtros, agrupamentos), labels, templates de Issue, templates de PR, automações, entradas no manifest, permissões.

**Output:** `prodops/artifacts/diligence/reports/github-workspace-inspection-YYYY-MM-DD.md`

**Taxonomia de drift:**

| Classificação | Definição |
|---|---|
| Compliant | Estado observado = estado esperado no schema |
| Missing | Esperado no schema, não existe no workspace |
| Unexpected | Existe no workspace, não está no schema |
| Different | Existe com configuração divergente |
| Unsupported | Não pode ser implementado com API disponível |
| Unverifiable | Inspect não confirmou — tratar como Missing para plano |

**Regra crítica:** Unexpected ≠ Inválido. Investigar uso antes de propor remoção.

---

## 6. Reconcile

### Estrutura do plano

Cada ação no plano de Reconcile deve documentar:
- `target`, `category`, `action` (Create/Update/Rename/Deprecate/Remove/Deferred/Unsupported)
- `current_state`, `expected_state`, `reason`
- `risk`, `reversible`, `automation_mechanism`
- `approval_required`, `rollback`

### Autorização

Reconcile **nunca** executa sem aprovação humana explícita. O plano é aprovado antes de qualquer ação.

### Automation First (ordem)

1. GitHub official API (GraphQL ou REST)
2. GitHub official SDK
3. GitHub CLI (comandos de criação de campo, label, view)
4. MCP integration autorizada
5. Web-assisted (humano segue instruções)
6. Manual instruction (último recurso; sempre com Issue de rastreamento)

### Política conservadora de remoção

Elementos Unexpected não são removidos automaticamente. Antes de incluir qualquer remoção no plano: identificar uso, identificar owner, verificar dependências, produzir Evidence, obter autorização explícita, definir rollback.

---

## 7. Verify

### Checks

- **DIL-WSP-001** — Workspace Schema Conforms to Declared Configuration

### Evidence mínima obrigatória

9 componentes obrigatórios: snapshot_before, authorized_plan, commands_or_mechanism, api_responses, snapshot_after, dil_wsp_001_result, limitations_noted, deferred_items, approver.

### Resultado esperado

Todos os elementos da Fase C devem ser Compliant. Elementos Deferred documentados explicitamente. Se DIL-WSP-001 Fail ou Warning: criar Finding antes de marcar Verify como completo.

---

## 8. Arquivos

| Arquivo | Criado/Modificado | Função | Validação |
|---|---|---|---|
| `prodops/framework/journeys/diligence/github-workspace-schema.yaml` | Criado | Schema declarativo machine-readable do estado esperado — 865 linhas | V1 PASS |
| `prodops/framework/journeys/diligence/github-workspace-readiness.md` | Criado | Protocolo de readiness — 9 seções, 20 anti-padrões, 7 riscos — 638 linhas | V8 PASS |
| `prodops/exec/manifest.yaml` | Modificado | Adicionados `readiness` e `schema` ao bloco `github_workspace` | V6 PASS |
| `prodops/framework/execution-mapping/work-item-schema.md` | Modificado | `Reconcile` adicionado ao operation enum; Finding/Remediation/Waiver/Check ao artifact_type; exemplos Diligence | ✓ |
| `prodops/framework/execution-mapping/matrix.md` | Modificado | Seção "Diligence — Entidades Canônicas" adicionada; resumo de recursos atualizado | ✓ |
| `prodops/documentation-review-diligence-github-readiness.md` | Criado | Este relatório de execução | ✓ |

---

## 9. Validações

| Validação | Descrição | Resultado |
|---|---|---|
| V1 | YAML válido | PASS ✓ |
| V2 | Campos derivados → Fase E apenas | PASS ✓ (Blocking, Waiver Expiration, Finding Status, Finding Severity → E) |
| V3 | Campos derivados não editáveis | PASS ✓ (todos editable=False) |
| V4 | Views com automação marcadas deferred | PASS ✓ (Blocking Findings → deferred) |
| V5 | Inspect read_only=true + Reconcile requires_authorization=true | PASS ✓ |
| V6 | manifest.yaml atualizado com readiness + schema | PASS ✓ |
| V7 | Sem comandos gh create/config nos novos arquivos | PASS ✓ (0 matches) |
| V8 | 9 seções em readiness.md | PASS ✓ |
| V9 | Tamanhos de arquivo | PASS ✓ (865 + 638 = 1503 linhas) |
| V10 | Workspace Reconciliation como Capability (não Cycle) | PASS com nota — ver abaixo |

**Nota sobre V10:** O grep `workspace-reconciliation.*cycle\|cycle.*workspace-reconciliation` detecta ocorrências onde "workspace-reconciliation" é um VALUE do campo Cycle (ex: `Cycle = workspace-reconciliation`) — não onde Workspace Reconciliation é classificada como Cycle. Os documentos distinguem explicitamente: o schema inclui nota "WR é Capability; valor usado para Work Items" e o readiness.md documenta "Workspace Reconciliation é uma Capability (não Cycle canônico)". As ocorrências são false positives do pattern matching.

---

## 10. Riscos residuais

| ID | Risco | Nível | Mitigação |
|---|---|---|---|
| RR-1 | GitHub API pode não suportar criação de Views programaticamente | Médio | Verificar durante Inspect; documentar como Unsupported; usar Web-Assisted |
| RR-2 | Campos do Project podem existir com nomes diferentes dos esperados | Médio | Inspect com busca ampla; classificar como Different, não Missing |
| RR-3 | Labels podem conflitar com labels existentes de outros times | Alto | Inspect exaustivo; política conservadora de Unexpected |
| RR-4 | Campo Blocking derivado pode não ser tipo nativo do Project v2 | Alto | Verificar tipos disponíveis durante Inspect; automação externa se necessário |
| RR-5 | Permissões insuficientes para criar custom fields no Project | Alto | Verificar permissões como parte do Inspect; obter permissões antes do Reconcile |
| RR-6 | Token GitHub sem escopo correto para Inspect | Alto | Garantir scopes: project, repo, write:org antes de iniciar Inspect |
| RR-7 | Alinhamento do time sobre vocabulário de operações | Médio | Revisar schema com time antes do Reconcile; Inspect não cria — há tempo para discussão |

---

## 11. Readiness para próxima etapa

### Próxima etapa: SOMENTE Workspace Reconciliation Inspect

A única ação permitida na próxima etapa é o **Inspect** do workspace GitHub real.

**O que o Inspect DEVE fazer:**
- Ler o estado real do workspace GitHub via API (com autenticação adequada)
- Comparar com `github-workspace-schema.yaml` elemento por elemento
- Classificar cada elemento: Compliant / Missing / Unexpected / Different / Unsupported / Unverifiable
- Documentar todas as limitações de API encontradas
- Produzir relatório em `prodops/artifacts/diligence/reports/github-workspace-inspection-YYYY-MM-DD.md`
- Registrar Evidence (EVD-YYYY-NNNN) com snapshot do estado observado

**O que o Inspect NÃO DEVE fazer:**
- Criar nenhum label, campo, view ou template
- Modificar nenhum elemento existente no workspace
- Remover nenhum elemento Unexpected
- Executar nenhum Reconcile
- Emitir plano de ações sem primeiro produzir o relatório de drift
- Declarar conformidade sem comparação exata com o schema

### O que vem DEPOIS do Inspect

Somente após o relatório de Inspect estar completo:
1. **Plan** — calcular drift e documentar cada ação proposta com mecanismo e rollback
2. **Authorize** — aprovação humana explícita do plano
3. **Reconcile** — executar apenas as ações autorizadas, em Automation First order
4. **Verify** — executar DIL-WSP-001 e registrar Evidence completa

---

## 12. Correção da sequência anterior

O relatório anterior (`prodops/documentation-review-diligence-github-workspace.md`,
Seção 10 — "Readiness para próxima etapa") recomendava a seguinte ordem:

> 1. Aprovar schema de campos
> 2. **Criar labels** ← criação ANTES do Inspect
> 3. Configurar campos do Project
> 4. Criar template de Issue body
> 5. Criar template de PR body
> 6. Criar Views
> 7. Workspace Reconciliation: Inspect ← Inspect DEPOIS da criação
> 8. Workspace Reconciliation: Reconcile
> 9. Workspace Reconciliation: Verify

**Essa sequência estava incorreta.** Criar labels (passo 2) antes do Inspect (passo 7) viola o princípio de que o Inspect deve capturar o estado real ANTES de qualquer modificação.

**A sequência canônica corrigida é:**

```
Specify   ← github-workspace.md + github-workspace-schema.yaml (concluído)
   ↓
Inspect   ← leitura read-only do estado real — PRIMEIRO
   ↓
Plan      ← baseado nos dados reais do Inspect
   ↓
Authorize ← aprovação humana do plano
   ↓
Reconcile ← criar labels, campos, views conforme plano autorizado
   ↓
Verify    ← DIL-WSP-001 + Evidence
```

**Por que a sequência anterior estava errada:**
1. Criar labels sem Inspecionar arrisca conflito com labels existentes de outros fluxos
2. Unexpected pode significar elementos legítimos que não estão no schema — Inspect revela isso
3. Sem snapshot pré-Reconcile, não há Evidence de rollback confiável
4. Autorizar criação sem dados reais é autorizar com pressupostos, não com fatos

Este relatório formaliza a sequência correta e garante que nenhum elemento seja criado antes do Inspect real ser executado.
