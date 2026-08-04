# OBC - RT Iteration Lifecycle Automation

## Status

Committed. Business Intent: PI-RT-004. Business Signal: #135. GitHub Issue: #145. DS-58. Owner Approval: Context Engineer — 2026-08-04.

## Business Outcome

O encerramento de uma Iteration é completamente automático: a issue de rastreamento é fechada com sumário de evidências, os assignees das issues de feature são preenchidos com o Context Engineer que executou o downstream — sem nenhuma ação manual após o último Promote.Completed.

### Em linguagem executiva

Hoje ao concluir uma iteração, o Context Engineer precisa fechar manualmente a issue de rastreamento e preencher assignees um a um. Esse trabalho automatiza os dois passos: ao completar o último Promote, o sistema fecha a tracking issue com um comment de encerramento e garante que todas as issues criadas no Plan Bootstrap já saem com o assignee preenchido.

## Premortem

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| `gh api user` retorna login diferente do esperado em ambientes CI | Baixa | Médio — assignee preenchido incorretamente | Validar login antes de usar; logar o valor no trail |
| Auto-close dispara antes de todas as issues serem promovidas (race condition) | Média | Alto — tracking issue fechada prematuramente | Só fechar quando contador de promoted == total de DS-IDs do plano |
| GitHub API retorna erro ao adicionar assignee (permissão, usuário inválido) | Baixa | Baixo — issue criada sem assignee, processo não bloqueado | Tratar como erro não-fatal; logar aviso e continuar |
| Tracking issue já fechada manualmente — auto-close falha ou reabre | Baixa | Baixo | Verificar status antes de fechar; idempotente se já fechada |
| Comment de encerramento muito longo é truncado pelo GitHub | Baixa | Baixo | Limitar sumário a DS-IDs + PRs + data, sem body completo |

## Observable Events

O auto-close é acionado pelo dispatcher interno após `Delivery.Plan.Bootstrap.Completed` ou como step final do Iteration Closure no downstream-agent. Nenhum CloudEvent novo é necessário — a ação é local (gh CLI).

## Initial SLIs

| SLI | Target |
|---|---|
| Tracking issue fechada automaticamente ao concluir iteração com sucesso | 100% |
| Assignee preenchido em cada issue de feature criada no Plan Bootstrap | ≥ 95% |
| Comment de encerramento contém DS-IDs, PRs mergeados e data | 100% |

## Reliability Rules

- Auto-close só ocorre se **todas** as issues da iteração chegaram a `Promote.Completed` — nunca em encerramento parcial.
- A operação de assignee é não-bloqueante: falha ao adicionar assignee não interrompe o Plan Bootstrap.
- Comment de encerramento é idempotente: se a tracking issue já estiver fechada, não reabre.

## Scope

### Step 1 — Assignees no Plan Bootstrap
Ao criar cada GitHub Issue de feature durante o Plan Bootstrap, preencher `assignees` com o login do usuário autenticado (`gh api user --jq '.login'`). Idem para a tracking issue da iteração.

### Step 2 — Auto-close no Iteration Closure
No step de Iteration Closure do downstream-agent, após confirmar que todos os DS-IDs chegaram a `Promote.Completed`, executar:
1. `gh issue comment <tracking-issue> --body "<sumário>"` com DS-IDs, PRs e data
2. `gh issue close <tracking-issue>`

### Fora de escopo
- Auto-close em caso de falha parcial (escopo: apenas encerramento com sucesso total)
- Notificações externas (Slack, email)
- Assignees variáveis por DS-ID (mesmo assignee para toda a iteração)

## Critérios de aceite

| # | Critério |
|---|---|
| 1 | Após `Promote.Completed` de todas as issues da iteração, a tracking issue é fechada automaticamente com comment contendo DS-IDs, PRs e data |
| 2 | Cada issue de feature criada no Plan Bootstrap tem assignee preenchido com o login do Context Engineer |
| 3 | A tracking issue também tem assignee preenchido no momento da criação |
| 4 | Auto-close não ocorre se algum DS-ID ainda não chegou a `Promote.Completed` |

## Related Artifacts

- Business Signal: [#135](https://github.com/produtoreativo/payments-api/issues/135)
- Business Intent: `prodops/artifacts/business-intents/PI-RT-004.md`
- GitHub Issue: [#145](https://github.com/produtoreativo/payments-api/issues/145)
- Bootstrap skill: `prodops/skills/bootstrap/`
- Downstream agent instructions: `prodops/skills/downstream/`
