# EXP-013 — Iteração 3: CloudEvents Foundation
# Relatório de Conclusão

**Data de execução:** 2026-07-27
**runtime-version:** 0.3.0
**Feature piloto:** Issue #76 — FTR-001: Invoice PIX — Happy Path Completo
**Resultado:** ✅ Todos os 8 objetivos implementados — comportamento funcional preservado

---

## 1. Objetivos — Verificação

| Objetivo | Status | Entregável |
|---|---|---|
| 1. Adotar CloudEvents 1.0 | ✅ | Envelope completo com todos os 9 campos obrigatórios |
| 2. Separar Envelope de Payload | ✅ | OEM exclusivamente em `data`; envelope = CloudEvents padrão |
| 3. Criar Event Validator | ✅ | `scripts/validate-event.sh` — 9 checks + specversion + data type |
| 4. Persistir CloudEvents na Timeline | ✅ | `timelines/76.json` contém CloudEvent completo |
| 5. Consumir apenas CloudEvents | ✅ | Consumer lê `.data["alters-state"]`, `.data["new-state"]`, `.type` |
| 6. Publicar para Datadog preservando rastreabilidade | ✅ | CE type como tag `event:`; correlation-id preservado |
| 7. Documentar contrato oficial | ✅ | `docs/contract.md` — envelope, payload, catálogo, versioning |
| 8. Garantir retrocompatibilidade funcional | ✅ | GitHub e Datadog recebem os mesmos dados; só o formato do evento mudou |

---

## 2. Arquivos Modificados

| Arquivo | Tipo | Mudanças |
|---|---|---|
| `prodops/runtime/runtime.yaml` | Atualizado | version 0.2.0→0.3.0; bloco `cloud-events` adicionado (specversion, source, datacontenttype) |
| `prodops/runtime/catalog/events.yaml` | Atualizado | Adicionados `cloud-event-type`, `description`, `data-schema` a `Delivery.Bootstrap.Started` |
| `prodops/runtime/producer/emit.sh` | Rewrite | Emite CloudEvent completo; OEM em `data`; lê `cloud-events.*` do config; chama validator antes de emitir |
| `prodops/runtime/timeline/append.sh` | Atualizado | Chama validator antes de appender — rejeita CloudEvents inválidos |
| `prodops/runtime/consumer/derive-state.sh` | Atualizado | Lê `.data["alters-state"]` e `.data["new-state"]`; campo renomeado `last-event` → `last-event-type` com valor = CE type |
| `prodops/runtime/scripts/bootstrap-runtime.sh` | Atualizado | Banner Iteration 3; exibe specversion/id/type do CE; usa `last-event-type` |
| `prodops/runtime/scripts/runtime-doctor.sh` | Atualizado | Banner v0.2.0 → v0.3.0 |

---

## 3. Arquivos Criados

| Arquivo | Descrição |
|---|---|
| `prodops/runtime/scripts/validate-event.sh` | Validator CloudEvents 1.0 — 9 campos obrigatórios + specversion check + data object check |
| `prodops/runtime/docs/contract.md` | Contrato oficial — envelope, payload, catálogo, timeline, derived state, validação, versioning, naming |
| `prodops/artifacts/experiments/013-runtime-validation/evidence/iteration-3-cloudevents-foundation.md` | Este relatório |

---

## 4. Mudanças no Contrato

### Formato do evento (Breaking Change)

**Antes (0.2.0 — formato proprietário):**
```json
{
  "runtime-event-id": "uuid",
  "runtime-correlation-id": "uuid",
  "runtime-version": "0.2.0",
  "framework-version": "1.0.0",
  "schema-version": "1",
  "occurred-at": "2026-07-27T...",
  "issue": "76",
  "event": "Delivery.Bootstrap.Started",
  "journey": "Delivery",
  "cycle": "Bootstrap",
  "phase": "Started",
  "alters-state": true,
  "new-state": "BOOTSTRAPPING"
}
```

**Depois (0.3.0 — CloudEvents 1.0):**
```json
{
  "specversion": "1.0",
  "id": "uuid",
  "source": "https://github.com/produtoreativo/payments-api",
  "type": "prodops.delivery.bootstrap.started",
  "subject": "76",
  "time": "2026-07-27T...",
  "datacontenttype": "application/json",
  "dataschema": "https://prodops.produtoreativo.io/schemas/events/delivery/bootstrap/started/v1.0.0",
  "data": {
    "issue": "76",
    "journey": "Delivery",
    "cycle": "Bootstrap",
    "phase": "Started",
    "alters-state": true,
    "new-state": "BOOTSTRAPPING",
    "runtime-correlation-id": "uuid",
    "runtime-version": "0.3.0",
    "framework-version": "1.0.0",
    "schema-version": "1"
  }
}
```

### Derived State output (Breaking Change)

| Campo | Antes | Depois |
|---|---|---|
| Evento do último estado | `last-event` (logical name) | `last-event-type` (CE type) |
| Valor | `"Delivery.Bootstrap.Started"` | `"prodops.delivery.bootstrap.started"` |

### GitHub Project `oem-last-event`

| Campo | Antes | Depois |
|---|---|---|
| Valor | `"Delivery.Bootstrap.Started"` | `"prodops.delivery.bootstrap.started"` |

### Datadog tag `event:`

| Campo | Antes | Depois |
|---|---|---|
| Valor | `"Delivery.Bootstrap.Started"` | `"prodops.delivery.bootstrap.started"` |

---

## 5. Breaking Changes

| # | Change | Impacto |
|---|---|---|
| BC-1 | Timeline de versões < 0.3.0 é incompatível | Consumer usa `.data["alters-state"]` — não existe em eventos do formato antigo. Mitigação: limpar timeline ao upgradar |
| BC-2 | `last-event` → `last-event-type` no derived-state.json | Qualquer consumer do derived-state.json precisa atualizar a chave lida |
| BC-3 | `oem-last-event` no GitHub armazena CE type | Usuários que liam o campo como nome lógico verão o CE type agora |
| BC-4 | Tag `event:` no Datadog usa CE type | Dashboards ou alertas baseados no nome lógico precisam ser atualizados |

---

## 6. Decisões Arquiteturais

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Dois gates de validação (producer + timeline) | Apenas no producer | Timeline valida como defesa em profundidade — se o producer for chamado de outro contexto, a integridade da Timeline é garantida |
| `dataschema` URI como placeholder | Omitir campo ou usar URI local | CloudEvents requer URI válida. URI de schema registry é o padrão correto mesmo sem o registry implantado |
| `last-event-type` (renomeado) | Manter `last-event` | O valor muda semanticamente (CE type vs logical name) — renomear evita ambiguidade silenciosa nos consumidores |
| OEM exclusivamente em `data` | Campos OEM no envelope + data | Envelope pertence ao CloudEvents. Misturar violaria a separação entre transporte e payload |
| Logical event name (`Delivery.Bootstrap.Started`) mantido como chave do catálogo | Usar CE type como chave | O nome lógico é mais legível para humanos. O catálogo é legível para operadores — o CE type é para máquinas |

---

## 7. Dívidas Técnicas Remanescentes

| Débito | Onde | Prioridade |
|---|---|---|
| `dataschema` URI é placeholder — não há schema registry real | `catalog/events.yaml` | Baixa — funcional; URI resolve quando registry existir |
| `validate-event.sh` não valida o conteúdo de `data` — apenas a presença e tipo | `scripts/validate-event.sh` | Média — payload válido não é verificado estruturalmente |
| `yaml_get()` duplicada em 5 scripts | Todos | Baixa — intencional (spec proíbe lib compartilhada) |
| `time` no CE usa `%Y-%m-%dT%H:%M:%SZ` — sem frações de segundo | `producer/emit.sh` | Baixa — RFC3339 compliant; frações são opcionais |
| Timeline sem deduplicação por `id` | `timeline/append.sh` | Média — re-execuções criam eventos duplicados com CEs distintos |

---

## 8. Limitações Conhecidas

| Limitação | Impacto |
|---|---|
| `dataschema` URI não resolve para um JSON Schema real | Validators externos não podem baixar o schema |
| CloudEvent `source` é o repo URL — não identifica o operador/processo específico | Pouco granular para ambientes multi-operador |
| Apenas 1 evento no catálogo | O Runtime não pode avançar de estado sem editar o catálogo |
| Timeline é incompatível com versões anteriores | Upgrade exige reset manual da timeline |

---

## 9. Definition of Done — Verificação

| Critério | Status | Evidência |
|---|---|---|
| Runtime produzindo CloudEvents válidos | ✅ | Validator: `[PASS] CloudEvent is valid (specversion=1.0 type=prodops.delivery.bootstrap.started)` |
| Timeline contendo CloudEvents | ✅ | `timelines/76.json` — CloudEvent completo com envelope + data |
| Consumer lendo CloudEvents | ✅ | Derived state via `.data["alters-state"]` e `.type` |
| GitHub sincronizado | ✅ | `oem-state=BOOTSTRAPPING`, `oem-last-event=prodops.delivery.bootstrap.started` |
| Datadog sincronizado | ✅ | HTTP 202, tag `event:prodops.delivery.bootstrap.started` |
| Validator funcionando | ✅ | 2 invocações por run: producer + timeline |
| Catálogo atualizado | ✅ | `cloud-event-type`, `description`, `data-schema` em cada evento |
| Contrato documentado | ✅ | `docs/contract.md` — 11 seções, exemplo completo |
| Nenhuma alteração funcional além do formato | ✅ | GitHub e Datadog recebem os mesmos dados operacionais |

---

## 10. Sugestões para a Iteração 4

| Sugestão | Valor |
|---|---|
| **Adicionar mais eventos ao catálogo** — `Delivery.Hack.Started`, `Delivery.Hack.Completed`, `Delivery.Promote.Completed` | Alto — permite observar uma Feature cruzando múltiplos estados; valida Q2 |
| **Criar JSON Schema real** para `data` e publicar no caminho `dataschema` | Médio — torna o contrato verificável por ferramentas externas |
| **Adicionar `oem-correlation-id` como campo no GitHub Project** | Médio — fecha rastreabilidade GitHub → Datadog sem precisar dos logs |
| **Implementar deduplicação por CE `id` na Timeline** | Médio — elimina duplicação em re-execuções |
| **Executar o fluxo para FTR-002 e FTR-003** com eventos distintos | Alto — começa a validar CS-01 (três Features com Timelines) |
| **Adicionar `data.runtime-session-id`** para distinguir sessão (bootstrap invocation) de correlation | Baixo — nuance útil em debug mas não essencial agora |
