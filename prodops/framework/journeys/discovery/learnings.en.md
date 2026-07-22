# Learnings

Record reusable learnings from experiments, spikes, prototypes and exploratory validation here.

Do not convert learnings into delivery commitments until they are accepted into Downstream.

## Credit Card Asaas Lifecycle

Credit card support is feasible with the current Payments gateway shape, but it should not advance to Downstream as a simple extension of `billingType: CREDIT_CARD`.

Key learnings:

- The Asaas hosted checkout and the transparent checkout are distinct product and security contracts.
- Direct card capture requires fields and decisions not present in the current DTO: `creditCard`, `creditCardHolderInfo`, `creditCardToken`, `authorizeOnly`, installments and `remoteIp`.
- Immediate card processing can refuse authorization before persisting a charge, so the invoice state model and idempotency behavior must be explicit.
- Asaas card events — such as risk analysis, authorization, capture refusal, confirmation, receipt, deletion and refund — need explicit BDD mapping and observability.
- Deleting an unpaid charge is not the same as refunding an already-paid card charge.

Candidate for Downstream only after the next experiment defines the capture model and produces OBC, BDD, DTO, observability and Reliability Plan updates.

## Hosted vs Tokenized Credit Card

The focused comparison favors the Asaas hosted checkout as the first Downstream slice.

Validated learning:

- The hosted checkout can reuse the current `POST /invoices` shape, since Asaas can create a `CREDIT_CARD` payment without card fields and return an `invoiceUrl` for completion by the payer.
- Tokenized card payment is viable, but it is not just a UI option. It requires `creditCardToken`, `remoteIp`, explicit timeout, refusal mapping, risk-analysis mapping and storage/security rules for token ownership.
- Direct raw card data capture should remain outside the first Downstream slice unless Magazine Siará explicitly accepts the PCI/security and antifraud obligations.
- The Validation Workbench now exposes the proposed tokenized payload shape and card-specific webhook events for functional exploration.
- The capability is nearly ready for Downstream as hosted checkout, but tokenized payment still needs product and security approval before delivery.

## Saved Cards and Tokenization Boundary

Saved-card support is a Payments-owned contract, not just a Checkout UI choice.

Reusable learning:

- Cart/Checkout should list and select cards through `cardId` values owned by Payments. It must not receive or store the provider's `creditCardToken`.
- Payments can persist safe display metadata for the card — brand, last 4 digits, expiry, holder, provider and status — but must not persist the full card number, CVV or raw `creditCard` payload.
- The provider card token must be treated as sensitive material and suppressed from logs, traces, analytics, error payloads and dead-letter messages.
- New card registration expands the PCI/security scope even when raw card data is only transient, because `creditCard` and `creditCardHolderInfo` cross the Payments API boundary.
- `remoteIp` belongs to the payer context and must be provided by Cart/Checkout; using the Payments server IP weakens the antifraud evidence.
- The hosted checkout can still advance first, but saved-card reuse and new-card registration need Security, Architecture and Product decisions before Downstream.

## Checkout Gateway Feature Flag Readiness

The highest-priority uncertainty in the current product context is not a Payments API endpoint. It is knowing whether Checkout can safely enable the new gateway through a Feature Flag with rollout, auditability and rollback evidence.

Reusable learning:

- A release can have a functional Payments API and still fail to deliver value if the Checkout routing flag cannot be activated safely.
- Feature Flag readiness is a cross-system contract between Checkout, Payments and operations.
- Rollback must define what happens to orders already started in Payments; simply cutting off new traffic is not sufficient.
- The repository can prove Payments-side idempotency, correlation and webhook behavior, but cannot prove Checkout targeting or rollback without external evidence.

## Datadog Native AWS Instrumentation

The Payments API can maintain Datadog instrumentation without depending on the Serverless Framework.

Reusable learning:

- `dd-trace` and the existing observability module are application concerns; they do not require `serverless-plugin-datadog`.
- The AWS deploy should attach the Datadog Lambda Extension through SAM parameters, with the API key injected by the deploy pipeline.
- Local functional validation should use the NestJS sandbox with mocks and in-memory storage; Lambda/LocalStack validation is a separate infrastructure path, not the standard development loop.
- The remaining deploy decision is external to the repository: the pipeline owners must provide the correct Datadog Extension Layer ARN/version per AWS region.
- Lambda Function URL is sufficient for this lab API and avoids API Gateway cost.
- DynamoDB provisioned capacity mode can keep the current table/index model within the classic Free Tier envelope of 25 RCU / 25 WCU, assigning 1 RCU and 1 WCU to each table and GSI.
- Removing CloudWatch Logs permissions avoids log ingestion/storage charges, at the cost of losing application logs on the AWS side for troubleshooting.
