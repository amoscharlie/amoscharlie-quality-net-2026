# Quality system

## Protected outcomes

The net protects tenant boundaries, verified session completion, persisted identity/removal, evidence integrity and truthful failure reporting. It deliberately exercises risk-bearing seams rather than every component. API request checks use a real PostgreSQL database; generation/analysis responses are controlled. UI checks render actual forms/pages and inspect observable state or the API payload; audio transport is a controlled socket.

| Risk | Check | Assertion that matters |
|---|---|---|
| A01/A09 | result_isolation request spec | 404/no mutation/no queued cross-tenant work; owner access still works; ordinary subscriber denied |
| A02/A07 | session_completion request spec | pending/uncovered remains unchanged; covered ends once; persisted failure reason survives recovery |
| A05/A06 | evidence_integrity service spec | invalid/fabricated response fails; prior DB rows survive; valid quotes/levels unchanged; no unsupported coverage promotion |
| A10 | lifecycle_races service spec | stale caller queues once, colliding turn counters retain both turns, old disconnect loses authority, outage leaves durable work, recovery retries once, completed results survive duplicate delivery |
| A15 | login_membership request spec | no token for unbound/foreign organization; owned membership signs the correct organization |
| A03/A04/A07/A08 | UI risk-path tests | removal tombstones, retained canonical IDs/scope, failed invite/reload, actual expected level |
| A07 | audio-outcome tests | fatal/retry-exhaustion failures stay failed; acknowledged clean end completes |
| Workflow | Node gate and release tests | required inputs, changed regression for production PRs, open P1/unverified acceptance blocks release |

Run commands are in `setup-local.md`. There is no percentage target; negative checks have positive controls so blanket denial or permanently failed generation cannot produce a misleading pass.

## Enforced workflow

Each push, PR and manual run starts the input gate, then API and web jobs. API builds its DB from migrations on PostgreSQL 17 and executes RSpec with Ruby 3.3.2; web installs the exact npm lockfile on Node 22, executes UI/hook checks and a TypeScript production build. Errors produce nonzero exit codes. Tests need no live provider key.

PR body requires four fields containing existing repository files:

```text
Spec: assessment/specs/quality-contract.md
Acceptance: assessment/specs/quality-contract.md
Design: assessment/specs/quality-contract.md
Tests: api/spec/requests/result_isolation_spec.rb
```

Production changes under api/app or web/src must also change a runnable regression file in the PR diff. Documentation changes may reference existing checks. PR text is read from JSON as data, not interpolated into a shell. Main requires the inputs, api and web checks before merge, including for the administrator.

A file reference and changed-test check cannot determine whether a specification is adequate or a test is meaningful. Reviewing the stated scenario, test assertions and design remains an owner responsibility. Deleting or weakening tests in a coordinated change is not automatically detected; main protection prevents accidental bypass, not malicious repository administration.

## RED to GREEN evidence

- Initial behavioral RED: [CI 38069039194](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38069039194). Frontend assertions failed; API initially encountered an eager-loading acronym defect, recorded separately.
- Confirmed API/UI behavioral RED: [CI 38069186590](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38069186590), 17 API examples / 14 failures plus UI failures.
- Main risk fixes GREEN: [CI 38069450263](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38069450263).
- Additional login/delivery RED: [CI 38069559731](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38069559731).
- Login/delivery fixes GREEN: [CI 38069792683](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38069792683).
- Reload failure RED: [CI 38070106333](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38070106333).
- Final recovery behavior and patched tooling GREEN: [CI 38070450860](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38070450860).

Evidence files under `assessment/evidence` capture specific runs; they are not claims that a saved log certifies a later commit. GitHub checks and tag commits are the authority for version-bound results. Initial failures are intentionally retained.

## Delivery integrity and limits

A pending portfolio is a durable DB delivery intent. Dispatcher locks its row, enqueues, then marks generating with a dispatch timestamp. A Redis failure rolls back the marker, leaving recoverable pending work. The Sidekiq server polls independently every 30 seconds, including after startup; stale generating work is retried after 15 minutes. An enqueue/DB-commit crash may deliver twice. Worker locking and a complete-result guard make that at-least-once delivery safe for already completed results.

The worker holds a portfolio lock across provider generation, trading per-result serialization for possible connection occupancy. Provider timeout is bounded; production sizing and failure/load behavior require further measurement. Controlled race checks do not certify distributed throughput. Candidate quote existence does not establish scoring accuracy. No real voice/provider E2E or browser audio timing test has passed, so production release remains blocked by the separate acceptance gate.


## Reviewable PR demonstrations

[PR #1](https://github.com/amoscharlie/amoscharlie-quality-net-2026/pull/1) intentionally changes a production-path source comment without required spec/acceptance/design/test inputs or changed regression evidence. Its PR-event inputs job fails and GitHub reports mergeStateStatus BLOCKED; it remains open for review and must not merge. The branch push job alone is not sufficient to authorize merging the PR. See [blocked PR CI](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38070500619).

[PR #2](https://github.com/amoscharlie/amoscharlie-quality-net-2026/pull/2) supplies all inputs and two meaningful coverage-rule checks: a single probe cannot cover a skill, and regressive/unknown model updates cannot erase coverage. It also makes PR-body edits rerun the gate and requires changed regression evidence for quality infrastructure. All required checks passed in [PR CI](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38070688770), then the PR was merged without bypass. [Post-merge main CI](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38070837663) also passed.

Main protection requires inputs/api/web, strict up-to-date checks, linear history and enforcement for administrators; force push and branch deletion are disabled. The release gate runs after the same quality jobs on tags. Candidate rc.1 may therefore have green quality jobs and an intentionally failed release decision. Inspect [tag workflow runs](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions?query=branch%3Av1.0.0-rc.1) and `03-release-decision.md` together.

## Post-tag gap found by real-provider testing

Controlled checks did not cover a provider analysis failure combined with AI natural closing. R01 remains open: the verified completion guard rejects the false all-covered claim, but orchestration stalls. Local portfolio recovery succeeded after model configuration changes; no new regression or fix is claimed. Current release gate also blocks R01 via the updated risk register. See `evidence/runtime-provider-review.md`.
