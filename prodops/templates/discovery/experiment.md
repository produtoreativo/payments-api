# Upstream Experiment

Localização canônica:

```text
prodops/journeys/discovery/experiments/NNN-short-slug/experiment.md
```

Cada experimento deve ter também:

```text
prodops/journeys/discovery/experiments/NNN-short-slug/upstream-trail.md
prodops/journeys/discovery/experiments/NNN-short-slug/evidence/
prodops/journeys/discovery/experiments/NNN-short-slug/features/   ← BDD Features (criadas durante o experimento)
prodops/journeys/discovery/experiments/NNN-short-slug/obcs/       ← OBC drafts (criados durante o experimento)
```

`features/` e `obcs/` são criados conforme necessário. Artefatos ficam aqui até `move-to-downstream`, quando são movidos para `prodops/artifacts/business/bdd/` e `prodops/artifacts/business/obcs/`.

Não criar arquivos de experimento diretamente em `prodops/journeys/discovery/experiments/` — sempre dentro de um subdiretório com slug.

## Status

- [ ] Planned
- [ ] In Progress
- [ ] Completed
- [ ] Cancelled

---

# Business Goal

Descreva o resultado de negócio esperado com este experimento.

Por que este experimento está sendo executado?

---

# Repository Scope Gate

Confirme se este experimento pode ser desenvolvido ou validado neste repositório.

## Escopo de responsabilidade deste repositório

Marque todos os itens aplicáveis:

- [ ] Comportamento da Payments API
- [ ] Lógica de domínio de Payments
- [ ] Integração com provedor
- [ ] Processamento de webhook
- [ ] Persistência
- [ ] Contrato de API/evento de propriedade do Payments
- [ ] Testes locais ou evidência executável

## Dependências externas

Liste dependências de responsabilidade de outro repositório, time, sistema, vendor ou plataforma.

Exemplos:

- Checkout Feature Flag
- Checkout rollout targeting
- Notification Service delivery
- Order Management fulfillment
- Integração corporativa de ITSM

## Decisão de escopo

Escolha uma opção:

- [ ] Prosseguir como experimento Upstream executável neste repositório
- [ ] Registrar apenas como dependência externa ou risco de release
- [ ] Redirecionar para repositório ou time responsável

Se este repositório não pode desenvolver ou validar a capability, pare aqui. Não crie BDD Features, rascunhos de OBC, protótipos ou artefatos de implementação para esta solicitação neste repositório.

---

# Question to Answer

Liste as perguntas que este experimento deve responder.

Exemplos:

- Esta capability pode ser implementada?
- A API do provedor é suficiente?
- Qual arquitetura deve ser adotada?
- O fluxo de negócio pode ser reproduzido localmente?

---

# Hypothesis

Descreva o resultado esperado antes da implementação.

Declare o que se acredita ser verdade e será validado durante o experimento.

---

# Scope

Descreva o que ESTÁ incluído.

Exemplos:

- APIs
- Fluxos de negócio
- Componentes
- Serviços
- Scripts de validação
- Documentação

---

# Out of Scope

Descreva explicitamente o que NÃO será investigado.

Esta seção previne expansão de escopo.

---

# Implementation

Descreva as atividades necessárias para executar o experimento.

Exemplos:

- estudar documentação
- implementar código
- atualizar contratos
- criar cenários BDD
- criar protótipo
- executar integrações

---

# Code Produced

Liste os artefatos executáveis criados.

Exemplos:

- endpoints
- services
- DTOs
- repositories
- scripts
- protótipos

Se nenhum código foi produzido, explique por quê.

---

# Functional Validation

Descreva como o fluxo de negócio foi validado.

Exemplos:

- execução local
- testes de integração
- cenários BDD
- sandbox do provedor
- scripts manuais

---

# Technical Findings

Documente descobertas técnicas.

Exemplos:

- Limitações de API
- Comportamento do provedor
- Timeout
- Idempotência
- Autenticação
- Modelo de eventos
- Restrições de integração

---

# Business Findings

Documente descobertas de negócio.

Exemplos:

- Novas regras de negócio
- Regras ausentes
- Descobertas de UX
- Melhorias de processo
- Riscos
- Oportunidades

---

# Architecture Impact

Descreva decisões arquiteturais.

Inclua:

- Decisões confirmadas
- Decisões rejeitadas
- Premissas
- Questões em aberto

---

# Reliability Impact

Descreva impactos em:

- Reliability Plan
- Observabilidade
- SLOs
- Telemetria
- Resiliência
- Segurança
- Prontidão operacional

---

# Artifacts Updated

Liste todos os artefatos atualizados.

Exemplos:

- Product Deck (`prodops/artifacts/product/context/product-deck.md`)
- Service Deck (`prodops/artifacts/product/context/service-decks/`)
- Repository Tracking List (`prodops/artifacts/product/backlogs/tracking-list.md`)
- Icebox (`prodops/artifacts/product/backlogs/icebox-backlog.md`)
- Event Storming (`prodops/journeys/assessment/event-storming/`)
- Reliability Plan (`prodops/journeys/assessment/reliability-plans/`)
- OBC (`prodops/artifacts/business/obcs/`)
- BDD Features (`prodops/artifacts/business/bdd/`)

---

# Knowledge Gaps Closed

Classifique cada pergunta original.

| Pergunta | Status | Evidência |
|----------|--------|----------|
| | ✅ Respondida | |
| | ⚠ Parcialmente respondida | |
| | ❌ Ainda desconhecida | |

---

# New Backlog Items

Liste trabalhos descobertos durante o experimento.

Classifique cada item como:

- Repository Tracking List
- Icebox
- Candidato ao Iteration Backlog
- Descartado

---

# Recommendation

Escolha uma opção:

- [ ] Mover para Downstream
- [ ] Executar outro experimento Upstream
- [ ] Aguardar decisão de negócio
- [ ] Aguardar dependência externa
- [ ] Descartar capability

Justifique.

---

# Decision Package

Resuma as informações necessárias para o Continuous Assessment.

Inclua:

## Executive Summary

## Decisão Recomendada

## Riscos Atualizados

## Oportunidades Atualizadas

## Itens de Tracking Atualizados

## OBCs Atualizados

## Reliability Plan Atualizado

## Escopo Downstream Recomendado

---

# Sandbox Deploy Record

Preencha apenas se o experimento foi implantado em AWS real via `/upstream deploy-to-sandbox`.

| Field | Value |
|---|---|
| Deploy date | |
| Branch | |
| API URL | |
| Triggered by | |
| Teardown date | |

---

# Exit Criteria

Confirme que:

- [ ] Hipótese original respondida
- [ ] Perguntas classificadas
- [ ] Lacunas de conhecimento documentadas
- [ ] Impacto arquitetural documentado
- [ ] Impacto em confiabilidade documentado
- [ ] Artefatos atualizados
- [ ] Recomendação produzida
- [ ] Decision Package completo

---

# Next Step

Descreva a próxima ação.

Exemplos:

- Iniciar outro experimento Upstream.
- Mover para Downstream.
- Aguardar decisão de Produto.
- Aguardar revisão de Arquitetura.
- Aguardar dependência externa.
