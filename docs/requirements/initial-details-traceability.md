# `initial_details.md` traceability

| Pillar/feature | Current location | Status |
|---|---|---|
| Deterministic PHQ-2/9, GAD-7, SCOFF | `packages/clinical-core/src/scoring.ts` | implemented/added |
| Bounded C-SSRS safety subset | `packages/clinical-core/src/cssrs.ts` | added |
| Gate 2 crisis lockout and emergency routes | `packages/clinical-core/src/crisis.ts` | implemented |
| Baseline and population z-score utilities | `packages/clinical-core/src/longitudinal.ts` | added |
| Safety Plan six-step model | `packages/clinical-core/src/safety-plan.ts` | implemented |
| Consent, audit, employer roles | `packages/database/prisma/schema.prisma` | implemented |
| PostgreSQL RLS and append-only artifact | `packages/database/prisma/policies/` | added/reviewed deployment required |
| Bilingual self-help content | `packages/therapy-content/src/` | implemented |
| UAE emergency/resource directory | `packages/therapy-content/src/resources.ts` | added; facilities deferred pending verification |
| Patient/clinician/admin/mobile/API scaffold | `apps/` | implemented scaffold |
| FHIR/Malaffi connectivity | `packages/fhir-models`, `services/worker-malaffi-sync` | scaffold/deferred production integration |
| Real patient data and production certification | repository-wide | deferred |

This matrix describes a challenge/demo state, not a production readiness claim.