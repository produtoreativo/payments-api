# Bootstrap

Bootstrap é a fase de preparação do ambiente para uma execução ProdOps.

## Responsabilidade

Bootstrap instala dependências, prepara serviços locais, verifica requisitos de configuração e executa o smoke gate. Não avalia readiness de produto e não inicia o Git flow.

```text
Preparar ferramentas → instalar dependências → preparar infraestrutura local
→ verificar configuração → smoke gate → ambiente pronto
```

## Limites

- Não lê nem altera código de produção.
- Não lê ou executa testes de comportamento.
- Não exige, lê ou cria OBC, BDD Feature, riscos, Reliability Plan ou Iteration Plan.
- Não cria, troca, sincroniza ou remove branches.
- Não gera context capsule.

O gate de readiness é responsabilidade do `/downstream`. Branch, base e demais decisões de Git flow são responsabilidade do `/hack start`.

## Entrada

- Scripts de setup e manifests de pacotes do repositório.
- Arquivos de exemplo com nomes de variáveis, nunca valores secretos.
- Infraestrutura local requerida.
- Gate `smoke` definido em `prodops/exec/manifest.yaml`.

## Saída

- Dependências instaladas.
- Serviços locais disponíveis.
- Requisitos de configuração identificados sem exposição de segredos.
- Smoke gate verde ou bloqueio de ambiente explícito.

## Procedimento executável

→ [`prodops/skills/bootstrap/SKILL.md`](../../../../skills/bootstrap/SKILL.md)

## Próxima fase

Após o readiness Downstream, `/hack start` estabelece o Git flow e inicia o Hack.
