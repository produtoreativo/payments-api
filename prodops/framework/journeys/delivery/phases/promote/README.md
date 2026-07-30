→ [Voltar para Delivery](../../README.md)

# Promote

---

## Visão Geral

**Para que serve:** Promove a Feature do ambiente de Staging (efêmero por Feature) para o ambiente de Sandbox (compartilhado, Release Candidate). Inicia somente após Ship.Completed.

**O que Promote NÃO é:** Promote NÃO publica em Production. Production está fora da Delivery Journey.

**Como funciona:**

```
Confirmar Ship.Completed → Confirmar Quality Gates e Validate
→ Confirmar riscos resolvidos
→ Promover Feature de Staging para Sandbox
→ Registrar no Release Trail
```

**Guardrails principais:**

- Não promover com evidência faltante
- Não iniciar antes de Ship.Completed
- Não aceitar risco alto silenciosamente — documentar ou mover para follow-up
- Nunca substituir histórico do Release Trail; sempre adicionar nova entrada
- Não promover para Production — o destino do Promote é Sandbox

**Posição no fluxo:**

```
CI Async  →  Ship → Validate → [Promote]
```

---

**Objetivo:** promover a Feature do ambiente de Staging para o ambiente de Sandbox (Release Candidate), com evidência registrada.

## Ambientes

| Ambiente | Tipo | Propósito |
|---|---|---|
| Staging | Efêmero por Feature/OBC | Validação exclusiva da Feature. Destruído após promoção. |
| Sandbox | Compartilhado | Release Candidate. Origem da promoção para Production. |
| Production | Operacional | Fora da Delivery Journey. |

Promote leva a Feature de **Staging → Sandbox**.

Sandbox recebe apenas Features promovidas pelo Ship. Production pertence ao processo operacional posterior.

## Capabilities do Promote

| Capability | Descrição |
|---|---|
| **Promotion Gates** | Verificação de todos os critérios antes da promoção |
| **Environment Promotion** | Mover a Feature de Staging para Sandbox (Release Candidate) |
| **Release Trail** | Registro definitivo da promoção com evidências |
| **Rollback Readiness** | Confirmar que o plano de rollback está documentado |

## Pré-condição

Ship.Completed emitido para o work-item: Feature disponível em Staging e merge confirmado.

## Sequência no Promote

1. Confirmar que Ship.Completed foi emitido para o work-item correto.
2. Confirmar que todos os Quality Gates estão satisfeitos. Ver [`prodops/framework/journeys/delivery/phases/finish/quality-gates.md`](../finish/quality-gates.md).
3. Confirmar que Validate foi concluída e riscos estão avaliados.
4. Aceitar formalmente os riscos remanescentes ou movê-los para follow-up documentado.
5. Executar Environment Promotion (Staging → Sandbox).
6. Fechar a Task com o template. Ver [`commit-workflow/templates/task-closing.md`](../../capabilities/commit-workflow/templates/task-closing.md).
7. Registrar a promoção no Release Trail: o que foi promovido, evidências, riscos aceitos e próximos passos.

## Checklist Promote

- [ ] Ship.Completed confirmado para o work-item.
- [ ] Promotion Gates satisfeitos (Quality Gates + Done Criteria).
- [ ] Validate concluída com sucesso.
- [ ] Riscos remanescentes aceitos ou movidos para follow-up.
- [ ] Rollback Readiness confirmado — plano documentado.
- [ ] Environment Promotion executada (Staging → Sandbox).
- [ ] Task fechada com evidência.
- [ ] Release Trail atualizado com entrada de promoção.

## Fluxo completo do CI Async

```
Ship (observa PR → merge → deploy Staging)
  ↓
Validate (Runtime → Observabilidade → SLO → Business)
  ↓
Promote (Gates → Promoção Staging→Sandbox → Trail)
```

Se Validate falhar → retorna para Hack com o comportamento observado como Red Bar.
Se Promote identificar risco inaceitável → retorna para Validate ou Hack conforme a natureza do risco.

Para mecânica de execução, veja [`prodops/skills/promote/`](../../../../../skills/promote/).
