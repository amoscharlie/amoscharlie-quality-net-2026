# Web

See [complete local setup](../assessment/setup-local.md). Use Node 22.12+, `npm ci`, and the ignored `.env.local` pointing to the API on port 3001. Vite serves on 5173. `npm test` runs rendered UI and socket-outcome checks; `npm run build` checks TypeScript and creates production assets. Sign in with a server-provisioned local admin.
