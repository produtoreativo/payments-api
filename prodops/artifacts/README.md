# Artifacts

Artefatos vivos do produto — instâncias locais organizadas por tipo de artefato. Definições conceituais estão em `prodops/framework/`. Paths são resolvidos via `prodops/exec/manifest.yaml`.

## Estrutura por tipo

| Diretório | Tipo de artefato | Mutabilidade |
|---|---|---|
| [obcs/](obcs/) | Observable Business Contracts — contratos observáveis comprometidos | Curado |
| [bdd/](bdd/) | BDD Features — especificações de comportamento executáveis | Curado |
| [business-intents/](business-intents/) | Business Intents — intenções de negócio exploratórias | Curado |
| [architecture/](architecture/) | Visão arquitetural operacional — decisões, inventário, integrações | Curado |
| [event-storming/](event-storming/) | Event Storming — modelo de domínio em JSON | Gerado/curado |
| [plans/](plans/) | Planos — iteration plan e reliability plans | Curado |
| [trails/](trails/) | Trilhas históricas — release trail, sessões, sincronização de workspace | Append-only |
| [evidence/](evidence/) | Evidências de entrega | Gerado |
| [experiments/](experiments/) | Experimentos upstream — hipóteses, upstream trail, evidências | Curado + append-only |
| [risks/](risks/) | Riscos e oportunidades | Curado |
| [product/](product/) | Contexto de produto — Product Deck, Service Decks, backlogs | Curado |

## Modelo → Template → Instância

Para cada tipo de artefato existe:

1. **Modelo** — definição do conceito em `prodops/framework/glossary.md`
2. **Template** — estrutura para criação em `prodops/templates/`
3. **Instância** — artefato produzido, armazenado aqui em `prodops/artifacts/`

Trilhas (trails/) podem ser append-only — referências históricas a paths antigos são válidas e não devem ser reescritas.
