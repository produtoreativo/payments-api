# Iteration Plan - Payments Release

> **Propósito:** Registro da execução de Delivery desta iteração. Contém os itens escolhidos do Iteration Backlog, a estratégia de execução, o acompanhamento das jornadas CI Sync e CI Async, as evidências produzidas e os critérios de saída.
>
> Este documento não é um backlog de planejamento ou priorização. Planejamento acontece no Iteration Backlog; priorização é responsabilidade do Product Owner.
>
> → [Hierarquia de backlogs](../../framework/backlogs.md)
> → [Iteration Backlog](../product/backlogs/iteration-backlog.md) — itens prontos para desenvolvimento

## Executive Summary

A próxima iteração deve priorizar o menor conjunto de funcionalidades capaz de colocar a nova jornada de pagamento em condição de gerar valor para o Checkout sem ampliar excessivamente o risco da Release.

O escopo recomendado é concentrar a Release em três resultados de negócio: criar invoice Pix, confirmar pagamento e informar status de pagamento ao cliente. Boleto deve ser dividido para não competir com a estabilização da jornada Pix. Cancelamento de invoice deve ficar fora do compromisso principal desta iteração, apesar de já existir no código, porque não é essencial para validar a ativação do novo gateway no Checkout.

A decisão principal é reduzir o lote: entregar uma jornada menor, completa e compreensível para o cliente e para o negócio, em vez de incluir todos os meios e capacidades de pagamento ao mesmo tempo.

## Objetivos da Release

- Habilitar o Checkout a consumir o novo gateway de Payments em uma jornada de pagamento controlada.
- Reduzir o acoplamento do Ecommerce com o monolito e com integrações diretas de provedor.
- Validar o novo domínio Payments como responsável por criação e confirmação de pagamento.
- Garantir que o cliente receba uma informação confiável sobre o status do pagamento.
- Reduzir a probabilidade de falha da Release ao limitar o escopo ao fluxo de maior valor imediato.

## Riscos que influenciaram o escopo

| Risco | Impacto no negócio | Probabilidade | Influência sobre o escopo |
| --- | --- | --- | --- |
| Novo gateway ainda desabilitado por Feature Flag devido a bug localizado. | Muito alto: impede ativação da Release e, segundo `prodops/artifacts/risks/risks.md`, existe risco contratual relevante. | Alta | Reduzir escopo para a jornada mais importante, evitando incluir funcionalidades paralelas que desviem foco da ativação. |
| Notification Service já teve incidentes que afetaram confirmação ao cliente. | Alto: cliente pode pagar e não receber informação confiável. | Alta | Manter notificação de status dentro da Release, mas apenas como parte da jornada principal, não como plataforma completa de comunicação. |
| Desacoplamento do monolito aumenta complexidade entre times e serviços. | Alto: falhas de integração podem impedir a experiência ponta a ponta. | Alta | Preferir uma jornada completa menor em vez de múltiplas jornadas incompletas. |
| Pix e Boleto possuem regras e expectativas diferentes. | Médio/alto: tratar ambos como variação simples pode aumentar erro de negócio. | Média | Dividir Boleto e não comprometer a Release principal com todas as variações do meio de pagamento. |
| Confirmação de pagamento é ponto crítico para liberação e comunicação ao cliente. | Muito alto: pagamento confirmado sem reflexo no Ecommerce gera perda de confiança e chamados. | Alta | Confirmação entra como parte obrigatória da iteração. |
| Cancelamento concorre com estados de pagamento e fluxo de estorno. | Médio: importante para operação, mas menos central para validar a ativação inicial do Checkout. | Média | Adiar cancelamento como compromisso de Release, mantendo fora do menor escopo de valor. |
| Divergência entre documentos e código. | Médio: pode gerar alinhamento incorreto sobre o que será entregue. | Alta | Escopo deve ser descrito por capacidades de negócio, não por detalhes de endpoints ou desenho técnico. |

## Oportunidades consideradas

| Oportunidade | Impacto | Urgência | Relevância para esta iteração | Influência sobre o escopo |
| --- | --- | --- | --- | --- |
| Validar Payments como domínio autônomo do Ecommerce. | Alto | Alta | Alta | Prioriza funcionalidades que provem o ciclo de pagamento fim a fim, não apenas endpoints isolados. |
| Criar visibilidade de negócio sobre jornada de pagamento. | Alto | Alta | Média | Reforça a escolha por uma jornada menor e mensurável pelo negócio, sem ampliar o escopo funcional. |
| Reduzir dependência direta de provedor. | Alto | Alta | Alta | Prioriza criação e confirmação via gateway Payments. |
| Aumentar confiança do cliente na confirmação de pagamento. | Alto | Alta | Alta | Mantém notificação de status dentro do escopo principal. |
| Acelerar meios adicionais de pagamento. | Médio/alto | Média | Média | Justifica preparar Boleto, mas não incluir a jornada completa se isso reduzir previsibilidade. |
| Integrar Payments ao modelo corporativo de incidentes. | Médio | Média | Baixa para decisão de escopo | Não altera as funcionalidades da iteração; deve ser tratado em artefato próprio de confiabilidade. |

## Iteration Backlog identificado

| Feature | Valor esperado | Dependências | Estado atual |
| --- | --- | --- | --- |
| Criar invoice via Pix | Permite ao Checkout iniciar a jornada de pagamento de maior prioridade para a Release. | Checkout, Payments, provedor Asaas, Feature Flag. | OBC em `prodops/artifacts/obcs/create-invoice.md`. BDD Feature em `prodops/artifacts/bdd/create-invoice.feature`. Parcialmente implementada no código. |
| Criar invoice via Cartão de Crédito (Hosted) | Amplia meios de pagamento com cartão hospedado, sem exposição PCI no backend. | Checkout, Payments, provedor Asaas, webhook de confirmação. | OBC em `prodops/artifacts/obcs/credit-card-authorization-confirmation.md`. BDD Feature em `prodops/artifacts/bdd/credit-card-payment.feature`. Aprovado em 2026-07-07 (EXP-003 + EXP-001 hosted slice). Pronto para Bootstrap + Hack. |
| Criar invoice via Boleto | Amplia meios de pagamento atendidos pelo novo gateway. | Checkout, Payments, regras de Boleto, provedor Asaas, notificação. | OBC criado em `prodops/artifacts/obcs/create-invoice-boleto.md`. BDD Feature criada em `prodops/artifacts/bdd/create-invoice-boleto.feature`. Riscos documentados em `risks.md`. Pronta para entrar no fluxo Downstream. |
| Confirmação de pagamento | Permite ao Ecommerce reconhecer pagamento aprovado e seguir a jornada do cliente. | Payments, webhook do provedor, Ecommerce/Orders, Notification Service. | OBC em `prodops/artifacts/obcs/payment-confirmation.md`. BDD Feature em `prodops/artifacts/bdd/payment-confirmation.feature`. Implementada no código para eventos principais. |
| Notificação de status de pagamento | Fecha o ciclo de comunicação com o cliente e reduz incerteza pós-pagamento. | Ecommerce, Notification Service, Payments. | Sem OBC nem BDD Feature neste repositório — depende de implementação no Notification Service e Ecommerce. Retornou para Upstream. |
| Cancelar invoice pendente | Evita que cobranças indevidas continuem ativas. | Payments, provedor Asaas, regras de estado da invoice. | OBC em `prodops/artifacts/obcs/cancel-invoice.md`. BDD Feature em `prodops/artifacts/bdd/cancel-invoice.feature`. Implementada no código. |
| Habilitar novo gateway para o Checkout | Permite que a Release gere valor real em produção. | Checkout, Feature Flag, Payments. | Sem OBC nem BDD Feature — depende de Feature Flag e integração no repositório do Checkout. Retornou para Upstream. |
| Validação de acesso por token de API | Garante que apenas sistemas autorizados consumam a Payments API, com rastreabilidade por tenant e chave local para desenvolvimento. | Payments API, variáveis de ambiente, time de Checkout e integrações. | Implementado. OBC em `prodops/artifacts/obcs/`. BDD em `prodops/artifacts/bdd/`. |
| Configuração de webhook por token de API | Permite que consumidores recebam notificações automáticas de mudança de status de pagamento sem polling. | Payments API, token de API, DynamoDB WebhooksTable. | Novo item; OBC e BDD criados. |
| Observabilidade com Datadog em produção | Diagnóstico de falhas de pagamento por correlationId sem acesso manual ao CloudWatch — reduz MTTR de incidentes. | Payments API, Lambda Extension Layer Datadog, PRODUCTION_DATADOG_API_KEY no GitHub. | OBC em `prodops/artifacts/obcs/observability-datadog.md`. BDD em `prodops/artifacts/bdd/observability-datadog.feature`. EXP-010 concluído. |
| Persistência DynamoDB otimizada para produção | Elimina risco de throttling em produção e habilita recuperação de dados de pagamento em até 35 dias. | DynamoDB produção, stack `payments-api-dynamo-production`, CloudFormation. | OBC em `prodops/artifacts/obcs/dynamodb-optimization.md`. BDD em `prodops/artifacts/bdd/dynamodb-optimization.feature`. EXP-011 concluído. |
| Pipeline de CI/CD para produção com gate de aprovação | Garante que nenhum deploy em produção aconteça sem aprovação humana rastreável — elimina deploys manuais não auditados. | GitHub Environment `production`, Required Reviewers, PRODUCTION_* secrets, role OIDC. | OBC em `prodops/artifacts/obcs/production-cicd-pipeline.md`. BDD em `prodops/artifacts/bdd/production-cicd-pipeline.feature`. EXP-012 concluído. |

## Iteration Plan recomendado

| Feature | Decisão | Justificativa | Valor entregue |
| --- | --- | --- | --- |
| Habilitar novo gateway para o Checkout na jornada priorizada | Upstream | Não possui OBC nem BDD Feature neste repositório. A habilitação depende de Feature Flag e integração no repositório do Checkout — escopo fora do domínio da Payments API. Retornou para Upstream para documentação como dependência externa no Reliability Plan. | — |
| Criar invoice via Cartão de Crédito (Hosted) | Entrou | EXP-003 + EXP-001 (hosted slice) validaram a abordagem. OBC e BDD Feature existem. Aprovado em 2026-07-07 — pronto para Bootstrap + Hack. | Checkout passa a oferecer cartão hospedado como meio de pagamento via gateway Payments, sem exposição PCI no backend. |
| Criar invoice via Pix | Entrou | Pix é a melhor fatia para validar o novo gateway: tem alto valor para Checkout, está presente no Service Deck e já possui base de implementação. OBC em `prodops/artifacts/obcs/create-invoice.md`. | Cliente consegue iniciar pagamento Pix pelo novo domínio Payments. |
| Confirmação de pagamento | Entrou | Sem confirmação, a invoice criada não fecha a jornada de negócio. Essa funcionalidade reduz o principal risco de cliente pagar sem continuidade clara. OBC em `prodops/artifacts/obcs/payment-confirmation.md`. | Ecommerce recebe sinal confiável de pagamento aprovado. |

| Notificação de status de pagamento | Upstream | Sem OBC nem BDD Feature neste repositório. Implementação pertence ao Notification Service e Ecommerce — dependência externa. Retornou para Upstream para registro no Reliability Plan como risco de integração. | — |
| Criar invoice via Boleto | Entrou | OBC e BDD Feature criados em 2026-07-06. Jornada específica documentada com 8 cenários, 4 riscos e contrato de resposta incluindo `bankSlipUrl` e `identificationField`. Dependências de implementação identificadas no OBC. Pronta para Bootstrap + Hack. | Checkout passa a oferecer Boleto como meio de pagamento via gateway Payments, com linha digitável e link PDF retornados ao cliente. |
| Validação de acesso por token de API | Entrou | Protege a Payments API de acessos não autorizados e habilita rastreabilidade por tenant desde o primeiro slice de produção. Chave local elimina fricção no ambiente de desenvolvimento. | Checkout e integrações passam a autenticar via token cadastrado; acesso local funciona sem dependência de secrets externos. |
| Configuração de webhook por token de API | Entrou | Completa o contrato de integração: consumidores que usam o token de API precisam receber notificações de status sem polling. Dependência direta do token de API já entregue. | Checkout e integrações recebem `invoice.confirmed` e `invoice.cancelled` via HTTP POST com assinatura verificável. |
| Observabilidade com Datadog em produção | Entrou | EXP-010 validou ativação em staging com traces e log injection confirmados. OBC e BDD criados em `prodops/artifacts/obcs/observability-datadog.md`. Derivado do EXP-009 (Serverless Maturity Assessment). | Time diagnostica falhas de pagamento por correlationId no Datadog sem consulta manual ao CloudWatch. |
| Persistência DynamoDB otimizada para produção | Entrou | EXP-011 validou PAY_PER_REQUEST, PITR e remoção de GSIs mortos em staging sem downtime. OBC e BDD criados em `prodops/artifacts/obcs/dynamodb-optimization.md`. | Zero risco de throttling em produção; recuperação point-in-time em 35 dias para todos os dados de pagamento. |
| Pipeline de CI/CD para produção com gate de aprovação | Entrou | EXP-012 criou o workflow com Required Reviewers, corrigiu SAM CLI merging behavior e documentou IaC da role OIDC. OBC e BDD criados em `prodops/artifacts/obcs/production-cicd-pipeline.md`. | Todo deploy em produção requer aprovação humana explícita com rastro auditável — eliminando deploys manuais não rastreados. |
| Cancelar invoice pendente | Adiada | Apesar de implementada, não é essencial para validar a ativação inicial do novo gateway no Checkout. Incluir como compromisso principal aumentaria superfície da Release. OBC em `prodops/artifacts/obcs/cancel-invoice.md` — disponível para próxima iteração. | Valor preservado para iteração posterior com menor risco de dispersão. |
| Integração corporativa de incidentes/ITSM | Saiu | É relevante para operação, mas não é funcionalidade de negócio da iteração. | Mantém foco no recorte funcional da Release. |
| Gateway fallback/Itau | Saiu | O Product Deck cita intercambiabilidade, mas o escopo atual é Asaas. Incluir fallback agora ampliaria demais a Release. | Evita transformar a iteração em programa de plataforma. |

## Trade-offs realizados

Boleto estava dividido por falta de evidência de jornada completa. Em 2026-07-06 o OBC, a BDD Feature e os riscos foram criados. A decisão foi revisada para "Entrou" — o contrato e os critérios de aceite estão definidos e a jornada pode seguir para Bootstrap + Hack sem competir com a estabilização do Pix, pois os artefatos delimitam claramente as regras e as dependências de implementação.

Cancelamento ficou adiado porque, embora tenha valor operacional e esteja implementado, não é a capacidade central para provar a nova jornada Checkout -> Payments -> confirmação -> cliente informado. Ele pode ser retomado quando a ativação principal estiver estabilizada.

Itens de observabilidade, ITSM, runbooks, rollout e confiabilidade não foram incluídos como escopo funcional do Iteration Plan porque o prompt define que esses assuntos pertencem ao Reliability Plan. Eles influenciam a cautela na seleção do escopo, mas não entram como funcionalidades desta decisão de negócio.

Fallback/Itau ficou fora porque aumentaria muito o tamanho da Release. A oportunidade de intercambiabilidade continua válida no Product Deck, mas não pertence ao menor conjunto de funcionalidades necessário para esta iteração.

## Premissas

- A próxima iteração tem duração de 15 dias, conforme o premortem.
- O objetivo principal da Release é habilitar o novo gateway no Checkout com menor risco de falha.
- Pix é a jornada prioritária para validar o novo gateway, por estar detalhada no Service Deck de Compra com Pix.
- Boleto é desejado pelo negócio, mas não há evidência suficiente nos artefatos para tratá-lo como jornada tão madura quanto Pix nesta iteração.
- Notification Service permanece como dependência crítica para a experiência do cliente.
- O bug da Feature Flag está fora do código deste repositório, mas influencia diretamente a decisão de escopo.
- A análise do código foi usada apenas para avaliar viabilidade de escopo, não para propor tarefas de implementação.

## Fontes consultadas

- `prodops/artifacts/product/context/product-deck.md`
- `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
- `prodops/artifacts/product/backlogs/icebox-backlog.md`
- `prodops/artifacts/bdd/create-invoice.feature`
- `prodops/artifacts/bdd/payment-confirmation.feature`
- `prodops/artifacts/bdd/cancel-invoice.feature`
- `prodops/framework/journeys/assessment/`
- `prodops/artifacts/product/backlogs/iteration-backlog.md`
- `prodops/artifacts/event-storming/plan.json`
- `api/src/modules/invoices`
- `api/src/infra/asaas.service.ts`
- `api/test/criar-invoice.e2e-spec.ts`
