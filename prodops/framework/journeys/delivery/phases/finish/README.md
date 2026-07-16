→ [Voltar para Delivery](../../README.md)

# Finish

---

## Visão Geral

**Para que serve:** É a porta de saída do CI Sync. Valida a qualidade
localmente com o mesmo rigor da pipeline, confirma que as regras de PR
automático estão válidas, publica os commits e abre um Pull Request
completamente autônomo — um PR que percorre todo o CI Async (Ship → Validate →
Promote) sem intervenção humana.

**O que Finish NÃO é:** Finish NÃO entrega software. Finish entrega o PR.

**Como funciona — quatro sub-passos, cada um com responsabilidade única e uma
fronteira explícita do que *não* faz** (para que cada passo seja auditável
isoladamente, sem efeitos colaterais cruzados):

```
validate → review → push origin → request
(análise    (inspeção   (git,        (abre PR com
 estática)   da pipeline) sem force)   auto aprovação)
```

1. **`validate`** — análise estática de qualidade (roda todos os passos de
   análise estática; a aceitação/integração é a única exceção dinâmica). Se algo
   falha, a correção pertence ao ciclo TDD do Hack — retorna ao `hack tdd`, não
   corrige aqui.
2. **`review`** — inspeciona a pipeline e garante que as regras para um PR
   automático estão válidas, **sem executar a pipeline**. Condição de branch
   protection ausente é um **bloqueador**.
3. **push origin** — publica os commits na branch de origem (git, sem force push).
4. **`request`** — abre o PR em modo auto aprovação (auto-merge se o CI aprovar),
   executa auto-approval, verifica os workflows existentes e confirma a aptidão
   do repositório para execução automática.

**Se qualquer requisito não puder ser satisfeito: Finish NÃO conclui. Interrompe para investigação.**

**Guardrails principais:**

- Não marcar completo sem evidência
- Não esconder testes pulados — registrar o motivo
- Não expandir escopo durante o Finish
- Se auto-approval ou auto-merge falhar: bloqueio — investigar antes de prosseguir
- Não fazer force push
- Não ativar auto aprovação sem branch protection configurada

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

## Sub-passos e responsabilidades

Cada sub-passo tem uma responsabilidade única e uma fronteira do que **não** é
sua responsabilidade. A mecânica de execução de cada um está no skill.

| Sub-passo | Responsabilidade | **Não** é sua responsabilidade | Skill |
|---|---|---|---|
| `validate` | Análise estática (format, lint, build) + aceitação/cobertura como exceção dinâmica | Commitar, escrever/ler código, escrever em artefatos, fazer push | [steps/validate](../../../../skills/finish/steps/validate/SKILL.md) |
| `review` | Confirmar que checks obrigatórios, branch protection e ausência de reviewer bloqueante permitem auto aprovação segura | Executar a pipeline, commitar, escrever/ler código, fazer push, abrir PR | [steps/review](../../../../skills/finish/steps/review/SKILL.md) |
| push origin | Publicar os commits na branch de origem, sem force push | Validar, inspecionar pipeline, abrir PR | — (git direto, ver skill router) |
| `request` | Abrir **um** PR com o template preenchido, auto-merge armado (`--auto --squash`) e auto-approval executado | Validar, fazer push, commitar, escrever/ler código | [steps/request](../../../../skills/finish/steps/request/SKILL.md) |

Ordem obrigatória: `validate` verde → `review` sem bloqueadores → push →
`request`. Se `validate` falha, a correção volta ao
[`hack tdd`](../../../../skills/hack/steps/tdd/SKILL.md) — o Finish não escreve
código de produto.

Ao final, marcar a Task como concluída com o template
[task-closing.md](../../capabilities/commit-workflow/templates/task-closing.md).

Checklist completo: [capabilities/commit-workflow/README.md — Checklist do Finish](../../capabilities/commit-workflow/README.md#checklist-do-finish)

Template de PR: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

Para mecânica de execução, veja [`prodops/skills/finish/`](../../../../../skills/finish/).
