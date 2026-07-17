# Repository Tracking List

> **Purpose:** Captures any local product signal not yet understood enough to be treated as a formal commitment. Items here have no OBC, no permanent identifier, and no delivery commitment.
>
> Promoted items follow the local flow: Premortem + Reliability Plan + Owner Approval → Product Intent Backlog.
>
> → [Backlog hierarchy](../../../framework/backlogs.en.md)
> → [Icebox](icebox-backlog.en.md) — next level; where the OBC is refined to the Committed state

| Item | Origin | Dimension | Owner | Status | Next action |
| --- | --- | --- | --- | --- | --- |
| Collect Feature Flag readiness evidence for the new gateway in Checkout. | EXP-004 Checkout Gateway Feature Flag Readiness | Release/Reliability/Checkout | Tech Lead Checkout + Payments | P0 Open | Obtain bug, owner, fix status, rollout targeting, audit, rollback and per-order telemetry. |
| Define policy for in-flight orders after Feature Flag rollback. | EXP-004 Checkout Gateway Feature Flag Readiness | Operations/Flow/Data | Checkout + Payments + Operations | P0 Open | Decide whether orders initiated in Payments continue reconciling in Payments after disabling new traffic. |
| Promote Asaas hosted card payment to Downstream. | Upstream hosted vs tokenized credit card experiment | Customer/Company/Technology | PM Payments + Tech Lead Payments | Promoted to Downstream | Approved on 2026-07-07. OBC and BDD Feature moved. Iteration Plan entry added. |
| Decide tokenized card policy. | Upstream hosted vs tokenized credit card experiment | Security/Technology/UX | PM Payments + Security + Anti-fraud | Open | Confirm token ownership, `remoteIp`, timeout, risk, refusal and storage limits before Downstream. |
| Keep direct card capture out of the first slice. | Upstream hosted vs tokenized credit card experiment | Security/Compliance | PM Payments + Security | Blocked by decision | Resume only if there is formal PCI/security and anti-fraud acceptance. |
| Define Cart/Checkout -> Payments contract for saved cards. | EXP-001 Credit Card Lifecycle | Product/API/Checkout | PM Payments + Tech Lead Checkout + Tech Lead Payments | Open | Validate `GET /users/{userId}/payment-methods/credit-cards`, `POST /users/{userId}/payment-methods/credit-cards` and `POST /invoices/{invoiceId}/pay-with-credit-card`. |
| Define secure storage for card token. | EXP-001 Credit Card Lifecycle | Security/Data/Architecture | Security + Architecture + Payments | P0 Open | Decide vault/encryption, masking, retention, revocation and response to token compromise. |
| Define refund boundary for confirmed card payment. | EXP-001 Credit Card Lifecycle | Finance/Operations/API | Finance + Operations + Payments | Open | Confirm `POST /invoices/{invoiceId}/refund` contract, idempotency, reconciliation and provider evidence. |
