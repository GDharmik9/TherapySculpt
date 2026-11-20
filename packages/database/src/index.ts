export const DATABASE_REGION = 'uaenorth';
export const AUDIT_RETENTION_YEARS = 25;
export type EmployerFirewallRole = 'EMPLOYER' | 'HR' | 'INSURER';
export function isEmployerFirewallRole(role: string): role is EmployerFirewallRole { return ['EMPLOYER', 'HR', 'INSURER'].includes(role); }

export interface AuditMetadataInput {
	userId?: string;
	actorId: string;
	action: string;
	resourceType: string;
	resourceId?: string;
	payloadHash: string;
	previousTamperHash?: string;
	createdAt?: Date;
}

export interface AuditMetadata extends AuditMetadataInput {
	retentionUntil: Date;
	appendOnly: true;
}

export function auditRetentionDate(createdAt: Date = new Date()): Date {
	const retentionUntil = new Date(createdAt);
	retentionUntil.setUTCFullYear(retentionUntil.getUTCFullYear() + AUDIT_RETENTION_YEARS);
	return retentionUntil;
}

export function buildTamperHashInput(metadata: AuditMetadataInput): string {
	return [metadata.previousTamperHash ?? '', metadata.actorId, metadata.action, metadata.resourceType, metadata.resourceId ?? '', metadata.payloadHash, (metadata.createdAt ?? new Date(0)).toISOString()].join('|');
}

export function createAuditMetadata(input: AuditMetadataInput): AuditMetadata {
	const createdAt = input.createdAt ?? new Date();
	return { ...input, createdAt, retentionUntil: auditRetentionDate(createdAt), appendOnly: true };
}