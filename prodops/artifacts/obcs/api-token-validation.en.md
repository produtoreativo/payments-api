# OBC - API Token Validation

## Status

Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan").

## Business Outcome

Magazine Siará can ensure that only authorized systems consume the Payments
API, validating each request against a registered API token. Tokens are scoped
to a tenant and can be revoked without redevelopment. The local environment has a
pre-registered key that authorizes requests originating from localhost, eliminating
dependency on secrets infrastructure during development.

## Observable Events

| Event | Meaning | Required dimensions |
| --- | --- | --- |
| `api.token.validated` | Request authenticated with a valid token. | `tenantId`, `tokenId`, `correlationId`, `path`, `method` |
| `api.token.rejected` | Token absent, invalid or revoked. | `correlationId`, `path`, `method`, `reason` |
| `api.token.registered` | New API token was registered. | `tenantId`, `tokenId`, `description`, `allowedOrigins` |
| `api.token.revoked` | Token was revoked. | `tenantId`, `tokenId`, `revokedBy`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
| --- | --- |
| Requests with a valid token authorized without additional latency > 5ms. | 99.9% |
| Requests with an absent or invalid token rejected with 401 and observable reason. | 100% |
| Localhost token valid in development environment without external secrets. | 100% |
| Tokens do not appear in logs, traces or error responses. | 100% |

## Reliability Rules

- Tokens are validated in memory from a configuration map loaded at startup.
- Local environment (`NODE_ENV=development` or `localhost` origin) uses a pre-registered token via `API_TOKEN_LOCAL`.
- Tokens must not be logged, even at debug level. The log must record only `tokenId`, never the raw value.
- Token revocation must be operational without a deploy: the token map is reloadable via environment variable without a forced process restart (enabled in a future iteration with an external store).
- Provider webhook routes (Asaas) are outside the API Token guard because they use their own authentication via the `asaas-access-token` header.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/api-token-validation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
