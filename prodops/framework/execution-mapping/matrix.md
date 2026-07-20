# Matriz de Execution Mapping

Mapeamento completo de todos os Artefatos do Knowledge Space contra operações permitidas, recursos GitHub, jornadas, modos de execução, evidências esperadas e responsáveis.

**Leitura:** cada linha é uma operação sobre um artefato. A coluna "Recursos GitHub" indica o que a operação PODE gerar — não o que obrigatoriamente deve gerar.

→ [Execution Mapping](README.md)
→ [Schema de Work Item](work-item-schema.md)

---

## Legenda

| Símbolo | Significado |
|---|---|
| Issue | GitHub Issue |
| PR | Pull Request |
| Disc | GitHub Discussion |
| Rel | GitHub Release |
| WF | GitHub Workflow (Actions) |
| Mile | GitHub Milestone |

**Responsáveis:**
- PO — Product Owner
- PCE — Product Context Engineer
- PRE — Product Reliability Engineer
- SE — Software Engineer
- PE — Platform Engineer
- Arch — Architecture
- TL — Tech Lead
- PPM — Portfolio PM

---

## Business Signal

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Capture` | Issue | Discovery, Diligence | N/A | Signal documentado na Tracking List | PCE, PO |
| `Review` | Issue | Discovery | N/A | Notas de avaliação registradas no Signal | PCE, PO |
| `Promote → Business Intent` | Issue | Discovery | N/A | Business Intent criada; Signal referenciado | PO, PCE |
| `Discard` | Issue | Discovery, Diligence | N/A | Justificativa de descarte no Signal | PO |

**Nunca:** PR (Business Signal não é arquivo commitável pelo agente), Release, Milestone

---

## Business Intent

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | Issue | Discovery | N/A | Intent document criado em `artifacts/business/intents/` | PO, PCE |
| `Refine` | Issue, PR | Discovery | Upstream | OBC Draft atualizado; hipóteses registradas | PCE, TL |
| `Explore` | Issue, Disc | Discovery | Upstream | Resultados de exploração no OBC | PCE, SE |
| `Review` | Issue, Disc | Discovery, Assessment | Upstream → Down | Checklist de revisão; decisão registrada | PO, TL |
| `Approve → Committed` | Issue | Assessment | Downstream | OBC em estado Committed | PO, TL |
| `Prioritize` | Project Item | Discovery, Delivery | Both | Prioridade registrada no Project | PO |
| `Split → Local OBCs` | Issue | Discovery | N/A | N Local OBC documents criados | PPM, TLs |
| `Promote → Product Backlog` | Issue | Discovery | N/A | Intent roteada ao Product Backlog | PPM, PO |
| `Archive` | PR | Operation | N/A | Nota de encerramento na Intent | PO |

**Nunca:** Release (a Intent não é uma entrega, seus artefatos são)

---

## Global OBC

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | PR | Discovery | Upstream | OBC Draft no repositório de portfólio | PPM, TL |
| `Refine` | PR, Issue | Discovery | Upstream | OBC evoluído com novas hipóteses e dados | PPM, TL |
| `Review` | Issue, Disc | Discovery, Assessment | Upstream | Comentários e decisões registrados | PPM, TLs |
| `Approve` | Issue | Assessment | Downstream | OBC em estado Committed | PPM |
| `Update` | PR | Delivery, Operation | N/A | OBC atualizado com evidências de entrega/operação | PPM, TL |
| `Split` | Issue | Discovery | N/A | N Local OBCs criados; tabela de rastreabilidade atualizada | PPM, TLs |
| `Archive` | PR | Operation | N/A | Nota de encerramento; estado Archived | PPM |

**Nunca:** é uma Issue; WF automatizado

---

## Local OBC

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | PR | Discovery | Upstream | `artifacts/business/obcs/<slug>.md` em estado Draft | PM, TL |
| `Refine` | PR, Issue | Discovery, Assessment | Upstream | OBC em estado Refining; critérios emergindo | PM, TL, SE |
| `Review` (Assessment) | Issue, Disc | Assessment | Upstream → Down | Checklist de Assessment preenchido | PM, TL |
| `Approve` (→ Committed) | Issue | Assessment | Downstream | OBC em estado Committed; mínimos validados | PM, TL |
| `Implement` | PR | Delivery | Downstream | Código; BDD executado; PR aprovado | SE |
| `Update` | PR | Delivery, Operation | Both | OBC atualizado com evidência real | SE, PM |
| `Validate` | WF, Issue | Delivery | Downstream | CI pass; acceptance tests green | SE, PRE |
| `Archive` | PR | Operation | N/A | Estado Archived; nota de encerramento | PM |

**Nunca:** é uma Issue; Release (a Release referencia a entrega, não o OBC diretamente)

---

## BDD Feature

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | PR | Discovery, Delivery | Upstream | `.feature` file em `artifacts/business/bdd/` | PCE, SE |
| `Refine` | PR | Discovery | Upstream | `.feature` atualizado com novos cenários | PCE, SE |
| `Review` | PR review | Assessment, Delivery | Downstream | PR aprovado; comentários resolvidos | PM, TL |
| `Validate` | WF | Delivery | Downstream | CI pass; todos os cenários verdes | SE |
| `Update` | PR | Delivery, Operation | Downstream | `.feature` atualizado com cenário de edge case ou regressão | SE, PCE |
| `Deprecate` | PR | Operation | N/A | Cenário marcado como deprecated no arquivo | SE, PCE |

**Nunca:** Issue autônoma; Discussion; Release

---

## Architecture

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Register` | PR | Delivery | Both | `artifacts/product/architecture/overview.md` atualizado | SE, Arch |
| `Review` | Issue, Disc | Delivery, Assessment | Both | Comentários e decisões registrados | Arch, TL |
| `Update` | PR | Delivery | Both | Diagrama atualizado; novo componente/rota/tabela registrado | SE, Arch |
| `Deprecate` | PR | Operation | N/A | Componente marcado como deprecated no diagrama | Arch |

**Regra de guardião (de AGENTS.md):** PR que adiciona módulo NestJS, rota, dependência externa, tabela DynamoDB, tópico de evento ou fila SQS DEVE incluir atualização do overview.md.

**Nunca:** Issue autônoma sem PR correspondente; Release

---

## Iteration Plan

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | Mile, PR | Delivery | Downstream | `artifacts/governance/plans/iteration-plan.md` criado | PO |
| `Update` | PR | Delivery | Downstream | Plano atualizado com progresso, decisões, bloqueios | PO, SE |
| `Close` | Rel, PR | Delivery | Downstream | Entrada em Release Trail; estado dos itens registrado | PO, SE |

**Nunca:** Discussion; Issue autônoma para o plano em si (Issues são para os itens dentro do plano)

---

## Reliability Plan

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | PR, Issue | Assessment | Downstream | Documento do Reliability Plan criado | PRE, TL |
| `Review` | Issue, Disc | Assessment | Downstream | Checklist de revisão; decisão sobre gate | PRE, PM, TL |
| `Approve` | Issue | Assessment | Downstream | Gate de Reliability aprovado | PRE, PM |
| `Update` | PR | Delivery, Operation | Downstream | Plano atualizado com resultados de SLOs e incidentes | PRE |
| `Validate` | WF, Issue | Delivery | Downstream | SLOs verificados; thresholds dentro do esperado | PRE |

**Gate condicional:** Reliability Plan obrigatório quando há movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração de persistência/segurança.

---

## Release Trail

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | Rel, PR | Delivery | Downstream | Entrada em `artifacts/governance/trails/release-trail.md` | SE, PO |
| `Update` | PR | Operation | N/A | Trail atualizado com postmortem, incidente ou revisão | SE, PRE |

**Nunca:** Issue autônoma; Discussion; Milestone

---

## Experiment

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Define` | Issue, Disc | Discovery | Upstream | Plano do experimento em `journeys/discovery/experiments/<slug>/` | PCE, SE |
| `Execute` | Branch, PR | Discovery | Upstream | Resultados parciais no diretório do experimento | SE, PCE |
| `Evaluate` | Issue, Disc | Discovery | Upstream | Avaliação documentada; hipótese confirmada ou refutada | PCE, PO |
| `Promote` | PR | Discovery | Upstream → Down | Artefato graduado para `prodops/artifacts/`; experimento arquivado | PCE, TL |
| `Discard` | Issue | Discovery | Upstream | Justificativa de descarte; experimento marcado como discarded | PCE |

---

## Evidence

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Capture` | PR (dentro de atualização de OBC ou Trail) | Operation, Delivery | Both | Evidência registrada no artefato de origem | SE, PRE |
| `Attach` | PR | Operation, Diligence | Both | Link de evidência adicionado ao OBC ou Trail | SE |
| `Review` | Issue | Diligence, Operation | Both | Revisão de qualidade da evidência registrada | PRE, PM |

**Nota:** Evidence não existe como artefato autônomo — sempre pertence a um OBC, Trail ou Experiment. O Work Item referencia o artefato que contém a evidência.

---

## Context Capsule

**Classificação:** Execution-generated — não é um artefato do Knowledge Space.

O Context Capsule (`prodops/exec/cards/<slug>/context.md`) é gerado automaticamente pelo Downstream readiness a partir dos artefatos de conhecimento existentes (OBC, BDD, Risks, Reliability Plan). É um documento de contexto de execução — efêmero e derivado.

**Não tem Work Items próprios.** Work Items que afetam o contexto de uma entrega referenciam os artefatos de origem (OBC, BDD, etc.), não o Context Capsule.

**Gerado por:** skill `/downstream` durante o Readiness gate.
**Localização:** `prodops/exec/cards/<card-slug>/context.md`
**Sobrevive a:** apenas a entrega corrente — não é histórico de longo prazo.

---

## Risk Register

| Operação | Recursos GitHub | Jornadas | Modo | Evidência esperada | Responsáveis |
|---|---|---|---|---|---|
| `Create` | PR, Issue | Assessment | Downstream | `journeys/assessment/risks.md` atualizado | PRE, TL |
| `Update` | PR | Assessment, Delivery | Downstream | Risco revisado (probabilidade, impacto, mitigação) | PRE |
| `Review` | Issue | Assessment | Downstream | Decisão sobre aceitar, mitigar ou escalar o risco | PRE, PM, TL |
| `Close` | PR | Operation | N/A | Risco resolvido; nota de encerramento | PRE |

---

## Resumo por recurso GitHub

| Recurso | Artefatos que pode referenciar |
|---|---|
| **Issue** | Business Signal, Business Intent, Local OBC, Global OBC, Experiment, Risk Register, Reliability Plan, Evidence |
| **Pull Request** | Todos os artefatos que existem como arquivos Markdown |
| **Discussion** | Business Intent, Global OBC, Local OBC, Architecture, Experiment |
| **Release** | Iteration Plan, Release Trail |
| **Workflow** | BDD Feature, Local OBC, Reliability Plan |
| **Milestone** | Iteration Plan |
| **Project Item** | Business Intent (priorização) |

---

## Operações nunca permitidas (para qualquer artefato)

| Operação proibida | Motivo |
|---|---|
| Artefato **é** um GitHub Issue | Issue representa trabalho; artefato é o conhecimento |
| Estado do GitHub Issue sincroniza estado do artefato | Estados são independentes |
| Fechar Issue muda estado do artefato | A Issue fecha porque o trabalho terminou; o estado do artefato muda quando seus critérios são satisfeitos |
| Criar Issue sem referenciar artefato | Issue sem artefato referenciado é trabalho sem contexto |
| Artefato como `contains` em GitHub Project | Projects contêm Work Items, não artefatos |

---

## Referências

→ [Execution Mapping](README.md)
→ [Schema de Work Item](work-item-schema.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.md)
→ [OBC](../obc.md)
→ [Artifact Governance](../artifact-governance.md)
