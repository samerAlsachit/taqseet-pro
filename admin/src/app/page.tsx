'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function HomePage() {
  const router = useRouter();

  useEffect(() => {
    // التحقق من وجود token
    const token = localStorage.getItem('admin_token');
    
    if (token) {
      // إذا وجد token، توجيه إلى لوحة التحكم
      router.push('/dashboard');
    } else {
      // إذا لم يوجد token، توجيه إلى صفحة تسجيل الدخول
      router.push('/login');
    }
  }, [router]);

  // عرض شاشة تحميل أثناء التحقق
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center" dir="rtl">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
        <p className="mt-4 text-gray-600">جاري التحقق من الجلسة...</p>
      </div>
    </div>
  );
}
