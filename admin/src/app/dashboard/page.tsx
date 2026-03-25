'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';

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
  city: string;
  plan_name: string;
  subscription_end: string;
  is_active: boolean;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
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

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric mx-auto"></div>
            <p className="mt-4 text-text-primary">جاري تحميل البيانات...</p>
          </div>
        </div>
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
      <h1 className="text-2xl font-bold text-navy mb-6">لوحة التحكم</h1>

      {/* بطاقات الإحصائيات */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-electric">
          <p className="text-text-primary text-sm mb-1">إجمالي المحلات</p>
          <p className="text-3xl font-bold text-navy">{stats?.total_stores || 0}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-success">
          <p className="text-text-primary text-sm mb-1">المحلات النشطة</p>
          <p className="text-3xl font-bold text-navy">{stats?.active_stores || 0}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-warning">
          <p className="text-text-primary text-sm mb-1">تنتهي خلال 7 أيام</p>
          <p className="text-3xl font-bold text-navy">{stats?.expiring_soon || 0}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-electric">
          <p className="text-text-primary text-sm mb-1">محلات جديدة هذا الشهر</p>
          <p className="text-3xl font-bold text-navy">{stats?.new_stores_this_month || 0}</p>
        </div>
      </div>

      {/* أحدث المحلات */}
      <div className="bg-white rounded-xl shadow-sm p-6">
        <h2 className="text-xl font-bold text-navy mb-4">أحدث المحلات</h2>
        {stores.length === 0 ? (
          <p className="text-text-primary text-center py-8">لا توجد محلات مسجلة</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">اسم المحل</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">المالك</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الهاتف</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">المدينة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">تاريخ الانتهاء</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الحالة</th>
                </tr>
              </thead>
              <tbody>
                {stores.map((store) => (
                  <tr key={store.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="py-3 px-4 text-text-primary">{store.name}</td>
                    <td className="py-3 px-4 text-text-primary">{store.owner_name}</td>
                    <td className="py-3 px-4 text-text-primary">{store.phone}</td>
                    <td className="py-3 px-4 text-text-primary">{store.city || '-'}</td>
                    <td className="py-3 px-4 text-text-primary">
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
