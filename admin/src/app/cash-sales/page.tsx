'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { DollarSign, Eye } from 'lucide-react';
import Link from 'next/link';

interface CashSale {
  id: string;
  product_name: string;
  customer_name: string;
  quantity: number;
  price: number;
  currency: string;
  sale_date: string;
  receipt_number: string;
}

export default function CashSalesPage() {
  const [sales, setSales] = useState<CashSale[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSales = async () => {
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/cash-sales`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) setSales(data.data.sales);
      } catch (error) {
        console.error('خطأ في جلب المبيعات', error);
      } finally {
        setLoading(false);
      }
    };
    fetchSales();
  }, []);

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center gap-2 mb-6">
          <DollarSign className="text-electric" size={28} />
          <h1 className="text-2xl font-bold text-navy dark:text-white">المبيعات النقدية</h1>
        </div>

        {sales.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 text-center">
            <p className="text-text-primary">لا توجد مبيعات نقدية</p>
          </div>
        ) : (
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <th className="text-right py-3 px-4">رقم الوصل</th>
                    <th className="text-right py-3 px-4">التاريخ</th>
                    <th className="text-right py-3 px-4">المنتج</th>
                    <th className="text-right py-3 px-4">العميل</th>
                    <th className="text-right py-3 px-4">الكمية</th>
                    <th className="text-right py-3 px-4">المبلغ</th>
                    <th className="text-right py-3 px-4"></th>
                  </tr>
                </thead>
                <tbody>
                  {sales.map((sale) => (
                    <tr key={sale.id} className="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                      <td className="py-3 px-4 font-mono text-sm">{sale.receipt_number}</td>
                      <td className="py-3 px-4">{new Date(sale.sale_date).toLocaleDateString('ar-IQ')}</td>
                      <td className="py-3 px-4">{sale.product_name}</td>
                      <td className="py-3 px-4">{sale.customer_name || '-'}</td>
                      <td className="py-3 px-4">{sale.quantity}</td>
                      <td className="py-3 px-4 font-bold">{sale.price.toLocaleString()} {sale.currency}</td>
                      <td className="py-3 px-4">
                        <button className="text-electric hover:text-blue-700">
                          <Eye size={18} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
