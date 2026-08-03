Feature: ProdOps Framework Install — DS-54
  Como Tech Lead de um produto que quer adotar o ProdOps Framework
  Quero executar um script de instalação que inicializa meu repositório com o Framework
  Para que meu produto possa usar as Skills, templates e ferramentas do ProdOps sem configuração manual

  Background:
    Given o repositório prodops-framework tem a versão v0.1.0 publicada com tag
    And o repositório alvo não tem a estrutura "prodops/" inicializada

  Scenario: Instalação bem-sucedida em repositório novo
    Given o script "install-prodops.sh" é executado no repositório alvo com "--version v0.1.0"
    When a instalação conclui sem erros
    Then o diretório "prodops/framework/" existe no repositório alvo
    And o diretório "prodops/skills/" existe no repositório alvo
    And o diretório "prodops/templates/" existe no repositório alvo
    And o arquivo "prodops/exec/manifest.yaml" existe no repositório alvo
    And o arquivo "prodops/exec/framework-lock.yaml" existe com "status: consumer"
    And o arquivo "prodops/exec/framework-lock.yaml" contém a versão "v0.1.0"
    And o arquivo ".prodopsignore" existe no repositório alvo
    And o script "prodops/scripts/doctor.sh" passa com exit 0 no repositório alvo

  Scenario: framework-lock.yaml gerado com campos corretos
    Given a instalação conclui com sucesso
    When o arquivo "prodops/exec/framework-lock.yaml" é lido
    Then o campo "status" é "consumer"
    And o campo "external_source" aponta para o repositório prodops-framework
    And o campo "synchronization_mechanism" é "ci-pr-sync"
    And o campo "distribution.state" é "installed"
    And o campo "drift.status" é "ok"

  Scenario: Instalação não sobrescreve conteúdo existente do produto
    Given o repositório alvo já tem arquivos em "prodops/artifacts/"
    When o script "install-prodops.sh" é executado novamente
    Then os arquivos em "prodops/artifacts/" não são modificados
    And os arquivos em "prodops/skills/local/" não são modificados
    And os arquivos em "prodops/exec/manifest.yaml" não são sobrescritos

  Scenario: Instalação falha se prodops-framework não tem a versão solicitada
    Given a versão "v9.9.9" não existe no repositório prodops-framework
    When o script "install-prodops.sh --version v9.9.9" é executado
    Then o script termina com exit 1
    And a mensagem de erro indica que a versão não foi encontrada
    And nenhum arquivo é criado no repositório alvo
