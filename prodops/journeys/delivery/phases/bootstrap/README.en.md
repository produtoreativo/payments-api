# Bootstrap

Bootstrap prepares the environment for a ProdOps execution.

## Responsibility

Bootstrap installs dependencies, prepares local services, verifies configuration requirements and runs the smoke gate. It does not assess product readiness or start Git flow.

```text
Prepare tools → install dependencies → prepare local infrastructure
→ verify configuration → smoke gate → environment ready
```

## Boundaries

- Does not read or change production code.
- Does not read or execute behavior tests.
- Does not require, read or create OBCs, BDD Features, risks, Reliability Plans or Iteration Plan entries.
- Does not create, switch, synchronize or remove branches.
- Does not generate a context capsule.

The `/downstream` orchestrator owns the readiness gate. `/hack start` owns branch, base and other Git flow decisions.

## Input

- Repository setup scripts and package manifests.
- Example files containing variable names, never secret values.
- Required local infrastructure.
- The `smoke` gate defined in `prodops/exec/manifest.yaml`.

## Output

- Dependencies installed.
- Local services available.
- Configuration requirements identified without exposing secrets.
- Green smoke gate or an explicit environment blocker.

## Executable procedure

→ [`prodops/skills/bootstrap/SKILL.md`](../../../../skills/bootstrap/SKILL.md)

## Next phase

After Downstream readiness, `/hack start` establishes Git flow and starts Hack.
