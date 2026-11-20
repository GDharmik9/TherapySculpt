# TherapySculpt documentation

TherapySculpt is a challenge/demo scaffold for UAE-localized stepped-care mental-wellbeing support. These docs describe the current additive implementation, its safety boundaries, and items intentionally deferred. They do not certify clinical, legal, security, or deployment readiness.

## Map

- `architecture/`: system shape and design constraints
- `frontend/`, `backend/`, `data/`: implementation guidance
- `setup/`: local setup and environment reference
- `cloud/`: UAE deployment planning and checklist
- `security/`: compliance posture and threat model
- `operations/`: runbooks and observability
- `decisions/`: architecture decision records
- `requirements/`: traceability from `initial_details.md`
- `implementation-summary.md`: consolidated record of completed work, boundaries, and validation
- `phase1.md`: detailed interactive client-experience requirements
- `Phase_details.md`: multi-phase execution roadmap from interactive UX through demo packaging
- `not-using/`: deliberately deferred capabilities
- `archive/`: how superseded material is retained

## Next implementation cycle

The next planned cycle is **Phase 1: Interactive Client Experiences**. Its detailed requirements are in `phase1.md`, and its cross-phase sequencing is in `Phase_details.md`.

The default entry point is the patient interactive screener and Gate 2 crisis-lock flow in `apps/web-patient`. The clinician triage queue and 15-minute SLA timer are the alternate first entry point. Whichever entry point is selected must follow: **inspect -> plan -> additive change -> test -> docs -> review**.

Keep unused or superseded material aside; do not remove it without explicit approval.