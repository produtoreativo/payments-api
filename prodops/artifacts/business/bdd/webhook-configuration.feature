# language: pt
Funcionalidade: Configuração de webhook associado ao token de API
  Como ecommerce Magazine Siará
  Quero registrar uma URL de webhook no meu token de API
  Para receber notificações automáticas de mudança de status de pagamento sem polling

  Contexto:
    Dado que o ecommerce possui um token de API válido para o tenant "magazine-siara"
    E todas as requisições de webhook incluem o header "X-Api-Token" com o token válido

  Cenário: Registrar um webhook para receber confirmações de pagamento
    Quando o ecommerce enviar "POST /webhooks" com "url" igual a "https://checkout.magazinesiara.com.br/payments/notify"
    E incluir "events" com valor "["invoice.confirmed"]"
    Então a Payments API deve retornar HTTP 201
    E deve retornar "webhookId" e "secret" no corpo da resposta
    E "secret" nunca deve aparecer novamente em listagens, logs ou eventos
    E deve registrar o evento "webhook.registered"

  Cenário: Registrar webhook com múltiplos eventos
    Quando o ecommerce enviar "POST /webhooks" com eventos "["invoice.confirmed", "invoice.cancelled"]"
    Então a Payments API deve retornar HTTP 201
    E deve armazenar os dois eventos associados ao webhook

  Cenário: Listar webhooks do token autenticado
    Dado que o token "magazine-siara" possui dois webhooks registrados
    Quando o ecommerce enviar "GET /webhooks"
    Então a Payments API deve retornar a lista de webhooks do token
    E nenhum item da lista deve conter o campo "secret"

  Cenário: Remover webhook registrado
    Dado que o token "magazine-siara" possui um webhook "wh_001" registrado
    Quando o ecommerce enviar "DELETE /webhooks/wh_001"
    Então a Payments API deve retornar HTTP 200
    E deve registrar o evento "webhook.deleted"
    E o webhook não deve mais aparecer em listagens

  Cenário: Rejeitar URL sem HTTPS em ambiente não-local
    Quando o ecommerce tentar registrar webhook com "url" igual a "http://checkout.magazinesiara.com.br/notify"
    Então a Payments API deve retornar HTTP 422
    E deve retornar mensagem informando que a URL deve usar HTTPS

  Cenário: Aceitar URL localhost em qualquer ambiente
    Quando o ecommerce tentar registrar webhook com "url" igual a "http://localhost:3000/webhook"
    Então a Payments API deve retornar HTTP 201
    E deve armazenar o webhook normalmente

  Cenário: Rejeitar registro quando token já possui 10 webhooks
    Dado que o token "magazine-siara" já possui 10 webhooks ativos registrados
    Quando o ecommerce tentar registrar um novo webhook
    Então a Payments API deve retornar HTTP 422
    E deve informar que o limite de webhooks por token foi atingido

  Cenário: Entregar evento ao webhook quando pagamento é confirmado
    Dado que o tenant "magazine-siara" possui webhook ativo para "invoice.confirmed"
    Quando a Payments API processar uma confirmação de pagamento via webhook do provedor
    Então a Payments API deve enviar HTTP POST para a URL do webhook
    E o body deve conter "deliveryId", "webhookId", "event" igual a "invoice.confirmed" e "payload" com dados da invoice
    E o header "X-Payments-Signature" deve conter "sha256=" seguido do HMAC-SHA256 do body com o secret do webhook
    E deve registrar o evento "webhook.delivery.sent" ou "webhook.delivery.failed"
    E a confirmação de pagamento não deve ser bloqueada por falha na entrega

  Cenário: Registrar falha de entrega sem bloquear o fluxo de pagamento
    Dado que o webhook configurado retorna HTTP 500 ou timeout
    Quando a Payments API tentar entregar o evento "invoice.confirmed"
    Então a Payments API deve registrar o evento "webhook.delivery.failed" com "statusCode" e "reason"
    E a invoice deve continuar com status "CONFIRMED"
    E o evento "payment.confirmed" deve ter sido publicado normalmente

  Cenário: Não entregar evento para webhook inativo
    Dado que o webhook "wh_001" foi removido
    Quando a Payments API processar uma confirmação de pagamento
    Então a Payments API não deve tentar entregar evento para a URL do webhook "wh_001"

  Cenário: Não expor secret em log ou resposta de listagem
    Dado que um webhook foi registrado com secret gerado pelo sistema
    Quando qualquer operação de listagem ou busca for executada
    Então o campo "secret" não deve aparecer no corpo da resposta
    E não deve aparecer em nenhum nível de log da aplicação
