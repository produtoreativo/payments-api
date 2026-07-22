---
name: diligence/diligence-async
description: Proactive drift-scan cycle. Reads all active OBCs and Issues, identifies divergences, and repairs what can be automated. Runs across the entire active backlog, not for a specific OBC.
---

# DILIGENCE ASYNC

Ciclo proativo da Diligence. Executado periodicamente ou quando drift sistêmico é detectado — sem trigger de OBC específico.

**Trigger:** proativo, agendado, ou chamado após detecção de drift sistêmico.
**Fluxo:** Scan → Flag → Repair
**Escopo:** todos os OBCs e Issues ativos do repositório.

## Steps

| Step | Responsabilidade | Arquivo |
|---|---|---|
| **Scan** | Ler todos os OBCs ativos e Issues; comparar estado declarado com ferramentas externas; verificar conformidade de título e labels. Produz lista de divergências. | [steps/scan/SKILL.md](steps/scan/SKILL.md) |
| **Flag** | Classificar divergências com severidade e ação corretora. Categoriza o que é reparável vs. o que requer decisão de produto. | [steps/flag/SKILL.md](steps/flag/SKILL.md) |
| **Repair** | Executar correções dos itens reparáveis; escalar itens bloqueados. Se Workspace Drift detectado: invocar `workspace-reconciliation`. | [steps/repair/SKILL.md](steps/repair/SKILL.md) |

Para executar um step isolado: `/diligence diligence-async <step>`.

## Post-conditions

Concluído quando **todos** os itens abaixo são verdadeiros:

- Todos os OBCs ativos e Issues verificados contra estado real das ferramentas
- Divergências classificadas por severidade
- Itens reparáveis corrigidos ou com Issue de rastreamento aberto
- Itens escalados documentados com OBC, gap e jornada responsável

## Guardrails

- Parar antes de Repair quando uma divergência requer decisão de produto — escalar com o OBC afetado, o gap e a jornada responsável.
- Nunca tomar decisões de produto — surfacer blockers ao usuário.
- Se Workspace Drift detectado durante Scan/Repair: invocar `workspace-reconciliation` para reconciliar infraestrutura antes de continuar.
- Nunca inventar OBCs, BDD Features ou riscos — apenas sincronizar o que já existe.

## References

→ [Diligence SKILL.md](../SKILL.md)
→ [Diligence journey README](../../../framework/journeys/diligence/README.md)
