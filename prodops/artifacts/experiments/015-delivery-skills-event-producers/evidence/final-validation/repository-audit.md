# EXP-015 — Repository Audit (Incremento 6)

**Data**: 2026-07-28  
**Auditor**: Claude (automated grep + structural inspection)  
**Branch**: `experiment/015-delivery-skills-event-producers`

---

## Objetivo

Provar através de evidências de repositório que:

1. CloudEvent assembly ocorre exclusivamente em `prodops/runtime/producer/emit.sh`  
2. Nenhuma Delivery Skill conhece Diligence  
3. O runner não chama o dispatcher diretamente  
4. Uma única fonte canônica de Skills serve todos os players  

---

## 1. CloudEvent Assembly

### 1.1 Localização canônica

```
prodops/runtime/producer/emit.sh
```

Campos construídos neste arquivo:

```bash
CE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
CE_SPECVERSION=$(yaml_get "cloud-events.specversion")
CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")
# jq builds: specversion, id, source, type, subject, time, datacontenttype, dataschema, data
```

### 1.2 Pipeline EXP-015 (produção)

```
Skill → Runner → prodops_emit_event tool → emit.sh (Step 1: CloudEvent build)
                                                   ↓
                                          → timeline/append.sh
                                          → consumer/derive-state.sh
                                          → datadog/send.sh
                                          → github/sync.sh
                                          → dispatcher/dispatch.sh (Step 6 — novo)
```

Nenhuma Skill e nenhum runner script constroem CloudEvents diretamente.

### 1.3 Scripts de demo pré-EXP-015 (exceção conhecida)

Dois scripts de demonstração do EXP-014 constroem CloudEvents diretamente:

| Script | Motivo |
|--------|--------|
| `prodops/runtime/scripts/bootstrap-diligence.sh` | Emite eventos Diligence diretamente para incluir cross-reference de Delivery no campo `data` (comentário inline: "Emits directly (not via emit.sh) to include delivery cross-reference in data") |
| `prodops/runtime/scripts/demo-delivery-with-diligence.sh` | Script de demo parcialmente usa `emit.sh` (linha 441) mas também tem path direto |

**Avaliação**: Estes scripts são artefatos de demo do EXP-014, fora do escopo do EXP-015. O pipeline EXP-015 (Skill → tool → emit.sh) não contém essa exceção.

**Gate EXP-015**: ✓ Dentro do pipeline EXP-015, CloudEvent assembly está exclusivamente em `emit.sh`.

---

## 2. Ausência de Conhecimento de Diligence nas Delivery Skills

### 2.1 Skills Delivery individuais auditadas

```bash
grep -ri "diligence|dispatch" prodops/skills/{bootstrap,hack,sync,finish,ship,validate,promote}/
```

**Resultado**: Zero ocorrências em todas as 7 Skills Delivery individuais.

| Skill | Referência a Diligence | Referência a Dispatch |
|-------|----------------------|----------------------|
| `bootstrap/SKILL.md` | ✗ | ✗ |
| `hack/SKILL.md` | ✗ | ✗ |
| `sync/SKILL.md` | ✗ | ✗ |
| `finish/SKILL.md` | ✗ | ✗ |
| `ship/SKILL.md` | ✗ | ✗ |
| `validate/SKILL.md` | ✗ | ✗ |
| `promote/SKILL.md` | ✗ | ✗ |

### 2.2 Separação arquitetural confirmada

Cada Skill Delivery apenas:
- Emite fatos via `prodops_emit_event` tool
- Não conhece subscriptions
- Não conhece quem reage aos seus eventos

O dispatcher (`prodops/runtime/dispatcher/dispatch.sh`) é ativado pelo Runtime pipeline (Step 6 de `emit-event`), não por nenhuma Skill.

---

## 3. Runner Não Chama Dispatcher

### 3.1 Evidência direta

```bash
grep -n "dispatch|DISPATCHER" prodops/runtime/tools/emit-event/tests/chain/run-chain.sh
```

**Resultado**:
```
21:# The runner does NOT call the dispatcher directly.
```

A única referência é o comentário explicativo. Nenhuma chamada ativa.

### 3.2 Skills scripts de chain sem dispatcher

```bash
grep -rn "dispatch|DISPATCHER" prodops/runtime/tools/emit-event/tests/chain/skills/
```

**Resultado**: Zero ocorrências em `bootstrap.sh`, `hack.sh`, `sync.sh`, `finish.sh`, `ship.sh`, `validate.sh`, `promote.sh`.

### 3.3 Mudança documentada (Incremento 4)

Antes desta validação, o runner chamava `dispatch_if_subscribed()` após cada fase. Essa violação foi corrigida integrando o dispatcher como Step 6 no pipeline interno do `emit-event`.

---

## 4. Fonte Canônica Única de Skills

### 4.1 Canonical skills

```
prodops/skills/{bootstrap,hack,sync,finish,ship,validate,promote}/SKILL.md
```

### 4.2 Player adapters (stubs de descoberta)

**Codex** (`.agents/skills/hack/SKILL.md`):
```yaml
---
name: hack
description: Execute implementation work with TDD, emitting Hack.Started and Hack.Completed via prodops_emit_event.
player: codex
---
Read `prodops/skills/hack/SKILL.md` and execute the full Hack flow.
```

**Copilot** (`.github/skills/hack/SKILL.md`):
```yaml
---
name: hack
description: Execute implementation work with TDD, emitting Hack.Started and Hack.Completed via prodops_emit_event.
player: copilot
---
Read `prodops/skills/hack/SKILL.md` and execute the full Hack flow.
```

Ambos os stubs direcionam o player para `prodops/skills/hack/SKILL.md`. Nenhum contrato privado por player.

### 4.3 Stubs verificados para todas as Skills

Stubs criados para `.agents/skills/` e `.github/skills/` para: `bootstrap`, `hack`, `sync`, `finish`, `ship`, `validate`, `promote`.

---

## 5. Resumo da Auditoria

| Critério | Status | Evidência |
|----------|--------|-----------|
| CloudEvent assembly em `emit.sh` (pipeline EXP-015) | ✓ PASS | grep mostra assembly apenas em `producer/emit.sh` para o pipeline da Tool |
| Delivery Skills sem conhecimento de Diligence | ✓ PASS | Zero ocorrências em 7 Skills individuais |
| Runner não chama dispatcher | ✓ PASS | Apenas comentário explicativo no runner |
| Skill scripts não chamam dispatcher | ✓ PASS | Zero ocorrências em 7 skill scripts |
| Única fonte canônica | ✓ PASS | Todos os stubs referenciam `prodops/skills/` |
| Sem contratos privados por player | ✓ PASS | Stubs são descoberta pura, sem lógica adicional |

**Exceção documentada**: Scripts demo EXP-014 fora do escopo EXP-015 (`bootstrap-diligence.sh`, `demo-delivery-with-diligence.sh`) — pré-existentes, não modificados neste experimento.

**Resultado global da auditoria**: ✓ PASS — arquitetura EXP-015 em conformidade.
