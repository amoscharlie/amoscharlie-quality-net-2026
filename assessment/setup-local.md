# Local setup

Use Ruby 3.3.2, Bundler 2.5.11, Node 22.12+ (Node 22 in CI), PostgreSQL 17 and Redis. System macOS Ruby 2.6 cannot install/run this bundle; use rbenv, not sudo gem installation. The frontend test runner requires a supported modern Node version.

From `api/`:

```sh
rbenv install -s 3.3.2
gem install bundler -v 2.5.11
bundle install
cp config/application.yml.sample config/application.yml
```

Set DB_USERNAME to your PostgreSQL role, DB_HOST to localhost, REDIS_URL to your local Redis, a new SECRET_KEY_BASE, ALLOWED_ORIGINS to http://localhost:5173 and APP_BASE_URL to http://localhost:5173. Development/test database names are platform_development/platform_test; their skill_review schema is created by migrations. Local application.yml is ignored; never commit credentials.

```sh
bundle exec rails db:create db:migrate db:seed
LOCAL_ADMIN_EMAIL=owner@example.test LOCAL_ADMIN_PASSWORD='choose-a-long-local-password' bundle exec rails runner script/setup_local_admin.rb
WEB_CONCURRENCY=0 bundle exec rails server -b 127.0.0.1 -p 3001
```

Run the worker in another terminal from `api/`:

```sh
bundle exec sidekiq -C config/sidekiq.yml
```

The local account must be bound to a server-owned organization (default seed: test-corp). Old unbound accounts cannot log in; an owner must provision membership. Public self-registration is not supported by the API. Passwords in this guide are placeholders, not seeded public credentials.

From `web/`:

```sh
npm ci
cp .env.example .env.local
npm run dev
```

Use VITE_API_BASE_URL=http://localhost:3001/api/v1 and VITE_WS_BASE_URL=ws://localhost:3001. Open http://localhost:5173 and sign in with the provisioned local admin. Existing local credentials may be in an ignored .local-credentials.json created during setup.

Verify:

```sh
# from api/
RAILS_ENV=test bundle exec rails db:create db:migrate
RAILS_ENV=test bundle exec rspec
# from web/
npm test
npm run build
# from repository root
node --test assessment/check-gate.test.mjs assessment/check-release.test.mjs
node assessment/check-gate.mjs
node assessment/check-release.mjs
```

The last command deliberately returns a failure while any critical acceptance check is pending. It is a release decision, not a broken regression suite.

Voice interview requires a real GEMINI_API_KEY and available live/analysis/pro models. Inherited model names must be checked against the provider account. Deterministic CI does not call the paid provider. Authenticated REST/UI smoke, Live handshake/transcript and one portfolio regenerate were observed. The full coverage/termination/review/comparison/export acceptance flow remains unverified.

## Explicit provider model decision (2026-10-11)

Inherited local analysis `gemini-2.5-flash` and portfolio `gemini-2.5-pro` returned HTTP 404 for this account. Model listing alone did not establish generateContent access. Ignored local configuration uses the exact model identifier `gemini-3.8-flash` for GEMINI_FLASH_MODEL and GEMINI_PRO_MODEL: an earlier actual generateContent probe succeeded and portfolio regeneration completed. This is an account-specific observed configuration, not a universal recommended model or a committed default. A subsequent verification probe returned HTTP 503; present provider availability is therefore unverified. Keep runtime errors visible and retain transcript for retry.

This compatibility issue is documented under A13 as a setup/runtime dependency decision, separate from R01 (the P1 failure to terminate safely when analysis fails). Do not mark live acceptance passed from model listing, one regeneration, or deterministic CI. Check the exact configured model with a minimal authenticated generateContent request, without logging keys, before a live demo. For defense: 404 establishes an unavailable model/configuration for the tested account; 503 is a later service failure, not evidence that the identifier changed.
