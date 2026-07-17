# Release Trail — Modelo de Versionamento

O Release Trail é o log append-only de evidências do Downstream. Cada sessão de agente produz seu próprio arquivo de trail.

→ [Índice de sessões e histórico](README.md)

---

## Como funciona

Cada sessão de agente gera **um único arquivo de trail**, identificado pelo ID da sessão e pela data de abertura.

### Convenção de nome

```
prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md
prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.en.md
```

- `YYYY-MM-DD` — data de abertura da sessão (não muda se a sessão cruzar a meia-noite)
- `<session-id>` — primeiros 8 caracteres do UUID da sessão do agente

**Exemplo:** sessão `08117eda-eaa2-4a5e-a935-837f4cf4cf86`, aberta em 2026-07-13:
```
sessions/2026-07-13-08117eda.md
sessions/2026-07-13-08117eda.en.md
```

---

## Estrutura de cada arquivo de sessão

```markdown
# Release Trail — YYYY-MM-DD · <session-id>

**Sessão:** `<session-id-completo>`
**Aberta em:** YYYY-MM-DD
**Status:** open | closed

---

## YYYY-MM-DD — <slug da entrega>

### Summary
### Related
### Artifacts Updated
### Validation
### Notes / Decision Trail
```

O campo `Status` muda para `closed` quando a sessão encerra.

---

## Regras

1. **Uma sessão = um arquivo.** Não misturar entregas de sessões diferentes.
2. **Append-only.** Nunca editar entradas já registradas; registrar correções como nova entrada.
3. **Bilíngue.** Sempre criar `.md` (pt-BR) e `.en.md` (English) em paralelo.
4. **Onde escrever.** O agente identifica o arquivo da sessão ativa pelo seu próprio session ID. Se o arquivo ainda não existir na sessão, criá-lo antes da primeira entrada.
5. **Legado.** Entradas anteriores a 2026-07-14 estão em [`sessions/legacy.md`](sessions/legacy.md).

---

## Template de entrada

Ver [`prodops/templates/delivery/release-entry.md`](../../templates/delivery/release-entry.md).

---

## Referências

→ [Índice de sessões](README.md)
→ [Canonical paths](../../framework/canonical-paths.md)
→ [Glossário: Release Trail](../../framework/glossary.md#release-trail)
