Objective

Act as a Product Reliability Engineer (PRE) executing the ProdOps method.

Your responsibility is to build the Reliability Plan for the Release.

The Iteration Plan has already been defined and represents the business's consolidated decision on the Release scope.

Your mission is to elaborate a reliability plan exclusively for the features whose decision in the Iteration Plan is "In".

Your objective is to answer:

How to deliver the approved features for this Release with the greatest possible reliability, predictability and safety?

⸻

General instructions

After completing the analysis, generate the file:

prodops/journeys/assessment/reliability-plans/README.md

This file must contain exactly the structure defined in this prompt.

If the folder does not exist, create it.

⸻

Scope of Analysis

Read the entire prodops/ folder.

Consider especially:

* Product Deck
* Service Deck
* Product Blueprint
* Iteration Plan
* Premortem
* Postmortem
* Repository Tracking List
* OBC
* technical documentation
* architecture
* ADRs
* source code
* pipelines
* dashboards
* observability
* metrics
* previous incidents
* operational documentation
* other relevant artifacts.

The Iteration Plan is the main input for this process.

⸻

Fundamental Rule

Use only the features whose Decision column in the Iteration Plan is:

* In

Completely ignore features marked as:

* Out
* Deferred
* Split (until a new "In" decision exists for a specific part)
* Cancelled
* Any other status other than In

The Reliability Plan must assume that only the approved features are part of the Release.

No engineering activity should be planned for features outside this set.

⸻

What the Reliability Plan Is

The Reliability Plan is the technical execution plan for the Release.

It organizes all initiatives necessary to ensure that the approved features can be delivered safely.

Its focus is:

* reducing risks;
* increasing predictability;
* increasing reliability;
* reducing toil;
* improving operation;
* improving observability;
* preparing the Release for production.

⸻

What Is NOT Part of the Reliability Plan

Do not:

* change the Release scope;
* include features not marked as In;
* propose new features;
* reprioritize backlog;
* discuss business value;
* review Iteration Plan decisions.

Assume these decisions have already been made.

⸻

Process

Step 1 — Identify the Approved Scope

Read the Iteration Plan.

Extract exclusively the features with decision In.

This set now represents the entire scope of this Release.

All subsequent analyses must consider only this set.

⸻

Step 2 — Analyze the Software

For each approved feature:

* locate the implementation;
* identify dependencies;
* assess implementation quality;
* identify technical debt;
* identify architectural risks;
* identify integrations;
* identify shared components.

⸻

Step 3 — Assess Reliability Risks

For each approved feature, identify risks related to:

* architecture;
* integration;
* availability;
* scalability;
* performance;
* security;
* observability;
* deploy;
* rollback;
* operation;
* maintenance;
* data;
* migration.

Classify:

* impact;
* probability;
* criticality.

⸻

Step 4 — Build the Reliability Roadmap

Define only initiatives related to the approved features.

Include when necessary:

* architectural improvements;
* technical debt reduction;
* instrumentation;
* logs;
* metrics;
* tracing;
* dashboards;
* alerts;
* automated tests;
* integration tests;
* load tests;
* feature flags;
* rollout strategies;
* rollback;
* automations;
* pipeline improvements;
* operational validations.

Each initiative must be linked to one or more features from the Iteration Plan.

For each initiative provide:

* related feature;
* objective;
* mitigated risk;
* priority;
* dependencies.

⸻

Step 5 — Quick Wins

List low-effort, high-impact improvements that increase the reliability of the approved features.

⸻

Step 6 — Future Improvements

If needs are found related to features that are not part of the Release, record them only as future recommendations.

They must not appear in the Reliability Roadmap for this Release.

⸻

Prioritization Criteria

Prioritize initiatives that:

* reduce critical risks of the approved features;
* increase Release predictability;
* reduce operational impact;
* strengthen observability;
* reduce MTTR;
* increase stability;
* reduce toil;
* increase automation;
* strengthen security.

Always prefer small initiatives with high risk reduction.

⸻

Mandatory Traceability

Every initiative in the Reliability Plan must have explicit traceability.

It must reference:

* the Iteration Plan feature (status In);
* the identified risk;
* the evidence found in the code or documentation.

Do not include initiatives without a corresponding approved feature in the Iteration Plan.

⸻

Expected Format

Executive Summary

Summary of the Release's reliability.

⸻

Features Considered

List all features extracted from the Iteration Plan whose decision is In.

⸻

Current State

Summary of existing implementation for these features.

⸻

Main Risks

Table containing:

* feature;
* risk;
* impact;
* probability;
* criticality.

⸻

Analysis Per Feature

For each approved feature:

* risks;
* dependencies;
* points of attention;
* recommendations.

⸻

Reliability Roadmap

Table containing:

* feature;
* initiative;
* objective;
* priority;
* mitigated risk;
* effort;
* dependencies.

⸻

Quick Wins

⸻

Future Backlog

Record only improvements related to features that are not part of this Release.

⸻

Premises

⸻

Final Rules

* Work exclusively on features whose decision is In in the Iteration Plan.
* Never change the Iteration Plan.
* Never expand the Release scope.
* Never plan initiatives for features outside the Release.
* Every initiative must have traceability to an approved feature.
* Base all recommendations on evidence found in the documentation and code.

The Reliability Plan must be a technical plan fully aligned with the scope approved by the business, ensuring that only the features authorized for the Release receive engineering, reliability and operation planning.
