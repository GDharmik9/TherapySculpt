import { calculateSignalConfidence } from '@therapy-sculpt/clinical-core';
/** Queue responsibility: longitudinal, deterministic baseline and signal-confidence jobs. */
export function processScoringJob(answeredItems: number, totalItems: number) { return calculateSignalConfidence({ answeredItems, totalItems }); }
console.info('worker-scoring ready');