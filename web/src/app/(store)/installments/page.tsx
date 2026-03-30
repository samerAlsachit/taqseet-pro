'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Eye } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

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
        return <span className="px-2 py-1 rounded-full text-sm bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-200">{status}</span>;
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">الأقساط</h1>
        <Link
          href="/installments/new"
          className="btn-primary"
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
          className="flex-1 px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-[var(--card-bg)] text-[var(--text-primary)]"
        />
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(1);
          }}
          className="px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-[var(--card-bg)] text-[var(--text-primary)]"
        >
          <option value="all">جميع الأقساط</option>
          <option value="active">نشطة</option>
          <option value="completed">مكتملة</option>
          <option value="overdue">متأخرة</option>
        </select>
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : !plans || plans.length === 0 ? (
      <div className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-12 text-center">
        <p className="text-gray-900 dark:text-white mb-4">لا توجد أقساط</p>
        <Link
          href="/installments/new"
          className="btn-primary"
        >
          إضافة قسط جديد
        </Link>
      </div>
      ) : (
        <>
      <div className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-t border-gray-100 dark:border-[#30363D] bg-gray-50 dark:bg-[#1C2128]">
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">العميل</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المنتج</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المبلغ الكلي</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المتبقي</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">التقدم</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">الحالة</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold"></th>
              </tr>
            </thead>
            <tbody>
              {plans.map((plan) => {
                const progress = ((plan.paid_count || 0) / (plan.total_count || 1)) * 100;
                return (
                  <tr key={plan.id} className="border-t border-gray-100 dark:border-[#30363D] hover:bg-gray-50 dark:hover:bg-[#1C2128]">
                    <td className="py-3 px-4">
                      <div className="font-medium text-gray-900 dark:text-white">{plan.customer_name}</div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">{plan.customer_phone}</div>
                    </td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{plan.product_name}</td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{plan.total_price.toLocaleString()} IQD</td>
                    <td className="py-3 px-4 text-gray-900 dark:text-white">{plan.remaining_amount.toLocaleString()} IQD</td>
                    <td className="py-3 px-4">
                      <div className="w-24 bg-gray-100 dark:bg-[#30363D] rounded-full h-2">
                        <div
                          className="bg-blue-600 rounded-full h-2"
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                      <span className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        {plan.paid_count || 0}/{plan.total_count}
                      </span>
                    </td>
                    <td className="py-3 px-4">{getStatusBadge(plan.status)}</td>
                    <td className="py-3 px-4">
                      <Link
                        href={`/installments/${plan.id}`}
                        className="text-[#3A86FF] hover:underline text-sm"
                      >
                        <Eye size={16} className="inline ml-1" />
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
                className="px-4 py-2 rounded-lg border border-[var(--border-color)] disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-4 py-2 text-[var(--text-primary)]">صفحة {page} من {totalPages}</span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-4 py-2 rounded-lg border border-[var(--border-color)] disabled:opacity-50"
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
