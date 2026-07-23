# OBCs

Este diretório contém os **Local OBCs** committed deste repositório de produto. É a fonte canônica dos contratos observáveis usados no Downstream.

**Todos os OBCs aqui são Local OBCs** — por definição, um repositório de produto contém apenas contratos de implementação de produto. Global OBCs pertencem ao repositório de portfólio da plataforma.

## Regras

- Todo Local OBC committed deve ter arquivo próprio neste diretório: `prodops/artifacts/obcs/<slug>.md`
- OBCs exploratórios (Draft/Refining) permanecem no diretório do experimento: `prodops/artifacts/experiments/<NNN-slug>/obcs/`
- Cada Local OBC deve referenciar o Global OBC correspondente (ou indicar "Local — fluxo direto" se não houver)
- Product Decks, BDD Features, Reliability Plans e demais artefatos referenciam o OBC, sem duplicar sua definição

## Estados

| Estado | Significado | Localização |
|---|---|---|
| Draft | Recém-criado, sem refinamento | Experiment dir |
| Refining | Em Discovery/Exploration ativo | Experiment dir |
| Committed | Pronto para Delivery, aprovado | `prodops/artifacts/obcs/<slug>.md` |
| In Delivery | Em execução no Iteration Plan | `prodops/artifacts/obcs/<slug>.md` |
| Operational | Em produção com evidências | `prodops/artifacts/obcs/<slug>.md` |
| Archived | Encerrado | Mantido aqui para rastreabilidade |

## Referências

→ **Definição completa do OBC (o que é, composição, estados, ciclo de vida):** [`prodops/framework/obc.md`](../../framework/obc.md)
→ **Template para Local OBC:** [`prodops/templates/obcs/local-obc.md`](../../templates/obcs/local-obc.md)
→ **Template para Global OBC** *(uso no repositório de portfólio):* [`prodops/templates/obcs/global-obc.md`](../../templates/obcs/global-obc.md)
