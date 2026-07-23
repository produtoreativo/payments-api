# OBC - API Token Validation

## Status

Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` (section "Iteration Plan recomendado").

## Business Outcome

Magazine Siará pode garantir que apenas sistemas autorizados consumam a Payments
API, validando cada requisição por um token de API cadastrado. Tokens têm escopo
de tenant e podem ser revogados sem redesenvolvimento. O ambiente local possui uma
chave pré-cadastrada que autoriza requisições originadas de localhost, eliminando
dependência de infraestrutura de secrets durante o desenvolvimento.

## Observable Events

| Event | Meaning | Required dimensions |
| --- | --- | --- |
| `api.token.validated` | Requisição autenticada com token válido. | `tenantId`, `tokenId`, `correlationId`, `path`, `method` |
| `api.token.rejected` | Token ausente, inválido ou revogado. | `correlationId`, `path`, `method`, `reason` |
| `api.token.registered` | Novo token de API foi cadastrado. | `tenantId`, `tokenId`, `description`, `allowedOrigins` |
| `api.token.revoked` | Token foi revogado. | `tenantId`, `tokenId`, `revokedBy`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
| --- | --- |
| Requisições com token válido autorizadas sem latência adicional > 5ms. | 99.9% |
| Requisições com token ausente ou inválido rejeitadas com 401 e reason observável. | 100% |
| Token de localhost válido em ambiente de desenvolvimento sem secrets externos. | 100% |
| Tokens não aparecem em logs, traces ou respostas de erro. | 100% |

## Reliability Rules

- Tokens são validados em memória a partir de mapa de configuração carregado na inicialização.
- Ambiente local (`NODE_ENV=development` ou origem `localhost`) usa token pré-cadastrado via `API_TOKEN_LOCAL`.
- Tokens não devem ser logados, mesmo em nível debug. O log deve registrar apenas `tokenId`, nunca o valor raw.
- A revogação de token deve ser operacional sem deploy: o mapa de tokens é recarregável via variável de ambiente sem reinicialização forçada do processo (viabilizado em iteração futura com store externo).
- Rotas de webhook do provedor (Asaas) ficam fora do guard de API Token porque usam autenticação própria por header `asaas-access-token`.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/api-token-validation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
