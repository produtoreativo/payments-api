→ [Voltar para Delivery](../../README.md)

# Finish

---

## Visão Geral

**Para que serve:** É a porta de saída do CI Sync. Garante que todos os quality gates passam antes de marcar o trabalho como pronto para ship — lint, build, testes, Definition of Done e evidência registrada no Release Trail.

**Como funciona:**

```
Revisar escopo do diff → Executar lint + build + testes
→ Confirmar artefatos ProdOps atualizados → Evidência no Release Trail → Publicar PR
```

**Guardrails principais:**

- Não marcar completo sem evidência
- Não esconder testes pulados — registrar o motivo
- Não expandir escopo durante o Finish

**Posição no fluxo:**

```
CI Sync  →  Bootstrap → Hack → Sync → [Finish]
                                               ↓
CI Async →                               Ship → Validate → Promote
```

---

Objetivo: confirmar que todos os Quality Gates passam antes de marcar o trabalho como pronto para ship.

Checklist:
- [ ] Lint passa (`npm run lint` exit 0).
- [ ] Todos os testes passam (unit + acceptance).
- [ ] Build passa.
- [ ] Nenhum TODO ou FIXME não resolvido introduzido nesta mudança.
- [ ] Definition of Done satisfeita. Ver [definition-of-done.md](../../../../../templates/engineering/definition-of-done.md).
- [ ] Evidência acrescentada ao Release Trail.

Uma implementação não sai do Finish até que todos os itens estejam marcados.

---

## Commit Workflow no Finish

O Finish é responsável por:

1. Validar histórico de commits (todos seguem Conventional Commits).
2. Executar formatter + lint (sem erros).
3. Executar build (sem erros TypeScript).
4. Executar testes unitários e de aceitação.
5. Validar contratos (BDD Features, OpenAPI, AsyncAPI).
6. Preencher o template de PR com evidências.
7. Publicar o Pull Request.
8. Marcar a Task como concluída com o template [task-closing.md](../../capabilities/commit-workflow/templates/task-closing.md).

Checklist completo: [capabilities/commit-workflow/README.md — Checklist do Finish](../../capabilities/commit-workflow/README.md#checklist-do-finish)

Template de PR: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

Para mecânica de execução, veja [`prodops/skills/finish/`](../../../../../skills/finish/).
