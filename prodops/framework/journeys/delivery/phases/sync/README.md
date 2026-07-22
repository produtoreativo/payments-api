→ [Voltar para Delivery](../../README.md)

# Sync

---

## Visão Geral

**Para que serve:** Checkpoint de consistência entre o Hack e o Finish. O Sync cuida de **duas integridades distintas e complementares**:

- **Integridade do repositório git** (`rebase`) — tornar o repositório pronto para merge, incorporando o estado mais recente da base sem conflitos.
- **Integridade dos artefatos ProdOps** (`align`) — garantir que os artefatos canônicos em `prodops/` refletem exatamente o que foi implementado.

Essas duas integridades são pré-condições para o Finish: o Finish não pode abrir um PR confiável sobre um repositório divergente nem sobre artefatos inconsistentes com o diff.

**Como funciona:**

```
sync rebase: Fetch remoto → Atualiza base (fast-forward) → Integra na feature
              → Resolve conflitos (dois lados) → Preserva TDD → Valida → Branch limpa
              [integridade do repositório git]

sync align:  Revisa o diff (main...HEAD) → Lista o que mudou
              → Identifica o artefato canônico para cada mudança
              → Atualiza só os artefatos inconsistentes → Release Trail quando significativo
              [integridade dos artefatos ProdOps]
```

Os dois steps são independentes — podem ser executados na ordem que fizer sentido ou individualmente conforme a necessidade. O `rebase` é trabalho de **git**; o `align` é trabalho de **rastreabilidade**. Um não substitui o outro.

**Guardrails principais:**

- Nunca descarta trabalho local nem reescreve histórico compartilhado
- Não enfraquece testes para fazer o sync passar
- Conflitos são inspecionados dos dois lados antes de qualquer edição
- Não reescreve decisões de produto durante trabalho de alinhamento de artefatos — alinha o artefato ao código, não o contrário

**Posição no fluxo:**

```
CI Sync  →  Bootstrap → Hack → [Sync] → Finish
                                   ├── rebase  (integridade do repositório git)
                                   └── align   (integridade dos artefatos ProdOps)
```

---

## O que Sync faz (e o que não faz)

O Sync tem fronteira precisa. Misturar responsabilidades com Hack e Finish cria workarounds que mascaram divergências.

### É responsabilidade do Sync

| Step | O que garante |
|---|---|
| `rebase` | Working tree limpa, base atualizada, feature branch integrada à base, testes passando sobre o histórico integrado, nenhuma assertion removida para resolver conflito. |
| `align` | Nenhum artefato ProdOps (BDD, Event Storming, arquitetura, OBC) está inconsistente com o diff do branch; Release Trail registra o alinhamento quando significativo. |

### **Não** é responsabilidade do Sync

- **Sync não valida quality gates de código.** Lint, formatação e tests de comportamento são trabalho do Hack (Yellow Bar) e do Finish. O `rebase` executa testes/lint apenas para validar que a **integração** não quebrou o histórico já verde — não para adicionar cobertura ou corrigir code smell herdado.
- **Sync não abre PR.** Abrir o pull request, descrever a mudança e acionar revisão é o Finish.
- **Sync não roda a pipeline completa.** Ship roda a pipeline assíncrona nos ambientes; Sync roda apenas a validação local mínima pós-integração.
- **Sync não reescreve decisões de produto.** Se o diff diverge de uma decisão upstream, o `align` registra a divergência; a decisão em si é ajustada em upstream ou no Finish, nunca durante o Sync.

---

## Steps

O Sync é composto por dois steps independentes, executados via `/sync <step>`:

| Step | Responsabilidade |
|---|---|
| [`rebase`](../../../../../skills/sync/steps/rebase/SKILL.md) | **Integridade do repositório git:** fetch, fast-forward da base, integração na feature branch (rebase ou merge), resolução de conflitos inspecionando os dois lados, preservação de TDD, validação pós-integração. |
| [`align`](../../../../../skills/sync/steps/align/SKILL.md) | **Integridade dos artefatos ProdOps:** revisar o diff, mapear cada mudança ao artefato canônico (BDD, Event Storming, arquitetura, OBC) e atualizar apenas os inconsistentes. |

Para mecânica de execução completa, veja [`prodops/skills/sync/`](../../../../../skills/sync/).

---

## Critérios de conclusão

### sync rebase — integridade do repositório

Concluído quando: working tree limpa + base local atualizada com `origin` + feature branch incorpora a base mais recente + testes/lint passam sobre o histórico integrado + nenhuma assertion foi removida para resolver conflito.

### sync align — integridade dos artefatos

Concluído quando: nenhum artefato ProdOps canônico está inconsistente com o que está no diff do branch (`git diff main...HEAD`), e o Release Trail recebeu entrada quando o alinhamento foi significativo.

---

## Checklist

### sync rebase

- [ ] Branch atualizada a partir da base mais recente.
- [ ] Conflitos resolvidos com ambos os lados inspecionados.
- [ ] Testes passam sobre o histórico integrado.
- [ ] Nenhum teste foi removido ou enfraquecido para completar o sync.
- [ ] Working tree limpa ao final.

### sync align

- [ ] BDD Feature reflete o comportamento implementado.
- [ ] Critérios de aceite do OBC estão satisfeitos pelos testes.
- [ ] Diagrama de arquitetura atualizado se a mudança foi estrutural.
- [ ] Event Storming atualizado se eventos foram adicionados, removidos ou renomeados.
- [ ] Entrada no Release Trail redigida com evidências quando o alinhamento foi significativo.