import { z } from 'zod';

export const consentTiers = ['TIER_A_SELF_REFLECTION', 'TIER_B_CLINICIAN_SHARE', 'TIER_C_PRIMARY_CARE_HIE'] as const;
export const roleSchema = z.enum(['PATIENT', 'CLINICIAN', 'TRIAGE_NURSE', 'ADMIN', 'EMPLOYER', 'HR', 'INSURER']);
export const screeningSubmissionSchema = z.object({ userId: z.string().min(1), phq9: z.array(z.number().int().min(0).max(3)).length(9), gad7: z.array(z.number().int().min(0).max(3)).length(7), scoff: z.array(z.boolean()).length(5), freeText: z.string().max(2000).optional(), locale: z.enum(['en', 'ar']).default('en') });
export const crisisResultSchema = z.object({ careTier: z.literal('TIER_4'), criticalFlag: z.literal(true), navigationLocked: z.literal(true), generativeAILocked: z.literal(true), dispatchSlaMinutes: z.literal(15) });
export const consentSchema = z.object({ tierASelfReflection: z.boolean(), tierBClinicianShare: z.boolean(), tierCPrimaryCareHie: z.boolean(), revokedAt: z.coerce.date().nullable().optional() });
export type ScreeningSubmission = z.infer<typeof screeningSubmissionSchema>;
export type ConsentTiers = z.infer<typeof consentSchema>;
export type Role = z.infer<typeof roleSchema>;
export function assertClinicalDataAccess(role: Role): void { if (role === 'EMPLOYER' || role === 'HR' || role === 'INSURER') throw new Error('FORBIDDEN_CLINICAL_DATA_ACCESS'); }