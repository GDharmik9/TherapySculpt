# TherapySculpt engineering directives

- Keep `packages/clinical-core` pure and deterministic. Never use an LLM to calculate scores or risk tiers.
- PHQ-9, GAD-7, and SCOFF are screening instruments, not diagnoses. Preserve patient-facing non-diagnostic explanations.
- PHQ-9 Q9 > 0 or a bilingual acute-crisis match must immediately produce `TIER_4`, `criticalFlag: true`, a navigation/AI lockout, emergency routes, and Safety Plan Step 6.
- Patient health data and compute are intended for approved UAE regions (`uaenorth` in this scaffold). Do not add secrets or export data outside approved boundaries.
- Tier A/B/C consent is independent and revocable. Employers, HR, and insurers must never receive individual wellbeing or clinical data.
- Clinical reads, writes, and exports require append-only audit logging with chained tamper hashes and 25-year retention policy metadata.
- Use `@therapy-sculpt/*` package boundaries, strict TypeScript, App Router pages, and logical RTL-friendly layout styles.

This is a challenge/demo scaffold. Obtain clinical, legal, security, and UAE deployment approval before production use.

- Preservation thumb rule: never remove existing code, docs, configuration, or features; keep unused items aside. Move or copy superseded material to `docs/archive/` with a dated note only after explicit approval. Each cycle follows inspect -> plan -> additive change -> test -> docs -> review.