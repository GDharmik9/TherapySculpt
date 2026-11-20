
***

```markdown
# MISSION PROMPT: THERAPYSCULPT — PHASE 1: INTERACTIVE CLIENT EXPERIENCES

You are an expert Principal Frontend Engineer and Healthcare Systems Specialist working in the `TherapySculpt` monorepo.
Your task is to implement **Phase 1: Interactive Client Experiences**, transforming the current static page scaffolds across `apps/web-patient`, `apps/web-clinician`, and `apps/web-admin` into fully interactive, production-quality, bilingual (English & Arabic RTL) web experiences.

---

## 1. ABSOLUTE REPOSITORY & CLINICAL RULES (DO NOT VIOLATE)

1. **Preservation Rule (Additive Changes Only):**
   - Follow the cycle: `inspect -> plan -> additive change -> test -> docs -> review`.
   - Never remove existing code, documentation, or configuration. If augmenting a scaffold, build upon the existing exports without breaking existing interfaces.
2. **Deterministic Evaluation (DECIDE-AI Standard):**
   - Never introduce LLM calls or probabilistic scoring for psychometrics.
   - All scoring must use pure functions imported directly from `@therapy-sculpt/clinical-core` (`evaluateScreener`, `evaluateGate2Crisis`, `calculateLongitudinalDelta`).
3. **Gate 2 Crisis Escalation Precedence:**
   - Any acute crisis trigger (PHQ-9 Question 9 > 0, C-SSRS active ideation, or crisis regex matches) must instantly mount `<EmergencyLockOverlay />`, halt normal navigation, surface one-touch emergency calling (**UAE 999**, **SKMC ER**, **Al Ain Hospital ER**), and render Step 6 (Means Safety) of the Stanley-Brown plan.
4. **Bilingual & RTL-First UI Standard:**
   - Full support for English (LTR) and Arabic (RTL).
   - Use Tailwind logical layout properties (`ms-`, `me-`, `start-`, `end-`, `text-start`, `text-end`) instead of hardcoded directional classes (`ml-`, `mr-`, `pl-`, `pr-`, `left-`, `right-`).
5. **Role & Tenant Isolation:**
   - No patient wellbeing data may ever be exposed to employer, HR, or commercial insurance roles (Federal Law 2/2019 Art. 16).

---

## 2. DETAILED DELIVERABLES FOR PHASE 1

### PART A: PATIENT APPLICATION (`apps/web-patient`)

#### 1. Interactive Stepped Screener Flow (`app/[lang]/screeners/page.tsx`)
- **Instruments:** Support both **PHQ-9** (Depression, 9 items) and **GAD-7** (Anxiety, 7 items).
- **Step-by-Step UX:**
  - Render an accessible, card-based question-by-question wizard with a smooth progress bar.
  - Frequency scale options: `0` (Not at all / أبداً), `1` (Several days / لعدة أيام), `2` (More than half the days / أكثر من نصف الأيام), `3` (Nearly every day / كل يوم تقريباً).
  - Include an explicit "Prefer not to answer" option where clinically permissible, which decrements the `signalConfidence` index rather than interpolating values.
- **Evaluation & Result Cards:**
  - On submission, call `evaluateScreener()` from `@therapy-sculpt/clinical-core`.
  - Display the dual-card explainer:
    - **What it means:** e.g., *"Mild elevated situational stress over the past 14 days."*
    - **What it does NOT mean:** e.g., *"This is NOT a formal psychiatric diagnosis of Major Depressive Disorder."*
  - Display stepped-care routing recommendations (Tier 1 self-care, Tier 2 guided CBT, or Tier 3 specialist referral).
- **Crisis Hook:** If PHQ-9 Question 9 is scored > 0, immediately trigger the Gate 2 Emergency Lock overlay.

#### 2. Interactive Calm Mind Suite (`app/[lang]/calm-mind/page.tsx`)
- Import exercise configurations from `@therapy-sculpt/therapy-content`.
- **Visual Breathing Pacers (Canvas or Animated SVG):**
  - **Box Breathing (4-4-4-4):** Visual square with an expanding/contracting indicator guiding Inhale (4s), Hold (4s), Exhale (4s), Hold (4s) with Arabic and English verbal cues.
  - **4-7-8 Relaxing Breath:** Visual pacer with rhythmic cycle counters and audio chimes (or visual pulse).
  - Include play/pause controls, cycle counters, and haptic feedback simulation.
- **5-4-3-2-1 Sensory Grounding Tool:**
  - Interactive tactile checklist stepping through the 5 senses (5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 positive self-affirmation).
- **CBT Psychoeducational Micro-Chapters:**
  - Render modular, expandable markdown units (Thought Traps, Cognitive Restructuring, Behavioral Activation) with interactive reflection inputs.

#### 3. Collaborative Stanley-Brown Safety Plan (`app/[lang]/safety-plan/page.tsx`)
- **6-Step Digitized Accordion / Wizard:**
  - Step 1: Personalized Warning Signs (internal thoughts, moods, behaviors).
  - Step 2: Internal Coping Strategies (breathing, walks, grounding without contacting another person).
  - Step 3: People and Social Settings that Provide Distraction.
  - Step 4: People I Can Ask for Help (trusted friends/family).
  - Step 5: Professionals and Agencies (Clinicians, UAE 999, SKMC ER).
  - Step 6: Making the Environment Safe (reducing access to lethal means).
- **Offline & Encryption Features:**
  - Persist plan locally in encrypted `localStorage` / IndexedDB with a visual "Available Offline" indicator.
  - One-tap "Export Crisis Card" (generates a compact emergency summary view).

#### 4. Gate 2 Emergency Screen Lock Component (`components/crisis/EmergencyLockOverlay.tsx`)
- Triggered automatically if `isCrisis === true`.
- Locks viewport scroll and backdrop with a high-contrast emergency treatment.
- Displays verified UAE emergency actions:
  - **999 (National Emergency / Police & Ambulance)** with direct `tel:999` link.
  - **Sheikh Shakhbout Medical City (SKMC)** Psychiatric ER: `tel:023144444`.
  - **Al Ain Hospital** Psychiatric Emergency: `tel:037022000`.
- Renders **Step 6 (Lethal Means Safety)** of the Stanley-Brown plan front-and-center.
- Shows notification badge: *"A licensed crisis coordinator has been notified (15-min SLA)."*

#### 5. Granular Consent Management Hub (`app/[lang]/consent/page.tsx`)
- Three explicit, interactive toggles bound to `@therapy-sculpt/contracts`:
  - **Tier A:** Self-reflection only (local baseline, zero clinician sharing).
  - **Tier B:** Tele-mental health clinician sharing (enables remote consultations).
  - **Tier C:** Primary Care Comorbidity HIE (Malaffi sharing for family GPs).
- Include an explicit visual badge: *"Employer & HR Firewall Active — Your employer or insurer can never view this data."*
- Provide instantaneous revocation with timestamp updates.

---

### PART B: CLINICIAN PORTAL (`apps/web-clinician`)

#### 1. Live Stepped Triage Queue (`app/[lang]/triage-board/page.tsx`)
- Multi-column triage board stratified by **Tier 1 (Minimal)**, **Tier 2 (Mild)**, **Tier 3 (Moderate/Severe)**, and **Tier 4 (Acute Crisis)**.
- **Urgent SLA Countdown Timer:**
  - For any Tier 4 / Gate 2 card, display an animated 15-minute countdown clock showing elapsed time since trigger.
  - Color-code urgency (Green < 5m, Yellow 5-10m, Red > 10m).
- Action buttons on each triage card: "Initiate Warm Video Call", "Assign to Social Worker", "Export Intake Brief".

#### 2. Clinical Consultation Suite & SOAP Charting (`app/[lang]/consultations/page.tsx`)
- Pre-populated intake header showing:
  - Verified Emirates ID mask (`784-****-*******-1`).
  - Latest PHQ-9, GAD-7 scores and longitudinal Z-score drift graph.
- Structured SOAP Editor:
  - **Subjective:** Intake notes and patient-reported check-in history.
  - **Objective:** Consented wearable metrics (resting HR, sleep duration trends) and vital signs.
  - **Assessment:** Searchable multi-select for ICD-10-CM codes (e.g., `F41.1 GAD`, `F32.1 MDD`, `E11 Type 2 Diabetes`).
  - **Plan:** Integrated DoH Drug Formulary dropdown (generic medication names, dosages, durations).
- "Sign & Sync to Malaffi" action button triggering FHIR bundle generation.

#### 3. Physical-Mental Comorbidity Brief (`app/[lang]/comorbidity-brief/page.tsx`)
- Specifically tailored for Ambulatory Healthcare Services (AHS) Family Medicine GPs.
- Visual dual-axis trend chart: plots blood glucose (HbA1c / fasting glucose) or resting heart rate against GAD-7 anxiety spikes over a 90-day window.
- Clinical interpretation card explaining how treating psychological distress can mitigate metabolic fluctuations.

#### 4. Malaffi HIE Preview Inspector (`app/[lang]/malaffi-sync/page.tsx`)
- Side-by-side view showing the raw clinical record and the corresponding valid **HL7 FHIR R4 Bundle JSON**:
  - `FHIR QuestionnaireResponse` (LOINC 44249-1 for PHQ-9).
  - `FHIR Observation` (Mental health screening score).
  - `FHIR Consent` (Documenting patient-approved Tier C sharing).

---

### PART C: GOVERNANCE & ADMIN PORTAL (`apps/web-admin`)

#### 1. 25-Year Immutable Audit Trail Inspector (`app/[lang]/audit-ledger/page.tsx`)
- Filterable, searchable data grid rendering `AuditLog` records:
  - Columns: Timestamp (ISO & UAE Gulf Standard Time), Actor ID, Clinician License #, Target User Hash, Action (`READ_CHART`, `GATE2_TRIGGER`, `REVOKE_CONSENT`), and Chained SHA-256 Tamper Hash.
  - Tamper verification indicator showing cryptographic integrity of the chain.

#### 2. Screening-to-Care Conversion & Fairness Dashboard (`app/[lang]/fairness-kpis/page.tsx`)
- Metric cards showing:
  - **Screening-to-Care Conversion Rate (%):** Tracking drop-off from positive screener to completed intake.
  - **Triage Response Median Time:** Tracking adherence to the 15-minute SLA.
  - **Demographic Parity Index:** Breakdown of screening accuracy, usage, and referral equity across age brackets (youth, working adult, geriatric), genders, and nationalities.

---

## 3. IMPLEMENTATION & CODE QUALITY REQUIREMENTS

1. **Shared Components:** Reuse shared UI primitives from `packages/ui-kit` where available, or build them additively in `packages/ui-kit/src` so both patient and clinician apps share a unified design language.
2. **State Management:** Use clean React state, URL search params for localized tabs, and optimistic UI updates for consent toggles.
3. **Mock Data Layer:** Provide rich, clinically realistic mock data in a shared mock service or within the app directories so all views display populated charts, timelines, and queues during demo mode.
4. **Verification Step:**
   - Run `pnpm build` and `pnpm test` via Turborepo after implementation.
   - Confirm that all workspace packages compile with zero TypeScript errors.

Begin step-by-step: inspect the existing routes, build the missing interactive views, connect the deterministic clinical engine, and ensure full English/Arabic bidirectional support.
```

***

