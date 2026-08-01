---
name: diligence/scan
description: Read all active OBCs and compare declared state with backlogs and external tools. Produces a divergence list. Does not repair — only identifies gaps.
---

# DILIGENCE ASYNC → SCAN

Execute only the Scan step of the Diligence Async flow.

**Responsabilidade:** varrer todos os OBCs ativos e identificar divergências entre o estado canônico (Markdown) e o estado nas ferramentas externas e backlogs. Scan não repara nada — produz um relatório de gaps para que Flag possa classificá-los e Repair possa corrigi-los.

## Ação

### 1. Verificar Business Signals na tracking list

Ler `prodops/artifacts/product/backlogs/tracking-list.md` e inspecionar a coluna `Issue` e o status de cada entrada:

```
Para cada linha da tabela:
  - Se Issue == "—" ou ausente E o status do Signal indica operação ativa (ex.: Capturando, Em triagem, Promovendo) → divergência: Business Signal com operação ativa sem Work Item rastreável
  - Se Issue == "—" ou ausente E o Signal está passivo (sem operação ativa) → não é divergência
  - Se Issue == "#NNN" → verificar via gh se o Issue existe e está no estado correto
```

> **Princípio N:M:** Um Business Signal pode ter zero ou mais Work Items ao longo de sua vida. A ausência de Issue NÃO é divergência por si só — só é divergência quando há operação ativa identificada sem Work Item rastreável.

```bash
gh issue view <number> --repo produtoreativo/payments-api --json state,title
```

| Sinal | Divergência |
|---|---|
| Signal com operação ativa E coluna `Issue` vazia ou `—` | Business Signal com operação ativa sem Work Item — Attach obrigatório |
| Signal sem operação ativa E coluna `Issue` vazia | Não é divergência — estado normal |
| Issue fechado com operação ainda em andamento | Estado do Issue diverge da operação em curso |
| Issue inexistente (404) com operação ativa | Issue referenciado não existe — Attach obrigatório |

Registrar cada gap com a linha afetada da tracking list e a ação corretora.

### 2. Verificar conformidade de Issues existentes

Listar todos os Issues abertos e verificar:

```bash
gh issue list --repo <owner>/<repo> --state all --json number,title,labels --limit 200
```

Para cada Issue, verificar:

| Check | Sinal de divergência |
|---|---|
| Título segue `[artifact-id]: descrição` | Título começa com `[Operation] —` (padrão antigo) |
| Label `operation:<valor>` presente | Issue sem label `operation:*` |
| Label `artifact-type:<valor>` presente | Issue sem label `artifact-type:*` |

Issues com padrão antigo ou sem labels canônicas → divergência `[ ] Média` — Repair atualiza título e adiciona labels.

### 3. Verificar membership de Issues no projeto gerenciado

Obter o número do projeto `ProdOps — <repo-name>`:

```bash
gh project list --owner <owner> --format json \
  | jq '.projects[] | select(.title == "ProdOps — <repo-name>") | .number'
```

Se o projeto não existir: registrar como limitação do scan — não como divergência de
OBC. Workspace Reconciliation deve ser executado primeiro.

Listar todos os itens membros do projeto gerenciado:

```bash
gh project item-list <project-number> --owner <owner> --format json \
  | jq '[.items[].content.number]'
```

Para cada Issue aberto com label `journey:*` ou `operation:*`, verificar se o número
está na lista de membros:

| Sinal | Divergência |
|---|---|
| Issue com label `journey:*` ausente da lista | Issue sem project membership — Attach obrigatório |
| Issue com label `operation:*` ausente da lista | Issue sem project membership — Attach obrigatório |

Registrar cada gap:

```
OBC: <obc-id se identificável pelo título do Issue>
Gap: Issue #N ("título") não é membro do projeto ProdOps — <repo-name>
Severidade: Média
Ação corretora: gh project item-add <project-number> --owner <owner> --url <issue-url>
Responsável: Diligence
```

Se `gh project item-list` falhar por permissão ou projeto inacessível: registrar como
limitação — não como divergência de OBC.

### 4. Listar todos os OBCs ativos

```bash
ls prodops/artifacts/obcs/
```

Para cada OBC: ler o arquivo e extrair o estado declarado (Draft, Committed, In Delivery, Operational).

### 5. Verificar consistência de cada OBC

Para cada OBC ativo, verificar os seguintes checks:

| Check | Esperado | Sinal de divergência |
|---|---|---|
| Work Item ativo | Existe GitHub Issue aberto referenciando o OBC quando há operação ativa em andamento | OBC com operação ativa identificada sem Work Item rastreável |
| BDD Feature | Existe `prodops/artifacts/bdd/<obc-id>.feature` quando OBC está em Iteration Plan | Item no Iteration Plan sem BDD Feature committed |
| Iteration Plan | OBC committed aparece no Iteration Plan | OBC committed ausente do Iteration Plan |
| Work Item fechado | Issue fechado quando OBC é Operational | OBC Operational com Issue ainda aberto |
| Riscos | Riscos documentados em `risks.md` quando OBC está em Iteration Plan | Entrada no Iteration Plan sem entrada correspondente em risks.md |
| Estado do Issue vs OBC | Estado do Issue no GitHub reflete o estado canônico do OBC | Issue fechado com OBC não-Operational; Issue aberto com labels divergentes do estado do OBC |

### 2a. Ler estado atual dos Issues no GitHub

Para cada OBC que possui referência a um GitHub Issue, consultar o estado atual via `gh`:

```bash
gh issue view <issue-number> --repo <owner>/<repo> --json state,labels,assignees,title
```

Comparar o estado retornado com o estado canônico do OBC:

| Estado do OBC | Estado esperado do Issue | Divergência se |
|---|---|---|
| Draft / Committed | open | Issue está closed |
| In Delivery | open | Issue está closed |
| Operational | closed | Issue está open |
| Qualquer | — | Título do Issue não referencia o `artifact_id` do OBC |

Se `gh` não estiver disponível ou o repositório não for acessível, registrar como limitação no relatório — não como divergência do OBC.

### 6. Produzir relatório de divergências

Para cada divergência encontrada, registrar:

```
OBC: <obc-id>
Gap: <descrição do gap>
Severidade: Alta | Média | Baixa
Ação corretora sugerida: <ação concreta>
Responsável sugerido: Diligence | Assessment | Delivery
```

**Alta:** item em Iteration Plan sem BDD Feature ou sem riscos documentados
**Média:** OBC committed sem Work Item; Work Item aberto com OBC Operational
**Baixa:** artefato de gestão desatualizado sem impacto em gate de Delivery

## Eventos — emissão obrigatória

Antes de qualquer trabalho de Scan, emitir:

```json
{
  "event": "Diligence.Scan.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-scan-agent" },
  "payload": {}
}
```

Para cada divergência encontrada, emitir **individualmente** antes de avançar para Flag:

```json
{
  "event": "Diligence.Divergence.Detected",
  "work-item-id": "<obc-work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-scan-agent" },
  "payload": {
    "obc-id": "<obc-id>",
    "gap": "<descrição do gap>",
    "severity": "Alta | Média | Baixa"
  }
}
```

Após todas as verificações concluídas (mesmo sem divergências), emitir:

```json
{
  "event": "Diligence.Scan.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-scan-agent" },
  "payload": { "divergences-found": <número> }
}
```

Não emitir `Scan.Completed` se algum check não pôde ser executado (ex.: ferramenta inacessível) — registrar o bloqueio explicitamente.

## Post-conditions

Concluído quando:

- Todos os OBCs ativos foram verificados
- Membership de Issues com labels canônicas no projeto gerenciado verificada
- Relatório de divergências produzido (pode ser vazio se não há gaps)
- Nenhuma correção executada

## Guardrails

- Não reparar nada neste step — produzir apenas o relatório.
- Não criar Work Items, atualizar OBCs ou fechar itens — isso é Repair.
- Se a ferramenta externa não está acessível (sem `gh`, sem permissão, sem número de Issue no OBC), registrar como limitação no relatório — não como divergência do OBC.
- Não marcar divergências como bloqueios sem antes confirmar que o artefato ou estado realmente está ausente/divergente.
- Verificar o estado atual do Issue via API antes de registrar divergência de estado — nunca assumir fechado ou aberto sem consultar.

## Out of scope

- `scan` **não** classifica divergências com prioridade de ação — isso é Flag.
- `scan` **não** executa correções — isso é Repair.
- `scan` **não** toma decisões de produto — gaps que exigem decisão são sinalizados para Assessment.
