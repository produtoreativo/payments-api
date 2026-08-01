# Templates — ProdOps

Templates reutilizáveis organizados por área de trabalho.

Copie o template para o local canônico indicado antes de preencher. Nunca preencha diretamente o template.

---

## Definição, template e instância

| Conceito | O que é | Onde fica |
|---|---|---|
| **Definição** | Estrutura e semântica do artefato | `prodops/framework/` |
| **Template** | Estrutura vazia pronta para copiar | `prodops/templates/` |
| **Instância** | Template preenchido com dados reais | `prodops/artifacts/` |

Instâncias preenchidas pertencem a `prodops/artifacts/`, nunca a `prodops/templates/`.

---

## Discovery (Upstream)

| Template | Uso | Localização canônica |
|---|---|---|
| [experiment.md](discovery/experiment.md) | Novo experimento Upstream | `prodops/artifacts/experiments/NNN-slug/experiment.md` |
| [trail.md](discovery/trail.md) | Trail cronológico de um experimento | `prodops/artifacts/experiments/NNN-slug/upstream-trail.md` |
| [learning.md](discovery/learning.md) | Aprendizado consolidado de experimento | nova entrada em `prodops/framework/journeys/discovery/learnings.md` |

Crie um diretório `evidence/` ao lado do experimento quando precisar de outputs de comandos, payloads ou respostas do provedor.

---

## Delivery (Downstream)

| Template | Uso | Localização canônica |
|---|---|---|
| [delivery/context-capsule.md](delivery/context-capsule.md) | Context Capsule gerada pelo Downstream readiness | `prodops/artifacts/iterations/<version>/cards/<slug>/context.md` |
| [delivery/release-entry.md](delivery/release-entry.md) | Entrada no Release Trail | acrescentar no trail da sessão ativa em `prodops/artifacts/trails/sessions/` |
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
| [assessment/decision-trail.md](assessment/decision-trail.md) | Registro de decisão sob incerteza | `prodops/framework/journeys/assessment/` ou inline no trail |
| [assessment/reliability-checklist.md](assessment/reliability-checklist.md) | Checklist de confiabilidade antes do Ship | usado no Finish/Ship |

---

## Intents

| Template | Uso | Localização canônica |
|---|---|---|
| [business-intents/intent.md](business-intents/intent.md) | Nova Intent | `prodops/artifacts/business-intents/<slug>.md` |

---

## OBCs

| Template | Uso | Localização canônica |
|---|---|---|
| [obcs/local-obc.md](obcs/local-obc.md) | Local OBC — contrato de implementação de um produto | `prodops/artifacts/obcs/<slug>.md` |
| [obcs/global-obc.md](obcs/global-obc.md) | Global OBC — contrato de plataforma (uso no repositório de portfólio) | repositório de portfólio da plataforma |
| [obcs/obc.md](obcs/obc.md) | Roteador: qual template OBC usar | referência histórica |

---

## Operation

| Template | Uso | Localização canônica |
|---|---|---|
| [operation/runbook.md](operation/runbook.md) | Runbook operacional | `prodops/framework/journeys/operation/runbooks.md` (nova seção) |
| [operation/postmortem.md](operation/postmortem.md) | Postmortem de incidente | `prodops/framework/journeys/operation/postmortems.md` (nova entrada) |

---

## Adaptações locais do produto (`templates/local/`)

Quando o produto precisar adaptar um template canônico (ex.: checklist com gates específicos, OBC com campos extras), a adaptação vai em `prodops/templates/local/`.

Regras:
- `templates/local/` pertence ao produto, não ao Framework canônico.
- `templates/local/` é protegido de sync por `.prodopsignore`.
- Uma Skill canônica não pode depender de um template local por nome.
- Uma Product Skill pode consumir um template local.
- Instâncias preenchidas nunca ficam em `templates/local/` — vão para `prodops/artifacts/`.

Este produto **não possui templates locais** no momento. O diretório `templates/local/` será criado somente quando houver conteúdo real.

---

## Direção de dependência

```
Framework Skill  →  pode usar template canônico
Framework Skill  →  não requer template local específico
Product Skill    →  pode usar template canônico ou local
Template (vazio) →  copiado e preenchido → vira Artefato em prodops/artifacts/
```

---

## Regras

- Nunca preencher templates no lugar — copie para o destino canônico.
- Nunca criar artefatos de produto ou de release aqui — templates são estrutura, não conteúdo.
- Ao evoluir um template, verificar se instâncias existentes nos artefatos precisam ser migradas.
- Templates canônicos não dependem de adaptações locais.
- Relação com Skills: ver `prodops/skills/README.md`.
- Relação com Artifacts: ver `prodops/artifacts/README.md`.
