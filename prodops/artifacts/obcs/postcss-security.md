# OBC - Resolução de Vulnerabilidade HIGH do postcss em validation-workbench

## Status

Committed. Aguardando entrada no Iteration Plan — DS-52, issue [#117](https://github.com/produtoreativo/payments-api/issues/117).

## Business Outcome

O workspace `validation-workbench/` opera sem dependências com vulnerabilidades HIGH ou critical sinalizadas pelo Dependabot. O alerta #101 — `postcss < 8.5.18`, Path Traversal via sourceMappingURL — é eliminado por atualização da dependência direta (`vite`) que arrasta `postcss` como transitiva.

A `api/` não é afetada e nenhuma alteração é feita em seu `package.json` ou `package-lock.json`. O fix é cirúrgico: restrito a `validation-workbench/`.

### Em linguagem executiva

O `validation-workbench` é a ferramenta interna de validação manual de fluxos de pagamento. Uma das bibliotecas que ele usa internamente (postcss, usada pelo Vite para processar CSS) tem uma falha de segurança conhecida que permite leitura de caminhos arbitrários de arquivo via source maps. A resolução é atualizar o Vite para uma versão que já inclui a versão corrigida do postcss — equivalente a instalar um patch de segurança.

## Observable Events

Não aplicável — mudança de dependência transitiva sem impacto em eventos de runtime da aplicação.

A evidência observável é operacional: alerta Dependabot #101 fechado e build do workspace verde após a atualização.

## Initial SLIs

| SLI | Initial target |
|---|---|
| Alertas Dependabot com severity `high` ou `critical` em `validation-workbench/package-lock.json` em estado `open` após a entrega. | 0 |
| Build de `validation-workbench/` (`tsc -b && vite build`) após atualização. | 100% verde |
| Nenhuma regressão introduzida em `api/` (npm audit e test suite inalterados). | 100% |

## Reliability Rules

- A resolução **não usa `--force`** — se o upgrade quebrar o build, a causa deve ser identificada e corrigida antes do merge.
- Nenhuma alteração em `api/package.json` ou `api/package-lock.json` — o fix é restrito a `validation-workbench/`.
- Se `postcss` não puder ser resolvido por upgrade de `vite`, usar `overrides` em `validation-workbench/package.json` apontando para `postcss >= 8.5.18`.
- O build de `validation-workbench/` deve passar antes de abrir o PR.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/postcss-security.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Risk: `prodops/artifacts/risks/risks.md` — DS-Security-01 (parcialmente resolvido)
- Issue de follow-up: [#117](https://github.com/produtoreativo/payments-api/issues/117)
- Dependabot alert: #101 (`postcss < 8.5.18` em `validation-workbench/package-lock.json`)
