# Diligence Infra

Diligence Infra é o agrupamento de infraestrutura do ProdOps Diligence. Representa o trabalho de **bootstrappar e manter sincronizada a infraestrutura do GitHub** a partir das definições canônicas do framework.

```
Diligence Infra: Workspace → Provision → Verify
```

## Propósito

Diligence Infra produz:
- Labels canônicas presentes e corretamente configuradas no repositório
- GitHub Project com custom fields e views alinhados à especificação
- Divergências entre spec canônica e estado real do GitHub identificadas e corrigidas

## Quando executar

- Bootstrap de um novo repositório
- Após mudanças na especificação canônica (`prodops/framework/github-workspace.md`)
- Quando o Scan detecta Issues sem labels canônicas (sinal de que a infraestrutura está incompleta)
- Periodicamente, como parte do ciclo `diligence-async` quando há suspeita de drift

## Estágios

### Workspace

Lê a especificação canônica em `prodops/framework/github-workspace.md` e compara com o estado atual do repositório GitHub. Produz um diff: o que existe, o que falta, o que está divergente.

Saída: lista de gaps entre spec e estado real — labels ausentes, labels com cor/descrição errada, custom fields ausentes no Project, views não configuradas.

→ [steps/workspace/SKILL.md](../../skills/diligence/steps/workspace/SKILL.md)

### Provision

Executa as criações e atualizações identificadas pelo Workspace. Cria labels ausentes, corrige labels com configuração divergente, adiciona custom fields ao GitHub Project, configura views.

Nunca remove labels ou views sem confirmação explícita — remoção pode afetar Issues existentes.

→ [steps/provision/SKILL.md](../../skills/diligence/steps/provision/SKILL.md)

### Verify

Confirma que o estado do repositório GitHub corresponde à especificação canônica após o Provision. Produz relatório de conformidade.

→ [steps/verify/SKILL.md](../../skills/diligence/steps/verify/SKILL.md)

## Capabilities utilizadas

| Capability | Estágio |
|---|---|
| [Divergence Detection](capabilities/README.md) | Workspace |
| [Artifact Evolution](capabilities/README.md) | Provision |
