'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

interface DashboardStats {
  total_customers: number;
  active_installments: number;
  due_today: { IQD: number; USD: number };
  overdue: { IQD: number; USD: number };
  today_collection: { IQD: number; USD: number };
}

export default function DashboardPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [storeName, setStoreName] = useState('');
  const [expiringWarning, setExpiringWarning] = useState(false);
  const [daysRemaining, setDaysRemaining] = useState(0);
  const [isTrial, setIsTrial] = useState(false);
  const [trialDaysLeft, setTrialDaysLeft] = useState(0);
  const [stats, setStats] = useState<DashboardStats>({
    total_customers: 0,
    active_installments: 0,
    due_today: { IQD: 0, USD: 0 },
    overdue: { IQD: 0, USD: 0 },
    today_collection: { IQD: 0, USD: 0 }
  });
  const [recentInstallments, setRecentInstallments] = useState<any[]>([]);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    const fetchData = async () => {
      try {
        // جلب بيانات المحل والمستخدم
        const meRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const meData = await meRes.json();
        if (meData.success) {
          setStoreName(meData.data.store?.name || 'المحل');
          
          // التحقق من الفترة التجريبية
          if (meData.data.subscription?.is_trial) {
            setIsTrial(true);
            setTrialDaysLeft(meData.data.subscription.trial_days_remaining);
          }
          
          // التحقق من انتهاء الاشتراك
          const daysRemaining = meData.data.subscription?.days_remaining;
          if (daysRemaining !== null && daysRemaining <= 7) {
            setExpiringWarning(true);
            setDaysRemaining(daysRemaining);
          }
        }

        // جلب إحصائيات Dashboard
        const statsRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/dashboard/stats`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const statsData = await statsRes.json();
        if (statsData.success) {
          setStats(statsData.data);
        }

        // جلب آخر الأقساط
        const installmentsRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/installments?limit=5`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const installmentsData = await installmentsRes.json();
        if (installmentsData.success) {
          setRecentInstallments(installmentsData.data.installments || []);
        }
      } catch (error) {
        console.error('خطأ في جلب البيانات', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-bg">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-bg">
      {/* Header */}
      <div className="bg-[var(--card-bg)] border-b border-[var(--border-color)] sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold text-navy dark:text-white">لوحة التحكم</h1>
            <div className="text-[var(--text-primary)]">
              مرحباً بك في {storeName}
            </div>
          </div>
        </div>
      </div>

      {/* تحذير الفترة التجريبية */}
      {isTrial && (
        <div className={`rounded-lg p-4 mb-6 ${trialDaysLeft <= 3 ? 'bg-red-50 border border-danger' : 'bg-yellow-50 border border-warning'}`}>
          <div className="flex justify-between items-center flex-wrap gap-4">
            <div>
              <p className="font-bold text-warning">⚠️ فترة تجريبية</p>
              <p className="text-[var(--text-primary)]">
                أنت حالياً في الفترة التجريبية. متبقي <span className="font-bold">{trialDaysLeft}</span> يوم.
                {trialDaysLeft <= 3 && (
                  <span className="block text-danger font-medium mt-1">
                    يرجى الاشتراك لتجنب انقطاع الخدمة!
                  </span>
                )}
              </p>
            </div>
            <Link
              href="/settings"
              className="bg-electric text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition"
            >
              اشتراك
            </Link>
          </div>
        </div>
      )}

      {/* تنبيه انتهاء الاشتراك */}
      {expiringWarning && (
        <div className="bg-warning/20 border border-warning rounded-lg p-4 mb-6 flex justify-between items-center">
          <div>
            <p className="font-bold text-warning">⚠️ تنبيه هام</p>
            <p className="text-[var(--text-primary)]">
              اشتراكك على وشك الانتهاء خلال {daysRemaining} أيام. يرجى التواصل مع الدعم لتجديد الاشتراك.
            </p>
          </div>
          <button
            onClick={() => window.open('https://wa.me/966500000000', '_blank')}
            className="bg-success text-white px-4 py-2 rounded-lg"
          >
            تواصل مع الدعم
          </button>
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        {/* بطاقات الإحصائيات */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6 mb-8">
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <p className="text-[var(--text-primary)]/70 text-sm mb-1">إجمالي العملاء</p>
            <p className="text-3xl font-bold text-[var(--text-navy)]">{stats.total_customers}</p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-success">
            <p className="text-[var(--text-primary)]/70 text-sm mb-1">الأقساط النشطة</p>
            <p className="text-3xl font-bold text-[var(--text-navy)]">{stats.active_installments}</p>
          </div>
          
          {/* تحصيلات اليوم */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">تحصيلات اليوم</p>
            {stats?.today_collection?.IQD > 0 && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {stats.today_collection.IQD.toLocaleString()} IQD
              </p>
            )}
            {stats?.today_collection?.USD > 0 && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {stats.today_collection.USD.toLocaleString()} USD
              </p>
            )}
            {(!stats?.today_collection?.IQD && !stats?.today_collection?.USD) && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">0</p>
            )}
          </div>

          {/* المستحقة اليوم */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-warning">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">مستحقة اليوم</p>
            {stats?.due_today?.IQD > 0 && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {stats.due_today.IQD.toLocaleString()} IQD
              </p>
            )}
            {stats?.due_today?.USD > 0 && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {stats.due_today.USD.toLocaleString()} USD
              </p>
            )}
            {(!stats?.due_today?.IQD && !stats?.due_today?.USD) && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">0</p>
            )}
          </div>

          {/* المتأخرات */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-danger">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">متأخرات</p>
            {stats?.overdue?.IQD > 0 && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {stats.overdue.IQD.toLocaleString()} IQD
              </p>
            )}
            {stats?.overdue?.USD > 0 && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {stats.overdue.USD.toLocaleString()} USD
              </p>
            )}
            {(!stats?.overdue?.IQD && !stats?.overdue?.USD) && (
              <p className="text-2xl font-bold text-gray-900 dark:text-white">0</p>
            )}
          </div>
        </div>

        {/* قائمة سريعة */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <Link href="/customers/new" className="bg-[var(--card-bg)] hover:bg-gray-50 dark:hover:bg-gray-800 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">👤+</div>
            <span className="text-[var(--text-primary)]">إضافة عميل</span>
          </Link>
          <Link href="/installments/new" className="bg-[var(--card-bg)] hover:bg-gray-50 dark:hover:bg-gray-800 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">💰+</div>
            <span className="text-[var(--text-primary)]">قسط جديد</span>
          </Link>
          <Link href="/products/new" className="bg-[var(--card-bg)] hover:bg-gray-50 dark:hover:bg-gray-800 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">📦+</div>
            <span className="text-[var(--text-primary)]">منتج جديد</span>
          </Link>
          <Link href="/payments/new" className="bg-[var(--card-bg)] hover:bg-gray-50 dark:hover:bg-gray-800 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">💵+</div>
            <span className="text-[var(--text-primary)]">تسديد دفعة</span>
          </Link>
        </div>

        {/* آخر الأقساط */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-navy dark:text-white">آخر الأقساط</h2>
            <Link href="/installments" className="text-electric hover:underline text-sm">
              عرض الكل
            </Link>
          </div>
          {recentInstallments.length === 0 ? (
            <p className="text-[var(--text-primary)] text-center py-8">لا توجد أقساط مسجلة</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                    <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">العميل</th>
                    <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المنتج</th>
                    <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المبلغ</th>
                    <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المتبقي</th>
                    <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">الحالة</th>
                    <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold"></th>
                  </tr>
                </thead>
                <tbody>
                  {recentInstallments.map((item: any) => (
                    <tr key={item.id} className="border-b border-[var(--border-color)] hover:bg-gray-50 dark:hover:bg-gray-800">
                      <td className="py-3 px-4 text-[var(--text-primary)]">{item.customer_name}</td>
                      <td className="py-3 px-4 text-[var(--text-primary)]">{item.product_name}</td>
                      <td className="py-3 px-4 text-[var(--text-primary)]">{item.total_price?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4 text-[var(--text-primary)]">{item.remaining_amount?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4">
                        <span className={`px-3 py-1 rounded-full text-sm ${
                          item.status === 'active' ? 'bg-success/10 text-success' :
                          item.status === 'completed' ? 'bg-electric/10 text-electric' :
                          'bg-danger/10 text-danger'
                        }`}>
                          {item.status === 'active' ? 'نشط' : item.status === 'completed' ? 'مكتمل' : 'متأخر'}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <Link href={`/installments/${item.id}`} className="text-electric hover:underline">
                          تفاصيل
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
