# Product Tracking List

> **Propósito:** Captura Business Signals do produto ainda não compreendidos o suficiente para gerar uma Business Intent formal. Itens aqui não têm OBC, não têm identificador permanente e não têm compromisso de entrega. Contém APENAS Business Signals.
>
> Cada Business Signal deve ter um GitHub Issue correspondente (Business Signal Issue). Entradas sem Issue estão incompletas — executar Diligence Sync → Attach para criar o Issue.
>
> Itens promovidos seguem o fluxo local: Premortem + Análise de Risco Preliminar + Owner Approval → Product Backlog (gerando Business Intent + Local OBC Draft).
>
> → [Hierarquia de backlogs](../../../framework/backlogs.md)
> → [Icebox](icebox-backlog.md) — próximo nível; onde o OBC é refinado até o estado Committed

| Item | Origem | Dimensão | Dono | Issue | Status | Próxima ação |
| --- | --- | --- | --- | --- | --- | --- |
| Coletar evidência de readiness da Feature Flag do novo gateway no Checkout. | EXP-004 Checkout Gateway Feature Flag Readiness | Release/Confiabilidade/Checkout | Tech Lead Checkout + Payments | #48 | P0 Aberto | Obter bug, owner, fix status, rollout targeting, auditoria, rollback e telemetria por pedido. |
| Definir política para pedidos em andamento após rollback da Feature Flag. | EXP-004 Checkout Gateway Feature Flag Readiness | Operação/Fluxo/Dados | Checkout + Payments + Operação | #49 | P0 Aberto | Decidir se pedidos iniciados no Payments continuam reconciliando no Payments após desligar novos tráfegos. |
| Promover pagamento com cartão hospedado Asaas para Downstream. | Upstream hosted vs tokenized credit card experiment | Cliente/Empresa/Tecnologia | PM Payments + Tech Lead Payments | #56 | Promovido para Downstream | Aprovado em 2026-07-07. OBC e BDD Feature movidos. Entrada no Iteration Plan adicionada. |
| Decidir política para cartão tokenizado. | Upstream hosted vs tokenized credit card experiment | Segurança/Tecnologia/UX | PM Payments + Segurança + Antifraude | #50 | Aberto | Confirmar token ownership, `remoteIp`, timeout, risco, recusa e limites de armazenamento antes de Downstream. |
| Manter captura direta de cartão fora do primeiro slice. | Upstream hosted vs tokenized credit card experiment | Segurança/Compliance | PM Payments + Segurança | #51 | Bloqueado por decisão | Retomar apenas se houver aceite formal de PCI/security e antifraude. |
| Definir contrato Cart/Checkout -> Payments para cartões salvos. | EXP-001 Credit Card Lifecycle | Produto/API/Checkout | PM Payments + Tech Lead Checkout + Tech Lead Payments | #52 | Aberto | Validar `GET /users/{userId}/payment-methods/credit-cards`, `POST /users/{userId}/payment-methods/credit-cards` e `POST /invoices/{invoiceId}/pay-with-credit-card`. |
| Definir armazenamento seguro de token de cartão. | EXP-001 Credit Card Lifecycle | Segurança/Dados/Arquitetura | Segurança + Arquitetura + Payments | #53 | P0 Aberto | Decidir cofre/criptografia, mascaramento, retenção, revogação e resposta a comprometimento de token. |
| Definir fronteira de refund para cartão confirmado. | EXP-001 Credit Card Lifecycle | Financeiro/Operação/API | Financeiro + Operação + Payments | #54 | Aberto | Confirmar contrato `POST /invoices/{invoiceId}/refund`, idempotência, conciliação e evidência do provedor. |
| Analisar e corrigir vulnerabilidades de segurança sinalizadas pelo Dependabot nas dependências do serviço. | GitHub Dependabot Security Alerts / Operation | Segurança/Dependências/Compliance | Tech Lead Payments | #55 | Aberto | Listar alertas ativos via `gh api /repos/produtoreativo/payments-api/dependabot/alerts`, classificar por severidade (critical/high primeiro), decidir estratégia — upgrade, patch ou accept risk — e registrar decisão por alerta. |
