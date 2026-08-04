# Ciclo de Vida dos Event Types — Operational Event Model
# ProdOps Framework

> **Domínio:** Framework — aplicável a todas as Journeys
> **Status:** Canônico
> **Versão:** 1.0.0
> **Depende de:** [README.md](README.md) · [ontology.md](ontology.md) · [taxonomy.md](taxonomy.md)

---

## Sobre este documento

Este documento formaliza o ciclo de vida dos **Event Types** do Operational Event Model:
como nascem, evoluem, são promovidos a compartilhados, depreciados e removidos ao longo
do tempo.

Este documento não define schema, implementação, formato de armazenamento nem catálogos
concretos por Journey. Trata exclusivamente da governança da evolução dos tipos.

→ [Taxonomia OEM](taxonomy.md) · [Ontologia OEM](ontology.md) · [Fundação OEM](README.md)

---

## 1. Ciclo de Vida Canônico

### 1.1 Dois modelos de ciclo de vida

Os Event Types possuem dois ciclos de vida distintos, correspondentes aos seus dois
registros possíveis na Taxonomia:

**Modelo A — Journey Event Type** (definido e governado por uma Journey):

```
[ Draft ] ──────────────────────────────────────→ [ Active ]
    │                                                  │
    │ (aprovação pela Journey)                         │ (Journey ou Framework)
    │                                                  ↓
    │                                           [ Deprecated ]
    │                                                  │
    └──────────────────────────────────────────→       │ (critérios satisfeitos)
                                                       ↓
                                                [ Removed ]
                                                       │
                                    (Timelines históricas preservam referência)
```

**Modelo B — Shared Event Type** (definido pelo Framework, reutilizável por qualquer Journey):

```
[ Draft ]
    │
    │ (Journey submete proposta ao Framework)
    ↓
[ Proposed ] ──→ (Framework recusa) ──→ retorna ao Journey como Draft ou Active
    │
    │ (Framework aprova)
    ↓
[ Active ] ─────────────────────────────────────────────────────────────────
    │                                                                       │
    │ (Framework)                                                           │
    ↓                                                                       │
[ Deprecated ] ─────────────────────────────────────────────────────────── │
    │                                                                       │
    │ (critérios satisfeitos)                                               │ (excepcional)
    ↓                                                                       ↓
[ Removed ]                                                            [ Restored ]
    │
    (Timelines históricas preservam referência)
```

### 1.2 Estados canônicos

| Estado | Aplicável a | Autoriza emissão? | Quem mantém |
|---|---|---|---|
| **Draft** | Journey Type · Shared Type (em elaboração) | Não | Journey |
| **Proposed** | Shared Type (em revisão pelo Framework) | Não | Framework |
| **Active** | Journey Type · Shared Type | Sim | Journey / Framework |
| **Deprecated** | Journey Type · Shared Type | Não (apenas legado) | Journey / Framework |
| **Removed** | Journey Type · Shared Type | Não | Journey / Framework |
| **Restored** | Qualquer tipo previamente Deprecated | Sim — após restauração | Quem depreciou |

### 1.3 Definição de cada estado

**Draft**
O tipo está sendo elaborado — ainda não possui todas as propriedades obrigatórias, ou
ainda não passou pela verificação de duplicatas e conformidade. Nenhuma Skill pode emitir
eventos deste tipo enquanto ele estiver em Draft.

**Proposed**
Estado exclusivo do processo de promoção a Shared Type. O tipo foi submetido ao Framework
para revisão cross-Journey. Nenhuma Skill pode emitir eventos deste tipo enquanto ele estiver
em Proposed (o tipo Journey original permanece Active durante a revisão).

**Active**
O tipo está aprovado, completamente documentado e disponível para emissão. Skills podem e
devem emitir eventos deste tipo quando as precondições são satisfeitas.

**Deprecated**
O tipo não deve mais ser emitido por novos Steps/Skills. Eventos já registrados com este tipo
em Timelines existentes permanecem válidos e imutáveis. Event Consumers devem continuar
reconhecendo o tipo para processamento de histórico.

**Removed**
O tipo foi removido do catálogo ativo. Nenhuma nova emissão é possível. Timelines históricas
que contêm eventos deste tipo continuam válidas — o tipo é preservado como referência
read-only no catálogo histórico. Event Consumers que processam Timelines históricas devem
tratar o tipo como válido para leitura.

**Restored**
Estado transitório: um tipo Deprecated voltou a ser Active por decisão fundamentada. Restored
não é um estado final — o tipo transita imediatamente para Active após a restauração ser
aprovada. O histórico de depreciação é preservado no registro do tipo.

---

## 2. Transições

### 2.1 Tabela de transições

| De | Para | Quem inicia | Condições |
|---|---|---|---|
| Draft | Active | Journey governance | Propriedades completas; sem duplicata semântica; REG-01 a REG-10 satisfeitos |
| Draft | Proposed | Journey governance | Type é candidato a Shared; proposta formal ao Framework |
| Proposed | Active (Shared) | Framework | Revisão concluída; critérios de promoção satisfeitos |
| Proposed | Draft | Framework | Revisão recusada; Journey recebe feedback |
| Active | Deprecated | Journey (Journey Type) · Framework (Shared Type) | Replacement disponível; razão documentada |
| Active | Proposed | Journey governance | Promoção iniciada; tipo Journey original permanece Active durante revisão |
| Deprecated | Removed | Journey (Journey Type) · Framework (Shared Type) | Critérios de remoção satisfeitos |
| Deprecated | Restored | Quem depreciou | Depreciação foi prematura; revisão de compatibilidade realizada |
| Restored | Active | Quem restaurou | Restauração aprovada — transição imediata |

### 2.2 Detalhamento de cada transição

---

#### Draft → Active (Journey Event Type)

**Quem pode iniciar:** a governança da Journey (quem aprova mudanças estruturais na Journey).

**Pré-condições:**
- Todas as propriedades obrigatórias estão preenchidas (`name`, `category`, `alters_state`,
  `producer_subtypes`, `preconditions`, `postconditions`, `status`, `introduced_in`)
- O nome segue a convenção `Subject.Action` da Taxonomia
- Foi realizada verificação de duplicatas nos catálogos de todas as Journeys e nos tipos
  compartilhados — nenhuma duplicata semântica encontrada
- REG-01 a REG-10 da Taxonomia estão satisfeitos
- Se `alters_state = true`, o `new_state` está documentado e é consistente com o modelo
  de Derived State da Journey
- A Category declarada existe no catálogo da Taxonomia
- INV-TAX-04 é satisfeito: a Category permite `alters_state = true` se o tipo o declara

**Evidências necessárias:**
- Definição completa no catálogo da Journey
- Registro do resultado da verificação de duplicatas

**Pós-condições:**
- O tipo pode ser emitido por Skills da Journey
- Event Consumers que processam a Journey devem reconhecer o tipo
- A versão do catálogo é incrementada

---

#### Draft → Proposed (início de promoção a Shared)

**Quem pode iniciar:** a Journey que é dona do tipo Journey ativo que está sendo proposto
para promoção.

**Pré-condições:**
- O tipo Journey está em status Active (não é possível propor um Draft diretamente como Shared)
- Há evidência de reutilização comprovada ou necessidade cross-Journey demonstrada (ver seção 3)
- A proposta está completa: inclui análise de semântica cross-Journey, lista de Journeys
  que usariam o tipo, e proposta de nome no catálogo compartilhado

**Evidências necessárias:**
- Proposta formal com análise de semântica
- Evidência de uso ou solicitação por pelo menos uma Journey adicional

**Pós-condições:**
- O tipo Journey original permanece Active durante toda a revisão
- O Framework assume a responsabilidade de revisão
- Nenhuma nova emissão do tipo Proposed é permitida (não é um tipo emissível neste estado)

---

#### Proposed → Active (aprovação pelo Framework como Shared Type)

**Quem pode iniciar:** exclusivamente o Framework.

**Pré-condições:**
- A revisão cross-Journey está concluída
- Nenhum tipo no catálogo compartilhado existente tem semântica equivalente
- O nome proposto não colide com nenhum tipo existente em nenhum catálogo
- Os critérios de promoção da seção 3 estão satisfeitos
- As Journeys que usarão o tipo foram consultadas e confirmaram compatibilidade

**Evidências necessárias:**
- Registro de revisão do Framework com decisão fundamentada
- Lista de Journeys que adotarão o tipo compartilhado

**Pós-condições:**
- O tipo é adicionado ao catálogo de tipos compartilhados com status Active
- O tipo Journey original (que originou a proposta) é automaticamente Deprecated com
  referência ao tipo compartilhado como substituto
- Journeys que usavam o tipo Journey original são notificadas para migrar emissão para
  o tipo compartilhado
- As Timelines históricas com o tipo Journey original permanecem válidas

---

#### Proposed → Draft (recusa pelo Framework)

**Quem pode iniciar:** o Framework, após revisão.

**Pré-condições:**
- A revisão concluiu que a promoção não é adequada (tipo duplicado, semântica insuficientemente
  genérica, naming inadequado, etc.)

**Evidências necessárias:**
- Registro de recusa com feedback estruturado para a Journey

**Pós-condições:**
- O tipo Journey original permanece Active (a recusa não o afeta)
- A Journey pode ajustar a proposta e tentar novamente, ou manter o tipo como exclusivo da Journey
- O feedback é registrado no catálogo da Journey para referência futura

---

#### Active → Deprecated

**Quem pode iniciar:**
- Journey (para Journey Event Types)
- Framework (para Shared Event Types)

**Pré-condições:**
- Existe um tipo substituto em status Active (salvo depreciação por obsolescência sem substituto)
- A razão da depreciação está documentada
- Todas as Skills que emitiam o tipo foram identificadas (não necessariamente migradas —
  a migração pode ocorrer após a depreciação)
- O tipo substituto foi comunicado aos Event Consumers relevantes

**Evidências necessárias:**
- `deprecated_in`: versão do catálogo em que ocorreu a depreciação
- `deprecation_reason`: razão textual
- `replacement_type`: referência ao tipo substituto (quando aplicável)
- `migration_deadline`: data ou ciclo até a qual a emissão do tipo depreciado ainda é tolerada

**Pós-condições:**
- O tipo não deve mais ser emitido por novos Steps
- Skills existentes que emitem o tipo continuam válidas durante o período de migração
- Event Consumers continuam reconhecendo o tipo para leitura de histórico
- O tipo permanece no catálogo como referência para as Timelines históricas

---

#### Deprecated → Removed

**Quem pode iniciar:**
- Journey (para Journey Event Types)
- Framework (para Shared Event Types)

**Pré-condições:**
- Nenhuma nova emissão do tipo ocorreu após a `migration_deadline`
- Todas as Skills que emitiam o tipo foram atualizadas para o tipo substituto (ou removidas)
- Os Event Consumers confirmaram que tratam o tipo como histórico e não o processam em
  contexto ativo
- O período mínimo de depreciação foi respeitado (pelo menos um ciclo completo de Journey
  sem novas emissões)

**Evidências necessárias:**
- `removed_in`: versão do catálogo em que ocorreu a remoção
- `removal_reason`: confirmação de que os critérios foram satisfeitos
- Registro de que Timelines históricas com o tipo são reconhecidas como válidas

**Pós-condições:**
- O tipo é marcado como Removed no catálogo ativo
- O tipo permanece como entrada read-only no catálogo histórico (para que Event Consumers
  possam decodificar Timelines antigas)
- Nenhuma nova emissão é possível — sistemas que tentarem emitir o tipo devem receber erro

---

#### Deprecated → Restored → Active

**Quem pode iniciar:** quem depreciou o tipo (Journey para Journey Types; Framework para
Shared Types).

**Condição para restauração:**
- A depreciação foi prematura — o tipo substituto provou ser inadequado, ou a razão da
  depreciação não se confirmou
- A restauração não viola compatibilidade histórica
- Nenhuma Timeline foi corrompida pelo período de depreciação

**Pré-condições:**
- O tipo ainda está em status Deprecated (não Removed)
- A análise de compatibilidade confirma que restaurar o tipo não cria ambiguidade com
  eventos emitidos durante o período de depreciação
- A decisão de restauração é documentada com justificativa

**Pós-condições:**
- O tipo retorna ao status Active
- O histórico de depreciação é preservado no registro do tipo (o tipo foi Deprecated e
  foi Restored — isso é informação relevante para a auditoria)
- Se havia um tipo substituto, ele permanece Active — os dois coexistem com clareza

---

## 3. Shared Event Types — Quando Promover

### 3.1 A decisão de promoção

> Um Journey Event Type deve permanecer exclusivo de sua Journey enquanto houver dúvida
> razoável de que a semântica é específica ao contexto da Journey.
>
> Ele deve ser promovido a Shared Event Type quando a semântica for comprovadamente
> equivalente e reutilizável em múltiplos contextos de Journey.

### 3.2 Critérios de promoção — todos devem ser satisfeitos

**CRT-01 — Reutilização ativa ou comprovada**
O tipo está sendo solicitado por pelo menos uma Journey adicional para um acontecimento
com semântica equivalente, OU há uso atual em uma Journey e evidência clara de que outras
Journeys precisarão do mesmo tipo em breve.

**CRT-02 — Equivalência semântica verificada**
As precondições e pós-condições do tipo fazem sentido no contexto de todas as Journeys
que o usariam, sem exigir adaptação semântica. Se qualquer Journey precisar "ajustar o
significado", o tipo não é candidato a Shared.

**CRT-03 — Estabilidade demonstrada**
O tipo esteve Active na Journey de origem por pelo menos um ciclo completo sem mudanças
em suas propriedades críticas (Category, `alters_state`, `new_state`). Tipos instáveis não
devem ser promovidos.

**CRT-04 — Generalidade sem perda de precisão**
O nome do tipo continua preciso e auto-descritivo fora do contexto da Journey de origem.
`Gate.Failed` é genérico o suficiente sem perder significado. `BootstrapSmokeGate.Failed`
é específico demais para ser Shared.

**CRT-05 — Sem duplicata no catálogo compartilhado**
Nenhum tipo com semântica equivalente já existe no catálogo de tipos compartilhados.
Se existir, a Journey deve migrar para o tipo existente — não criar um segundo Shared Type
concorrente.

### 3.3 Critérios que não justificam promoção

| Critério inadequado | Por quê é insuficiente |
|---|---|
| "Pode ser útil no futuro" | Violaria ANT-LC-01 (promoção prematura) |
| "O nome é similar ao de outra Journey" | Similaridade de nome ≠ equivalência semântica |
| "Seria mais organizado como Shared" | Organização não é critério arquitetural |
| "A Journey quer usar o tipo de outra Journey" | Import direto é ANT-TAX-09; promoção é a solução correta |

### 3.4 Quando não promover (manter como Journey Type)

Um tipo deve permanecer exclusivo da Journey quando:

- A semântica é genuinamente específica ao contexto da Journey (ex.: `Bootstrap.SmokeGate.Failed`
  faz sentido apenas em Delivery, onde Bootstrap é uma Phase com gate de smoke test)
- O tipo está em Draft ou foi modificado recentemente (instabilidade)
- Nenhuma outra Journey demonstrou necessidade do mesmo tipo
- A promoção exigiria renomear o tipo — o que viola INV-LC-06

---

## 4. Processo de Promoção

### 4.1 Fluxo canônico de promoção

```
Fase 1 — Identificação (Journey)
│
│  • Journey identifica que seu tipo Journey ativo está sendo
│    solicitado por outra Journey com semântica equivalente
│  • Journey verifica CRT-01 a CRT-05
│  • Journey confirma que não existe Shared Type equivalente
│
↓

Fase 2 — Elaboração da Proposta (Journey)
│
│  • Journey elabora a proposta de promoção com:
│    - análise de semântica cross-Journey
│    - lista das Journeys que usariam o tipo
│    - proposta de nome no catálogo compartilhado
│    - análise de compatibilidade histórica
│    - proposta de plano de migração para o tipo Journey original
│
↓

Fase 3 — Submissão (Journey → Framework)
│
│  • Tipo Journey transita para estado Proposed
│  • Tipo Journey original permanece Active
│  • Nenhuma nova emissão do "Proposed" é permitida
│
↓

Fase 4 — Revisão (Framework)
│
│  • Framework verifica CRT-01 a CRT-05
│  • Framework consulta Journeys que usariam o tipo
│  • Framework verifica ausência de duplicata no catálogo compartilhado
│  • Framework decide: Aprovado | Recusado | Aprovado com ajustes
│
↓

Fase 5A — Aprovação (Framework)          │  Fase 5B — Recusa (Framework)
│                                         │
│  • Tipo adicionado ao catálogo           │  • Tipo retorna ao status Draft
│    compartilhado como Active             │    na Journey
│  • Tipo Journey original → Deprecated   │  • Framework fornece feedback
│    (referência ao Shared como substituto)│  • Journey pode ajustar e
│  • Journeys migram emissão para Shared  │    re-submeter, ou manter
│                                         │    como Journey Type
↓

Fase 6 — Migração (Journeys afetadas)
│
│  • Skills atualizadas para emitir o Shared Type
│  • Timelines históricas com o tipo Journey original: válidas e preservadas
│  • Tipo Journey original permanece no catálogo como Deprecated (read-only histórico)
│
↓

[ Shared Type Active — disponível para todas as Journeys ]
```

### 4.2 Garantias do processo de promoção

- O tipo Journey original **nunca é deletado** — apenas depreciado com referência ao Shared Type
- Timelines históricas com o tipo Journey original **permanecem válidas** — a promoção
  não quebra retrocompatibilidade
- O Shared Type **herda a semântica** do tipo Journey original — não é uma entidade nova
  com semântica diferente

---

## 5. Depreciação

### 5.1 Quando depreciar

Um Event Type deve ser depreciado quando:

| Situação | Critério |
|---|---|
| **Substituição** | Um tipo mais preciso ou mais adequado está disponível como substituto |
| **Redundância** | O tipo foi promovido a Shared Type (o tipo Journey original é automaticamente depreciado) |
| **Obsolescência** | O acontecimento que o tipo representava não ocorre mais no fluxo da Journey |
| **Refatoração de Phase** | Uma Phase foi renomeada ou reestruturada, tornando o tipo desatualizado |

### 5.2 Quando não depreciar

| Situação | O que fazer em vez de depreciar |
|---|---|
| "O nome poderia ser melhor" | Não depreciar; names de tipos ativos são imutáveis |
| "Tem pouco uso" | Pouco uso não é critério de depreciação; uso zero por um ciclo completo pode ser |
| "Queremos consolidar dois tipos similares" | Criar o tipo consolidado; deprecar os originais com referência ao novo |

### 5.3 Compatibilidade com Timelines históricas

A depreciação de um tipo nunca afeta Timelines históricas. A razão é ontológica: eventos
são imutáveis (INV-02 da Ontologia). Um evento registrado com um tipo depreciado é válido
— ele registra um fato que ocorreu quando o tipo era Active.

**O que muda com a depreciação:**
- Skills não devem emitir o tipo
- Novos catálogos de Journey não devem referenciar o tipo como ativo
- Documentação do catálogo marca o tipo como Deprecated com razão e substituto

**O que não muda:**
- Eventos históricos com o tipo depreciado — permanecem inalterados
- O significado desses eventos — o tipo depreciado ainda é reconhecido pelos Consumers
- A Timeline do Work Item — não é alterada pela depreciação do tipo

### 5.4 Período de depreciação

O período de depreciação deve ser suficiente para que:

1. Todas as Skills ativas que emitiam o tipo sejam identificadas
2. Todas essas Skills sejam atualizadas para o tipo substituto
3. Os Event Consumers sejam notificados sobre a depreciação
4. Pelo menos um ciclo completo de Journey transcorra sem novas emissões do tipo depreciado

Não existe um período mínimo em dias ou semanas — a depreciação é orientada a ciclos de
Journey, não a calendário.

---

## 6. Compatibilidade

### 6.1 Contrato de compatibilidade do OEM

> Qualquer mudança no ciclo de vida de um Event Type deve preservar a capacidade de
> Event Consumers processarem Timelines históricas com eventos do tipo afetado.

Este contrato é incondicional. A compatibilidade com histórico nunca pode ser sacrificada
por conveniência de implementação ou de reorganização.

### 6.2 Como Event Consumers tratam tipos depreciados e removidos

| Status do tipo | Como o Consumer deve tratar |
|---|---|
| **Active** | Processa normalmente — o tipo está em uso ativo |
| **Deprecated** | Processa normalmente para histórico — o tipo é reconhecido; nova emissão é sinal de anomalia |
| **Removed** | Processa normalmente para histórico — o tipo existe no catálogo histórico read-only; nova emissão é erro |

### 6.3 Catálogo histórico (read-only)

O catálogo de tipos do OEM tem duas seções:

**Catálogo ativo:** tipos em status Draft, Proposed, Active, Deprecated — os que ainda
são gerenciados ativamente.

**Catálogo histórico (read-only):** tipos em status Removed — preservados exclusivamente
para que Event Consumers possam decodificar Timelines antigas. Nenhuma modificação é
permitida no catálogo histórico.

### 6.4 Auditoria de Timelines com tipos depreciados ou removidos

A presença de eventos com tipos Deprecated em uma Timeline ativa pode ser:

- **Normal:** o evento ocorreu quando o tipo ainda era Active — evento válido
- **Anomalia:** o evento foi emitido após a `migration_deadline` — sinal de que uma Skill
  não foi atualizada

A Diligence é responsável por distinguir os dois casos: verificar se o timestamp do evento
é anterior ou posterior à `deprecated_in` do tipo.

---

## 7. Governança

### 7.1 Mapa de responsabilidades

| Ação | Journey | Framework | Observação |
|---|---|---|---|
| **Criar** tipo em Draft | Sim | Não | Apenas a Journey dona do catálogo |
| **Aprovar** Draft → Active (Journey Type) | Sim | Não | Governança interna da Journey |
| **Propor** promoção a Shared | Sim (inicia) | Aprova | Journey inicia; Framework decide |
| **Aprovar** Proposed → Active (Shared) | Não | Sim | Exclusividade do Framework |
| **Recusar** promoção | Não | Sim | Com feedback obrigatório |
| **Deprecar** Journey Type | Sim | Não | Com critérios documentados |
| **Deprecar** Shared Type | Não | Sim | Com migração documentada |
| **Remover** Journey Type | Sim | Não | Após critérios satisfeitos |
| **Remover** Shared Type | Não | Sim | Após critérios satisfeitos |
| **Restaurar** tipo depreciado | Quem depreciou | Quem depreciou | Revisão de compatibilidade obrigatória |
| **Auditar** conformidade cross-Journey | Não | Sim | Verificar REG-01 a REG-10 |
| **Manter** catálogo histórico | Journey (Journey Types) | Framework (Shared Types) | Read-only após Removed |

### 7.2 Responsabilidades do Framework

O Framework é responsável por:

- Aprovar e publicar todos os Shared Event Types
- Manter o catálogo de tipos compartilhados (ativos e históricos)
- Arbitrar conflitos de nomenclatura e semântica entre Journeys
- Auditar periodicamente os catálogos das Journeys para conformidade com REG-01 a REG-10
- Comunicar depreciações de Shared Types a todas as Journeys afetadas
- Manter este documento (`lifecycle.md`) atualizado como referência de governança

### 7.3 Responsabilidades da Journey

Cada Journey é responsável por:

- Manter seu catálogo de Journey Event Types com versionamento
- Verificar duplicatas antes de propor qualquer tipo novo
- Executar o processo de promoção corretamente quando critérios são satisfeitos
- Atualizar Skills quando tipos são depreciados
- Notificar o Framework quando identificar necessidade de novo Shared Type
- Registrar a `deprecated_in`, `deprecation_reason` e `replacement_type` ao deprecar

---

## 8. Invariantes

### INV-LC-01 — Event Types históricos nunca desaparecem das Timelines

Timelines são imutáveis (INV-02 da Ontologia). Um evento registrado com qualquer tipo —
Active, Deprecated ou Removed — permanece na Timeline com o tipo original. Nenhum processo
de migração, depreciação ou remoção de tipo pode alterar eventos já registrados.

### INV-LC-02 — Shared Event Types nunca voltam a ser exclusivos de Journey

Uma vez que um tipo foi promovido a Shared e está Active no catálogo compartilhado, ele
pertence ao Framework — não pode ser "devolvido" a uma Journey. Se o tipo se mostrar
inadequado como Shared, ele deve ser depreciado e substituído por um tipo mais apropriado.

### INV-LC-03 — A promoção a Shared preserva compatibilidade histórica

O tipo Journey original que deu origem a um Shared Type é depreciado — nunca deletado.
Timelines históricas que contêm eventos do tipo Journey original continuam válidas. A
promoção não pode ser usada como mecanismo para invalidar histórico.

### INV-LC-04 — Depreciação nunca altera eventos existentes

Deprecar um tipo é uma operação exclusivamente no catálogo — não nas Timelines. Nenhum
evento já registrado muda seu `event_type` em decorrência de uma depreciação.

### INV-LC-05 — Remoção só ocorre após critérios satisfeitos

Um tipo não pode transitar de Deprecated para Removed sem que: (a) nenhuma nova emissão
tenha ocorrido após a `migration_deadline`, (b) todas as Skills relevantes tenham sido
atualizadas, e (c) os Event Consumers tenham confirmado tratamento histórico adequado.

### INV-LC-06 — Promoção não renomeia o tipo

Um Shared Type deve ter o mesmo nome que o tipo Journey original que o originou (salvo
ajuste de Namespace). Se o nome precisar mudar, o processo correto é: deprecar o tipo
Journey original, criar um novo tipo Journey com o nome correto, e propor esse novo tipo
para promoção.

### INV-LC-07 — Draft e Proposed não autorizam emissão

Nenhuma Skill pode emitir eventos de tipos em status Draft ou Proposed. Somente tipos
em status Active podem ser emitidos. Uma emissão de tipo Draft é um erro de processo —
não um evento válido.

### INV-LC-08 — O registro de histórico do ciclo de vida é preservado

Quando um tipo é Restored após depreciação, o histórico de que foi Deprecated e Restored
deve ser preservado no catálogo. Não é possível "apagar" o histórico de um ciclo de vida.
A trilha `Draft → Active → Deprecated → Restored → Active` é auditável.

---

## 9. Anti-padrões

### ANT-LC-01 — Promoção prematura

**O problema:** uma Journey promove um tipo a Shared Type após uma única solicitação de
uso por outra Journey, sem evidência de estabilidade ou equivalência semântica verificada.

**Consequência:** o Shared Type é instável e precisará ser depreciado cedo — gerando ruído
no catálogo compartilhado. O ciclo de vida de tipos compartilhados deve ser longo; emitir
um Shared Type instável compromete a confiabilidade do catálogo para todas as Journeys.

**Mitigação:** exigir que o tipo Journey esteja Active por pelo menos um ciclo completo (CRT-03)
antes de qualquer proposta de promoção.

---

### ANT-LC-02 — Criar Shared Types sem uso comprovado

**O problema:** o Framework cria tipos compartilhados "preventivamente" — antes de qualquer
Journey precisar deles — para "evitar duplicações futuras".

**Consequência:** o catálogo compartilhado acumula tipos sem uso. Quando uma Journey
finalmente precisar de um tipo similar, pode descobrir que o Shared Type existente não
tem a semântica adequada — mas está Active e não pode ser renomeado.

**Mitigação:** Shared Types nascem da promoção de Journey Types com uso comprovado —
nunca de previsão de uso futuro.

---

### ANT-LC-03 — Reutilizar nome com semântica diferente

**O problema:** após deprecar `Phase.Started`, uma Journey cria um novo tipo com o mesmo
nome (`Phase.Started`) com semântica ligeiramente diferente.

**Consequência:** Event Consumers que processam Timelines históricas não conseguem
distinguir qual versão do tipo está sendo referenciada. Métricas e auditorias ficam
corrompidas.

**Mitigação:** nomes de tipos Deprecated e Removed são reservados — não podem ser reutilizados.
Todo novo tipo deve ter um nome que nunca existiu no catálogo (ativo ou histórico).

---

### ANT-LC-04 — Alterar significado de um tipo Active

**O problema:** uma Journey atualiza as precondições de um tipo Active de forma a mudar
sua semântica — sem deprecar o tipo original e criar um novo.

**Consequência:** eventos históricos com o tipo são agora interpretados sob uma semântica
diferente da que existia quando foram emitidos. A Timeline perde integridade histórica.

**Mitigação:** types são imutáveis após aprovação (INV-TAX-01 da Taxonomia). Qualquer
mudança semântica exige deprecar o tipo e criar um novo.

---

### ANT-LC-05 — Remover tipo ainda presente em Timelines ativas

**O problema:** uma Journey remove um tipo do catálogo sem verificar se ainda há Timelines
ativas com eventos desse tipo.

**Consequência:** Event Consumers que encontrarem o tipo em Timelines não o reconhecerão
e poderão falhar ao processar. Métricas e auditorias ficam corrompidas.

**Mitigação:** INV-LC-05 exige critérios objetivos de remoção, incluindo a confirmação
de que Event Consumers tratam o tipo como histórico. Remoção prematura é proibida.

---

### ANT-LC-06 — Deprecar sem tipo substituto disponível

**O problema:** uma Journey depreca um tipo porque "não gosta do nome", sem ter um substituto
Active. Skills que emitiam o tipo ficam sem opção — param de emitir ou continuam emitindo
o depreciado.

**Consequência:** lacunas na Timeline — momentos de acontecimentos reais sem registro de
evento. P-07 (emissão obrigatória) é violado.

**Mitigação:** antes de deprecar, garantir que o tipo substituto está Active. Se não existe
substituto, criar e aprovar o novo tipo antes de deprecar o antigo.

---

### ANT-LC-07 — Draft eterno (zombie Draft)

**O problema:** um tipo fica em Draft indefinidamente — existe no catálogo mas nunca é
aprovado nem descartado. A Journey "está trabalhando nele" há múltiplos ciclos.

**Consequência:** o catálogo acumula ruído; outros que consultam o catálogo não sabem se
o tipo será aprovado; duplicatas podem ser criadas por outras Journeys que não viram o Draft.

**Mitigação:** Drafts devem ter uma `target_cycle` — o ciclo em que a aprovação é esperada.
Drafts sem progressão após dois ciclos devem ser descartados.

---

### ANT-LC-08 — Restauração sem revisão de compatibilidade

**O problema:** um tipo Deprecated é Restored sem verificar o que aconteceu durante o
período de depreciação — se havia emissões do tipo substituto com semântica sobreposta,
ou se Timelines já registraram ambos os tipos.

**Consequência:** duas versões do mesmo acontecimento na Timeline — representadas por tipos
diferentes. Métricas e Diligence não conseguem agregá-las consistentemente.

**Mitigação:** a transição Deprecated → Restored é sempre precedida de análise de
compatibilidade (o que foi emitido durante o período de depreciação? há sobreposição com
o tipo substituto?).

---

### ANT-LC-09 — Contornar promoção com import informal

**O problema:** Delivery decide simplesmente "usar" `Diligence.Scan.Completed` em suas
Timelines sem iniciar o processo formal de promoção.

**Consequência:** tipo de outra Journey referenciado em contexto errado; se Diligence
deprecar o tipo, Delivery quebra silenciosamente; análises cross-Journey colidem.

**Mitigação:** REG-09 da Taxonomia proíbe import informal. O processo de promoção é a
única forma válida de compartilhar tipos entre Journeys.

---

## 10. Relação com Documentos Futuros

### `events/shared-types.md`

O catálogo de tipos compartilhados depende diretamente deste Lifecycle para:

- O estado de cada tipo no catálogo (`Active`, `Deprecated`, `Removed`)
- As propriedades `deprecated_in`, `deprecation_reason`, `replacement_type` de tipos depreciados
- As propriedades `removed_in`, `removal_reason` de tipos removidos
- O registro de histórico do ciclo de vida de cada tipo compartilhado

### `events/schema.md`

O schema técnico de um Event Type depende deste Lifecycle para:

- Os campos obrigatórios do registro de um tipo: `status`, `introduced_in`, `deprecated_in`,
  `removed_in` — todos definidos conceitualmente aqui
- As regras de validação: um evento não pode referenciar um tipo em status Draft ou Proposed
- O tratamento de tipos Removed em registros históricos

### `journeys/*/events/catalog.md`

Cada catálogo de Journey depende deste Lifecycle para:

- Entender quando submeter um tipo para promoção a Shared (seção 3)
- Seguir o processo correto de deprecação (seção 5)
- Manter o catálogo com os campos de status de ciclo de vida
- Garantir que a remoção de um tipo satisfaça os critérios de INV-LC-05

---

## Referências

- [Fundação OEM](README.md)
- [Ontologia OEM](ontology.md)
- [Taxonomia OEM](taxonomy.md)
- [Ontologia do Framework](../ontology.md)
- Relatório da taxonomia OEM

---

*Este documento é a fonte canônica da governança de evolução dos Event Types no OEM.
Todo catálogo de eventos por Journey e todo documento de tipos compartilhados deve
referenciar este documento para as regras de criação, promoção, depreciação e remoção.*
