# EnableCV Public Portfolio

Public-safe portfolio repository derived from professional data platform and reporting work completed at EnableCV.

This repository is designed to show how I approach reporting delivery, SQL contracts, validation, documentation, and operational reliability without exposing proprietary code, internal identifiers, or company-sensitive artifacts.

## Featured Artifacts

- [Reporting Endpoint Delivery and Validation](case-studies/reporting-and-validation.md)
  A public case study on building reporting-ready outputs, coordinating handoff, and validating reliability before stakeholder use.
- [Reporting Endpoint View](examples/sql/reporting_endpoint_view.sql)
  A sanitized SQL example showing a business-facing reporting contract built from operational and dimension data.
- [Reporting Endpoint Validation Checks](examples/sql/reporting_endpoint_validation.sql)
  A small set of release-readiness checks for freshness, row counts, and key coverage.
- [Reporting Refresh Handoff Utility](examples/python/reporting_refresh_handoff.py)
  A sanitized Python utility that translates trigger cadence into operator-facing BI refresh guidance.
- [Reporting View Validation Runner](examples/shell/validate_reporting_views.sh)
  A sanitized shell workflow for row-count and schema parity checks before reporting handoff.

## What This Repo Demonstrates

- reporting-ready dataset and SQL delivery patterns
- validation and release-readiness workflows
- analyst-facing reporting and stakeholder support work
- documentation, runbooks, and training-style communication
- automation used to reduce manual investigation and improve reliability

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
- `docs/` public-safety rules and repo strategy
- `scripts/` helper scripts for auditing publishable content

## Publishing Rule

This repo is a portfolio, not a mirror of the private work repository.

If a file depends on company-specific names, runtime details, screenshots, exports, or implementation specifics, it should be rewritten as a generalized example or case study before being added here.
