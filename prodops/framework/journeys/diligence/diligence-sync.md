# Diligence Sync

Diligence Sync é o agrupamento reativo do ProdOps Diligence. Representa o trabalho **acionado por eventos externos** — decisões do Assessment, experimentos concluídos no Discovery, sinais de Operation ou mudanças estratégicas de Roadmap.

```
Diligence Sync: Capture → Attach → Promote → Close
```

## Propósito

Diligence Sync produz:
- OBC atualizado com o estado canônico da decisão que acionou o ciclo
- Work Item criado ou atualizado referenciando o OBC, a operação e a jornada
- Item promovido na hierarquia de backlogs até o nível de readiness correto
- Work Item fechado quando o OBC atinge estado Operational

## Estágios

### Capture

Cria ou atualiza o OBC a partir da decisão que acionou o ciclo. Registra o estado canônico no arquivo Markdown em `prodops/artifacts/obcs/`. Não cria Work Items — apenas estabiliza o estado do OBC.

Saída: OBC committed com estado canônico atualizado, data e decisão registradas.

→ [steps/capture/SKILL.md](../../../skills/diligence/diligence-sync/steps/capture/SKILL.md)

### Attach

Verifica se existe Work Item ativo referenciando o OBC no backlog externo correspondente. Se não existir, cria um Work Item seguindo o schema canônico com `artifact_type`, `artifact_id`, `operation` e `journey` preenchidos.

Título canônico: `[Operation] — [Artifact Type] [Artifact ID]: descrição concisa`

Exemplo: `Promote — Local OBC observability-datadog: avançar para Iteration Plan`

→ [steps/attach/SKILL.md](../../../skills/diligence/diligence-sync/steps/attach/SKILL.md)

### Promote

Move o item pela hierarquia de backlogs verificando os pré-requisitos de cada transição:

- **→ Iteration Backlog:** OBC committed
- **→ Iteration Plan:** OBC committed + BDD Feature committed + riscos documentados

Registra o status `Entrou` no Iteration Plan quando a transição é concluída. Registra o bloqueio e o artefato faltante quando a transição não pode ocorrer.

→ [steps/promote/SKILL.md](../../../skills/diligence/diligence-sync/steps/promote/SKILL.md)

### Close

Fecha o Work Item quando o OBC atinge estado `Operational` e o Release Trail registra a entrega. Atualiza artefatos de gestão (Roadmap, Product Backlog) para refletir o estado final.

→ [steps/close/SKILL.md](../../../skills/diligence/diligence-sync/steps/close/SKILL.md)

## Capabilities utilizadas

| Capability | Estágio |
|---|---|
| [Backlog Synchronization](capabilities/README.md) | Capture, Promote |
| [Work Item Management](capabilities/README.md) | Attach, Close |
| [Readiness Verification](capabilities/README.md) | Promote |
