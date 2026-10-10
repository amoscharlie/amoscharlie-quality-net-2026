# Release decision

Candidate tag: **v1.0.0-rc.1**. Owner: Amos Charlie. Decision date: 2026-10-11. Decision: **BLOCKED for production release**.

The known reproduced P1 defects have been corrected and protected by regression checks. Deterministic API/UI checks and the build can be GREEN while a release is BLOCKED. Real mic-to-provider interview acceptance has not been verified: local credentials are placeholders and inherited provider model availability is unconfirmed. No owner risk acceptance has been invented.

`assessment/risk-register.json` records final finding dispositions and required acceptance checks. `check-release.mjs` blocks any open P0/P1 without named/evidenced owner acceptance and any required check not passed. Tag CI first runs the same quality jobs, then computes the release decision on the tagged source. A failed release job is the expected result for this candidate; no production deployment or published production release is authorized by green unit tests.

## Fixed in this candidate

Tenant result ownership and coverage roles; server-owned login membership; verified/idempotent completion; persisted skill removal and canonical identity; fail-closed, transactional AI evidence persistence; evidence-dependent coverage; truthful error/recovery UI; expected-level contract; stale caller/connection handling and durable portfolio delivery.

## Remaining risks and mitigations

- Critical acceptance pending: actual provider voice interview and generated output through the complete user flow. Required to release. Owner must configure credentials/models and retain real evidence; automated fake results do not substitute for it.
- P2 A12: invite expiry/revocation, external token revocation/membership and full active-edit/timeout policy require explicit product decisions. Protect credentials and use controlled local sessions; do not imply broad deployment acceptance.
- P2 A13: local runtime works; inherited deployment manifests are examples, not approved production infrastructure. Review environment, DB backup/restore and provider quotas before deployment.
- P2 A14: seven build-tool advisories remain (five high, two moderate). This workflow uses repository-owned build patterns, does not expose a Vitest/mock server, and keeps dependency installation separate from app runtime. Revisit patched compatible releases; no blind force upgrade.
- Measurement limits: multi-process load, interruption/audio latency and semantic rating accuracy remain unmeasured. Exact quotes establish existence, not evaluator correctness.

## To change the decision

1. Configure available provider models and a local key without committing secrets.
2. Run a real candidate interview: invite, mic/provider reconnect, persisted transcript/coverage, legitimate termination, generated portfolio, assessor review/override, vacancy comparison and export.
3. Verify exact candidate evidence, levels/confidence and failure states; preserve logs/screenshots with secrets and personal data redacted.
4. Update the acceptance record with evidence and actual owner review in a checked PR; resolve any newly discovered P0/P1 first.
5. Create a new immutable candidate tag and rerun all gates. Do not move rc.1 or rewrite its decision.

Release notes live in `assessment/releases/v1.0.0-rc.1.md`. The immutable tag points to `58eb125645b96e580aeba786c1acbefc1cec9758`. [Tag CI](https://github.com/amoscharlie/amoscharlie-quality-net-2026/actions/runs/38070843981) passed inputs/API/web and failed release with `decision: BLOCKED`, no open finding blockers, and `unverified: [live_provider_interview]`. Later documentation updates on main do not change the tagged candidate. This is a reviewable release candidate with a deliberate blocked decision, not a claim of production readiness.
