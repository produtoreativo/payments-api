# Diligence Sync

## Natureza

Diligence Sync é o ciclo **síncrono e reativo** do ProdOps Diligence.

- **Síncrono:** executa em conjunto com uma operação em andamento ou transição de estado em outra jornada.
- **Contextual:** está ligado a uma operação ou transição específica — não é periódico e não ocorre de forma independente.
- **Reativo:** acionado por eventos externos (decisão do Assessment, experimento concluído no Discovery, sinal da Operation, mudança estratégica no Roadmap).
- **Bloqueante:** pode bloquear uma transição quando os critérios canônicos não estão satisfeitos. O fluxo não avança até que a pré-condição esteja resolvida ou seja escalada.

```
diligence-sync: Capture → Attach → Promote → Close
```

---

## Propósito

Diligence Sync produz:
- OBC atualizado com o estado canônico da decisão que acionou o ciclo
- Work Item criado ou atualizado referenciando o OBC, a operação e a jornada — quando há operação ativa
- Item promovido na hierarquia de backlogs até o nível de readiness correto
- Work Item fechado quando o OBC atinge estado Operational e o Release Trail registra a entrega

---

## Modelo de acionamento

O Diligence Sync é acionado por um evento que representa uma operação em andamento ou uma transição necessária:

| Evento acionador | Fase tipicamente iniciada |
|---|---|
| Decisão de Assessment registrada | Capture |
| Experimento Discovery concluído com decisão | Capture |
| OBC pronto para avançar no backlog | Promote |
| Trabalho ativo identificado sem Work Item | Attach |
| OBC atingiu estado Operational + Release Trail confirmado | Close |
| Falha de Attach ou Promote por ausência de infraestrutura | Workspace Reconciliation (Capability invocada) |

**O Diligence Sync não é agendado periodicamente.** A varredura periódica pertence ao ciclo Diligence Async.

---

## Fases

### Capture

**Objetivo:** Registrar o estado canônico da decisão que acionou o ciclo no artefato correspondente.

**O que faz:**
- Cria ou atualiza o OBC a partir da decisão que acionou o ciclo
- Registra o estado canônico no arquivo Markdown em `prodops/artifacts/obcs/`
- Preenche ou atualiza: identificador, Business Intent de origem, estado, decisão registrada, data

**O que NÃO faz:**
- Não cria Work Items — apenas estabiliza o estado do artefato
- Não inventa conteúdo de negócio — apenas registra decisões já tomadas pela jornada competente
- Não avalia se a decisão foi correta

**Pré-condição de entrada:** Decisão, experimento ou sinal com gatilho canônico documentado.

**Saída:** OBC com estado canônico atualizado, data e decisão registradas.

→ [steps/capture/SKILL.md](../../../skills/diligence/diligence-sync/steps/capture/SKILL.md)

---

### Attach

**Objetivo:** Verificar se existe Work Item rastreável para a operação em andamento; criar se necessário.

**O que faz:**
- Verifica se existe Work Item ativo referenciando o OBC no backlog externo correspondente
- Verifica se o Work Item está no estado correto e com os campos canônicos preenchidos
- Se não existe e há operação ativa: cria um Work Item seguindo o schema canônico com `artifact_type`, `artifact_id`, `operation` e `journey` preenchidos

**Formato de título canônico:**

```
[Artifact ID]: descrição concisa
```

Exemplo: `observability-datadog: avançar para Iteration Plan`

A operação (`Promote`) e o tipo de artefato (`Local OBC`) vão nos campos e labels do Issue — **não no título**.

→ [work-item-schema.md](../../execution-mapping/work-item-schema.md)

**O que NÃO faz:**
- Não cria Issue para artefato sem operação ativa (não viola o modelo N:M)
- Não cria Issues em lote para todos os artefatos da tracking list
- Não altera conteúdo do OBC

**Quando a ausência de Work Item é legítima:** artefato passivo (Business Signal registrado, sem investigação ativa; OBC em Draft sem operação autorizada em andamento).

**Quando a ausência de Work Item é uma divergência:** há operação ativa identificada (Capture concluído, Promote em progresso, trabalho de Delivery em andamento) sem Work Item rastreável.

**Saída:** Work Item existente confirmado ou novo Work Item criado com schema completo.

→ [steps/attach/SKILL.md](../../../skills/diligence/diligence-sync/steps/attach/SKILL.md)

---

### Promote

**Objetivo:** Mover o item pela hierarquia de backlogs verificando os pré-requisitos de cada transição.

**O que faz:**
- Verifica pré-requisitos canônicos de cada transição
- Registra o status `Entrou` no nível de destino quando a transição é concluída
- Registra o bloqueio e o artefato faltante quando a transição não pode ocorrer
- Bloqueia o fluxo quando pré-condição não está satisfeita — o fluxo não avança até que seja resolvido ou escalado

**Pré-requisitos por transição:**

| Destino | Pré-requisitos obrigatórios |
|---|---|
| → Icebox | OBC transitioning de Draft para Refining; início de Discovery ativo |
| → Iteration Backlog | OBC Committed; Discovery suficiente; riscos identificados |
| → Iteration Plan | OBC Committed + BDD Feature Committed + riscos documentados |
| → Iteration Plan (com risco qualificado) | + Reliability Plan (quando: movimentação financeira, integração externa, mudança de SLO, risco alto/crítico, alteração de persistência ou segurança) |

**O que NÃO faz:**
- Não promove item sem critérios satisfeitos
- Não decide o backlog no lugar do Product Owner
- Não avalia o mérito de negócio do item

**Saída:** Transição registrada com data e pré-requisitos verificados, ou bloqueio registrado com artefato faltante identificado.

→ [steps/promote/SKILL.md](../../../skills/diligence/diligence-sync/steps/promote/SKILL.md)

---

### Close

**Objetivo:** Encerrar o ciclo de rastreamento quando o OBC atinge estado Operational.

**O que faz:**
- Fecha o Work Item quando o OBC atinge estado `Operational` e o Release Trail registra a entrega
- Atualiza artefatos de gestão (Roadmap, Product Backlog) para refletir o estado final
- Preserva o histórico: Work Item fechado com referência ao Release e ao OBC

**O que NÃO faz:**
- Não fecha Work Item prematuramente (sem confirmação do Release Trail)
- Não apaga histórico de operações anteriores
- Não altera o estado do OBC (o OBC transiciona para Operational pelo Assessment ou pelo Promote — não pelo Close)

**Saída:** Work Item fechado com referência à entrega; artefatos de gestão atualizados.

→ [steps/close/SKILL.md](../../../skills/diligence/diligence-sync/steps/close/SKILL.md)

---

## Relação com Workspace Reconciliation

O Diligence Sync pode invocar a Capability **Workspace Reconciliation** quando o step Attach ou Promote falha por ausência de label canônica, campo obrigatório ausente no Project ou drift de infraestrutura.

**Workspace Reconciliation é uma Capability invocada como sub-rotina — não é uma fase do Diligence Sync.** Após a conclusão da Workspace Reconciliation, o step que a invocou retoma sua execução.

```
Diligence Sync — Attach (falha: label ausente)
       │
       └──→ Workspace Reconciliation (Capability)
                  Inspect → Reconcile → Verify
                  └──→ retorna ao Attach
```

→ [workspace-reconciliation.md](workspace-reconciliation.md)

---

## Capabilities utilizadas

| Capability | Fase |
|---|---|
| [Backlog Synchronization](capabilities/README.md) | Capture, Promote |
| [Work Item Management](capabilities/README.md) | Attach, Close |
| [Readiness Verification](capabilities/README.md) | Promote |
| [Artifact Evolution](capabilities/README.md) | Capture, Close |
| [Workspace Reconciliation](workspace-reconciliation.md) | Invocada por Attach ou Promote quando necessário |
