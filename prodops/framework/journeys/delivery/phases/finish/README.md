→ [Voltar para Delivery](../../README.md)

# Finish

---

## Visão Geral

**Para que serve:** É a porta de saída do CI Sync. Valida a qualidade
localmente com o mesmo rigor da pipeline, confirma que as regras de PR
automático estão válidas, publica os commits e abre o PR em modo auto aprovação.

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
4. **`request`** — abre o PR em modo auto aprovação (auto-merge se o CI aprovar).

**Guardrails principais:**

- Não marcar completo sem evidência
- Não esconder testes pulados — registrar o motivo
- Não expandir escopo durante o Finish
- Não fazer force push
- Não ativar auto aprovação sem branch protection configurada

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

## Sub-passos e responsabilidades

Cada sub-passo tem uma responsabilidade única e uma fronteira do que **não** é
sua responsabilidade. A mecânica de execução de cada um está no skill.

| Sub-passo | Responsabilidade | **Não** é sua responsabilidade | Skill |
|---|---|---|---|
| `validate` | Análise estática (format, lint, build) + aceitação/cobertura como exceção dinâmica | Commitar, escrever/ler código, escrever em artefatos, fazer push | [steps/validate](../../../../skills/finish/steps/validate/SKILL.md) |
| `review` | Confirmar que checks obrigatórios, branch protection e ausência de reviewer bloqueante permitem auto aprovação segura | Executar a pipeline, commitar, escrever/ler código, fazer push, abrir PR | [steps/review](../../../../skills/finish/steps/review/SKILL.md) |
| push origin | Publicar os commits na branch de origem, sem force push | Validar, inspecionar pipeline, abrir PR | — (git direto, ver skill router) |
| `request` | Abrir **um** PR com o template preenchido e auto-merge armado (`--auto --squash`) | Validar, fazer push, commitar, escrever/ler código | [steps/request](../../../../skills/finish/steps/request/SKILL.md) |

Ordem obrigatória: `validate` verde → `review` sem bloqueadores → push →
`request`. Se `validate` falha, a correção volta ao
[`hack tdd`](../../../../skills/hack/steps/tdd/SKILL.md) — o Finish não escreve
código de produto.

Checklist completo: [capabilities/commit-workflow/README.md — Checklist do Finish](../../capabilities/commit-workflow/README.md#checklist-do-finish)

Template de PR: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

Para mecânica de execução, veja [`prodops/skills/finish/`](../../../../../skills/finish/).
