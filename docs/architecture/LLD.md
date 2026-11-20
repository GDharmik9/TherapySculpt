# Low-level design

- Clinical scoring: `packages/clinical-core/src/scoring.ts`
- Crisis and Gate 2: `packages/clinical-core/src/crisis.ts`
- C-SSRS bounded screen: `packages/clinical-core/src/cssrs.ts`
- Longitudinal statistics: `packages/clinical-core/src/longitudinal.ts`
- Database model: `packages/database/prisma/schema.prisma`
- Reviewed PostgreSQL policy artifact: `packages/database/prisma/policies/security.sql`
- Bilingual content/resources: `packages/therapy-content/src/`

Missing numeric answers are not imputed. Zero-variance or insufficient baselines return `null` z-score inputs. All screening output is non-diagnostic.