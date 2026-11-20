export interface SafetyPlanStep { step: 1 | 2 | 3 | 4 | 5 | 6; title: { en: string; ar: string }; prompts: { en: string[]; ar: string[] }; entries: string[]; }
export interface StanleyBrownSafetyPlan { version: 'stanley-brown-1.0'; steps: SafetyPlanStep[]; }
export function createSafetyPlan(entries: Partial<Record<1 | 2 | 3 | 4 | 5 | 6, string[]>> = {}): StanleyBrownSafetyPlan {
  const labels = [
    ['Warning signs', 'علامات التحذير', 'What thoughts, feelings, or situations show that a crisis may be starting?', 'ما الأفكار أو المشاعر أو المواقف التي تشير إلى بداية الأزمة؟'],
    ['Internal coping strategies', 'استراتيجيات التكيف الداخلية', 'What can I do alone to feel safer for a short time?', 'ما الذي يمكنني فعله بمفردي لأشعر بالأمان مؤقتاً؟'],
    ['People and places for distraction', 'أشخاص وأماكن للتشتيت', 'Who or where can help me shift attention safely?', 'من أو أين يمكن أن يساعدني على تغيير انتباهي بأمان؟'],
    ['People to ask for help', 'أشخاص أطلب منهم المساعدة', 'Who can I contact directly and honestly?', 'من يمكنني الاتصال به بصراحة ووضوح؟'],
    ['Professionals and emergency contacts', 'المختصون وجهات الطوارئ', 'Which clinician, service, or emergency route will I contact?', 'بأي مختص أو خدمة أو جهة طوارئ سأتصل؟'],
    ['Means safety', 'الأمان من الوسائل الخطرة', 'How will I reduce access to anything I could use to hurt myself? Move away, ask a trusted person to secure it, and call 999 if immediate danger exists.', 'كيف سأقلل الوصول إلى أي وسيلة قد أؤذي بها نفسي؟ ابتعد عنها واطلب من شخص موثوق تأمينها واتصل بـ999 عند وجود خطر فوري.']
  ] as const;
  return { version: 'stanley-brown-1.0', steps: labels.map((label, index) => ({ step: (index + 1) as 1 | 2 | 3 | 4 | 5 | 6, title: { en: label[0], ar: label[1] }, prompts: { en: [label[2]], ar: [label[3]] }, entries: entries[(index + 1) as 1 | 2 | 3 | 4 | 5 | 6] ?? [] })) };
}