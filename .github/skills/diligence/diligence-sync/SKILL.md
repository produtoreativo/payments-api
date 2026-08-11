---
name: diligence/diligence-sync
description: Event-driven cycle triggered by a product decision. Captures the decision as an OBC, attaches a Work Item, promotes it through the backlog hierarchy, and closes it when the OBC reaches Operational. Runs for a specific OBC.
---

# DILIGENCE SYNC

Ciclo reativo da Diligence. Executado quando uma decisão de produto (Assessment, Discovery, Operation signal) requer captura e rastreamento.

**Trigger:** decisão que aciona o ciclo — OBC identifier informado pelo caller.
**Fluxo:** Capture → Attach → Promote → Close
**Escopo:** um OBC por execução.

## Steps

| Step | Responsabilidade | Arquivo |
|---|---|---|
| **Capture** | Criar ou atualizar o OBC a partir da decisão. Estado canônico apenas no Markdown. | [steps/capture/SKILL.md](steps/capture/SKILL.md) |
| **Attach** | Verificar ou criar o Work Item no backlog externo referenciando o OBC. | [steps/attach/SKILL.md](steps/attach/SKILL.md) |
| **Promote** | Avançar o item pela hierarquia de backlogs verificando pré-requisitos em cada transição. | [steps/promote/SKILL.md](steps/promote/SKILL.md) |
| **Close** | Fechar o Work Item quando o OBC atinge estado Operational. | [steps/close/SKILL.md](steps/close/SKILL.md) |

Para executar um step isolado: `/diligence diligence-sync <step> <obc-id>`.

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- OBC existe em `prodops/artifacts/obcs/<obc-id>.md` com estado atualizado
- Work Item existe no backlog externo referenciando o OBC
- Work Item está na posição correta da hierarquia (ou bloqueio registrado)
- Se OBC em Operational: Work Item fechado

## Guardrails

- Parar em qualquer bloqueio — registrar o artefato ausente, a jornada responsável e a ação concreta antes de parar.
- Nunca pular uma transição de Promote sem registrar o pré-requisito ausente e seu artefato canônico.
- Nunca tomar decisões de produto — essas pertencem ao Assessment.
- Se infraestrutura ausente (label, campo) durante Attach/Promote: invocar `workspace-reconciliation` antes de continuar.

## References

→ [Diligence SKILL.md](../SKILL.md)
→ [Diligence journey README](../../../framework/journeys/diligence/README.md)
