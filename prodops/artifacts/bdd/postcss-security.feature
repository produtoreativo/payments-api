Feature: Resolução da vulnerabilidade HIGH do postcss em validation-workbench

  O workspace validation-workbench depende de vite, que usa postcss como
  dependência transitiva. Versões anteriores de postcss (< 8.5.18) possuem
  Path Traversal via sourceMappingURL (Dependabot alert #101).
  Esta feature garante que a atualização resolve o alerta sem quebrar o build
  e sem afetar a api/.

  Background:
    Given o repositório payments-api com workspaces api/ e validation-workbench/
    And o Dependabot alert #101 em estado "open" apontando para postcss < 8.5.18 em validation-workbench/package-lock.json

  Scenario: Upgrade de vite resolve o alerta do postcss
    Given validation-workbench/package.json declara "vite": "^6.0.5" como dependência direta
    When o vite é atualizado para uma versão que depende de postcss >= 8.5.18
    And npm install é executado em validation-workbench/
    Then validation-workbench/package-lock.json não contém postcss com versão < 8.5.18
    And o Dependabot alert #101 é fechado automaticamente pelo GitHub

  Scenario: Build de validation-workbench permanece verde após o upgrade
    Given postcss foi atualizado para >= 8.5.18 via upgrade do vite
    When "tsc -b && vite build" é executado em validation-workbench/
    Then o build conclui com exit code 0
    And nenhum erro de compilação TypeScript é reportado

  Scenario: api/ não é afetada pela mudança
    Given a atualização foi aplicada exclusivamente em validation-workbench/
    When npm audit é executado em api/
    Then o resultado de api/ é idêntico ao anterior à mudança
    And nenhum arquivo em api/package.json ou api/package-lock.json foi modificado

  Scenario: Override cobre cenário onde upgrade direto do vite não é suficiente
    Given o upgrade do vite não resolve indiretamente o postcss para >= 8.5.18
    When "overrides": { "postcss": ">=8.5.18" } é adicionado em validation-workbench/package.json
    And npm install é executado
    Then validation-workbench/package-lock.json resolve postcss >= 8.5.18
    And o build de validation-workbench/ conclui com exit code 0

  Scenario: Zero alertas HIGH ou critical em validation-workbench após a entrega
    Given o fix foi aplicado e o PR foi mergeado em master
    When o Dependabot re-analisa validation-workbench/package-lock.json
    Then nenhum alerta com severity "high" ou "critical" permanece aberto para validation-workbench/
