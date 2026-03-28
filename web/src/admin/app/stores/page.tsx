'use client';

import { useState, useEffect } from 'react';
import { useTheme } from '../../context/ThemeContext';

export default function AdminStores() {
  const { theme } = useTheme();
  const [stores, setStores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    const fetchStores = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores`);
        const data = await res.json();
        if (data.success) setStores(data.data);
      } catch (error) {
        console.error('Error fetching stores:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchStores();
  }, []);

  const filteredStores = stores.filter(store => {
    const matchesSearch = store.name.toLowerCase().includes(search.toLowerCase()) ||
                         store.owner_name.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || store.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

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
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">المحلات</h1>
        </div>

        {/* Filters */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 mb-8">
          <div className="flex flex-col sm:flex-row gap-4">
            <input
              type="text"
              placeholder="بحث عن محل..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="flex-1 px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
            />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
            >
              <option value="all">جميع الحالات</option>
              <option value="active">نشط</option>
              <option value="trial">تجريبي</option>
              <option value="expired">منتهي</option>
            </select>
          </div>
        </div>

        {/* Stores Table */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">اسم المحل</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">المالك</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الهاتف</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الخطة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">تاريخ الإنشاء</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody>
                {filteredStores.map((store: any) => (
                  <tr key={store.id} className="border-b border-[var(--border-color)] hover:bg-[var(--bg-primary)]">
                    <td className="py-3 px-4 text-[var(--text-primary)]">{store.name}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{store.owner_name}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{store.phone}</td>
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
                    <td className="py-3 px-4">
                      <button className="text-electric hover:underline text-sm">
                        عرض
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
