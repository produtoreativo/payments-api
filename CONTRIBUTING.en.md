# Contributing

→ [Versão em português](CONTRIBUTING.md)

This repository practices dogfooding: contributions to the framework follow the ProdOps
framework itself. Before contributing, read `AGENTS.md`, `prodops/README.md`, and the
contributor philosophy:
[`prodops/framework/contributor-philosophy.en.md`](prodops/framework/contributor-philosophy.en.md).

---

## Where each change belongs

Before any contribution, answer: is this a domain law (→ Framework), a reference
implementation choice (→ Runtime), or a per-AI-service optimization (→ Agents/Skills)?

The full philosophy — including the four design qualifiers, the community standards rule,
and the language-pair convention — is in
[`prodops/framework/contributor-philosophy.en.md`](prodops/framework/contributor-philosophy.en.md).

---

## The model

Every relevant framework change starts as an **Intent** from the **Team** Origin Stream —
the team's own needs to evolve process, tooling, and operational quality
(see [`prodops/framework/origin-streams.md`](prodops/framework/origin-streams.md)).

| Contribution type | Needs Intent? | Path |
|---|---|---|
| New capability, skill, doctor check, process change | Yes (`origin_stream: Team`) | Intent in `prodops/business-intents/` (template: `prodops/templates/business-intents/intent.en.md`) |
| Typo, broken link, cosmetic fix | No | Direct PR with Conventional Commit |

Small changes do not need an Intent — just open the PR.

---

## Contributor flow

1. **Fork** the repository.
2. **Atomic branch per subject**, named `type/slug` (e.g. `docs/fix-broken-links`, `feat/doctor-check-manifests`).
3. **Conventional Commits** on every commit:
   - Format: `<type>(<scope>): <summary>` (scope optional, summary ≤ 72 characters).
   - Accepted types: `feat` `fix` `docs` `test` `refactor` `perf` `build` `ci` `style` `chore` `revert`.
4. **Small, focused PR**: one subject = one PR. Do not mix refactoring with features or unrelated docs with code.
5. **No force-push on shared branches.** Rebase only on branches you own alone.

---

## Quality before the PR

| You touched… | Run |
|---|---|
| Code in `api/` | `cd api && npm run lint` and `npm run test` |
| Anything in `prodops/` | `./prodops/scripts/doctor.sh` |

Enable local commit validation hooks (once per clone):

```bash
git config core.hooksPath prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

Commit Workflow details: [`prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md`](prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md).

---

## Good first contributions

- **New doctor checks** (`prodops/scripts/doctor.sh`): structure, link, and manifest validations.
- **Consistency validations** between artifacts (glossary ↔ documents, canonical paths ↔ real tree).
- **Doc ↔ code drift fixes**: when documentation describes something the repository no longer does (or vice versa).
- **Intent examples by Origin Stream**: example Intents for Business, Enterprise, Team, and Technology in `prodops/business-intents/`.

---

## Agent compatibility

The framework works with multiple code agents. Each agent has its own entry points,
but canonical content lives in one place only:

| Agent | Entry points |
|---|---|
| Claude Code | `.claude/commands/` (slash commands) + skills in `prodops/skills/` |
| GitHub Copilot | `.github/prompts/` |
| Codex | `.codex/instructions.md` |

**Thin-wrapper rule:** agent commands and prompts point to the canonical `SKILL.md` in
`prodops/skills/<skill>/` — they never duplicate content.
When contributing a skill, edit the `SKILL.md`; wrappers must only reference it.

---

## Context rules

- **Never invent** missing OBCs, SLOs, risks, or acceptance criteria. If the context
  does not exist, record the gap instead of filling it by assumption.
- **Conflict with an existing rule:** preserve the existing rule and record the divergence
  in a Decision Trail
  (template: [`prodops/templates/assessment/decision-trail.en.md`](prodops/templates/assessment/decision-trail.en.md)).

---

## Questions

Open an issue describing the process problem or observable improvement you want to
achieve — the issue is the draft of your Intent.
