# OBC - Resolução de Vulnerabilidade HIGH do postcss em validation-workbench

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-52 |
| Iteração | v0.10.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-52 (#117) — v0.10.0, PR #126. Registro anterior: Committed. Aguardando entrada no Iteration Plan — DS-52, issue [#117](https://github.com/produtoreativo/payments-api/issues/117).
**Pendência:** iteração concluída (PR #126); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [#118](https://github.com/produtoreativa/payments-api/issues/118) |
| Business Intent | [PI-014](../business-intents/PI-014.md) |
| Product Tracking Item | issue #117 (DS-52), ver `prodops/artifacts/plans/iteration-plan.md` |
| Relacionado | [PI-013](../business-intents/PI-013.md) |

## Business Outcome

O workspace `validation-workbench/` opera sem dependências com vulnerabilidades HIGH ou critical sinalizadas pelo Dependabot. O alerta #101 — `postcss < 8.5.18`, Path Traversal via sourceMappingURL — é eliminado por atualização da dependência direta (`vite`) que arrasta `postcss` como transitiva.

A `api/` não é afetada e nenhuma alteração é feita em seu `package.json` ou `package-lock.json`. O fix é cirúrgico: restrito a `validation-workbench/`.

### Em linguagem executiva

O `validation-workbench` é a ferramenta interna de validação manual de fluxos de pagamento. Uma das bibliotecas que ele usa internamente (postcss, usada pelo Vite para processar CSS) tem uma falha de segurança conhecida que permite leitura de caminhos arbitrários de arquivo via source maps. A resolução é atualizar o Vite para uma versão que já inclui a versão corrigida do postcss — equivalente a instalar um patch de segurança.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/postcss-security.feature`; marcar após verificação.

- [ ] Upgrade de vite resolve o alerta do postcss
- [ ] Build de validation-workbench permanece verde após o upgrade
- [ ] api/ não é afetada pela mudança
- [ ] Override cobre cenário onde upgrade direto do vite não é suficiente
- [ ] Zero alertas HIGH ou critical em validation-workbench após a entrega

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | n/a — capacidade de plataforma/framework, não é Product Service |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

Não aplicável — mudança de dependência transitiva sem impacto em eventos de runtime da aplicação.

A evidência observável é operacional: alerta Dependabot #101 fechado e build do workspace verde após a atualização.

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Alertas Dependabot com severity `high` ou `critical` em `validation-workbench/package-lock.json` em estado `open` após a entrega. | 0 | [apurar] |
| Build de `validation-workbench/` (`tsc -b && vite build`) após atualização. | 100% verde | [apurar] |
| Nenhuma regressão introduzida em `api/` (npm audit e test suite inalterados). | 100% | [apurar] |

## Reliability Rules

- A resolução **não usa `--force`** — se o upgrade quebrar o build, a causa deve ser identificada e corrigida antes do merge.
- Nenhuma alteração em `api/package.json` ou `api/package-lock.json` — o fix é restrito a `validation-workbench/`.
- Se `postcss` não puder ser resolvido por upgrade de `vite`, usar `overrides` em `validation-workbench/package.json` apontando para `postcss >= 8.5.18`.
- O build de `validation-workbench/` deve passar antes de abrir o PR.

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

- BDD: `prodops/artifacts/bdd/postcss-security.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Risk: `prodops/artifacts/risks/risks.md` — DS-Security-01 (parcialmente resolvido)
- Issue de follow-up: [#117](https://github.com/produtoreativo/payments-api/issues/117)
- Dependabot alert: #101 (`postcss < 8.5.18` em `validation-workbench/package-lock.json`)
