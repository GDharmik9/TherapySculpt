# TherapySculpt

TherapySculpt is a challenge/demo scaffold for a UAE-localized stepped-care mental-wellbeing platform. It combines calm-mind content, deterministic screening, clinician triage, consented FHIR exchange, and a hard-coded crisis safety gate.

## Important disclaimer

This repository is **not legally certified, clinically validated, or production-ready**. It requires review by licensed clinicians, UAE legal and privacy specialists, security engineers, data-protection officers, and deployment teams before use with real people or health data. Emergency information must be verified for the target deployment.

## Start

1. Install Node.js 20+ and pnpm 9+.
2. Copy `.env.example` to a deployment-specific environment file; keep all health data and compute in an approved UAE region such as `uaenorth`.
3. Run `pnpm install`.
4. Run `pnpm test:clinical`, then `pnpm build`.

The API is intentionally minimal and uses deterministic `@therapy-sculpt/clinical-core` functions. No LLM is used for scoring or risk-tier selection.

## Workspace map

- `packages/clinical-core`: pure scoring, bilingual crisis detection, emergency routes, and safety plan model.
- `packages/contracts`: Zod request/response contracts and role firewall.
- `packages/database`: Prisma data model for Emirates identity, consent, encounters, assessments, and append-only audit records.
- `packages/fhir-models`: minimal FHIR R4 interfaces.
- `packages/therapy-content`: bilingual CBT and calming content.
- `packages/ui-kit`: small React RTL-aware safety components.
- `apps/*`: patient, clinician, admin, mobile, and API entrypoints.
- `services/*`: queue worker entrypoints with documented responsibilities.

## Clinical safety shape

PHQ-9 Question 9 above zero or a bilingual acute-crisis pattern forces `TIER_4`, `criticalFlag: true`, disables general navigation/AI, exposes UAE emergency routes and Safety Plan Step 6, and creates a 15-minute triage-dispatch responsibility. This scaffold does not replace human clinical judgment or emergency services.