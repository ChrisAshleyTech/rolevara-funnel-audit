# Rolevara-Funnel-and-Tracking-Audit.pdf

A business analysis of real usage data from [Rolevara](https://rolevara.com), a job-simulation platform I built, where learners work realistic help desk, IAM and SOC tickets.

I queried the production database with SQL, compared what the event log says learners did against what their saved progress shows, and turned the gaps into a data quality log, requirements and recommendations.

## Key findings

- **0 of 9 outside learners signed in again** after the day they joined (Oct 23 to Nov 6, 2026).
- **The event log undercounts activity.** 5 learners have an onboarding record in saved progress; the event log records 1 completion.
- **The most popular track can't be tracked.** Help desk is the top pick (3 learners), but the event table only accepts IAM, IAM-GRC, GRC and PAM.

The sample is small (9 accounts), so these are early signals to act on, not statistics.

## Learner funnel: event log vs reality

| Step | Event log | Saved progress or account data |
| --- | --- | --- |
| Signed up | 8 | 9 |
| Chose a role track | 1 | 8 |
| Onboarding recorded | 1 | 5 |
| Practiced tickets | 1 | 3 |
| Signed in on a later day | 0 | 0 |

## Data quality issues found

| ID | Issue | Severity |
| --- | --- | --- |
| DQ-01 | Track choices outside four allowed values are rejected | High |
| DQ-02 | Onboarding completions are undercounted | High |
| DQ-03 | Anonymous activity never links to the account created later | High |
| DQ-04 | Sign-in event fires inconsistently (1 event for 9 sign-ins) | Medium |
| DQ-05 | A ticket completed with no ticket started | Medium |
| DQ-06 | An account with no account-created event | Low |

## What's in this repo

- `Rolevara-Funnel-and-Tracking-Audit.pdf`: the full report with method, funnel, data quality log, 7 requirements with acceptance criteria, and recommendations
- `queries.sql`: every query behind the numbers, so the analysis can be rerun

## Skills shown

SQL (CTEs, joins, JSONB, aggregates, data-quality checks) · funnel and retention analysis · data quality auditing · requirements with acceptance criteria · prioritization (MoSCoW) · privacy-aware reporting (owner accounts excluded, no personal data published)

## About me

Christopher Ashley: 16+ years in controls, audit and ERP administration, moving into business analysis. This project applies an auditor's habit, checking whether the records match reality, to product data.
