→ [Voltar para Delivery](../../README.md)

# Hack

---

## Visão Geral

**Para que serve:** É a fase de implementação do CI Sync. Transforma os
critérios de aceite do OBC e os cenários BDD em código verificável por testes,
seguindo o ciclo Red→Green→Yellow, com evidência registrada no Release Trail.

**Como funciona:**

```
Red (teste falha pela razão certa) → Green (mínimo que passa)
→ Yellow (refactor + validações transversais) → Commit → Evidência
```

**Quando usar:** depois que o Bootstrap entregou branch limpa, ambiente pronto
e contrato verificado — e antes do Sync. Vale para Upstream e Downstream. O
Hack começa diretamente no TDD; se o contrato ou o critério de aceite estiver
ausente, volte ao Bootstrap.

**Posição no fluxo:**

```
CI Sync  →  Bootstrap → [Hack] → Sync → Finish
```

---

## Procedimento

O procedimento executável do Hack é o skill — este README não mantém uma
segunda cópia:

**→ [`prodops/skills/hack/SKILL.md`](../../../../skills/hack/SKILL.md)** (invocável via `/hack`)

| Step | Responsabilidade |
|---|---|
| [`start`](../../../../skills/hack/steps/start/SKILL.md) | Limpar o stage, sincronizar a base e criar a feature branch |
| [`tdd`](../../../../skills/hack/steps/tdd/SKILL.md) | Ciclo Red → Green → Yellow com fechamento de artefatos |
| [`commit`](../../../../skills/hack/steps/commit/SKILL.md) | Stage, revisão do diff e commit com Conventional Commit |

Os steps são sequenciais. As validações de **Segurança, Qualidade e
Documentação não são steps** — são transversais e rodam no Yellow Bar de cada
ciclo. O checklist canônico de saída do ciclo (os gates mínimos para
commitar) está em [quality-gates.md](quality-gates.md).

Quality gates de repositório (`lint`, `acceptance`, `no_mocks`), tipos de
commit e paths canônicos: [`prodops/exec/manifest.yaml`](../../../../exec/manifest.yaml).
