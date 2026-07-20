# Modo Upstream

Upstream é o **modo de exploração** do Framework ProdOps.

## Definição canônica

Upstream representa um modo de exploração. Seu objetivo é reduzir incertezas antes de assumir qualquer compromisso de entrega. O Upstream não representa uma promessa — representa um espaço para aprender. Todo trabalho realizado no Upstream é considerado experimental.

## Propósito

Produzir conhecimento. Não produzir software comprometido.

## Características do modo

No Upstream:

- não existem gates obrigatórios
- não existe obrigação de concluir artefatos
- não existe obrigação de produzir um OBC Committed
- não existe obrigação de seguir todas as Skills
- o engenheiro decide quais Skills utilizar
- vibecoding é permitido
- experimentação é incentivada
- falhar faz parte do processo

O objetivo é aprender o mais rápido possível.

Um experimento Upstream pode produzir código de qualidade de produção, mas esse código é considerado exploratório até que a capability seja promovida para Downstream.

## OBC no Upstream

Quando uma Business Intent entra no Business Intent Backlog, um OBC é criado como Draft.

Durante o Upstream:

- o OBC permanece em Draft
- pode ser atualizado continuamente
- pode permanecer incompleto
- não bloqueia o avanço dos experimentos

O OBC funciona como memória do aprendizado — não como mecanismo de validação.

## Quando usar o modo Upstream

- Hipótese a validar, incerteza alta
- Explorar uma capability nova
- Prototipar integração com provedor
- Validar fluxo de negócio antes de comprometer
- Explorar abordagem técnica antes de decidir

## Como executar no modo Upstream

→ [Jornada Discovery](../journeys/discovery/README.md)

A jornada Discovery documenta o workflow completo de exploração, experimentos, revisão de Decision Package e processo de promoção para Downstream.

## Encerramento do Upstream

Ao final do Upstream podem ocorrer quatro resultados:

1. **Descartar** a Business Intent — aprendizado suficiente, mas não vale a pena avançar.
2. **Arquivar** para uso futuro — aprendizado registrado, decisão adiada.
3. **Retornar** ao Business Intent Backlog — aguardar decisão de negócio ou dependência externa.
4. **Promover** para Downstream — decisão explícita do Product Owner, com Decision Package completo.

A promoção para Downstream deve ser uma decisão explícita. Não existe transição automática.

## Resultado esperado

Ao final de um ciclo Upstream, deve existir:

- Hipótese respondida com evidência
- Decision Package completo
- Recomendação clara (promover, requer outro experimento, aguardar, descartar)
- Artefatos ProdOps atualizados

## Sandbox Deploy (Upstream)

Um experimento pode ser implantado em AWS real sem passar pelo rigor do Downstream.

Objetivo: validar comportamento contra um provedor real (ex: Asaas sandbox) quando o ambiente local não é suficiente.

**Características:**

- Ativado manualmente via `workflow_dispatch` — nunca em push
- Stack efêmera: `payments-api-experiment` + `payments-api-dynamo-experiment`
- Recursos AWS prefixados `experiment-*` — isolados de staging e production
- Role IAM dedicada `payments-api-github-experiment` — escopo restrito a `experiment-*`
- Sem gate de aprovação, sem Release Trail, sem OBC committed
- **Obrigatório:** stack destruída ao final do experimento via `action=teardown`

→ [Step: deploy-to-sandbox](../skills/upstream/steps/deploy-to-sandbox/SKILL.md)
→ [Workflow: experiment-deploy.yml](../../.github/workflows/experiment-deploy.yml)
→ [Role IAM: iam-experiment-role.yaml](../../api/infra/iam-experiment-role.yaml)

## Promoção para Downstream

Uma capability promovida do Upstream para Downstream deve ter:

1. BDD Feature movida de `prodops/journeys/discovery/experiments/<NNN-slug>/features/` para `prodops/artifacts/business/bdd/`
2. OBC movido de `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` para `prodops/artifacts/business/obcs/`
3. Entrada no Iteration Plan em `prodops/artifacts/governance/plans/iteration-plan.md`
4. Reliability Plan atualizado em `prodops/journeys/assessment/reliability-plans/`

→ [Processo completo de promoção](../journeys/discovery/README.md#processo-de-promoção-para-downstream)
