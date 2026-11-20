import type { CareTier } from './crisis.js';
import { EMERGENCY_ROUTES } from './crisis.js';

/** A deliberately small safety screen, not the full C-SSRS assessment. */
export interface CssrsSubsetInput {
  wishToBeDead?: boolean;
  suicidalThoughts?: boolean;
  suicidalIntent?: boolean;
  selfHarmBehavior?: boolean;
}

export interface CssrsSubsetResult {
  instrument: 'C-SSRS-SUBSET';
  isFullAssessment: false;
  positiveSignals: string[];
  criticalFlag: boolean;
  careTier: CareTier;
  navigationLocked: boolean;
  generativeAILocked: boolean;
  emergencyRoutes: typeof EMERGENCY_ROUTES;
  dispatchSlaMinutes: 15;
  nonDiagnostic: { means: string; doesNotMean: string };
}

export function screenCssrsSubset(input: CssrsSubsetInput): CssrsSubsetResult {
  const positiveSignals = [
    input.wishToBeDead ? 'WISH_TO_BE_DEAD' : undefined,
    input.suicidalThoughts ? 'SUICIDAL_THOUGHTS' : undefined,
    input.suicidalIntent ? 'SUICIDAL_INTENT' : undefined,
    input.selfHarmBehavior ? 'SELF_HARM_BEHAVIOR' : undefined
  ].filter((signal): signal is string => signal !== undefined);
  const criticalFlag = positiveSignals.length > 0;
  return {
    instrument: 'C-SSRS-SUBSET',
    isFullAssessment: false,
    positiveSignals,
    criticalFlag,
    careTier: criticalFlag ? 'TIER_4' : 'TIER_1',
    navigationLocked: criticalFlag,
    generativeAILocked: criticalFlag,
    emergencyRoutes: criticalFlag ? EMERGENCY_ROUTES : [],
    dispatchSlaMinutes: 15,
    nonDiagnostic: {
      means: 'A small safety-screen signal that warrants human review and immediate support when positive.',
      doesNotMean: 'This is not a full C-SSRS assessment, diagnosis, risk prediction, or substitute for a trained clinician.'
    }
  };
}