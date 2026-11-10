# OBC - Atualização de Dependências com Vulnerabilidades de Segurança

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-44 |
| Iteração | v0.7.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-44 (#115) — v0.7.0, PR #116. Registro anterior: Downstream. Pendente de entrada no Iteration Plan — artefatos de produto em elaboração.
**Pendência:** iteração concluída (PR #116); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [#55](https://github.com/produtoreativa/payments-api/issues/55) |
| Business Intent | [PI-013](../business-intents/PI-013.md) |
| Product Tracking Item | issue #115 (DS-44), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

A Payments API opera sem dependências npm com vulnerabilidades conhecidas (high ou critical) sinalizadas pelo Dependabot. As 27 vulnerabilidades abertas — 14 high, 11 medium, 2 low — em 9 pacotes são resolvidas por atualização de versão, sem quebra de contrato de API, sem regressão no test suite e sem introdução de novas dependências.

A dependência direta `axios` (única com alerta que exige atualização em `package.json`) é elevada de `^1.13.2` para `>=1.18.0`. As demais vulnerabilidades são em dependências transitivas e resolvidas via `npm audit fix` ou `overrides` no `package.json`, priorizando o caminho de menor impacto.

### Em linguagem executiva

O Dependabot identificou 27 vulnerabilidades em bibliotecas que a Payments API usa internamente — entre elas, falhas que permitem vazamento de credenciais, negação de serviço e leitura de arquivos arbitrários. Nenhuma dessas vulnerabilidades afeta a API diretamente agora, mas representam risco real se exploradas em ambiente de produção.

A resolução é uma atualização de versão das bibliotecas afetadas — equivalente a instalar patches de segurança em um sistema operacional. O trabalho é verificar que a atualização não quebra nada que já funciona e depois confirmar que os alertas foram fechados.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/dependency-security-update.feature`; marcar após verificação.

- [ ] Dependência direta axios atualizada sem regressão
- [ ] Dependências transitivas resolvidas via npm audit
- [ ] Upgrade de major version com breaking change requer decisão registrada
- [ ] Nenhum contrato de API alterado após atualização
- [ ] Confirmação final — zero alertas high/critical abertos

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

Não aplicável — mudança de dependências sem impacto em eventos de runtime da aplicação.

A evidência observável é operacional: número de alertas Dependabot com estado `open` e resultado do CI (test suite + build) após a atualização.

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Alertas Dependabot com severity `critical` ou `high` em estado `open` após a entrega. | 0 | [apurar] |
| Cenários BDD existentes passando após atualização de dependências. | 100% | [apurar] |
| Build de produção (`npm run build`) concluído sem erro após atualização. | 100% | [apurar] |
| Nenhum contrato de API alterado (endpoints, payloads, status codes). | 100% | [apurar] |

## Reliability Rules

- Atualização de dependência direta (`axios`) deve usar range semântico compatível com o lockfile existente — sem forçar versão que quebre o contrato de resposta do provedor Asaas.
- Dependências transitivas com upgrade de major version (ex.: `multer` 1.x → 2.x) exigem verificação de breaking changes antes do `npm audit fix --force`. Se houver breaking change real: documentar decisão de aceite de risco ou abrir issue de follow-up.
- O `package-lock.json` deve ser commitado junto com `package.json` — nenhum `npm install` sem lockfile atualizado entra no PR.
- Após atualização, executar o test suite completo localmente antes de abrir PR — não confiar apenas no CI para detectar regressões em dependências transitivas.
- Alertas que não possuem versão patched disponível ou que exigem breaking change maior devem ser documentados como aceite de risco em `prodops/artifacts/risks/risks.md` — nunca silenciados sem registro.

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| — | [apurar] | [apurar] |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/dependency-security-update.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Risk Register: `prodops/artifacts/risks/risks.md`
- Issue de referência: [#55](https://github.com/produtoreativo/payments-api/issues/55) — Business Signal capturado pelo Dependabot
