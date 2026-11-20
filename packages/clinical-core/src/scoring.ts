export type Severity = 'MINIMAL' | 'MILD' | 'MODERATE' | 'MODERATELY_SEVERE' | 'SEVERE';
export type GADSeverity = Exclude<Severity, 'MODERATELY_SEVERE'>;
export type PHQ2Severity = Exclude<Severity, 'MODERATELY_SEVERE'>;

export interface ScoreResult<TSeverity extends string = Severity> {
  instrument: 'PHQ-2' | 'PHQ-9' | 'GAD-7' | 'SCOFF';
  rawScore: number;
  severity: TSeverity;
  answered: number;
  totalItems: number;
  missingItems: number;
  nonDiagnostic: { means: string; doesNotMean: string };
}

const clamp = (value: number, max: number): number => Math.min(max, Math.max(0, Math.trunc(value)));
const phqSeverity = (score: number): Severity => score <= 4 ? 'MINIMAL' : score <= 9 ? 'MILD' : score <= 14 ? 'MODERATE' : score <= 19 ? 'MODERATELY_SEVERE' : 'SEVERE';
const phq2Severity = (score: number): PHQ2Severity => score <= 2 ? 'MINIMAL' : score === 3 ? 'MILD' : score <= 5 ? 'MODERATE' : 'SEVERE';
const gadSeverity = (score: number): GADSeverity => score <= 4 ? 'MINIMAL' : score <= 9 ? 'MILD' : score <= 14 ? 'MODERATE' : 'SEVERE';
const normalize = (answers: readonly (number | undefined)[], max: number): number[] => answers.map((value) => value === undefined ? undefined : clamp(value, max)).filter((value): value is number => value !== undefined);

export function scorePHQ2(answers: readonly (number | undefined)[]): ScoreResult<PHQ2Severity> {
  const values = normalize(answers.slice(0, 2), 3);
  const rawScore = values.reduce((sum, value) => sum + value, 0);
  return { instrument: 'PHQ-2', rawScore, severity: phq2Severity(rawScore), answered: values.length, totalItems: 2, missingItems: 2 - values.length, nonDiagnostic: { means: 'A brief screening indication of depressive symptoms over the recent period.', doesNotMean: 'This is not a diagnosis of depression and does not replace a clinician assessment.' } };
}

export function scorePHQ9(answers: readonly (number | undefined)[]): ScoreResult {
  const values = normalize(answers.slice(0, 9), 3);
  const rawScore = values.reduce((sum, value) => sum + value, 0);
  return { instrument: 'PHQ-9', rawScore, severity: phqSeverity(rawScore), answered: values.length, totalItems: 9, missingItems: 9 - values.length, nonDiagnostic: { means: 'A screening indication of depressive symptoms over the recent period.', doesNotMean: 'This is not a diagnosis of depression or a substitute for a clinician assessment.' } };
}

export function scoreGAD7(answers: readonly (number | undefined)[]): ScoreResult<GADSeverity> {
  const values = normalize(answers.slice(0, 7), 3);
  const rawScore = values.reduce((sum, value) => sum + value, 0);
  return { instrument: 'GAD-7', rawScore, severity: gadSeverity(rawScore), answered: values.length, totalItems: 7, missingItems: 7 - values.length, nonDiagnostic: { means: 'A screening indication of anxiety symptoms over the recent period.', doesNotMean: 'This is not a diagnosis of an anxiety disorder or a substitute for a clinician assessment.' } };
}

export function scoreSCOFF(answers: readonly (boolean | undefined)[]): ScoreResult<'MINIMAL' | 'MILD' | 'MODERATE' | 'SEVERE'> {
  const values = answers.slice(0, 5).filter((value): value is boolean => value !== undefined);
  const rawScore = values.filter(Boolean).length;
  const severity = rawScore >= 4 ? 'SEVERE' : rawScore >= 3 ? 'MODERATE' : rawScore >= 2 ? 'MILD' : 'MINIMAL';
  return { instrument: 'SCOFF', rawScore, severity, answered: values.length, totalItems: 5, missingItems: 5 - values.length, nonDiagnostic: { means: 'A screening indication that eating-related concerns may warrant discussion.', doesNotMean: 'This is not a diagnosis of an eating disorder.' } };
}

export interface SignalConfidence { score: number; answeredRatio: number; missingSignals: string[]; }
export function calculateSignalConfidence(input: { answeredItems: number; totalItems: number; optionalSignals?: Record<string, boolean> }): SignalConfidence {
  const total = Math.max(1, input.totalItems);
  const answeredRatio = Math.min(1, Math.max(0, input.answeredItems / total));
  const missingSignals = Object.entries(input.optionalSignals ?? {}).filter(([, present]) => !present).map(([name]) => name);
  return { score: Math.round(answeredRatio * 80 + ((Object.keys(input.optionalSignals ?? {}).length - missingSignals.length) / Math.max(1, Object.keys(input.optionalSignals ?? {}).length)) * 20), answeredRatio, missingSignals };
}