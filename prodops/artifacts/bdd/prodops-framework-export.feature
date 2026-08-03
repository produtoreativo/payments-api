Feature: ProdOps Framework Export — DS-53
  Como ProdOps Context Engineer
  Quero extrair o conteúdo canônico do ProdOps Framework de payments-api para o repositório prodops-framework
  Para que o framework tenha uma fonte canônica independente do produto

  Background:
    Given o arquivo "prodops/exec/export-manifest.yaml" existe e é válido
    And o script "prodops/scripts/validate-export-manifest.sh" passa com exit 0
    And o script "prodops/scripts/doctor.sh" passa com exit 0 no repositório de origem

  Scenario: Export bem-sucedido gera PR no prodops-framework
    Given o script "prodops/scripts/export-framework.sh" é executado
    When o export conclui sem erros
    Then um PR é aberto no repositório prodops-framework
    And o PR contém apenas os paths declarados em "export-manifest.yaml" seção include
    And o PR não contém nenhum path declarado em "export-manifest.yaml" seção exclude
    And o "prodops/scripts/doctor.sh" passa com exit 0 no repositório de destino

  Scenario: Export não inclui artefatos do produto
    Given o script "prodops/scripts/export-framework.sh" é executado
    When o export conclui
    Then o PR não contém nenhum arquivo de "prodops/artifacts/"
    And o PR não contém nenhum arquivo de "prodops/exec/"
    And o PR não contém nenhum arquivo de "prodops/skills/local/"
    And o PR não contém nenhum arquivo de "prodops/scripts/local/"

  Scenario: Export falha se validate-export-manifest não passa
    Given o arquivo "prodops/exec/export-manifest.yaml" está inválido ou incompleto
    When o script "prodops/scripts/export-framework.sh" é executado
    Then o script termina com exit 1
    And nenhum PR é aberto
    And a mensagem de erro indica qual validação falhou

  Scenario: Versão v0.1.0 publicada com tag e LICENSE
    Given o export foi aplicado e o PR aprovado no prodops-framework
    When a versão v0.1.0 é publicada
    Then existe uma tag "v0.1.0" no repositório prodops-framework
    And existe um arquivo "LICENSE" no repositório prodops-framework
    And existe um arquivo "CHANGELOG.md" no repositório prodops-framework
