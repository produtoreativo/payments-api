# Prompt para Claude — EXP-015 Iteration 3
## Player Adapters

## Objetivo

Expor a mesma Tool e a mesma Skill canônica em Claude Code, Codex e GitHub Copilot, usando apenas adapters de descoberta/configuração.

## Fonte canônica

```text
prodops/skills/
```

## Materializações

### Claude

```text
.claude/skills/prodops-emit-event/SKILL.md
.claude/agents/delivery-agent.md        # opcional
CLAUDE.md                               # apenas routing global
```

### Codex

```text
.agents/skills/prodops-emit-event/SKILL.md
AGENTS.md                               # routing conciso
```

Opcional dentro da Skill:

```text
agents/openai.yaml
```

### Copilot

```text
.github/skills/prodops-emit-event/SKILL.md
.github/agents/delivery-agent.agent.md
.github/copilot-instructions.md
```

## Script de materialização

Crie:

```text
prodops/scripts/agents/materialize-skills.sh
```

Requisitos:

- determinístico;
- idempotente;
- `--check`;
- detecta drift;
- não sobrescreve divergência manual silenciosamente;
- inclui provenance header;
- garante corpo semântico equivalente.

## Teste

Em cada player:

1. confirme descoberta da Skill;
2. invoque explicitamente;
3. emita `Delivery.Bootstrap.Started`;
4. valide Runtime.

## Gate

Uma única fonte canônica, nenhum contrato privado por player, mesma Tool e resultados equivalentes.
