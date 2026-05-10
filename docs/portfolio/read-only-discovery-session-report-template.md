# Read-Only Discovery Session Report Template

## Purpose

This template shows how I structure a read-only discovery handoff when the goal
is to understand reporting assets, dependencies, refresh health, and immediate
risks without changing production systems.

## Session Metadata

- Discovery type: Reporting readiness review.
- Access posture: Read-only.
- Output audience: Analysts, engineers, and project owners.
- Source systems: Generic operational data platform and BI service.

## Discovery Checklist

1. Confirm the target reporting asset and intended business owner.
2. Inventory upstream source objects and serving-layer views.
3. Review refresh cadence, recent run status, and known delays.
4. Check row counts, latest data date, and key coverage.
5. Record open risks, owner follow-ups, and recommended next actions.

## Query Audit Fields

Each discovery query should capture:

- Query label.
- System or endpoint type.
- Read-only command or API category.
- Runtime status.
- Row count or finding count.
- Notes needed for follow-up.

## Example Findings

| Area | Finding | Recommended Action |
| --- | --- | --- |
| Serving layer | Reporting view exists and returns current rows | Keep as approved endpoint |
| Refresh | BI refresh should run after upstream load window | Align schedule and monitor first run |
| Data quality | Small number of missing account labels | Review source mapping and document exception |
| Ownership | Support path was not explicit | Add owner and escalation notes to runbook |

## Handoff Summary

The final handoff should make clear what is ready, what still needs review, and
which validation checks can be rerun before a report is published or changed.

## What This Demonstrates

- Read-only discovery discipline.
- Repeatable reporting-support workflow.
- Evidence capture for technical and non-technical stakeholders.
- Privacy-conscious reporting documentation.
