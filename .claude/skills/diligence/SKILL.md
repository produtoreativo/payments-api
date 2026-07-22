---
name: diligence
description: Synchronize OBC state across backlogs and tools. Runs event-driven cycle (diligence-sync) or proactive drift-scan cycle (diligence-async). Never touches product code.
---

Parse `$ARGUMENTS` as `<scope> <obc-id>`.

Supported scopes:

- `diligence-sync`
- `diligence-async`
- `full`

When scope is omitted, use `diligence-sync` temporarily and report the default explicitly.

If the user passes `workspace-reconciliation` as scope: this is a capability invocation, not a cycle. Route to `prodops/skills/diligence/capabilities/workspace-reconciliation/SKILL.md` and execute the full Inspect → Reconcile → Verify sequence, identifying the caller as a direct user invocation.

Use the Agent tool to delegate to the diligence-agent:

- subagent_type: `diligence-agent`
- run_in_background: false
- prompt: `Execute ProdOps Diligence. Scope: <scope>. OBC: <obc-id>.`

Wait for the agent result before reporting.
