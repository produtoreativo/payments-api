---
name: downstream
description: Execute ProdOps Downstream readiness and CI Sync, CI Async, or the complete delivery flow.
argument-hint: "[ci-sync|ci-async|full] [capability]"
---

Parse `$ARGUMENTS` as `<scope> <capability>`.

Supported scopes:

- `ci-sync`
- `ci-async`
- `full`

When scope is omitted, use `full`.

Use the Agent tool to delegate to the downstream-agent:

- subagent_type: `downstream-agent`
- run_in_background: false
- prompt: `Execute ProdOps Downstream. Scope: <scope>. Capability: <capability>.`

Wait for the agent result before reporting. If readiness is incomplete, report the missing gate and next owning action; do not continue to a delivery phase.
