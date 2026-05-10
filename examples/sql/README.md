# SQL Examples

Sanitized SQL examples that show how I structure reporting-facing contracts and validation checks.

Current examples:

- `reporting_endpoint_view.sql` for a business-facing reporting view
- `reporting_endpoint_validation.sql` for freshness, row count, and key coverage checks
- `validation_guardrails_template.sql` for object availability, freshness,
  distribution, key coverage, and source-to-reporting parity checks

These are rewritten around generic entities and synthetic assumptions rather than copied from production systems.
