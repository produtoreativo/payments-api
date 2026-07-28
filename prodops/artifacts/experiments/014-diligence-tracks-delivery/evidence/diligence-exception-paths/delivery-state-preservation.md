# Delivery State Preservation — EXP-014 Iteration 5
# Evidência: Diligência não altera Delivery

**Data:** 2026-07-27
**Cenários validados:** A (#76), B (#77), C (#78)

---

## Invariantes

A Diligence pode:
- Ler Delivery Timeline (read-only)
- Ler Derived State (read-only)
- Comparar GitHub Project com Derived State
- Criar Findings
- Corrigir projeção GitHub (apenas campos Diligence)
- Registrar evidências e métricas

A Diligence **não pode**:
- Editar eventos da Delivery Timeline
- Remover eventos da Delivery Timeline
- Alterar `state` ou `last-event-type` no Derived State
- Usar GitHub como fonte de verdade para Repair
- Inserir eventos de tipo `prodops.delivery.*` em timelines de Diligence

---

## Verificação de preservação (hashes SHA-256, 16 chars)

Calculados antes e depois da execução de `demo-diligence-exception-paths.sh`:

| Issue | Hash antes | Hash depois | Status |
|---|---|---|---|
| #76 | (registrado em runtime.log) | (verificado pelo script) | ✅ INALTERADA |
| #77 | (registrado em runtime.log) | (verificado pelo script) | ✅ INALTERADA |
| #78 | (registrado em runtime.log) | (verificado pelo script) | ✅ INALTERADA |

*Valores reais disponíveis em `prodops/artifacts/runtime/runtime.log`*

---

## Segregação de timelines

| Arquivo | Tipo | Usado por |
|---|---|---|
| `timelines/76.json` | Delivery | **read-only** pelo script Diligence |
| `timelines/77.json` | Delivery | **read-only** pelo script Diligence |
| `timelines/78.json` | Delivery | **read-only** pelo script Diligence |
| `timelines/diligence-76.json` | Diligence | escrito pelo script Diligence |
| `timelines/diligence-77.json` | Diligence | escrito pelo script Diligence |
| `timelines/diligence-78.json` | Diligence | escrito pelo script Diligence |

---

## Verificação de tipos de eventos

Checagem implementada em `validate-demo.sh --mode exception-paths`:

```bash
# Delivery Timeline não deve conter eventos Diligence
DIL_IN_DEL=$(jq '[.[].type | select(startswith("prodops.diligence."))] | length' timelines/<issue>.json)
# Esperado: 0
```

---

## Repair de #78: fonte de verdade

O campo `repair-source` no evento `Diligence.Repair.Started` registra:

```
derived-state-78.json
```

O valor correto de `oem-state` foi lido de `prodops/artifacts/runtime/derived-state-78.json`,
**não** do GitHub Project. Isso garante que um GitHub corrompido não possa influenciar
o valor restaurado.

---

## Conclusão

A execução de todos os três cenários (Scenario A, B e C) não alterou nenhuma
Delivery Timeline. A Diligence operou estritamente como layer de observabilidade
e reconciliação, preservando todos os invariantes de integridade.
