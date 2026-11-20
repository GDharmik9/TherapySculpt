import { describe, expect, it } from 'vitest';
import { baselineMean, calculateBaselineStats, evaluateGate2, populationStandardDeviation, scoreGAD7, scorePHQ2, scorePHQ9, scoreSCOFF, screenCssrsSubset, zScoreDelta } from './index';

describe('PHQ-2 screening', () => {
  it('scores deterministically and remains non-diagnostic', () => {
    expect(scorePHQ2([2, 1])).toMatchObject({ instrument: 'PHQ-2', rawScore: 3, severity: 'MILD', answered: 2, missingItems: 0 });
    expect(scorePHQ2([3, undefined]).nonDiagnostic.doesNotMean).toContain('not a diagnosis');
  });
});

describe('small C-SSRS safety subset', () => {
  it('produces Gate 2-compatible lockout output for positive signals', () => {
    expect(screenCssrsSubset({ suicidalIntent: true })).toMatchObject({ instrument: 'C-SSRS-SUBSET', isFullAssessment: false, careTier: 'TIER_4', criticalFlag: true, navigationLocked: true, generativeAILocked: true });
  });
  it('does not escalate an entirely negative subset', () => {
    expect(screenCssrsSubset({})).toMatchObject({ criticalFlag: false, careTier: 'TIER_1', emergencyRoutes: [] });
  });
});

describe('longitudinal baseline utilities', () => {
  it('uses present values only and does not impute missing data', () => {
    expect(baselineMean([1, undefined, 3])).toBe(2);
    expect(populationStandardDeviation([1, 3])).toBe(1);
    expect(zScoreDelta(3, [1, 3])).toBe(1);
    expect(calculateBaselineStats([1, undefined, 3])).toMatchObject({ count: 2, missingCount: 1, mean: 2, populationStandardDeviation: 1, insufficientData: false });
  });
  it('returns null for insufficient or zero-variance baselines', () => {
    expect(populationStandardDeviation([2])).toBeNull();
    expect(zScoreDelta(3, [2, 2])).toBeNull();
  });
});

describe('deterministic severity boundaries', () => {
  it.each([[4, 'MINIMAL'], [5, 'MILD'], [9, 'MILD'], [10, 'MODERATE'], [14, 'MODERATE'], [15, 'MODERATELY_SEVERE'], [19, 'MODERATELY_SEVERE'], [20, 'SEVERE']])('PHQ-9 score %s is %s', (score, severity) => {
    expect(scorePHQ9(Array.from({ length: 9 }, (_, i) => i < Math.floor(score / 3) ? 3 : i === Math.floor(score / 3) ? score % 3 : 0)).severity).toBe(severity);
  });
  it.each([[4, 'MINIMAL'], [5, 'MILD'], [9, 'MILD'], [10, 'MODERATE'], [14, 'MODERATE'], [15, 'SEVERE']])('GAD-7 boundary %s is %s', (score, severity) => {
    expect(scoreGAD7(Array.from({ length: 7 }, (_, i) => i < Math.floor(score / 3) ? 3 : i === Math.floor(score / 3) ? score % 3 : 0)).severity).toBe(severity);
  });
  it('scores SCOFF yes answers without guessing missing answers', () => {
    expect(scoreSCOFF([true, true, undefined, false, false])).toMatchObject({ rawScore: 2, missingItems: 1, severity: 'MILD' });
  });
});

describe('Gate 2 crisis safety', () => {
  it('locks out on PHQ-9 question 9 even without text', () => {
    expect(evaluateGate2({ phq9Question9: 1 })).toMatchObject({ careTier: 'TIER_4', criticalFlag: true, navigationLocked: true, generativeAILocked: true });
  });
  it('detects Arabic crisis language and exposes emergency routes', () => {
    const result = evaluateGate2({ freeText: 'أفكر في الانتحار' });
    expect(result.criticalFlag).toBe(true);
    expect(result.crisis.language).toBe('ar');
    expect(result.emergencyRoutes.some((route) => route.id === 'safety-step-6')).toBe(true);
  });
});