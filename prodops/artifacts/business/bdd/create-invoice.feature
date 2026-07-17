# language: pt
Funcionalidade: Criar invoice no gateway de pagamentos
  Como ecommerce Magazine Siará
  Quero criar uma invoice usando um contrato unico de gateway
  Para emitir cobrancas sem depender diretamente da API de um provedor especifico

  Contexto:
    Dado que o gateway possui os provedores "ITAU" e "ASAAS" cadastrados
    E o provedor "ASAAS" esta habilitado para o ecommerce Magazine Siará
    E o ecommerce envia uma chave de idempotencia em toda solicitacao de criacao

  Cenário: Criar invoice com sucesso no Asaas usando cliente ja vinculado
    Dado que existe um cliente Magazine Siará "customer-123" vinculado ao cliente Asaas "cus_asaas_123"
    Quando o ecommerce solicitar a criacao de uma invoice para o pedido "MS-100045" no valor de "159.90" BRL
    E informar o provedor "ASAAS"
    Então o gateway deve registrar a invoice com status "CREATED"
    E deve chamar o endpoint Asaas "POST /v3/payments"
    E deve enviar "customer" com valor "cus_asaas_123"
    E deve enviar "billingType", "value", "dueDate", "description" e "externalReference"
    E o "externalReference" deve conter o identificador do pedido "MS-100045"
    E deve atualizar a invoice para status "OPEN"
    E deve retornar "invoiceId", "provider", "providerPaymentId", "status" e dados de pagamento ao ecommerce

  Cenário: Criar cliente Asaas antes da invoice quando nao houver vinculo
    Dado que nao existe vinculo entre o cliente Magazine Siará "customer-456" e um cliente Asaas
    Quando o ecommerce solicitar a criacao de uma invoice no provedor "ASAAS"
    Então o gateway deve buscar se ja existe cliente Asaas reutilizavel por documento ou "externalReference"
    E, se nao encontrar, deve chamar "POST /v3/customers"
    E deve persistir o identificador retornado pelo Asaas
    E deve usar esse identificador no campo "customer" da cobranca Asaas

  Cenário: Evitar duplicidade em retentativa do ecommerce
    Dado que uma invoice para o pedido "MS-100045" ja foi criada com a chave de idempotencia "MS-100045:create"
    Quando o ecommerce repetir a criacao com a mesma chave de idempotencia
    Então o gateway nao deve chamar novamente o provedor de pagamento
    E deve retornar a mesma invoice criada anteriormente

  Cenário: Rejeitar provedor nao habilitado
    Dado que o provedor "ASAAS" esta desabilitado para o tenant atual
    Quando o ecommerce solicitar criacao de invoice com provedor "ASAAS"
    Então o gateway deve rejeitar a solicitacao com erro de negocio
    E nao deve chamar a API da Asaas
    E deve registrar auditoria da tentativa rejeitada

  Cenário: Falha transiente ao criar cobranca no provedor
    Dado que o gateway registrou a invoice com status "CREATED"
    Quando a Asaas retornar timeout ou erro 5xx ao criar a cobranca
    Então o gateway deve marcar a tentativa como falha transiente
    E deve permitir retry seguro com a mesma chave de idempotencia
    E nao deve informar invoice "OPEN" ao ecommerce sem "providerPaymentId"

  Cenário: Falha de validacao retornada pelo provedor
    Quando a Asaas rejeitar a criacao da cobranca por dados invalidos
    Então o gateway deve marcar a invoice como "FAILED"
    E deve retornar erro claro ao ecommerce sem expor segredo ou payload sensivel
    E deve manter a resposta do provedor disponivel para auditoria interna

