'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

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
    if (!confirm('هل أنت متأكد من حذف هذا العميل؟')) return;

    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        fetchCustomers();
      } else {
        alert(data.error || 'فشل في حذف العميل');
      }
    } catch (error) {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-navy">العملاء</h1>
        <Link
          href="/customers/new"
          className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition text-center"
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
          className="w-full max-w-md px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
        />
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
        </div>
      ) : customers.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm p-12 text-center">
          <p className="text-text-primary mb-4">لا يوجد عملاء</p>
          <Link
            href="/customers/new"
            className="bg-electric text-white px-4 py-2 rounded-lg inline-block"
          >
            أضف أول عميل
          </Link>
        </div>
      ) : (
        <>
          <div className="bg-white rounded-xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الاسم</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">رقم الهاتف</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">العنوان</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الرقم الوطني</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">أقساط نشطة</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">إجراءات</th>
                   </tr>
                </thead>
                <tbody>
                  {customers.map((customer) => (
                    <tr key={customer.id} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4 text-text-primary">{customer.full_name}</td>
                      <td className="py-3 px-4 text-text-primary">{customer.phone}</td>
                      <td className="py-3 px-4 text-text-primary">{customer.address || '-'}</td>
                      <td className="py-3 px-4 text-text-primary">{customer.national_id || '-'}</td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-1 rounded-full text-sm bg-electric/10 text-electric">
                          {customer.active_installments_count || 0}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex gap-2">
                          <Link
                            href={`/customers/${customer.id}`}
                            className="text-electric hover:underline"
                          >
                            تفاصيل
                          </Link>
                          <button
                            onClick={() => handleDelete(customer.id)}
                            className="text-danger hover:underline"
                          >
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
                className="px-4 py-2 rounded-lg border border-gray-300 disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-4 py-2 text-text-primary">
                صفحة {page} من {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-4 py-2 rounded-lg border border-gray-300 disabled:opacity-50"
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
