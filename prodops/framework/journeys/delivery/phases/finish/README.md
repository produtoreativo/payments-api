→ [Voltar para Delivery](../../README.md)

# Finish

---

## Visão Geral

**Para que serve:** É a porta de saída do CI Sync. Entrega um Pull Request completamente autônomo — um PR que percorre todo o CI Async (Ship → Validate → Promote) sem intervenção humana.

**O que Finish NÃO é:** Finish NÃO entrega software. Finish entrega o PR.

**Como funciona:**

```
Revisar escopo do diff → Executar lint + build + testes + contratos
→ Confirmar artefatos ProdOps atualizados → Evidência no Release Trail
→ Publicar PR → Auto-approval → Auto-merge → Verificar workflows
→ Confirmar aptidão do repositório para execução automática
```

**Se qualquer requisito não puder ser satisfeito: Finish NÃO conclui. Interrompe para investigação.**

**Guardrails principais:**

- Não marcar completo sem evidência
- Não esconder testes pulados — registrar o motivo
- Não expandir escopo durante o Finish
- Se auto-approval ou auto-merge falhar: bloqueio — investigar antes de prosseguir

**Posição no fluxo:**

```
CI Sync  →  Bootstrap → Hack → Sync → [Finish]
                                               ↓
CI Async →                               Ship → Validate → Promote
```

---

Objetivo: entregar um Pull Request completamente autônomo — todos os Quality Gates satisfeitos, PR criado com evidências completas, auto-approval e auto-merge configurados, repositório apto para execução automática.

Checklist:
- [ ] Lint passa (`npm run lint` exit 0).
- [ ] Todos os testes passam (unit + acceptance).
- [ ] Build passa.
- [ ] Nenhum TODO ou FIXME não resolvido introduzido nesta mudança.
- [ ] Definition of Done satisfeita. Ver [definition-of-done.md](../../../../../templates/engineering/definition-of-done.md).
- [ ] Evidência acrescentada ao Release Trail.
- [ ] PR criado com template preenchido.
- [ ] Auto-approval executado (ou resultado registrado se não suportado).
- [ ] Auto-merge habilitado (ou resultado registrado se não suportado).
- [ ] Workflows existentes verificados e válidos.
- [ ] Repositório confirmado apto para execução automática.

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
8. Executar auto-approval no PR (quando o repositório suportar).
9. Habilitar auto-merge no PR (quando o repositório suportar).
10. Verificar workflows existentes e aptidão do repositório para execução automática.
11. Marcar a Task como concluída com o template [task-closing.md](../../capabilities/commit-workflow/templates/task-closing.md).

Checklist completo: [capabilities/commit-workflow/README.md — Checklist do Finish](../../capabilities/commit-workflow/README.md#checklist-do-finish)

Template de PR: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

Para mecânica de execução, veja [`prodops/skills/finish/`](../../../../../skills/finish/).
