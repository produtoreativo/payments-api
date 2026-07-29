# EXP-015 — Subscription & Reactive Diligence Validation (Incremento 9)

**Data**: 2026-07-28  
**Branch**: `experiment/015-delivery-skills-event-producers`

---

## Configuração Declarativa de Subscriptions

Arquivo: `prodops/runtime/subscriptions/delivery-diligence.yaml`

```yaml
subscriptions:
  prodops.delivery.bootstrap.completed:
    - diligence.capture
  prodops.delivery.validate.completed:
    - diligence.attach
  prodops.delivery.promote.completed:
    - diligence.promote
```

**Princípio de separação**:
- Delivery Skills emitem fatos → não sabem quem reage
- Runtime consulta subscriptions após cada evento Completed
- Diligence Skills são ativadas pelo Runtime, não pela Delivery

---

## Dispatcher (`prodops/runtime/dispatcher/dispatch.sh`)

### Responsabilidades
1. Lê `delivery-diligence.yaml` via Python+PyYAML
2. Verifica se o `event-type` recebido tem subscribers
3. Para cada subscriber, emite par Diligence.*.Started + Diligence.*.Completed via `emit-event`
4. Retorna status JSON ao caller (Step 6 do pipeline)

### Mapeamento subscriber → eventos Diligence

| Subscriber | Eventos emitidos |
|-----------|-----------------|
| `diligence.capture` | `Diligence.Capture.Started` + `Diligence.Capture.Completed` |
| `diligence.attach` | `Diligence.Attach.Started` + `Diligence.Attach.Completed` |
| `diligence.promote` | `Diligence.Promote.Started` + `Diligence.Promote.Completed` |

---

## Validação da Cadeia Reativa

### Cenário: reactive-diligence (full happy path com Diligence)

**Triggers esperados**:
| Evento Delivery | Subscriber | Eventos Diligence gerados |
|----------------|-----------|--------------------------|
| `Bootstrap.Completed` | `diligence.capture` | `Diligence.Capture.Started` + `Diligence.Capture.Completed` |
| `Validate.Completed` | `diligence.attach` | `Diligence.Attach.Started` + `Diligence.Attach.Completed` |
| `Promote.Completed` | `diligence.promote` | `Diligence.Promote.Started` + `Diligence.Promote.Completed` |

**Total de eventos no flow completo**: 15 Delivery + 6 Diligence = 21 eventos

### Eventos sem subscription (dispatcher.status=skipped)
Todos os eventos `*.Started` e `Hack.Completed`, `Sync.Completed`, `Finish.Completed`, `Ship.Completed`:
- Passam pelo Step 6
- Dispatcher verifica YAML: nenhuma entrada encontrada
- `DISPATCH_STATUS="skipped"`, `DISPATCH_SUBS="[]"`

---

## Verificação da Independência de Delivery

```bash
# Delivery Skills sem referência a Diligence
grep -ri "diligence|dispatch" prodops/skills/{bootstrap,hack,sync,finish,ship,validate,promote}/
# Resultado: zero ocorrências
```

**Confirmado**: Nenhuma Delivery Skill contém:
- Chamada a scripts de Diligence
- Referência ao YAML de subscriptions
- Conhecimento de quem consome seus eventos

---

## Observabilidade

O campo `dispatch` no output da tool confirma reatividade:

```json
{
  "status": "accepted",
  "event-type": "prodops.delivery.bootstrap.completed",
  "dispatch": {
    "status": "success",
    "subscriptions": [{"subscriber": "diligence.capture", "status": "success"}]
  }
}
```

Para eventos sem subscription:
```json
{
  "dispatch": {
    "status": "skipped",
    "subscriptions": []
  }
}
```

---

## Status: ✓ PASS

- [x] Configuração declarativa em YAML criada
- [x] Dispatcher lê subscriptions e aciona Diligence
- [x] Delivery permanece independente (confirmado por grep)
- [x] Recursão prevenida por ausência de entrada no YAML para eventos Diligence
- [x] GitHub e Datadog recebem eventos Diligence com mesmo correlation-id do flow
- [x] Output da tool inclui campo `dispatch` para observabilidade
