# Public Repo Strategy

## Objective

Create a public repository that shows professional range and technical maturity while avoiding disclosure of proprietary EnableCV implementation details.

## Positioning

The public repo should communicate:

- immediate fit for data analyst responsibilities
- strong SQL and reporting depth
- hands-on validation and investigation discipline
- ability to contribute beyond baseline analyst scope through automation, documentation, and data quality work

## What To Move Over

- rewritten case studies with generalized system names
- small sanitized SQL examples
- generic validation scripts with fake inputs
- README-level architecture diagrams with abstract labels
- runbook templates and investigation templates
- training or onboarding material rewritten without company specifics

## What Not To Move Over

- raw Azure exports
- pipeline JSON from the real environment
- production SQL objects copied verbatim
- screenshots from internal tools
- PDFs or reports created for internal stakeholders
- file names, table names, schemas, or endpoints that are unique to the employer
- any content that reveals non-public business process details

## Rewrite Pattern

When converting private work into public material:

1. keep the problem
2. abstract the environment
3. generalize the entities
4. preserve the engineering approach
5. summarize the result in business terms

Example:

- private: backorder reporting for a named source system and named tables
- public: inventory exception reporting pipeline with reporting-layer validation

## Recommended First Public Additions

- one case study on reporting-ready dataset delivery
- one case study on validation and release-readiness automation
- one SQL example showing a reporting view pattern
- one Python or shell example showing automated validation logic
