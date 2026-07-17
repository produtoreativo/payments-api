# Global OBC - <Nome da Intenção de Negócio>

<!-- ATENÇÃO: Este template é para uso no repositório de PORTFÓLIO da plataforma, não neste repositório de produto. -->
<!-- Global OBCs pertencem ao nível de plataforma. Repositórios de produto contêm apenas Local OBCs. -->
<!-- Renomeie este arquivo para o slug da intenção: ex. split-payment.md -->
<!-- Definição completa do formato: prodops/framework/obc.md -->
<!-- Owner: Portfolio PM -->

## Status

<!-- Declare o estado atual do contrato.
     Estados possíveis: Draft | Refining | Operational | Archived
     O Global OBC vai de Draft → Refining (durante Discovery no BIB) → Operational (quando todos os Local OBCs derivados estão em produção) -->

Draft.

## Objetivo de Negócio

<!-- Descreva o objetivo estratégico que esta intenção busca alcançar.
     Responda: qual resultado de negócio queremos gerar, para quem, e por quê agora.
     Foque no objetivo — não na solução técnica. -->

<Objetivo estratégico em uma ou duas frases.>

## Valor de Negócio

<!-- Descreva o valor esperado: impacto em receita, retenção, compliance, eficiência, etc.
     Inclua métricas de sucesso esperadas quando conhecidas. -->

<Valor esperado e métricas de sucesso.>

## Stakeholders

<!-- Liste os stakeholders envolvidos: quem patrocina, quem será impactado, quem aprova. -->

| Stakeholder | Papel | Responsabilidade |
|---|---|---|
| <Nome / Papel> | <Patrocinador / Aprovador / Impactado> | <O que decide ou recebe> |

## Regras de Negócio

<!-- Liste as regras de negócio que esta intenção deve respeitar.
     Estas são restrições ou invariantes do domínio — não regras técnicas. -->

- <Regra de negócio 1>
- <Regra de negócio 2>

## Eventos de Negócio

<!-- Liste os eventos de negócio que esta intenção gera ou depende.
     Nível estratégico — não técnico. O que acontece no mundo real? -->

| Evento | Significado | Quando ocorre |
|---|---|---|
| `<nome-do-evento>` | <O que este evento representa no negócio.> | <Condição de disparo.> |

## KPIs / Resultados Esperados

<!-- Defina os indicadores-chave de desempenho e os resultados quantitativos esperados.
     Estes KPIs orientam a definição dos SLIs nos Local OBCs derivados. -->

| KPI | Baseline atual | Meta | Prazo |
|---|---|---|---|
| <Nome do KPI> | <Valor atual> | <Meta esperada> | <Prazo> |

## Value Stream

<!-- Descreva o fluxo de valor: como esta intenção se encaixa no processo de negócio maior.
     Identifique os principais touchpoints: usuário → sistema → resultado. -->

<Descrição do fluxo de valor em linguagem de negócio.>

## Produtos Envolvidos

<!-- Liste os produtos (repositórios) que participarão da entrega desta intenção.
     Esta lista será usada no OBC Partitioning para criar os Local OBCs. -->

| Produto / Repositório | Responsabilidade esperada |
|---|---|
| <nome-do-repositório> | <O que este produto entrega para esta intenção.> |

## Rastreabilidade de Local OBCs

<!-- Preenchido durante o OBC Partitioning.
     Para cada produto envolvido, registre o Local OBC correspondente. -->

| Produto | Local OBC | Estado | Última atualização |
|---|---|---|---|
| <nome-do-repositório> | `prodops/artifacts/business/obcs/<slug>.md` | Draft | <data> |

## Notas de Discovery

<!-- Registre aqui os aprendizados do Discovery no BIB.
     Hipóteses levantadas, experimentos realizados, decisões tomadas.
     Atualizado continuamente durante Discovery e depois via Refinamento Contínuo do OBC. -->

### Hipóteses

- <Hipótese 1 — validada / refutada / em investigação>

### Experimentos

- <Experimento: link para prodops/journeys/discovery/experiments/<NNN-slug>/>

### Decisões

- <Decisão tomada e justificativa>
