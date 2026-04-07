# Shell Examples

Sanitized shell workflows that show how repeatable release-readiness checks can
be packaged for operators and engineers.

Current examples:

- `validate_reporting_views.sh` assembles a read-only SQL parity check for
  source tables and reporting views, then runs it through `sqlcmd`

These examples use neutral schemas, object names, and environment variables so
they stay portfolio-safe while still showing real operating patterns.
