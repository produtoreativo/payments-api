---
name: sync/align
description: Align ProdOps artifacts with the current implementation. Use when BDD Features, Event Storming, architecture diagrams, or the Release Trail are stale relative to what was implemented in Hack.
---

# SYNC → ALIGN

Execute only the artifact alignment step of the Sync flow.

**Responsabilidade:** garantir a **integridade dos artefatos ProdOps** — revisar o diff do branch e atualizar apenas os artefatos canônicos inconsistentes com o que foi implementado. Este é um step de **rastreabilidade**, não de git (isso é `rebase`) nem de produto (decisões upstream são preservadas, não reescritas).

## Inputs

- Current diff (`git diff main...HEAD`) — what changed in this branch
- `prodops/artifacts/business/bdd/` — BDD Features
- `prodops/journeys/assessment/event-storming/plan.json` — Event Storming
- `prodops/artifacts/product/architecture/overview.md` — architecture diagram
- `prodops/artifacts/governance/trails/sessions/` — active session trail
- Relevant OBC in `prodops/artifacts/business/obcs/`

## Action

### 1. Identify what changed

Review the branch diff and list:

- behaviors added, changed, or removed
- domain events added, renamed, or removed
- structural changes (new module, route, external dependency, table, event topic)
- contracts changed (OpenAPI, AsyncAPI, BDD Feature)

### 2. Trace the source of truth

For each item identified, locate the canonical artifact in `prodops/`. Use this mapping as the source of truth — when in doubt, the artifact path wins over heuristics from module filenames:

| Mudança no código | Artefato canônico |
|---|---|
| Comportamento novo ou alterado | BDD Feature em `prodops/artifacts/business/bdd/` |
| Evento de domínio adicionado, renomeado ou removido | `prodops/journeys/assessment/event-storming/plan.json` |
| Novo módulo, rota, dependência externa ou tabela | `prodops/artifacts/product/architecture/overview.md` |
| OBC satisfeito ou alterado | `prodops/artifacts/business/obcs/<slug>.md` |

Quando uma mudança não se encaixa em nenhuma linha da tabela, isso é um sinal de artefato canônico ausente — registre como gap (veja Guardrails), em vez de inventar um novo artefato.

### 3. Update only stale artifacts

Update each artifact that is inconsistent with the implementation:

- **BDD Feature** — reflect the behavior as implemented, not as originally speculated.
- **Event Storming** — add/rename/remove events in `customEvents`; update flow bands; add `sloSuggestions` if on critical path; update `assumptions[last]` with today's date.
- **Architecture** — edit the Mermaid diagram; add a row to the History table.

Do not touch artifacts that are already consistent. Do not rewrite product decisions made upstream of this branch.

### 4. Validate links and Markdown

Check that all internal links in updated files resolve. Verify changed Markdown renders correctly (headings, tables, code blocks).

### 5. Record in the Release Trail

Append an entry to the active session trail (`prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`) when the alignment is meaningful (behavior change, structural update, or contract correction). Include:

- what artifact was updated
- why it was stale (what the implementation introduced)
- date

Preserve all historical entries — append only, never replace.

## Post-conditions

**Critério de conclusão — integridade dos artefatos ProdOps:** concluído quando **todos** os itens abaixo são verdadeiros:

- All ProdOps artifacts reflect the current implementation.
- No stale BDD Features, Event Storming entries, or architecture descriptions remain for this branch's changes.
- Release Trail updated when the alignment was meaningful.
- No product decisions were rewritten.

## Guardrails

- Do not rewrite product decisions while doing consistency work.
- Do not duplicate Product Deck, Service Deck, OBC, or Reliability Plan content — prefer references to canonical paths.
- Do not update artifacts that are unrelated to this branch's changes.
- Preserve historical Release Trail entries — append, never replace.
- If an artifact is missing entirely (e.g. no BDD Feature exists for the behavior), record it as a gap rather than inventing content.

## Out of scope — not the responsibility of `align`

- `align` **does not** resolve git conflicts or integrate the base — that is `rebase`.
- `align` **does not** validate quality gates of code (lint, tests, coverage) — that is Hack (Yellow Bar) and Finish.
- `align` **does not** open a pull request — that is Finish.
- `align` **does not** rewrite product decisions made upstream. If the diff diverges from a BDD Feature or OBC in a way that changes intent (not just detail), record the divergence in the Release Trail and surface it to Finish — do not silently re-specify the product here.
