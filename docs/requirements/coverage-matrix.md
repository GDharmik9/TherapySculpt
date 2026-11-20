# Coverage matrix

| Requirement | Evidence |
|---|---|
| Safety-critical deterministic math | `packages/clinical-core`, clinical tests |
| Crisis lockout | `crisis.ts`, `cssrs.ts`, Gate 2 tests |
| UAE/privacy boundary | Prisma schema, policy artifact, security docs |
| Bilingual resources | `packages/therapy-content/src/resources.ts` |
| Preserve unused work | `.cursor/rules/04-preservation-and-cycle.mdc`, `CONTRIBUTING.md`, `docs/not-using/` |
| Traceability | `docs/requirements/initial-details-traceability.md` |