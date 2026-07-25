# Relatório — Ciclo de Vida dos Event Types (OEM)
# ProdOps Framework

> **Data:** 2026-07-21
> **Tipo:** Formalização de governança — exclusivamente conceitual
> **Status:** Concluído
> **Escopo:** `prodops/framework/events/lifecycle.md`

---

## 1. Executive Summary

O Ciclo de Vida dos Event Types foi formalizado como a governança completa de como um
Event Type nasce, evolui, é promovido a compartilhado, depreciado e removido ao longo do
tempo.

| Item | Resultado |
|---|---|
| Estados do ciclo de vida | 6 (Draft, Proposed, Active, Deprecated, Removed, Restored) |
| Transições formalizadas | 8 com precondições, evidências e pós-condições completas |
| Critérios de promoção (Shared Types) | 5 (CRT-01 a CRT-05) — todos devem ser satisfeitos |
| Processo de promoção | 6 fases com garantias de compatibilidade explícitas |
| Invariantes de ciclo de vida (INV-LC) | 8 (INV-LC-01 a INV-LC-08) |
| Anti-padrões documentados | 9 (ANT-LC-01 a ANT-LC-09) |
| Mapa de responsabilidades | Framework vs. Journey — 14 ações mapeadas |
| Documentos criados | 2 (`lifecycle.md` + este relatório) |
| Documentos alterados | 0 |
| Conceitos arquiteturais novos introduzidos | 0 |
| Decisões anteriores alteradas | Nenhuma |

---

## 2. O Modelo de Ciclo de Vida

### 2.1 Dois modelos distintos

A principal decisão estrutural foi separar o ciclo de vida em dois modelos, refletindo os
dois registros possíveis da Taxonomia:

**Modelo A — Journey Event Type:**
```
Draft → Active → Deprecated → Removed
```
Governado inteiramente pela Journey. Três fases de transição: aprovação interna, depreciação
por decisão da Journey, remoção após critérios satisfeitos.

**Modelo B — Shared Event Type:**
```
Draft → Proposed → Active → Deprecated → Removed
```
O estado `Proposed` é exclusivo do processo de promoção — quando um Journey Type é
submetido ao Framework para revisão cross-Journey.

**Por que dois modelos e não um único?**

O estado `Proposed` só existe no contexto de promoção a Shared. Criar um modelo único com
`Proposed` obrigatório para todos os tipos adicionaria burocracia desnecessária aos Journey
Types, que são aprovados pela própria Journey sem revisão externa. A separação reflete as
realidades de governança distintas.

### 2.2 O estado Restored

`Restored` foi incluído como estado transitório — não um estado final. Um tipo Deprecated
pode retornar a Active em casos excepcionais onde a depreciação foi prematura. O estado
`Restored` é imediatamente seguido de `Active` após aprovação.

A decisão de incluir `Restored` como estado explícito (em vez de apenas permitir a
transição silenciosa) serve a INV-LC-08: o histórico de que um tipo foi Deprecated e
Restored deve ser auditável. Omitir `Restored` como estado permitiria que a transição
ocorresse sem deixar registro.

### 2.3 O que cada estado autoriza

| Estado | Emissão | Leitura histórica | Modificação |
|---|---|---|---|
| Draft | Não | — | Permitida |
| Proposed | Não | — | Restrita (apenas pelo Framework) |
| Active | Sim | Sim | Proibida (INV-TAX-01) |
| Deprecated | Não | Sim | Apenas metadados de depreciação |
| Removed | Não | Sim | Proibida |
| Restored → Active | Sim | Sim | Proibida |

---

## 3. Decisões Tomadas

### DEC-LC-01 — Draft não autoriza emissão

**Decisão:** tipos em Draft não podem ser emitidos por nenhuma Skill.

**Justificativa:** se Draft permitisse emissão, haveria eventos em Timelines com tipos
que poderiam ser alterados antes da aprovação — violando a imutabilidade da relação entre
evento e tipo. Um evento historicamente registrado com um Draft que nunca foi aprovado
criaria um registro sem contrato formal.

**INV-LC gerado:** INV-LC-07.

---

### DEC-LC-02 — Promoção mantém o tipo Journey original como Deprecated (não Remove)

**Decisão:** quando um Journey Type é promovido a Shared, o tipo Journey original transita
para Deprecated — não para Removed.

**Justificativa:** Timelines históricas contêm eventos com o tipo Journey original. Removê-lo
imediatamente tornaria esses eventos órfãos de definição. O tipo Journey permanece como
Deprecated para que:
1. Consumers processem histórico corretamente
2. A referência ao tipo Shared substituto seja rastreável
3. INV-LC-03 seja satisfeito

---

### DEC-LC-03 — Nomes de tipos Deprecated e Removed são reservados

**Decisão:** após deprecação ou remoção, o nome do tipo não pode ser reutilizado por
nenhum novo tipo.

**Justificativa:** ANT-LC-03 descreve o problema: se `Phase.Started` for depreciado e
um novo tipo com o mesmo nome (semântica diferente) for criado, Consumers processando
Timelines históricas não conseguem distinguir qual versão do tipo está sendo referenciada.

A reserva de nomes é o único mecanismo que garante inequivocidade histórica sem exigir
versionamento explícito dos tipos.

---

### DEC-LC-04 — Promoção não renomeia o tipo (INV-LC-06)

**Decisão:** um Shared Type deve ter o mesmo nome do tipo Journey que o originou, salvo
ajuste de Namespace.

**Justificativa:** a promoção é um ato de reconhecimento cross-Journey da semântica do
tipo — não uma refatoração. Se o nome precisar mudar para ser adequado como Shared, isso
indica que a semântica também está sendo ajustada — o que exige um novo tipo, não uma
promoção.

Renomear na promoção também quebraria as Skills que emitiam o tipo Journey original com
o nome original.

---

### DEC-LC-05 — Período de depreciação é orientado a ciclos, não a calendário

**Decisão:** o critério para transitar de Deprecated para Removed é baseado em ciclos de
Journey (pelo menos um ciclo completo sem novas emissões), não em dias ou semanas.

**Justificativa:** o ciclo de uma Journey é a unidade natural de progressão dos Work Items.
Um tipo pode estar "sem uso" por 30 dias em um período de baixo volume, mas ainda ser
relevante. O ciclo de Journey garante que o critério é atingido quando o tipo foi
genuinamente substituído no fluxo operacional — não apenas em uma janela de tempo inativa.

---

### DEC-LC-06 — CRT-05 proíbe criar Shared Types preventivos

**Decisão:** Shared Types nascem exclusivamente da promoção de Journey Types com uso
comprovado — nunca de previsão de uso futuro.

**Justificativa:** ANT-LC-02 descreve o problema: um Shared Type criado preventivamente
pode ter semântica insuficientemente madura. Quando uma Journey finalmente precisar do
tipo, pode descobrir que ele não serve — mas está Active no catálogo compartilhado e não
pode ser renomeado (DEC-LC-04). A criação preventiva de Shared Types cria dívida de
taxonomia difícil de resolver.

---

## 4. Relação com a Taxonomia

O lifecycle.md é um complemento direto ao taxonomy.md. A Taxonomia definiu o que um
Event Type é e como é classificado; o Lifecycle define como um Event Type evolui.

| Conceito da Taxonomia | Complemento no Lifecycle |
|---|---|
| Event Type tem `status` | Os estados canônicos de `status` são definidos no Lifecycle |
| INV-TAX-01 (tipos imutáveis após aprovação) | O Lifecycle confirma: mudança semântica → deprecar e criar novo |
| Journey Event Types vs. Shared Event Types | O processo de promoção (seção 4 do Lifecycle) é o mecanismo de transição |
| Anti-padrões de nomenclatura (ANT-01 a ANT-11) | Anti-padrões do Lifecycle (ANT-LC-01 a ANT-LC-09) cobrem a dimensão temporal |
| REG-09 (proibição de import informal) | ANT-LC-09 refere explicitamente REG-09 como fundamento |

---

## 5. Relação com a Ontologia

O lifecycle.md não introduz novos conceitos à Ontologia. Ele opera dentro dos conceitos
já formalizados, especificando como um deles (Event Type) evolui ao longo do tempo.

| Conceito da Ontologia | Como o Lifecycle interage |
|---|---|
| **Operational Event** (imutável por INV-01 e INV-02) | A imutabilidade dos eventos é a razão central pela qual tipos depreciados devem persistir como referência histórica |
| **Event Type** | O sujeito central do Lifecycle |
| **Operational Timeline** (append-only) | A Timeline justifica INV-LC-01 (tipos históricos nunca desaparecem das Timelines) |
| **Derived State** | Não é diretamente afetado pelo ciclo de vida dos tipos — mas seria corrompido se tipos ativos mudassem semântica retroativamente |
| **Event Consumer** | Consumers devem tratar tipos Deprecated e Removed como válidos para leitura (seção 6.2 do lifecycle.md) |
| **Event Producer** | Producers (Skills) só podem emitir tipos Active — não Draft, Proposed, Deprecated ou Removed |

---

## 6. Análise dos Invariantes

### 6.1 Hierarquia de invariantes

Os 8 invariantes do Lifecycle (INV-LC-01 a INV-LC-08) podem ser organizados por nível:

**Nível 1 — Imutabilidade histórica** (derivados de INV-01 e INV-02 da Ontologia):
- INV-LC-01: Event Types históricos nunca desaparecem das Timelines
- INV-LC-04: Depreciação nunca altera eventos existentes

**Nível 2 — Integridade do catálogo compartilhado**:
- INV-LC-02: Shared Types nunca voltam a ser exclusivos de Journey
- INV-LC-03: Promoção preserva compatibilidade histórica
- INV-LC-06: Promoção não renomeia o tipo

**Nível 3 — Controle de emissão**:
- INV-LC-07: Draft e Proposed não autorizam emissão
- INV-LC-05: Remoção só ocorre após critérios satisfeitos

**Nível 4 — Auditabilidade**:
- INV-LC-08: O registro de histórico do ciclo de vida é preservado

### 6.2 Invariantes que não foram criados e por quê

| Candidato descartado | Motivo |
|---|---|
| "Um tipo só pode ter uma promoção" | Falso — um tipo pode ser promovido, removido como Shared, e um descendente ser promovido novamente |
| "Journey Types não podem ter Namespace externo" | Já coberto por REG-01 a REG-10 na Taxonomia |
| "Draft tem TTL máximo" | TTL é implementação — o anti-padrão ANT-LC-07 cobre o risco sem tornar o Lifecycle dependente de calendário |

---

## 7. Análise dos Anti-padrões

### 7.1 Os 9 anti-padrões e sua categoria de risco

| ANT | Nome | Categoria de risco |
|---|---|---|
| ANT-LC-01 | Promoção prematura | Catálogo compartilhado instável |
| ANT-LC-02 | Shared Types preventivos | Catálogo compartilhado poluído |
| ANT-LC-03 | Reutilizar nome com semântica diferente | Integridade histórica comprometida |
| ANT-LC-04 | Alterar significado de tipo Active | Timeline historicamente inconsistente |
| ANT-LC-05 | Remover tipo presente em Timelines ativas | Consumers quebram ao ler histórico |
| ANT-LC-06 | Deprecar sem substituto disponível | Lacunas na Timeline (P-07 violado) |
| ANT-LC-07 | Draft eterno (zombie Draft) | Catálogo poluído; duplicatas não detectadas |
| ANT-LC-08 | Restauração sem revisão de compatibilidade | Ambiguidade semântica na Timeline |
| ANT-LC-09 | Contornar promoção com import informal | Violação de REG-09; acoplamento frágil entre Journeys |

### 7.2 Anti-padrão de maior impacto: ANT-LC-03

ANT-LC-03 (reutilizar nome com semântica diferente) é o de maior impacto sistêmico.
Enquanto os demais anti-padrões criam problemas na Journey ou no catálogo, ANT-LC-03
cria ambiguidade permanente na Timeline: não há forma programática de distinguir dois
eventos com o mesmo tipo mas semânticas diferentes, a não ser pelo timestamp relativo
à data de depreciação do tipo original.

DEC-LC-03 (reserva de nomes) é a mitigação direta.

### 7.3 Anti-padrão mais frequente esperado: ANT-LC-01

Com base nos padrões observados em frameworks semelhantes, ANT-LC-01 (promoção prematura)
tende a ser o mais frequente. A pressão para centralizar tipos é natural — evita a percepção
de duplicação entre Journeys. CRT-03 (estabilidade mínima de um ciclo) é a barreira mais
efetiva contra esse anti-padrão.

---

## 8. Critérios de Promoção — Análise de Suficiência

Os 5 critérios de promoção (CRT-01 a CRT-05) foram definidos para que todos precisem
ser satisfeitos simultaneamente. A análise de por que cada critério individual é necessário
mas não suficiente:

| CRT | Por que não basta sozinho |
|---|---|
| CRT-01 (reutilização ativa) | Uma Journey pode querer "reutilizar" um tipo com semântica ligeiramente diferente — CRT-02 é necessário para filtrar |
| CRT-02 (equivalência semântica) | Um tipo semanticamente equivalente mas instável não deve ser promovido — CRT-03 é necessário |
| CRT-03 (estabilidade) | Um tipo estável mas excessivamente específico não serve como Shared — CRT-04 é necessário |
| CRT-04 (generalidade) | Um tipo genérico pode duplicar um Shared Type existente — CRT-05 é necessário |
| CRT-05 (sem duplicata) | A ausência de duplicata não implica que as outras condições estão satisfeitas |

O conjunto é necessário e suficiente: satisfazer todos os 5 significa que a promoção é
adequada e o Shared Type resultante é estável, utilizável e não redundante.

---

## 9. O Processo de Promoção — Análise do Fluxo

### 9.1 Garantias do processo de 6 fases

| Garantia | Onde é estabelecida |
|---|---|
| O tipo Journey original permanece Active durante a revisão | Fase 3 — sem interrupção de emissão durante o processo |
| Timelines históricas com o tipo Journey original continuam válidas | Fase 6 — compatibilidade retroativa garantida |
| Journeys afetadas são consultadas antes da aprovação | Fase 4 — Framework verifica cross-Journey |
| A recusa inclui feedback estruturado | Fase 5B — a Journey pode ajustar e re-submeter |
| O tipo Journey original é depreciado, não deletado | Fase 5A — DEC-LC-02 aplicado |

### 9.2 O que acontece com Journeys que não participam da consulta

A Fase 4 inclui a consulta às Journeys que usariam o tipo compartilhado. Journeys que não
participam da consulta não são forçadas a adotar o Shared Type — cada Journey escolhe
migrar suas emissões para o Shared Type no seu próprio ritmo. O único impacto imediato
é na Journey que deu origem à proposta: seu tipo Journey original é depreciado.

---

## 10. Compatibilidade com a Ontologia — Verificação Formal

| Conceito da Ontologia | Compatibilidade com lifecycle.md |
|---|---|
| **INV-01** (eventos imutáveis) | INV-LC-04 deriva diretamente: depreciação nunca altera eventos |
| **INV-02** (Timeline append-only) | INV-LC-01 deriva: tipos históricos persistem como referência read-only |
| **INV-03** (Timeline única por Work Item) | Não afetado pelo ciclo de vida dos tipos |
| **INV-07** (Event Types do catálogo) | O lifecycle.md especifica como um tipo entra e sai do catálogo |
| **INV-09** (Timeline prevalece) | Reforçado: remoção de tipo não pode invalidar Timeline |
| **INV-10** (correções são eventos) | Não afetado — a Correction Category continua válida para qualquer tipo Active |

Nenhuma incompatibilidade encontrada.

---

## 11. Documentos Futuros Dependentes

O lifecycle.md é referenciado como pré-requisito pelos seguintes documentos futuros:

| Documento | O que depende do lifecycle.md |
|---|---|
| `events/shared-types.md` | Os campos `status`, `deprecated_in`, `removed_in`, `replacement_type` de cada tipo no catálogo seguem os estados e propriedades definidos aqui |
| `events/schema.md` | A estrutura do Event Type inclui campos de ciclo de vida; regra de validação: tipo deve ser Active para emissão |
| `journeys/*/events/catalog.md` | Cada catálogo de Journey deve declarar o `status` de cada tipo e seguir o processo de promoção e depreciação definido aqui |
| `events/categories.md` | Categories seguem seu próprio ciclo de vida (mais restrito que os Types) — lifecycle.md é a referência base |

---

## 12. Confirmação de Invariantes Arquiteturais

| Decisão arquitetural anterior | Status |
|---|---|
| Operational Event como unidade fundamental | Preservado |
| Operational Timeline como fonte primária de verdade | Preservado |
| Derived State como projeção da Timeline | Preservado |
| Event Category como catálogo fixo do Framework | Preservado |
| Event Type como conceito formal da Ontologia | Preservado e expandido (ciclo de vida) |
| Shared Types como responsabilidade do Framework | Preservado e detalhado |
| Journey Types como responsabilidade das Journeys | Preservado e detalhado |
| COR como consumidora do OEM | Preservado |
| Diligence como verificadora de consistência | Preservado |
| Nenhuma Journey foi alterada | Confirmado |
| Nenhum Skill foi alterado | Confirmado |
| Nenhum manifest foi alterado | Confirmado |
| README do OEM não alterado | Confirmado |
| Ontologia do OEM não alterada | Confirmado |
| Taxonomia do OEM não alterada | Confirmado |
| Nenhum conceito arquitetural novo introduzido | Confirmado |
| Nenhum commit criado | Confirmado |

---

## 13. Arquivos Criados e Alterados

### Criados

| Arquivo | Linhas | Conteúdo |
|---|---|---|
| `prodops/framework/events/lifecycle.md` | ~530 | Governança completa do ciclo de vida dos Event Types |
| `prodops/documentation-review-operational-event-lifecycle.md` | Este arquivo | Relatório de formalização |

### Alterados

Nenhum arquivo existente foi alterado.

---

## 14. Próximos Passos Sugeridos

O Lifecycle completa a tríade conceitual do OEM:

```
Fundação (README.md)     → O que é um Operational Event e por quê
Ontologia (ontology.md)  → Quais conceitos existem e como se relacionam
Taxonomia (taxonomy.md)  → Como os Event Types são classificados e nomeados
Lifecycle (lifecycle.md) → Como os Event Types nascem, evoluem e são removidos
```

Os próximos documentos naturais são:

| Documento | Prioridade | Raciocínio |
|---|---|---|
| `events/shared-types.md` | Alta | O catálogo de tipos compartilhados precisa dos estados de lifecycle para cada entrada |
| `events/schema.md` | Alta | Desbloqueia todos os catálogos de Journey; inclui campos de lifecycle em todo tipo |
| `journeys/delivery/events/catalog.md` | Alta | 83 Event Types propostos no documento de análise; lifecycle define o status de cada um |
| `events/categories.md` | Média | Detalha as 8 Categories com exemplos; pode incluir ciclo de vida específico de Categories |
