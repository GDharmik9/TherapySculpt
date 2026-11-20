'use client';

import { useEffect } from 'react';
import type { Gate2Result } from '@therapy-sculpt/clinical-core';
import { createSafetyPlan } from '@therapy-sculpt/clinical-core';

export function EmergencyLockOverlay({ locale, gate }: { locale: 'en' | 'ar'; gate: Gate2Result }) {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { document.body.style.overflow = previousOverflow; };
  }, []);

  const isArabic = locale === 'ar';
  const stepSix = createSafetyPlan().steps[5];
  const text = isArabic
    ? { title: 'توقف الأمان الفوري', message: 'تم اكتشاف إشارة تتطلب دعماً بشرياً فورياً. لا تستخدم الدردشة العامة الآن.', call: 'اتصل بخدمات الطوارئ في الإمارات', sla: 'تم إخطار منسق أزمات مرخص — مهلة الاستجابة 15 دقيقة', routes: 'خيارات الدعم الفوري' }
    : { title: 'Immediate safety lock', message: 'A safety signal was detected. Human and emergency support take priority now. General navigation is locked.', call: 'Call UAE emergency services', sla: 'A licensed crisis coordinator has been notified — 15-minute response SLA', routes: 'Immediate support options' };

  return <div role="alertdialog" aria-modal="true" aria-labelledby="emergency-title" style={{ position: 'fixed', inset: 0, zIndex: 50, overflowY: 'auto', background: '#fff7ed', color: '#431407', padding: 24 }}>
    <div style={{ maxWidth: 720, margin: '0 auto', border: '3px solid #c2410c', borderRadius: 16, padding: 24, background: '#ffffff' }}>
      <p style={{ fontWeight: 700, color: '#b91c1c' }}>{isArabic ? 'TIER_4 — دعم فوري' : 'TIER_4 — immediate support'}</p>
      <h2 id="emergency-title" style={{ fontSize: 32, margin: '8px 0' }}>{text.title}</h2>
      <p>{text.message}</p>
      <p style={{ fontWeight: 700 }}>{text.sla}</p>
      <h3>{text.routes}</h3>
      <div style={{ display: 'grid', gap: 12 }}>
        <a href="tel:999" style={{ display: 'block', padding: 16, borderRadius: 10, background: '#b91c1c', color: 'white', fontWeight: 700, textDecoration: 'none' }}>{text.call} — 999</a>
        {gate.emergencyRoutes.filter((route) => route.id !== 'uae-999' && route.id !== 'safety-step-6').map((route) => <div key={route.id} style={{ padding: 14, borderRadius: 10, background: '#ffedd5' }}>{route.label[locale]}<small style={{ display: 'block', marginTop: 4 }}>{isArabic ? 'تأكد من رقم المنشأة محلياً قبل الاتصال.' : 'Verify the facility number locally before calling.'}</small></div>)}
      </div>
      <section style={{ marginTop: 24, padding: 16, borderRadius: 10, background: '#fef2f2' }}>
        <h3>{stepSix.title[locale]}</h3>
        <p>{stepSix.prompts[locale][0]}</p>
      </section>
    </div>
  </div>;
}
