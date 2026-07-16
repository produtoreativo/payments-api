# OBC - <Nome da Capability>

<!-- Renomeie este arquivo para o slug da capability: ex. create-invoice.md -->
<!-- Mova para prodops/artifacts/obcs/<slug>.md ao promover para Downstream -->
<!-- Definição completa do formato: prodops/framework/obc.md -->

## Status

<!-- Declare o estado atual e onde o OBC está localizado no ciclo de backlogs. -->
<!-- Estados possíveis: Draft | Minimum OBC | Active | Operational | Archived -->

Draft. Localizado em `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md` (exploratório).

## Business Outcome

<!-- Descreva o resultado de negócio que a capability entrega.
     Responda: para quem, o quê e com qual garantia.
     Foque no resultado — não na implementação técnica. -->

<Ator> consegue <fazer o quê> sem <problema que resolve>. <Sistema> <comportamento principal>, <comportamento de confiabilidade>.

### Em linguagem executiva

<!-- Opcional. Explicação sem jargão técnico para stakeholders não técnicos.
     Use uma analogia se ajudar. -->

<Analogia ou explicação executiva do que a funcionalidade garante ao negócio.>

## Observable Events

<!-- Liste todos os eventos observáveis que a capability emite.
     Inclua eventos de sucesso, falha, casos especiais e de segurança.
     Cada evento deve ter nome canônico, significado e dimensões obrigatórias. -->

| Event | Meaning | Required dimensions |
|---|---|---|
| `<dominio>.<acao_sucesso>` | <O que representa este evento de sucesso.> | `<campo1>`, `<campo2>`, `correlationId` |
| `<dominio>.<acao_falha>` | <O que representa este evento de falha.> | `<campo1>`, `reason`, `correlationId` |
| `<dominio>.<caso_especial>` | <O que representa este evento de caso especial.> | `<campo1>`, `correlationId` |

## Initial SLIs

<!-- Defina os indicadores de nível de serviço com targets quantitativos.
     Cada SLI deve ser observável via os eventos declarados acima.
     Use percentuais absolutos (ex: 99.9%, 100%). -->

| SLI | Initial target |
|---|---|
| <Critério de sucesso principal observável via eventos.> | 99.9% |
| <Critério de idempotência ou segurança crítica.> | 100% |
| <Critério de comportamento em falha controlada.> | 100% |

## Reliability Rules

<!-- Liste os invariantes que a implementação não pode violar.
     Inclua regras de idempotência, falha segura, auditoria e isolamento.
     Cada regra deve ser verificável a partir dos eventos e SLIs acima. -->

- <Regra de comportamento em falha transiente: o que o sistema faz quando o provider falha.>
- <Regra de idempotência: o que acontece em retentativas com a mesma chave.>
- <Regra de isolamento: validações que ocorrem antes de chamar sistemas externos.>
- <Regra de auditoria: o que é registrado e o que nunca deve ser exposto.>

## Response Contract

<!-- Defina o contrato de resposta: payload retornado ao consumidor, campos obrigatórios.
     Use JSON se a capability é uma API. Use descrição narrativa se for um evento assíncrono. -->

```json
{
  "<campo_id>": "...",
  "<campo_referencia>": "...",
  "<campo_status>": "<ESTADO_ESPERADO>",
  "<campo_valor>": 0.00
}
```

## Related Artifacts

<!-- Links para artefatos diretamente relacionados. Preencha conforme disponível. -->

- BDD: `prodops/artifacts/bdd/<slug>.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/icebox-backlog.md` — <ID do item>
- OBCs relacionados: *(liste OBCs com dependência direta)*
