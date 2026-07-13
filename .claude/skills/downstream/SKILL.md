---
name: downstream
description: Execute governed ProdOps delivery. Use when implementing approved backlog items, following the Reliability Plan, applying TDD, updating OBCs, running quality gates, validating observability, shipping, or promoting release work.
---

Use the Agent tool to delegate to the downstream-agent:
- subagent_type: "downstream-agent"
- run_in_background: false
- prompt: "Execute the full ProdOps CI Sync delivery flow. Capability: $ARGUMENTS"

Wait for the agent result before reporting to the user.
