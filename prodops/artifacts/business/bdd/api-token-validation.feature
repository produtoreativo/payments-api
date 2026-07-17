# language: pt
Funcionalidade: Validação de acesso à Payments API por token
  Como Magazine Siará
  Quero garantir que apenas sistemas autorizados consumam a Payments API
  Para proteger a jornada de pagamento de acessos não autorizados e manter rastreabilidade por tenant

  Contexto:
    Dado que a Payments API exige autenticação por token em todas as rotas de negócio
    E tokens são identificados pelo header "X-Api-Token"
    E cada token está associado a um tenant e possui um identificador observável

  Cenário: Requisição autenticada com token válido
    Dado que o sistema cliente possui um token de API válido para o tenant "magazine-siara"
    Quando o cliente enviar "POST /invoices" com o header "X-Api-Token" preenchido
    Então a Payments API deve autorizar a requisição
    E deve registrar o evento "api.token.validated" com "tenantId", "tokenId" e "correlationId"

  Cenário: Requisição sem token é rejeitada
    Quando o cliente enviar "POST /invoices" sem o header "X-Api-Token"
    Então a Payments API deve retornar HTTP 401
    E deve registrar o evento "api.token.rejected" com "reason" igual a "token_missing"
    E não deve expor o valor de nenhum token na resposta ou nos logs

  Cenário: Requisição com token inválido é rejeitada
    Quando o cliente enviar "POST /invoices" com "X-Api-Token" contendo um valor não cadastrado
    Então a Payments API deve retornar HTTP 401
    E deve registrar o evento "api.token.rejected" com "reason" igual a "token_invalid"
    E não deve revelar se o token quase corresponde a algum cadastrado

  Cenário: Token revogado é rejeitado
    Dado que o token "tok_revogado" foi revogado para o tenant "magazine-siara"
    Quando o cliente enviar uma requisição com "X-Api-Token" igual a "tok_revogado"
    Então a Payments API deve retornar HTTP 401
    E deve registrar o evento "api.token.rejected" com "reason" igual a "token_revoked"

  Cenário: Validação local com token de desenvolvimento
    Dado que o ambiente é "development"
    E a variável "API_TOKEN_LOCAL" está configurada com um valor conhecido
    Quando o cliente local enviar uma requisição com o valor de "API_TOKEN_LOCAL" no header "X-Api-Token"
    Então a Payments API deve autorizar a requisição como tenant "local"
    E deve registrar o evento "api.token.validated" com "tokenId" igual a "local-dev"

  Cenário: Rota de webhook do provedor não exige token de API
    Dado que o webhook da Asaas usa autenticação própria por "asaas-access-token"
    Quando a Asaas enviar evento para "POST /webhooks/asaas"
    Então a Payments API não deve exigir o header "X-Api-Token"
    E deve aplicar a validação de "asaas-access-token" normalmente

  Cenário: Token não aparece em logs ou respostas de erro
    Dado que um token inválido é enviado na requisição
    Quando a Payments API rejeitar a requisição com HTTP 401
    Então o valor raw do token não deve aparecer no body da resposta
    E não deve aparecer em nenhum nível de log da aplicação
    E o evento "api.token.rejected" deve registrar apenas "tokenId" quando disponível
