# Local OBC - <Nome da Capability>

<!-- Renomeie este arquivo para o slug da capability: ex. split-payment-api.md -->
<!-- Mova para prodops/artifacts/business/obcs/<slug>.md ao promover para Committed -->
<!-- Definição completa do formato: prodops/framework/obc.md -->
<!-- Owner: Product Manager + Tech Lead do produto -->

## Status

<!-- Declare o estado atual do contrato.
     Estados possíveis: Draft | Refining | Committed | In Delivery | Operational | Archived
     Localização por estado:
       Draft/Refining: prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md
       Committed+:     prodops/artifacts/business/obcs/<slug>.md -->

Draft. Localizado em `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md`.

## Global OBC

<!-- Campo obrigatório. Referencie o Global OBC do qual este Local OBC foi derivado.
     Se este é um Local OBC de fluxo local (sem Global OBC), registre "Local — fluxo direto". -->

→ `<path-no-repo-portfolio>/obcs/<slug-global>.md` — <Nome da Intenção de Negócio>

## Produto / Repositório / Bounded Context

<!-- Identifique claramente qual produto implementa este contrato e qual bounded context está envolvido. -->

- **Repositório:** `<nome-do-repositório>`
- **Bounded Context:** <Nome do bounded context>
- **Responsabilidade:** <O que este produto entrega como parte da intenção de negócio.>

## APIs e Eventos (responsabilidade deste produto)

<!-- Liste as APIs e eventos que ESTE produto é responsável por implementar.
     Não duplique informações estratégicas do Global OBC — foque na responsabilidade técnica deste produto. -->

### APIs

| Endpoint | Método | Responsabilidade |
|---|---|---|
| `<path>` | `<HTTP método>` | <O que esta API faz.> |

### Eventos Publicados

| Evento | Tópico | Quando |
|---|---|---|
| `<dominio>.<acao>` | `<nome-do-tópico>` | <Condição de disparo.> |

### Eventos Consumidos

| Evento | Origem | Propósito |
|---|---|---|
| `<dominio>.<acao>` | `<repositório-origem>` | <Por que este produto consome este evento.> |

## BDD / Critérios de Aceite

<!-- Liste os critérios de aceite a nível de produto — comportamentos verificáveis.
     Referência ao arquivo BDD Feature quando comprometido. -->

- [ ] <Critério de aceite 1: comportamento esperado verificável.>
- [ ] <Critério de aceite 2: comportamento em falha esperado.>

**BDD Feature:** `prodops/artifacts/business/bdd/<slug>.feature` *(quando committed)*

## Eventos Observáveis

<!-- Liste todos os eventos observáveis que esta capability emite.
     Inclua eventos de sucesso, falha, casos especiais e de segurança.
     Cada evento deve ter nome canônico, significado e dimensões obrigatórias. -->

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `<dominio>.<acao_sucesso>` | <O que representa este evento de sucesso.> | `<campo1>`, `<campo2>`, `correlationId` |
| `<dominio>.<acao_falha>` | <O que representa este evento de falha.> | `<campo1>`, `reason`, `correlationId` |

## Regras de Confiabilidade

<!-- Liste os invariantes que a implementação não pode violar.
     Inclua regras de idempotência, falha segura, auditoria e isolamento. -->

- <Regra de idempotência: o que acontece em retentativas com a mesma chave.>
- <Regra de comportamento em falha transiente: o que o sistema faz quando um provider falha.>
- <Regra de isolamento: validações que ocorrem antes de chamar sistemas externos.>
- <Regra de auditoria: o que é registrado e o que nunca deve ser exposto.>

## Contrato de Resposta

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

## Dependências Técnicas

<!-- Liste as dependências técnicas: outros serviços, infraestrutura, integrações externas. -->

| Dependência | Tipo | Criticidade | Observação |
|---|---|---|---|
| `<nome-do-serviço>` | <Síncrono / Assíncrono / Infra> | <Alta / Média / Baixa> | <Observação relevante.> |

## Evidências

<!-- Preenchido durante e após Delivery.
     Registre links para evidências de implementação e operação. -->

- Release Trail: `prodops/artifacts/governance/trails/sessions/<data>-<session-id>.md`
- PR: *(link para o PR de implementação)*
- Métricas em produção: *(link para dashboard de observabilidade)*
