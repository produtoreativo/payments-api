# Opportunities Register — Payments Premortem

> Based on the Premortem document for the Payments release.

## Objective

Consolidate the opportunities identified during the Premortem so they can be incorporated into the Reliability Plan, the Roadmap and the release OBCs.

---

# Glory 2 — APM Integration with the ITSM Tool

## Description

Integrate the observability platform (DataDog/APM) with the corporate ITSM process, enabling the correlation of incidents, CIs, CMDB and operational evidence.

## Expected Benefits

- MTTR reduction
- Better incident traceability
- Correlation between alerts and assets
- Greater operational efficiency

## Next Actions

- Integrate DataDog with ITSM
- Map Payments domain CIs
- Automate incident creation

---

# Glory 3 — Observability Tags Review

## Description

Re-evaluate the tag strategy considering the monolith decomposition into microservices.

## Expected Benefits

- Per-service dashboards
- Clear ownership
- More efficient queries
- Standardized metrics

## Next Actions

- Define tag standards
- Update instrumentation
- Review dashboards

---

# Glory 9 — Cart Monitoring

## Description

Instrument the cart flow using DataDog to track the full customer journey through to payment confirmation.

## Expected Benefits

- End-to-end visibility
- Early degradation detection
- Better customer experience
- Conversion KPIs

## Next Actions

- Instrument Checkout
- Instrument Payments
- Correlate distributed traces
- Create executive dashboards

---

# Derived Strategic Opportunities

In addition to the opportunities recorded in the document, the release context highlights initiatives that can increase operational maturity:

- Standardize instrumentation with OpenTelemetry.
- Evolve observable contracts (OBCs) for all critical capabilities.
- Define OpenSLOs for payments.
- Automate observability Quality Gates.
- Consolidate the Release Trail as execution evidence.
- Evolve the Operational Trail for continuous learning.

---

# Recommendations for the Reliability Plan

## Short Term

- Deploy DataDog/APM
- Instrument Feature Flags
- Create operational dashboards
- Integrate ITSM

## Medium Term

- Full distributed traces
- Business KPIs
- SLO-based alerts
- Automated runbooks

## Long Term

- Observability as a standard OBC requirement
- RCA automation
- Continuous reliability roadmap
