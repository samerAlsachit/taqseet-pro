'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

interface InstallmentPlan {
  id: string;
  customer_name: string;
  customer_phone: string;
  product_name: string;
  total_price: number;
  remaining_amount: number;
  status: string;
  start_date: string;
  end_date: string;
  paid_count: number;
  total_count: number;
}

export default function InstallmentsPage() {
  const router = useRouter();
  const [plans, setPlans] = useState<InstallmentPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const limit = 20;

  const fetchInstallments = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    setLoading(true);
    try {
      let url = `${process.env.NEXT_PUBLIC_API_URL}/installments?search=${search}&page=${page}&limit=${limit}`;
      if (statusFilter !== 'all') {
        url += `&status=${statusFilter}`;
      }
      
      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        setPlans(data.data.installments);
        setTotalPages(data.data.pagination.totalPages);
      }
    } catch (error) {
      console.error('خطأ في جلب الأقساط', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInstallments();
  }, [page, search, statusFilter]);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <span className="px-2 py-1 rounded-full text-sm bg-success/10 text-success">نشط</span>;
      case 'completed':
        return <span className="px-2 py-1 rounded-full text-sm bg-electric/10 text-electric">مكتمل</span>;
      case 'overdue':
        return <span className="px-2 py-1 rounded-full text-sm bg-danger/10 text-danger">متأخر</span>;
      default:
        return <span className="px-2 py-1 rounded-full text-sm bg-gray-100 text-text-primary">{status}</span>;
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-navy">الأقساط</h1>
        <Link
          href="/installments/new"
          className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition text-center"
        >
          + إضافة قسط جديد
        </Link>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <input
          type="text"
          placeholder="بحث باسم العميل أو المنتج..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
        />
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(1);
          }}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white"
        >
          <option value="all">جميع الأقساط</option>
          <option value="active">نشطة</option>
          <option value="completed">مكتملة</option>
          <option value="overdue">متأخرة</option>
        </select>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
        </div>
      ) : !plans || plans.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm p-12 text-center">
          <p className="text-text-primary mb-4">لا توجد أقساط</p>
          <Link
            href="/installments/new"
            className="bg-electric text-white px-4 py-2 rounded-lg inline-block"
          >
            إضافة قسط جديد
          </Link>
        </div>
      ) : (
        <>
          <div className="bg-white rounded-xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">العميل</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المنتج</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المبلغ الكلي</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المتبقي</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">التقدم</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الحالة</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold"></th>
                  </tr>
                </thead>
                <tbody>
                  {plans.map((plan) => {
                    const progress = ((plan.paid_count || 0) / (plan.total_count || 1)) * 100;
                    return (
                      <tr key={plan.id} className="border-b border-gray-100 hover:bg-gray-50">
                        <td className="py-3 px-4">
                          <div className="font-medium text-text-primary">{plan.customer_name}</div>
                          <div className="text-sm text-text-primary/70">{plan.customer_phone}</div>
                        </td>
                        <td className="py-3 px-4 text-text-primary">{plan.product_name}</td>
                        <td className="py-3 px-4 text-text-primary">{plan.total_price.toLocaleString()} IQD</td>
                        <td className="py-3 px-4 text-text-primary">{plan.remaining_amount.toLocaleString()} IQD</td>
                        <td className="py-3 px-4">
                          <div className="w-24 bg-gray-200 rounded-full h-2">
                            <div
                              className="bg-electric rounded-full h-2"
                              style={{ width: `${progress}%` }}
                            />
                          </div>
                          <span className="text-xs text-text-primary mt-1">
                            {plan.paid_count || 0}/{plan.total_count}
                          </span>
                        </td>
                        <td className="py-3 px-4">{getStatusBadge(plan.status)}</td>
                        <td className="py-3 px-4">
                          <Link
                            href={`/installments/${plan.id}`}
                            className="text-electric hover:underline"
                          >
                            تفاصيل
                          </Link>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {totalPages > 1 && (
            <div className="flex justify-center gap-2 mt-6">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-4 py-2 rounded-lg border border-gray-300 disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-4 py-2 text-text-primary">صفحة {page} من {totalPages}</span>
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
