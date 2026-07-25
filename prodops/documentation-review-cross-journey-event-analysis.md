# Cross-Journey Event Analysis
# ProdOps Framework — Delivery vs. Diligence

> **Data:** 2026-07-24
> **Tipo:** Análise comparativa — reutilização cross-Journey
> **Status:** Concluído
> **Escopo:** Delivery Event Catalog MVP (17 tipos) × Diligence Event Catalog MVP (20 tipos)

---

## Executive Summary

| Métrica | Resultado |
|---|---|
| Event Types comparados | 37 (17 Delivery + 20 Diligence) |
| Pares com nome idêntico | 7 pares |
| Classificação Equivalente | 3 tipos |
| Classificação Similar (mesmo nome, semântica diferente) | 4 tipos (2 pares) |
| Classificação Exclusivo — Delivery | 10 tipos |
| Classificação Exclusivo — Diligence | 14 tipos |
| Candidatos reais a Shared Type | 3 imediatos + 1 pendente |
| Conflitos encontrados | 4 (1 crítico, 3 colisões de naming) |
| Lacunas identificadas | 3 |
| OEM consistente nas duas implementações | **Sim** |
| Necessidade de revisão do OEM | **Não** |
| Evidência suficiente para criar `shared-types.md` | **Sim** |

---

## 1. Comparação completa dos Event Types

### 1.1 Método de classificação

| Classe | Critério |
|---|---|
| **Equivalente** | Nome idêntico, semântica idêntica, comportamento idêntico (alters_state, new_state, producers, payload_shape equivalente) |
| **Similar** | Nome idêntico ou próximo, semântica ou comportamento diferente |
| **Exclusivo** | Sem equivalente — nenhum tipo com nome ou semântica comparável na outra Journey |

---

### 1.2 Tipos Equivalentes

Estes tipos possuem semântica idêntica nas duas Journeys. São os candidatos reais a Shared Type.

---

#### Gate.Passed — EQUIVALENTE

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Gate.Passed` | `Gate.Passed` | Sim |
| category | Gate | Gate | Sim |
| alters_state | false | false | Sim |
| new_state | — | — | Sim |
| producer_subtypes | [System, Agent] | [System, Agent] | Sim |
| payload: gate_name | obrigatório (string) | obrigatório (string) | Sim |
| payload: duration_ms | obrigatório (integer) | obrigatório (integer) | Sim |

**Semântica:** "Um gate automatizado passou com sucesso." Independente de Journey — o
conceito de um critério verificável automaticamente é genuinamente genérico.

**Variação legítima de contexto:**
- Delivery: gate verifica lint, testes, cobertura, segurança
- Diligence: gate verifica readiness, labels canônicas, conformidade de campos

Esta variação está no `payload.gate_name`, não na semântica do tipo. Um Consumer que
recebe `gate_name = "smoke-test"` ou `gate_name = "readiness-check"` usa o mesmo Event
Type — a diferença é de domínio, não de modelo.

**Justificativa:** semanticamente idêntico, estruturalmente idêntico, independente de Journey.

---

#### Gate.Failed — EQUIVALENTE

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Gate.Failed` | `Gate.Failed` | Sim |
| category | Gate | Gate | Sim |
| alters_state | false | false | Sim |
| new_state | — | — | Sim |
| producer_subtypes | [System, Agent] | [System, Agent] | Sim |
| payload: gate_name | obrigatório | obrigatório | Sim |
| payload: reason | obrigatório | obrigatório | Sim |
| payload: duration_ms | obrigatório | obrigatório | Sim |

**Semântica:** "Um gate automatizado falhou." Complemento de Gate.Passed. Mesma análise.

**Justificativa:** semanticamente idêntico, estruturalmente idêntico, par natural de Gate.Passed.

---

#### Impediment.Declared — EQUIVALENTE

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Impediment.Declared` | `Impediment.Declared` | Sim |
| category | Blocking | Blocking | Sim |
| alters_state | true | true | Sim |
| new_state | BLOCKED | BLOCKED | Sim |
| producer_subtypes | [Human, Agent] | [Human, Agent] | Sim |
| payload: impediment_description | obrigatório | obrigatório | Sim |
| payload: blocking_since | obrigatório | obrigatório | Sim |

**Semântica:** "Um impedimento externo foi declarado para o Work Item. O trabalho não pode
progredir." O conceito de bloqueio por causa externa é genuinamente transversal — um
impedimento na Delivery (dependência de infraestrutura) e um impedimento na Diligence
(acesso negado a sistema externo) são o mesmo fenômeno operacional.

**Justificativa:** semanticamente idêntico, estruturalmente idêntico, par natural de Impediment.Resolved.

---

### 1.3 Tipos Similares

Estes tipos compartilham o nome mas têm semântica ou comportamento diferente. **Não são candidatos a Shared Type.** Representam o risco de ambiguidade se tratados como equivalentes.

---

#### Impediment.Resolved — SIMILAR (conflito técnico)

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Impediment.Resolved` | `Impediment.Resolved` | Sim |
| category | Blocking | Blocking | Sim |
| alters_state | **true** | **false** | **NÃO** |
| new_state | **HACKING** (hardcoded) | — (Lookback) | **NÃO** |
| producer_subtypes | [Human] | [Human] | Sim |
| payload: resolution_description | obrigatório | obrigatório | Sim |

**Semântica:** idêntica — "O impedimento externo foi resolvido e o trabalho pode ser retomado."

**Diferença:** implementação técnica diverge. A Delivery usa `alters_state = true` com
`new_state = HACKING` (simplificação MVP documentada). A Diligence usa `alters_state = false`
com Lookback via `preBlockedState()` (implementação refinada).

**Causa:** a Delivery MVP documentou explicitamente a simplificação como limitação. A Diligence
implementou o padrão correto do OEM. A semântica é a mesma; o comportamento técnico diverge
entre os dois catálogos.

**Conclusão:** É equivalente semanticamente, mas não tecnicamente. O `alters_state` conflitante
impede a promoção direta. A Delivery precisa ser atualizada para `alters_state = false` antes
que este tipo possa ser promovido a Shared Type.

**Classificação:** Similar com intenção de equivalência — requer Delivery v2 para convergir.

---

#### Promote.Approved — SIMILAR (colisão de naming)

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Promote.Approved` | `Promote.Approved` | Sim |
| category | Human Decision | Human Decision | Sim |
| alters_state | true | true | Sim |
| new_state | PROMOTING | PROMOTING | Sim |
| producer_subtypes | [Human] | [Human] | Sim |
| precondition (estado) | VALIDATING | **ATTACHED** | **NÃO** |
| Contexto | Autoriza deploy em produção | Autoriza promoção de readiness | **NÃO** |

**Diferença:** o `new_state` coincide (PROMOTING) e `alters_state` coincide, mas o domínio
é diferente. "Produção" (Delivery) vs. "readiness no backlog" (Diligence) são decisões
com responsáveis, critérios e consequências completamente distintos. O payload confirma:
Delivery exige `environment_validated` (homologação); Diligence exige `readiness_criteria`
(critérios de backlog).

**Risco:** se fosse promovido a Shared Type, um Consumer genérico não conseguiria distinguir
os contextos — um `Promote.Approved` para produção e um para readiness de backlog teriam
o mesmo tipo mas significados operacionais completamente distintos.

**Conclusão:** colisão de naming — mesmos tokens, domínios diferentes. Não é candidato a Shared Type.

---

#### Promote.Rejected — SIMILAR (comportamento conflitante)

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Promote.Rejected` | `Promote.Rejected` | Sim |
| category | Human Decision | Human Decision | Sim |
| alters_state | **true** | **false** | **NÃO** |
| new_state | **VALIDATING** | — (permanece ATTACHED) | **NÃO** |
| precondition (estado) | VALIDATING | ATTACHED | NÃO |

**Diferença:** além do domínio diferente (mesma análise de Promote.Approved), o comportamento
técnico diverge. Na Delivery, `Promote.Rejected` retorna ativamente ao estado VALIDATING
(`alters_state = true`). Na Diligence, `Promote.Rejected` não altera o estado — o Work Item
permanece ATTACHED (`alters_state = false`). Isso reflete a diferença operacional: na Delivery,
o reject precisa sinalizar que o ciclo de validação continua; na Diligence, o Work Item
simplesmente fica no estado ATTACHED aguardando nova revisão.

**Conclusão:** colisão de naming com conflito técnico real de `alters_state`. Não é candidato.

---

#### Promote.Completed — SIMILAR (estados finais diferentes)

| Campo | Delivery | Diligence | Idêntico? |
|---|---|---|---|
| name | `Promote.Completed` | `Promote.Completed` | Sim |
| category | Phase Lifecycle | Phase Lifecycle | Sim |
| alters_state | true | true | Sim |
| new_state | **DONE** | **PROMOTED** | **NÃO** |
| producer_subtypes | [System] | [Human, Agent] | NÃO |
| Terminal? | Sim (DONE = estado final) | Não (Close.Completed ainda necessário) | NÃO |

**Diferença:** domínio, estado resultante, terminalidade, e producer diferentes. Na Delivery,
`Promote.Completed` é o evento terminal — deploy em produção realizado, `new_state = DONE`.
Na Diligence, é um passo intermediário — promoção de readiness, `new_state = PROMOTED`, com
`Close.Completed` ainda pendente.

**Conclusão:** colisão de naming com estados finais incompatíveis. Não é candidato.

---

### 1.4 Tipos Exclusivos da Delivery (sem equivalente na Diligence)

| Event Type | Category | Por que é exclusivo |
|---|---|---|
| `Bootstrap.Started` | Phase Lifecycle | Preparação de ambiente de desenvolvimento — conceito CI |
| `Bootstrap.Completed` | Phase Lifecycle | Conclusão de bootstrap de dev — conceito CI |
| `Hack.Completed` | Phase Lifecycle | Abertura de PR de código — conceito CI |
| `Sync.Completed` | Phase Lifecycle | Merge de PR — conceito CI |
| `Finish.Completed` | Phase Lifecycle | Conclusão das checagens finais do CI Sync |
| `Ship.Completed` | Phase Lifecycle | Deploy em homologação — conceito CI Async |
| `Review.Approved` | Human Decision | Aprovação de code review — PR workflow |
| `Review.ChangesRequested` | Human Decision | Solicitação de alterações em PR — PR workflow |
| `Rework.Declared` | Rework | Retorno ao desenvolvimento por qualidade insuficiente |
| `Rework.Completed` | Rework | Conclusão de ciclo de rework |

10 tipos exclusivos da Delivery (58,8% do catálogo).

---

### 1.5 Tipos Exclusivos da Diligence (sem equivalente na Delivery)

| Event Type | Category | Por que é exclusivo |
|---|---|---|
| `Capture.Started` | Phase Lifecycle | Registro de Work Item na Diligence — sem análogo CI |
| `Capture.Completed` | Phase Lifecycle | Conclusão de captura — sem análogo CI |
| `Attach.Completed` | Phase Lifecycle | Associação ao projeto gerenciado — sem análogo CI |
| `Close.Completed` | Phase Lifecycle | Fechamento formal do ciclo Sync — sem análogo CI |
| `Scan.Started` | Phase Lifecycle | Varredura assíncrona — conceito Diligence |
| `Scan.Completed` | Phase Lifecycle | Conclusão de varredura — conceito Diligence |
| `Flag.Completed` | Phase Lifecycle | Sinalização de divergência — conceito Diligence |
| `Repair.Started` | Phase Lifecycle | Início de reparo de divergência — conceito Diligence |
| `Repair.Completed` | Phase Lifecycle | Conclusão de reparo — conceito Diligence |
| `Waiver.Granted` | Human Decision | Exceção formal — exclusivo Diligence |
| `Waiver.Rejected` | Human Decision | Rejeição de exceção — exclusivo Diligence |
| `Divergence.Detected` | Diligence | Registro de divergência — exclusivo Diligence |
| `Finding.Recorded` | Diligence | Registro de achado de auditoria — exclusivo Diligence |
| `Promote.Completed` (semântica) | Phase Lifecycle | Promoção de readiness (vs. deploy em produção) |

14 tipos exclusivos da Diligence (70% do catálogo).

---

## 2. Event Categories

### 2.1 Categories presentes nas duas Journeys

| Category | Delivery | Diligence | Observação |
|---|---|---|---|
| **Phase Lifecycle** | 7 tipos | 10 tipos | A maior categoria em ambas — estrutura os steps de cada ciclo |
| **Gate** | 2 tipos | 2 tipos | Tamanho idêntico — os 4 candidatos diretos a Shared Type |
| **Human Decision** | 4 tipos | 4 tipos | Tamanho idêntico — diferentes tipos, mesmo volume |
| **Blocking** | 2 tipos | 2 tipos | Tamanho idêntico — os candidatos mais fortes a Shared Type |

### 2.2 Categories exclusivas

| Category | Exclusiva de | Tipos |
|---|---|---|
| **Rework** | Delivery | Rework.Declared, Rework.Completed |
| **Diligence** | Diligence | Divergence.Detected, Finding.Recorded |

**Rework na Delivery:** conceito legítimo de retorno ao desenvolvimento. Poderia ter
análogo na Diligence? O ciclo Async tem `Repair.Started/Completed`, que cobre a retomada
de trabalho após divergência — mas usa a category Phase Lifecycle, não Rework. Existe
uma diferença conceitual: Rework é iniciado por falha de qualidade (Gate.Failed,
Review.ChangesRequested) dentro do ciclo normal; Repair é um ciclo independente acionado
por Scan. São conceitos distintos.

**Diligence na Diligence:** conceito legítimo de auditoria. Poderia haver tipos Diligence
em outras Journeys? Não no MVP atual — mas `Finding.Recorded` poderia ser relevante em
uma Journey Operation ou Assessment. A category está bem-posicionada como domain-specific
mas não Journey-exclusive no longo prazo.

### 2.3 Categories subutilizadas (sem nenhum tipo em nenhum dos dois catálogos)

| Category | Tipos em Delivery | Tipos em Diligence | Comentário |
|---|---|---|---|
| **System** | 0 | 0 | Ausente nos dois MVPs — eventos automáticos de infraestrutura |
| **Correction** | 0 | 0 | Ausente nos dois MVPs — pattern de correção de erros de timeline |

**System:** a ausência é esperada nos MVPs. Events do tipo `CI.Triggered`, `Deploy.Initiated`,
`Webhook.Received` seriam candidatos. Não há urgência — o OEM suporta a category, apenas
não há tipos definidos ainda.

**Correction:** a ausência é esperada e correta. `Event.Corrected` é um tipo especial que
só deve ser criado quando um erro de registro real precisar ser corrigido na Timeline. Não
faz sentido criar types de Correction preventivamente.

---

## 3. Reutilização semântica

Os tipos com semântica verdadeiramente idêntica nas duas Journeys são:

| Event Type | Semântica compartilhada | Evidência |
|---|---|---|
| `Gate.Passed` | "Gate automatizado passou — critério verificado com sucesso" | Delivery e Diligence, payload idêntico, producers idênticos |
| `Gate.Failed` | "Gate automatizado falhou — critério não satisfeito" | Delivery e Diligence, payload idêntico, producers idênticos |
| `Impediment.Declared` | "Impedimento externo declarado — trabalho suspenso (BLOCKED)" | Delivery e Diligence, payload idêntico, producers idênticos |

`Impediment.Resolved` possui semântica idêntica mas implementação divergente — está em
estado de "equivalência pendente de convergência técnica" (ver seção 4).

Estes são os verdadeiros candidatos a Shared Type. Não existe nenhum outro tipo nos dois
catálogos com semântica genuinamente equivalente — os demais pares com nome idêntico
(`Promote.*`) foram confirmados como colisões de naming, não equivalências semânticas.

---

## 4. Conflitos

### Conflito 1 — `Impediment.Resolved`: alters_state divergente (CRÍTICO)

| Aspecto | Delivery | Diligence |
|---|---|---|
| alters_state | `true` | `false` |
| new_state | `HACKING` (hardcoded) | — (Lookback) |

**Tipo:** inconsistência técnica entre implementações do mesmo conceito.

**Causa:** a Delivery usou uma simplificação MVP documentada. A Diligence implementou o
padrão correto do OEM (Lookback via `preBlockedState`).

**Risco:** se promovido a Shared Type agora, o tipo teria `alters_state = false` (padrão
correto da Diligence) — mas o catálogo Delivery ainda declara `alters_state = true`. O
Shared Type entraria em conflito direto com o catálogo Delivery v1. Um Consumer lendo
a Timeline da Delivery encontraria `Impediment.Resolved` com `alters_state = true` (no
catálogo da Delivery) e `alters_state = false` (no catálogo Shared) — impossível reconciliar.

**Resolução necessária:** atualizar `Impediment.Resolved` no catálogo Delivery para
`alters_state = false` (Delivery v2) antes de promover para Shared Type.

**Impacto:** bloqueante para a promoção de Impediment.Resolved — não bloqueante para
Gate.Passed, Gate.Failed, ou Impediment.Declared.

---

### Conflito 2 — `Promote.Approved`: colisão de naming (MÉDIO)

| Aspecto | Delivery | Diligence |
|---|---|---|
| Precondition | VALIDATING | ATTACHED |
| Contexto | Deploy em produção | Promoção de readiness |
| Payload | environment_validated | readiness_criteria |

**Tipo:** colisão de naming — mesmo token `Promote.Approved`, domínios distintos.

**Risco:** uma Journey futura que precise de um "Promote.Approved" genérico terá que
escolher entre os dois contextos existentes — ou criar um terceiro token. O namespace
(`Delivery.Promote.Approved` vs. `Diligence.Promote.Approved`) mitiga o risco no
catálogo atual, mas a colisão pode criar confusão em análises cross-Journey.

**Resolução sugerida:** nenhuma ação imediata necessária — os namespaces Delivery e
Diligence são qualificadores suficientes. Documentar o risco nos catálogos.

---

### Conflito 3 — `Promote.Rejected`: alters_state divergente + colisão (MÉDIO)

| Aspecto | Delivery | Diligence |
|---|---|---|
| alters_state | `true` (retorna a VALIDATING) | `false` (permanece ATTACHED) |
| Precondition | VALIDATING | ATTACHED |

**Tipo:** colisão de naming com comportamento técnico conflitante — mais grave que
`Promote.Approved` porque `alters_state` também diverge.

**Resolução sugerida:** sem ação imediata. O comportamento divergente reflete diferenças
operacionais legítimas entre as duas Journeys. Não há tentativa de equivalência aqui.

---

### Conflito 4 — `Promote.Completed`: new_state incompatível (BAIXO)

| Aspecto | Delivery | Diligence |
|---|---|---|
| new_state | DONE (terminal) | PROMOTED (não-terminal) |
| Producer | System | Human, Agent |

**Tipo:** colisão de naming com estados de destino incompatíveis.

**Risco:** o mais "inocente" dos conflitos — qualquer Consumer que leia `new_state`
consegue distinguir trivialmente. Mas a colisão de naming pode confundir análises de
alto nível.

**Resolução sugerida:** sem ação imediata. Os namespaces e `new_state` distintos são
suficientes para distinguir os dois tipos.

---

## 5. Shared Type Candidates

### 5.1 Tabela de candidatos

| Event Type | Journeys | Justificativa | Nível de confiança | Bloqueio |
|---|---|---|---|---|
| `Gate.Passed` | Delivery, Diligence | Semanticamente idêntico, estruturalmente idêntico, producers idênticos, payload idêntico; o conceito de "gate automatizado passou" é independente de Journey | **Alta** | Nenhum |
| `Gate.Failed` | Delivery, Diligence | Idem — par complementar de Gate.Passed | **Alta** | Nenhum |
| `Impediment.Declared` | Delivery, Diligence | Semanticamente idêntico, estruturalmente idêntico, producers idênticos, payload idêntico; bloqueio por impedimento externo é genuinamente transversal | **Alta** | Nenhum |
| `Impediment.Resolved` | Delivery, Diligence | Semântica idêntica — "impedimento resolvido, retomar trabalho"; implementação técnica diverge (alters_state true vs false) | **Média** | Requer Delivery v2 (alters_state → false) |

### 5.2 Candidatos descartados

| Event Type | Motivo do descarte |
|---|---|
| `Promote.Approved` | Colisão de naming — semânticas diferentes (deploy em produção vs. promoção de readiness) |
| `Promote.Rejected` | Colisão de naming + alters_state conflitante |
| `Promote.Completed` | Colisão de naming + new_state incompatível |

---

## 6. Lacunas

### 6.1 Tipos que existem em uma Journey mas deveriam existir na outra

#### Rework na Diligence?

A Delivery tem `Rework.Declared` e `Rework.Completed` (category: Rework) para modelar
retorno ao desenvolvimento por qualidade insuficiente.

A Diligence tem `Repair.Started` e `Repair.Completed` (category: Phase Lifecycle) para
modelar reparo de divergências.

**São lacunas diferentes?** Não — são conceitos distintos. O Rework da Delivery é acionado
por falha dentro do ciclo principal (Gate.Failed, Review.ChangesRequested). O Repair da
Diligence é acionado por varredura assíncrona externa. A ausência de `Rework.*` na Diligence
não é uma lacuna — é uma diferença operacional justificada.

**Lacuna real:** o ciclo Diligence Sync não tem eventos para revisão humana que antecedem
`Promote.Approved` — existe um espaço implícito de "revisão de readiness" sem representação
no catálogo. `Review.Approved` / `Review.ChangesRequested` da Delivery cobrem o equivalente
no CI. A Diligence salta diretamente de ATTACHED para `Promote.Approved` sem registrar
o processo de revisão intermediário.

**Candidato para Diligence v2:** `Review.Approved` (revisão de readiness concluída,
state permanece ATTACHED) e `Review.ChangesRequested` (revisão de readiness solicitou
correções).

#### Bloqueio na Diligence Async pós-REPAIRED?

A Diligence não tem um evento para "novo ciclo de varredura acionado após REPAIRED".
Quando o Work Item está em REPAIRED e um novo ciclo Async começa, `Scan.Started` é
emitido — o que faz sentido, mas o estado de REPAIRED → SCANNING não tem um evento
explícito de transição que documente "reinício do ciclo". Isso é uma lacuna menor —
`Scan.Started` cobre o caso, mas poderia haver um `Scan.Initiated` para disambiguar
o trigger.

**Classificação:** lacuna menor — o MVP cobre o caso funcionalmente.

#### Ausência de eventos System em ambos os catálogos

Nenhum catálogo tem tipos na category System. Eventos de infraestrutura como
`Pipeline.Triggered`, `Webhook.Received`, `Deploy.Queued` são naturalmente candidatos
mas foram deixados para catálogos v2. Esta é uma lacuna intencional dos MVPs.

**Candidatos para futuros catálogos v2:** System category em ambas as Journeys.

---

### 6.2 Resumo das lacunas

| Lacuna | Journey afetada | Prioridade | Ação sugerida |
|---|---|---|---|
| Revisão humana antes de Promote.Approved (Diligence Sync) | Diligence | Média | `Review.Approved` + `Review.ChangesRequested` em Diligence v2 |
| Tipos de category System | Delivery e Diligence | Baixa | Defer para catálogos v2 |
| Transição explícita REPAIRED → SCANNING | Diligence | Baixa | `Scan.Initiated` em Diligence v2 |

---

## 7. Maturidade do OEM

### 7.1 Consistência do OEM nas duas implementações

**O OEM permaneceu consistente nas duas implementações.** Evidência:

| Invariante do OEM | Delivery | Diligence |
|---|---|---|
| Event Type Schema (12 VALs) satisfeito por todos os tipos | Sim — 17/17 | Sim — 20/20 |
| Naming convention `Subject.Action` PascalCase | Sim — 17/17 | Sim — 20/20 |
| `alters_state = true` exige `new_state` definido | Sim | Sim |
| `alters_state = false` sem `new_state` | Sim | Sim |
| Timeline append-only com timestamps não-decrescentes | Respeitado nos fluxos | Respeitado nos fluxos |
| Derived State como projeção — nunca armazenado | Respeitado | Respeitado |
| Lookback como operação de Consumer — não como campo | — | Sim (Impediment.Resolved) |
| Nenhum novo campo ou category necessário | Confirmado | Confirmado |

### 7.2 Pontos que poderiam indicar necessidade de revisão do OEM

**Ponto 1: Impediment.Resolved — inconsistência de implementação**

A inconsistência de `alters_state` entre os dois catálogos não é uma fraqueza do OEM —
é uma consequência de uma simplificação MVP documentada e deliberada na Delivery. O OEM
(`timeline.md`) define corretamente o padrão Lookback. A Diligence o implementou. A
Delivery o simplificou com ciência. O OEM é o árbitro correto — e está certo.

**Não é necessidade de revisão do OEM. É necessidade de atualização do catálogo Delivery.**

**Ponto 2: Colisões de naming em `Promote.*`**

O naming convention `Subject.Action` pode gerar colisões quando "Subject" representa
conceitos diferentes em Journeys diferentes. `Promote` na Delivery é "deploy em produção";
`Promote` na Diligence é "promoção de readiness". O OEM não proíbe isso — os namespaces
`Delivery.Promote.*` vs. `Diligence.Promote.*` são a solução.

**Não é necessidade de revisão do OEM. É um comportamento esperado do modelo.**
A alternativa seria forçar nomes únicos globalmente — o que criaria `DeliveryPromote.Approved`
e `DiligencePromote.Approved`, que é pior. O namespace é o isolador correto.

**Ponto 3: category Rework ausente na Diligence**

A ausência da category Rework na Diligence não indica que o OEM está incompleto — indica
que a Diligence tem um modelo de retorno ao trabalho diferente (Repair como ciclo Async
independente). A category Rework está disponível para qualquer Journey que precise — a
Diligence simplesmente não precisa dela.

**Não é necessidade de revisão do OEM. É uma diferença operacional entre Journeys.**

### 7.3 Avaliação final da maturidade

**O OEM não necessita de revisão.** As duas implementações confirmam que:

1. O Event Type Schema é expressivo o suficiente para capturar dois modelos operacionais
   completamente diferentes sem extensão.
2. O modelo de Lifecycle é aplicável a ambos os catálogos.
3. O mecanismo de Lookback — formalizado no `timeline.md` antes de ser usado — resolveu
   um problema real na Diligence sem precisar alterar o modelo.
4. As 8 Event Categories cobriram 5 das categorias necessárias para ambas as Journeys,
   com as 3 restantes (System, Correction, e uma ausente por opção) disponíveis para uso.
5. O naming convention `Subject.Action` funcionou corretamente — as colisões em `Promote.*`
   são resolvidas pelos namespaces de Journey, conforme previsto.

O OEM atingiu o objetivo de ser um modelo transversal reutilizável. Nenhuma decisão
arquitetural anterior precisa ser revisada com base nesta análise.

---

## 8. Recomendação Objetiva

### O Framework já possui evidência suficiente para criar `shared-types.md`?

**Sim. O Framework possui evidência suficiente para criar `shared-types.md`.**

**Base da recomendação:**

Os critérios CRT-01 a CRT-05 (definidos em `lifecycle.md`) foram verificados para os três
candidatos de alta confiança:

| Critério | Gate.Passed | Gate.Failed | Impediment.Declared |
|---|---|---|---|
| CRT-01: Reutilização ativa em dois ou mais Journeys | ✓ Delivery + Diligence | ✓ Delivery + Diligence | ✓ Delivery + Diligence |
| CRT-02: Semântica equivalente verificada | ✓ Idêntica | ✓ Idêntica | ✓ Idêntica |
| CRT-03: Estabilidade — sem mudança desde introdução | ✓ v1.0.0 em ambos | ✓ v1.0.0 em ambos | ✓ v1.0.0 em ambos |
| CRT-04: Generalidade — não perde precisão ao promover | ✓ Payload é genérico | ✓ Payload é genérico | ✓ Payload é genérico |
| CRT-05: Sem duplicata no catálogo Shared | ✓ Catálogo Shared vazio | ✓ Catálogo Shared vazio | ✓ Catálogo Shared vazio |

**Ação recomendada:**

1. Criar `prodops/framework/events/shared-types.md` com os 3 tipos de alta confiança:
   - `Gate.Passed`
   - `Gate.Failed`
   - `Impediment.Declared`

2. Documentar `Impediment.Resolved` no arquivo como "Pending" — candidato confirmado
   que aguarda Delivery v2 (atualização de `alters_state` para `false`).

3. Atualizar o catálogo Delivery v2 com `Impediment.Resolved → alters_state = false`
   para que o quarto candidato possa ser promovido em seguida.

**O que NÃO fazer agora:**
- Não promover `Promote.*` — são colisões de naming, não equivalências.
- Não promover `Rework.*` — presentes apenas na Delivery.
- Não promover `Impediment.Resolved` antes de corrigir a Delivery.

---

## 9. Arquivos Criados e Alterados

### Criados

| Arquivo | Conteúdo |
|---|---|
| `prodops/documentation-review-cross-journey-event-analysis.md` | Este documento |

### Alterados

Nenhum arquivo existente foi alterado.
