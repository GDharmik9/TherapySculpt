# TherapySculpt implementation summary

**Status:** challenge/demo scaffold completed with additive enhancements  
**Last reviewed:** 2026-11-18  
**Repository:** TherapySculpt  
**Primary deployment intent:** UAE-localized health data and compute, with `uaenorth` used by the scaffold

> This document summarizes what has been built in the repository. It is not a clinical validation report, legal certification, security attestation, or production-readiness approval. Before use with real people or health data, obtain review from licensed clinicians, UAE legal/privacy specialists, security engineers, data-protection officers, and the deployment team.

## 1. Product and architectural intent

TherapySculpt is organized as a stepped-care mental-wellbeing platform for the screening-to-care gap. The repository combines:

- Patient-facing calm-mind, self-help, self-screening, safety-plan, consent, and appointment surfaces.
- Clinician-facing triage, consultation, comorbidity, and Malaffi/FHIR workflow surfaces.
- Administration-facing audit-ledger and fairness-KPI surfaces.
- A deterministic clinical library shared by API, workers, and user interfaces.
- A database model for identity binding, consent, screening, clinical encounters, and audit metadata.
- Bilingual English/Arabic content and RTL-aware UI foundations.
- Explicit governance rules so future changes preserve clinical safety and repository history.

The implementation favors a small, testable vertical slice over fake production integrations. Where an external service, legal control, or clinical workflow needs deployment-specific verification, it is represented as a documented boundary or scaffold rather than being presented as complete.

## 2. Repository foundation

The repository is a pnpm/Turborepo monorepo with strict TypeScript configuration.

### Root configuration

- `package.json`: workspace scripts for build, development, tests, type checking, database generation/migration, and cleaning.
- `pnpm-workspace.yaml`: includes `apps/*`, `services/*`, and `packages/*`.
- `turbo.json`: coordinates build dependencies, tests, lint/typecheck tasks, development tasks, and database tasks.
- `tsconfig.json`: shared strict TypeScript baseline.
- `.npmrc`, `.gitignore`, `.env.example`: package-management, repository hygiene, and environment guidance.
- `.github/workflows/ci.yml`: continuous integration workflow.
- `.github/workflows/clinical-audit.yml`: clinical safety test workflow.

All internal packages use the `@therapy-sculpt/*` namespace. The implementation uses Node.js 20+ and pnpm 9+.

## 3. Applications and services

### Applications

- `apps/web-patient`: Next.js App Router patient PWA scaffold with localized routes for login, calm mind, screeners, safety plan, consent, and appointments.
- `apps/web-clinician`: Next.js clinician portal scaffold with triage board, consultations, comorbidity brief, and Malaffi sync routes.
- `apps/web-admin`: Next.js governance portal scaffold with audit-ledger and fairness-KPI routes.
- `apps/mobile-patient`: Expo/React Native patient shell for daily check-ins, offline safety-plan access, and opt-in sensor integration boundaries.
- `apps/api-server`: Fastify API entrypoint exposing health and deterministic screening behavior. It validates requests through shared contracts and blocks employer, HR, and insurer roles from clinical data access.

### Worker services

- `services/worker-scoring`: deterministic signal-confidence and longitudinal scoring responsibility.
- `services/worker-crisis-dispatch`: urgent triage-nurse dispatch job shape with a 15-minute SLA and no LLM use.
- `services/worker-malaffi-sync`: outbound FHIR/Malaffi integration boundary and worker scaffold.

These services are intentionally small entrypoints. Queue providers, webhooks, identity systems, Malaffi connectivity, and operational infrastructure require deployment-specific configuration and review.

## 4. Deterministic clinical core

`packages/clinical-core` is pure TypeScript and contains no LLM calls, network calls, database access, or probabilistic score calculation.

### Screening instruments

- PHQ-2 scoring with deterministic raw totals, severity, missing-item counts, and non-diagnostic explanations.
- PHQ-9 scoring with the standard severity bands: Minimal, Mild, Moderate, Moderately Severe, and Severe.
- GAD-7 scoring with Minimal, Mild, Moderate, and Severe bands.
- SCOFF scoring with explicit missing-answer handling and non-diagnostic explanations.
- Bounded C-SSRS safety subset in `cssrs.ts`. It is explicitly marked as a subset and not a full C-SSRS assessment.

Missing answers are not guessed or interpolated. Optional signals reduce confidence instead of being fabricated.

### Crisis Gate 2

`packages/clinical-core/src/crisis.ts` implements the hard-coded crisis guardrail:

- PHQ-9 Question 9 above zero triggers the critical path.
- English and Arabic acute-crisis patterns are checked deterministically.
- A critical result becomes `TIER_4` and sets `criticalFlag: true`.
- Normal navigation is locked.
- General-purpose generative AI is locked.
- Emergency routes are exposed, including UAE 999 and Safety Plan Step 6.
- A 15-minute human triage-dispatch responsibility is returned.

The gate is designed to prioritize immediate human and emergency support. It is not an emergency service and does not replace professional clinical judgment.

### Safety plan

`packages/clinical-core/src/safety-plan.ts` provides a bilingual six-step Stanley-Brown safety-plan data model:

1. Warning signs
2. Internal coping strategies
3. People and places for distraction
4. People to ask for help
5. Professionals and emergency contacts
6. Means safety

### Longitudinal utilities

`packages/clinical-core/src/longitudinal.ts` provides deterministic:

- Baseline mean.
- Population standard deviation.
- Z-score delta.
- Missing-observation counts.
- Insufficient-data and zero-variance handling.

No clinical conclusion is inferred from a z-score by this scaffold. A clinician-reviewed interpretation layer is still required.

## 5. Shared contracts and clinical data models

### Contracts

`packages/contracts` contains shared Zod schemas and types for:

- Screening submissions.
- Consent tiers.
- Crisis responses.
- Role-based clinical-data access.
- Employer/HR/insurer firewall checks.

### FHIR models

`packages/fhir-models` contains minimal FHIR R4 interfaces for the integration boundary, including consent, observations, questionnaire responses, and bundles.

These models are interoperability scaffolding, not a complete certified FHIR implementation.

### Database

`packages/database/prisma/schema.prisma` models:

- Users and Emirates ID binding.
- Patient roles, clinician roles, triage roles, administration, employer, HR, and insurer roles.
- Revocable Tier A, Tier B, and Tier C consent toggles.
- Screening assessments and Gate 2 fields.
- Clinical encounters and SOAP-note storage boundary.
- Append-only audit records with actor, action, resource, payload hash, tamper hash, previous hash, and retention date metadata.

`packages/database/src/index.ts` provides UAE-region metadata, 25-year retention metadata, employer-firewall helpers, audit retention calculation, and tamper-hash input construction.

### Database policy artifact

The complete PostgreSQL policy source is preserved in:

- `packages/database/prisma/policies/security.postgresql.md`

It documents row-level security, employer/HR/insurer restrictions, and audit append-only protections. It is not automatically executed by Prisma. `security.sql` is retained as a compatibility pointer for tools that expect the original filename.

A DBA and security reviewer must adapt session claims, roles, migration ordering, break-glass controls, and retention operations before deployment.

## 6. Content and UI foundations

### Therapy content

`packages/therapy-content` contains bilingual:

- CBT modules for thought traps and behavioral activation.
- Box breathing and 4-7-8 breathing configurations.
- 5-4-3-2-1 grounding guidance.
- Non-diagnostic and self-help disclaimers.
- UAE resource-directory types and a verified 999 entry.
- Explicit placeholders for local facilities whose names and contact routes require verification.

### UI kit

`packages/ui-kit` provides:

- RTL/LTR provider behavior.
- Bilingual UI foundations.
- Safety/emergency component boundaries.
- Shared package-level UI conventions for patient-facing surfaces.

Logical layout direction and English/Arabic content are required for new patient-facing UI.

## 7. Governance, privacy, and safety rules

The repository includes:

- `CLAUDE.md`: clinical, privacy, architecture, and preservation directives.
- `copilot-instructions.md`: deterministic scoring, crisis precedence, role separation, bilingual UI, and preservation rules.
- `.cursor/rules/01-clinical-governance.mdc`: clinical scoring and crisis constraints.
- `.cursor/rules/02-uae-compliance.mdc`: UAE localization, employer firewall, and audit expectations.
- `.cursor/rules/03-architecture-style.mdc`: package boundaries and RTL conventions.
- `.cursor/rules/04-preservation-and-cycle.mdc`: the mandatory inspect/plan/add/test/docs/review workflow.
- `CONTRIBUTING.md`: required tests, builds, clinical review, and documentation updates.

### Preservation thumb rule

Never remove existing code, documentation, configuration, or features. If something is no longer used:

1. Keep it in place where safe, or move/copy it to `docs/archive/` only after explicit approval.
2. Add a dated note explaining what was superseded and why.
3. Do not silently overwrite user changes.
4. Follow every cycle: **inspect -> plan -> additive change -> test -> docs -> review**.

## 8. Documentation created

The `docs/` directory is organized as follows:

- `docs/architecture/`: HLD, LLD, and design principles.
- `docs/frontend/`: frontend conventions and route guidance.
- `docs/backend/`: API and service guidance.
- `docs/data/`: data, consent, audit, and FHIR guidance.
- `docs/setup/`: local development and environment reference.
- `docs/cloud/`: Azure UAE architecture and deployment checklist.
- `docs/security/`: compliance posture and threat model.
- `docs/operations/`: runbooks and observability guidance.
- `docs/decisions/`: ADRs for deterministic clinical logic, UAE localization, and employer firewall.
- `docs/requirements/`: traceability and coverage matrices against `initial_details.md`.
- `docs/not-using/`: deliberately deferred capabilities.
- `docs/archive/`: rules for retaining superseded material.
- `docs/implementation-summary.md`: this consolidated summary.

## 9. Intentionally deferred or not used

The following are intentionally not represented as production-complete:

- LLM-based clinical scoring, diagnosis, or risk-tier selection.
- Real patient data or production credentials.
- Direct production Malaffi/HIE connectivity.
- Unverified facility names, emergency contacts, or local care pathways.
- Automatic execution of PostgreSQL policy SQL.
- Production UAE PASS/OIDC integration.
- Production video consultation and e-prescribing.
- Employer or insurer access to individual wellbeing data.
- Automated clinical interpretation of longitudinal z-scores.
- Full C-SSRS assessment implementation.

These items remain documented rather than being hidden or deleted. They require explicit product, clinical, legal, security, and deployment approval.

## 10. Validation completed

The repository was validated after the additive implementation work:

- Clinical test suite: **22 tests passed**.
- Full Turborepo build: **14 of 14 workspace build tasks passed**.
- Next.js patient, clinician, and admin portals compiled successfully.
- TypeScript packages, API, mobile shell, and workers compiled successfully.
- No application code was intentionally removed.

The workspace is not currently a Git repository, so Git-based deletion/status verification is unavailable. File-level review and the preservation workflow were used instead.

## 11. Recommended next cycle

Before adding production integrations:

1. Obtain clinical review of all screening wording, thresholds, crisis routing, and safety-plan content.
2. Obtain UAE legal/privacy and security review of localization, consent, identity, audit, and employer isolation controls.
3. Add integration tests for API role blocking and Gate 2 response behavior.
4. Add a reviewed PostgreSQL migration process and test the RLS policies in a disposable UAE-approved environment.
5. Verify facility routes and emergency contacts locally before exposing them to patients.
6. Add deployment infrastructure only after the cloud readiness checklist is approved.
7. Repeat the required cycle: **inspect -> plan -> additive change -> test -> docs -> review**.
