# Templates — ProdOps

Templates reutilizáveis organizados por área de trabalho.

Copie o template para o local canônico indicado antes de preencher. Nunca preencha diretamente o template.

---

## Discovery (Upstream)

| Template | Uso | Localização canônica |
|---|---|---|
| [experiment.md](discovery/experiment.md) | Novo experimento Upstream | `prodops/journeys/discovery/experiments/NNN-slug/experiment.md` |
| [trail.md](discovery/trail.md) | Trail cronológico de um experimento | `prodops/journeys/discovery/experiments/NNN-slug/upstream-trail.md` |
| [learning.md](discovery/learning.md) | Aprendizado consolidado de experimento | nova entrada em `prodops/journeys/discovery/learnings.md` |

Crie um diretório `evidence/` ao lado do experimento quando precisar de outputs de comandos, payloads ou respostas do provedor.

---

## Delivery (Downstream)

| Template | Uso | Localização canônica |
|---|---|---|
| [delivery/release-entry.md](delivery/release-entry.md) | Entrada no Release Trail | acrescentar no trail da sessão ativa em `prodops/artifacts/governance/trails/sessions/` |
| [delivery/pull-request-checklist.md](delivery/pull-request-checklist.md) | Checklist de PR antes do Finish | usado na revisão do Pull Request |

---

## Engineering

| Template | Uso | Localização canônica |
|---|---|---|
| [engineering/definition-of-done.md](engineering/definition-of-done.md) | Definition of Done | referência no Finish phase |
| [engineering/test-plan.md](engineering/test-plan.md) | Plano de testes para uma capability | usado durante o Hack |

---

## Assessment

| Template | Uso | Localização canônica |
|---|---|---|
| [assessment/decision-trail.md](assessment/decision-trail.md) | Registro de decisão sob incerteza | `prodops/journeys/assessment/` ou inline no trail |
| [assessment/reliability-checklist.md](assessment/reliability-checklist.md) | Checklist de confiabilidade antes do Ship | usado no Finish/Ship |

---

## Intents

| Template | Uso | Localização canônica |
|---|---|---|
| [business-intents/intent.md](business-intents/intent.md) | Nova Intent | `prodops/artifacts/business/intents/<slug>.md` |

---

## Operation

| Template | Uso | Localização canônica |
|---|---|---|
| [operation/runbook.md](operation/runbook.md) | Runbook operacional | `prodops/journeys/operation/runbooks.md` (nova seção) |
| [operation/postmortem.md](operation/postmortem.md) | Postmortem de incidente | `prodops/journeys/operation/postmortems.md` (nova entrada) |

---

## Regras

- Nunca preencher templates no lugar — copie para o destino canônico.
- Nunca criar artefatos de produto ou de release aqui — templates são estrutura, não conteúdo.
- Ao evoluir um template, verificar se instâncias existentes nos artefatos precisam ser migradas.
