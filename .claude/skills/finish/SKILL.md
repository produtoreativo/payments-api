---
name: finish
description: Close technical work with quality gates. Use before considering a task complete, especially after implementation or artifact updates.
---

Use the Agent tool to delegate to the finish-agent:
- subagent_type: "finish-agent"
- run_in_background: false
- prompt: "Evaluate done criteria and quality gates for the current delivery task. Read prodops/skills/finish/SKILL.md first."

Wait for the agent result. If the agent finds a failure, report the diagnostic — do not attempt to fix code.
