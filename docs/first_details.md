### 1. Master AI System Initialization Prompt

> *Copy and paste this prompt directly into your AI coding agent (Cursor Composer, Claude Code, Windsurf, or GitHub Copilot) to generate and scaffold the entire repository in one pass.*

```markdown
You are an expert Principal Healthcare Systems Architect and Full-Stack Monorepo Engineer.
You are tasked with bootstrapping and structuring "TherapySculpt", an enterprise-grade, privacy-first tele-mental health and clinical navigation platform designed for the Future Health Digital Innovation Challenge (Abu Dhabi Department of Health / Inception 42 / Microsoft Foundry, Challenge 10: Earlier, Safer Mental-Wellbeing Support).

### MISSION & ARCHITECTURAL FOUNDATION
TherapySculpt is a stepped-care tele-mental health platform closing the positive-screening-to-care conversion gap. It bridges consumer mental wellness (calm mind, self-help CBT chapters, validated self-testing) with a multi-specialty clinical workstation (doctor EMR, nurse triage queue, comorbidity briefs for family medicine, and Malaffi HIE connectivity).

You must generate a complete, high-performance Turborepo monorepo with pnpm workspaces, strict TypeScript configurations, and all required code scaffolding and developer guidelines.

### NON-NEGOTIABLE CLINICAL & STATUTORY CONSTRAINTS
1. Strict Separation of Deterministic Math & Generative AI (DECIDE-AI Standard):
   - Large Language Models (LLMs) must NEVER calculate clinical scores (PHQ-9, GAD-7, SCOFF, C-SSRS) or determine risk tiers. All scoring is deterministic pure arithmetic in TypeScript/Python.
   - LLMs are restricted strictly to generating bilingual (English and Arabic RTL) plain-language explanations ("What it means / What it does NOT mean") and consented comorbidity summaries.
2. Hard-Coded Gate 2 Crisis Escalation:
   - When self-harm or acute suicidal ideation (e.g., PHQ-9 Q9 > 0 or crisis regex) is detected, standard navigation and generative AI lock out immediately (<150 ms).
   - The UI surfaces immediate emergency actions: UAE 999 dialing, Sheikh Shakhbout Medical City (SKMC) ER, Al Ain Hospital ER, and Step 6 (Means Safety) of the digitized Stanley-Brown Safety Plan.
   - Pushes an urgent webhook alert to the middle-staff Triage Nurse queue with a 15-minute response SLA.
3. UAE Statutory Healthcare Compliance:
   - UAE ICT Health Law (Federal Law No. 2 of 2019 Art. 13 & MD 51/2021): All data and compute remain localized in the UAE (Azure UAE North / Dubai).
   - Article 16 & Cabinet Res. 32/2020: Granular, revocable FHIR Consent (Tier A: private, Tier B: tele-mental health, Tier C: family GP). Absolute tenant-level firewall blocking employers, HR, and underwriters.
   - Article 20: 25-year immutable WORM audit trail chained with cryptographic tamper hashes.
   - Article 21: Mandatory Emirates ID binding (784-xxxx-xxxxxxx-x) via UAE PASS.
   - ADHICS v2 (Abu Dhabi Healthcare Information and Cyber Security Standard): Zero-trust AES-256-GCM encryption with customer-managed keys.

Now, construct the complete monorepo skeleton, configuration files, and AI steering documentation as detailed below.
```

---

### 2. Complete Monorepo Skeleton & File Tree

This structure enforces modularity across consumer mobile applications, clinical web portals, background message brokers, and shared clinical libraries:

```text
therapy-sculpt/
├── .cursor/
│   └── rules/
│       ├── 01-clinical-governance.mdc   # Gate 2 crisis & deterministic scoring rules
│       ├── 02-uae-compliance.mdc        # Law 2/2019, ADHICS v2, Emirates ID & Consent
│       └── 03-architecture-style.mdc    # Turborepo, Next.js 15, Tailwind RTL guidelines
├── .github/
│   └── workflows/
│       ├── ci.yml                       # Linting, typecheck, Turborepo remote cache
│       └── clinical-audit.yml           # Automated check verifying 100% crisis gate test pass
├── apps/
│   ├── web-patient/                     # Next.js 15 App Router: Bilingual patient PWA
│   │   ├── app/
│   │   │   ├── [lang]/
│   │   │   │   ├── (auth)/login/        # UAE PASS authentication
│   │   │   │   ├── calm-mind/           # Breathing pacers, grounding audio, CBT chapters
│   │   │   │   ├── screeners/           # Interactive PHQ-9, GAD-7, SCOFF batteries
│   │   │   │   ├── safety-plan/         # Offline Stanley-Brown 6-step plan
│   │   │   │   ├── consent/             # Granular Tier A/B/C toggle controls
│   │   │   │   └── appointments/        # Telehealth video / async consult booking
│   │   │   └── layout.tsx
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── web-clinician/                   # Next.js 15: Doctor EMR & Nurse Triage Portal
│   │   ├── app/
│   │   │   ├── [lang]/
│   │   │   │   ├── triage-board/        # Live priority queue with 15-minute SLA timers
│   │   │   │   ├── consultations/       # SOAP notes, ICD-10-CM & DoH Formulary picker
│   │   │   │   ├── comorbidity-brief/   # Consented physical-mental summary (e.g. Diabetes)
│   │   │   │   └── malaffi-sync/        # HIE outbound FHIR bundle inspector
│   │   │   └── layout.tsx
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── web-admin/                       # Next.js 15: Governance & ADHICS Audit Portal
│   │   ├── app/
│   │   │   └── [lang]/
│   │   │       ├── audit-ledger/        # 25-year WORM immutable access trail viewer
│   │   │       └── fairness-kpis/       # Demographic disparity telemetry across age/gender
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── mobile-patient/                  # React Native (Expo SDK 52)
│   │   ├── src/
│   │   │   ├── screens/                 # Daily check-ins, offline Stanley-Brown cache
│   │   │   └── sensors/                 # Opt-in Apple Health / Health Connect signals
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── api-server/                      # NestJS / Express API Gateway
│       ├── src/
│       │   ├── modules/
│       │   │   ├── auth/                # UAE PASS OIDC & Emirates ID encryption
│       │   │   ├── screening/           # Deterministic scoring endpoint
│       │   │   ├── crisis/              # <150ms zero-latency emergency gate
│       │   │   ├── consent/             # FHIR Consent ledger & employer firewall guard
│       │   │   └── clinical/            # SOAP notes, Malaffi HL7/FHIR export
│       │   └── main.ts
│       ├── package.json
│       └── tsconfig.json
├── services/
│   ├── worker-scoring/                  # BullMQ worker: Longitudinal Z-score drift calculation
│   ├── worker-crisis-dispatch/          # High-priority queue: Urgent nurse triage alert webhooks
│   └── worker-malaffi-sync/             # Outbound HL7 v2 / FHIR R4 pipeline for Abu Dhabi HIE
├── packages/
│   ├── clinical-core/                   # PURE TS: Deterministic math, C-SSRS, crisis regex
│   │   ├── src/
│   │   │   ├── scoring/                 # PHQ-9, GAD-7, SCOFF, signal confidence index
│   │   │   ├── crisis/                  # Bilingual acute risk matcher & emergency routing
│   │   │   └── safety-plan/             # Digitized Stanley-Brown data model
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── therapy-content/                 # CBT chapters, audio transcripts, grounding exercises
│   │   ├── src/
│   │   │   ├── cbt-modules/             # Structured JSON/Markdown for psychoeducation
│   │   │   └── calm-mind/               # Pacing configurations (Box breathing, 5-4-3-2-1)
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── contracts/                       # Shared Zod DTOs, API contracts, TypeScript types
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── fhir-models/                     # HL7 FHIR R4 interfaces (Consent, Observation, CarePlan)
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── database/                        # Prisma ORM schema, migrations, seed data
│   │   ├── prisma/
│   │   │   └── schema.prisma
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── ui-kit/                          # Shared Tailwind components with LTR/RTL support
│   │   ├── src/
│   │   │   ├── components/              # Buttons, Cards, Modals, Emergency Banner
│   │   │   └── rtl-provider.tsx         # Directional layout provider (English / Arabic)
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── config/                          # Base configurations
│       ├── eslint/
│       ├── tailwind/
│       └── typescript/
├── .gitignore
├── .npmrc
├── CLAUDE.md                            # Complete steering documentation for Claude Code
├── copilot-instructions.md              # Global guidelines for GitHub Copilot
├── package.json                         # Root package.json
├── pnpm-lock.yaml
├── pnpm-workspace.yaml                  # pnpm monorepo workspace definition
├── README.md                            # Architecture, setup instructions, challenge alignment
└── turbo.json                           # Turborepo task pipeline configuration
```

---

### 3. Core Root Configuration Files

#### `package.json` (Root)
```json
{
  "name": "therapy-sculpt",
  "private": true,
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "lint": "turbo run lint",
    "test": "turbo run test",
    "test:clinical": "turbo run test --filter=@therapy-sculpt/clinical-core",
    "db:generate": "turbo run db:generate",
    "db:migrate": "turbo run db:migrate",
    "clean": "turbo run clean && rm -rf node_modules"
  },
  "devDependencies": {
    "prettier": "^3.4.2",
    "turbo": "^2.3.3",
    "typescript": "^5.7.2"
  },
  "packageManager": "pnpm@9.15.0",
  "engines": {
    "node": ">=20.0.0",
    "pnpm": ">=9.0.0"
  }
}
```

#### `pnpm-workspace.yaml`
```yaml
packages:
  - "apps/*"
  - "services/*"
  - "packages/*"
```

#### `turbo.json`
```json
{
  "$schema": "[suspicious link removed]",
  "ui": "tui",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", ".env*"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "lint": {
      "dependsOn": ["^lint"]
    },
    "test": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", "src/**/*.test.ts", "src/**/*.spec.ts"]
    },
    "db:generate": {
      "cache": false
    },
    "db:migrate": {
      "cache": false
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "clean": {
      "cache": false
    }
  }
}
```

---

### 4. Developer & AI Steering Documentation

To ensure any AI tool (Cursor, Claude Code, GitHub Copilot) writes safe, clinically sound, and compliant code, place these documentation files directly at the repository root.

#### File: `CLAUDE.md` (and `copilot-instructions.md`)
```markdown
# THERAPYSCULPT: AI ENGINEERING DIRECTIVES & CLINICAL CONTEXT

## Project Identity & Clinical Purpose
TherapySculpt is a stepped-care tele-mental health and clinical navigation platform architected for the Future Health Digital Innovation Challenge (Abu Dhabi Department of Health / Inception 42 / Microsoft Foundry, Challenge 10: Earlier, Safer Mental-Wellbeing Support).

The platform bridges consumer mental wellbeing (calm mind tools, psychoeducational CBT chapters, validated self-testing) with clinical workflows (doctor EMR, triage queues, and Malaffi HIE connectivity).

---

## 1. ABSOLUTE CLINICAL & SAFETY DIRECTIVES

### A. Strict Non-Diagnostic & Deterministic Scoring Engine
- **NEVER use LLMs to calculate psychometric scores or infer diagnostic categories.**
- All scoring for PHQ-9, GAD-7, SCOFF, and C-SSRS must execute through pure TypeScript arithmetic located in `@therapy-sculpt/clinical-core`.
- If optional inputs (e.g., wearable sleep/HRV data) are absent, reduce the `signalConfidence` index rather than hallucinating or interpolating missing values.
- All patient-facing score outputs MUST include clear educational disclaimers:
  - What it means: e.g., "Elevated situational distress over the past 14 days."
  - What it does NOT mean: "This is NOT a formal psychiatric diagnosis of Major Depressive Disorder."

### B. Zero-Latency Gate 2 Crisis Escalation (<150 ms)
- If an input matches acute crisis patterns (suicidal ideation, intent, self-harm, or PHQ-9 Question 9 > 0):
  1. Instantly halt all generative AI interactions and standard app navigation.
  2. Display the Emergency Screen Lock with one-touch dialing:
     - National Emergency: **999**
     - Sheikh Shakhbout Medical City (SKMC) Psychiatric Emergency Department (Abu Dhabi)
     - Al Ain Hospital Psychiatric Emergency Department (Al Ain)
  3. Immediately display Step 6 (Lethal Means Safety) of the user's Stanley-Brown Safety Plan.
  4. Emit a high-priority job to `worker-crisis-dispatch` to alert the on-call Triage Nurse with a **15-minute response SLA**.

---

## 2. UAE STATUTORY COMPLIANCE & DATA PRIVACY

### A. Health Data Localization (Federal Law No. 2 of 2019 Art. 13 & MD 51/2021)
- All databases, cloud clusters, background workers, and AI inference MUST reside in UAE data centers (Microsoft Azure UAE North / Dubai).
- Zero identifiable health data may leave the UAE borders.

### B. Granular Consent & Employer Isolation (Federal Law No. 2 of 2019 Art. 16)
- Maintain a revocable FHIR Consent ledger with independent toggles:
  - `tierASelfReflection`: Private longitudinal tracking only.
  - `tierBClinicianShare`: Tele-mental health clinician access.
  - `tierCPrimaryCareHIE`: Primary care comorbidity sharing (Malaffi HIE).
- **Absolute Employer Isolation:** Employers, HR dashboards, and insurers must be blocked from accessing individual wellbeing data. Queries from unauthorized corporate roles must return `403 Forbidden`.

### C. 25-Year Immutable Retention & Emirates ID Binding (Articles 20 & 21)
- Every patient record must link to a 15-digit Emirates ID (`784-xxxx-xxxxxxx-x`) authenticated via UAE PASS.
- All clinical notes, screenings, and consent updates must write to an append-only, tamper-evident audit ledger retained for 25 years.

---

## 3. CODESTYLE & MONOREPO BEST PRACTICES

- **Monorepo Management:** Turborepo with `pnpm`. Shared types belong in `packages/contracts` or `packages/fhir-models`.
- **Frontend Standard:** Next.js 15 App Router, React 19, Tailwind CSS. Every UI component must support bidirectional layouts: Left-to-Right (LTR for English) and Right-to-Left (RTL for Arabic).
- **Backend Standard:** NestJS or modular Express with strict Zod validation pipes.
- **Database Access:** Prisma client generated from `@therapy-sculpt/database`. Never run direct raw SQL bypassing audit logging.
- **Testing:** Unit test deterministic math in `@therapy-sculpt/clinical-core` with 100% test coverage on edge cases (e.g., boundary scores 4/5, 9/10, 14/15, 19/20).
```

---

#### File: `.cursor/rules/01-clinical-governance.mdc`
```markdown
---
description: Enforces deterministic psychometric math, DECIDE-AI compliance, and Gate 2 crisis escalation
globs: **/*.ts, **/*.tsx, **/*.py
---
# Clinical Governance & Crisis Safety Rules

1. Deterministic Evaluation:
   - When modifying files in `packages/clinical-core`, never introduce probabilistic or LLM-driven score estimation.
   - PHQ-9 raw scores range from 0 to 27. Severity bands: Minimal (0-4), Mild (5-9), Moderate (10-14), Moderately Severe (15-19), Severe (20-27).
   - GAD-7 raw scores range from 0 to 21. Severity bands: Minimal (0-4), Mild (5-9), Moderate (10-14), Severe (15-21).

2. Crisis Gate Execution:
   - Any score on PHQ-9 Question 9 > 0 or positive match on `ACUTE_CRISIS_PATTERNS` MUST set `careTier = 'TIER_4'` and trigger `criticalFlag = true`.
   - Never allow user chat prompts containing crisis keywords to pass through to general-purpose LLM completions.
```

---

#### File: `.cursor/rules/02-uae-compliance.mdc`
```markdown
---
description: Enforces UAE ICT Health Law (Federal Law 2/2019), ADHICS v2, and FHIR Consent
globs: **/schema.prisma, **/services/**, **/api-server/**
---
# UAE Healthcare Legal Compliance Rules

1. Data Localization:
   - All connection strings, cloud endpoints, and deployment configs must point exclusively to UAE regions (`uaenorth`).
2. Employer Firewall:
   - Inspect all API routes fetching `ScreeningAssessment` or `ClinicalEncounter`. Ensure middleware asserts that `req.user.role !== 'EMPLOYER' && req.user.role !== 'INSURER'`.
3. Audit Trails:
   - Every read, update, or export of clinical data must invoke `AuditLogService.logAccess()` with a chained SHA-256 tamper hash.
```

---

#### File: `.cursor/rules/03-architecture-style.mdc`
```markdown
---
description: Monorepo conventions, Turborepo pipelines, and bilingual RTL UI rules
globs: apps/**/*.tsx, packages/ui-kit/**/*.tsx
---
# Frontend & Architecture Conventions

1. Turborepo Package Boundaries:
   - Internal packages must use the `@therapy-sculpt/*` namespace.
   - Do not import `apps/*` from other apps or packages.
2. Bilingual & RTL Support:
   - Use logical Tailwind classes (`ms-`, `me-`, `start-`, `end-`) instead of hard-coded `ml-`, `mr-`, `left-`, `right-`.
   - Every patient-facing text string must be localized in both English and Arabic.
```

---

