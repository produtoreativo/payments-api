# Decision Trail — Fronteira Payments SOR e PSP

## Decisão

Em 2026-07-12, a documentação duplicada em `docs/` foi consolidada. O Product Deck passou a declarar Payments como System of Record do domínio de pagamentos, e o Architecture Overview passou a declarar provedores como Asaas como PSPs externos.

Esta consolidação organiza contexto já existente; não aprova novos estados, eventos, SLOs ou comportamentos de runtime. Mudanças desse tipo continuam exigindo Intent, OBC, BDD Feature, riscos e demais pré-condições do fluxo aplicável.

## Contexto

A definição estava apenas em documentos não canônicos sob `docs/prodops/`, divergentes do Product Deck, das BDD Features e do Event Storming canônicos. Manter duas fontes permitia que consumidores adotassem contratos antigos.

## Alternativas consideradas

| Alternativa | Por que descartada |
|---|---|
| Manter `docs/prodops/payments-sor-psp.md` como fonte separada | Criaria uma terceira fonte para produto e arquitetura. |
| Mover todos os documentos de `docs/` sem triagem | Preservaria endpoints obsoletos e BDDs concorrentes. |
| Descartar integralmente a definição SOR/PSP | Perderia uma fronteira de responsabilidade útil e compatível com a arquitetura atual. |

## Impacto em testes

Nenhum teste ou contrato committed foi alterado. Cenários adicionais da BDD alternativa não foram promovidos automaticamente.

## Impacto em observabilidade

O Event Storming canônico foi preservado. Eventos e tags existentes apenas na cópia legada não foram incorporados sem OBC e BDD correspondentes.

## Impacto em confiabilidade

A remoção dos documentos antigos reduz o risco de integração por endpoints divergentes. Regras de timeout, retry, segurança de webhook e proteção de PII continuam sob o Reliability Plan.

## Pendências

- PM e Tech Lead devem revisar a formulação da visão SOR/PSP na próxima revisão do Product Deck.
- Estados ou eventos adicionais devem seguir o fluxo ProdOps antes de entrar em contratos committed.
