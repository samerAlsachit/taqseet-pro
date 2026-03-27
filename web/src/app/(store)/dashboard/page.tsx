'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

interface DashboardStats {
  total_customers: number;
  active_installments: number;
  due_today: number;
  overdue: number;
  today_collection: number;
}

export default function DashboardPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [storeName, setStoreName] = useState('');
  const [expiringWarning, setExpiringWarning] = useState(false);
  const [daysRemaining, setDaysRemaining] = useState(0);
  const [stats, setStats] = useState<DashboardStats>({
    total_customers: 0,
    active_installments: 0,
    due_today: 0,
    overdue: 0,
    today_collection: 0
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
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold text-navy">لوحة التحكم</h1>
            <div className="text-text-primary">
              مرحباً بك في {storeName}
            </div>
          </div>
        </div>
      </div>

      {/* تنبيه انتهاء الاشتراك */}
      {expiringWarning && (
        <div className="bg-warning/20 border border-warning rounded-lg p-4 mb-6 flex justify-between items-center">
          <div>
            <p className="font-bold text-warning">⚠️ تنبيه هام</p>
            <p className="text-text-primary">
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
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <p className="text-text-primary text-sm mb-1">إجمالي العملاء</p>
            <p className="text-3xl font-bold text-navy">{stats.total_customers}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-success">
            <p className="text-text-primary text-sm mb-1">الأقساط النشطة</p>
            <p className="text-3xl font-bold text-navy">{stats.active_installments}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-warning">
            <p className="text-text-primary text-sm mb-1">مستحقة اليوم</p>
            <p className="text-3xl font-bold text-navy">{stats.due_today}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-danger">
            <p className="text-text-primary text-sm mb-1">متأخرات</p>
            <p className="text-3xl font-bold text-navy">{stats.overdue}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <p className="text-text-primary text-sm mb-1">تحصيلات اليوم</p>
            <p className="text-3xl font-bold text-navy">{stats.today_collection.toLocaleString()} IQD</p>
          </div>
        </div>

        {/* قائمة سريعة */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <Link href="/customers/new" className="bg-white hover:bg-gray-50 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">👤+</div>
            <span className="text-text-primary">إضافة عميل</span>
          </Link>
          <Link href="/installments/new" className="bg-white hover:bg-gray-50 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">💰+</div>
            <span className="text-text-primary">قسط جديد</span>
          </Link>
          <Link href="/products/new" className="bg-white hover:bg-gray-50 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">📦+</div>
            <span className="text-text-primary">منتج جديد</span>
          </Link>
          <Link href="/payments/new" className="bg-white hover:bg-gray-50 p-4 rounded-xl shadow-sm text-center transition">
            <div className="text-2xl mb-2">💵+</div>
            <span className="text-text-primary">تسديد دفعة</span>
          </Link>
        </div>

        {/* آخر الأقساط */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-navy">آخر الأقساط</h2>
            <Link href="/installments" className="text-electric hover:underline text-sm">
              عرض الكل
            </Link>
          </div>
          {recentInstallments.length === 0 ? (
            <p className="text-text-primary text-center py-8">لا توجد أقساط مسجلة</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">العميل</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المنتج</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المبلغ</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المتبقي</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الحالة</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold"></th>
                  </tr>
                </thead>
                <tbody>
                  {recentInstallments.map((item: any) => (
                    <tr key={item.id} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4 text-text-primary">{item.customer_name}</td>
                      <td className="py-3 px-4 text-text-primary">{item.product_name}</td>
                      <td className="py-3 px-4 text-text-primary">{item.total_price?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4 text-text-primary">{item.remaining_amount?.toLocaleString()} IQD</td>
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
