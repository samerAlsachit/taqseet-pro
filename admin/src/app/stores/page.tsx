'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';

interface Store {
  id: string;
  name: string;
  owner_name: string;
  phone: string;
  city: string;
  plan_name: string;
  subscription_end: string;
  is_active: boolean;
  created_at: string;
}

interface PaginationData {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export default function StoresPage() {
  const [stores, setStores] = useState<Store[]>([]);
  const [pagination, setPagination] = useState<PaginationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Search and filter states
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [currentPage, setCurrentPage] = useState(1);
  
  // Modal states
  const [showExtendModal, setShowExtendModal] = useState(false);
  const [selectedStore, setSelectedStore] = useState<Store | null>(null);
  const [extendDays, setExtendDays] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  // Fetch stores data
  useEffect(() => {
    fetchStores();
  }, [search, statusFilter, currentPage]);

  const fetchStores = async () => {
    setLoading(true);
    const token = localStorage.getItem('token');
    
    try {
      const params = new URLSearchParams({
        page: currentPage.toString(),
        limit: '10',
        ...(search && { search }),
        ...(statusFilter !== 'all' && { status: statusFilter }),
      });

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores?${params}`, {
        headers: { Authorization: `Bearer ${token}` }
      });

      const data = await response.json();
      if (data.success) {
        setStores(data.data.stores);
        setPagination(data.data.pagination);
      } else {
        setError('فشل في جلب بيانات المحلات');
      }
    } catch (err) {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (isActive: boolean, endDate: string) => {
    if (!isActive) return 'text-danger bg-red-50';
    const end = new Date(endDate);
    const today = new Date();
    const daysLeft = Math.ceil((end.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    if (daysLeft <= 0) return 'text-danger bg-red-50';
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

  const handleExtendSubscription = async () => {
    if (!selectedStore || !extendDays) return;

    setActionLoading(true);
    const token = localStorage.getItem('token');

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores/${selectedStore.id}/extend`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ days: parseInt(extendDays) }),
      });

      const data = await response.json();
      if (data.success) {
        setShowExtendModal(false);
        setExtendDays('');
        setSelectedStore(null);
        fetchStores(); // Refresh data
      } else {
        setError('فشل في تمديد الاشتراك');
      }
    } catch (err) {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleStatus = async (store: Store) => {
    setActionLoading(true);
    const token = localStorage.getItem('token');

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores/${store.id}/toggle`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      const data = await response.json();
      if (data.success) {
        fetchStores(); // Refresh data
      } else {
        setError('فشل في تغيير حالة المحل');
      }
    } catch (err) {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setActionLoading(false);
    }
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

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-navy">إدارة المحلات</h1>
          <p className="text-text-primary">إدارة وتحكم في جميع المحلات المسجلة في النظام</p>
        </div>

        {error && (
          <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-4 text-center">
            {error}
          </div>
        )}

        {/* Search and Filter */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex flex-col md:flex-row gap-4">
            {/* Search */}
            <div className="flex-1">
              <input
                type="text"
                placeholder="بحث بالاسم، المالك، أو الهاتف..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric focus:border-transparent"
              />
            </div>
            
            {/* Filter */}
            <div className="flex gap-2">
              <button
                onClick={() => setStatusFilter('all')}
                className={`px-4 py-2 rounded-lg transition ${
                  statusFilter === 'all'
                    ? 'bg-electric text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                الكل
              </button>
              <button
                onClick={() => setStatusFilter('active')}
                className={`px-4 py-2 rounded-lg transition ${
                  statusFilter === 'active'
                    ? 'bg-electric text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                نشط
              </button>
              <button
                onClick={() => setStatusFilter('inactive')}
                className={`px-4 py-2 rounded-lg transition ${
                  statusFilter === 'inactive'
                    ? 'bg-electric text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                منتهي
              </button>
            </div>
          </div>
        </div>

        {/* Stores Table */}
        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">اسم المحل</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">المالك</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الهاتف</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">المدينة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الخطة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">تاريخ الانتهاء</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody>
                {stores.map((store) => (
                  <tr key={store.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="py-3 px-4 text-text-primary font-medium">{store.name}</td>
                    <td className="py-3 px-4 text-text-primary">{store.owner_name}</td>
                    <td className="py-3 px-4 text-text-primary">{store.phone}</td>
                    <td className="py-3 px-4 text-text-primary">{store.city || '-'}</td>
                    <td className="py-3 px-4 text-text-primary">{store.plan_name || '-'}</td>
                    <td className="py-3 px-4 text-text-primary">
                      {new Date(store.subscription_end).toLocaleDateString('ar-IQ')}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-3 py-1 rounded-full text-sm ${getStatusColor(store.is_active, store.subscription_end)}`}>
                        {getStatusText(store.is_active, store.subscription_end)}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex gap-2">
                        <button
                          onClick={() => {
                            setSelectedStore(store);
                            setShowExtendModal(true);
                          }}
                          className="px-3 py-1 bg-electric text-white rounded hover:bg-blue-600 transition text-sm"
                          disabled={actionLoading}
                        >
                          تمديد
                        </button>
                        <button
                          onClick={() => handleToggleStatus(store)}
                          className={`px-3 py-1 rounded transition text-sm ${
                            store.is_active
                              ? 'bg-warning text-white hover:bg-yellow-600'
                              : 'bg-success text-white hover:bg-green-600'
                          }`}
                          disabled={actionLoading}
                        >
                          {store.is_active ? 'تعطيل' : 'تفعيل'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            
            {stores.length === 0 && (
              <div className="text-center py-8 text-text-primary">
                لا توجد محلات مطابقة للبحث
              </div>
            )}
          </div>

          {/* Pagination */}
          {pagination && pagination.last_page > 1 && (
            <div className="flex justify-center items-center gap-2 p-4 border-t border-gray-200">
              <button
                onClick={() => setCurrentPage(currentPage - 1)}
                disabled={currentPage === 1}
                className="px-3 py-1 rounded bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                السابق
              </button>
              
              <span className="text-text-primary">
                صفحة {pagination.current_page} من {pagination.last_page}
              </span>
              
              <button
                onClick={() => setCurrentPage(currentPage + 1)}
                disabled={currentPage === pagination.last_page}
                className="px-3 py-1 rounded bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                التالي
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Extend Subscription Modal */}
      {showExtendModal && selectedStore && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-lg p-6 w-full max-w-md">
            <h3 className="text-xl font-bold text-navy mb-4">تمديد اشتراك المحل</h3>
            
            <div className="mb-4">
              <p className="text-text-primary mb-2">المحل: {selectedStore.name}</p>
              <p className="text-text-primary mb-4">المالك: {selectedStore.owner_name}</p>
            </div>

            <div className="mb-6">
              <label className="block text-text-primary mb-2">عدد الأيام للإضافة:</label>
              <input
                type="number"
                min="1"
                value={extendDays}
                onChange={(e) => setExtendDays(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric focus:border-transparent"
                placeholder="أدخل عدد الأيام"
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={handleExtendSubscription}
                disabled={!extendDays || actionLoading}
                className="flex-1 bg-electric text-white py-2 px-4 rounded-lg hover:bg-blue-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {actionLoading ? 'جاري التمديد...' : 'تأكيد التمديد'}
              </button>
              <button
                onClick={() => {
                  setShowExtendModal(false);
                  setExtendDays('');
                  setSelectedStore(null);
                }}
                className="flex-1 bg-gray-200 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-300 transition"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
