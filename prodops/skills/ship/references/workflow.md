# SHIP Workflow

SHIP é a fase de observação e orquestração. O agente observa a execução do Pull Request autônomo criado pelo Finish — checks, aprovação, merge, deploy para Staging — sem executar nenhuma dessas etapas diretamente.

**Quem executa aprovação, merge e workflows:** GitHub
**Quem executa pipelines e deploy:** GitHub Actions
**Ship:** observa, emite eventos, reage a falhas

## Ambientes

| Ambiente | Tipo | Ship observa? |
|---|---|---|
| Staging | Efêmero por Feature/OBC | Sim — destino do deploy observado |
| Sandbox | Compartilhado (Release Candidate) | Não — responsabilidade do Promote |
| Production | Operacional | Não — fora da Delivery Journey |

## Detectar o PR criado pelo Finish

```sh
gh pr list --head <branch> --state open --json number,url,title,statusCheckRollup
gh pr view <pr-number> --json number,url,title,state,mergeable,statusCheckRollup,autoMergeRequest
```

Confirmar que o PR foi criado pelo Finish para o work-item correto antes de emitir Ship.Started.

## Observar Checks e Workflows

```sh
gh pr checks <pr-number> --watch
gh run list --branch <branch>
gh run view <run-id>
```

Se qualquer check falhar: registrar o run-id e motivo da falha. **Interromper progressão.** Não prosseguir para merge ou deploy. Reportar — Finish deve ser reaberto.

## Observar Aprovação Automática

Verificar se o repositório tem auto-approval configurado (via GitHub Apps ou CODEOWNERS com auto-approve):

```sh
gh pr view <pr-number> --json reviews,autoMergeRequest
```

Se auto-approval não ocorrer em tempo razoável após checks passarem: reportar como bloqueio e aguardar investigação.

## Observar Merge Automático

```sh
gh pr view <pr-number> --json state,mergedAt,mergeCommit
```

Aguardar `state: MERGED`. Se merge não ocorrer após aprovação e checks passarem: reportar como bloqueio.

## Observar Deploy para Staging

Após merge, observar disparo do pipeline de deploy para Staging:

```sh
gh run list --branch main --workflow <staging-deploy-workflow>
gh run view <run-id> --log
```

Aguardar conclusão do pipeline com sucesso. Se o pipeline falhar: registrar run-id e motivo. **Interromper progressão.**

## Registrar Evidência e Emitir Ship.Completed

Após merge confirmado **E** deploy em Staging concluído com sucesso:

1. Registrar no Release Trail:
   - PR mergeado: número, commit, data
   - Deploy em Staging: run-id, versão, ambiente
   - Resultado: sucesso

2. Emitir `Delivery.Ship.Completed` com `correlation-id` do Ship.Started.

## Resposta a Falhas

| Falha | Ação do Ship |
|---|---|
| Check de CI falha | Interromper. Reportar run-id e motivo. Finish deve ser reaberto. |
| Auto-approval não ocorre | Reportar como bloqueio. Aguardar investigação. |
| Merge não ocorre | Reportar como bloqueio. Aguardar investigação. |
| Deploy em Staging falha | Interromper. Reportar run-id e motivo. Finish deve ser reaberto. |

**Ship NÃO emite Ship.Completed em cenários de falha.**
