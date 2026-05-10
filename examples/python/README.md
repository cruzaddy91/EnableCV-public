# Python Examples

Sanitized Python utilities that reflect the kind of operational support work
needed to hand off reporting assets cleanly.

Current examples:

- `reporting_refresh_handoff.py` computes recommended BI refresh times from a
  trigger schedule and prints a repeatable handoff checklist
- `readonly_discovery_report_builder.py` turns sanitized discovery findings,
  readiness checks, and query-audit metadata into a simple HTML handoff report
- `powerbi_api_discovery.py` performs read-only Power BI REST inventory checks
  and masks identifiers by default for safer handoff notes

These examples are rewritten around generic schedule metadata and neutral
project names rather than copied from a private environment.
