'use client';

import Link from 'next/link';
import { Shield } from 'lucide-react';

export default function UnauthorizedPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 w-full max-w-md text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-red-100 dark:bg-red-900/30 mb-4">
          <Shield className="text-red-600 dark:text-red-400" size={32} />
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">غير مصرح</h1>
        <p className="text-gray-500 dark:text-gray-400 mb-6">
          ليس لديك صلاحية للوصول إلى هذه الصفحة. هذه اللوحة مخصصة للمشرفين فقط.
        </p>
        <Link
          href="/login"
          className="inline-block bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition"
        >
          العودة إلى تسجيل الدخول
        </Link>
      </div>
    </div>
  );
}
