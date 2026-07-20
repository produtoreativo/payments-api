# Execution Model

Upstream e Downstream são **modos de execução** do Framework ProdOps — não são jornadas, não são fases e não substituem as jornadas.

## Terminologia canônica

| Conceito | Definição |
|---|---|
| **Upstream** | Modo de exploração |
| **Downstream** | Modo de compromisso |
| **Discovery** | Jornada presente nos dois modos |
| **Delivery** | Jornada presente nos dois modos; somente Downstream produz entrega promovível |
| **Operation** | Jornada presente nos dois modos; Upstream limita-se a sandbox/experimento |

Os modos não substituem as jornadas. Eles definem como as jornadas serão executadas.

## Fluxo de decisão da Business Intent

Toda Business Intent segue um dos dois modos. No BIB, a decisão da exploração global é do Portfolio; no Product Backlog, a decisão local é do Product Owner. Nenhuma transição acontece automaticamente.

```
Business Intent
  ↓
Escolha do modo (Product Owner)
  ↓
Upstream                    Downstream
(exploração)                (compromisso)
     │                           │
  Discovery                  Product Backlog
  Experimentos                   → Icebox (VIEW — Discovery)
  Aprendizados                   → Iteration Backlog (VIEW)
     │                           → Iteration Plan
  (Eventualmente)                → Delivery
  Downstream                     → Operation
```

Não existe transição automática entre os modos. A mudança deve ser uma decisão explícita.

Cada modo utiliza as jornadas de forma diferente. A diferença está no compromisso e no rigor aplicado, não na presença ou ausência de uma jornada.

## Upstream

Modo permissivo e experimental, sem compromisso de entrega.

**Características:**
- Sem compromisso de entrega
- Liberdade para selecionar capabilities e práticas conforme necessidade
- Código é descartável até ser promovido para Downstream
- Evolução rápida de artefatos
- Foco em aprendizado, não em entrega

Upstream transforma hipóteses em conhecimento validado.

→ [Detalhes do modo Upstream](upstream.md)

## Downstream

Modo com compromisso de entrega e aplicação completa dos quality gates vigentes.

**Características:**
- Compromisso formal com critérios de aceite (OBC + BDD Feature)
- Governança e rastreabilidade completas
- Artefatos obrigatórios antes do início
- Evidências registradas em cada etapa
- Sequência completa obrigatória

Downstream entrega software com conhecimento validado pela Discovery, realizada diretamente em Downstream ou promovida do Upstream.

→ [Detalhes do modo Downstream](downstream.md)

## Como escolher o modo

| Situação | Modo |
|---|---|
| Hipótese a validar, incerteza alta | Upstream |
| Item com compromisso, sendo guiado até completar readiness | Downstream |
| Explorar uma capability nova | Upstream |
| Executar item com todos os gates de readiness satisfeitos | Downstream |
| Prototipar integração com provedor | Upstream |
| Entregar feature com compromisso | Downstream |
