---
name: diligence/flag
description: Classify divergences from Scan and register them as pending Diligence items with severity and corrective action. Does not repair — only signals.
---

# DILIGENCE ASYNC → FLAG

Execute only the Flag step of the Diligence Async flow.

**Responsabilidade:** classificar as divergências produzidas pelo Scan e registrá-las como itens pendentes de Diligence. Flag não repara — apenas sinaliza com suficiente contexto para que Repair possa agir sem ambiguidade.

## Ação

### 1. Ler o relatório do Scan

Obter a lista de divergências produzida pelo step Scan. Se Scan não foi executado neste ciclo, executá-lo primeiro.

### 2. Classificar cada divergência

Para cada divergência, classificar a ação corretora e o responsável:

| Tipo de gap | Ação | Quem pode reparar |
|---|---|---|
| OBC committed sem Work Item | Attach — criar Work Item | Diligence |
| Issue com labels canônicas fora do projeto gerenciado | Attach — adicionar Issue ao projeto | Diligence |
| Item no Iteration Plan sem BDD Feature | Bloqueio — BDD Feature deve ser criada antes | Delivery (Downstream readiness) |
| Item no Iteration Plan sem riscos documentados | Bloqueio — documentar riscos em risks.md | Assessment |
| Work Item aberto com OBC Operational | Close — fechar Work Item | Diligence |
| OBC committed ausente do Iteration Plan | Promote — verificar pré-requisitos e promover | Diligence |
| Artefato de gestão desatualizado | Artifact Evolution — atualizar artefato | Diligence |

### 3. Registrar itens pendentes

Para cada divergência reparável pela Diligence, registrar:

```
[ ] [SEVERITY] OBC: <obc-id> — Gap: <gap> — Ação: <ação corretora>
```

Para divergências que bloqueiam e exigem outra jornada, registrar com status `BLOQUEADO`:

```
[B] [SEVERITY] OBC: <obc-id> — Gap: <gap> — Dono: <jornada responsável> — Próxima ação: <ação>
```

### 4. Priorizar para Repair

Ordenar itens reparáveis pela Diligence por severidade: Alta → Média → Baixa.

## Eventos — emissão obrigatória

Antes de classificar qualquer divergência, emitir:

```json
{
  "event": "Diligence.Flag.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-flag-agent" },
  "payload": {}
}
```

Após todas as divergências classificadas e lista de itens pendentes produzida, emitir:

```json
{
  "event": "Diligence.Flag.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "diligence-flag-agent" },
  "payload": {
    "items-flagged": <número>,
    "items-blocked": <número>
  }
}
```

## Post-conditions

Concluído quando:

- Todos os gaps do Scan foram classificados
- Itens reparáveis pela Diligence estão listados com severidade e ação concreta
- Itens bloqueados estão registrados com jornada responsável e próxima ação
- Nenhuma correção executada

## Guardrails

- Não reparar nada neste step — apenas sinalizar.
- Não inventar ações corretoras que exigem decisão de produto.
- Registrar bloqueios explicitamente — silêncio sobre um gap não resolvido é uma inconsistência nova.
- Não escalar um gap para Assessment sem verificar que o artefato realmente está ausente.

## Out of scope

- `flag` **não** executa correções — isso é Repair.
- `flag` **não** toma decisões de prioridade — registra a severidade técnica, não a decisão de negócio.
- `flag` **não** lê OBCs diretamente — consome o relatório do Scan.
