# Data

Prisma models cover users, independent consent, assessments, encounters, and audit records. `packages/database/prisma/policies/security.sql` is a deployment-reviewed PostgreSQL artifact, not an automatic migration.

Health data and compute are intended for approved UAE regions. Missing observations are not imputed. Audit records require append-only semantics, chained tamper hashes, and 25-year retention metadata.