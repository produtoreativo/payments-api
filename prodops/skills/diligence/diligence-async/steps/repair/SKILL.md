---
name: diligence/repair
description: Execute corrections identified by Flag — update OBCs, create missing Work Items, close orphaned ones. Never touches product code or creates implementation PRs.
---

# DILIGENCE ASYNC → REPAIR

Execute only the Repair step of the Diligence Async flow.

**Responsabilidade:** executar as correções identificadas pelo Flag, restaurando a consistência entre artefatos canônicos e ferramentas externas. Repair nunca modifica código de produto e nunca cria Pull Requests de implementação.

## Ação

### 1. Ler a lista de itens pendentes do Flag

Obter os itens classificados como reparáveis pela Diligence. Ignorar itens com status `BLOQUEADO` — esses pertencem a outras jornadas.

### 2. Executar reparos em ordem de severidade

Para cada item, aplicar a ação corretora correspondente:

**Work Item ausente:** executar step Attach para o OBC afetado.

```
→ prodops/skills/diligence/steps/attach/SKILL.md
```

**Work Item aberto com OBC Operational:** executar step Close para o OBC afetado.

```
→ prodops/skills/diligence/steps/close/SKILL.md
```

**OBC absent do Iteration Plan com pré-requisitos satisfeitos:** executar step Promote para o OBC afetado.

```
→ prodops/skills/diligence/steps/promote/SKILL.md
```

**Artefato de gestão desatualizado (Iteration Plan, Roadmap, Product Backlog):** atualizar o artefato diretamente, registrando a data e a decisão que originou a mudança.

**OBC sem estado canônico correto:** executar step Capture para o OBC afetado.

```
→ prodops/skills/diligence/steps/capture/SKILL.md
```

### 3. Parar em itens que exigem decisão de produto

Quando um reparo não pode ser executado sem uma decisão de produto:
- Registrar o bloqueio com o OBC afetado, o gap e a jornada responsável
- Não inventar a decisão
- Escalar para Assessment ou Discovery conforme o tipo de gap

### 4. Commit por grupo de reparos

```bash
git add prodops/artifacts/business/obcs/
git add prodops/artifacts/governance/plans/
git commit -m "docs(diligence): repair divergences from async scan"
```

### 5. Registrar resultado

Para cada item reparado: OBC afetado, ação executada, data.
Para cada item não reparado: motivo e jornada responsável.

## Post-conditions

Concluído quando:

- Todos os itens reparáveis foram corrigidos ou tiveram o bloqueio explicitamente registrado
- Nenhum código de produto foi modificado
- Nenhum Pull Request de implementação foi criado

## Guardrails

- Nunca modificar código de produto — escopo é exclusivamente artefatos ProdOps e backlogs.
- Nunca criar Pull Requests de implementação.
- Parar e escalar itens que exigem decisão de produto antes de reparar.
- Não silenciar falhas de reparo — registrar explicitamente o que não pôde ser corrigido e por quê.

## Out of scope

- `repair` **não** implementa funcionalidades — nunca.
- `repair` **não** resolve divergências que exigem decisão de Assessment ou Discovery.
- `repair` **não** substitui a execução de Downstream readiness para itens bloqueados por artefatos ausentes de Delivery.
