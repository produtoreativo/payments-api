# language: pt
Funcionalidade: Confirmacao de pagamento por webhook
  Como ecommerce Magazine Siará
  Quero receber confirmacao confiavel de pagamento
  Para liberar o pedido uma unica vez apos aprovacao do provedor

  Contexto:
    Dado que a invoice "inv-100045" existe no gateway com status "OPEN"
    E a invoice esta associada ao provedor "ASAAS"
    E a invoice possui "providerPaymentId" igual a "pay_asaas_123"
    E o webhook da Asaas foi configurado com token de autenticacao

  Cenário: Confirmar pagamento com evento PAYMENT_CONFIRMED
    Quando a Asaas enviar um webhook "PAYMENT_CONFIRMED" para "pay_asaas_123"
    E o header "asaas-access-token" for valido
    Então o gateway deve persistir o evento bruto recebido
    E deve atualizar a invoice para status "CONFIRMED"
    E deve publicar o evento canonico "payment.confirmed" para o ecommerce
    E o evento deve conter "invoiceId", "orderId", "provider", "providerPaymentId" e data de confirmacao

  Cenário: Conciliar recebimento financeiro com evento PAYMENT_RECEIVED
    Dado que a invoice "inv-100045" ja esta com status "CONFIRMED"
    Quando a Asaas enviar um webhook "PAYMENT_RECEIVED" para "pay_asaas_123"
    Então o gateway deve atualizar a invoice para status "RECEIVED"
    E deve registrar o evento para conciliacao financeira
    E nao deve publicar uma segunda liberacao de pedido ao ecommerce

  Cenário: Rejeitar webhook com token invalido
    Quando a Asaas enviar um webhook sem o header "asaas-access-token" valido
    Então o gateway deve rejeitar a requisicao
    E nao deve alterar o status da invoice
    E nao deve publicar evento ao ecommerce
    E deve registrar log de seguranca sem expor o token recebido

  Cenário: Processar webhook duplicado sem efeito colateral
    Dado que o evento "PAYMENT_CONFIRMED" para "pay_asaas_123" ja foi processado
    Quando o mesmo webhook for recebido novamente
    Então o gateway deve reconhecer a duplicidade
    E deve responder com sucesso tecnico para evitar novas retentativas do provedor
    E nao deve publicar outro "payment.confirmed"

  Cenário: Receber webhook antes da resposta da criacao da invoice
    Dado que existe uma tentativa de criacao de invoice com "externalReference" igual a "MS-100045"
    Mas o "providerPaymentId" ainda nao foi consolidado internamente
    Quando a Asaas enviar "PAYMENT_CONFIRMED" com "externalReference" igual a "MS-100045"
    Então o gateway deve correlacionar o evento pela referencia externa
    E deve concluir a associacao com a invoice correta
    E deve confirmar o pagamento sem criar invoice duplicada

  Cenário: Ignorar evento que nao libera pedido no MVP
    Quando a Asaas enviar um evento "PAYMENT_OVERDUE"
    Então o gateway deve registrar o evento
    E deve atualizar o estado operacional quando aplicavel
    E nao deve publicar "payment.confirmed" ao ecommerce

