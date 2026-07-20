# language: pt
Funcionalidade: Cancelar invoice no gateway de pagamentos
  Como ecommerce Magazine Siará
  Quero cancelar uma invoice pendente usando o gateway
  Para impedir pagamento de cobrancas que nao devem mais permanecer ativas

  Contexto:
    Dado que o ecommerce envia uma chave de idempotencia em toda solicitacao de cancelamento
    E a invoice "inv-100045" esta associada ao pedido "MS-100045"
    E a invoice possui provedor "ASAAS"
    E a invoice possui "providerPaymentId" igual a "pay_asaas_123"

  Cenário: Cancelar invoice aberta com sucesso no Asaas
    Dado que a invoice "inv-100045" esta com status "OPEN"
    Quando o ecommerce solicitar o cancelamento da invoice
    Então o gateway deve atualizar a invoice para "CANCEL_REQUESTED"
    E deve chamar o endpoint Asaas "DELETE /v3/payments/pay_asaas_123"
    E deve atualizar a invoice para "CANCELLED"
    E deve publicar o evento canonico "payment.cancelled" para o ecommerce

  Cenário: Cancelamento idempotente
    Dado que a invoice "inv-100045" ja foi cancelada com a chave de idempotencia "MS-100045:cancel"
    Quando o ecommerce repetir o cancelamento com a mesma chave de idempotencia
    Então o gateway nao deve chamar novamente a Asaas
    E deve retornar o status "CANCELLED"

  Cenário: Impedir cancelamento apos pagamento confirmado
    Dado que a invoice "inv-100045" esta com status "CONFIRMED"
    Quando o ecommerce solicitar o cancelamento da invoice
    Então o gateway deve rejeitar a operacao por regra de negocio
    E nao deve chamar "DELETE /v3/payments/pay_asaas_123"
    E deve informar que cancelamento apos confirmacao exige fluxo de estorno

  Cenário: Provedor informa que cobranca nao existe
    Dado que a invoice "inv-100045" esta com status "OPEN"
    Quando a Asaas retornar "404" ao cancelar "pay_asaas_123"
    Então o gateway deve consultar a politica de conciliacao
    E deve manter a invoice em estado que permita investigacao operacional
    E nao deve publicar "payment.cancelled" sem confirmacao de remocao ou decisao explicita de reconciliacao

  Cenário: Webhook de remocao confirma cancelamento
    Dado que a invoice "inv-100045" esta com status "CANCEL_REQUESTED"
    Quando a Asaas enviar o webhook "PAYMENT_DELETED" para "pay_asaas_123"
    Então o gateway deve confirmar o status "CANCELLED"
    E deve registrar o evento bruto para auditoria
    E nao deve duplicar o evento "payment.cancelled" se ele ja tiver sido publicado no comando de cancelamento

