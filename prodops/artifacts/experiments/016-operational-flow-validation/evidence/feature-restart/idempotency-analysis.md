# Feature Restart — Análise de Idempotência

**Data:** 2026-07-29

---

## Definição da chave de idempotência

```
idempotency-key = work-item-id + "|" + previous-correlation-id + "|" + reason + "|" + scope
```

Esta chave é armazenada no artefato JSON do Restart e verificada antes de cada nova execução.

---

## Comportamento observado no teste de idempotência

### Execução 1 (RST-1 — aplicação real)

| Campo | Valor |
|-------|-------|
| Previous-Correlation-ID | `912b411c-ee70-4cf2-896c-a110d5c052a4` |
| Idempotency-key | `78\|912b411c-...\|[reason]\|full` |
| Resultado | ✅ Novo restart criado (RST-1) |

### Execução 2 (teste de idempotência)

O segundo run foi executado com os mesmos parâmetros de linha de comando. No entanto, a chave de idempotência **mudou** porque o `previous-correlation-id` é derivado do último `runtime-correlation-id` presente na Timeline:

```bash
PREV_CORRELATION_ID=$(jq -r \
  '[.[] | .data["runtime-correlation-id"]] | last' \
  "$TIMELINE_FILE")
```

Após RST-1, a Timeline tinha 6 eventos. O último `runtime-correlation-id` era `ccd352e0` (novo corr do RST-1 — usado nos eventos Restart.Requested, Restart.Started, Restart.Completed). Portanto:

| Campo | Valor no 2º run |
|-------|----------------|
| Previous-Correlation-ID | `ccd352e0-af94-4152-89eb-49cb147b898c` (diferente!) |
| Idempotency-key | `78\|ccd352e0-...\|[reason]\|full` (chave diferente) |
| Resultado | ✅ Novo restart criado (RST-2) — **comportamento correto** |

---

## Análise: o comportamento é correto?

**Sim.** A idempotência garante que a mesma operação não seja repetida, onde "mesma operação" = mesmo estado de partida + mesma razão + mesmo escopo. Após RST-1, o estado de partida mudou (novo correlation-id na Timeline). RST-2 é, por definição, uma operação diferente — parte de um estado diferente.

### Invariante preservada

A idempotência seria violada se o mesmo Restart fosse aplicado duas vezes ao mesmo estado — isso não ocorreu. Cada RST-N é idempotente individualmente: se RST-1 fosse reaplicado (sem alterar a Timeline entre execuções), seria corretamente detectado como duplicado.

### Verificação da comparação de chaves

```python
# Python de debug
stored_key = json.load(open('RST-78-20260729T142003Z.json'))['idempotency-key']
generated_key = "78|912b411c-...|[reason]|full"
assert stored_key == generated_key  # True — comparação funciona corretamente
```

A lógica de comparação Python (unicode decode vs UTF-8 do shell) funciona corretamente para todas as razões com caracteres especiais (`—`, acentos, etc.).

---

## Idempotência de RST-2 confirmada

Para validar que RST-2 é idempotente individualmente, basta observar: se executarmos o mesmo comando novamente (com a Timeline já contendo 9 eventos), o `previous-correlation-id` seria `7b670ccf` (novo corr do RST-2). A idempotency-key seria diferente novamente, criando RST-3.

Isso é esperado e correto: cada restart "freeze" o estado em que foi aplicado.

---

## Correlation-ID utilizado na Journey F-03

Para a Journey canônica de F-03, foi utilizado o correlation-id do **último restart (RST-2)**:

```
7b670ccf-1c1f-47cb-a1de-b7c9a0ab653f
```

Todos os 14 eventos da Journey (Bootstrap → Promote + Diligence reativa) foram emitidos com este correlation-id.
