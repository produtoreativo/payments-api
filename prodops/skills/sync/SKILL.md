---
name: sync
description: Synchronize a work branch with its base or align ProdOps artifacts with the current implementation. Use when fetching remote changes, resolving conflicts, updating from main, or when BDD Features, Event Storming, architecture, or the Release Trail are stale.
---

# SYNC

Use this skill to make the repository internally consistent with the current
ProdOps context or to synchronize a work branch with its intended base.

The Sync phase has two independent steps, each guaranteeing a distinct integrity:

- **`rebase` — integridade do repositório git** (pronto para merge, base incorporada, testes preservados)
- **`align` — integridade dos artefatos ProdOps** (BDD, Event Storming, arquitetura, OBC e Release Trail refletem o diff do branch)

Os steps são complementares: nenhum substitui o outro. O Sync **não** abre PR
(Finish), **não** roda a pipeline completa (Ship) e **não** reescreve decisões
de produto upstream. Quando invocado com um argumento de step (`/sync <step>`),
execute apenas aquele step. Caso contrário, execute ambos em sequência.

## Steps

| Step | File | When to use |
|---|---|---|
| `rebase` | [steps/rebase/SKILL.md](steps/rebase/SKILL.md) | Branch is behind origin, has conflicts, or needs to incorporate upstream changes |
| `align` | [steps/align/SKILL.md](steps/align/SKILL.md) | BDD Features, Event Storming, architecture, or Release Trail are stale relative to what was implemented |

If the requested step is not listed, run the full flow.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/product/`
- `prodops/journeys/assessment/`
- `prodops/artifacts/governance/trails/sessions/` (active session trail)

## Flow

When invoked without a step argument, execute both steps in sequence:

1. **[rebase](steps/rebase/SKILL.md)** — fetch remote updates, fast-forward base, integrate into feature branch, resolve conflicts, preserve TDD, validate
2. **[align](steps/align/SKILL.md)** — identify stale artifacts, trace source of truth in `prodops/`, update only impacted files, record in Release Trail

For detailed branch synchronization mechanics, read `references/workflow.md`.

## Guardrails

- Do not rewrite product decisions while doing consistency work.
- Do not duplicate Product Deck, Service Deck, OBC, or Reliability Plan content
  inside skills.
- Prefer references to canonical ProdOps paths.
- Never discard local changes.
- Never force-push or rewrite shared branch history unless the user explicitly
  requests it.
- Do not auto-stash unknown user work without approval.
- If conflicts occur, inspect both sides before editing.
- After conflict resolution, run tests that cover the conflicted files.
- Do not delete or weaken tests just to make synchronization pass.
