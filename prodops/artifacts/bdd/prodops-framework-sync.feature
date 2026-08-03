Feature: ProdOps Framework Sync — DS-55
  Como Tech Lead de um produto que usa o ProdOps Framework
  Quero executar um script de sync que atualiza o Framework instalado para uma nova versão
  Para que meu produto se beneficie de evoluções do Framework sem perder artefatos locais

  Background:
    Given o repositório produto tem o Framework instalado com "status: consumer"
    And o arquivo "prodops/exec/framework-lock.yaml" existe com uma versão instalada
    And o arquivo ".prodopsignore" existe declarando os paths protegidos do produto

  Scenario: Sync bem-sucedido abre PR com diff revisável
    Given existe uma nova versão "v0.2.0" disponível no prodops-framework
    When o script "sync-from-framework.sh --version v0.2.0" é executado
    Then o script cria uma branch "update/prodops-framework-v0.2.0"
    And um PR é aberto no repositório produto com o diff do conteúdo do framework
    And nenhum commit é feito diretamente em "main"
    And o PR não modifica nenhum path listado em ".prodopsignore"
    And o "prodops/scripts/doctor.sh" passa com exit 0 antes e depois da cópia

  Scenario: Sync atualiza framework-lock.yaml após aprovação do PR
    Given o PR de sync foi aprovado e mergeado
    When o "prodops/exec/framework-lock.yaml" é lido
    Then o campo "version" é "v0.2.0"
    And o campo "drift.status" é "ok"

  Scenario: Sync não sobrescreve artefatos do produto
    Given o produto tem arquivos em "prodops/artifacts/", "prodops/skills/local/", "prodops/exec/"
    When o script "sync-from-framework.sh" é executado
    Then nenhum arquivo em "prodops/artifacts/" é modificado
    And nenhum arquivo em "prodops/skills/local/" é modificado
    And nenhum arquivo em "prodops/exec/manifest.yaml" é modificado
    And nenhum arquivo em "prodops/exec/framework-lock.yaml" é sobrescrito pelo conteúdo do framework

  Scenario: --check detecta drift sem modificar o repositório
    Given existe uma nova versão disponível no prodops-framework
    When o script "sync-from-framework.sh --check" é executado
    Then o script termina com exit 1
    And a saída indica quais arquivos divergem
    And nenhum arquivo é modificado no repositório produto
    And nenhum PR é aberto

  Scenario: Sync com --dry-run mostra o que seria feito sem executar
    When o script "sync-from-framework.sh --dry-run" é executado
    Then a saída lista os arquivos que seriam atualizados
    And nenhum arquivo é modificado
    And nenhum PR é aberto
