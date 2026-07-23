---
name: diligence/promote
description: Advance an OBC through the backlog hierarchy (Icebox → Iteration Backlog → Iteration Plan), checking prerequisites at each transition. Use after Attach has confirmed a Work Item exists.
---

# DILIGENCE SYNC → PROMOTE

Execute only the Promote step of the Diligence Sync flow.

**Responsabilidade:** mover o item pela hierarquia de backlogs verificando os pré-requisitos de cada transição. Promote não decide a prioridade — o Product Owner decide. Promote verifica se os artefatos necessários existem e registra o resultado da verificação.

## Ação

### 1. Identificar posição atual na hierarquia

Localizar o estado atual do OBC:
- `prodops/artifacts/plans/iteration-plan.md` (Iteration Plan)
- `prodops/artifacts/product/backlogs/iteration-backlog.md` (Iteration Backlog)
- `prodops/artifacts/product/backlogs/icebox-backlog.md` (Icebox)

### 2. Verificar pré-requisitos da transição alvo

**Transição → Iteration Backlog:**
- [ ] OBC committed em `prodops/artifacts/obcs/`

**Transição → Iteration Plan:**
- [ ] OBC committed
- [ ] BDD Feature committed em `prodops/artifacts/bdd/`
- [ ] Riscos documentados em `prodops/artifacts/risks/risks.md`
- [ ] Reliability Plan quando aplicável (movimento de dinheiro, integração externa, mudança de SLO, risco alto/crítico, mudança de persistência ou segurança)

### 3. Executar a transição ou registrar bloqueio

Se todos os pré-requisitos estão satisfeitos:
- Atualizar o Iteration Plan com o item e status `Entrou`
- Registrar a transição no OBC (campo de histórico ou seção de status)

Se algum pré-requisito está ausente:
- Registrar o gap como bloqueio: qual artefato falta, qual jornada é responsável, qual ação concreta é necessária
- Não avançar o item
- Não inventar o artefato ausente

### 4. Commit das atualizações

```bash
git add prodops/artifacts/plans/iteration-plan.md
git add prodops/artifacts/obcs/<obc-id>.md
git commit -m "docs(diligence): promote <obc-id> to Iteration Plan"
```

## Post-conditions

Concluído quando:

- Item posicionado na hierarquia correta com pré-requisitos verificados
- **OU** bloqueio registrado com artefato faltante, jornada responsável e ação concreta identificada

## Guardrails

- Não inventar OBCs, BDD Features ou entradas de riscos para satisfazer um pré-requisito.
- Não avançar item sem verificar pré-requisitos — o gate existe para proteger a Delivery.
- Não tomar decisão de prioridade — registrar o resultado da verificação, não a decisão de negócio.
- Parar e surfacing como bloqueador quando um artefato ausente exige decisão de produto.

## Out of scope

- `promote` **não** cria o OBC nem a BDD Feature — esses são pré-requisitos que devem existir antes.
- `promote` **não** fecha Work Items — isso é Close.
- `promote` **não** detecta drift em outros OBCs — isso é Scan.
