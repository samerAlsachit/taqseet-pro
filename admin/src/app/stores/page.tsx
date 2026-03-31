'use client';

import { useState, useEffect, useCallback } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { Search, Filter, MoreVertical, Edit, Trash2 } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

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

export default function StoresPage() {
  const [stores, setStores] = useState<Store[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [statusFilter, setStatusFilter] = useState('all');
  const limit = 20;

  // Modal states
  const [showExtendModal, setShowExtendModal] = useState(false);
  const [selectedStore, setSelectedStore] = useState<Store | null>(null);
  const [extendDays, setExtendDays] = useState(30);
  const [extending, setExtending] = useState(false);

  // دالة جلب البيانات - مستقلة
  const fetchStores = useCallback(async () => {
    setLoading(true);
    const token = localStorage.getItem('token');
    
    try {
      let url = `${process.env.NEXT_PUBLIC_API_URL}/admin/stores?page=${page}&limit=${limit}&search=${searchTerm}`;
      if (statusFilter !== 'all') {
        url += `&status=${statusFilter}`;
      }
      
      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      
      if (data.success) {
        setStores(data.data.stores);
        setTotalPages(data.data.pagination.totalPages);
      }
    } catch (error) {
      console.error('خطأ في جلب المحلات:', error);
    } finally {
      setLoading(false);
    }
  }, [page, searchTerm, statusFilter]);

  // useEffect لتغيير الصفحة عند البحث أو الفلتر
  useEffect(() => {
    fetchStores();
  }, [fetchStores]);

  // دالة معالجة البحث
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
    setPage(1); // إعادة تعيين الصفحة إلى 1 عند تغيير البحث
  };

  // دالة تبديل حالة المحل
  const toggleStoreStatus = async (storeId: string, currentStatus: boolean) => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores/${storeId}/toggle-status`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({ is_active: !currentStatus })
      });
      const data = await res.json();
      if (data.success) {
        alert(`تم ${!currentStatus ? 'تفعيل' : 'تعطيل'} المحل بنجاح`);
        fetchStores();
      } else {
        alert(data.error || 'فشل في تغيير حالة المحل');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  // دالة تمديد الاشتراك
  const handleExtend = async () => {
    if (!selectedStore) return;
    
    setExtending(true);
    const token = localStorage.getItem('token');
    
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/stores/${selectedStore.id}/extend`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({ additional_days: extendDays })
      });
      
      const data = await response.json();
      
      if (data.success) {
        setShowExtendModal(false);
        fetchStores(); // تحديث القائمة
      } else {
        alert(data.error || 'فشل في تمديد الاشتراك');
      }
    } catch (error) {
      console.error('خطأ في تمديد الاشتراك:', error);
      alert('حدث خطأ في الاتصال بالخادم');
    } finally {
      setExtending(false);
    }
  };

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">مرساة - إدارة المحلات</h1>

        {/* شريط البحث والفلتر - يبقى ثابت */}
        <div className="flex flex-col sm:flex-row gap-4 mb-6">
          <div className="relative flex-1">
            <Search className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500" size={18} />
            <input
              type="text"
              placeholder="بحث باسم المحل، المالك، أو رقم الهاتف..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pr-10 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(1);
              }}
              className="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
            >
              <option value="all">جميع المحلات</option>
              <option value="active">نشطة</option>
              <option value="expired">منتهية</option>
            </select>
            <button className="px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-900 transition">
              <Filter size={18} />
            </button>
          </div>
        </div>

        {/* الجدول - يتغير فقط */}
        {loading ? (
          <LoadingSpinner />
        ) : stores.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 text-center">
            <p className="text-gray-500 dark:text-gray-400">لا توجد محلات</p>
          </div>
        ) : (
          <>
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900">
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">اسم المحل</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">المالك</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الهاتف</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">المدينة</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الخطة</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">تاريخ الانتهاء</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الحالة</th>
                      <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">إجراءات</th>
                     </tr>
                  </thead>
                  <tbody>
                    {stores.map((store) => (
                      <tr key={store.id} className="border-b border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-900">
                        <td className="py-3 px-4 text-gray-900 dark:text-white">{store.name}</td>
                        <td className="py-3 px-4 text-gray-900 dark:text-white">{store.owner_name}</td>
                        <td className="py-3 px-4 text-gray-900 dark:text-white">{store.phone}</td>
                        <td className="py-3 px-4 text-gray-900 dark:text-white">{store.city || '-'}</td>
                        <td className="py-3 px-4 text-gray-900 dark:text-white">{store.plan_name || '-'}</td>
                        <td className="py-3 px-4 text-gray-900 dark:text-white">
                          {new Date(store.subscription_end).toLocaleDateString('ar-IQ')}
                        </td>
                        <td className="py-3 px-4">
                          <span className={`px-3 py-1 rounded-full text-sm ${
                            store.is_active 
                              ? 'bg-success/10 text-success' 
                              : 'bg-danger/10 text-danger'
                          }`}>
                            {store.is_active ? 'نشط' : 'غير نشط'}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => {
                                setSelectedStore(store);
                                setExtendDays(30);
                                setShowExtendModal(true);
                              }}
                              className="text-electric hover:underline text-sm flex items-center gap-1"
                            >
                              <Edit size={16} />
                              تمديد
                            </button>
                            <button
                              onClick={() => toggleStoreStatus(store.id, store.is_active)}
                              className={`flex items-center gap-1 px-3 py-1 rounded-lg text-sm transition ${
                                store.is_active
                                  ? 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200'
                                  : 'bg-green-100 text-green-700 hover:bg-green-200'
                              }`}
                            >
                              {store.is_active ? 'تعطيل' : 'تفعيل'}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex justify-center gap-2 mt-6">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white disabled:opacity-50"
                >
                  السابق
                </button>
                <span className="px-4 py-2 text-gray-900 dark:text-white">
                  صفحة {page} من {totalPages}
                </span>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white disabled:opacity-50"
                >
                  التالي
                </button>
              </div>
            )}
          </>
        )}

        {/* Modal تمديد الاشتراك */}
        {showExtendModal && selectedStore && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 w-full max-w-md border border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">تمديد الاشتراك</h2>
              
              <div className="space-y-4">
                <div>
                  <p className="text-gray-900 dark:text-white">المحل: <span className="font-medium">{selectedStore.name}</span></p>
                  <p className="text-gray-900 dark:text-white mt-1">المالك: {selectedStore.owner_name}</p>
                  <p className="text-gray-900 dark:text-white mt-1">تاريخ الانتهاء الحالي: {new Date(selectedStore.subscription_end).toLocaleDateString('ar-IQ')}</p>
                </div>
                
                <div>
                  <label className="block text-gray-900 dark:text-white mb-2">عدد أيام التمديد</label>
                  <div className="flex gap-2 mb-2">
                    <button
                      onClick={() => setExtendDays(30)}
                      className={`px-4 py-2 rounded-lg border ${extendDays === 30 ? 'bg-electric text-white border-electric' : 'border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white'}`}
                    >
                      30 يوم
                    </button>
                    <button
                      onClick={() => setExtendDays(90)}
                      className={`px-4 py-2 rounded-lg border ${extendDays === 90 ? 'bg-electric text-white border-electric' : 'border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white'}`}
                    >
                      90 يوم
                    </button>
                    <button
                      onClick={() => setExtendDays(365)}
                      className={`px-4 py-2 rounded-lg border ${extendDays === 365 ? 'bg-electric text-white border-electric' : 'border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white'}`}
                    >
                      365 يوم
                    </button>
                  </div>
                  <input
                    type="number"
                    min="1"
                    value={extendDays}
                    onChange={(e) => setExtendDays(parseInt(e.target.value) || 0)}
                    className="w-full px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  />
                </div>
              </div>
              
              <div className="flex gap-3">
                <button
                  onClick={handleExtend}
                  disabled={extending || extendDays <= 0}
                  className="flex-1 bg-electric hover:bg-blue-600 text-white py-2 rounded-lg disabled:opacity-50"
                >
                  {extending ? 'جاري التمديد...' : 'تأكيد التمديد'}
                </button>
                <button
                  onClick={() => setShowExtendModal(false)}
                  className="flex-1 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white py-2 rounded-lg"
                >
                  إلغاء
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
