→ [Voltar para Delivery](../../README.md)

# Validate

---

## Visão Geral

**Para que serve:** Prova que a entrega funciona no ambiente alvo com evidência mensurável — testes, logs, métricas e SLOs. Não assume que o que passou em local passa em produção.

**Como funciona:**

```
Identificar capability/OBC → Selecionar evidências executáveis
→ Executar validações → Confirmar BDD no ambiente alvo
→ Verificar observabilidade → Avaliar riscos → Release Trail
```

**Guardrails principais:**

- Não inventar métricas ou SLOs — se ausentes, registrar o gap no artefato ProdOps
- Preferir evidência executável sobre afirmações narrativas
- Se falhar: não promover; abrir novo ciclo Hack com o comportamento observado como Red Bar

**Posição no fluxo:**

```
CI Async  →  Ship → [Validate] → Promote
```

---

**Objetivo:** verificar a entrega em execução no ambiente alvo.

## Capabilities do Validate

| Capability | Descrição |
|---|---|
| **Smoke Tests** | Verificações rápidas de sanidade pós-deploy |
| **Runtime Contract Validation** | Confirmar que a API responde conforme o contrato OpenAPI/AsyncAPI |
| **Synthetic Monitoring** | Execução contínua de cenários reais contra o ambiente |
| **Health Checks** | Verificar disponibilidade dos componentes no ambiente alvo |
| **Observability Validation** | Confirmar logs, métricas e correlationId no ambiente real |
| **SLO Validation** | Verificar que os SLOs definidos no OBC estão sendo atendidos |
| **Business Validation** | Confirmar que o comportamento de negócio está correto em runtime |
| **Incident Signals** | Monitorar sinais de alerta e anomalias após o deploy |

## Pré-condição

O PR foi aprovado e o deploy para staging foi realizado.

## Sequência no Validate

1. Identificar a capability, OBC ou risco sendo validado.
2. Selecionar evidências executáveis: testes, logs, métricas, eventos ou SLO signals.
3. Executar os comandos de validação e registrar os resultados exatos.
4. Confirmar que os cenários do BDD Feature passam no ambiente de staging.
5. Verificar observabilidade: logs esperados emitidos, correlationId propagado, nenhum secret em log.
6. Avaliar riscos remanescentes e decidir se são aceitáveis para promoção.
7. Registrar evidência no Release Trail.

## Checklist Validate

- [ ] Smoke Tests passam no ambiente alvo.
- [ ] Cenários BDD passam no ambiente alvo.
- [ ] OBC satisfeito com evidência mensurável.
- [ ] Logs e rastreabilidade verificados no ambiente alvo (correlationId, tenantId).
- [ ] SLOs verificados — nenhuma degradação introduzida.
- [ ] Riscos remanescentes avaliados e documentados.
- [ ] Release Trail atualizado com evidência de validação.

## Se a validação falhar

Não promover. Abrir um novo ciclo Hack com o comportamento observado como Red Bar. Registrar o gap no Release Trail como "Validação com falha — retornou para Hack".

Para mecânica de execução, veja [`prodops/skills/validate/`](../../../../../skills/validate/).
