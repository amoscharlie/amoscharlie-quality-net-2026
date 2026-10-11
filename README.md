# Skill Review Quality Net

Independent two-service assessment platform: Rails REST/WebSocket API with PostgreSQL and Redis/Sidekiq; React/TypeScript browser with Vite. Configure assessment skills, invite a candidate, record an interview, generate an evidence-backed portfolio, review/override levels, compare a vacancy and export results.

Start with [local setup](assessment/setup-local.md). Ruby 3.3.2, Bundler 2.5.11, Node 22.12+, PostgreSQL and Redis are required. Do not use macOS system Ruby or commit local credentials.

Assessment deliverables:

- [Audit and final finding dispositions](assessment/01-audit.md)
- [Quality system, checks and CI evidence](assessment/02-quality-system.md)
- [Version-bound release decision](assessment/03-release-decision.md)
- [Release candidate notes](assessment/releases/v1.0.0-rc.1.md)
- [Defense learning guide](assessment/04-defense-guide.md)
- [Final submission review](assessment/05-submission-review.md)

Production release is BLOCKED by open P1 R01 (automatic termination stalls) and incomplete real provider/voice acceptance. Deterministic checks deliberately run offline and do not claim model suitability or audio timing.
