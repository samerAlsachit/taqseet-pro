'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import AdminLayout from '@/components/layout/AdminLayout';
import LoadingSpinner from '@/components/ui/LoadingSpinner';
import {
  Store,
  AlertTriangle,
  MessageCircle,
  Mail,
  Clock,
  Users,
  AlertCircle,
  Calendar,
  TrendingUp
} from 'lucide-react';

interface Stats {
  total_stores: number;
  active_stores: number;
  expiring_soon: number;
  new_stores_this_month: number;
}

interface Store {
  id: string;
  name: string;
  owner_name: string;
  phone: string;
  email?: string;
  city: string;
  plan_name: string;
  subscription_end: string;
  is_active: boolean;
  days_left?: number;
}

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<Stats | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
  const [expiringStores, setExpiringStores] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      const token = localStorage.getItem('token');
      
      try {
        // جلب الإحصائيات
        const statsRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stats`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const statsData = await statsRes.json();
        if (statsData.success) setStats(statsData.data);

        // جلب المحلات المنتهية خلال 7 أيام
        const expiringRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores/expiring`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const expiringData = await expiringRes.json();
        if (expiringData.success) {
          setExpiringStores(expiringData.data);
        }

        // جلب آخر 5 محلات
        const storesRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores?limit=5`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const storesData = await storesRes.json();
        if (storesData.success) setStores(storesData.data.stores);

      } catch (err) {
        setError('حدث خطأ في جلب البيانات');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const getStatusColor = (isActive: boolean, endDate: string) => {
    if (!isActive) return 'text-danger bg-red-50';
    const end = new Date(endDate);
    const today = new Date();
    const daysLeft = Math.ceil((end.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    if (daysLeft <= 7) return 'text-warning bg-yellow-50';
    return 'text-success bg-green-50';
  };

  const getStatusText = (isActive: boolean, endDate: string) => {
    if (!isActive) return 'غير نشط';
    const end = new Date(endDate);
    const today = new Date();
    const daysLeft = Math.ceil((end.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    if (daysLeft <= 0) return 'منتهي';
    if (daysLeft <= 7) return `ينتهي خلال ${daysLeft} أيام`;
    return 'نشط';
  };

  const handleSendWhatsApp = (store: any) => {
    const message = `*تقسيط برو - تنبيه انتهاء اشتراك*\n\nالسلام عليكم،\n\nنود إعلامكم بأن اشتراك محل "${store.name}" على وشك الانتهاء خلال ${store.days_left} يوم.\n\nيرجى التواصل مع الدعم لتجديد الاشتراك.\n\nشكراً لثقتكم بنا.`;
    const encodedMessage = encodeURIComponent(message);
    const phoneNumber = store.phone?.replace(/[^0-9]/g, '');
    if (phoneNumber) {
      window.open(`https://wa.me/${phoneNumber}?text=${encodedMessage}`, '_blank');
    } else {
      alert('رقم الهاتف غير متوفر');
    }
  };

  const handleSendEmail = async (store: any) => {
    if (!store.email) {
      alert('البريد الإلكتروني غير متوفر لهذا المحل');
      return;
    }
    
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/notify-expiring`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('token')}` 
        },
        body: JSON.stringify({
          store_id: store.id,
          days_left: store.days_left
        })
      });
      const data = await response.json();
      if (data.success) {
        alert('تم إرسال الإشعار بنجاح');
      } else {
        alert(data.error || 'فشل في إرسال الإشعار');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  if (loading) {
    return (
      <AdminLayout>
        <LoadingSpinner />
      </AdminLayout>
    );
  }

  if (error) {
    return (
      <AdminLayout>
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-4 text-center">
          {error}
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">مرساة - لوحة التحكم</h1>

      {/* بطاقات الإحصائيات */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-electric">
          <div className="flex items-center justify-between mb-2">
            <Store className="text-electric" size={24} />
            <p className="text-gray-500 dark:text-gray-400 text-sm">إجمالي المحلات</p>
          </div>
          <p className="text-3xl font-bold text-gray-900 dark:text-white">{stats?.total_stores || 0}</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-success">
          <div className="flex items-center justify-between mb-2">
            <Users className="text-success" size={24} />
            <p className="text-gray-500 dark:text-gray-400 text-sm">المحلات النشطة</p>
          </div>
          <p className="text-3xl font-bold text-gray-900 dark:text-white">{stats?.active_stores || 0}</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-warning">
          <div className="flex items-center justify-between mb-2">
            <AlertCircle className="text-warning" size={24} />
            <p className="text-gray-500 dark:text-gray-400 text-sm">تنتهي خلال 7 أيام</p>
          </div>
          <p className="text-3xl font-bold text-gray-900 dark:text-white">{stats?.expiring_soon || 0}</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-electric">
          <div className="flex items-center justify-between mb-2">
            <Calendar className="text-electric" size={24} />
            <p className="text-gray-500 dark:text-gray-400 text-sm">محلات جديدة هذا الشهر</p>
          </div>
          <p className="text-3xl font-bold text-gray-900 dark:text-white">{stats?.new_stores_this_month || 0}</p>
        </div>
      </div>

      {/* المحلات المنتهية قريباً */}
      {expiringStores.length > 0 && (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 mb-8">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-warning flex items-center gap-2">
              <AlertTriangle size={20} />
              محلات على وشك انتهاء الاشتراك
            </h2>
            <Link href="/stores?status=expiring" className="text-electric hover:underline text-sm">
              عرض الكل
            </Link>
          </div>
          <div className="space-y-3">
            {expiringStores.map((store) => (
              <div key={store.id} className="flex justify-between items-center p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-warning">
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">{store.name}</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">المالك: {store.owner_name} | الهاتف: {store.phone}</p>
                  <p className="text-sm text-warning">ينتهي خلال {store.days_left} أيام</p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleSendWhatsApp(store)}
                    className="bg-success text-white px-3 py-1 rounded-lg text-sm"
                  >
                    <MessageCircle size={16} className="inline ml-1" />
                    واتساب
                  </button>
                  <button
                    onClick={() => handleSendEmail(store)}
                    className="bg-electric text-white px-3 py-1 rounded-lg text-sm"
                  >
                    <Mail size={16} className="inline ml-1" />
                    إيميل
                  </button>
                  <button
                    onClick={() => router.push(`/stores?extend=${store.id}`)}
                    className="bg-warning text-white px-3 py-1 rounded-lg text-sm"
                  >
                    <Clock size={16} className="inline ml-1" />
                    تمديد
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* أحدث المحلات */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">أحدث المحلات</h2>
        {stores.length === 0 ? (
          <p className="text-gray-500 dark:text-gray-400 text-center py-8">لا توجد محلات مسجلة</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900">
                  <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">اسم المحل</th>
                  <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">المالك</th>
                  <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الهاتف</th>
                  <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">المدينة</th>
                  <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">تاريخ الانتهاء</th>
                  <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الحالة</th>
                </tr>
              </thead>
              <tbody>
                {stores.map((store) => (
                  <tr key={store.id} className="border-b border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-900">
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{store.name}</td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{store.owner_name}</td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{store.phone}</td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{store.city || '-'}</td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">
                      {new Date(store.subscription_end).toLocaleDateString('ar-IQ')}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-3 py-1 rounded-full text-sm ${getStatusColor(store.is_active, store.subscription_end)}`}>
                        {getStatusText(store.is_active, store.subscription_end)}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
