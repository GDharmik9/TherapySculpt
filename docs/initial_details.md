### 1. The Core Synthesis: Bridging Your Vision with the Hackathon Mandate

You have a vision for a **full-fledged doctor, therapy, and psychology application** (EHR, clinical consultation, self-tests, psychoeducational chapters, calm mind/mindfulness). The **Future Health Digital Innovation Challenge (Challenge 10: Earlier, Safer Mental-Wellbeing Support)** addresses the **screening-to-care conversion gap** in Abu Dhabi: many individuals take a test or feel distress, but stigma, fragmented clinic pathways, and fear of employer discovery prevent them from reaching care.

By uniting these two perspectives, **TherapySculpt** becomes a **Stepped-Care Continuum**:
- For the **User/Patient**, it feels like a daily wellness and calm-mind companion (self-assessments, self-help therapy chapters, mood/sleep tracking, Stanley-Brown safety planning).
- For the **Doctor & Care Team**, it functions as a clinical workstation (validated intake scores, longitudinal baseline tracking, comorbidity context for family physicians, and Malaffi HIE/FHIR compatibility).
- For the **Hackathon Evaluators**, it hits every regulatory requirement: deterministic non-diagnostic scoring, zero-latency hard-coded crisis escalation, strict UAE data localization, and an employer-blocking privacy firewall.

---

### 2. The Five Functional Pillars of the Unified Platform

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THERAPYSCULPT PLATFORM                          │
├───────────────────────────────┬────────────────────────────────────────┤
│   CONSUMER & WELLBEING SIDE   │      CLINICAL & GOVERNANCE SIDE        │
│                               │                                        │
│  [1. Calm Mind & Self-Help]   │  [4. Clinician & Doctor Portal]        │
│  • Self-guided CBT chapters   │  • Structured SOAP documentation       │
│  • Mindful regulation & audio │  • Comorbidity briefs (e.g. Diabetes)   │
│  • Psychoeducation library    │  • Teleconsultation & e-prescriptions  │
│                               │                                        │
│  [2. Validated Self-Testing]  │  [5. Middle Staff & Triage Queue]      │
│  • Deterministic PHQ-9/GAD-7  │  • Real-time risk sorting (<15m SLA)   │
│  • Longitudinal Z-score drift │  • Warm handoffs & care coordination   │
│  • Non-diagnostic explanations│  • Malaffi HIE / FHIR R4 connectivity  │
├───────────────────────────────┴────────────────────────────────────────┤
│                     [3. DETERMINISTIC CRISIS GATE]                     │
│    Hard-coded regex/keyword safety lock ──► 999 / SKMC ER / Stanley-   │
│    Brown Plan Step 6 (Zero AI generation during acute crisis)          │
└────────────────────────────────────────────────────────────────────────┘
```

#### Pillar 1: Calm Mind & Self-Help Therapy Chapters (Tier 1 Support)
- **Psychoeducational Chapters:** Structured, self-guided micro-modules rooted in Cognitive Behavioral Therapy (CBT), Acceptance and Commitment Therapy (ACT), and sleep hygiene.
- **Calm Mind Tools:** Grounding exercises (box breathing, progressive muscle relaxation, 5-4-3-2-1 sensory orientation) and audio tracks for stress regulation.
- **Low-Stigma Engagement:** Users explore exercises privately without immediate clinical labeling.

#### Pillar 2: Validated Early Identification & Self-Testing (Tier 1 to 2)
- **Standardized Batteries:** Built-in digital screeners for **PHQ-2/9** (Depression), **GAD-2/7** (Anxiety), and **SCOFF** (Eating Disorders).
- **Deterministic Math:** Pure algorithmic scoring (no LLM approximations) tracking rolling personal baselines and standard deviation shifts.
- **Transparent Communication:** Explicit disclaimers clarifying what scores indicate (e.g., *"Elevated stress over the past 14 days"*) and what they do *not* indicate (e.g., *"This is not a clinical diagnosis of Major Depressive Disorder"*).

#### Pillar 3: Deterministic Crisis Guardrail & Safety Planning (Tier 4 Gate)
- **Hard-Coded Safety Gate:** If lexical patterns or C-SSRS thresholds detect active suicidal ideation or intent, standard app navigation and generative AI lock out immediately (<150 ms).
- **Stanley-Brown Safety Plan:** Instant access to the patient's customized 6-step safety plan (warning signs, internal coping, social distractions, emergency contacts, lethal means reduction).
- **Direct Emergency Routing:** One-touch dialing for UAE Emergency (**999**), Sheikh Shakhbout Medical City (SKMC) ER, or Al Ain Hospital ER.

#### Pillar 4: Middle Staff & Triage Care Coordination (The "Missing Middle")
- **Queue Management:** Triage Nurses and Care Coordinators monitor real-time intake scores and system flags.
- **SLA Tracking:** Ensures high-risk screenings receive human contact within **15 minutes** and moderate-risk cases within **24 hours**.
- **Intake Verification:** Pre-populates clinical summaries and verifies Emirates ID before passing cases to physicians.

#### Pillar 5: Full-Fledged Doctor & Specialist Application (Tier 2 & 3 Support)
- **Doctor Consultation Suite:** Integrated video teleconsultation, appointment scheduling, and structured clinical documentation (SOAP notes, ICD-10-CM coding, DoH Drug Formulary prescriptions).
- **Physical-Mental Comorbidity Briefs:** When consented by the patient, primary care doctors see cross-condition trends (e.g., anxiety or sleep disruption impacting HbA1c control in diabetic patients).
- **Health Information Exchange:** HL7 FHIR R4 compatibility for exporting clinical summaries to **Malaffi** (Abu Dhabi HIE).

---

### 3. Scalable Monorepo Blueprint

To support web portals, mobile apps, background queues, and shared domain libraries from a single source of truth, the project utilizes **Turborepo** with **pnpm workspaces**:

```text
therapy-sculpt/
├── apps/
│   ├── web-patient/            # Next.js 15: Self-assessments, calm mind, appointments
│   ├── web-clinician/          # Next.js 15: Doctor EMR portal, SOAP notes, triage queue
│   ├── web-admin/              # Next.js 15: ADHICS audit viewer, conversion & fairness KPIs
│   ├── mobile-patient/         # React Native (Expo SDK 52): Daily check-ins, offline safety plan
│   └── api-server/             # NestJS / FastAPI: Authentication, FHIR routes, business logic
├── services/
│   ├── worker-scoring/         # BullMQ queue: Baseline calculations & Z-score analytics
│   ├── worker-crisis-dispatch/ # High-priority queue: Immediate nurse triage alert webhooks
│   └── worker-malaffi-sync/    # Outbound HL7 v2 / FHIR R4 message generator for Malaffi
├── packages/
│   ├── clinical-core/          # Pure TS: Scoring math (PHQ-9, GAD-7), C-SSRS, crisis regex
│   ├── therapy-content/        # Structured Markdown/JSON: CBT chapters, audio exercises
│   ├── contracts/              # Zod schemas & TypeScript DTOs shared across web/mobile/API
│   ├── fhir-models/            # HL7 FHIR R4 schemas (Consent, Observation, QuestionnaireResponse)
│   ├── database/               # Prisma schema, migrations, seed scripts, audit triggers
│   ├── ui-kit/                 # Tailwind CSS component library (Bilingual EN/AR RTL support)
│   └── config/                 # Shared TypeScript, ESLint, and Tailwind presets
├── turbo.json                  # Turborepo pipeline caching
└── pnpm-workspace.yaml
```

---

### 4. Implementation Steps: Building the Foundation

#### Step 1: Core Data Models & Granular Consent (`packages/database`)
1. Define the schema in Prisma/PostgreSQL:
   - **Users & Identities:** Stores patient demographic fields bound to their 15-digit Emirates ID (`784-xxxx-xxxxxxx-x`) per Federal Law 2/2019.
   - **Granular Consent Ledger (FHIR Consent):** Stores independent toggles for *Tier A* (self-reflection only), *Tier B* (tele-mental health clinician sharing), and *Tier C* (primary care comorbidity sharing).
   - **Employer Firewall Rule:** A PostgreSQL row-level security policy that rejects any query originating from corporate, employer, or commercial insurance roles.
   - **25-Year WORM Audit Log:** Append-only transaction table recording `userId`, `actorId`, `action`, `resourceId`, and `timestamp` complying with ADHICS v2 and Article 20.

#### Step 2: Deterministic Clinical & Crisis Engine (`packages/clinical-core`)
1. Implement pure, unit-tested functions for psychometric scoring:
   - **PHQ-9 & GAD-7 Calculators:** Computes raw scores, severity classifications, and baseline deltas.
   - **Signal Confidence Index:** Lowers confidence score when optional questions are skipped, rather than interpolating or guessing.
   - **Zero-Latency Crisis Guardrail:** A hard-coded matcher checking against self-harm keywords, C-SSRS triggers, and acute distress patterns in both English and Arabic.
   - **Safety Plan Generator:** Formats the 6-step Stanley-Brown Safety Plan into a localized data structure cached locally for offline availability.

#### Step 3: Self-Help & Calm Mind Repository (`packages/therapy-content`)
1. Organize modular mental health content:
   - **CBT Chapters:** Step-by-step interactive psychoeducation (Cognitive Restructuring, Thought Traps, Behavioral Activation).
   - **Mindfulness & Autonomic Reset:** Breathing exercises with visual pacing timers (4-7-8 breathing, box breathing).
   - **Resource Directory:** Curated, verified contact details for Abu Dhabi community centers, family support clinics, and national hotlines.

#### Step 4: Doctor EMR & Clinical Workstation (`apps/web-clinician`)
1. Construct the clinical workflow:
   - **Live Triage Board:** Categorizes incoming cases by risk level (Tier 1 to 4) with countdown timers tracking response SLAs (e.g., 15-minute timer for elevated flags).
   - **Clinical Encounter Documentation:** Structured SOAP note editor featuring ICD-10-CM diagnostic picker, DoH Drug Formulary dropdown, and allergy recording.
   - **Comorbidity Summary Card:** Synthesizes consented physical-mental health connections (e.g., blood glucose variability correlated with high anxiety scores) for the attending physician.

#### Step 5: Patient Mobile & Web Application (`apps/web-patient` & `apps/mobile-patient`)
1. Build the responsive interface:
   - **Bilingual Interface:** Full layout mirroring between English (LTR) and Arabic (RTL).
   - **Symptom Tracker & Journal:** Visual longitudinal charts illustrating mood and sleep trends without diagnostic jargon.
   - **One-Tap Emergency Screen:** Persistent, accessible access to the Stanley-Brown plan and immediate 999 calling.
   - **Provider Booking Engine:** Scheduling interface for asynchronous chat consults or live video appointments.

---

### 5. Architectural Alignment Check

| Feature | Your Doctor App Vision | Hackathon Requirement (Challenge 10) | TherapySculpt Unified Implementation |
| :--- | :--- | :--- | :--- |
| **Self-Tests** | Interactive intake questionnaires | Validated instruments with clear non-diagnostic context | Deterministic PHQ-9/GAD-7 engine with *"What it means / doesn't mean"* cards. |
| **Therapy Chapters** | Self-paced psychoeducation | Stepped-care navigation (Tier 1 low-intensity support) | Interactive modular CBT/mindfulness units in `packages/therapy-content`. |
| **Calm Mind** | Relaxation tools, breathing guides | Accessible self-help to alleviate clinic overload | Offline-ready breathing pacer, grounding exercises, and audio tracks. |
| **Doctor Portal** | Comprehensive EMR & consultation | Licensed human clinician in the loop as final authority | SOAP charting, e-prescriptions, comorbidity briefs, and triage board. |
| **Safety & Crisis** | Standard emergency numbers | Hard-coded risk escalation & warm human transfer | Gate 2 screen lock, Stanley-Brown plan, and 15-minute nurse alert queue. |
| **Governance** | User profiles & appointments | UAE Health Data Law & ADHICS v2 compliance | Emirates ID linkage, granular consent toggles, and employer-blocking firewall. |

---

### Next Step

To begin scaffolding the concrete codebase, which would you like to build first?
1. **The Shared Clinical Engine (`packages/clinical-core`)**: TypeScript implementation of the deterministic PHQ-9/GAD-7 scoring rules, longitudinal delta calculations, and the hard-coded crisis detection regex/logic.
2. **The Database & Consent Schema (`packages/database`)**: The complete Prisma schema defining users, Emirates ID bindings, granular FHIR Consent toggles, and the immutable ADHICS audit log.