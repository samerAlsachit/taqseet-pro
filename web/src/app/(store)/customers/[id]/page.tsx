'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

interface Customer {
  id: string;
  full_name: string;
  phone: string;
  phone_alt: string;
  address: string;
  national_id: string;
  notes: string;
  created_at: string;
}

interface Installment {
  id: string;
  product_name: string;
  total_price: number;
  remaining_amount: number;
  status: string;
  start_date: string;
  end_date: string;
  installments_count: number;
  paid_count: number;
}

export default function CustomerDetailPage() {
  const router = useRouter();
  const params = useParams();
  const customerId = params.id as string;

  const [customer, setCustomer] = useState<Customer | null>(null);
  const [installments, setInstallments] = useState<Installment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchData = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    setLoading(true);
    try {
      // جلب بيانات العميل
      const customerRes = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/customers/${customerId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const customerData = await customerRes.json();

      if (!customerData.success) {
        setError(customerData.error || 'العميل غير موجود');
        return;
      }
      
      // الـ API يرجع customer داخل data.customer
      setCustomer(customerData.data.customer);
      
      // الأقساط موجودة في customerData.data.installment_plans
      setInstallments(customerData.data.installment_plans || []);
      
    } catch {
      setError('حدث خطأ في جلب البيانات');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (customerId) {
      fetchData();
    }
  }, [customerId]);

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

  if (loading) {
    return <LoadingSpinner />;
  }

  if (error || !customer) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-4 text-center">
          {error || 'العميل غير موجود'}
        </div>
        <div className="text-center mt-4">
          <Link href="/customers" className="text-blue-600 dark:text-blue-400 hover:underline">
            ← العودة إلى العملاء
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/customers" className="text-blue-600 dark:text-blue-400 hover:underline">
          ← العودة إلى العملاء
        </Link>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">ملف العميل</h1>
      </div>

      {/* معلومات العميل */}
      <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 mb-8">
        <div className="flex justify-between items-start mb-4">
          <h2 className="text-xl font-bold text-[var(--text-primary)]">معلومات العميل</h2>
          <Link
            href={`/customers/${customerId}/edit`}
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm transition"
          >
            ✏️ تعديل
          </Link>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <p className="text-[var(--text-secondary)] text-sm">الاسم الكامل</p>
            <p className="font-medium text-[var(--text-primary)]">{customer.full_name}</p>
          </div>
          <div>
            <p className="text-[var(--text-secondary)] text-sm">رقم الهاتف</p>
            <p className="font-medium text-[var(--text-primary)]">{customer.phone}</p>
          </div>
          {customer.phone_alt && (
            <div>
              <p className="text-[var(--text-secondary)] text-sm">هاتف إضافي</p>
              <p className="font-medium text-[var(--text-primary)]">{customer.phone_alt}</p>
            </div>
          )}
          {customer.national_id && (
            <div>
              <p className="text-[var(--text-secondary)] text-sm">الرقم الوطني</p>
              <p className="font-medium text-[var(--text-primary)]">{customer.national_id}</p>
            </div>
          )}
          {customer.address && (
            <div className="md:col-span-2">
              <p className="text-[var(--text-secondary)] text-sm">العنوان</p>
              <p className="font-medium text-[var(--text-primary)]">{customer.address}</p>
            </div>
          )}
          {customer.notes && (
            <div className="md:col-span-2">
              <p className="text-[var(--text-secondary)] text-sm">ملاحظات</p>
              <p className="font-medium text-[var(--text-primary)]">{customer.notes}</p>
            </div>
          )}
          <div>
            <p className="text-[var(--text-secondary)] text-sm">تاريخ التسجيل</p>
            <p className="font-medium text-[var(--text-primary)]">{new Date(customer.created_at).toLocaleDateString('ar-IQ')}</p>
          </div>
        </div>
      </div>

      {/* أقساط العميل */}
      <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-[var(--text-primary)]">الأقساط</h2>
          <Link
            href={`/installments/new?customer_id=${customerId}`}
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm transition"
          >
            + إضافة قسط جديد
          </Link>
        </div>

        {installments.length === 0 ? (
          <p className="text-[var(--text-secondary)] text-center py-8">لا توجد أقساط لهذا العميل</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)]">
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] font-semibold">المنتج</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] font-semibold">المبلغ الكلي</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] font-semibold">المتبقي</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] font-semibold">التقدم</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] font-semibold"></th>
                 </tr>
              </thead>
              <tbody>
                {installments.map((inst) => {
                  const progress = ((inst.paid_count || 0) / inst.installments_count) * 100;
                  return (
                    <tr key={inst.id} className="border-b border-[var(--border-color)] hover:bg-[var(--border-color)]">
                      <td className="py-3 px-4 text-[var(--text-primary)]">{inst.product_name}</td>
                      <td className="py-3 px-4 text-[var(--text-primary)]">{inst.total_price.toLocaleString()} IQD</td>
                      <td className="py-3 px-4 text-[var(--text-primary)]">{inst.remaining_amount.toLocaleString()} IQD</td>
                      <td className="py-3 px-4">
                        <div className="w-24 bg-[var(--border-color)] rounded-full h-2">
                          <div
                            className="bg-blue-600 rounded-full h-2"
                            style={{ width: `${progress}%` }}
                          />
                        </div>
                        <span className="text-xs text-[var(--text-secondary)] mt-1">
                          {inst.paid_count || 0}/{inst.installments_count}
                        </span>
                      </td>
                      <td className="py-3 px-4">{getStatusBadge(inst.status)}</td>
                      <td className="py-3 px-4">
                        <Link
                          href={`/installments/${inst.id}`}
                          className="text-blue-600 dark:text-blue-400 hover:underline"
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
        )}
      </div>
    </div>
  );
}
