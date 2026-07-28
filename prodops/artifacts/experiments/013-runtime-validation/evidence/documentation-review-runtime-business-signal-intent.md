# Relatório — Business Signal e Product Intent: ProdOps Runtime Validation
# ProdOps Framework — Iniciativa de Validação do Runtime

> **Data:** 2026-07-25
> **Tipo:** Registro de artefatos iniciais — sem compromisso de implementação
> **Status:** Concluído
> **Artefatos criados:** BS-RUNTIME-001 · PI-RUNTIME-001

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Business Signal criado | BS-RUNTIME-001 |
| Product Intent criada | PI-RUNTIME-001 |
| Documentos existentes alterados | 0 |
| Decisões arquiteturais alteradas | 0 |
| OBC criado | Não — fora do escopo desta etapa |
| Release Plan criado | Não — fora do escopo desta etapa |
| Código criado | Não — fora do escopo desta etapa |

---

## 2. Justificativa da criação do Business Signal (BS-RUNTIME-001)

### 2.1 O sinal existe

O ProdOps Framework possui um modelo conceitual completo e estabilizado — OEM, Journeys, Shared Types, COR. O que não existe é evidência de realizabilidade: nenhuma Iteration real foi executada com Runtime, GitHub COR e Datadog sincronizados simultaneamente.

Esta ausência é um sinal de negócio/tecnologia legítimo: **há risco não mensurado no modelo que só pode ser quantificado por execução real.**

### 2.2 Origem dual é correta

O Business Signal tem origem em dois Origin Streams:

- **Team:** o time de payments-api opera o Framework mas nunca o validou end-to-end. A fricção operacional real é desconhecida.
- **Technology:** os componentes técnicos (OEM Consumer, GitHub COR sync, Datadog pipeline) foram especificados mas nunca integrados em execução real.

Ambos os streams identificam o mesmo gap por perspectivas diferentes — o que reforça a relevância do sinal.

### 2.3 Alcance do Business Signal

O sinal não propõe solução nem escopo de implementação. Ele captura a lacuna observada e as perguntas que precisam ser respondidas por investigação estruturada. Está correto no nível de abstração para um Business Signal (versus uma Business Intent, que já pressupõe decisão estratégica tomada).

### 2.4 Localização canônica

O Business Signal foi criado em `prodops/artifacts/business-signals/BS-RUNTIME-001.md`. Esta é uma nova pasta no repositório — justificada pelo fato de que o Framework distingue explicitamente Business Signals (captura de oportunidades sem estrutura) de Business Intents (decisões estratégicas com identidade formal). A pasta existente `business-intents/` é destinada a intents; a pasta `business-signals/` acomoda sinais que merecem rastreabilidade própria, como neste caso.

---

## 3. Justificativa da Product Intent (PI-RUNTIME-001)

### 3.1 A decisão estratégica está clara

O Business Signal BS-RUNTIME-001 tem escopo suficientemente definido para gerar uma Product Intent: sabemos qual produto (payments-api), qual Framework (ProdOps), e quais componentes devem ser validados (Runtime, Delivery, Diligence, GitHub COR, Datadog, Timeline, Derived State).

A decisão estratégica é: **investir em descoberta para validar o Runtime antes de qualquer escalonamento**.

### 3.2 Modo Upstream é a decisão correta

A hipótese principal — "o Runtime é realizável sem ajustes estruturais" — não pode ser validada por análise de documentos. Exige execução real. Há perguntas abertas sobre o Consumer de Derived State, a granularidade de sincronização do COR, e o pipeline para Datadog. O modo Upstream (Discovery) é a escolha correta neste momento.

A Product Intent seria Downstream se o Runtime já tivesse sido validado em outro produto e o trabalho fosse simplesmente replicá-lo no payments-api. Esse não é o caso.

### 3.3 Localização canônica

A Product Intent foi criada em `prodops/artifacts/business-intents/PI-RUNTIME-001.md`. O prefixo `PI-` (Product Intent) em vez de `BI-` (Business Intent) reflete o escopo estritamente local ao produto — sem necessidade de Global OBC ou coordenação de Portfolio. A pasta canônica `business-intents/` é a localização correta por ser onde Business/Product Intents são armazenadas no repositório.

---

## 4. Aderência ao Framework

| Aspecto | Status | Detalhe |
|---|---|---|
| Business Signal representa oportunidade não estruturada | ✓ | BS-RUNTIME-001 captura gap de validação sem prescrever solução |
| Business Signal não é uma Business Intent | ✓ | O sinal gera a intent — não se transforma nela |
| Product Intent não é OBC | ✓ | Nenhum OBC foi criado — não há compromisso de implementação |
| Origin Stream correto | ✓ | Team + Technology — ambos identificam o mesmo gap |
| Modo de execução declarado | ✓ | Upstream — incerteza real documentada |
| Próximo passo declarado | ✓ | Experimento em experiments/ como próximo artefato |
| Produto explicitamente declarado | ✓ | payments-api — com justificativa de pertencimento |
| Independência do Portfolio justificada | ✓ | Escopo local, sem Global OBC, sem dependência de outros times |
| Componentes de validação declarados | ✓ | Runtime, Delivery, Diligence, GitHub COR, Datadog, Timeline, Derived State |

---

## 5. Relação entre Business Signal e Product Intent

```
BS-RUNTIME-001 (Business Signal)
│
│  "O Runtime nunca foi validado end-to-end em condição real"
│  Origin: Team + Technology
│  Gap: Timeline real, GitHub COR sincronizado, Datadog com métricas derivadas
│
└─ gera ──→ PI-RUNTIME-001 (Product Intent)
               │
               │  "Validar o ProdOps Operational Runtime no payments-api"
               │  Escopo explícito: 7 componentes definidos
               │  Critérios: 5 critérios de avanço para Discovery
               │
               └─ próximo passo ──→ EXP-013 (a criar)
                                    Experimento de validação do Runtime
```

**Distinção de identidade:** BS-RUNTIME-001 é o sinal — permanece mesmo após gerar a intent. PI-RUNTIME-001 é a decisão estratégica — terá OBC quando avançar para Downstream. As duas entidades coexistem com identidades distintas, conforme o Framework exige.

**Rastreabilidade:** a Product Intent referencia o Business Signal de origem. O Business Signal referencia a intent gerada. A cadeia de rastreabilidade está completa e bidirecional.

---

## 6. Confirmação explícita — nenhuma decisão arquitetural existente foi alterada

| Documento | Status |
|---|---|
| `prodops/framework/events/` — OEM completo | Não alterado |
| `prodops/framework/events/shared-types.md` | Não alterado |
| `prodops/framework/journeys/delivery/events/catalog.md` (v2.0.0) | Não alterado |
| `prodops/framework/journeys/diligence/events/catalog.md` (v2.0.0) | Não alterado |
| `prodops/framework/journeys/assessment/events/catalog.md` (v2.0.0) | Não alterado |
| `prodops/artifacts/business-intents/README.md` | Não alterado |
| `prodops/artifacts/product/backlogs/tracking-list.md` | Não alterado |
| Todos os demais documentos prodops/ | Não alterados |

**Nenhum conceito do OEM foi alterado.** Nenhum Event Type foi criado. Nenhum Shared Type foi promovido ou modificado. Nenhum catálogo de Journey foi alterado. Nenhum código foi criado. Nenhum commit foi criado.

---

## 7. Arquivos criados

| Arquivo | Tipo | Localização |
|---|---|---|
| `BS-RUNTIME-001.md` | Business Signal | `prodops/artifacts/business-signals/BS-RUNTIME-001.md` |
| `PI-RUNTIME-001.md` | Product Intent | `prodops/artifacts/business-intents/PI-RUNTIME-001.md` |
| `documentation-review-runtime-business-signal-intent.md` | Relatório | `prodops/documentation-review-runtime-business-signal-intent.md` |
