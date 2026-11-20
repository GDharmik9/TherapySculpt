export interface BaselineStats {
  count: number;
  missingCount: number;
  mean: number | null;
  populationStandardDeviation: number | null;
  insufficientData: boolean;
}

const presentValues = (values: readonly (number | undefined)[]): number[] => values.filter((value): value is number => value !== undefined && Number.isFinite(value));

/** Missing observations are excluded; they are never imputed. */
export function baselineMean(values: readonly (number | undefined)[]): number | null {
  const present = presentValues(values);
  return present.length === 0 ? null : present.reduce((sum, value) => sum + value, 0) / present.length;
}

/** Uses population variance (divide by N), not sample variance. */
export function populationStandardDeviation(values: readonly (number | undefined)[]): number | null {
  const present = presentValues(values);
  if (present.length < 2) return null;
  const mean = present.reduce((sum, value) => sum + value, 0) / present.length;
  return Math.sqrt(present.reduce((sum, value) => sum + (value - mean) ** 2, 0) / present.length);
}

/** Returns null when there is no usable baseline, fewer than two observations, or zero variance. */
export function zScoreDelta(currentValue: number, baseline: readonly (number | undefined)[]): number | null {
  if (!Number.isFinite(currentValue)) return null;
  const mean = baselineMean(baseline);
  const standardDeviation = populationStandardDeviation(baseline);
  return mean === null || standardDeviation === null || standardDeviation === 0 ? null : (currentValue - mean) / standardDeviation;
}

export function calculateBaselineStats(values: readonly (number | undefined)[]): BaselineStats {
  const present = presentValues(values);
  return {
    count: present.length,
    missingCount: values.length - present.length,
    mean: baselineMean(values),
    populationStandardDeviation: populationStandardDeviation(values),
    insufficientData: present.length < 2
  };
}