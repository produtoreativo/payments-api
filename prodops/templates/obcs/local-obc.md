# OBC - <Nome da Capability>

<!-- Renomeie este arquivo para o slug da capability: ex. split-payment-api.md -->
<!-- Mova para prodops/artifacts/obcs/<slug>.md quando o OBC estiver Committed -->
<!-- Definição completa do formato: prodops/framework/obc.md -->
<!-- Owner: Product Manager + Tech Lead do produto -->

## Status

<!-- Declare o estado atual e onde está rastreado.
     Estados possíveis: Draft | Refining | Committed | In Delivery | Operational | Archived
     Exemplo: Downstream. Status `Entrou` em prodops/artifacts/plans/iteration-plan.md. -->

Draft. Localizado em `prodops/artifacts/obcs/<slug>.md`.

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

## Observable Events

<!-- Liste todos os eventos observáveis que esta capability emite.
     Inclua eventos de sucesso, falha, idempotência e casos especiais.
     Cada evento deve ter nome canônico em snake_case, significado e dimensões obrigatórias.
     `correlationId` é sempre obrigatório. -->

| Event | Meaning | Required dimensions |
|---|---|---|
| `<dominio>.<acao_sucesso>` | <O que representa este evento de sucesso.> | `<campo1>`, `<campo2>`, `correlationId` |
| `<dominio>.<acao_falha>` | <O que representa este evento de falha.> | `<campo1>`, `reason`, `correlationId` |

## Initial SLIs

<!-- Liste os indicadores de nível de serviço iniciais com metas mensuráveis.
     Use 100% para invariantes absolutos; use percentuais para metas de confiabilidade.
     Estas metas são revisadas e evoluídas durante Operation. -->

| SLI | Initial target |
|---|---|
| <Comportamento mensurável que o sistema deve garantir.> | <100% ou 99.x%> |

## Reliability Rules

<!-- Liste os invariantes que a implementação não pode violar.
     Cobrir obrigatoriamente: idempotência, comportamento em falha transiente, isolamento de segredos, auditoria.
     Cada regra é uma afirmação prescritiva — não uma sugestão. -->

- <Regra de idempotência: o que acontece em retentativas com a mesma chave de idempotência.>
- <Regra de comportamento em falha transiente: o que o sistema faz quando um provider externo falha.>
- <Regra de isolamento: validações que ocorrem antes de chamar sistemas externos.>
- <Regra de auditoria: o que é registrado e o que nunca deve ser exposto em logs ou respostas.>

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

## Related Artifacts

<!-- Liste os artefatos relacionados a esta capability.
     BDD e Iteration Plan são obrigatórios quando o OBC está In Delivery ou posterior.
     OBCs relacionados listam capabilities que dependem ou são dependidas por esta. -->

- BDD: `prodops/artifacts/bdd/<slug>.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBCs relacionados: *(links para OBCs de capabilities dependentes ou relacionadas)*
