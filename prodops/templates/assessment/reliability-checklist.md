# Reliability Checklist

Usar antes de promover uma capability de Upstream para Downstream, ou antes de fazer o ship de um item Downstream.

## Cobertura de comportamento

- [ ] OBC definido e mensurável.
- [ ] Todos os critérios de aceite cobertos por testes.
- [ ] Modos de falha documentados em `prodops/journeys/assessment/risks.md`.

## Observabilidade

- [ ] Operações no caminho crítico emitem logs estruturados.
- [ ] Respostas de erro têm correlation IDs.
- [ ] Nenhum secret ou PII nos logs.
- [ ] Sinal de SLO identificado (baseado em métrica ou log).

## Prontidão operacional

- [ ] Runbook existe ou foi atualizado em `prodops/journeys/operation/runbooks.md`.
- [ ] Time de on-call notificado sobre novo modo de falha.
- [ ] Plano de rollback definido.

## Evidência

- [ ] Execução de testes pré-deploy registrada.
- [ ] Validação pós-deploy concluída.
- [ ] Entrada adicionada no trail da sessão ativa em `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`.
