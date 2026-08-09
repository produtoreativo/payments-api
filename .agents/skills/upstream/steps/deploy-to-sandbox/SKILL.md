---
name: upstream/deploy-to-sandbox
description: Fazer deploy de uma branch de experimento em um ambiente de sandbox real na nuvem, sem o rigor Downstream. Use quando um experimento precisa validar comportamento contra um provedor externo real que não pode ser exercitado localmente.
---

# UPSTREAM / DEPLOY TO SANDBOX

Use este step para fazer deploy de um experimento em infraestrutura de nuvem real para validação Upstream.

Sem OBC committed, sem Release Trail, sem gates Downstream — o objetivo é aprendizado.

## Quando usar

- A hipótese do experimento requer uma resposta real do provedor (ex: provedor externo de pagamentos, webhooks, ciclo de vida de dados)
- Simulação local ou modo mock são insuficientes para responder à pergunta do experimento
- O time precisa de uma URL acessível para demonstrar ou validar comportamento com dados reais

## Pré-condições

Antes de executar este step, confirmar:

- [ ] Experimento registrado em `prodops/artifacts/experiments/`
- [ ] Branch do experimento existe no repositório
- [ ] GitHub Environment `experiment` existe com os secrets necessários (ver setup local do produto)
- [ ] Identidade cloud para deploy de experimento existe (ver infraestrutura local do produto)

## Setup necessário (uma vez por produto — definido na área local do produto)

### 1. GitHub Environment

Criar um GitHub Environment chamado `experiment`:

- Sem revisores obrigatórios (intencional — bypass do gate de aprovação)
- Secrets: definidos pelo produto (chaves de API do provedor, tokens de webhook, secrets de admin)
- Ver: `prodops/skills/local/` para instruções de setup específicas do produto

### 2. Identidade cloud

Fazer deploy do template de identidade cloud uma vez (definido pelo produto):

```bash
# Comando específico do produto — ver skills locais do produto ou scripts de infra
```

Isso cria uma identidade com escopo apenas para recursos `experiment-*`. Não pode afetar stacks de staging ou produção.

## Como fazer o deploy

Trigger do workflow de experimento via `workflow_dispatch` (workflow definido pelo produto):

| Input | Valor |
|---|---|
| `branch` | nome da branch do experimento |
| `experiment_id` | ex: `EXP-007` |
| `action` | `deploy` |

O workflow executa uma verificação rápida (lint + build apenas — sem testes de aceitação). O gate é intencionalmente mais leve que o de staging.

## O que é deployado

Todos os recursos de nuvem têm prefixo `experiment-*`, isolados de `staging-*` e `production-*`:

- Compute (Lambda, container ou equivalente)
- Datastore (tabelas de banco, filas)
- Infraestrutura de eventos

O isolamento garante que recursos de experimento não possam afetar staging ou produção.

## Após o deploy

Registrar o deploy de sandbox no trail do experimento:

```markdown
## Sandbox Deploy Record

| Campo | Valor |
|---|---|
| Data do deploy | YYYY-MM-DD |
| Branch | branch-name |
| API URL | https://... |
| Disparado por | nome |
```

## Obrigação de teardown

O stack do experimento **deve ser removido** quando o experimento for concluído.

Trigger do workflow de experimento com `action=teardown`. Todos os recursos do experimento serão deletados.

Não deixar stacks de experimento rodando após o fim do experimento. Eles acumulam custo e não são monitorados por nenhum SLO operacional.

## O que isto NÃO é

- Não é um ambiente de staging.
- Não é um gate de release.
- Evidências coletadas aqui são evidências Upstream — não substituem a validação Downstream.
- Não avança trabalho no Release Trail.
