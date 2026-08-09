# Release Trail — Modelo de Versionamento

O Release Trail é o log append-only de evidências do Downstream. Cada sessão de agente produz seu próprio arquivo de trail.

→ [Índice de sessões e histórico](README.md)

---

## Como funciona

Cada sessão de agente gera **um único arquivo de trail**, identificado pelo ID da sessão e pela data de abertura.

### Convenção de nome

```
prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md
prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.en.md
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
   O arquivo vive **sempre** em `prodops/artifacts/trails/sessions/`, nunca dentro
   da pasta de uma iteração. Uma sessão é endereçada pelo seu ID, não pela versão:
   ela pode cruzar iterações, e sua localização não deve depender de estado mutável
   da entrega. Trail dentro de `iterations/<version>/` é desvio — mover para
   `sessions/` e registrar no índice.
2. **Append-only.** Nunca editar entradas já registradas; registrar correções como nova entrada.
3. **Bilíngue.** Sempre criar `.md` (pt-BR) e `.en.md` (English) em paralelo.
4. **Onde escrever.** O agente identifica o arquivo da sessão ativa pelo seu próprio session ID. Se o arquivo ainda não existir na sessão, criá-lo antes da primeira entrada.
5. **Legado.** Entradas anteriores a 2026-07-14 estão em [`sessions/legacy.md`](sessions/legacy.md).

---

## Release Trail ≠ Iteration Trail

Dois artefatos distintos já foram confundidos por compartilharem o nome
`release-trail.md`. Eles pertencem a camadas diferentes:

| | Release Trail (sessão) | Iteration Trail (iteração/card) |
|---|---|---|
| **Escopo** | uma sessão de agente | uma entrega dentro de uma iteração |
| **Identidade** | session ID (UUID) | versão da iteração ou slug do card |
| **Onde vive** | `trails/sessions/` | `iterations/<version>/` |
| **Nome** | `YYYY-MM-DD-<session-id>.md` | `iteration-trail*.md` |
| **Camada** | Framework define; Runtime executa | texto de trail do produto |

O Release Trail é ontologia do Framework — o log append-only de sessões.
O Iteration Trail é artefato de produto: consolida a evidência de uma entrega
específica (TDD, decisões, artefatos tocados) e não tem identidade de sessão.
**Não usar o nome `release-trail.md` para trail escopado por iteração ou card.**

---

## Template de entrada

Ver [`prodops/templates/delivery/release-entry.md`](../../templates/delivery/release-entry.md).

---

## Referências

→ [Índice de sessões](README.md)
→ [Canonical paths](../../framework/canonical-paths.md)
→ [Glossário: Release Trail](../../framework/glossary.md#release-trail)
