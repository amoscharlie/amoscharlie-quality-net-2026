# Platform audit

Audit date: 2026-10-10. Owner: Amos Charlie.

## Decision

**DO NOT SHIP the baseline.** Cross-tenant result access, fabricated completion, and unvalidated AI output threaten candidate data and hiring decisions. Static evidence is distinguished from reproducible runtime evidence below. No P0 has yet been demonstrated. A missing local runtime is an environment prerequisite, not a product P0.

## Architecture and objective

Two services: React/TypeScript browser and Rails REST/WebSocket API. PostgreSQL persists tenant assessments, sessions, ordered transcript turns, coverage maps, portfolios, assessor overrides, vacancies and comparisons. Redis provides queues, throttling and coverage pub/sub. Sidekiq compiles prompts, analyzes coverage and generates portfolios/comparisons. A realtime AI connection proxies candidate PCM audio. The objective is a defensible skills assessment with persisted evidence and correct, isolated results.

Critical flow: configure skills -> create invite -> start interview -> persist turns -> update evidence-based coverage -> end once -> generate portfolio -> review/override -> compare vacancy -> export.

## Sources and assumptions

The assessment brief supplies severity, workflow and release requirements. Two supplied external PRDs describe behavioral probing and an end-to-end reference simulation. Those sources have been read privately; identifiable source links and scenario names are deliberately excluded from the public copy.

A change-specific acceptance contract and design note will be recorded in `assessment/specs/quality-contract.md`. The external PRDs are referenced inputs, not repository-local files. No local PRD/notes/tickets are present; missing local input and traceability are recorded under A12. This does not imply that the entire product has no specification.

Assumptions: a signed assessor credential authorizes only its own organization; invite possession permits only the associated candidate session; `all_covered` must describe verified coverage, not a client assertion; persisted skill IDs are canonical taxonomy strings; generated ratings require a complete, valid response and supporting candidate evidence; removing a persisted skill must survive save/reload. These assumptions are engineering decisions requiring explicit traceability, not invented claims that every rule was stated verbatim in the PRDs.

Severity is applied top to bottom: P0 objective impossible, no workaround; P1 data/logic wrong or manual workaround required (all integrity defects at least P1); P2 limited issue with correct function/data; P3 visual/copy only.

## Ranked findings

| ID | Severity | Classification | Impact and evidence | Initial status |
|---|---|---|---|---|
| A01 | P1 | Built wrong / isolation assumption | `Portfolio.find` and a portfolio-skill join lack a tenant-qualified session predicate. A valid assessor may access or alter another organization's results. Reproduce export, fit/gap and override using another tenant's IDs. | Static confirmed; runtime pending |
| A02 | P1 | Built wrong / lifecycle integrity | `audio_complete` accepts any existing invite and calls EndHandler with `all_covered`; no active/coverage check. Pending/incomplete interviews can be persisted as successfully covered. | Static confirmed; runtime pending |
| A03 | P1 | Built wrong / persistence seam | Edit forms remove rows in memory but send no `_destroy` for persisted IDs. Reload can restore supposedly removed assessment/vacancy skills and change what is assessed/compared. | Static confirmed; runtime pending |
| A04 | P1 | Built wrong / taxonomy identity | SkillPicker deliberately discards taxonomy `skill_id` and scope exclusion; stored identity is lost and comparison falls back to labels. | Static confirmed; runtime pending |
| A05 | P1 | Built wrong / AI boundary | Generator defaults absent arrays to empty, clamps invalid levels into 1..5, and deletes/replaces skills outside one transaction. Malformed output can become a complete or partial portfolio. | Static confirmed; runtime pending |
| A06 | P1 | Built wrong / evidence requirement | Coverage worker promotes partial rows with >=4 probes when absent from the latest updates, without proving evidence sufficiency or actual context expiry. Coverage can be falsely completed. | Static confirmed; runtime pending |
| A07 | P1 | Built wrong / outcome reporting | Candidate info failures, nonrecoverable WS errors and retry exhaustion render Interview Complete with a recording claim. Candidate may believe an interview was recorded when it never ran. | Static confirmed; browser pending |
| A09 | P1 | Built wrong / authorization assumption | Coverage WebSocket validates JWT and organization but never checks assessor/admin role. A same-tenant ordinary-user token can subscribe to assessment coverage. | Static confirmed; runtime pending |
| A10 | P1 | Systemic risk / concurrency | Multiple browser connections have separate turn counters and independent disconnect timers. Uniqueness errors are swallowed; an old connection's grace timer may end a refreshed interview. EndHandler has a read-before-write race and DB-to-queue failure window. | Hypothesis; controlled reproduction required |
| A15 | P1 | Built wrong / credential minting | Local admin login accepts a client-selected X-Tenant-Scheme without membership. Valid passwords can mint another organization credential. Runtime: login returns 200 where unauthorized is required. | RED reproduced |
| A08 | P2 | Built wrong / API contract | API comparisons expose `expected_level`; frontend reads `required_level`. Required level disappears although backend delta remains correct. Escalate if observed to corrupt decisions or stored outcomes. | Static confirmed; browser pending |
| A11 | P2 | Missing workflow inputs/enforcement | No CI, runnable test suites, change-input gate, release gate or repository-local traceability. RSpec dependencies alone do not form a quality net. Inputs must become enforceable at PR and release boundaries. | Inventory confirmed |
| A12 | P2 | Missing/ambiguous specification | Invite expiry/revocation, tenant membership, active-assessment editing, reconnect ownership, deadline enforcement while silent, and failed-job recovery lack a complete acceptance/design contract. | Remaining; document assumptions/owners |
| A13 | P2 | Setup/reproducibility | README/sample ports differ, invite base targets backend, local seed has no admin, database names are hardcoded, frontend has no initial lockfile, console helper queries a missing column. | Confirmed; local workarounds documented |
| A14 | P2 | Dependency/operational risk | Initial npm resolution reports 7 advisories in build tooling (5 high, 2 moderate); no public untrusted-pattern build input is established. Production configuration has placeholder/inherited hosting settings and no demonstrated provider credential. | Remaining; assess exposure before upgrade |

## Systemic patterns

1. Authentication and parent ownership are not applied consistently to child resources or WebSockets.
2. Screen state and client assertions substitute for persisted facts.
3. AI output is trusted as valid business data; prompt instructions are not a data validator.
4. Async writes, jobs and multiple connections lack a single explicit lifecycle owner and evidence boundary.
5. Quality inputs and release evidence are not yet bound to a specific change/version.

## Reproduction and limits

Baseline frontend `npm run build`: PASS. PostgreSQL and Redis: reachable. Ruby 3.3.2, PostgreSQL and Redis are installed and the local API/web/worker run. Owner login and authenticated assessment listing have been verified over HTTP. Live AI audio has not been verified because the local key is a placeholder. No test will claim provider behavior merely because a deterministic fake passes.

The initial review inspected API, web, models, all migrations/schema, package and environment configuration, deployment manifests, READMEs and external PRDs. Inventory: no local notes/tickets/docs folders, test suites, `.github` workflows or pre-existing assessment folder. No feature defect was patched before this audit.

## Ship line and residual ownership

Release is blocked until reproducible checks cover A01-A07 and A09 and identified P1 defects are corrected. A10 must be reproduced or explicitly retained as a release-blocking integrity uncertainty, rather than silently marked fixed. Runtime/CI evidence, visible blocked/pass PRs, tag-bound checks and confidentiality review are required before claiming the assessment submission complete. Amos Charlie owns all remaining risks and verification work. P2/P3 may be deferred with a stated impact and mitigation. Unknown provider behavior remains an explicit release limit.


## Final disposition (2026-10-11)

| Findings | Disposition | Reproducible evidence |
|---|---|---|
| A01 / A09 | Fixed: HTTP child lookups join the session tenant; coverage subscription checks the assessor role. | `api/spec/requests/result_isolation_spec.rb` |
| A02 | Fixed: both the HTTP boundary and locked end transition require active, verified coverage. | `api/spec/requests/session_completion_spec.rb` |
| A03 / A04 | Fixed: persisted deletion tombstones, retained IDs and canonical taxonomy scope. | `web/src/test/risk-paths.test.tsx` |
| A05 / A06 | Fixed: validate complete response before atomic replacement; no count-only coverage promotion. | `api/spec/services/evidence_integrity_spec.rb` |
| A07 / A08 | Fixed: invalid invites, fatal WS errors, exhausted retries and reloaded error endings remain failures; expected level renders from API contract. | frontend risk-path and audio-outcome checks; candidate-info request check |
| A10 | Fixed for reproduced cases: session row locks, durable pending delivery, independent recovery polling, serialized worker and complete-result idempotency; new browser lease supersedes old disconnect termination. | `api/spec/services/lifecycle_races_spec.rb` |
| A15 | Fixed: local login binds server-owned user organization; legacy unbound accounts are quarantined. | `api/spec/requests/login_membership_spec.rb` |
| A11 | Fixed: mandatory input/changed-test gate, every-change CI, protected main, visible blocked/pass examples, version-bound release gate. | workflow, gate tests, PR links in quality-system document |
| A12 | Deferred P2: expiry/revocation, external token membership/revocation, live load and full timeout policy remain specified incompletely. | release limits and risk register |
| A13 | Local setup corrected and verified; deployment configurations remain inherited examples requiring environment-specific review. | `assessment/setup-local.md` |
| A14 | Deferred P2: seven build-tool advisories remain. Newly added test tooling was upgraded to remove its critical advisories. No untrusted build pattern input is accepted in this workflow. | lockfile / npm audit; release notes |

The lifecycle checks reproduce controlled competing/stale callers and queued-delivery failure. They do not establish multi-process load capacity or audio latency. Exact candidate-quote grounding does not prove that a model's level or skill attribution is semantically correct. Real provider/voice acceptance is still pending and independently blocks production release.

RED history is retained in independent Git commits, local evidence files and real CI runs. See `02-quality-system.md` for exact links; failed boot/setup runs are labeled separately from behavioral RED runs. No failed regression assertion was weakened to obtain GREEN.

## Post-tag runtime finding: R01 (historical P1 reproduction; subsequently fixed)

The earlier final disposition describes controlled cases, not complete live acceptance. Real voice testing exposed premature natural-close orchestration: AI closing words trigger all_covered while coverage analysis is failing, so the verified completion boundary rejects the transition and the candidate remains stuck. Manual termination is required. This is built wrong, P1 (objective requires manual workaround), owner Amos Charlie. See `evidence/runtime-provider-review.md` for repro, impact, sanitized evidence and recovery limits.

Provider model compatibility also failed: list availability did not establish generateContent access. Local configuration now uses a model verified by an actual call; one existing portfolio regenerated successfully. At that reproduction point R01 was open and had no new regression/fix; the subsequent corrective disposition below supersedes that historical status. Full acceptance remains pending. A08 remains P2 because the expected-level display was missing while persisted requirements and backend delta were correct.

## R01 corrective disposition

R01 is fixed for reproduced failure/timeout paths. Verified preparation is shared by natural closing, injected wrap-up and phrase fallback. Unverified closure persists error and emits a failed terminal outcome; verified coverage still drains and acknowledges. Timeout preserves actual persisted reason and checks connection ownership. Browser completion rejection has bounded retries and terminal cleanup stops capture/playback plus pending work. Five API checks and three page checks were RED before the respective fixes; assertions are retained unchanged. Full net now has 31 API examples and 13 UI checks. See PR #5 and quality-system evidence; real full-provider acceptance still pending.

## Final input review and classification

See `non-code-review.md` for the exact non-code file inventory and scoped confidentiality checks. Built-wrong findings concern implemented behavior violating recorded contracts (A01-A09, A15 and R01); A10 is a systemic integrity risk reproduced under controlled conditions. Missing/ambiguous inputs are A11/A12; A11 workflow enforcement is corrected, while repository-local PRDs/tickets and product-policy inputs remain incomplete. A13 includes model compatibility: 404 is an account/configuration observation; the conscious local recovery and subsequent 503 are documented in `setup-local.md`.

R means runtime finding discovered after the first tag and recorded in the risk register. R01 is P1 because the objective required manual termination. Documentation corrections after the tag are on main; candidate source is unchanged. No original-source history review is claimed.
