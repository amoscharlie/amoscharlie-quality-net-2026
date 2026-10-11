# Local provider review - 2026-10-11

This is a sanitized summary of observed local development logs and database queries, not a CI run or a complete acceptance result. No key, invite token, candidate identity or transcript content is included.

## Observed evidence

- Valid configured key and Live handshake: `LIVE_SETUP_ACCEPTED`.
- Real local interview retained 26 transcript turns in session 3.
- Coverage analyzer repeatedly received HTTP 404: configured `gemini-2.5-flash` was unavailable to this account. Persisted configured coverage remained `not_yet`, probe count 0.
- AI closing phrase triggered natural-close `all_covered`. The HTTP completion guard rejected unverified coverage. Session stayed active; timeout fallback also attempted the invalid transition. User needed manual termination.
- Portfolio generation using `gemini-2.5-pro` received HTTP 404 and exhausted retries. Transcript remained available.
- Actual `generateContent` probe succeeded on `gemini-3.8-flash`. A listing alone was insufficient: listed Pro models also rejected calls.
- Only ignored local configuration was changed to use the verified model for coverage and portfolio; API and worker restarted. Existing session portfolio regenerated through the authenticated endpoint: status `complete`, error null, one skill stored.

## R01: P1 / built wrong / open

Reproduce an active interview with coverage analysis unavailable; allow the voice model to utter a closing phrase. Expected: end only with verified coverage or expose a clear failure/recovery path. Actual: closing-phrase/natural-close code sends an unverified all-covered signal, HTTP validation rejects completion, and the session/UI stalls.

Affected boundaries: `audio_websocket_middleware.rb` closing fallback/natural close/poll timeout; `audio_complete` verified-coverage guard; browser handling of preparing-to-end and rejected completion. The guard prevents a false persisted success, but orchestration remains broken. Manual end is a workaround, not a fix.

No new regression RED or code fix for R01 has been committed. Owner: Amos Charlie. Release BLOCKED. Next: regression for provider-analysis failure plus natural closing; repair terminal/error behavior without weakening coverage checks; rerun CI and full live acceptance.

Successful local regenerate does not establish semantic scoring accuracy, complete coverage, review/override, comparison/export, load capacity or the tagged candidate's provider configuration. Immutable rc.1 remains unchanged.
