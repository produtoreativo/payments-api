# Diligence Async

Diligence Async é o agrupamento proativo do ProdOps Diligence. Representa o trabalho **iniciado sem evento externo** — varredura periódica ou acionada por suspeita de divergência entre artefatos canônicos e ferramentas externas.

```
Diligence Async: Scan → Flag → Repair
```

## Propósito

Diligence Async produz:
- Relatório de consistência entre artefatos Markdown e backlogs externos
- Divergências classificadas com severidade e ação corretora identificada
- Artefatos e ferramentas restaurados à consistência

## Estágios

### Scan

Lê todos os OBCs ativos em `prodops/artifacts/business/obcs/` e compara o estado declarado com o estado nos backlogs externos e ferramentas. Identifica gaps:

- OBC committed sem Work Item correspondente
- Item no Iteration Plan sem BDD Feature committed
- OBC com estado `Operational` com Work Item ainda aberto
- Item promovido sem todos os pré-requisitos de readiness satisfeitos

Saída: lista de divergências com OBC afetado, gap identificado e severidade.

→ [steps/scan/SKILL.md](../../skills/diligence/steps/scan/SKILL.md)

### Flag

Classifica cada divergência encontrada no Scan e registra como item de Diligence pendente. Não executa reparos — apenas sinaliza com o OBC afetado, o gap, a severidade e a ação corretora sugerida. Itens que exigem decisão de produto são marcados como `BLOQUEADO` com a jornada responsável.

→ [steps/flag/SKILL.md](../../skills/diligence/steps/flag/SKILL.md)

### Repair

Executa as correções identificadas pelo Flag. Nunca modifica código de produto nem cria Pull Requests de implementação. Para cada gap reparável pela Diligence, aplica o step correspondente do ciclo diligence-sync (`attach`, `close`, `promote`, `capture`). Itens `BLOQUEADO` são escalados para a jornada responsável.

→ [steps/repair/SKILL.md](../../skills/diligence/steps/repair/SKILL.md)

## Capabilities utilizadas

| Capability | Estágio |
|---|---|
| [Divergence Detection](capabilities/README.md) | Scan, Flag |
| [Artifact Evolution](capabilities/README.md) | Repair |
| [Backlog Synchronization](capabilities/README.md) | Repair |
| [Work Item Management](capabilities/README.md) | Repair |
