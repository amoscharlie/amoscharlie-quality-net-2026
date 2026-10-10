# Quality contract

Owner: Amos Charlie. Scope: critical persisted outcome and authorization boundaries.

## Spec

Signed assessor credentials authorize their own organization only. Candidate invite possession authorizes only that session. A completed coverage outcome must be derived from active server state. Taxonomy identity and removal of persisted skills must survive save and reload. An AI response is untrusted input: invalid, incomplete or ungrounded output cannot become a complete rating portfolio. Transport failure cannot be displayed as successful recording.

## Acceptance

- A01: Given tenants A/B, when A exports, compares or overrides B's results, then API returns 404 and no B data or queued mutation is produced; owner access still succeeds.
- A02: Given pending/incomplete coverage, when invite calls audio_complete, then 422 and persisted state is unchanged. Fully covered active session ends once, with one portfolio/job and correct duration.
- A03: Given two stored skills, when one is removed and saved, then the request includes that ID with _destroy and reload contains only the retained skill.
- A04: Given a selected taxonomy row, when saved, then canonical string ID and exclusion scope are preserved.
- A05: Given empty, invalid-level, unexpected or fabricated-evidence output, when generation runs, then it fails visibly and preserves the prior result; valid grounded output persists accurately and atomically.
- A06: Given partial coverage, when analyzer supplies no supporting update, then it remains partial; two-probe forward-only rules remain enforced.
- A07: Given invalid invite or fatal transport failure, then a retry/error state appears without a recording-success claim.
- A08: Given a comparison with expected level three, then Required displays L3 and override provenance is explicit.
- A09: Given a non-assessor token, when subscribing to coverage, then it is denied even within the same organization.

- A10: Stale termination callers and old disconnect timers do not end/queue a refreshed session twice; distinct transcript turns are preserved. Pending portfolio delivery survives a queue outage and is retried automatically.
- A15: Login derives organization from server-owned user membership. Unbound users and mismatched requested organizations cannot mint credentials.

## Design

Use explicit joins through the session tenant at result boundaries, keeping background access independent of HTTP request context. Validate completion inside a locked session transaction. Validate full AI response identity, type/range, confidence and candidate-quote grounding before replacing rows inside a transaction. Remove count-only coverage promotion. Track persisted removal tombstones in edit forms and preserve string IDs. Separate failure from completion in frontend state. Add regression checks at request, DB service and UI payload boundaries. Tests use controlled provider output for repeatability; live audio/provider suitability requires separate verification.

Changes must reference this spec, acceptance and design in PR metadata. Tests must exercise persisted effects or observable behavior. Release readiness also reads the machine-readable risk register; a green regression suite alone cannot erase open P1 risks.
