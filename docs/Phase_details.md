Based on the **`implementation-summary.md`**, the repository has established a solid architectural foundation:
- The **Turborepo monorepo** compiles cleanly across all 14 workspace tasks.
- **`packages/clinical-core`** contains pure deterministic scoring (PHQ-2/9, GAD-7, SCOFF, C-SSRS subset), Gate 2 crisis evaluation, the Stanley-Brown data model, and longitudinal math.
- **`packages/database`**, **`contracts`**, and **`fhir-models`** define the data models, Emirates ID binding, granular Tier A/B/C consent, employer isolation, and 25-year audit logging.
- The web apps (`web-patient`, `web-clinician`, `web-admin`), `mobile-patient`, `api-server`, and workers exist as structured scaffolds.

To progress smoothly while adhering to the repository's governance rule (**`inspect -> plan -> additive change -> test -> docs -> review`** without breaking existing builds or removing code), here is the detailed execution plan for the next development cycles.

---

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       THERAPYSCULPT NEXT PHASES                             │
├───────────────────────────────┬─────────────────────────────────────────────┤
│  PHASE 1: INTERACTIVE UX      │  PHASE 2: API & DATA PIPELINES              │
│  • Patient PWA interactive UI │  • Fastify route handlers & middleware      │
│  • Clinician triage & SOAP    │  • BullMQ event dispatching                 │
│  • Admin audit & equity cards │  • Synthetic database seed engine           │
├───────────────────────────────┼─────────────────────────────────────────────┤
│  PHASE 3: INTEGRATION TESTS   │  PHASE 4: HACKATHON DEMO PACKAGING          │
│  • Employer firewall tests    │  • Challenge 10 narrative & golden path     │
│  • Gate 2 <150ms recall tests │  • Submission deck & live walk-through      │
│  • Consent enforcement tests  │  • Clinician & legal review checklists      │
└───────────────────────────────┴─────────────────────────────────────────────┘
```

---

### Phase 1: Interactive Client Experiences (Bringing Scaffolds to Life)

*Objective: Turn static route scaffolds into fully functional, bilingual (English & Arabic RTL) interactive interfaces connected to `@therapy-sculpt/clinical-core` and `@therapy-sculpt/therapy-content`.*

#### 1.1 Patient Application (`apps/web-patient`)
1. **Interactive Stepped Screener Flow (`/screeners`):**
   - Multi-step questionnaire for PHQ-9 and GAD-7 using logical layout classes (`ms-`, `me-`).
   - Client-side deterministic evaluation via `evaluateScreener`: instant non-diagnostic summary display (*"What this means / What this does NOT mean"*) with zero diagnostic labeling.
2. **Interactive Calm Mind Pacing Suite (`/calm-mind`):**
   - SVG/Canvas animated visual breathing pacers for **Box Breathing (4-4-4-4)** and **4-7-8 Breathing** configured in `packages/therapy-content`.
   - Step-by-step interactive **5-4-3-2-1 Sensory Grounding** exercise with tactile step completion.
3. **Collaborative Stanley-Brown Safety Plan (`/safety-plan`):**
   - 6-step accordion interface (Warning Signs, Coping Strategies, Social Distractions, Trusted Contacts, Professionals, Lethal Means Safety).
   - LocalStorage offline caching so patients can access their safety plan even without network connectivity.
4. **Emergency Screen Lock Component (`EmergencyLockOverlay.tsx`):**
   - Modal triggered when Gate 2 detects acute crisis (PHQ-9 Q9 > 0 or crisis regex).
   - Locks standard navigation, presents 1-touch calling for **UAE 999**, **SKMC ER**, and **Al Ain Hospital ER**, and displays Step 6 (Means Safety).
5. **Granular Consent Management Center (`/consent`):**
   - Interactive toggle switches for **Tier A** (Self-reflection only), **Tier B** (Tele-mental health clinician), and **Tier C** (Primary Care GP / Malaffi HIE).
   - Clear explanations of data boundary isolation and revocation timestamps.

#### 1.2 Clinician Portal (`apps/web-clinician`)
1. **Real-Time Stepped Triage Queue (`/triage-board`):**
   - Visual Kanban/table categorizing patients across Tiers 1–4.
   - High-visibility banner and animated countdown timer for the **15-minute response SLA** on Tier 4 / Gate 2 crisis alerts.
2. **Clinical Workstation & SOAP Charting (`/consultations`):**
   - Intake view pre-populated with deterministic screening scores and longitudinal baseline delta graphs.
   - Structured SOAP note editor featuring searchable ICD-10-CM diagnostic picker and DoH Drug Formulary medication selectors.
3. **Physical-Mental Comorbidity Brief (`/comorbidity-brief`):**
   - Consented view for family medicine GPs correlating chronic physical indicators (e.g., Type 2 Diabetes HbA1c/glycemic drift) with mental distress trends (e.g., GAD-7 anxiety spikes).
4. **Malaffi HIE Preview (`/malaffi-sync`):**
   - Inspector showing the generated HL7 FHIR R4 Bundle (`QuestionnaireResponse`, `Observation`, `Consent`) ready for outbound sync.

#### 1.3 Governance & Administration Portal (`apps/web-admin`)
1. **25-Year WORM Audit Trail Inspector (`/audit-ledger`):**
   - Filterable table displaying actor IDs, actions, resource targets, and SHA-256 tamper-chain verification badges.
2. **Conversion & Health Equity Dashboard (`/fairness-kpis`):**
   - Visual charts tracking the screening-to-care conversion rate and demographic parity across age bands, gender, and nationality.

---

### Phase 2: API Gateway & Data Integration (`apps/api-server` & `packages/database`)

*Objective: Connect the web frontends to persistent storage and background workers while enforcing UAE statutory firewalls.*

1. **Fastify Route Controllers:**
   - `POST /api/v1/screeners/submit`: Validates incoming payload with `@therapy-sculpt/contracts`, invokes deterministic scoring, saves to Prisma `ScreeningAssessment`, creates a chained `AuditLog` entry, and returns the result.
   - `POST /api/v1/crisis/evaluate`: Immediate sub-150ms evaluation. If acute crisis is flagged, persists alert, dispatches BullMQ job to `worker-crisis-dispatch`, and returns the emergency directives.
   - `GET /api/v1/consent` & `PUT /api/v1/consent`: Manages Tier A/B/C state with cryptographic signature hashing.
   - `GET /api/v1/triage/queue`: Returns prioritized clinical queue filtered by clinician facility and assigned tiers.
2. **Employer & Insurer Isolation Middleware:**
   - Fastify pre-handler hook inspecting request claims: unconditionally rejects requests with `403 Forbidden` if `role === 'EMPLOYER'` or `role === 'INSURER'` when querying clinical endpoints (Federal Law 2/2019 Art. 16).
3. **Comprehensive Database Seed Script (`packages/database/prisma/seed.ts`):**
   - Creates verified mock personas:
     - 1 Triage Nurse, 1 Family Medicine GP, 1 Psychiatrist.
     - 4 Patient personas representing Tier 1 (minimal distress), Tier 2 (mild anxiety + CBT user), Tier 3 (diabetic comorbidity + consented Tier C), and Tier 4 (acute crisis trigger).
     - Realistic longitudinal score histories and chained audit logs.

---

### Phase 3: Integration Testing & Verification

*Objective: Establish programmatic proof of safety, recall, and compliance without relying on subjective assertions.*

1. **Gate 2 Recall & Latency Benchmark:**
   - Automated tests running 50+ bilingual English and Arabic crisis permutations (direct suicidal intent, lethality, farewell statements) ensuring **100% recall** and execution speed under 150 ms.
2. **Employer Firewall Negative Tests:**
   - Automated integration tests verifying that corporate or HR tokens cannot read individual assessment records or clinical notes under any route combination.
3. **Consent Revocation Enforcement Tests:**
   - Tests confirming that when a patient revokes Tier B or Tier C consent, clinician queries immediately return masked/redacted data.

---

### Phase 4: Hackathon Presentation & Demonstration Packaging

*Objective: Package the platform for high-impact evaluation during the Future Health Challenge judging.*

1. **The "Golden Path" Live Demonstration Script:**
   - **Step 1 (Consumer Wellbeing):** Patient opens PWA, does a 4-4-4-4 box breathing exercise, reads a CBT thought-trap chapter, and takes a self-assessment.
   - **Step 2 (Safety Intervention):** Patient submits an acute distress phrase or Question 9 > 0. The UI instantly locks (<150ms), reveals UAE 999 calling, and presents Stanley-Brown Step 6.
   - **Step 3 (The Missing Middle):** Clinician portal receives a live WebSocket alert with a 15-minute SLA countdown timer.
   - **Step 4 (Stepped Clinical Care):** GP opens the comorbidity brief showing consented diabetic-anxiety drift and generates an FHIR R4 Malaffi bundle.
   - **Step 5 (Statutory Governance):** Admin opens the audit ledger proving 25-year immutable logging and employer firewall enforcement.
2. **Submission Presentation Deck:**
   - Structure a clear slide deck highlighting problem statement, clinical safety architecture, stepped-care conversion metrics, and DoH / Malaffi regulatory alignment.

---

### Recommended Next Step

To begin **Phase 1**, should we build the **Patient Interactive Screener & Crisis Lock Flow** (`apps/web-patient`), or wire up the **Clinician Real-Time Triage Queue with the 15-minute SLA timer** (`apps/web-clinician`)?