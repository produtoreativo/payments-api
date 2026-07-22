→ [Voltar para Delivery](../../README.md)

# Promote

---

## Visão Geral

**Para que serve:** Oficializa a evolução do release com aprovação formal de PM e Tech Lead, move o artefato para o próximo ambiente e fecha o ciclo com evidência registrada no Release Trail.

**Como funciona:**

```
Confirmar Quality Gates → Verificar prontidão operacional
→ Release Approval (PM + Tech Lead) → Environment Promotion
→ Fechar Task → Registrar no Release Trail
```

**Guardrails principais:**

- Não promover com evidência faltante
- Não aceitar risco alto silenciosamente — documentar ou mover para follow-up
- Nunca substituir histórico do Release Trail; sempre adicionar nova entrada

**Posição no fluxo:**

```
CI Async  →  Ship → Validate → [Promote]
```

---

**Objetivo:** oficializar a evolução da versão com aprovação formal e evidência registrada.

## Capabilities do Promote

| Capability | Descrição |
|---|---|
| **Promotion Gates** | Verificação de todos os critérios antes da promoção |
| **Environment Promotion** | Mover o artefato para o próximo ambiente (staging → prod) |
| **Release Approval** | Aprovação formal por PM e Tech Lead |
| **Release Trail** | Registro definitivo da promoção com evidências |
| **Operational Evidence** | Evidências de operação saudável pós-promoção |
| **Release Documentation** | Notas de release, changelog, comunicado |
| **Rollback Readiness** | Confirmar que o plano de rollback está documentado e testado |

## Pré-condição

Validação concluída, riscos avaliados, prontidão operacional confirmada.

## Sequência no Promote

1. Confirmar que todos os Quality Gates estão satisfeitos. Ver [`prodops/framework/journeys/delivery/phases/finish/quality-gates.md`](../finish/quality-gates.md).
2. Verificar prontidão operacional: runbooks existem para os novos failure modes, on-call informado.
3. Executar Release Approval com PM e Tech Lead.
4. Aceitar formalmente os riscos remanescentes ou movê-los para follow-up documentado.
5. Executar Environment Promotion (staging → prod).
6. Fechar a Task com o template. Ver [`commit-workflow/templates/task-closing.md`](../../capabilities/commit-workflow/templates/task-closing.md).
7. Registrar a promoção no Release Trail: o que foi promovido, evidências, riscos aceitos e próximos passos.

## Checklist Promote

- [ ] Promotion Gates satisfeitos (Quality Gates + Done Criteria).
- [ ] Release Approval obtida (PM + Tech Lead).
- [ ] Runbooks atualizados para novos failure modes (se aplicável).
- [ ] Rollback Readiness confirmado — plano documentado.
- [ ] Environment Promotion executada.
- [ ] Task fechada com evidência.
- [ ] Release Trail atualizado com entrada de promoção.
- [ ] Operational Evidence registrada.

## Fluxo completo do CI Async

```
Ship (Preparation → Deployment)
  ↓
Validate (Runtime → Observability → SLO → Business)
  ↓
Promote (Gates → Approval → Promotion → Trail)
```

Se Validate falhar → retorna para Hack com o comportamento observado como Red Bar.
Se Promote identificar risco inaceitável → retorna para Validate ou Hack conforme a natureza do risco.

Para mecânica de execução, veja [`prodops/skills/promote/`](../../../../../skills/promote/).
