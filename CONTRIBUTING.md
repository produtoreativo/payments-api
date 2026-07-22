# Contribuindo

Este repositório pratica dogfooding: contribuições ao framework seguem o
próprio framework ProdOps. Antes de contribuir, leia `AGENTS.md` e
`prodops/README.md`.

---

## O modelo

Toda mudança relevante no framework nasce como uma **Intent** do Origin Stream
**Team** — necessidades do próprio time para evoluir processo, ferramentas e
qualidade operacional (ver [`prodops/framework/origin-streams.md`](prodops/framework/origin-streams.md)).

| Tipo de contribuição | Precisa de Intent? | Caminho |
|---|---|---|
| Nova capability, skill, check do doctor, mudança de processo | Sim (`origin_stream: Team`) | Intent em `prodops/business-intents/` (template: `prodops/templates/business-intents/intent.md`) |
| Typo, link quebrado, ajuste cosmético | Não | PR direto com Conventional Commit |

Mudanças pequenas dispensam Intent — basta abrir o PR.

---

## Fluxo do contribuidor

1. **Fork** do repositório.
2. **Branch atômica por assunto**, nomeada `type/slug` (ex.: `docs/fix-broken-links`, `feat/doctor-check-manifests`).
3. **Conventional Commits** em todos os commits:
   - Formato: `<type>(<scope>): <summary>` (scope opcional, summary ≤ 72 caracteres).
   - Tipos aceitos: `feat` `fix` `docs` `test` `refactor` `perf` `build` `ci` `style` `chore` `revert`.
4. **PR pequeno e focado**: um assunto = um PR. Não misture refatoração com feature nem docs com código não relacionado.
5. **Sem force-push em branches compartilhadas.** Rebase apenas em branches que só você usa.

---

## Qualidade antes do PR

| Você tocou em… | Rode |
|---|---|
| Código em `api/` | `cd api && npm run lint` e `npm run test` |
| Qualquer coisa em `prodops/` | `./prodops/scripts/doctor.sh` |

Ative os hooks locais de validação de commit (uma vez por clone):

```bash
git config core.hooksPath prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

Detalhes do Commit Workflow: [`prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md`](prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md).

---

## Boas primeiras contribuições

- **Novas checagens no doctor** (`prodops/scripts/doctor.sh`): verificações de estrutura, links e manifests.
- **Validações de consistência** entre artefatos (glossário ↔ documentos, canonical paths ↔ árvore real).
- **Correções de drift docs ↔ código**: quando a documentação descreve algo que o repositório não faz mais (ou vice-versa).
- **Exemplos de Intent por Origin Stream**: Intents de exemplo para Business, Enterprise, Team e Technology em `prodops/business-intents/`.

---

## Compatibilidade de agentes

O framework funciona com múltiplos agentes de código. Cada agente tem seus
entry points, mas o conteúdo canônico vive em um lugar só:

| Agente | Entry points |
|---|---|
| Claude Code | `.claude/commands/` (slash commands) + skills em `prodops/skills/` |
| GitHub Copilot | `.github/prompts/` |
| Codex | `.codex/instructions.md` |

**Regra do wrapper fino:** comandos e prompts de agentes apontam para o
`SKILL.md` canônico em `prodops/skills/<skill>/` — nunca duplicam conteúdo.
Ao contribuir com uma skill, edite o `SKILL.md`; os wrappers devem apenas
referenciá-lo.

---

## Regras de contexto

- **Nunca inventar** OBCs, SLOs, riscos ou critérios de aceite ausentes. Se o
  contexto não existe, registre a lacuna em vez de preenchê-la por suposição.
- **Conflito com regra existente:** preserve a regra existente e registre a
  divergência em um Decision Trail
  (template: [`prodops/templates/assessment/decision-trail.md`](prodops/templates/assessment/decision-trail.md)).

---

## Dúvidas

Abra uma issue descrevendo o problema de processo ou a melhoria observável que
você quer alcançar — a issue é o rascunho da sua Intent.
