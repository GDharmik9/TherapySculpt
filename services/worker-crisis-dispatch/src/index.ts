export interface CrisisDispatchJob { assessmentId: string; createdAt: string; slaMinutes: 15; priority: 'URGENT'; }
/** Queue responsibility: urgent, human triage-nurse webhook dispatch. Never invokes an LLM. */
export function createCrisisDispatchJob(assessmentId: string): CrisisDispatchJob { return { assessmentId, createdAt: new Date().toISOString(), slaMinutes: 15, priority: 'URGENT' }; }
console.info('worker-crisis-dispatch ready');