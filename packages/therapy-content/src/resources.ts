import type { BilingualText } from './index.js';

export interface VerifiedResource {
  id: string;
  name: BilingualText;
  kind: 'EMERGENCY' | 'FACILITY_PLACEHOLDER';
  phone?: string;
  verificationStatus: 'VERIFIED_IN_THIS_SCAFFOLD' | 'REQUIRES_LOCAL_VERIFICATION';
  disclaimer: BilingualText;
}

export const verifiedResources: readonly VerifiedResource[] = [
  {
    id: 'uae-emergency-999',
    name: { en: 'UAE emergency services', ar: 'خدمات الطوارئ في الإمارات' },
    kind: 'EMERGENCY',
    phone: '999',
    verificationStatus: 'VERIFIED_IN_THIS_SCAFFOLD',
    disclaimer: { en: 'For immediate danger, call 999. Confirm local routing before production use.', ar: 'عند وجود خطر فوري اتصل بالرقم 999. يجب تأكيد التوجيه المحلي قبل الاستخدام الإنتاجي.' }
  },
  {
    id: 'uae-clinical-facilities-placeholder',
    name: { en: 'Clinically verified local facilities', ar: 'المنشآت المحلية التي تم التحقق منها سريرياً' },
    kind: 'FACILITY_PLACEHOLDER',
    verificationStatus: 'REQUIRES_LOCAL_VERIFICATION',
    disclaimer: { en: 'Facility names, routes, and contacts require clinical and local verification; no unverified phone number is supplied.', ar: 'تتطلب أسماء المنشآت وطرق الوصول وبيانات الاتصال تحققاً سريرياً ومحلياً؛ لا يتم توفير رقم هاتف غير متحقق منه.' }
  }
];