# Diligence — Jornada Transversal

## O que é

A Diligence é a jornada transversal do Framework ProdOps responsável por manter o sistema de trabalho sincronizado e consistente ao longo do ciclo de vida do produto.

> **Princípio canônico:** A Diligence é a guardiã da consistência do sistema de trabalho do ProdOps. Ela garante que o estado de cada Observable Business Contract permaneça sincronizado em todos os backlogs, ferramentas e artefatos de gestão, sem modificar o código do produto.

---

## Propósito

Fechar o gap entre as decisões produzidas pelo Assessment e o trabalho pronto para a Delivery. A Diligence não avalia o produto — isso é responsabilidade do Assessment. Ela garante que o que foi decidido esteja refletido em todos os backlogs, ferramentas e artefatos de gestão antes que a Delivery precise desse contexto.

---

## Problema que resolve

Sem a Diligence, o sistema de trabalho se fragmenta:

- Um OBC comprometido existe em `prodops/artifacts/obcs/`, mas a GitHub Issue correspondente nunca foi criada.
- Um item foi priorizado para a próxima Release, mas a Repository Tracking List não foi atualizada.
- Um risco identificado no Premortem aparece nos planos, mas não foi refletido no Icebox ou na Iteration.
- O estado do OBC evoluiu, mas as ferramentas externas (Jira, GitHub Projects) ainda mostram o estado antigo.
- Um experimento terminou com decisão tomada, mas o Roadmap não foi atualizado.

A Diligence detecta esses gaps e os corrige antes que gerem confusão, retrabalho ou decisões baseadas em estado desatualizado.

---

## Posição no Framework

```
Assessment              → produz decisões, OBCs, planos
Diligence               → sincroniza o estado dessas decisões em todos os backlogs e ferramentas
Delivery                → consome o trabalho organizado e rastreável
Operation               → alimenta novos sinais de volta ao Assessment e à Diligence
```

A Diligence observa continuamente todas as jornadas. É ativada por:

- Novas decisões do Assessment
- Conclusão de experimentos no Discovery
- Novos riscos ou incidentes no Operation
- Mudanças estratégicas no Roadmap
- Divergências detectadas entre artefatos e ferramentas

---

## Princípios

### 1. Sincronização, não implementação

A Diligence nunca implementa software. Nunca cria Pull Requests de implementação. Nunca modifica código do produto. Seu escopo é o sistema de trabalho: backlogs, OBCs, ferramentas de gestão, artefatos ProdOps.

### 2. OBC como identificador permanente

O OBC nasce quando a Intent entra no Business Intent Backlog (fluxo global) ou no Product Intent Backlog (fluxo local). A partir desse ponto, acompanha o trabalho por toda sua vida. A Diligence usa o OBC como âncora para todas as verificações de consistência. Cada ferramenta, cada backlog, cada artefato deve ser rastreável até um OBC.

### 3. Estado único, múltiplas representações

Um OBC committed tem um único estado canônico — registrado em `prodops/artifacts/obcs/`. GitHub Issues, Jira Cards, Azure DevOps Work Items são representações operacionais desse estado em ferramentas diferentes. A Diligence garante que essas representações estejam sincronizadas com a fonte de verdade.

### 4. Continuidade, não cerimônia

A Diligence não tem início e fim por ciclo. Acompanha o produto enquanto ele existir. Não é uma reunião semanal ou um ritual de sprint. É uma verificação contínua que ocorre toda vez que o estado do sistema muda.

### 5. Rastreabilidade ponta a ponta

Intent → OBC → Issue → PR → Release → Operation. A Diligence garante que cada elo dessa cadeia seja rastreável. Um gap em qualquer ponto é uma inconsistência que precisa ser corrigida.

---

## Responsabilidades

### Sincronização de backlogs

Manter o estado de cada OBC sincronizado entre Repository Tracking List, Product Intent Backlog, Icebox, Iteration Backlog, Iteration Plan e as ferramentas externas correspondentes.

### Criação e atualização de representações operacionais

Criar ou atualizar GitHub Issues, Jira Cards e outras representações operacionais quando um OBC avança para o Iteration Backlog ou Iteration Plan.

### Verificação de pré-requisitos da Delivery

Garantir que todos os pré-requisitos obrigatórios estejam satisfeitos antes que um item entre em Delivery: OBC committed, BDD Feature committed, entrada no Iteration Plan, riscos documentados. Verificar se existe Reliability Plan — quando existe, confirmar que foi revisado antes da decisão de readiness (recomendado, não obrigatório).

### Detecção de divergências

Identificar proativamente gaps entre o estado dos OBCs nos artefatos ProdOps e o estado nas ferramentas externas.

### Evolução dos artefatos de gestão

Atualizar artefatos de gestão (Iteration Plan, Product Intent Backlog, entradas de Roadmap) quando decisões do Assessment ou resultados do Discovery mudam o estado do trabalho.

---

## O que a Diligence NÃO faz

- Não implementa software ou modifica código do produto.
- Não cria Pull Requests de implementação.
- Não toma decisões de produto — isso é responsabilidade do Assessment.
- Não substitui o Assessment em avaliações de risco ou definição de critérios.
- Não executa fases da Delivery (Bootstrap, Hack, Sync, Finish).

---

## Relação com as demais jornadas

| Jornada | Relação com Diligence |
|---|---|
| Discovery | A Diligence atualiza backlogs e ferramentas quando experimentos terminam com decisão tomada |
| Assessment | A Diligence sincroniza as decisões do Assessment nos backlogs e representações operacionais |
| Delivery | A Diligence garante que o trabalho chegue à Delivery organizado, rastreável e com pré-requisitos satisfeitos |
| Operation | A Diligence recebe sinais de novos riscos e incidentes para atualizar backlogs e planos |

---

## Sistema de trabalho governado

A Diligence governa a hierarquia completa de backlogs do Framework ProdOps.

**Fluxo global (Portfolio → Produto):**

```
Global Tracking List
      │  reconhecido como Intent
      ▼
Business Intent Backlog   ← OBC Draft nasce aqui
      │
      ▼
Roadmap                   ← vive fora do repositório
      │
      ▼
Platform Release
      │  aceito pelo Product Owner
      ▼
Product Intent Backlog
```

**Fluxo local (Produto):**

```
Repository Tracking List
      │  Premortem + Reliability Plan + Owner Approval
      ▼
Product Intent Backlog    ← OBC Draft nasce aqui se ainda não existe
```

**Convergência — fluxo de Delivery:**

```
Product Intent Backlog
      │
      ▼
Icebox                    ← Discovery Downstream ocorre aqui
      │  OBC mínimo validado
      ▼
Iteration Backlog
      │  OBC committed + BDD committed
      ▼
Iteration Plan
      │
      ▼
Delivery
```

→ [Definições e modelo oficial da hierarquia](../../framework/backlogs.md)

---

## Evolução

A Diligence pode evoluir para incluir verificações automatizadas, dashboards de consistência e alertas automáticos quando divergências são detectadas entre artefatos. A automação serve a jornada — não a substitui. A decisão de corrigir uma divergência sempre envolve julgamento humano sobre o impacto no produto e no trabalho em andamento.
