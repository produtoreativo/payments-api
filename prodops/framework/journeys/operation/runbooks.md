# Runbooks — Definição Canônica

Um **Runbook** é um procedimento operacional estruturado que define como responder a
um incidente, falha ou condição anômala específica em produção. Runbooks são parte
da Jornada Operation e complementam o Reliability Plan, os SLOs e os planos de
observabilidade do produto.

> Runbooks de produto pertencem ao consumidor e devem ser criados em
> `prodops/artifacts/runbooks/`. Esta definição canônica descreve a estrutura e
> os requisitos de um Runbook dentro do ProdOps Framework.

---

## Propósito

Um Runbook transforma um cenário de risco identificado no pré-mortem em um
procedimento executável. Cada Runbook:

- Reduz o tempo médio de recuperação (MTTR) ao eliminar diagnóstico ad-hoc.
- Distribui o conhecimento operacional entre todos os membros da equipe.
- Preserva a rastreabilidade entre incidentes, decisões e evidências.
- Vincula-se ao ciclo de melhoria contínua via Postmortem e Assessment.

---

## Relação com a Jornada Operation

```
Reliability Plan (premortem)
       ↓ identifica cenários de risco
Runbook
       ↓ define resposta operacional
Incidente em produção
       ↓ executa o Runbook
Operational Trail (registro)
       ↓ alimenta
Postmortem
       ↓ melhora
Reliability Plan (próximo ciclo)
```

---

## Pré-condições para criar um Runbook

Antes de criar um Runbook, os seguintes pré-requisitos devem estar atendidos:

- O cenário de risco correspondente está documentado no Premortem do Reliability Plan.
- Os sinais de alerta do cenário estão mapeados para Observable Events dos OBCs.
- A equipe operacional tem acesso às ferramentas de diagnóstico necessárias (logs, filas, datastores).
- Há clareza sobre quem possui o Runbook (ownership) e quem pode autorizar ações de contenção.

---

## Sinais de ativação

Um Runbook é ativado quando:

- Um alerta de SLO ou SLI é disparado e o cenário corresponde a um Runbook documentado.
- Um operador ou agente detecta sintomas que correspondem aos sinais de alerta do Runbook.
- O suporte recebe relatos de clientes que correspondem ao padrão de falha descrito.
- A telemetria de observabilidade revela eventos de falha acima do threshold baseline.

---

## Estrutura canônica de um Runbook

### Cabeçalho

```markdown
## RB-NNN — <Título descritivo do cenário>

**Cenário de origem:** <Referência ao Premortem — ex: PRE-NNN>

**Quando usar:** <Condição objetiva que ativa este Runbook>

**Proprietário:** <Time ou papel responsável>

**SLO relacionado:** <SLO ou SLI que este Runbook protege>

**OBC relacionado:** <OBC cujos eventos de falha disparam este Runbook>
```

### Sinais de alerta

Listar sintomas observáveis que confirmam que este Runbook se aplica:

- Eventos de falha específicos no sistema de observabilidade.
- Mensagens de log características.
- Comportamento anômalo de filas, datastores ou integrações externas.
- Volume de erros acima do threshold baseline.

### Diagnóstico

Comandos e consultas para confirmar a causa raiz:

```bash
# Consultar <primary-datastore> para identificar registros afetados
# Verificar filas de <event-broker> — DLQ e fila principal
# Consultar logs de <observability-platform> por correlação
# Verificar status do <external-provider>
```

### Contenção imediata

Ações para estabilizar o sistema e impedir agravamento:

1. Isolar ou proteger registros em estado inconsistente.
2. Pausar fluxos automáticos que possam agravar a situação.
3. Comunicar escopo e impacto imediato ao time.

### Mitigação

Ações para reduzir o impacto enquanto a causa raiz é resolvida:

1. Ação de mitigação prioritária.
2. Verificação de efeitos colaterais.
3. Escalada se necessário.

### Recuperação

Ações para restaurar o estado correto do sistema:

1. Reprocessar eventos ou registros afetados.
2. Verificar integridade dos dados.
3. Confirmar que o fluxo normal foi restaurado.

### Rollback

Condições e procedimento para reversão segura, se aplicável:

- Quando o rollback é preferível à recuperação in-place.
- Estados de dados que devem ser reconciliados após rollback.
- Checklist de verificação pós-rollback.

### Verificação pós-resolução

Checklist para confirmar que o incidente foi resolvido:

- [ ] Evento de falha não aparece mais acima do baseline.
- [ ] Registros afetados estão no estado esperado.
- [ ] Fluxo downstream não foi afetado ou foi recuperado.
- [ ] Volume de DLQ retornou ao baseline.

### Comunicação

- [ ] Time afetado notificado.
- [ ] Stakeholders comunicados se o impacto for externo.
- [ ] Status page atualizado se aplicável.

### Evidências

Registrar para o Postmortem:

- Horário de detecção e de resolução.
- Comandos executados e seus outputs relevantes.
- Decisões tomadas e justificativas.

### Closure

**Registrar em:** `prodops/artifacts/trails/operational-trail.md` (append-only).

Campos obrigatórios: data/hora, Runbook executado, causa raiz identificada, decisão tomada, escopo de impacto, evidências.

**Abrir Postmortem se:**

- O incidente causou impacto externo a clientes.
- O MTTR excedeu o threshold definido no Reliability Plan.
- A causa raiz não estava prevista no Premortem.

→ Template de Postmortem: `prodops/templates/operation/postmortem.md`

---

## Vinculação com OBCs e SLOs

Cada Runbook deve estar vinculado a:

- **OBC:** O OBC cujos Observable Events disparam este Runbook (eventos de falha `*_failed`, `*_rejected`).
- **SLO:** O SLO que este Runbook protege (ex: taxa de erro < X%, MTTR < Y min).
- **Observabilidade:** O dashboard ou alerta que monitora os sinais de ativação.

---

## Ownership e atualização

- **Proprietário do Runbook:** o time responsável pelo componente ou fluxo afetado.
- **Revisão:** após cada execução do Runbook, verificar se o procedimento permanece válido.
- **Atualização obrigatória:** quando o componente, a integração ou o fluxo coberto pelo Runbook for modificado em uma entrega Downstream.

---

## Template de Runbook de produto

Para criar um Runbook de produto, use:
`prodops/templates/operation/runbook.md`

Runbooks de produto ficam em: `prodops/artifacts/runbooks/`
