# language: pt
Funcionalidade: Pagamento com cartao de credito no gateway de pagamentos
  Como ecommerce Magazine Siará
  Quero aceitar pagamento com cartao de credito por um contrato observavel
  Para aumentar conversao sem acoplar o checkout diretamente ao provedor Asaas

  Contexto:
    Dado que o provedor "ASAAS" esta habilitado para o ecommerce Magazine Siará
    E o ecommerce envia uma chave de idempotencia em toda solicitacao de criacao
    E o webhook da Asaas foi configurado com token de autenticacao

  Cenário: Criar cobranca de cartao com entrada hospedada no Asaas
    Quando o ecommerce solicitar a criacao de uma invoice com "billingType" igual a "CREDIT_CARD"
    E nao enviar dados de cartao no payload do gateway
    Então o gateway deve chamar "POST /v3/payments"
    E deve retornar uma URL de pagamento hospedada pelo provedor
    E deve manter a invoice em estado "OPEN" ate receber confirmacao por webhook
    E nao deve trafegar dados sensiveis de cartao pela Payments API

  Cenário: Confirmar pagamento de cartao hospedado por webhook
    Dado que a invoice de cartao hospedado foi criada com status "OPEN"
    E o cliente concluiu o pagamento no ambiente hospedado da Asaas
    Quando a Asaas enviar "PAYMENT_CONFIRMED"
    Então o gateway deve atualizar a invoice para "CONFIRMED"
    E deve publicar o evento canonico "payment.confirmed" uma unica vez
    E deve manter a rastreabilidade por "orderId", "invoiceId", "providerPaymentId" e "correlationId"

  Cenário: Conciliar recebimento financeiro de cartao
    Dado que a invoice de cartao esta com status "CONFIRMED"
    Quando a Asaas enviar "PAYMENT_RECEIVED"
    Então o gateway deve atualizar a invoice para "RECEIVED"
    E deve registrar o recebimento para conciliacao financeira
    E nao deve publicar uma segunda liberacao de pedido

  Cenário: Criar cobranca de cartao tokenizado
    Dado que existe um token de cartao associado ao cliente Asaas correto
    Quando o ecommerce solicitar a criacao de uma invoice com "billingType" igual a "CREDIT_CARD"
    E enviar "creditCardToken" e "remoteIp"
    Então o gateway deve chamar "POST /v3/payments" com os campos de tokenizacao
    E deve classificar autorizacao, recusa ou analise de risco sem expor dados sensiveis
    E deve aplicar timeout explicito de pelo menos 60 segundos para a chamada ao provedor

  Cenário: Listar cartoes cadastrados para o carrinho
    Dado que o cliente possui cartoes tokenizados associados ao usuario e tenant corretos
    Quando o carrinho solicitar "GET /users/{userId}/payment-methods/credit-cards"
    Então o gateway deve retornar apenas "cardId", bandeira, ultimos 4 digitos, validade e status
    E nao deve retornar "creditCardToken", numero completo, CVV ou payload bruto do provedor
    E deve registrar o evento observavel "payment.card.saved.listed"

  Cenário: Impedir acesso a cartao salvo de outro usuario ou tenant
    Dado que existe um "cardId" associado a outro usuario ou tenant
    Quando o carrinho tentar listar ou pagar usando esse cartao
    Então o gateway deve rejeitar a operacao
    E deve registrar motivo observavel sem expor token ou dados sensiveis

  Cenário: Cadastrar novo cartao preservando fronteira PCI
    Dado que a capability de tokenizacao foi aprovada por Seguranca e Arquitetura
    Quando o carrinho enviar um novo cartao para cadastro
    Então o gateway deve enviar "creditCard" e "creditCardHolderInfo" ao provedor apenas de forma transiente
    E deve persistir somente token protegido, bandeira, ultimos 4 digitos, validade, usuario, tenant e status
    E nao deve persistir numero completo, CVV ou payload bruto de cartao

  Cenário: Pagar com cartao cadastrado
    Dado que o cliente selecionou um "cardId" valido no carrinho
    Quando o carrinho solicitar pagamento com cartao cadastrado informando "remoteIp"
    Então o gateway deve resolver o "cardId" para o token protegido do provedor
    E deve enviar "creditCardToken" e "remoteIp" para a Asaas
    E deve mapear autorizacao, confirmacao, recusa ou analise de risco

  Cenário: Pagar com novo cartao sem armazenar dados sensiveis
    Dado que a capability de novo cartao esta habilitada no ambiente
    Quando o carrinho enviar dados de novo cartao para pagamento
    Então o gateway deve usar os dados apenas para a tentativa atual e eventual tokenizacao autorizada
    E deve mascarar dados sensiveis em logs, traces, erros e eventos
    E deve rejeitar a operacao se a capability nao estiver aprovada para o ambiente

  Cenário: Mapear pagamento autorizado aguardando captura
    Dado que a invoice de cartao esta associada ao provedor "ASAAS"
    Quando a Asaas enviar o evento "PAYMENT_AUTHORIZED"
    Então o gateway deve registrar a autorizacao
    E deve emitir evento observavel sem liberar pedido como pagamento confirmado

  Cenário: Mapear analise de risco aprovada
    Dado que a invoice de cartao esta em analise de risco
    Quando a Asaas enviar "PAYMENT_APPROVED_BY_RISK_ANALYSIS"
    Então o gateway deve registrar a aprovacao da analise de risco
    E deve aguardar o evento de confirmacao antes de liberar pedido

  Cenário: Mapear analise de risco reprovada
    Dado que a invoice de cartao esta em analise de risco
    Quando a Asaas enviar "PAYMENT_REPROVED_BY_RISK_ANALYSIS"
    Então o gateway deve registrar a reprovacao da analise de risco
    E deve emitir evento observavel de pagamento recusado
    E nao deve publicar "payment.confirmed"

  Cenário: Mapear analise de risco manual
    Dado que a invoice de cartao esta associada ao provedor "ASAAS"
    Quando a Asaas enviar "PAYMENT_AWAITING_RISK_ANALYSIS"
    Então o gateway deve registrar que o pagamento esta em analise
    E deve impedir timeout operacional silencioso da jornada do checkout

  Cenário: Mapear recusa de captura
    Dado que a invoice de cartao esta associada ao provedor "ASAAS"
    Quando a Asaas enviar "PAYMENT_CREDIT_CARD_CAPTURE_REFUSED"
    Então o gateway deve marcar o pagamento como recusado ou falho de negocio
    E deve publicar motivo observavel para checkout, atendimento e operacao

  Cenário: Confirmar pagamento com cartao
    Dado que a invoice de cartao esta associada ao provedor "ASAAS"
    Quando a Asaas enviar "PAYMENT_CONFIRMED"
    Então o gateway deve atualizar a invoice para "CONFIRMED"
    E deve publicar o evento canonico "payment.confirmed" uma unica vez

  Cenário: Simular pagamento aprovado na sandbox Asaas
    Dado que o ambiente utilizado e a sandbox da Asaas
    E o experimento "002-sandbox-funding" esta sendo executado
    Quando o ecommerce validar um pagamento com cartao de teste aprovado
    Então o gateway deve tratar o resultado como evidencia funcional de sandbox
    E deve registrar quais estados foram reproduzidos pela sandbox
    E deve registrar quais estados foram apenas simulados no Validation Workbench

  Cenário: Simular pagamento recusado na sandbox ou no Validation Workbench
    Dado que o ambiente utilizado e a sandbox da Asaas ou o Validation Workbench
    Quando o provedor simular recusa, captura recusada ou reprovacao por risco
    Então o gateway deve manter a invoice fora de "CONFIRMED"
    E deve registrar motivo observavel para checkout, atendimento e operacao
    E deve preservar idempotencia para retentativa segura quando aplicavel

  Cenário: Tratar estorno como fluxo diferente de cancelamento
    Dado que a invoice de cartao esta com status "CONFIRMED"
    Quando o ecommerce solicitar cancelamento apos confirmacao
    Então o gateway deve rejeitar o cancelamento simples
    E deve orientar o fluxo de estorno ou reversao

  Cenário: Solicitar estorno de pagamento confirmado
    Dado que a invoice de cartao esta com status "CONFIRMED" ou "RECEIVED"
    Quando o ecommerce solicitar "POST /invoices/{invoiceId}/refund"
    Então o gateway deve registrar "payment.card.refund.requested"
    E deve aguardar evidencia do provedor antes de tratar o estorno como concluido
    E deve impedir duplicidade de estorno por idempotencia

  Cenário: Manter captura direta de cartao fora do primeiro slice
    Dado que o ecommerce deseja enviar dados sensiveis de cartao diretamente para Payments API
    Quando a capability ainda nao tiver decisao formal de seguranca, compliance e antifraude
    Então o gateway nao deve aceitar captura direta como escopo Downstream
    E deve manter essa alternativa como investigacao Upstream
