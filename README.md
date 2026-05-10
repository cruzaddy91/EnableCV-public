# EnableCV Public Portfolio

Public-safe portfolio repository derived from professional data platform and reporting work completed at EnableCV.

This repository is designed to show how I approach reporting delivery, SQL contracts, validation, documentation, and operational reliability without exposing proprietary code, internal identifiers, or company-sensitive artifacts.

## Featured Artifacts

- [Reporting Endpoint Delivery and Validation](case-studies/reporting-and-validation.md)
  A public case study on building reporting-ready outputs, coordinating handoff, and validating reliability before stakeholder use.
- [Reporting Remediation Stakeholder Brief](assets/pdf/contracts-reporting-remediation-stakeholder-brief.pdf)
  A sanitized PDF brief showing how I communicate reporting remediation, validation, and handoff work to stakeholders.
- [Read-Only Discovery Session Report Template](assets/pdf/read-only-discovery-session-report-template.pdf)
  A sanitized PDF template for capturing discovery findings, query audit notes, and reporting-readiness risks.
- [Reporting Endpoint View](examples/sql/reporting_endpoint_view.sql)
  A sanitized SQL example showing a business-facing reporting contract built from operational and dimension data.
- [Reporting Endpoint Validation Checks](examples/sql/reporting_endpoint_validation.sql)
  A small set of release-readiness checks for freshness, row counts, and key coverage.
- [Validation Guardrails Template](examples/sql/validation_guardrails_template.sql)
  A broader SQL guardrail example for object availability, freshness, key coverage, and source-to-reporting parity.
- [Reporting Refresh Handoff Utility](examples/python/reporting_refresh_handoff.py)
  A sanitized Python utility that translates trigger cadence into operator-facing BI refresh guidance.
- [Read-Only Discovery Report Builder](examples/python/readonly_discovery_report_builder.py)
  A sanitized Python example for generating an HTML discovery handoff from neutral JSON input.
- [Power BI API Discovery Helper](examples/python/powerbi_api_discovery.py)
  A read-only API helper that masks IDs by default for safer inventory and refresh-history notes.
- [Reporting View Validation Runner](examples/shell/validate_reporting_views.sh)
  A sanitized shell workflow for row-count and schema parity checks before reporting handoff.
- [Reporting Lineage Verification Runner](examples/shell/verify_lineage_readonly.sh)
  A read-only shell workflow for checking expected views and dependency sources.

## What This Repo Demonstrates

- reporting-ready dataset and SQL delivery patterns
- validation and release-readiness workflows
- analyst-facing reporting and stakeholder support work
- documentation, runbooks, and training-style communication
- automation used to reduce manual investigation and improve reliability
- privacy-conscious evidence packaging for public portfolio use

## What Is Intentionally Excluded

- production exports, pipeline definitions, and internal schemas
- company-specific table names, endpoints, credentials, and environment details
- internal reports, screenshots, PDFs, and stakeholder materials
- anything that reproduces private implementation directly

## Repository Layout

- `case-studies/` public writeups of delivery problems, approach, and outcomes
- `examples/sql/` sanitized SQL examples and validation patterns
- `examples/python/` sanitized Python utilities and validation examples
- `examples/shell/` sanitized shell workflows and automation examples
- `docs/portfolio/` sanitized source documents used to generate public PDFs
- `assets/pdf/` generated public-safe PDF evidence
- `docs/` public-safety rules and repo strategy
- `scripts/` helper scripts for auditing publishable content

## Publishing Rule

This repo is a portfolio, not a mirror of the private work repository.

If a file depends on company-specific names, runtime details, screenshots, exports, or implementation specifics, it should be rewritten as a generalized example or case study before being added here.
