export type CareTier = 'TIER_1' | 'TIER_2' | 'TIER_3' | 'TIER_4';
export const ACUTE_CRISIS_PATTERNS: readonly RegExp[] = [
  /\b(suicide|suicidal|kill myself|end my life|self[- ]?harm|hurt myself|overdose|no reason to live)\b/i,
  /انتحار|أنتحر|اقتل نفسي|إنهاء حياتي|إيذاء نفسي|أؤذي نفسي|جرعة زائدة|لا أريد أن أعيش/u
];

export interface CrisisMatch { matched: boolean; pattern?: string; language?: 'en' | 'ar'; }
export function detectAcuteCrisis(text: string): CrisisMatch {
  for (const pattern of ACUTE_CRISIS_PATTERNS) {
    if (pattern.test(text)) return { matched: true, pattern: pattern.source, language: /[\u0600-\u06ff]/u.test(text) ? 'ar' : 'en' };
  }
  return { matched: false };
}

export interface EmergencyRoute { id: string; label: { en: string; ar: string }; phone?: string; action: 'CALL' | 'OPEN_SAFETY_PLAN'; }
export const EMERGENCY_ROUTES: readonly EmergencyRoute[] = [
  { id: 'uae-999', label: { en: 'UAE emergency services', ar: 'خدمات الطوارئ في الإمارات' }, phone: '999', action: 'CALL' },
  { id: 'skmc-er', label: { en: 'Sheikh Shakhbout Medical City ER', ar: 'قسم طوارئ مدينة الشيخ شخبوط الطبية' }, action: 'CALL' },
  { id: 'al-ain-er', label: { en: 'Al Ain Hospital ER', ar: 'قسم طوارئ مستشفى العين' }, action: 'CALL' },
  { id: 'safety-step-6', label: { en: 'Safety Plan Step 6: reduce access to lethal means', ar: 'الخطوة السادسة: تقليل الوصول إلى الوسائل الخطرة' }, action: 'OPEN_SAFETY_PLAN' }
];

export interface Gate2Result { careTier: CareTier; criticalFlag: boolean; navigationLocked: boolean; generativeAILocked: boolean; crisis: CrisisMatch; emergencyRoutes: readonly EmergencyRoute[]; dispatchSlaMinutes: 15; }
export function evaluateGate2(input: { phq9Question9?: number; freeText?: string }): Gate2Result {
  const question9Positive = (input.phq9Question9 ?? 0) > 0;
  const crisis = detectAcuteCrisis(input.freeText ?? '');
  const criticalFlag = question9Positive || crisis.matched;
  return { careTier: criticalFlag ? 'TIER_4' : 'TIER_1', criticalFlag, navigationLocked: criticalFlag, generativeAILocked: criticalFlag, crisis: crisis.matched ? crisis : { matched: question9Positive, pattern: question9Positive ? 'PHQ-9_Q9_POSITIVE' : undefined }, emergencyRoutes: criticalFlag ? EMERGENCY_ROUTES : [], dispatchSlaMinutes: 15 };
}