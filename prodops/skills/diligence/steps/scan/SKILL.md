---
name: diligence/scan
description: Read all active OBCs and compare declared state with backlogs and external tools. Produces a divergence list. Does not repair — only identifies gaps.
---

# DILIGENCE ASYNC → SCAN

Execute only the Scan step of the Diligence Async flow.

**Responsabilidade:** varrer todos os OBCs ativos e identificar divergências entre o estado canônico (Markdown) e o estado nas ferramentas externas e backlogs. Scan não repara nada — produz um relatório de gaps para que Flag possa classificá-los e Repair possa corrigi-los.

## Ação

### 1. Verificar Business Signals na tracking list

Ler `prodops/artifacts/product/backlogs/tracking-list.md` e inspecionar a coluna `Issue` de cada entrada:

```
Para cada linha da tabela:
  - Se Issue == "—" ou ausente → divergência: Business Signal sem GitHub Issue
  - Se Issue == "#NNN" → verificar via gh se o Issue existe e está no estado correto
```

```bash
gh issue view <number> --repo produtoreativo/payments-api --json state,title
```

| Sinal | Divergência |
|---|---|
| Coluna `Issue` vazia ou `—` | Business Signal sem Issue — Attach obrigatório |
| Issue fechado com signal ainda `Aberto` | Estado do Issue diverge do status na tracking list |
| Issue inexistente (404) | Issue referenciado não existe — Attach obrigatório |

Registrar cada gap com a linha afetada da tracking list e a ação corretora.

### 2. Listar todos os OBCs ativos

```bash
ls prodops/artifacts/business/obcs/
```

Para cada OBC: ler o arquivo e extrair o estado declarado (Draft, Committed, In Delivery, Operational).

### 4. Verificar consistência de cada OBC

Para cada OBC ativo, verificar os seguintes checks:

| Check | Esperado | Sinal de divergência |
|---|---|---|
| Work Item ativo | Existe GitHub Issue aberto referenciando o OBC | OBC committed sem Issue correspondente |
| BDD Feature | Existe `prodops/artifacts/business/bdd/<obc-id>.feature` quando OBC está em Iteration Plan | Item no Iteration Plan sem BDD Feature committed |
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

### 5. Produzir relatório de divergências

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

## Post-conditions

Concluído quando:

- Todos os OBCs ativos foram verificados
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
