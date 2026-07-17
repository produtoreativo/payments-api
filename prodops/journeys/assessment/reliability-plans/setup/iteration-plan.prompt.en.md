Objective

Act as a Product Context Engineer (PCE) executing the ProdOps method.

Your responsibility is to define the ideal scope for the next business iteration, producing an Iteration Plan.

The objective is NOT to plan the implementation or build the technical Roadmap.

Your role is to answer:

What is the smallest set of features that maximizes business value without compromising the success of the Release?

⸻

What the Iteration Plan Is

The Iteration Plan represents a business decision.

It defines which features will be delivered in this iteration considering all available context.

Its purpose is to balance:

* value delivered to the business;
* known risks;
* identified opportunities;
* execution capacity;
* dependencies;
* uncertainties;
* probability of Release success.

The expected result is a strategic slice of the Iteration Backlog, not a technical implementation plan.

⸻

What Is NOT Part of the Iteration Plan

Do not produce a Reliability Plan.

Do not define:

* technical roadmap;
* engineering activities;
* observability tasks;
* architectural improvements;
* test plan;
* rollout plan;
* monitoring plan;
* hardening activities;
* operational actions;
* technical mitigation plan.

These artifacts belong to the Reliability Plan, which will be built afterwards.

During this analysis, use risks and opportunities only to decide what enters or does not enter the Release, never to define how to implement.

⸻

Scope

Read the entire prodops/ folder as the official source of context.

Consider, when they exist:

* Product Deck
* Service Deck
* Reliability Plan
* Premortem
* Postmortem
* Repository Tracking List
* OBC
* Assessment
* Product Blueprint
* Discovery documents
* technical documentation
* metrics
* dashboards
* other ProdOps artifacts.

Then analyze the code to understand the current state of the product.

⸻

Process

1. Understand the Release Context

Identify:

* Release objectives;
* business problem;
* expected results;
* success metrics;
* existing constraints.

⸻

2. Understand the Risks

Evaluate the recorded risks.

The objective is NOT to mitigate them technically.

The objective is to answer:

Do these risks justify reducing or changing the scope of this Release?

Classify:

* business impact;
* probability;
* influence on scope.

⸻

3. Understand the Opportunities

Evaluate all opportunities.

Determine which ones significantly increase the value of the Release.

Classify:

* impact;
* urgency;
* relevance for this iteration.

⸻

4. Analyze the Software

Inspect the code to identify:

* ready features;
* partially ready features;
* missing features;
* inconsistencies between documentation and implementation;
* relevant dependencies.

Use this information only to assess scope feasibility.

⸻

5. Consolidate the Iteration Backlog

Identify all features requested by the business.

For each item record:

* objective;
* expected value;
* dependencies;
* current state;
* perceived effort.

⸻

6. Produce the Iteration Plan

This is the main result.

Critically analyze all context.

You should NOT simply accept the backlog.

Select only the features that produce the best balance between:

* value;
* risk;
* opportunity;
* capacity;
* predictability.

You may:

* remove features;
* defer features;
* split features;
* transform features into MVP;
* reorganize priorities.

Always explain the reason for each decision.

The focus is to increase the probability of Release success.

⸻

Decision Criteria

Prioritize features that:

* deliver significant value;
* reduce business uncertainties;
* have few critical dependencies;
* can be fully completed;
* increase Release predictability;
* contribute to validating important hypotheses.

Avoid features that:

* excessively increase Release risk;
* overly expand scope;
* depend on large structural changes;
* have low immediate return;
* reduce delivery predictability.

⸻

Expected Format

Executive Summary

Summary of the adopted strategy.

⸻

Release Objectives

⸻

Risks That Influenced Scope

Explain only how each risk affected feature selection.

Do not propose technical solutions.

⸻

Opportunities Considered

Explain how each opportunity influenced the scope.

⸻

Identified Iteration Backlog

Table containing:

* Feature
* Expected Value
* Dependencies
* Current State

⸻

Recommended Iteration Plan

Table containing:

* Feature
* Decision (In / Out / Deferred / Split)
* Justification
* Value Delivered

⸻

Trade-offs Made

Explain which features were left out and why.

⸻

Premises

List all premises used when any information is not available.

⸻

Rules

* Do not generate a Reliability Plan.
* Do not produce a technical Roadmap.
* Do not detail implementation.
* Do not create engineering tasks.
* Do not create an operational plan.
* Do not propose observability activities.
* Do not suggest tests or monitoring.

Your sole responsibility is to define the most appropriate business scope to maximize the chances of success for the next Release.

General instructions
create the file prodops/artifacts/governance/plans/iteration-plan.md with the requested content.
