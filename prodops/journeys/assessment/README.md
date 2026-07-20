# Assessment

## Responsabilidade

Produzir análises para apoiar decisões.

O Assessment não implementa software. Ele produz insumos para decisões de produto, arquitetura e confiabilidade.

## Quando ocorre

O Assessment pode ocorrer tanto no Upstream quanto no Downstream.

- **No Upstream:** avalia hipóteses, experimentos e aprendizados para decidir se uma capability deve avançar para Downstream.
- **No Downstream:** avalia riscos, oportunidades e OBCs para decidir se um item está pronto para Delivery.

## O que produz

- análises de riscos e oportunidades
- diagnósticos de produto
- Premortem
- Reliability Plans
- Decision Packages
- recomendações de priorização

## Artefatos

| Artefato | Localização |
|---|---|
| Riscos | [risks.md](risks.md) |
| Oportunidades | [opportunities.md](opportunities.md) |
| Reliability Plans | [reliability-plans/](reliability-plans/) |
| Event Storming | [event-storming/](event-storming/) |
| Arquitetura | [../../artifacts/product/architecture/](../../artifacts/product/architecture/) |
| OBCs (referência) | [../../artifacts/business/obcs/](../../artifacts/business/obcs/) |
| Iteration Plans (referência) | [../../artifacts/governance/plans/](../../artifacts/governance/plans/) |

## Relação com outras jornadas

- **Discovery** produz experimentos e aprendizados que o Assessment usa para emitir recomendações.
- **Delivery** consome as decisões do Assessment (OBC committed, Reliability Plan, riscos documentados).
- **Operation** envia sinais de incidentes e postmortems que o Assessment usa para atualizar riscos.
- **Diligence** sincroniza as decisões do Assessment nos backlogs e representações operacionais.
