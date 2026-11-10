# OBC - API Token Validation

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-42 |
| Iteration | v0.5.0 (retrabalho em v0.6.0) |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-42 (#42) — v0.5.0 (retrabalho em v0.6.0), PR #102. Previous record: Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan").
**Pending:** iteration completed (PR #102); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-007](../business-intents/PI-007.md) |
| Product Tracking Item | issue #42 (DS-42), see `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

Magazine Siará can ensure that only authorized systems consume the Payments
API, validating each request against a registered API token. Tokens are scoped
to a tenant and can be revoked without redevelopment. The local environment has a
pre-registered key that authorizes requests originating from localhost, eliminating
dependency on secrets infrastructure during development.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/api-token-validation.feature`; tick after verification.

- [ ] Requisição autenticada com token válido
- [ ] Requisição sem token é rejeitada
- [ ] Requisição com token inválido é rejeitada
- [ ] Token revogado é rejeitado
- [ ] Validação local com token de desenvolvimento
- [ ] Rota de webhook do provedor não exige token de API
- [ ] Token não aparece em logs ou respostas de erro

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | Service Deck: [autenticacao-api-token](../product/context/service-decks/autenticacao-api-token.md) |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `api.token.validated` | Emitted | Request authenticated with a valid token. | `tenantId`, `tokenId`, `correlationId`, `path`, `method` |
| `api.token.rejected` | Emitted | Token absent, invalid or revoked. | `correlationId`, `path`, `method`, `reason` |
| `api.token.registered` | Planned | New API token was registered. | `tenantId`, `tokenId`, `description`, `allowedOrigins` |
| `api.token.revoked` | Planned | Token was revoked. | `tenantId`, `tokenId`, `revokedBy`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| Requests with a valid token authorized without additional latency > 5ms. | 99.9% | [to be determined] |
| Requests with an absent or invalid token rejected with 401 and observable reason. | 100% | [to be determined] |
| Localhost token valid in development environment without external secrets. | 100% | [to be determined] |
| Tokens do not appear in logs, traces or error responses. | 100% | [to be determined] |

## Reliability Rules

- Tokens are validated in memory from a configuration map loaded at startup.
- Local environment (`NODE_ENV=development` or `localhost` origin) uses a pre-registered token via `API_TOKEN_LOCAL`.
- Tokens must not be logged, even at debug level. The log must record only `tokenId`, never the raw value.
- Token revocation must be operational without a deploy: the token map is reloadable via environment variable without a forced process restart (enabled in a future iteration with an external store).
- Provider webhook routes (Asaas) are outside the API Token guard because they use their own authentication via the `asaas-access-token` header.

## Risks

| Risk | Severity | Handling |
|---|---|---|
| [to be determined] | [to be determined] | see `prodops/artifacts/risks/risks.md` |

## Dependencies

| Type | Dependency | Note |
|---|---|---|
| Internal service | DynamoDB | Critical (Product Deck, section 4) |

## Decisions

| Date | Decision | Rationale | Source |
|---|---|---|---|
| 2026-11-10 | Migration to the `local-obc.en.md` template: sections added, Status normalized, events classified by Status and SLIs with Source. | Template adherence and the rule that the event name is the one emitted in the code. Fields without a source marked `[to be determined]`. | `obc` skill (`fix` mode); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/api-token-validation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/autenticacao-api-token.md`
