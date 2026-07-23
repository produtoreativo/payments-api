---
name: diligence/workspace-reconciliation/verify
description: Confirm that the GitHub repository state matches the Canonical Specification across all 4 categories. Reads Views via GraphQL. Updates the sync manifest with the verified conformance state. Produces the Conformance Report.
---

# WORKSPACE RECONCILIATION → VERIFY

Execute only the Verify step of the Workspace Reconciliation capability.

**Responsabilidade:** confirmar programaticamente o estado de todas as 4 categorias após o Reconcile e atualizar o sync manifest com o resultado verificado. Verify é a única fonte que atualiza o manifest com dados confirmados via API.

## Ação

### 1. Verificar Labels

```bash
gh label list --repo <owner>/<repo> --json name,color,description --limit 200
```

Comparar com Canonical Specification. Contar: conformes, ausentes, divergentes.

### 2. Verificar Milestones

```bash
gh api /repos/<owner>/<repo>/milestones --jq '[.[] | {title, state}]'
```

Comparar com OBCs no Iteration Plan que têm release definida. Para cada Milestone ausente, registrar como pendente de ação do Product Owner.

### 3. Verificar Custom Fields

```bash
gh project field-list <number> --owner <owner> --format json
```

Verificar quais campos canônicos existem. `Evidence Required` (CHECKBOX): verificar se existe entre os campos retornados. Se ausente, registrar como `PENDENTE — Issue #X documentado` (abrir Issue de rastreamento se ainda não existir).

### 4. Verificar Views via GraphQL

```bash
gh api graphql -f query='
query {
  organization(login: "<owner>") {
    projectV2(number: <N>) {
      views(first: 20) {
        nodes { id name }
      }
    }
  }
}'
```

Comparar nomes retornados com a lista canônica. Para cada view canônica: `CONFORME` se existe, `PENDENTE — Issue #X documentado` se ausente (abrir Issue de rastreamento se ainda não existir). Views extras (não canônicas) detectadas: registrar em "Automation Opportunities" como candidatas a remoção via Browser Automation.

### 5. Produzir Conformance Report

```
╔══════════════════════════════════════════════════════════════╗
║  CONFORMIDADE — <data>                                       ║
║  Repositório: <owner>/<repo>  |  Project: #<N>              ║
╠══════════════════════════════════════════════════════════════╣
║  Labels        ✅ CONFORME    — <N> labels em conformidade   ║
║                ⚠️  PARCIAL    — <N> ausentes: <lista>        ║
║                                                              ║
║  Milestones    ✅ N/A         — nenhum OBC com release       ║
║                ⚠️  PENDENTE   — v1.2 ausente (Product Owner) ║
║                                                              ║
║  Custom Fields ✅ CONFORME    — 8/8 campos                   ║
║                ⚠️  PARCIAL    — Evidence Required            ║
║                               PENDENTE — Issue #X           ║
║                                                              ║
║  Views         ✅ CONFORME    — 5/5 views                    ║
║                ⚠️  PENDENTE   — 3 views ausentes             ║
║                               PENDENTE — Issue #X           ║
║                                                              ║
║  Project       ✅ CONFORME    — Project #<N> acessível       ║
║                ⚠️  AUSENTE    — DIVERGENTE — reconcile req.  ║
╠══════════════════════════════════════════════════════════════╣
║  Resultado geral: CONFORME | PARCIAL | NÃO CONFORME          ║
╠══════════════════════════════════════════════════════════════╣
║  Automation Opportunities                                    ║
║  - Remover "View 1" — aguardando autorização Browser Auto.   ║
║  - Remover "test-view" — aguardando autorização Browser Auto.║
╠══════════════════════════════════════════════════════════════╣
║  Known Platform Limitations                                  ║
║  - group_by: GitHub API não suporta (REST 404, sem GraphQL)  ║
╠══════════════════════════════════════════════════════════════╣
║  Próxima Ação                                                ║
║  Posso executar via Browser Automation. Deseja que execute?  ║
╚══════════════════════════════════════════════════════════════╝
```

**Critério de resultado:**
- `CONFORME` — todas as 4 categorias sem divergências automatizáveis pendentes. Quando não há Workspace Drift: reportar "Desired state satisfied. No reconciliation actions required." — nunca "Reconcile skipped."
- `PARCIAL` — divergências com Issue de rastreamento aberto (Views, Checkbox, Milestones) mas nada automatizável restante
- `NÃO CONFORME` — Labels ou Fields automatizáveis ainda divergentes (Reconcile não foi executado ou falhou); ou projeto ausente (requer `gh project create` — DIVERGENTE, não "ação manual")

### 5b. Verificar Issues de infraestrutura abertos

```bash
gh issue list --repo <owner>/<repo> \
  --label "operation:provision,journey:diligence" \
  --state open \
  --json number,title,state
```

Incluir no Conformance Report: lista de Issues `infra:` abertos com número e título. Issues abertos indicam gaps documentados — não são falhas de processo, são rastreamento explícito.

### 6. Atualizar o sync manifest

Escrever em `prodops/artifacts/trails/github-sync-manifest.md`:
- Status de cada categoria baseado na verificação via API deste ciclo
- Para categorias PARCIAL: referenciar o Issue de rastreamento (ex: `PARCIAL — ver Issue #63`)
- Marcar `[x]` nas views e campos confirmados via API como existentes
- Adicionar linha no Histórico com: data, executor, resultado, Issues abertos

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- Todas as 4 categorias verificadas via API
- Conformance Report produzido com resultado explícito (`CONFORME`, `PARCIAL` ou `NÃO CONFORME`)
- Sync manifest atualizado com o estado verificado neste ciclo

## Guardrails

- **Verificar todas as 4 categorias** — não pular nenhuma mesmo que o manifest indique conformidade anterior.
- Nunca marcar uma categoria como `CONFORME` no manifest sem ter verificado via API nesta execução.
- Distinguir claramente entre `PENDENTE — Issue #X documentado` (gap com rastreamento) e `NÃO CONFORME automatizável` (requer re-executar Reconcile). Nunca usar `PENDENTE manual` como status — toda pendência deve ter um Issue de rastreamento.
- **Automation First (Princípio 8)** — projeto ausente é sempre `DIVERGENTE — reconcile required` (automatizável via `gh project create`), nunca "ação manual obrigatória". Ver [automation-first.md](../../../../../framework/automation-first.md).
- Sempre incluir seções "Automation Opportunities" e "Known Platform Limitations" no Conformance Report quando aplicável.
- Atualizar o manifest é obrigatório — Verify sem atualização de manifest não está completo.

## Out of scope

- `verify` **não** corrige divergências — isso é Reconcile.
- `verify` **não** verifica Issues individuais — isso é Scan (Diligence Async).
