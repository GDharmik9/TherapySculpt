# PostgreSQL security policy artifact

This is the reviewed PostgreSQL policy source. It is intentionally not wired into Prisma migrations. Apply only after DBA, security, and clinical compliance review.

```sql
-- TherapySculpt challenge/demo artifact. Review and adapt before deployment.
-- This file is intentionally not wired into Prisma migrations.

ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ConsentLedger" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ScreeningAssessment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ClinicalEncounter" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "AuditLog" ENABLE ROW LEVEL SECURITY;

-- Employer, HR, and commercial insurer roles must never read individual health data.
CREATE POLICY therapysculpt_user_employer_firewall ON "User"
  AS RESTRICTIVE FOR ALL
  USING (current_setting('app.actor_role', true) NOT IN ('EMPLOYER', 'HR', 'INSURER'))
  WITH CHECK (current_setting('app.actor_role', true) NOT IN ('EMPLOYER', 'HR', 'INSURER'));

CREATE POLICY therapysculpt_assessment_employer_firewall ON "ScreeningAssessment"
  AS RESTRICTIVE FOR ALL
  USING (current_setting('app.actor_role', true) NOT IN ('EMPLOYER', 'HR', 'INSURER'));

CREATE POLICY therapysculpt_encounter_employer_firewall ON "ClinicalEncounter"
  AS RESTRICTIVE FOR ALL
  USING (current_setting('app.actor_role', true) NOT IN ('EMPLOYER', 'HR', 'INSURER'));

-- Audit rows are append-only for application roles. Controlled retention/deletion is a reviewed DBA operation.
CREATE POLICY therapysculpt_audit_append_only ON "AuditLog"
  FOR INSERT
  WITH CHECK ("appendOnly" = true AND "retentionUntil" >= "createdAt");

CREATE POLICY therapysculpt_audit_no_update ON "AuditLog"
  FOR UPDATE USING (false);

CREATE POLICY therapysculpt_audit_no_delete ON "AuditLog"
  FOR DELETE USING (false);
```
