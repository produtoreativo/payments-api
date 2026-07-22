# Sync → Align

Read `prodops/skills/sync/steps/align/SKILL.md` and execute the Align step.

**Objetivo do step:** garantir a **integridade dos artefatos ProdOps** — revisar o diff (`git diff main...HEAD`) e atualizar apenas os artefatos canônicos inconsistentes com o que foi implementado.

**Mapeamento canônico mudança → artefato:**

| Mudança no código | Artefato canônico |
|---|---|
| Comportamento novo ou alterado | BDD Feature em `prodops/artifacts/bdd/` |
| Evento de domínio adicionado, renomeado ou removido | `prodops/framework/journeys/assessment/event-storming/plan.json` |
| Novo módulo, rota, dependência externa ou tabela | `prodops/framework/journeys/assessment/architecture/overview.md` |
| OBC satisfeito ou alterado | `prodops/artifacts/obcs/<slug>.md` |

**Critério de conclusão:** nenhum artefato ProdOps canônico está inconsistente com o diff do branch; Release Trail recebeu entrada quando o alinhamento foi significativo; nenhuma decisão de produto foi reescrita.

**Fora do escopo:** não resolve conflitos git (`rebase`), não valida quality gates de código (Hack/Finish), não abre PR (Finish), não reescreve decisões de produto upstream — se o diff divergir de BDD/OBC em intenção, registre a divergência no Release Trail e sinalize ao Finish.

Execute apenas o step `align`. Importe o contexto de `AGENTS.md` e `prodops/framework/journeys/delivery/phases/sync/README.md` quando houver dúvida sobre fronteira.