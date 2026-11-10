# OBC - API Token Validation

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-42 |
| Iteração | v0.5.0 (retrabalho em v0.6.0) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-42 (#42) — v0.5.0 (retrabalho em v0.6.0), PR #102. Registro anterior: Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` (section "Iteration Plan recomendado").
**Pendência:** iteração concluída (PR #102); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-007](../business-intents/PI-007.md) |
| Product Tracking Item | issue #42 (DS-42), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

Magazine Siará pode garantir que apenas sistemas autorizados consumam a Payments
API, validando cada requisição por um token de API cadastrado. Tokens têm escopo
de tenant e podem ser revogados sem redesenvolvimento. O ambiente local possui uma
chave pré-cadastrada que autoriza requisições originadas de localhost, eliminando
dependência de infraestrutura de secrets durante o desenvolvimento.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/api-token-validation.feature`; marcar após verificação.

- [ ] Requisição autenticada com token válido
- [ ] Requisição sem token é rejeitada
- [ ] Requisição com token inválido é rejeitada
- [ ] Token revogado é rejeitado
- [ ] Validação local com token de desenvolvimento
- [ ] Rota de webhook do provedor não exige token de API
- [ ] Token não aparece em logs ou respostas de erro

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [autenticacao-api-token](../product/context/service-decks/autenticacao-api-token.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `api.token.validated` | Emitido | Requisição autenticada com token válido. | `tenantId`, `tokenId`, `correlationId`, `path`, `method` |
| `api.token.rejected` | Emitido | Token ausente, inválido ou revogado. | `correlationId`, `path`, `method`, `reason` |
| `api.token.registered` | Planejado | Novo token de API foi cadastrado. | `tenantId`, `tokenId`, `description`, `allowedOrigins` |
| `api.token.revoked` | Planejado | Token foi revogado. | `tenantId`, `tokenId`, `revokedBy`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Requisições com token válido autorizadas sem latência adicional > 5ms. | 99.9% | [apurar] |
| Requisições com token ausente ou inválido rejeitadas com 401 e reason observável. | 100% | [apurar] |
| Token de localhost válido em ambiente de desenvolvimento sem secrets externos. | 100% | [apurar] |
| Tokens não aparecem em logs, traces ou respostas de erro. | 100% | [apurar] |

## Reliability Rules

- Tokens são validados em memória a partir de mapa de configuração carregado na inicialização.
- Ambiente local (`NODE_ENV=development` ou origem `localhost`) usa token pré-cadastrado via `API_TOKEN_LOCAL`.
- Tokens não devem ser logados, mesmo em nível debug. O log deve registrar apenas `tokenId`, nunca o valor raw.
- A revogação de token deve ser operacional sem deploy: o mapa de tokens é recarregável via variável de ambiente sem reinicialização forçada do processo (viabilizado em iteração futura com store externo).
- Rotas de webhook do provedor (Asaas) ficam fora do guard de API Token porque usam autenticação própria por header `asaas-access-token`.

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/api-token-validation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/autenticacao-api-token.md`
