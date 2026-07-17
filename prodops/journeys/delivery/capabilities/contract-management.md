# Capability — Contract Management

## Objetivo

Definir, manter e verificar contratos que descrevem o comportamento esperado do sistema — antes, durante e após a implementação.

## Responsabilidades

- Criar e manter BDD Features como contratos de comportamento
- Criar e manter OBCs como critérios de sucesso mensuráveis
- Manter OpenAPI e AsyncAPI em sincronia com o comportamento implementado
- Verificar que o contrato existe antes de iniciar qualquer implementação Downstream

## Flows consumidores

| Flow | Momento de uso |
|---|---|
| Bootstrap | Verificar que o contrato existe — pré-condição do Hack |
| Hack | Escrever o primeiro teste a partir do contrato (Red Bar) |
| Sync | Confirmar que o contrato reflete o comportamento implementado |
| Validate | Executar Runtime Contract Validation no ambiente alvo |

## Artefatos produzidos

- BDD Feature em `prodops/artifacts/business/bdd/` (committed) ou `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratory)
- OBC em `prodops/artifacts/business/obcs/`
- OpenAPI spec atualizada
- AsyncAPI spec atualizada

## Dependências

- Product Deck (`prodops/artifacts/product/product-deck.md`)
- Reliability Plan (`prodops/journeys/assessment/reliability-plans/`)

## Referências

→ [prodops/framework/glossary.md](../../../framework/glossary.md) — definições de OBC e BDD Feature
→ [prodops/journeys/delivery/phases/bootstrap/README.md](../phases/bootstrap/README.md) — como verificar o contrato no Bootstrap
