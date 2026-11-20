'use client';

import { useMemo, useState } from 'react';
import { evaluateGate2, scoreGAD7, scorePHQ9, type Gate2Result } from '@therapy-sculpt/clinical-core';
import { EmergencyLockOverlay } from './crisis/EmergencyLockOverlay';

type Instrument = 'PHQ-9' | 'GAD-7';
type Answer = number | undefined;

const scale = [
  { value: 0, en: 'Not at all', ar: 'أبداً' },
  { value: 1, en: 'Several days', ar: 'لعدة أيام' },
  { value: 2, en: 'More than half the days', ar: 'أكثر من نصف الأيام' },
  { value: 3, en: 'Nearly every day', ar: 'كل يوم تقريباً' },
];

const questions = {
  'PHQ-9': [
    ['Little interest or pleasure in doing things', 'قلة الاهتمام أو المتعة في القيام بالأشياء'],
    ['Feeling down, depressed, or hopeless', 'الشعور بالحزن أو الاكتئاب أو اليأس'],
    ['Trouble sleeping or sleeping too much', 'صعوبة النوم أو النوم أكثر من اللازم'],
    ['Feeling tired or having little energy', 'الشعور بالتعب أو قلة الطاقة'],
    ['Poor appetite or overeating', 'ضعف الشهية أو الإفراط في الأكل'],
    ['Feeling bad about yourself', 'الشعور بالسوء تجاه نفسك'],
    ['Trouble concentrating', 'صعوبة التركيز'],
    ['Moving or speaking slowly, or feeling restless', 'بطء الحركة أو الكلام أو الشعور بالتململ'],
    ['Thoughts that you would be better off dead or of hurting yourself', 'أفكار بأنك أفضل حالاً ميتاً أو بإيذاء نفسك'],
  ],
  'GAD-7': [
    ['Feeling nervous, anxious, or on edge', 'الشعور بالتوتر أو القلق'],
    ['Not being able to stop or control worrying', 'عدم القدرة على إيقاف القلق أو التحكم به'],
    ['Worrying too much about different things', 'القلق المفرط بشأن أمور مختلفة'],
    ['Trouble relaxing', 'صعوبة الاسترخاء'],
    ['Being so restless it is hard to sit still', 'التململ الشديد وصعوبة الجلوس بهدوء'],
    ['Becoming easily annoyed or irritable', 'سهولة الانزعاج أو سرعة الغضب'],
    ['Feeling afraid as if something awful might happen', 'الشعور بالخوف من حدوث أمر سيئ'],
  ],
} as const;

export function InteractiveScreener({ locale }: { locale: 'en' | 'ar' }) {
  const [instrument, setInstrument] = useState<Instrument>('PHQ-9');
  const [answers, setAnswers] = useState<Answer[]>(Array(9).fill(undefined));
  const [current, setCurrent] = useState(0);
  const [result, setResult] = useState<{ phq: ReturnType<typeof scorePHQ9>; gad: ReturnType<typeof scoreGAD7>; gate: Gate2Result }>();
  const isArabic = locale === 'ar';
  const items = questions[instrument];
  const answer = answers[current];
  const progress = Math.round(((current + 1) / items.length) * 100);

  const labels = useMemo(() => isArabic
    ? { title: 'فحص ذاتي تفاعلي', choose: 'اختر أداة الفحص', next: 'التالي', back: 'السابق', skip: 'أفضل عدم الإجابة', submit: 'عرض النتيجة', means: 'ماذا تعني النتيجة؟', notMeans: 'ماذا لا تعني؟', confidence: 'مؤشر اكتمال الإجابات', tier: 'مسار الدعم المقترح', tier1: 'الدعم الذاتي والتمارين الهادئة', tier2: 'دعم CBT موجّه', tier3: 'إحالة إلى مختص', note: 'هذه أداة فحص وليست تشخيصاً.' }
    : { title: 'Interactive self-screening', choose: 'Choose a screening tool', next: 'Next', back: 'Back', skip: 'Prefer not to answer', submit: 'View result', means: 'What it means', notMeans: 'What it does not mean', confidence: 'Answer completeness', tier: 'Suggested support pathway', tier1: 'Self-care and calm-mind tools', tier2: 'Guided CBT support', tier3: 'Specialist referral', note: 'This is a screening tool, not a diagnosis.' }, [isArabic]);

  function chooseInstrument(next: Instrument) {
    setInstrument(next);
    setAnswers(Array(next === 'PHQ-9' ? 9 : 7).fill(undefined));
    setCurrent(0);
    setResult(undefined);
  }

  function submit() {
    const phqAnswers = instrument === 'PHQ-9' ? answers : Array(9).fill(undefined);
    const gadAnswers = instrument === 'GAD-7' ? answers : Array(7).fill(undefined);
    const phq = scorePHQ9(phqAnswers);
    const gad = scoreGAD7(gadAnswers);
    const gate = evaluateGate2({ phq9Question9: phqAnswers[8] });
    setResult({ phq, gad, gate });
  }

  const currentQuestion = items[current];
  return <main style={{ maxWidth: 760, margin: '0 auto', padding: 24 }}>
    <h1>{labels.title}</h1>
    <p>{labels.note}</p>
    <label htmlFor="instrument">{labels.choose}</label>
    <select id="instrument" value={instrument} onChange={(event) => chooseInstrument(event.target.value as Instrument)} style={{ display: 'block', margin: '8px 0 24px', padding: 10 }}>
      <option value="PHQ-9">PHQ-9 — Depression symptoms</option>
      <option value="GAD-7">GAD-7 — Anxiety symptoms</option>
    </select>
    <div aria-label={`${progress}% complete`} style={{ height: 10, background: '#e5e7eb', borderRadius: 999, marginBottom: 24 }}><div style={{ width: `${progress}%`, height: '100%', background: '#2563eb', borderRadius: 999 }} /></div>
    <section aria-live="polite" style={{ border: '1px solid #cbd5e1', borderRadius: 14, padding: 24 }}>
      <p><strong>{instrument}</strong> · {current + 1}/{items.length}</p>
      <h2>{currentQuestion[locale]}</h2>
      <div style={{ display: 'grid', gap: 10 }}>
        {scale.map((option) => <label key={option.value} style={{ display: 'flex', gap: 10, alignItems: 'center', padding: 12, border: '1px solid #d1d5db', borderRadius: 8 }}><input type="radio" name={`question-${current}`} checked={answer === option.value} onChange={() => setAnswers((previous) => previous.map((value, index) => index === current ? option.value : value))} />{option[locale]}</label>)}
        <label style={{ display: 'flex', gap: 10, alignItems: 'center', padding: 12, border: '1px dashed #94a3b8', borderRadius: 8 }}><input type="radio" name={`question-${current}`} checked={answer === undefined} onChange={() => setAnswers((previous) => previous.map((value, index) => index === current ? undefined : value))} />{labels.skip}</label>
      </div>
    </section>
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 20 }}>
      <button type="button" disabled={current === 0} onClick={() => setCurrent((value) => value - 1)}>{labels.back}</button>
      {current < items.length - 1 ? <button type="button" onClick={() => setCurrent((value) => value + 1)}>{labels.next}</button> : <button type="button" onClick={submit}>{labels.submit}</button>}
    </div>
    {result && <section style={{ marginTop: 28, display: 'grid', gap: 12 }}>
      <article style={{ padding: 18, background: '#eff6ff', borderRadius: 12 }}><h2>{labels.means}</h2><p>{instrument === 'PHQ-9' ? `${result.phq.severity}: ${result.phq.nonDiagnostic.means}` : `${result.gad.severity}: ${result.gad.nonDiagnostic.means}`}</p></article>
      <article style={{ padding: 18, background: '#f8fafc', borderRadius: 12 }}><h2>{labels.notMeans}</h2><p>{instrument === 'PHQ-9' ? result.phq.nonDiagnostic.doesNotMean : result.gad.nonDiagnostic.doesNotMean}</p></article>
      <p><strong>{labels.confidence}:</strong> {instrument === 'PHQ-9' ? `${result.phq.answered}/${result.phq.totalItems}` : `${result.gad.answered}/${result.gad.totalItems}`} {labels.tier}: {result.gate.criticalFlag ? 'TIER_4 — immediate human support' : (instrument === 'PHQ-9' && result.phq.rawScore >= 15) || (instrument === 'GAD-7' && result.gad.rawScore >= 15) ? labels.tier3 : (instrument === 'PHQ-9' && result.phq.rawScore >= 5) || (instrument === 'GAD-7' && result.gad.rawScore >= 5) ? labels.tier2 : labels.tier1}</p>
    </section>}
    {result?.gate.criticalFlag && <EmergencyLockOverlay locale={locale} gate={result.gate} />}
  </main>;
}
