# Done Criteria

Uma task está pronta quando:

- A mudança implementada corresponde ao contexto ProdOps atual.
- Artefatos impactados de BDD, Reliability Plan ou operação foram atualizados.
- Testes ou evidências de validação foram executados, ou a ausência foi documentada com justificativa.
- O Release Trail tem uma nova entrada para o trabalho significativo realizado.
- Riscos remanescentes e próximos passos estão explícitos.

## Critérios por sub-passo do Finish

O Finish está completo quando, **em ordem**:

- [ ] **`validate`** passou — análise estática (format, lint, build) mais a
      aceitação quando comportamento ou contratos mudaram. A execução da
      aceitação também emite a **cobertura** em Cobertura XML
      (`api/coverage/cobertura-coverage.xml`) — não há passo de coverage
      separado. Falha aqui não avança: a correção retorna ao `hack tdd`.
- [ ] **`review`** confirmou as regras de PR automático — checks obrigatórios,
      branch protection na branch de destino e ausência de reviewer bloqueante —
      ou **registrou o bloqueador** de branch protection antes de qualquer auto
      aprovação.
- [ ] **push** realizado na branch de origem, sem force push.
- [ ] **`request`** abriu **um** PR com título e body segundo o template,
      preenchido com evidências, e auto aprovação armada (`gh pr merge --auto
      --squash`).
- [ ] Release Trail atualizado com o link do PR (trail da sessão ativa em
      `prodops/artifacts/trails/sessions/`).
