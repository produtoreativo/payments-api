# Relatório de Execução — GitHub Workspace Specification
# ProdOps Framework — Diligence GitHub Workspace v1.0.0

> Executado em: 2026-07-24
> Escopo: Definição do modelo canônico de representação de operações Diligence no GitHub
> Input: Documentos de modelo, persistência, catálogo, jornada e execução-mapping já formalizados
> Status: **concluído — especificação criada, relatório gerado, validações executadas**

---

## 1. Executive Summary

### Objetivo

Definir o modelo canônico para representação de operações Diligence no GitHub (Execution Space), preservando o princípio fundamental de que o GitHub representa operações sobre entidades — não as entidades canônicas em si.

### Arquivos criados

| Arquivo | Função |
|---|---|
| `prodops/framework/journeys/diligence/github-workspace.md` | Especificação canônica do workspace — 26 seções, 1040 linhas |
| `prodops/documentation-review-diligence-github-workspace.md` | Este relatório de execução |

### Arquivos modificados

| Arquivo | O que mudou |
|---|---|
| `prodops/exec/manifest.yaml` | Adicionado bloco `github_workspace` com referência à especificação e status `planned` |
| `prodops/documentation-review-diligence-check-catalog.md` | 4 correções editoriais de contagens inconsistentes com o catalog.yaml |

### Correções editoriais ao check-catalog report

As seguintes inconsistências foram encontradas e corrigidas no relatório anterior, usando `catalog.yaml` como fonte de verdade:

| Campo | Valor no relatório | Valor correto (catalog.yaml) | Seção corrigida |
|---|---|---|---|
| Operacional (dimensão, contagem) | 8 | 7 | Seção 3 — Por dimensão |
| `auto_finding: true` (contagem) | 15 | 16 | Seção 4.5 + V8 |
| `auto_finding: false` (contagem) | 4 | 3 | Seção 4.5 |
| `human_review_required: true` (contagem) | 3 | 4 | Seção 4.6 |

Verificação: `DIL-CON-001, DIL-CON-002, DIL-STR-003, DIL-OPS-004` = 4 Checks com `human_review_required: true` (confirmado via `python3 -c "..."`).

### Decisões-chave

1. **Finding ≠ Issue** — princípio fundamental reforçado como Princípio 1 da especificação
2. **Artifact ID + Artifact Type como estratégia base** — evita proliferação de campos por entidade
3. **Blocking é derivado** — não editável manualmente; requer Waiver canônico para suspensão
4. **Check Result não recomendado na v1** — referência a Evidence no body é suficiente
5. **24 anti-padrões documentados** — cobrindo todas as violações identificadas
6. **Workspace Reconciliation como Capability** — não como terceiro ciclo; confirmado e reforçado

### Critérios atendidos

| Critério | Status |
|---|---|
| github-workspace.md criado com 26 seções | ✓ |
| Princípio "GitHub representa operações, não entidades" presente | ✓ |
| Finding ≠ Issue documentado explicitamente | ✓ |
| Cardinalidade N:M preservada e documentada | ✓ |
| 24 anti-padrões documentados (mínimo era 23) | ✓ |
| 5 exemplos completos com lição | ✓ |
| Blocking como campo derivado (não manual) | ✓ |
| Waiver Expiration como campo derivado | ✓ |
| Check Result não recomendado na v1 | ✓ |
| Workspace Reconciliation como Capability (não Cycle) | ✓ |
| Sem comandos gh create/config no documento | ✓ |
| Sem entidades GitHub reais criadas | ✓ |
| manifest.yaml atualizado com github_workspace | ✓ |
| Correções editoriais ao check-catalog report aplicadas | ✓ |
| Nenhum código de produto modificado | ✓ |
| Nenhum commit realizado | ✓ |

---

## 2. Modelo de representação

### Entidades no Knowledge Space

| Entidade | ID Canônico | Localização | É GitHub Issue? |
|---|---|---|---|
| Check | `DIL-CATEGORY-NNN` | `checks/catalog.yaml` | Não |
| Finding | `FND-YYYY-NNNN` | `artifacts/diligence/findings/` | Não |
| Evidence | `EVD-YYYY-NNNN` | `artifacts/diligence/evidence/` | Não |
| Remediation | `RMD-YYYY-NNNN` | `artifacts/diligence/remediations/` | Não |
| Waiver | `WVR-YYYY-NNNN` | `artifacts/diligence/waivers/` | Não |

### Operações no Execution Space

| Entidade | Tipo de Work Item | Quando criar | O que o WI representa |
|---|---|---|---|
| Finding | Issue | Quando há operação ativa | Investigação, rastreamento, ou gate |
| Remediation | Issue | Quando aprovada e em andamento | Implementação ou verificação |
| Waiver | Issue | Para revisão/aprovação operacional | Operação de revisão humana |
| Evidence | Issue (raro) | Coleta complexa ou recorrente | Operação de coleta explícita |
| Check (manual) | Issue | Execução extensa ou auditável | Execução formal de Check |

### Cardinalidades

```
Finding      N ─── N  Work Item
Remediation  N ─── N  Work Item
Waiver       N ─── N  Work Item
Evidence     N ─── N  Work Item
Check        N ─── N  Work Item
Work Item    1 ─── N  Entity Reference
```

### Princípio central

> **O GitHub representa operações sobre entidades da Diligence. Ele não representa as entidades canônicas em si.**

Consequências diretas:
- Finding sem Work Item ativo = estado correto, não lacuna
- Work Item Done ≠ Finding Resolved ou Verified
- Project vazio para uma entidade = sem operação ativa = correto
- Visibilidade de Finding vem de `registry.yaml` e relatórios, não do Project

---

## 3. Schema proposto

### Campos do GitHub Project

| Campo | Existente/Novo/Derivado | Fonte de verdade | Direção | Editável no Project | Uso |
|---|---|---|---|---|---|
| Status | Existente | GitHub | Execution-only | Sim | Estado da operação (Todo/In Progress/Done) |
| Repository | Existente | GitHub | Execution-only | Sim | Contexto de repositório |
| Journey | Existente | Work Item | Knowledge → GitHub | Não | Filtro (valor: Diligence) |
| Cycle | Existente | Work Item | Knowledge → GitHub | Não | Filtro (diligence-sync, diligence-async) |
| Phase | Existente | Work Item | Knowledge → GitHub | Não | Filtro por fase operacional |
| Operation | Existente/Estendido | Work Item | Knowledge → GitHub | Sim (operacional) | Tipo de operação (Repair, Validate, Approve Waiver, etc.) |
| Mode | Existente | Work Item | Knowledge → GitHub | Não | Sync/Async |
| Owner | Existente | GitHub | Execution-only | Sim | Responsável operacional |
| Artifact ID | Existente | Work Item | Knowledge → GitHub | Não | ID da entidade primária |
| Artifact Type | Existente | Work Item | Knowledge → GitHub | Não | Finding | Remediation | Evidence | Waiver | Check |
| Blocking | Derivado/Novo (futuro) | Check + Finding + Waiver | Knowledge → GitHub | Não | Gate; calculado automaticamente |
| Waiver Expiration | Derivado/Novo (futuro) | Arquivo Waiver | Knowledge → GitHub | Não | Alerta de expiração |
| Finding Severity | Derivado (avaliar) | Arquivo Finding | Knowledge → GitHub | Não | Filtro/agrupamento se necessário |
| Finding Status | Derivado (avaliar) | Arquivo Finding | Knowledge → GitHub | Não | Visibilidade de estado separado de WI Status |
| Check Result | Não recomendado (v1) | Evidence | Knowledge → GitHub | Não | Não criar na v1 |

---

## 4. Views planejadas

| View | Propósito | Filtro | Agrupamento | Campos visíveis | Limitação |
|---|---|---|---|---|---|
| Diligence Operations | Operações ativas da Diligence | Journey = Diligence, Status ≠ Done | Artifact Type | Status, Artifact ID, Artifact Type, Operation, Phase, Owner | Não lista todos os Findings |
| Active Remediations | Remediations em andamento | Artifact Type = Remediation, Status ∈ {Todo, In Progress} | Status | Status, Artifact ID, Operation, Owner, Priority | Sem Remediations sem WI ativo |
| Blocking Findings | Findings com blocking ativo | Blocking = true, Status ≠ Done | Phase | Status, Artifact ID, Operation, Phase, Owner, Blocking | Requer campo Blocking derivado |
| Waiver Reviews | Operações de revisão de Waiver | Artifact Type = Waiver OR label = diligence:waiver-review | Status | Status, Artifact ID, Operation, Owner, Waiver Expiration | Não representa todos os Waivers |
| Workspace Reconciliation | Operações de reconciliação | Operation = Reconcile OR label = diligence:reconciliation | Status | Status, Artifact ID, Operation, Phase, Owner | Específico à Capability |
| Verification Queue | Verificações pendentes | Operation = Validate, Status = Todo | Priority | Status, Artifact ID, Artifact Type, Operation, Owner | Fila vazia ≠ tudo verificado |
| Diligence History | Histórico de operações | Status = Done, Journey = Diligence | Artifact Type + mês | Status, Artifact ID, Artifact Type, Operation, Phase, Owner | Não representa estado atual das entidades |

---

## 5. Labels

### Reutilizadas (existentes)

| Label | Contexto de reutilização |
|---|---|
| `journey:diligence` | Journey Diligence (padrão existente) |
| `artifact-type:finding` | Work Item sobre Finding |
| `artifact-type:remediation` | Work Item sobre Remediation |
| `artifact-type:waiver` | Work Item sobre Waiver |
| `artifact-type:evidence` | Work Item sobre Evidence |
| `artifact-type:check` | Work Item sobre Check |
| `operation:repair` | Operação de Remediation/Repair |
| `operation:validate` | Operação de verificação |
| `operation:review` | Operação de revisão |
| `operation:reconcile` | Operação de reconciliação |

### Propostas (novas)

| Label | Propósito |
|---|---|
| `diligence` | Label base identificadora de todos os Work Items de Diligence |
| `diligence:investigation` | Operação de investigação de Finding |
| `diligence:remediation` | Operação de implementação de Remediation |
| `diligence:verification` | Operação de verificação pós-Remediation |
| `diligence:waiver-review` | Operação de revisão ou aprovação de Waiver |
| `diligence:reconciliation` | Operação de Workspace Reconciliation |
| `diligence:evidence-collection` | Coleta explícita de Evidence |
| `operation:approve-waiver` | Operação específica de aprovação de Waiver |
| `operation:collect-evidence` | Operação específica de coleta de Evidence |

### Rejeitadas (com razão)

| Label rejeitada | Razão |
|---|---|
| `finding:FND-YYYY-NNNN` | ID canônico como label é frágil e cria dependência — usar campo Artifact ID |
| `severity:high` / `severity:critical` | Severidade pertence ao arquivo Finding no Knowledge Space |
| `waiver-active` | Waiver ativo é estado canônico no arquivo — label não é suficiente |
| `verified` | Status canônico de Finding — não representável por label |
| `blocking` | Campo derivado — não atribuível manualmente |
| `expired` | Estado temporal do Waiver — pertence ao arquivo |

---

## 6. Decisões arquiteturais

### Finding sem Issue: justificativa

Finding pode existir sem Work Item ativo. A criação de Issue para todo Finding violaria o princípio N:M, poluiria o Project com trabalho fantasma, e confundiria estado de entidade com estado de operação. A visibilidade de Findings vem de `registry.yaml`, relatórios e dashboards futuros — não do Project.

### Artifact ID + Artifact Type como estratégia base

Em vez de criar campos específicos por entidade (Finding Severity, Finding ID, Remediation ID, Waiver ID, Check ID), a estratégia adotada é:
- `Artifact ID`: ID da entidade primária (FND-*, RMD-*, WVR-*, EVD-*, DIL-*)
- `Artifact Type`: tipo da entidade (Finding, Remediation, Waiver, Evidence, Check)

Campos específicos (Severity, Status de entidade) só são criados quando há necessidade demonstrada de filtro/agrupamento que não pode ser satisfeita pelos campos base. Isso minimiza a superfície de drift.

### Waiver: arquivo canônico é a autoridade

O Waiver válido é o arquivo `WVR-YYYY-NNNN.md` com:
- `approved_by` preenchido com identificador do aprovador com autoridade
- `approved_at` com datetime da aprovação
- `expires_at` com data futura (obrigatório sem exceção)
- Evidence de aprovação referenciada (EVD do PR de aprovação)
- Todos os campos obrigatórios de DIL-OPS-005 satisfeitos

Issue, label, status de Project ou mudança de campo: nenhum desses constitui aprovação de Waiver.

### Evidence: não é comentário

Evidence canônica com identidade própria (`EVD-YYYY-NNNN.md`) é usada quando:
- Reutilizada por múltiplos Findings
- Prova Remediation ou verificação
- Tem validade temporal
- Contém saída técnica relevante para auditoria

Comentários de Issue não têm ID próprio, não são imutáveis, não são referenciáveis por ID canônico.

### Blocking: derivado e não editável

`blocking_effective` é calculado a partir das entidades canônicas (Check.blocking, Finding.status, Waiver.status, Waiver.expires_at). Não pode ser sobrescrito manualmente no Project. A única forma de suspender blocking é via Waiver canônico válido.

### Status: estado de entidade ≠ estado de operação

| | Tipo | Dono | Exemplo |
|---|---|---|---|
| Finding Status | Estado de entidade | Knowledge Space | Open, In Remediation, Verified |
| Work Item Status | Estado de operação | GitHub | Todo, In Progress, Done |

Fechar um Work Item não altera o Finding Status. O Finding Status só muda quando critérios canônicos são satisfeitos (Evidence, Check Pass, Waiver ativo, etc.).

### Check Result: não recomendado na v1

Check Result temporal não é adequado para campo de Project. A Evidence (`EVD-*`) captura resultado, timestamp e contexto com estrutura adequada. Um campo derivado pode ser adicionado em versões futuras quando houver necessidade demonstrada de filtro por resultado.

### Sincronização: regra por campo, não bidirecional sem controle

Cada campo tem fonte de verdade e direção declaradas (ver Seção 11 da especificação). Não existe sincronização bidirecional sem regras explícitas. Campos do Knowledge Space fluem `Knowledge → GitHub`. Campos do Execution Space são Execution-only. Campos derivados são calculados, não editáveis.

---

## 7. Arquivos

| Arquivo | Criado/Modificado | Função | Validação |
|---|---|---|---|
| `prodops/framework/journeys/diligence/github-workspace.md` | Criado | Especificação canônica do workspace — 26 seções, 1040 linhas, 24 anti-padrões, 5 exemplos, 10 princípios, schema completo | ✓ |
| `prodops/exec/manifest.yaml` | Modificado | Bloco `github_workspace` adicionado com referência à especificação e `implementation_status: planned` | ✓ |
| `prodops/documentation-review-diligence-check-catalog.md` | Modificado | 4 correções editoriais de contagens (Operacional: 8→7; auto_finding: true: 15→16; auto_finding: false: 4→3; human_review_required: true: 3→4) | ✓ |
| `prodops/documentation-review-diligence-github-workspace.md` | Criado | Este relatório de execução | ✓ |

---

## 8. Validações

### Comandos executados e resultados

**V1 — Arquivo existe e tem conteúdo:**
```bash
wc -l prodops/framework/journeys/diligence/github-workspace.md
```
Resultado: `1040 prodops/framework/journeys/diligence/github-workspace.md` ✓

**V2 — Sem comandos gh de configuração:**
```bash
grep -n "gh project create|gh label create|..." github-workspace.md | wc -l
```
Resultado: `0` ✓

**V3 — Princípio Finding ≠ Issue presente:**
Múltiplas ocorrências confirmadas, incluindo: "Nenhuma dessas entidades É um GitHub Issue. Um Finding não é uma Issue." ✓

**V4 — Cardinalidade N:M presente:**
Seção 5 (Princípio 5), Seção 6 (tabela N:N), múltiplas referências ✓

**V5 — Todas as 26 seções presentes:**
`grep -n "^## Seção " github-workspace.md` retornou 26 entradas (Seção 1 a Seção 26) ✓

**V6 — Blocking derivado (não manual):**
Campo `blocking_effective` com fórmula de cálculo documentado; "não editável" explícito em múltiplos pontos ✓

**V7 — manifest.yaml atualizado:**
```
141:  github_workspace:
142:    specification: prodops/framework/journeys/diligence/github-workspace.md
143:    implementation_status: planned
```
✓

**V8 — Sem entidades GitHub reais criadas:**
Nenhum arquivo `.sh` novo; nenhum `gh create` no documento de especificação ✓

**V9 — 5 exemplos presentes:**
Exemplo 1 (linha 853), Exemplo 2 (871), Exemplo 3 (907), Exemplo 4 (929), Exemplo 5 (958) ✓

**V10 — 24 anti-padrões:**
`grep -n "^[0-9]\+\. \*\*" github-workspace.md | wc -l` = 24 (requisito mínimo era 23) ✓

**V11 — Check Result documentado:**
Seção 22 completa com decisão "não recomendado na v1" e justificativa ✓

**V12 — Workspace Reconciliation como Capability:**
Nenhuma ocorrência de "Workspace Reconciliation.*Cycle" ou "Cycle.*Workspace Reconciliation" ✓

### Limitações das validações

- Validações são point-in-time — não garantem consistência futura
- A compatibilidade dos campos propostos com a API do GitHub Project v2 não foi verificada (requer acesso real ao workspace)
- A automação de sincronização de campos derivados não foi implementada — os campos Blocking, Waiver Expiration, Finding Status e Finding Severity são derivados apenas no design, não em execução

---

## 9. Riscos residuais

| ID | Risco | Impacto se não resolvido | Ação recomendada |
|---|---|---|---|
| R-1 | Campos derivados (Blocking, Waiver Expiration, Finding Status) requerem automação não implementada | Campos criados sem automação = drift imediato após primeiro uso | Implementar automação de sincronização antes de criar os campos no Project; ou não criar os campos até a automação estar pronta |
| R-2 | Schema de `work-item-schema.md` não inclui `Approve Waiver` e `Collect Evidence` | Agentes podem usar operações não canônicas ou genéricas | Propor adição das operações ao `work-item-schema.md` como próxima fase |
| R-3 | Nomenclatura das labels (`diligence:*`) não foi validada com time | Time pode ter convenções diferentes | Revisar nomenclatura de labels com time antes de Workspace Reconciliation criar |
| R-4 | Ausência de template de Issue e PR no repositório GitHub | Operadores podem criar Work Items sem a estrutura canônica | Criar templates após aprovação do schema |
| R-5 | Visibilidade de Findings sem Work Item depende de ferramentas não implementadas | Findings existentes mas invisíveis operacionalmente sem dashboard | Implementar relatório agregado a partir de `registry.yaml` como prioridade antes do Project |
| R-6 | Compatibilidade dos campos com a API do GitHub Project v2 | Campo `Cycle` pode não existir como tipo nativo | Verificar disponibilidade de campos customizados do tipo single_select no Project v2 antes de Reconcile |
| R-7 | Campo `Phase` com valores mistos (Sync + Async) pode gerar confusão | Agentes podem filtrar incorretamente por fase | Considerar campos separados ou clarificação de valores no schema |

---

## 10. Readiness para próxima etapa

### Ordem segura de implementação

1. **Aprovar schema de campos** — Este documento e a especificação (`github-workspace.md`) constituem a proposta. Aprovação necessária antes de qualquer criação no Project.

2. **Criar labels** — Labels `diligence` e `diligence:*` são as de menor risco e maior impacto imediato. Não requerem automação. Workspace Reconciliation pode criar via gh CLI.

3. **Configurar campos do Project** — Operation (com novos valores Diligence), Artifact Type (com valores Finding/Remediation/etc.), Journey, Cycle, Phase, Mode. Não requerem automação de sincronização.

4. **Criar template de Issue body** — Seção `## ProdOps References` e `## Operation` como template reutilizável para Work Items de Diligence.

5. **Criar template de PR body** — Seção `## Diligence References` como template para PRs de Remediation, Waiver e Verificação.

6. **Criar Views** — Após campos configurados. Começar por Diligence Operations e Verification Queue (mais simples). Blocking Findings requer campo Blocking (mais complexo).

7. **Workspace Reconciliation: Inspect** — Comparar este documento com estado real do workspace. Identificar divergências.

8. **Workspace Reconciliation: Reconcile** — Aplicar mudanças autorizadas. Usar Automation First.

9. **Workspace Reconciliation: Verify** — Executar DIL-WSP-001. Registrar Evidence.

10. **Automação de campos derivados** — Implementar sincronização de Blocking, Waiver Expiration, Finding Status. Criar apenas após campos existirem e automação estar testada.

11. **Dashboard de Findings** — Ferramenta independente que lê `registry.yaml` e gera relatório. Não usa o GitHub Project como mecanismo.

### Decisões que precisam de aprovação antes de implementar

| Decisão | Por que aguarda aprovação |
|---|---|
| Schema de campos (nomes, tipos, valores de enums) | Time pode ter preferências sobre nomenclatura |
| Nomenclatura das labels `diligence:*` | Convenção pode conflitar com labels existentes |
| Adicionar `Approve Waiver` e `Collect Evidence` ao `work-item-schema.md` | Mudança normativa no schema canônico |
| Campo `Cycle` no Project | Pode não ser suportado nativamente como tipo — requer verificação técnica |
| Campos derivados (Blocking, Waiver Expiration) | Requerem automação — decisão sobre timing |
| Dashboard de Findings | Decisão sobre tecnologia e responsável |
