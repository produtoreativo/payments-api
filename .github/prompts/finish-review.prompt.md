# Finish → Review

Read `prodops/skills/finish/steps/review/SKILL.md` and execute the Review step.

**Objetivo do step:** garantir que as **regras para um PR automático estão válidas** — que as condições para auto aprovação segura estão presentes no repositório — **sem executar a pipeline**. É um passo de inspeção de configuração (via `gh` e leitura de config), não de execução.

**Condições a confirmar (cada ausente é bloqueador):**

- [ ] A pipeline expõe `lint`, `acceptance` e `build` como status checks.
- [ ] Branch protection na branch de destino **exige** esses checks passando antes do merge.
- [ ] Nenhum reviewer obrigatório bloqueia o merge de um PR com todos os checks verdes (ou um bot auto-aprova).

**Critério de conclusão:** todas as condições confirmadas, ou o bloqueador de branch protection registrado no Finish. Ativar auto-merge sem branch protection mergearia código sem gate — por isso `review` é pré-condição do push e do `request`.

**Fora do escopo:** não executa pipelines, não commita, não escreve/lê código de produto, não faz push, não abre PR (`request`). Se as condições não puderem ser lidas (permissão) ou não estiverem configuradas, trate como bloqueador explícito, não como "provavelmente ok".

Execute apenas o step `review`. Importe o contexto de `AGENTS.md`, `prodops/framework/journeys/delivery/phases/finish/quality-gates.md` e `.github/workflows/pr-gates.yml` quando houver dúvida sobre fronteira.
