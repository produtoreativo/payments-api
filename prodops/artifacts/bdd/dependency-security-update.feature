# language: pt
Funcionalidade: Atualização de dependências npm com vulnerabilidades de segurança
  Como operador da Payments API
  Quero eliminar as vulnerabilidades de segurança identificadas pelo Dependabot
  Para que a API opere sem dependências com CVEs conhecidos em severity high ou critical

  Contexto:
    Dado que o repositório possui 27 alertas Dependabot abertos (14 high, 11 medium, 2 low)
    E a dependência direta afetada é "axios" na versão "^1.13.2"
    E as dependências transitivas afetadas incluem "js-yaml", "multer", "fast-uri", "brace-expansion", "qs", "postcss", "body-parser" e "@babel/core"

  Cenário: Dependência direta axios atualizada sem regressão
    Dado que "axios" está em "^1.13.2" com 13 alertas de segurança associados
    Quando a versão de "axios" for atualizada para ">=1.18.0" no "package.json"
    E o comando "npm install" for executado com o lockfile atualizado
    Então o build de produção deve concluir sem erros
    E o test suite completo deve passar sem falhas
    E os alertas Dependabot de "axios" devem estar fechados no GitHub

  Cenário: Dependências transitivas resolvidas via npm audit
    Dado que dependências transitivas possuem vulnerabilidades sem alteração direta no "package.json"
    Quando "npm audit fix" for executado para dependências transitivas sem breaking change
    Então nenhuma dependência transitiva com severity "high" deve permanecer com estado "open"
    E o test suite completo deve passar sem falhas após a resolução

  Cenário: Upgrade de major version com breaking change requer decisão registrada
    Dado que "multer" possui vulnerabilidade com patched version "2.2.0" (upgrade de major 1.x → 2.x)
    Quando a atualização de "multer" exigir avaliação de breaking changes
    E for identificada incompatibilidade real com o código existente
    Então a decisão de aceite de risco ou plano de adequação deve ser registrada em "prodops/artifacts/risks/risks.md"
    E o alerta não deve ser silenciado sem registro formal

  Cenário: Nenhum contrato de API alterado após atualização
    Dado que as dependências foram atualizadas
    Quando todos os cenários BDD existentes forem executados
    Então todos os cenários devem passar sem modificação de implementação
    E nenhum endpoint deve ter alteração de payload, status code ou comportamento observável

  Cenário: Confirmação final — zero alertas high/critical abertos
    Dado que todas as atualizações foram aplicadas e commitadas
    Quando o GitHub Dependabot reprocessar os alertas
    Então o número de alertas com severity "critical" em estado "open" deve ser 0
    E o número de alertas com severity "high" em estado "open" deve ser 0
