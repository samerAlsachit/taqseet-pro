'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import Swal from 'sweetalert2';
import { Eye, Trash2 } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

interface Customer {
  id: string;
  full_name: string;
  phone: string;
  address: string;
  national_id: string;
  created_at: string;
  active_installments_count: number;
}

export default function CustomersPage() {
  const router = useRouter();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [isStoreActive, setIsStoreActive] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const limit = 20;

  const fetchCustomers = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    setLoading(true);
    try {
      // جلب بيانات المستخدم والمحل
      const meRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const meData = await meRes.json();
      
      if (meData.success) {
        const store = meData.data.store;
        if (store && !store.is_active) {
          setIsStoreActive(false);
          alert('حساب المحل غير نشط. يرجى التواصل مع الدعم.');
        }
      }

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/customers?search=${search}&page=${page}&limit=${limit}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await res.json();
      if (data.success) {
        setCustomers(data.data.customers);
        setTotalPages(data.data.pagination.totalPages);
      }
    } catch (error) {
      console.error('خطأ في جلب العملاء', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomers();
  }, [page, search]);

  const handleDelete = async (id: string) => {
    if (!isStoreActive) {
      alert('حساب المحل غير نشط. لا يمكن إجراء عمليات.');
      return;
    }

  const result = await Swal.fire({
    title: 'هل أنت متأكد؟',
    text: 'لن تتمكن من استعادة هذا العميل!',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#DC3545',
    cancelButtonColor: '#6c757d',
    confirmButtonText: 'نعم، احذف',
    cancelButtonText: 'إلغاء'
  });

  if (result.isConfirmed) {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم حذف العميل بنجاح');
        fetchCustomers();
      } else {
        toast.error(data.error || 'فشل في حذف العميل');
      }
    } catch (error) {
      toast.error('حدث خطأ في الاتصال بالخادم');
    }
  }
};

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      {/* تحذير المحل غير النشط */}
      {!isStoreActive && (
        <div className="bg-red-50 dark:bg-red-900/30 border border-red-300 dark:border-red-700 rounded-lg p-4 mb-6">
          <div className="flex items-center gap-3">
            <div className="text-red-600 dark:text-red-400 text-xl">⚠️</div>
            <div>
              <p className="font-bold text-red-700 dark:text-red-400">حساب المحل غير نشط</p>
              <p className="text-red-600 dark:text-red-300 text-sm">
                حسابك غير نشط حالياً. يرجى التواصل مع الدعم لتفعيله.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">العملاء</h1>
        <Link
          href="/customers/new"
          className={`px-4 py-2 rounded-lg transition ${
            isStoreActive
              ? 'bg-[#3A86FF] hover:bg-[#2563EB] text-white'
              : 'bg-gray-300 dark:bg-gray-600 cursor-not-allowed opacity-50'
          }`}
          onClick={(e) => !isStoreActive && e.preventDefault()}
        >
          + إضافة عميل جديد
        </Link>
      </div>

      {/* Search */}
      <div className="mb-6">
        <input
          type="text"
          placeholder="بحث بالاسم أو رقم الهاتف..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          className="w-full max-w-md px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
        />
      </div>

      {/* Table */}
      {loading ? (
        <LoadingSpinner />
      ) : customers.length === 0 ? (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 text-center">
          <p className="text-gray-900 dark:text-white mb-4">لا يوجد عملاء</p>
          <Link
            href="/customers/new"
            className="bg-[#3A86FF] hover:bg-[#2563EB] text-white px-4 py-2 rounded-lg transition"
          >
            أضف أول عميل
          </Link>
        </div>
      ) : (
        <>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الاسم</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">رقم الهاتف</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">العنوان</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الرقم الوطني</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">أقساط نشطة</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">إجراءات</th>
                   </tr>
                </thead>
                <tbody>
                  {customers.map((customer) => (
                    <tr key={customer.id} className="border-b border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{customer.full_name}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{customer.phone}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{customer.address || '-'}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{customer.national_id || '-'}</td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-1 rounded-full text-sm bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
                          {customer.active_installments_count || 0}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex gap-2">
                          <Link
                            href={`/customers/${customer.id}`}
                            className="text-[#3A86FF] hover:underline text-sm"
                          >
                            <Eye size={16} className="inline ml-1" />
                            تفاصيل
                          </Link>
                          <button
                            onClick={() => handleDelete(customer.id)}
                            className="text-[#DC3545] hover:underline text-sm"
                          >
                            <Trash2 size={16} className="inline ml-1" />
                            حذف
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
                className="px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-900 dark:text-white disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-4 py-2 text-gray-900 dark:text-white">
                صفحة {page} من {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-900 dark:text-white disabled:opacity-50"
              >
                التالي
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
