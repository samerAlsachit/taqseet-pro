'use client';

import { useState, useEffect } from 'react';
import { useTheme } from '../../context/ThemeContext';

export default function AdminDashboard() {
  const { theme } = useTheme();
  const [stats, setStats] = useState(null);
  const [stores, setStores] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsRes, storesRes] = await Promise.all([
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stats`),
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores`)
        ]);

        const statsData = await statsRes.json();
        const storesData = await storesRes.json();

        if (statsData.success) setStats(statsData.data);
        if (storesData.success) setStores(storesData.data);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--bg-primary)]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--bg-primary)]">
      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">لوحة التحكم</h1>
          <div className="text-[var(--text-primary)]/70">
            {theme === 'light' ? '☀️' : '🌙'} الوضع {theme === 'light' ? 'النهاري' : 'الليلي'}
          </div>
        </div>

        {/* إحصائيات */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-electric">
            <p className="text-[var(--text-primary)]/70 text-sm mb-1">إجمالي المحلات</p>
            <p className="text-3xl font-bold text-[var(--text-primary)]">{stats?.total_stores || 0}</p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-success">
            <p className="text-[var(--text-primary)]/70 text-sm mb-1">إجمالي المستخدمين</p>
            <p className="text-3xl font-bold text-[var(--text-primary)]">{stats?.total_users || 0}</p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-warning">
            <p className="text-[var(--text-primary)]/70 text-sm mb-1">إجمالي الخطط</p>
            <p className="text-3xl font-bold text-[var(--text-primary)]">{stats?.total_plans || 0}</p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-danger">
            <p className="text-[var(--text-primary)]/70 text-sm mb-1">الإيرادات الشهرية</p>
            <p className="text-3xl font-bold text-[var(--text-primary)]">{stats?.monthly_revenue?.toLocaleString() || 0} IQD</p>
          </div>
        </div>

        {/* المحلات الأخيرة */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 mb-8">
          <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">المحلات الأخيرة</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">اسم المحل</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">المالك</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الخطة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">تاريخ الإنشاء</th>
                </tr>
              </thead>
              <tbody>
                {stores.slice(0, 5).map((store: any) => (
                  <tr key={store.id} className="border-b border-[var(--border-color)] hover:bg-[var(--bg-primary)]">
                    <td className="py-3 px-4 text-[var(--text-primary)]">{store.name}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{store.owner_name}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{store.plan_name || 'غير محدد'}</td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-1 rounded-full text-sm ${
                        store.status === 'active' ? 'bg-success/10 text-success' :
                        store.status === 'trial' ? 'bg-warning/10 text-warning' :
                        'bg-danger/10 text-danger'
                      }`}>
                        {store.status === 'active' ? 'نشط' : store.status === 'trial' ? 'تجريبي' : 'منتهي'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      {new Date(store.created_at).toLocaleDateString('ar-IQ')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* خلاصات سريعة */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
            <h3 className="text-lg font-bold text-[var(--text-primary)] mb-4">الخطط الأكثر استخداماً</h3>
            <div className="space-y-3">
              {stats?.popular_plans?.map((plan: any, index: number) => (
                <div key={index} className="flex justify-between items-center">
                  <span className="text-[var(--text-primary)]">{plan.name}</span>
                  <span className="text-[var(--text-primary)]/70">{plan.count} محلات</span>
                </div>
              ))}
            </div>
          </div>
          
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
            <h3 className="text-lg font-bold text-[var(--text-primary)] mb-4">النشاط الأخير</h3>
            <div className="space-y-3">
              {stats?.recent_activity?.map((activity: any, index: number) => (
                <div key={index} className="flex justify-between items-center">
                  <span className="text-[var(--text-primary)]">{activity.description}</span>
                  <span className="text-[var(--text-primary)]/70 text-sm">
                    {new Date(activity.created_at).toLocaleDateString('ar-IQ')}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
