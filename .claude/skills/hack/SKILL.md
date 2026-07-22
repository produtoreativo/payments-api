---
name: hack
description: Execute implementation work with TDD. Use when changing code, behavior, contracts, tests, or release artifacts as part of a ProdOps-backed task.
argument-hint: "[start|tdd|commit]"
---

If "$ARGUMENTS" matches a listed step (`start`, `tdd`, `commit`), spawn the corresponding worker agent:

- `start`  → subagent_type: "hack-start-agent"
- `tdd`    → subagent_type: "hack-tdd-agent"
- `commit` → subagent_type: "hack-commit-agent"

If "$ARGUMENTS" is empty or does not match a step, spawn the L2 orchestrator:
- subagent_type: "hack-agent"

In all cases:
- run_in_background: false
- prompt: include the capability context from $ARGUMENTS if provided
- Wait for the agent result before reporting to the user
- If the agent returns blocked, explain the blocker — do not attempt to fix it yourself
