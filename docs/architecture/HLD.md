# High-level design

TherapySculpt is a pnpm/Turborepo monorepo with patient web/mobile experiences, clinician/admin portals, a minimal API, workers, and shared packages. `packages/clinical-core` is pure deterministic TypeScript. Crisis signals produce Gate 2 lockout and human escalation; no LLM calculates scores or tiers.

Data is designed for approved UAE regions such as `uaenorth`. Consent is granular, employer/insurer access is blocked, and clinical access is audit logged. This is a challenge/demo architecture pending professional review.