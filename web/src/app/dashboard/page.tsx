'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

export default function DashboardPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [storeName, setStoreName] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    // جلب بيانات المحل
    const fetchStore = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          setStoreName(data.data.store?.name || 'المحل');
        }
      } catch (error) {
        console.error('خطأ في جلب البيانات', error);
      } finally {
        setLoading(false);
      }
    };

    fetchStore();
  }, [router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-bg">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-bg p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-2xl font-bold text-navy mb-2">مرحباً بك في {storeName}</h1>
        <p className="text-text-primary mb-8">لوحة التحكم الرئيسية</p>

        {/* بطاقات إحصائيات */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <p className="text-text-primary text-sm mb-1">إجمالي العملاء</p>
            <p className="text-3xl font-bold text-navy">0</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-success">
            <p className="text-text-primary text-sm mb-1">الأقساط النشطة</p>
            <p className="text-3xl font-bold text-navy">0</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-warning">
            <p className="text-text-primary text-sm mb-1">مستحقة اليوم</p>
            <p className="text-3xl font-bold text-navy">0</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-danger">
            <p className="text-text-primary text-sm mb-1">متأخرات</p>
            <p className="text-3xl font-bold text-navy">0</p>
          </div>
        </div>

        {/* قائمة سريعة */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-navy mb-4">الوصول السريع</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <a href="/customers" className="bg-gray-bg hover:bg-gray-100 p-4 rounded-lg text-center transition">
              <div className="text-2xl mb-2">👥</div>
              <span className="text-text-primary">العملاء</span>
            </a>
            <a href="/installments/new" className="bg-gray-bg hover:bg-gray-100 p-4 rounded-lg text-center transition">
              <div className="text-2xl mb-2">➕</div>
              <span className="text-text-primary">قسط جديد</span>
            </a>
            <a href="/inventory" className="bg-gray-bg hover:bg-gray-100 p-4 rounded-lg text-center transition">
              <div className="text-2xl mb-2">📦</div>
              <span className="text-text-primary">المخزن</span>
            </a>
            <a href="/reports" className="bg-gray-bg hover:bg-gray-100 p-4 rounded-lg text-center transition">
              <div className="text-2xl mb-2">📊</div>
              <span className="text-text-primary">التقارير</span>
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
