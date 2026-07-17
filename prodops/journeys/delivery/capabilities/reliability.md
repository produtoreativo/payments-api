# Capability — Reliability

## Objetivo

Definir e verificar requisitos de confiabilidade antes, durante e após a implementação: timeouts, retries, idempotência, degradação controlada.

## Responsabilidades

- Documentar requisitos de confiabilidade no OBC antes da implementação
- Verificar durante o Hack que os requisitos estão implementados
- Registrar riscos no Reliability Plan
- Validar SLOs no ambiente de staging antes da promoção

## Flows consumidores

| Flow | Momento de uso |
|---|---|
| Downstream readiness | Ler riscos e requisitos de confiabilidade do OBC |
| Hack | Implementar timeout, retry, idempotência, exceções |
| Finish | Definition of Done — itens de confiabilidade |
| Promote | Rollback Readiness, riscos aceitos formalmente |

## Artefatos produzidos

- Riscos documentados em `prodops/journeys/assessment/risks.md`
- OBC com SLIs e Reliability Rules em `prodops/artifacts/business/obcs/`
- Reliability Plan entry em `prodops/journeys/assessment/reliability-plans/`

## Documentação canônica

→ [prodops/journeys/delivery/capabilities/reliability-policy.md](reliability-policy.md)
→ [prodops/journeys/assessment/risks.md](../../assessment/risks.md)
