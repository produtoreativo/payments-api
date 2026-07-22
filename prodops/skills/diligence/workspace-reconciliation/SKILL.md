---
name: diligence/workspace-reconciliation
description: Orchestrate Inspect → Reconcile → Verify to align the GitHub Workspace with the Canonical Specification. Entry point for any caller (Bootstrap, Diligence Async, Diligence Sync). Never runs standalone as a third cycle.
---

# WORKSPACE RECONCILIATION — Orchestrator

Workspace Reconciliation é uma **capability**, não um ciclo. É invocada por Bootstrap, Diligence Async e Diligence Sync como sub-rotina de alinhamento da infraestrutura do GitHub Workspace com a Canonical Specification.

**Dois projetos gerenciados:**
- `ProdOps — template` — template canônico da org (source para cópias)
- `ProdOps — <repo-name>` — projeto gerenciado do repositório atual

## Ação

### 1. Ler o contexto do caller

Identificar quem invocou esta capability:
- **Bootstrap** → executar Inspect → Reconcile → Verify em sequência completa. Retornar Conformance Report ao Bootstrap.
- **Diligence Async** → executar Inspect primeiro; se Workspace Drift detectado, executar Reconcile → Verify; se não houver drift, executar apenas Verify para confirmar e atualizar o manifest.
- **Diligence Sync** → executar Inspect para identificar o gap específico que causou o bloqueio; executar Reconcile apenas para esse gap; executar Verify.

Se o caller não for identificado, executar sequência completa: Inspect → Reconcile → Verify.

### 2. Executar Inspect

Ler a Canonical Specification (`prodops/framework/github-workspace.md`) e o Actual Workspace (estado real do GitHub via API). Produzir Drift Report.

Seguir: [steps/inspect/SKILL.md](steps/inspect/SKILL.md)

**Output esperado:** Drift Report no formato:

```
=== DRIFT REPORT — <data> ===

LABELS (<N> ausentes, <N> divergentes): ...
MILESTONES (<N> ausentes): ...
TEMPLATE (ProdOps — template): ...
PROJETO GERENCIADO (ProdOps — <repo-name>): ...
```

### 3. Verificar se há Workspace Drift

- **Sem drift:** pular Reconcile e ir direto para Verify (confirmar e atualizar manifest).
- **Com drift:** executar Reconcile antes do Verify.

### 4. Executar Reconcile (se Workspace Drift detectado)

Executar as criações e atualizações identificadas pelo Inspect. Para gaps não automatizáveis, abrir Issue de rastreamento.

Seguir: [steps/reconcile/SKILL.md](steps/reconcile/SKILL.md)

**Ordem obrigatória:** Labels → Template → Projeto Gerenciado → Milestones. O projeto gerenciado depende do template existir.

### 5. Executar Verify

Confirmar programaticamente o estado de todas as categorias e atualizar o sync manifest.

Seguir: [steps/verify/SKILL.md](steps/verify/SKILL.md)

**Output esperado:** Conformance Report:

```
╔══════════════════════════════════════════════════════════════╗
║  CONFORMIDADE — <data>                                       ║
║  Repositório: <owner>/<repo>  |  Project: #<N>              ║
╠══════════════════════════════════════════════════════════════╣
║  Labels        ✅ CONFORME    — <N> labels em conformidade   ║
║  Custom Fields ✅ CONFORME    — 8/8 campos                   ║
║  Views         ✅ CONFORME    — 5/5 views                    ║
║  Milestones    ✅ N/A         — nenhum OBC com release       ║
╠══════════════════════════════════════════════════════════════╣
║  Resultado geral: CONFORME | PARCIAL | NÃO CONFORME          ║
╠══════════════════════════════════════════════════════════════╣
║  Automation Opportunities (se houver)                        ║
║  - <ação> — aguardando autorização para Browser Automation   ║
╠══════════════════════════════════════════════════════════════╣
║  Known Platform Limitations (se houver)                      ║
║  - group_by: GitHub API não suporta (REST 404, sem GraphQL)  ║
╠══════════════════════════════════════════════════════════════╣
║  Próxima Ação (se Automation Opportunities presentes)        ║
║  Posso executar via Browser Automation. Deseja que execute?  ║
╚══════════════════════════════════════════════════════════════╝
```

Quando não há Workspace Drift: reportar "Desired state satisfied. No reconciliation actions required." — nunca "Reconcile skipped."

### 6. Retornar ao caller

Entregar o Conformance Report ao caller com:
- Resultado geral: `CONFORME`, `PARCIAL` ou `NÃO CONFORME`
- Issues abertos para gaps não automatizáveis (com número e link)
- Seção "Automation Opportunities" para ações realizáveis via Browser Automation aguardando autorização
- Seção "Known Platform Limitations" para limitações demonstradas de API com rastreamento via Issue
- Ações pendentes de Product Owner (ex: criação de Milestones) referenciadas por Issue — nunca como instrução flutuante

Quando não há Workspace Drift: reportar "Desired state satisfied. No reconciliation actions required." — nunca "Reconcile skipped."

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- Drift Report produzido pelo Inspect
- Reconcile executado se Workspace Drift foi detectado
- Verify executado e Conformance Report produzido
- Sync manifest atualizado com o estado verificado
- Caller recebeu o Conformance Report

## Guardrails

- **Nunca operar em projetos manuais** — qualquer projeto sem o prefixo `ProdOps — ` é ignorado.
- **Nunca executar como ciclo standalone** — esta capability é sempre invocada por um caller.
- **Ordem obrigatória:** Inspect → (Reconcile se drift) → Verify. Nunca inverter.
- **Identificar projetos por nome exato, nunca por número.**
- **Sync manifest é atualizado apenas pelo Verify** — nunca pelo Inspect ou Reconcile.
- **Automation First (Princípio 8)** — tentar API → MCP → CLI → SDK → Browser Automation antes de declarar qualquer limitação. Manual Exception somente quando tudo falhar, sempre com Issue de rastreamento aberto. Ver [automation-first.md](../../../framework/automation-first.md).

## References

→ [Capability README](../../../framework/journeys/diligence/workspace-reconciliation.md)
→ [Canonical Specification](../../../framework/github-workspace.md)
→ [GitHub Sync Manifest](../../../artifacts/governance/github-sync-manifest.md)
