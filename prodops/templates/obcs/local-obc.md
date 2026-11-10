# OBC - <Nome da Capability>

<!-- Renomeie este arquivo para o slug da capability: ex. split-payment-api.md -->
<!-- Localização: enquanto Draft/Refining dentro de um experimento Upstream, mantenha em
     prodops/artifacts/experiments/<NNN-slug>/obcs/<slug>.md.
     Mova para prodops/artifacts/obcs/<slug>.md somente quando o OBC estiver Committed (move-to-downstream). -->
<!-- Definição completa do formato: prodops/framework/obc.md -->
<!-- Owner: Product Manager + Tech Lead do produto -->
<!-- Seções marcadas "(obrigatória para Committed)" devem estar preenchidas antes de o OBC ser Committed.
     Seções opcionais podem ser removidas se não se aplicarem — nunca deixe placeholders `<...>` num OBC Committed. -->

## Metadados

<!-- Obrigatória para Committed. DS-ID e Iteração são preenchidos quando o item entra no Iteration Plan. -->

| Campo | Valor |
|---|---|
| Owner | <Product Manager> + <Tech Lead> |
| DS-ID | <DS-NN> *(preencher ao entrar no Iteration Plan)* |
| Iteração | <vX.Y.Z> *(preencher ao entrar no Iteration Plan)* |
| Última atualização | <AAAA-MM-DD> |

## Status

<!-- Declare exatamente UM estado, sem texto adicional na linha do estado:
     Draft | Refining | Committed | In Delivery | Operational | Archived
     Onde o item é rastreado (ex.: Status `Entrou` em prodops/artifacts/plans/iteration-plan.md)
     vai na linha "Rastreado em". Não escreva "Downstream. Status ..." no lugar do estado. -->

**Estado:** Draft
**Rastreado em:** <Product Tracking List | Icebox | Iteration Plan v0.0.0>

## Origem

<!-- Obrigatória para Committed. Rastreabilidade ascendente exigida pelo framework.
     Fluxo local: preencha Business Signal, Business Intent e Product Tracking Item.
     Fluxo global (Intent vinda do Portfólio): preencha também o Global OBC de origem. -->

| Elo | Referência |
|---|---|
| Business Signal | `prodops/artifacts/business-signals/<BS-ID>.md` |
| Business Intent | `prodops/artifacts/business-intents/<PI-ID>.md` |
| Product Tracking Item | <link para o item na tracking list> |
| Global OBC *(só no fluxo global)* | <link para o Global OBC no repositório de portfólio> |

## Business Outcome

<!-- Descreva em uma ou duas partes:
     1. O que o produto entrega e quais garantias oferece (perspectiva técnica de negócio).
     2. Opcional — "### Em linguagem executiva": analogia acessível para stakeholders não-técnicos.
     Foque no RESULTADO observável, não na implementação. -->

<Descreva o resultado de negócio que esta capability entrega, as garantias que oferece e os problemas que resolve.>

### Em linguagem executiva

<!-- Opcional. Use quando o comportamento da capability não for intuitivo para stakeholders não-técnicos.
     Escreva como uma analogia do mundo real, sem jargão técnico. -->

<Analogia simples que explica o comportamento para uma audiência executiva.>

## Escopo

<!-- Obrigatória para Committed. Delimita o que esta capability cobre e o que NÃO cobre,
     para evitar que o escopo cresça sem decisão explícita. -->

**Dentro do escopo**

- <Comportamento coberto por esta capability.>

**Fora de escopo**

- <Comportamento explicitamente não coberto, com a capability ou iteração que o trata, se houver.>

## Regras de Negócio

<!-- Obrigatória para Committed. Regras do negócio que a capability aplica (não confundir com Reliability Rules,
     que são invariantes técnicos de confiabilidade). Cada regra é prescritiva e testável. -->

- <Regra de negócio: condição → comportamento esperado.>

## Critérios de Aceite

<!-- Obrigatória para Committed. Condições verificáveis para considerar a capability entregue.
     Cada critério deve ter ao menos um cenário no BDD Feature (prodops/artifacts/bdd/<slug>.feature). -->

- [ ] <Critério verificável.>

## Contexto Enterprise

<!-- Obrigatória para Committed. Restrições e padrões organizacionais que se aplicam. -->

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | <Value Stream ou Service a que pertence> — Service Deck: `prodops/artifacts/product/context/service-decks/<slug>.md` |
| Stakeholders | <Quem decide ou é impactado, e a decisão que toma.> |
| Compliance | <PCI, LGPD, auditoria ou "não se aplica".> |

## Observable Events

<!-- Obrigatória para Committed. Liste todos os eventos observáveis que esta capability emite.
     Inclua eventos de sucesso, falha, idempotência e casos especiais.

     REGRA DE NOMENCLATURA: eventos de negócio seguem `payments.<agregado>.<fato>` (minúsculas, snake_case,
     em inglês) e o nome na coluna "Event" deve ser IDÊNTICO ao emitido no código — fonte única:
     api/src/events/payments-events.ts. Catálogo e regras: prodops/artifacts/architecture/domain-events.md.
     Não invente nomes de contrato que o código não usa, nem emita o mesmo fato sob dois nomes.
     Chaves de observabilidade (event_key) e tipos de webhook externo não seguem esta convenção.

     Coluna "Situação": `Emitido` = já existe no código; `Planejado` = ainda não existe (entra no escopo de
     implementação e não pode ser tratado como contrato vigente). Não deixe evento `Planejado` num OBC Operational.

     `correlationId` é sempre obrigatório. -->

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `<event_key_sucesso>` | Emitido | <O que representa este evento de sucesso.> | `<campo1>`, `<campo2>`, `correlationId` |
| `<event_key_falha>` | Emitido | <O que representa este evento de falha.> | `<campo1>`, `reason`, `correlationId` |

## Initial SLIs

<!-- Obrigatória para Committed. Liste os indicadores de nível de serviço iniciais com metas mensuráveis.
     Use 100% para invariantes absolutos; use percentuais para metas de confiabilidade.
     A coluna "Fonte" diz de onde sai o número: métrica do Datadog, evento acima ou consulta.
     Estas metas são revisadas e evoluídas durante Operation. -->

| SLI | Initial target | Fonte |
|---|---|---|
| <Comportamento mensurável que o sistema deve garantir.> | <100% ou 99.x%> | <métrica Datadog / `event_key` / consulta> |

## Reliability Rules

<!-- Obrigatória para Committed. Liste os invariantes que a implementação não pode violar.
     Cobrir obrigatoriamente: idempotência, comportamento em falha transiente, isolamento de segredos, auditoria.
     Cada regra é uma afirmação prescritiva — não uma sugestão. -->

- <Regra de idempotência: o que acontece em retentativas com a mesma chave de idempotência.>
- <Regra de comportamento em falha transiente: o que o sistema faz quando um provider externo falha.>
- <Regra de isolamento: validações que ocorrem antes de chamar sistemas externos.>
- <Regra de auditoria: o que é registrado e o que nunca deve ser exposto em logs ou respostas.>

## APIs

<!-- Opcional. Incluir quando a capability expõe endpoints. Omitir para capabilities puramente assíncronas.
     Confira método, caminho e autenticação no controller correspondente em api/src. -->

| Método | Caminho | Autenticação | Descrição |
|---|---|---|---|
| `<GET\|POST\|DELETE>` | `/<caminho>` | `X-Api-Token` \| nenhuma | <O que o endpoint faz.> |

## Response Contract

<!-- Opcional. Incluir quando a capability expõe uma API com contrato de resposta bem definido.
     Use JSON para APIs REST. Omitir para capabilities puramente assíncronas (event-driven). -->

```json
{
  "<campo_id>": "...",
  "<campo_referencia>": "...",
  "<campo_status>": "<ESTADO_ESPERADO>",
  "<campo_valor>": 0.00
}
```

## Riscos

<!-- Obrigatória para Committed. Riscos relevantes desta capability e onde estão tratados.
     Quando houver movimentação financeira, integração externa, mudança de SLO, risco alto/crítico ou alteração
     de persistência/segurança, o Reliability Plan deve estar atualizado. -->

| Risco | Severidade | Tratamento |
|---|---|---|
| <Descrição do risco.> | <Baixa \| Média \| Alta \| Crítica> | <Mitigação ou link para `prodops/artifacts/risks/risks.md`> |

## Dependências

<!-- Obrigatória para Committed. O que esta capability precisa para funcionar. -->

| Tipo | Dependência | Observação |
|---|---|---|
| OBC | `prodops/artifacts/obcs/<slug>.md` | <por que depende> |
| Serviço interno | <ex.: DynamoDB, SQS> | <criticidade> |
| Serviço externo | <ex.: Asaas> | <contrato ou limite relevante> |

## Decisões

<!-- Registro de decisões que moldaram o contrato (a skill diligence/capture exige data, decisão, justificativa
     e fonte). Acrescente linhas; não reescreva as anteriores. -->

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| <AAAA-MM-DD> | <Decisão tomada.> | <Por quê.> | <experiment.md / risks.md / trail> |

## Related Artifacts

<!-- Liste os artefatos relacionados a esta capability.
     BDD e Iteration Plan são obrigatórios quando o OBC está In Delivery ou posterior.
     OBCs relacionados listam capabilities que dependem ou são dependidas por esta. -->

- BDD: `prodops/artifacts/bdd/<slug>.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/<slug>.md`
- OBCs relacionados: *(links para OBCs de capabilities dependentes ou relacionadas)*
