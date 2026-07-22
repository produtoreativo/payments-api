# Sync → Rebase

Read `prodops/skills/sync/steps/rebase/SKILL.md` and execute the Rebase step.

**Objetivo do step:** garantir a **integridade do repositório git** — tornar o repositório pronto para merge incorporando o estado mais recente da base na feature branch, sem conflitos e sem enfraquecer testes.

**Critério de conclusão:** working tree limpa + base local atualizada com `origin` + feature branch incorpora a base mais recente + testes/lint passam sobre o histórico integrado + nenhuma assertion foi removida para resolver conflito.

**Fora do escopo:** não abre PR (Finish), não roda pipeline completa (Ship), não adiciona cobertura nem corrige code smell herdado (Hack/Yellow Bar), não alinha artefatos ProdOps (`align`). Se um conflito exigir alterar uma BDD Feature ou OBC committed, sinalize como bloqueador — não reescreva o artefato aqui.

Execute apenas o step `rebase`. Importe o contexto de `AGENTS.md` e `prodops/framework/journeys/delivery/phases/sync/README.md` quando houver dúvida sobre fronteira.