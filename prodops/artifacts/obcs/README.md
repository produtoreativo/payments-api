# OBCs

Este diretório contém os OBCs committed e é a fonte canônica dos contratos observáveis usados no Downstream.

## Dois tipos de OBC

O modelo OBC possui dois níveis:

| Tipo | Descrição | Subdiretório |
|---|---|---|
| **Global OBC** | Contrato estratégico de negócio. Pertence ao BIB/Portfolio. Cobre toda a intenção de negócio. | `global/` |
| **Local OBC** | Contrato de implementação de produto. Pertence a um PIB. Especializa/particiona o Global OBC. | `local/` |

**Relação:** 1 Global OBC → N Local OBCs (via OBC Partitioning)

## Regras

- Todo OBC committed deve ter arquivo próprio no subdiretório correspondente.
- Product Decks, Service Decks, BDD Features, Reliability Plans e demais artefatos devem referenciar o OBC correspondente, sem duplicar sua definição.
- Local OBCs **nunca duplicam** conteúdo estratégico do Global OBC — apenas especializam a responsabilidade do produto.
- OBCs exploratórios (Draft/Refining) permanecem no diretório do experimento em `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` até a promoção formal.

## Estados

| Estado | Significado | Onde vive |
|---|---|---|
| Draft | Recém-criado, sem refinamento | Experiment dir ou diretório local |
| Refining | Em Discovery/Exploration ativo | Experiment dir |
| Committed | Pronto para Delivery, aprovado | `obcs/local/<slug>.md` |
| Implemented | Em Delivery ou recém entregue | `obcs/local/<slug>.md` |
| Operational | Em produção com evidências | `obcs/local/<slug>.md` ou `obcs/global/<slug>.md` |
| Archived | Encerrado | Mantido no subdiretório para rastreabilidade |

## Referências

→ **Definição completa do OBC (o que é, composição, estados, ciclo de vida):** [`prodops/framework/obc.md`](../framework/obc.md)
→ **Template para Global OBC:** [`prodops/templates/obcs/global-obc.md`](../templates/obcs/global-obc.md)
→ **Template para Local OBC:** [`prodops/templates/obcs/local-obc.md`](../templates/obcs/local-obc.md)
