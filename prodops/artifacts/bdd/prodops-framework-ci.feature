Feature: ProdOps Framework CI Distribution — DS-56
  Como ProdOps Context Engineer
  Quero que a publicação de uma nova release no prodops-framework dispare automaticamente PRs de sync nos repositórios consumidores
  Para que nenhum produto fique desatualizado sem aviso e sem possibilidade de revisão

  Background:
    Given o repositório prodops-framework tem o workflow "notify-consumers.yml" configurado
    And pelo menos um repositório consumidor tem o workflow "sync-prodops.yml" configurado
    And o arquivo "consumers.yaml" no prodops-framework lista os repositórios consumidores

  Scenario: Nova release dispara sync em todos os consumidores registrados
    Given uma nova tag "v0.3.0" é publicada no prodops-framework
    When o workflow "notify-consumers.yml" é disparado pelo evento de push de tag
    Then o workflow "sync-prodops.yml" é invocado via "workflow_dispatch" em cada repo listado em "consumers.yaml"
    And cada invocação recebe o parâmetro "framework_version: v0.3.0"

  Scenario: sync-prodops.yml abre PR no repositório consumidor
    Given o workflow "sync-prodops.yml" é disparado com "framework_version: v0.3.0"
    When o workflow conclui com sucesso
    Then um PR é aberto no repositório consumidor com título contendo "v0.3.0"
    And o PR não modifica nenhum path listado em ".prodopsignore"
    And nenhum commit é feito diretamente em "main"

  Scenario: Falha em um consumidor não bloqueia os demais
    Given o repositório "repo-a" retorna erro no workflow_dispatch
    When o workflow "notify-consumers.yml" processa a lista de consumidores
    Then o repositório "repo-b" ainda recebe o dispatch
    And o erro de "repo-a" é registrado no log do workflow
    And o workflow termina com status de falha parcial (não exit 0)

  Scenario: Consumidor sem workflow configurado é ignorado com aviso
    Given um repositório em "consumers.yaml" não tem o workflow "sync-prodops.yml"
    When o "notify-consumers.yml" tenta disparar o workflow nesse repositório
    Then o dispatch falha com erro 404
    And o erro é registrado no log
    And os demais repositórios continuam sendo notificados
