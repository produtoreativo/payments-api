# Release Trail — Versioning Model

The Release Trail is the append-only log of Downstream evidence. Each agent session produces its own trail file.

→ [Session index and history](README.en.md)

---

## How it works

Each agent session generates **a single trail file**, identified by the session ID and the opening date.

### Naming convention

```
prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md
prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.en.md
```

- `YYYY-MM-DD` — session opening date (does not change if the session crosses midnight)
- `<session-id>` — first 8 characters of the agent session UUID

**Example:** session `08117eda-eaa2-4a5e-a935-837f4cf4cf86`, opened on 2026-07-13:
```
sessions/2026-07-13-08117eda.md
sessions/2026-07-13-08117eda.en.md
```

---

## Structure of each session file

```markdown
# Release Trail — YYYY-MM-DD · <session-id>

**Session:** `<full-session-id>`
**Opened:** YYYY-MM-DD
**Status:** open | closed

---

## YYYY-MM-DD — <delivery slug>

### Summary
### Related
### Artifacts Updated
### Validation
### Notes / Decision Trail
```

The `Status` field changes to `closed` when the session ends.

---

## Rules

1. **One session = one file.** Do not mix deliveries from different sessions.
   The file **always** lives in `prodops/artifacts/trails/sessions/`, never inside
   an iteration folder. A session is addressed by its ID, not by a version: it may
   span iterations, and its location must not depend on mutable delivery state.
   A trail under `iterations/<version>/` is a deviation — move it to `sessions/`
   and register it in the index.
2. **Append-only.** Never edit already-recorded entries; record corrections as a new entry.
3. **Bilingual.** Always create `.md` (pt-BR) and `.en.md` (English) in parallel.
4. **Where to write.** The agent identifies the active session file by its own session ID. If the file does not yet exist for the session, create it before the first entry.
5. **Legacy.** Entries prior to 2026-07-14 are in [`sessions/legacy.en.md`](sessions/legacy.en.md).

---

## Release Trail ≠ Iteration Trail

Two distinct artifacts have already been confused because they shared the name
`release-trail.md`. They belong to different layers:

| | Release Trail (session) | Iteration Trail (iteration/card) |
|---|---|---|
| **Scope** | one agent session | one delivery inside an iteration |
| **Identity** | session ID (UUID) | iteration version or card slug |
| **Location** | `trails/sessions/` | `iterations/<version>/` |
| **Name** | `YYYY-MM-DD-<session-id>.md` | `iteration-trail*.md` |
| **Layer** | Framework defines; Runtime executes | product trail text |

The Release Trail is Framework ontology — the append-only log of sessions.
The Iteration Trail is a product artifact: it consolidates the evidence for a
specific delivery (TDD, decisions, artifacts touched) and has no session
identity. **Do not use the name `release-trail.md` for a trail scoped to an
iteration or a card.**

---

## Entry template

See [`prodops/templates/delivery/release-entry.md`](../../templates/delivery/release-entry.en.md).

---

## References

→ [Session index](README.en.md)
→ [Canonical paths](../../framework/canonical-paths.en.md)
→ [Glossary: Release Trail](../../framework/glossary.en.md#release-trail)
