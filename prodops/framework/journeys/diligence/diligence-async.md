# Diligence Async

## Natureza

Diligence Async é o ciclo **assíncrono e proativo** do ProdOps Diligence.

- **Assíncrono:** não depende de uma transação específica em andamento em outra jornada.
- **Proativo:** iniciado por varredura periódica agendada ou por suspeita de drift — não espera um evento externo.
- **Orientado a drift:** seu objetivo é detectar divergências acumuladas que escaparam à verificação síncrona.
- **Não bloqueante por padrão:** produz relatório de consistência e executa reparos autorizados; escalona quando reparo requer decisão de produto.

```
diligence-async: Scan → Flag → Repair
```

---

## Propósito

Diligence Async produz:
- Relatório de consistência entre artefatos Markdown e backlogs externos
- Divergências classificadas com severidade e ação corretora identificada
- Artefatos e ferramentas restaurados à consistência para itens reparáveis
- Escalações registradas para itens que requerem decisão humana

---

## Modelo de acionamento

O Diligence Async é acionado por:

| Acionador | Frequência típica |
|---|---|
| Varredura periódica agendada | Semanal ou conforme configuração |
| Suspeita de drift reportada por agente ou usuário | Sob demanda |
| Mudança em documentação normativa | Automático |
| Solicitação explícita de auditoria de consistência | Sob demanda |

**O Diligence Async não é acionado por eventos de operação específica** — esse é o papel do Diligence Sync.

---

## Fases

### Scan

**Objetivo:** Leitura completa do sistema de trabalho e identificação de divergências, distinguindo ausência legítima de relação incompleta.

**O que faz:**
- Lê todos os OBCs ativos em `prodops/artifacts/obcs/` e compara o estado declarado com os backlogs externos e ferramentas
- Compara o GitHub Workspace (Labels, Fields, Views, Projects) com a Canonical Specification em `prodops/framework/github-workspace.md`
- Lê Work Items abertos e verifica se referenciam artefatos válidos
- Identifica gaps por categoria

**Distinção crítica — ausência legítima vs. relação incompleta:**

| Situação | Classificação |
|---|---|
| OBC em Draft, sem operação ativa autorizada, sem Work Item | **Ausência legítima** — não é divergência |
| Business Signal registrado, sem investigação ativa, sem Work Item | **Ausência legítima** — não é divergência |
| OBC Committed com operação de Delivery ativa, sem Work Item | **Relação incompleta** — divergência |
| OBC Committed no Iteration Plan, Work Item ainda aberto após Release Operational | **Relação incompleta** — divergência (Close não foi executado) |
| Work Item aberto referenciando OBC inexistente | **Relação inválida** — divergência |

**O que NÃO faz:**
- Não repara durante o Scan — apenas identifica
- Não cria artefatos, Work Items ou Issues durante o Scan
- Não classifica trilhas históricas como divergências normativas

**Saída:** Lista de gaps com OBC afetado, tipo de gap, severidade e natureza (ausência legítima ou relação incompleta/inválida).

→ [steps/scan/SKILL.md](../../../skills/diligence/diligence-async/steps/scan/SKILL.md)

---

### Flag

**Objetivo:** Classificar cada divergência encontrada no Scan e registrar para ação.

**O que faz:**
- Classifica cada divergência com: OBC afetado, tipo, severidade, ação corretora sugerida, responsável
- Registra itens reparáveis automaticamente pela Diligence
- Marca como `BLOQUEADO` itens que exigem decisão de produto ou humana, identificando a jornada responsável (Assessment, Product Owner, Tech Lead)
- Produz relatório de consistência intermediário

**O que NÃO faz:**
- Não executa reparos — apenas sinaliza
- Não decide qual ação tomar — apenas sugere com base nas regras canônicas
- Não classifica como divergência o que foi legitimamente identificado como ausência válida no Scan

> **Nota:** A taxonomia formal de Findings (severidade, tipo, impacto) está planejada para uma versão futura. Nesta versão, o Flag produz classificação funcional suficiente para orientar o Repair sem implementar o schema completo de Finding.

**Saída:** Itens classificados por tipo de ação: reparável automaticamente / requer decisão / requer escalação.

→ [steps/flag/SKILL.md](../../../skills/diligence/diligence-async/steps/flag/SKILL.md)

---

### Repair

**Objetivo:** Executar as correções autorizadas identificadas pelo Flag.

**O que faz:**
- Para cada gap reparável pela Diligence, aplica o step correspondente do ciclo diligence-sync (`attach`, `close`, `promote`, `capture`) como sub-rotina
- Invoca Workspace Reconciliation quando o Scan detectou Workspace Drift
- Escala itens `BLOQUEADO` para a jornada responsável com registro do bloqueio
- Produz relatório final com: reparado / bloqueado / escalado

**O que NÃO faz:**
- Não modifica código do produto
- Não cria Pull Requests de implementação
- Não altera artefatos canônicos silenciosamente — toda modificação de conteúdo canônico requer autorização
- Não corrige trilhas históricas para adequá-las ao vocabulário atual
- Não toma decisões de produto no lugar do Product Owner ou Assessment

**Guardrail de modificação canônica:** Se o Repair identificar que a correção requer alterar o conteúdo de um OBC, BDD Feature, Reliability Plan ou outro artefato de Knowledge Space, deve parar e registrar a necessidade de decisão humana — não corrigir sozinho.

**Saída:** Relatório final: lista de reparos aplicados, bloqueios registrados, escalações geradas.

→ [steps/repair/SKILL.md](../../../skills/diligence/diligence-async/steps/repair/SKILL.md)

---

## Relação com Workspace Reconciliation

O ciclo Diligence Async invoca a Capability **Workspace Reconciliation** quando o Scan detecta sinais de Workspace Drift: labels ausentes, campos faltando, projetos fora da spec.

**Workspace Reconciliation é uma Capability invocada como sub-rotina — não é uma fase do Diligence Async.** O Async não chama Workspace Reconciliation em toda varredura — apenas quando o Scan detecta drift explícito na infraestrutura.

```
Diligence Async — Repair (gap: label ausente)
       │
       └──→ Workspace Reconciliation (Capability)
                  Inspect → Reconcile → Verify
                  └──→ retorna ao Repair
```

→ [workspace-reconciliation.md](workspace-reconciliation.md)

---

## Capabilities utilizadas

| Capability | Fase |
|---|---|
| [Divergence Detection](capabilities/README.md) | Scan, Flag |
| [Artifact Evolution](capabilities/README.md) | Repair |
| [Backlog Synchronization](capabilities/README.md) | Repair |
| [Work Item Management](capabilities/README.md) | Repair |
| [Readiness Verification](capabilities/README.md) | Scan (verificação de pré-condições) |
| [Workspace Reconciliation](workspace-reconciliation.md) | Invocada pelo Repair quando Workspace Drift detectado |
