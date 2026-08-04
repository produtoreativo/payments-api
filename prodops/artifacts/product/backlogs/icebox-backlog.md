# Icebox - Payments

> **Propósito:** Itens comprometidos pelo Product Owner que ainda estão sendo preparados para Delivery. O Discovery necessário ocorre aqui — funcional, técnico ou operacional. O objetivo é produzir um Local OBC no estado Committed. Enquanto isso não acontece, o item permanece no Icebox.
>
> Itens que concluem o estado Committed avançam para o Iteration Backlog (pronto para desenvolver).
>
> → [Hierarquia de backlogs](../../../framework/backlogs.md)

## 1. Governança do Icebox

| Campo | Conteúdo |
| --- | --- |
| Produto | Payments |
| Contexto | Gateway de pagamentos para ecommerce Magazine Siara, com foco inicial em compra por Pix e integração Asaas. |
| Dono de produto | `[Product Manager Payments]` |
| Dono técnico | `[Tech Lead Payments]` |
| Canal | `[Slack/Teams: #payments-prodops]` |
| Fonte principal | Features em `prodops/artifacts/bdd/` |
| Última atualização | `2026-08-01` |

## 2. Como usar este backlog

1. Registrar oportunidades como problemas observáveis, não apenas soluções.
2. Classificar cada item por resultado esperado, risco, dependência e evidência.
3. Manter itens no icebox enquanto faltarem contexto, prioridade ou capacidade.
4. Promover para discovery quando houver pergunta crítica a responder.
5. Promover para delivery somente quando houver critérios de aceite, telemetria mínima, dependências conhecidas e owner definido.

## 3. Estados do item

| Estado | Significado | Critério de movimentação |
| --- | --- | --- |
| Icebox | Item comprometido pelo Product Owner (vindo do Product Backlog), sendo refinado pelo Discovery para atingir o estado Committed. | OBC Draft em refinamento; falta completar Discovery funcional, técnico ou operacional. |
| Discovery | Item em investigação de produto, negócio, técnica, operação ou dados. | Existe pergunta clara, dono e prazo de aprendizado. |
| Ready for Delivery | Item pronto para planejamento de sprint/kanban. | Critérios de aceite, dependências, métricas e riscos estão claros. |
| Delivery | Item em implementação. | Time assumiu compromisso e iniciou execução. |
| Done | Entregue e observado em produção. | Critérios de aceite, logs, métricas, eventos e documentação operacional validados. |
| Dropped | Não será executado agora. | Decisão registrada com motivo e condição de revisita. |

## 4. Campos padrão por item

| Campo | Descrição |
| --- | --- |
| ID | Identificador estável do item no backlog. |
| Título | Nome curto, orientado ao resultado. |
| Tipo | Feature, melhoria, risco, experimento, dívida técnica, observabilidade ou operação. |
| Problema/oportunidade | Dor, risco ou oportunidade de negócio que justifica o item. |
| Usuário/cliente | Pessoa, sistema ou time impactado. |
| Outcome esperado | Mudança mensurável no comportamento, operação ou resultado. |
| Evidência atual | Dado, incidente, requisito, feature file, feedback ou hipótese. |
| Escopo MVP | Menor entrega útil e verificável. |
| Fora de escopo | Limites explícitos para evitar expansão silenciosa. |
| Dependências | Sistemas, times, contratos, dados ou decisões necessárias. |
| Riscos | Principais riscos de negócio, dados, tecnologia, segurança ou operação. |
| Telemetria mínima | Eventos, logs, métricas, traces e auditoria necessários. |
| Critérios de aceite | Condições objetivas para considerar o item pronto. |
| Score | Priorização por RICE/ICE/WSJF adaptada ao produto. |
| Status | Estado atual do item. |

## 5. Modelo de priorização

Use RICE como critério padrão e complemente com risco operacional quando a confiabilidade da jornada for parte central da decisão.

| Campo | Escala | Pergunta |
| --- | --- | --- |
| Reach | 1-5 | Quantos clientes, pedidos, times ou fluxos são impactados? |
| Impact | 1-5 | Quanto o item protege conversão, GMV, confiança, eficiência ou continuidade? |
| Confidence | 1-5 | Quanta evidência existe para sustentar a prioridade? |
| Effort | 1-5 | Qual o esforço relativo de engenharia, produto, dados e operação? |
| Operational Risk | 1-5 | Qual o risco de incidente, retrabalho, perda financeira ou divergência operacional se não fizer? |

Fórmula sugerida:

```text
Score = ((Reach * Impact * Confidence) + Operational Risk) / Effort
```

## 6. Backlog resumido

| ID | Título | Tipo | Outcome esperado | Status | Score inicial | Fonte |
| --- | --- | --- | --- | --- | --- | --- |
| POPS-ICE-001 | Mecanismo de distribuição do ProdOps Framework | Plataforma | Qualquer repo produto instala e mantém o Framework atualizado a partir do `prodops-framework`, sem sobrescrever artefatos locais. | Icebox | — | [#129](https://github.com/produtoreativo/payments-api/issues/129) |
| RT-ICE-001 | Event Pipeline Completeness — Bootstrap intermediários e oem-state | Observabilidade/Runtime | Todos os eventos do ciclo de Bootstrap chegam ao Datadog e o oem-state é transitado automaticamente no GitHub Project. | Icebox | — | [#142](https://github.com/produtoreativo/payments-api/issues/142) |
| RT-ICE-002 | Continuous Operational Trail — trail por phase durante execução | Runtime/Processo | Trail de cada Feature é uma narrativa contínua — auditável em tempo real, não apenas ao final. | Icebox | — | [#143](https://github.com/produtoreativo/payments-api/issues/143) |
| RT-ICE-003 | Dashboard Evolution — cycle time, iteration filter e labels | Observabilidade/Dashboard | Dashboard Datadog exibe cycle time por phase, filtro por Iteration ID e labels canônicos. | Icebox | — | [#144](https://github.com/produtoreativo/payments-api/issues/144) |
| RT-ICE-004 | Iteration Lifecycle Automation — auto-close e assignees | Runtime/Processo | Encerramento de Iteration é completamente automático: tracking issue fechada, assignees preenchidos, sem ação manual. | Icebox | — | [#145](https://github.com/produtoreativo/payments-api/issues/145) |
| PAY-ICE-001 | Criar invoice via gateway com contrato único | Feature | Ecommerce emite cobranças sem acoplamento direto ao provedor Asaas. | Done | 16.4 | [create-invoice.feature](../../bdd/create-invoice.feature) |
| PAY-ICE-002 | Confirmar pagamento por webhook confiável | Feature | Pedido e ecommerce recebem confirmação uma única vez, com eventos auditáveis. | Done | 20.8 | [payment-confirmation.feature](../../bdd/payment-confirmation.feature) |
| PAY-ICE-003 | Cancelar invoice pendente com idempotência | Feature | Cobranças abertas podem ser canceladas sem pagamento indevido ou evento duplicado. | Ready for Delivery | 13.7 | [cancel-invoice.feature](../../bdd/cancel-invoice.feature) |

## 7. Itens detalhados

### POPS-ICE-001 - Mecanismo de distribuição do ProdOps Framework

| Campo | Conteúdo |
| --- | --- |
| Tipo | Plataforma |
| Problema/oportunidade | O ProdOps Framework evolui em `payments-api` mas qualquer equipe que queira adotá-lo precisa copiar arquivos manualmente — sem saber o que copiar, sem garantia de integridade e sem como receber melhorias futuras. |
| Usuário/cliente | Equipes de produto que adotam o ProdOps Framework (Context Engineers, Tech Leads, agentes). |
| Outcome esperado | Qualquer repositório produto instala o Framework com um script, recebe atualizações via PR automático e nunca perde artefatos locais em um sync. |
| Evidência atual | `framework-lock.yaml` declara `synchronization_mechanism: null`. Script de sync anterior desabilitado. `export-manifest.yaml` completo e validado. Business Signal #129. |
| Escopo MVP | 4 camadas: Export (`export-framework.sh` + v0.1.0), Install (`install-prodops.sh`), Sync (`sync-from-framework.sh`), CI (`notify-consumers.yml` + `sync-prodops.yml`). |
| Fora de escopo | Resolução automática de conflitos em conteúdo canônico divergente; publicação NPM; suporte a múltiplas versões simultâneas. |
| Dependências | Repositório `prodops-framework` acessível; `export-manifest.yaml` válido; `doctor.sh` passando com exit 0. |
| Riscos | Sobrescrita de artefatos do consumidor; links quebrados após cópia; versão desatualizada sem detecção; conteúdo produto-específico exportado como canônico. Ver Premortem em OBC. |
| Telemetria mínima | `framework-lock.yaml` atualizado a cada sync com versão e drift status; PR de sync como evidência auditável de cada atualização. |
| Critérios de aceite | Export passa `validate-export-manifest.sh`; Install gera lock com `status: consumer`; Sync abre PR sem tocar em `.prodopsignore` paths; `doctor.sh` passa antes e depois de cada operação. |
| Score | — |
| Status | Icebox — OBC Draft em `prodops/artifacts/obcs/prodops-framework-distribution.md`. Próximo: refinar até Committed (BDD + risks formalizados + owner approval para Iteration Backlog). |

---

### PAY-ICE-001 - Criar invoice via gateway com contrato único

| Campo | Conteúdo |
| --- | --- |
| Tipo | Feature |
| Problema/oportunidade | O ecommerce precisa criar cobranças sem depender diretamente da API de um provedor específico, preservando a capacidade futura de troca ou fallback de gateway. |
| Usuário/cliente | Ecommerce Magazine Siara, Checkout, Payments, Operação. |
| Outcome esperado | Invoice criada com status rastreável, provedor registrado, identificador externo persistido e resposta padronizada ao ecommerce. |
| Evidência atual | Feature `Criar invoice no gateway de pagamentos`; necessidade de contrato único e idempotência por pedido. |
| Escopo MVP | Criar invoice no Asaas, criar/reutilizar cliente Asaas, validar provedor habilitado, garantir idempotência e tratar falhas transientes/validação. |
| Fora de escopo | Múltiplo provedor ativo em fallback automático, split de pagamento, estorno, conciliação financeira completa. |
| Dependências | Credenciais Asaas, cadastro de provedores por tenant, modelo de customer binding, storage de idempotência, contrato de resposta ao ecommerce. |
| Riscos | Duplicidade de cobrança, cliente Asaas duplicado, invoice aberta sem `providerPaymentId`, exposição de payload sensível em erro. |
| Telemetria mínima | Evento de invoice criada, tentativa de chamada ao provedor, provider latency, provider error code, idempotency hit/miss, audit log de rejeição. |
| Critérios de aceite | Cenários do arquivo [create-invoice.feature](../../bdd/create-invoice.feature) passam; retry com mesma chave não chama o provedor; falha 5xx não retorna invoice `OPEN` sem `providerPaymentId`; erro de validação é auditável sem segredo. |
| Score | Reach 4, Impact 5, Confidence 4, Effort 5, Operational Risk 2 = 16.4 |
| Status | Done — Entregue em v0.4.0, PR #89. OBC: `prodops/artifacts/obcs/create-invoice.md`. Critérios de aceite validados. |

**Perguntas de discovery**

- Qual é o contrato canônico de invoice que deve permanecer estável entre provedores?
- Como identificar cliente reutilizável com segurança: documento, `externalReference` ou binding interno?
- Quais erros do Asaas viram erro de negócio, erro técnico ou retry seguro?

### PAY-ICE-002 - Confirmar pagamento por webhook confiável

| Campo | Conteúdo |
| --- | --- |
| Tipo | Feature |
| Problema/oportunidade | Pagamento confirmado precisa liberar pedido uma única vez, mesmo com webhook duplicado, atrasado ou recebido antes da consolidação interna da invoice. |
| Usuário/cliente | Ecommerce Magazine Siara, Order Management, Payments, Financeiro, Atendimento. |
| Outcome esperado | Evento canônico `payment.confirmed` publicado uma única vez por pagamento confirmado, com invoice atualizada e evento bruto auditável. |
| Evidência atual | Feature `Confirmação de pagamento por webhook`; necessidade de confirmação confiável, conciliação e proteção contra duplicidade. |
| Escopo MVP | Validar token Asaas, persistir evento bruto, processar `PAYMENT_CONFIRMED`, processar `PAYMENT_RECEIVED`, deduplicar eventos, correlacionar por `providerPaymentId` ou `externalReference`. |
| Fora de escopo | Painel financeiro completo, contestação, chargeback, regras avançadas de reconciliação multi-provedor. |
| Dependências | Endpoint público de webhook, segredo/token Asaas, armazenamento de eventos brutos, publicação de eventos canônicos, contrato com ecommerce/Orders. |
| Riscos | Pedido liberado duas vezes, pagamento recebido sem pedido liberado, token vazado em logs, evento não correlacionado, divergência entre `CONFIRMED` e `RECEIVED`. |
| Telemetria mínima | Webhook received, webhook rejected, event deduplication, invoice status transition, canonical event published, lag entre recebimento e publicação. |
| Critérios de aceite | Cenários do arquivo [payment-confirmation.feature](../../bdd/payment-confirmation.feature) passam; webhook inválido não altera invoice; evento duplicado retorna sucesso técnico sem republicar; `PAYMENT_RECEIVED` não libera pedido pela segunda vez. |
| Score | Reach 5, Impact 5, Confidence 4, Effort 5, Operational Risk 4 = 20.8 |
| Status | Done — Entregue em v0.5.0/v0.6.0. OBC: `prodops/artifacts/obcs/payment-confirmation.md`. Critérios de aceite validados. |

**Perguntas de discovery**

- Qual evento canônico deve liberar pedido: `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED` ou ambos com regras diferentes?
- Qual é o SLA aceitável entre webhook recebido e evento entregue ao ecommerce?
- Como operar eventos não correlacionados ou recebidos fora de ordem?

### PAY-ICE-003 - Cancelar invoice pendente com idempotência

| Campo | Conteúdo |
| --- | --- |
| Tipo | Feature |
| Problema/oportunidade | O ecommerce precisa cancelar cobranças pendentes para impedir pagamento indevido, mantendo idempotência e decisão clara quando o provedor divergir. |
| Usuário/cliente | Ecommerce Magazine Siara, Checkout, Payments, Atendimento, Operação. |
| Outcome esperado | Invoice aberta pode ser cancelada com segurança, sem chamada duplicada ao provedor e sem evento canônico incorreto. |
| Evidência atual | Feature `Cancelar invoice no gateway de pagamentos`; necessidade de cancelamento de cobranças ainda ativas. |
| Escopo MVP | Cancelar invoice `OPEN` no Asaas, registrar `CANCEL_REQUESTED`, confirmar `CANCELLED`, publicar `payment.cancelled`, impedir cancelamento após `CONFIRMED`, tratar 404 de provedor. |
| Fora de escopo | Estorno após pagamento confirmado, disputa financeira, cancelamento parcial, políticas avançadas de conciliação. |
| Dependências | Política de estados da invoice, endpoint Asaas `DELETE /v3/payments/{id}`, idempotência de cancelamento, evento `payment.cancelled`, política para 404. |
| Riscos | Cobrança permanecer pagável após cancelamento local, publicação de cancelamento sem confirmação do provedor, cancelamento indevido após pagamento, duplicidade de evento. |
| Telemetria mínima | Cancel request, provider delete latency/error, status transition, idempotency hit/miss, webhook `PAYMENT_DELETED`, canonical cancellation published. |
| Critérios de aceite | Cenários do arquivo [cancel-invoice.feature](../../bdd/cancel-invoice.feature) passam; invoice `CONFIRMED` não é cancelada; retry com mesma chave não chama o provedor; 404 não publica `payment.cancelled` sem decisão explícita. |
| Score | Reach 3, Impact 4, Confidence 4, Effort 4, Operational Risk 2 = 13.7 |
| Status | Ready for Delivery — OBC committed em `prodops/artifacts/obcs/cancel-invoice.md`. Adiado para próxima iteração. |

**Perguntas de discovery**

- O evento `payment.cancelled` deve ser publicado no comando de cancelamento ou apenas após webhook `PAYMENT_DELETED`?
- Qual política operacional deve ser aplicada quando o Asaas retorna 404?
- Quais status permitem cancelamento e quais exigem fluxo de estorno?

---

### RT-ICE-001 - Event Pipeline Completeness

| Campo | Conteúdo |
| --- | --- |
| Tipo | Observabilidade / Runtime |
| Problema/oportunidade | Eventos intermediários de Bootstrap (Dependencies.Installed, Services.Ready, Smoke.Passed) somem silenciosamente no Datadog; oem-state ficou preso durante v0.11.0 e exigiu correção manual. |
| Usuário/cliente | Tech Lead Payments, Context Engineer, qualquer stakeholder que usa o dashboard Datadog para monitorar entregas. |
| Outcome esperado | Pipeline emit-event entrega todos os 5 eventos de Bootstrap com tags corretas e o GitHub Project Board reflete o estado atual sem intervenção manual. |
| Evidência atual | Business Signal #135 (itens 2 e 3); DS-53 ficou preso em FINISHING durante v0.11.0; logs de Datadog confirmam ausência dos eventos intermediários. |
| Escopo MVP | Investigar gap (skill vs pipeline) e corrigir na camada correta; corrigir mapeamento oem-state FINISHING em `github/sync.sh`. |
| Fora de escopo | Mudanças no schema CloudEvents; alterações nos dashboards (RT-ICE-003). |
| Dependências | Acesso a logs Datadog de v0.11.0; entendimento do código de emit-event e github/sync.sh. |
| Riscos | Fix pode ser no skill (não no pipeline) — exige mudança em camada diferente da prevista. Ver Premortem no OBC. |
| Telemetria mínima | `emit-event` retorna `"github-sync": "success"` para todos os eventos de phase; 5 eventos Bootstrap visíveis no Datadog. |
| Critérios de aceite | Ver OBC `prodops/artifacts/obcs/rt-event-pipeline-completeness.md`. |
| Score | — |
| Status | Icebox — OBC Draft em `prodops/artifacts/obcs/rt-event-pipeline-completeness.md`. Perguntas abertas: onde está o gap (skill ou pipeline)? |

---

### RT-ICE-002 - Continuous Operational Trail

| Campo | Conteúdo |
| --- | --- |
| Tipo | Runtime / Processo |
| Problema/oportunidade | O downstream-agent não documenta ações durante o loop e o trail de cada issue só aparece ao final da iteração — sem rastro de qual phase completou em caso de falha mid-flight. |
| Usuário/cliente | Context Engineer, Tech Lead, qualquer auditor da execução de uma Iteration. |
| Outcome esperado | Trail de cada Feature é uma narrativa contínua: cada phase deixa uma entry antes de avançar, e o agent registra o que está executando no GitHub Issue em tempo real. |
| Evidência atual | Business Signal #135 (itens 1 e 5); trail de v0.11.0 vazio durante execução. |
| Escopo MVP | Instrução ao downstream-agent em `SKILL.md` para registrar entry por phase; entry escrita via `gh issue comment` antes de avançar. |
| Fora de escopo | Integração do trail com Datadog (RT-ICE-003); trail para fases de plan. |
| Dependências | GitHub Issue existente por work-item (criada no Plan Bootstrap). |
| Riscos | Entries duplicadas em restart; rate limit do GitHub. Ver Premortem no OBC. |
| Telemetria mínima | Comments no GitHub Issue com entries por phase. |
| Critérios de aceite | Ver OBC `prodops/artifacts/obcs/rt-continuous-operational-trail.md`. |
| Score | — |
| Status | Icebox — OBC Draft em `prodops/artifacts/obcs/rt-continuous-operational-trail.md`. Pergunta aberta: trail em arquivo ou GitHub Issue ou ambos? |

---

### RT-ICE-003 - Dashboard Evolution

| Campo | Conteúdo |
| --- | --- |
| Tipo | Observabilidade / Dashboard |
| Problema/oportunidade | Dashboard Datadog sem cycle time por phase, sem filtro por Iteration ID e com labels que usam nomes internos de CloudEvents em vez dos nomes canônicos das phases. |
| Usuário/cliente | Tech Lead Payments, PM Payments, stakeholders executivos que acompanham entregas. |
| Outcome esperado | Dashboard Runtime mostra cycle time por phase, permite filtrar por iteração ativa e usa labels legíveis por qualquer stakeholder. |
| Evidência atual | Business Signal #135 (item 4); dashboard atual sem template variable de iteração; labels como `prodops.delivery.bootstrap.started`. |
| Escopo MVP | Tag `iteration:<id>` em `send.sh`; template variable no dashboard; widget de cycle time; labels canônicos. |
| Fora de escopo | Alertas; dados históricos anteriores à implementação; outros produtos. |
| Dependências | PI-RT-001 / RT-ICE-001 deve estar concluído — pipeline completo antes de medir cycle time. Tag `iteration` nos eventos (verificar `send.sh`). |
| Riscos | Tag `iteration` ausente (bloqueante); cycle time com latência em log-based metric. Ver Premortem no OBC. |
| Telemetria mínima | Tag `iteration:<id>` presente em todos os eventos; gauge `prodops.phase.duration_seconds` opcional. |
| Critérios de aceite | Ver OBC `prodops/artifacts/obcs/rt-dashboard-evolution.md`. |
| Score | — |
| Status | Icebox — OBC Draft em `prodops/artifacts/obcs/rt-dashboard-evolution.md`. Bloqueado por RT-ICE-001. Pergunta aberta: tag `iteration` já existe em `send.sh`? |

---

### RT-ICE-004 - Iteration Lifecycle Automation

| Campo | Conteúdo |
| --- | --- |
| Tipo | Runtime / Processo |
| Problema/oportunidade | Ao concluir uma Iteration, o Context Engineer fecha manualmente a tracking issue e preenche assignees um a um — etapas que podem ser automatizadas com `gh` CLI. |
| Usuário/cliente | Context Engineer — elimina steps manuais repetitivos após cada iteração. |
| Outcome esperado | Tracking issue fechada automaticamente após o último Promote.Completed, com comment de encerramento; assignees preenchidos em todas as issues desde o Plan Bootstrap. |
| Evidência atual | Business Signal #135 (itens 6 e 7); v0.11.0 encerrada manualmente sem assignees. |
| Escopo MVP | `gh api user --jq '.login'` para assignees no Bootstrap; auto-close + comment no Iteration Closure. |
| Fora de escopo | Auto-close em falha parcial; notificações externas; assignees variáveis por DS-ID. |
| Dependências | `gh` CLI autenticado com permissão de escrita nas issues; tracking issue criada no Plan Bootstrap. |
| Riscos | Race condition se fechamento disparar antes de todos os Promotes; falha não-fatal de assignee. Ver Premortem no OBC. |
| Telemetria mínima | GitHub Issue fechada com comment; assignee visível nas issues. |
| Critérios de aceite | Ver OBC `prodops/artifacts/obcs/rt-iteration-lifecycle-automation.md`. |
| Score | — |
| Status | Icebox — OBC Draft em `prodops/artifacts/obcs/rt-iteration-lifecycle-automation.md`. Pergunta aberta: auto-close no downstream-agent ou no dispatcher via `Plan.Bootstrap.Completed`? |

---

## 8. Definition of Ready

Um item só deve sair do icebox para delivery quando atender aos critérios abaixo.

| Critério | Evidência esperada |
| --- | --- |
| Problema claro | Dor, oportunidade ou risco escrito em linguagem de negócio e operação. |
| Outcome mensurável | Métrica, evento ou comportamento esperado definido. |
| Usuário/cliente conhecido | Sistemas, pessoas ou times impactados identificados. |
| Escopo MVP delimitado | Inclusões e exclusões documentadas. |
| Contrato definido | API, evento, payload ou comportamento externo versionável. |
| Estados e erros mapeados | Transições principais, falhas esperadas e regras de retry/idempotência claras. |
| Observabilidade planejada | Logs, métricas, traces, auditoria e alertas mínimos definidos. |
| Dependências conhecidas | Times, credenciais, tópicos, filas, tabelas e provedores mapeados. |
| Critérios de aceite | Cenários testáveis e rastreáveis a feature file ou especificação. |
| Owner definido | Responsável de produto e técnico nomeados. |

## 9. Definition of Done operacional

| Dimensão | Critério |
| --- | --- |
| Produto | Outcome inicial validado ou plano de medição ativo. |
| Engenharia | Testes automatizados relevantes passando, contrato versionado e deploy rastreável. |
| Confiabilidade | Logs, métricas, traces e alertas mínimos em funcionamento. |
| Operação | Runbook ou procedimento de suporte atualizado para falhas conhecidas. |
| Dados | Eventos canônicos e auditoria persistidos quando aplicável. |
| Segurança | Segredos, tokens e payloads sensíveis protegidos em logs, erros e auditoria. |
| Aprendizado | Decisões, limites e trade-offs registrados no artefato correspondente. |

## 10. Decisões pendentes

| ID | Decisão | Impacto | Dono | Status |
| --- | --- | --- | --- | --- |
| DEC-001 | Definir contrato canônico de invoice entre ecommerce e Payments API. | Bloqueia estabilidade de API e testes de contrato. | Tech Lead Payments | Aberto |
| DEC-002 | Definir política de publicação para `payment.confirmed`, `payment.received` e `payment.cancelled`. | Afeta Orders, ecommerce e conciliação. | PM Payments + Tech Lead Payments | Aberto |
| DEC-003 | Definir política para erros 404, 409, 422, 5xx e timeout do Asaas. | Afeta retry, suporte e estado final da invoice. | Engenharia Payments | Aberto |
| DEC-004 | Definir retenção e mascaramento de eventos brutos de webhook. | Afeta auditoria, segurança e LGPD. | Segurança + Payments | Aberto |
| DEC-005 | Definir SLO inicial de confirmação de pagamento. | Afeta dashboards, alertas e readiness operacional. | SRE + Payments | Aberto |

## 11. Próximas ações recomendadas

| Ação | Dono sugerido | Saída esperada |
| --- | --- | --- |
| Revisar scores com PM, Tech Lead e SRE. | PM Payments | Priorização inicial validada. |
| Transformar PAY-ICE-002 em discovery técnico-operacional. | Tech Lead Payments | Decisão sobre eventos, idempotência e correlação. |
| Especificar contrato canônico de invoice. | Engenharia Payments | OpenAPI ou contrato interno versionado. |
| Definir eventos canônicos e tópicos de publicação. | Payments + Orders | Contrato de integração entre Payments e ecommerce/Orders. |
| Criar matriz de estados da invoice. | Engenharia Payments | Estados permitidos, transições e regras de erro. |
