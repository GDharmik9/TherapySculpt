import type { Bundle } from '@therapy-sculpt/fhir-models';
/** Queue responsibility: consent-gated FHIR R4 export inspection and UAE HIE delivery. */
export function prepareMalaffiBundle(bundle: Bundle, tierCConsent: boolean): Bundle | null { return tierCConsent ? bundle : null; }
console.info('worker-malaffi-sync ready');