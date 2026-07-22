# Premortem ProdOps - Payments e Checkout

> Exercício preventivo para antecipar falhas prováveis na sprint de integração entre Checkout, Payments e Notification Service. O objetivo é transformar riscos conhecidos em ações observáveis antes de habilitar o novo gateway em produção.

## 1. Contexto executivo

Os times de Ecommerce da Magazine Siara iniciaram um processo de desacoplamento do monólito para aumentar a autonomia das equipes, reduzir dependência entre entregas e permitir evolução mais rápida dos domínios de negócio. Dentro desse movimento, o time de Payments foi criado para administrar as funcionalidades relacionadas à gestão de pagamentos dos clientes, incluindo criação de cobranças, confirmação de pagamento, eventos de status e integrações com provedores externos.

Parte da estrutura de notificação já foi extraída para um serviço separado, pois estava tecnicamente pronta para operar fora do monólito. Com isso, algumas funcionalidades foram antecipadas para consumo pelo Ecommerce, que segue centralizando a conversação com os clientes e orquestrando a comunicação de status da jornada de compra.

O serviço de Checkout já está preparado para usar o novo gateway em produção, mas a ativação permanece bloqueada por Feature Flag devido a um bug localizado. Ao mesmo tempo, o Notification Service já está em uso e possui histórico recente de incidentes que prejudicaram a comunicação de confirmação de pagamento ao cliente.

A próxima sprint do time, prevista para iniciar no dia 20 e durar 15 dias, pretende entregar as capacidades necessárias para a funcionalidade de Checkout:

- Criar invoice via Pix.
- Criar invoice via Boleto.
- Confirmar pagamento.
- Notificar status de pagamento.

## 2. Premissa do premortem

Estamos no fim da sprint de 15 dias e a entrega falhou ou precisou ser revertida. O novo fluxo de pagamento não foi habilitado com segurança em produção, clientes ficaram sem informação confiável sobre o pagamento, ou houve divergência entre Checkout, Payments, Notification Service e provedor de pagamento.

Este documento responde: o que provavelmente aconteceu, quais sinais teriam aparecido antes e quais ações reduzem a chance de falha.

## 3. Resultado esperado da sprint

| Resultado | Descrição |
| --- | --- |
| Checkout integrado ao gateway | Checkout consegue criar invoices no Payments usando contrato estável para Pix e Boleto. |
| Pagamento confirmável | Payments recebe confirmação do provedor, atualiza estado interno e publica evento canônico. |
| Cliente informado | Notification Service comunica status de pagamento ao cliente sem duplicidade, atraso excessivo ou silêncio operacional. |
| Feature Flag segura | Ativação do novo gateway pode ser feita de forma gradual, reversível e observável. |
| Operação preparada | Times conseguem diagnosticar falhas por orderId, invoiceId, paymentId, providerPaymentId e correlationId. |

## 4. Hipóteses críticas

| Hipótese | Risco se for falsa | Como validar antes do go-live |
| --- | --- | --- |
| O contrato Checkout -> Payments cobre Pix e Boleto sem ambiguidade. | Checkout envia payload válido para um meio e inválido para outro; erros aparecem só em produção. | Testes de contrato para Pix e Boleto, exemplos versionados e validação de schema. |
| A Feature Flag isola totalmente o novo gateway. | Parte do tráfego usa o gateway novo sem controle ou rollback consistente. | Teste de ativação/desativação em ambiente controlado e auditoria por tenant/canal. |
| Notification Service consegue operar a carga e os eventos esperados. | Cliente paga, mas não recebe confirmação ou recebe mensagens duplicadas. | Teste de carga leve, deduplicação por evento e dashboard de envio/falha. |
| Payments possui idempotência por pedido/invoice. | Retentativas criam cobranças duplicadas. | Testes com mesma chave de idempotência para sucesso, timeout e retry. |
| Confirmação de pagamento e notificação usam eventos correlacionáveis. | Pagamento confirmado não encontra pedido ou notificação correta. | Rastrear correlationId, orderId, invoiceId, paymentId e providerPaymentId ponta a ponta. |

## 5. Cenários de falha prováveis

| ID | Falha imaginada | Causa provável | Impacto | Sinais antecipados | Ação preventiva |
| --- | --- | --- | --- | --- | --- |
| PMT-PRE-001 | Checkout habilita o novo gateway e parte dos pedidos não cria invoice. | Contrato Pix/Boleto incompleto, validação divergente ou bug ainda protegido pela Feature Flag. | Queda de conversão e aumento de erro no checkout. | 4xx/5xx em criação de invoice, feature flag ligada para poucos usuários com erro acima do baseline. | Criar suite de contrato Checkout -> Payments e checklist de liberação da flag. |
| PMT-PRE-002 | Cliente paga, mas não recebe confirmação. | Notification Service falha, não consome evento ou não correlaciona pagamento e pedido. | Chamados no atendimento, baixa confiança e pedidos parados. | `payment.confirmed` sem notificação enviada; aumento de eventos em retry/dead-letter. | Definir SLO de notificação e alerta para confirmação sem comunicação ao cliente. |
| PMT-PRE-003 | Pagamento é confirmado mais de uma vez. | Webhook duplicado, retry do provedor ou consumo não idempotente. | Pedido liberado duas vezes, notificação duplicada e risco operacional. | Eventos repetidos com mesmo `providerPaymentId`; duplicidade de `payment.confirmed`. | Persistir eventos brutos e deduplicar por provider event id, payment id e transição de estado. |
| PMT-PRE-004 | Pix funciona, mas Boleto falha em produção. | Boleto foi tratado como variação simples de invoice, sem regras próprias de vencimento, linha digitável e status. | Clientes de Boleto ficam bloqueados ou recebem instrução incorreta. | Erros concentrados em `billingType=Boleto`; payloads rejeitados pelo provedor. | Separar critérios de aceite de Pix e Boleto e testar contratos específicos por meio. |
| PMT-PRE-005 | Feature Flag não permite rollback limpo. | Estado criado no novo gateway não tem reconciliação ou fallback para o fluxo antigo. | Operação fica presa entre dois fluxos e precisa tratar pedidos manualmente. | Pedidos iniciados no gateway novo continuam recebendo eventos após flag desligada. | Definir política de rollback: novos pedidos voltam ao fluxo antigo, pedidos já iniciados seguem reconciliados no Payments. |
| PMT-PRE-006 | Times não conseguem diagnosticar falhas rapidamente. | Logs sem correlationId, dashboards incompletos ou eventos sem identificadores comuns. | MTTR alto e decisão por percepção, não por evidências. | Incidentes dependem de consulta manual em banco/provedor; Atendimento sem status confiável. | Padronizar logs e eventos com orderId, invoiceId, paymentId, providerPaymentId e correlationId. |
| PMT-PRE-007 | Criação de invoice gera cobrança duplicada. | Retentativa do Checkout após timeout sem idempotência consistente. | Cliente pode pagar duplicado; conciliação e suporte ficam comprometidos. | Mesmo orderId com mais de uma invoice aberta no provedor. | Exigir chave de idempotência por operação e bloquear duplicidade por orderId + método + tenant. |
| PMT-PRE-008 | A sprint entrega endpoints, mas não entrega operabilidade. | Scrum foca itens funcionais e deixa alertas, runbooks e dashboards para depois. | Go-live tecnicamente possível, mas operacionalmente frágil. | Histórias sem critério de observabilidade; ausência de runbook para incidentes conhecidos. | Incluir Definition of Done operacional para cada história da sprint. |
| PMT-PRE-009 | Pagamento falha em produção por throttling no DynamoDB. | Tabelas ainda operando com BillingMode PROVISIONED (1 WCU padrão) — qualquer carga real excede o limite. | Criação de invoice ou confirmação de pagamento começa a retornar erro 500; clientes impactados. | `ProvisionedThroughputExceededException` em logs do Lambda; latência da API aumenta abruptamente. | Garantir que todas as tabelas de produção operem com PAY_PER_REQUEST antes do go-live — validar via `describe-table` no pipeline. |
| PMT-PRE-010 | Dado de pagamento corrompido ou deletado incorretamente sem possibilidade de recuperação. | PITR não habilitado nas tabelas de produção — ausência de backup contínuo significa perda irreversível de dados. | Perda de dados de pagamento, inconsistência entre Payments e Ecommerce, risco regulatório. | Incidente detectado somente após operação de escrita ou delete que corrompeu dados; sem snapshot recente disponível. | Habilitar PITR em todas as tabelas críticas (`UpdateContinuousBackups`) antes de qualquer carga de produção — validar via `describe-continuous-backups`. |
| PMT-PRE-011 | Deploy não autorizado em produção altera comportamento da API sem aprovação. | Pipeline de CI/CD sem gate de aprovação humana — qualquer push em main pode triggerar deploy em produção. | Mudança não revisada chega a produção; incidente difícil de atribuir; rollback manual necessário. | Deploy concluído sem registro de aprovação; ausência de rastro auditável no GitHub Actions. | Configurar `workflow_dispatch` exclusivo e GitHub Environment `production` com Required Reviewers — bloquear qualquer trigger automático por push. |

## 6. Perguntas que precisam de resposta antes da sprint

| Pergunta | Por que importa | Dono sugerido |
| --- | --- | --- |
| Qual bug mantém o novo gateway desligado por Feature Flag? | Define risco real de go-live e critério mínimo de correção. | Tech Lead Checkout + Payments |
| A entrega de Pix e Boleto usa o mesmo contrato ou contratos especializados? | Evita que regras de um meio contaminem o outro. | Engenharia Payments |
| Quem é dono da comunicação final ao cliente: Ecommerce ou Notification Service? | Define responsabilidade quando pagamento confirma, mas cliente não é avisado. | PM Ecommerce + PM Payments |
| Qual evento libera notificação de status: criação, confirmação, recebimento ou cancelamento? | Evita mensagens antecipadas, duplicadas ou ausentes. | Payments + Notification |
| Qual é a política para pedidos criados enquanto a flag estava ligada e depois desligada? | Evita perda de rastreabilidade durante rollback. | Checkout + Payments + Operação |
| Quais incidentes recentes do Notification Service se repetiriam neste fluxo? | Usa aprendizado real para reduzir reincidência. | SRE + Notification |

## 7. Readiness checklist

| Área | Critério mínimo antes de habilitar em produção | Status |
| --- | --- | --- |
| Produto | Jornada Pix e Boleto descritas com estados esperados e mensagens ao cliente. | Aberto |
| Checkout | Feature Flag com rollout gradual, auditoria e rollback testado. | Aberto |
| Payments | Criação de invoice idempotente para Pix e Boleto. | Aberto |
| Payments | Confirmação de pagamento deduplicada e correlacionada com invoice/pedido. | Aberto |
| Notification | Consumo de eventos com deduplicação e rastreabilidade por pedido. | Aberto |
| Observabilidade | Dashboard com criação de invoice, confirmação, notificação, erro e latência. | Aberto |
| Alertas | Alerta para pagamento confirmado sem notificação ao cliente. | Aberto |
| Operação | Runbook para falha de invoice, confirmação ausente, notificação ausente e rollback da flag. | Aberto |
| Atendimento | Consulta ou procedimento para informar status confiável ao cliente. | Aberto |
| Segurança | Segredos e payloads sensíveis do provedor mascarados em logs e auditoria. | Aberto |
| Persistência | DynamoDB produção com PAY_PER_REQUEST e PITR habilitado em todas as tabelas críticas. | Fechado — EXP-011 concluído |
| Observabilidade | Datadog ativo em produção com traces e log injection (DD_TRACE_ENABLED=true, DD_LOGS_INJECTION=true). | Fechado — EXP-010 concluído |
| CI/CD | Deploy em produção exige aprovação do Required Reviewer via GitHub Environment — sem deploy manual não rastreado. | Fechado — EXP-012 concluído |

## 8. Plano de redução de risco

| Prioridade | Ação | Resultado esperado | Dono sugerido |
| --- | --- | --- | --- |
| P0 | Corrigir e documentar o bug que mantém o gateway desabilitado. | Feature Flag deixa de esconder risco desconhecido. | Checkout + Payments |
| P0 | Definir contrato canônico de invoice para Pix e Boleto. | Checkout e Payments integram sem ambiguidade de payload e erro. | Payments |
| P0 | Implementar idempotência e deduplicação em criação e confirmação. | Retentativas não geram cobrança ou notificação duplicada. | Payments |
| P0 | Criar alerta para `payment.confirmed` sem notificação entregue. | Incidente de cliente sem informação aparece antes do chamado. | SRE + Notification |
| P1 | Criar dashboard de jornada ponta a ponta. | Time visualiza conversão técnica por etapa. | SRE + Payments |
| P1 | Testar rollback da Feature Flag com pedidos em andamento. | Desligamento não abandona invoices já criadas. | Checkout + Payments |
| P1 | Revisar incidentes recentes do Notification Service. | Ações de mitigação entram na sprint, não no pós-incidente. | Notification + SRE |
| P2 | Criar runbook inicial de pagamento confirmado sem notificação. | Atendimento e operação têm procedimento padrão. | Payments + Atendimento |

## 9. Definition of Done ProdOps para a sprint

Uma história da sprint só deve ser considerada concluída quando atender aos pontos abaixo, quando aplicável:

- Critérios funcionais implementados e testados.
- Contrato de API ou evento documentado.
- Erros esperados mapeados com resposta clara para Checkout/Ecommerce.
- Idempotência validada para retry do cliente, timeout e webhook duplicado.
- Logs estruturados com `correlationId`, `orderId`, `invoiceId`, `paymentId` e `providerPaymentId`.
- Métricas de sucesso, erro e latência emitidas.
- Evento canônico publicado uma única vez por transição relevante.
- Dashboard ou query operacional disponível.
- Runbook mínimo atualizado para falhas conhecidas.
- Feature Flag testada para ativação gradual e rollback.

## 10. Narrativa melhorada para alinhamento

O desacoplamento do monólito da Magazine Siara criou uma fronteira nova entre Ecommerce, Checkout, Payments e Notification Service. Essa fronteira aumenta autonomia, mas também transfere parte do risco para contratos, eventos, observabilidade e operação entre times.

Payments passa a ser o dono do domínio de pagamento: criar invoices, integrar provedores, receber confirmações e manter estados confiáveis. Ecommerce continua responsável pela conversa com o cliente, mas depende de sinais corretos e tempestivos de Payments e Notification Service para informar status da compra.

Como o Notification Service já opera fora do monólito e já apresentou incidentes, ele deve ser tratado como dependência crítica da jornada, não apenas como canal auxiliar. Uma confirmação de pagamento tecnicamente correta ainda pode falhar como experiência do cliente se a notificação não for enviada, for duplicada ou chegar atrasada.

O novo gateway está tecnicamente preparado no Checkout, mas permanece desabilitado por Feature Flag por causa de um bug localizado. Isso indica que a sprint não deve medir sucesso apenas por endpoints entregues. O sucesso real exige liberar o fluxo com contrato claro, idempotência, rollback testado, telemetria ponta a ponta e runbooks para os cenários de falha mais prováveis.

Para a sprint de 15 dias iniciada no dia 20, as entregas de invoice Pix, invoice Boleto, confirmação de pagamento e notificação de status devem ser planejadas como uma jornada única. A falha mais perigosa não é apenas uma chamada retornar erro; é o cliente pagar e a plataforma não conseguir explicar, confirmar, notificar ou reconciliar o que aconteceu.
