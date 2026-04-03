'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import LoadingSpinner from '@/components/ui/LoadingSpinner';
import {
  Users,
  Receipt,
  Calendar,
  AlertCircle,
  DollarSign,
  Plus,
  Package,
  CreditCard
} from 'lucide-react';

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
  const [isStoreActive, setIsStoreActive] = useState(true);
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

    const checkStoreStatus = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        
        if (data.success && data.data.store) {
          if (!data.data.store.is_active) {
            setIsStoreActive(false);
            alert('المحل غير نشط. يرجى التواصل مع الدعم.');
            // لا نقوم بتسجيل الخروج تلقائياً، فقط نعرض التحذير
          }
        }
      } catch (error) {
        console.error('خطأ في التحقق', error);
      }
    };
    
    checkStoreStatus();

    const fetchData = async () => {
      try {
        // جلب بيانات المحل والمستخدم
        const meRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const meData = await meRes.json();
        console.log('meData:', meData);
        console.log('store status:', meData.data?.store?.is_active);
        if (meData.success) {
          const store = meData.data.store;
          if (store && !store.is_active) {
            setIsStoreActive(false);
          }
          setStoreName(store?.name || 'المحل');
          
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

  // التحقق الفوري من حالة المحل
  useEffect(() => {
    const checkStoreStatus = async () => {
      const token = localStorage.getItem('token');
      if (!token) return;
      
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success && data.data.store && !data.data.store.is_active) {
          setIsStoreActive(false);
          alert('المحل غير نشط. سيتم تسجيل الخروج.');
          setTimeout(() => {
            localStorage.removeItem('token');
            router.push('/login');
          }, 3000);
        }
      } catch (error) {
        console.error('خطأ في التحقق من حالة المحل', error);
      }
    };
    
    checkStoreStatus();
    const interval = setInterval(checkStoreStatus, 30000); // كل 30 ثانية
    return () => clearInterval(interval);
  }, [router]);

  if (loading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="min-h-screen bg-[#F0F2F5] dark:bg-[#0D1117]">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">لوحة التحكم</h1>
            <div className="bg-gray-50 dark:bg-[#1C2128]">
              مرحباً بك في {storeName}
            </div>
          </div>
        </div>
      </div>

      {/* تحذير المحل غير النشط */}
      {!isStoreActive && (
        <div className="bg-red-50 dark:bg-red-900/30 border border-red-300 dark:border-red-700 rounded-lg p-4 mb-6">
          <div className="flex items-center gap-3">
            <div className="text-red-600 dark:text-red-400 text-xl">⚠️</div>
            <div>
              <p className="font-bold text-red-700 dark:text-red-400">حساب المحل غير نشط</p>
              <p className="text-red-600 dark:text-red-300 text-sm">
                حسابك غير نشط حالياً. لا يمكنك إجراء أي عمليات. يرجى التواصل مع الدعم.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* تحذير الفترة التجريبية */}
      {isTrial && (
        <div className={`rounded-lg p-4 mb-6 ${trialDaysLeft <= 3 ? 'bg-red-50 dark:bg-red-900/30 border border-red-300 dark:border-red-600' : 'bg-yellow-50 dark:bg-yellow-900/30 border border-yellow-300 dark:border-yellow-600'}`}>
          <div className="flex justify-between items-center flex-wrap gap-4">
            <div>
              <p className="font-bold text-yellow-600 dark:text-yellow-400">⚠️ فترة تجريبية</p>
              <p className="text-gray-900 dark:text-gray-200">
                أنت حالياً في الفترة التجريبية. متبقي <span className="font-bold">{trialDaysLeft}</span> يوم.
                {trialDaysLeft <= 3 && (
                  <span className="block text-red-600 dark:text-red-400 font-medium mt-1">
                    يرجى الاشتراك لتجنب انقطاع الخدمة!
                  </span>
                )}
              </p>
            </div>
            <Link
              href="/settings"
              className="btn-primary"
            >
              اشتراك
            </Link>
          </div>
        </div>
      )}

      {/* تنبيه انتهاء الاشتراك */}
      {expiringWarning && (
        <div className="bg-yellow-50 dark:bg-yellow-900/30 border border-yellow-300 dark:border-yellow-600 rounded-lg p-4 mb-6 flex justify-between items-center">
          <div>
            <p className="font-bold text-yellow-600 dark:text-yellow-400">⚠️ تنبيه هام</p>
            <p className="text-gray-900 dark:text-gray-200">
              اشتراكك على وشك الانتهاء خلال {daysRemaining} أيام. يرجى التواصل مع الدعم لتجديد الاشتراك.
            </p>
          </div>
          <button
            onClick={() => window.open('https://wa.me/966500000000', '_blank')}
            className="btn-success"
          >
            تواصل مع الدعم
          </button>
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        {/* بطاقات الإحصائيات */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6 mb-8">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <div className="flex items-center justify-between mb-2">
              <Users className="text-electric" size={24} />
              <p className="text-gray-500 dark:text-gray-400 text-sm">إجمالي العملاء</p>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white">{stats.total_customers}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-success">
            <div className="flex items-center justify-between mb-2">
              <Receipt className="text-success" size={24} />
              <p className="text-gray-500 dark:text-gray-400 text-sm">الأقساط النشطة</p>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white">{stats.active_installments}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <div className="flex items-center justify-between mb-2">
              <DollarSign className="text-electric" size={24} />
              <p className="text-gray-500 dark:text-gray-400 text-sm">تحصيلات اليوم</p>
            </div>
            {stats?.today_collection?.IQD > 0 && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {stats.today_collection.IQD.toLocaleString()} IQD
              </p>
            )}
            {stats?.today_collection?.USD > 0 && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {stats.today_collection.USD.toLocaleString()} USD
              </p>
            )}
            {(!stats?.today_collection?.IQD && !stats?.today_collection?.USD) && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">0</p>
            )}
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-warning">
            <div className="flex items-center justify-between mb-2">
              <Calendar className="text-warning" size={24} />
              <p className="text-gray-500 dark:text-gray-400 text-sm">مستحقة اليوم</p>
            </div>
            {stats?.due_today?.IQD > 0 && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {stats.due_today.IQD.toLocaleString()} IQD
              </p>
            )}
            {stats?.due_today?.USD > 0 && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {stats.due_today.USD.toLocaleString()} USD
              </p>
            )}
            {(!stats?.due_today?.IQD && !stats?.due_today?.USD) && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">0</p>
            )}
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-danger">
            <div className="flex items-center justify-between mb-2">
              <AlertCircle className="text-danger" size={24} />
              <p className="text-gray-500 dark:text-gray-400 text-sm">متأخرات</p>
            </div>
            {stats?.overdue?.IQD > 0 && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {stats.overdue.IQD.toLocaleString()} IQD
              </p>
            )}
            {stats?.overdue?.USD > 0 && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {stats.overdue.USD.toLocaleString()} USD
              </p>
            )}
            {(!stats?.overdue?.IQD && !stats?.overdue?.USD) && (
              <p className="text-3xl font-bold text-gray-900 dark:text-white">0</p>
            )}
          </div>
        </div>

        {/* قائمة سريعة */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
          <Link href="/customers/new" className="group bg-gradient-to-br from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 dark:from-blue-600 dark:to-blue-700 p-4 rounded-xl shadow-md text-center transition-all duration-200 transform hover:scale-105">
            <Plus className="mx-auto mb-2 text-white" size={24} />
            <span className="text-white font-medium">إضافة عميل</span>
          </Link>

          <Link href="/installments/new" className="group bg-gradient-to-br from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700 dark:from-purple-600 dark:to-purple-700 p-4 rounded-xl shadow-md text-center transition-all duration-200 transform hover:scale-105">
            <Receipt className="mx-auto mb-2 text-white" size={24} />
            <span className="text-white font-medium">قسط جديد</span>
          </Link>

          <Link href="/products/new" className="group bg-gradient-to-br from-teal-500 to-teal-600 hover:from-teal-600 hover:to-teal-700 dark:from-teal-600 dark:to-teal-700 p-4 rounded-xl shadow-md text-center transition-all duration-200 transform hover:scale-105">
            <Package className="mx-auto mb-2 text-white" size={24} />
            <span className="text-white font-medium">منتج جديد</span>
          </Link>

          <Link href="/cash-sales/new" className="group bg-gradient-to-br from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700 dark:from-emerald-600 dark:to-emerald-700 p-4 rounded-xl shadow-md text-center transition-all duration-200 transform hover:scale-105">
            <DollarSign className="mx-auto mb-2 text-white" size={24} />
            <span className="text-white font-medium">بيع نقدي</span>
          </Link>

          <Link href="/payments/new" className="group bg-gradient-to-br from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 dark:from-amber-600 dark:to-amber-700 p-4 rounded-xl shadow-md text-center transition-all duration-200 transform hover:scale-105">
            <CreditCard className="mx-auto mb-2 text-white" size={24} />
            <span className="text-white font-medium">تسديد دفعة</span>
          </Link>
        </div>

        {/* آخر الأقساط */}
        <div className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6 overflow-hidden">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">آخر الأقساط</h2>
            <Link href="/installments" className="text-blue-600 dark:text-blue-400 hover:underline text-sm">
              عرض الكل
            </Link>
          </div>
          {recentInstallments.length === 0 ? (
            <p className="text-gray-500 dark:text-gray-400 text-center py-8">لا توجد أقساط مسجلة</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-t border-gray-100 dark:border-[#30363D] bg-gray-50 dark:bg-[#1C2128]">
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
                    <tr key={item.id} className="border-t border-gray-100 dark:border-[#30363D] hover:bg-gray-50 dark:hover:bg-[#1C2128]">
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{item.customer_name}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{item.product_name}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{item.total_price?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{item.remaining_amount?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4">
                        <span className={`px-3 py-1 rounded-full text-sm ${
                          item.status === 'active' ? 'bg-green-100 text-green-600' :
                          item.status === 'completed' ? 'bg-blue-100 text-blue-600' :
                          'bg-red-100 text-red-600'
                        }`}>
                          {item.status === 'active' ? 'نشط' : item.status === 'completed' ? 'مكتمل' : 'متأخر'}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <Link href={`/installments/${item.id}`} className="btn-outline">
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
