# Finish → Validate

Read `prodops/skills/finish/steps/validate/SKILL.md` and execute the Validate step.

**Objetivo do step:** inspecionar a qualidade executando **todos os passos de análise estática de código** (format, lint, build), replicando localmente o que a pipeline remota (`.github/workflows/pr-gates.yml`) roda. A suíte de aceitação/integração é a **única exceção dinâmica** — e é ela que emite a cobertura em Cobertura XML (`api/coverage/cobertura-coverage.xml`); não há passo de coverage separado.

**Fonte dos comandos:** `prodops/exec/manifest.yaml` (`gates.lint`, `gates.build`, `gates.acceptance`, `gates.no_mocks`) — referencie, não reescreva.

**Critério de conclusão:** todos os gates estáticos passam localmente (lint exit 0, build compila) e a aceitação passa quando comportamento ou contratos mudaram. Cobertura é informativa, não bloqueia.

**Em caso de falha:** não corrija aqui. `validate` é inspeção, sem escrita em código — a correção de um lint/build/aceitação vermelha é mudança de produto e retorna ao `hack tdd` (Red → Green → Refactor). Só reexecute `validate` depois de fechar em verde.

**Fora do escopo:** não commita, não escreve/lê código, não escreve em artefatos, não faz push, não inspeciona a pipeline (`review`), não abre PR (`request`).

Execute apenas o step `validate`. Importe o contexto de `AGENTS.md` e `prodops/journeys/delivery/phases/finish/README.md` quando houver dúvida sobre fronteira.
