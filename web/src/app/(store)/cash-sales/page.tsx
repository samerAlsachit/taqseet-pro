'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { DollarSign, Eye, Plus, Printer } from 'lucide-react';
import toast from 'react-hot-toast';

interface CashSale {
  id: string;
  product_name: string;
  customer_name: string;
  quantity: number;
  price: number;
  currency: string;
  sale_date: string;
  receipt_number: string;
  products?: {
    name: string;
    currency: string;
  };
}

export default function CashSalesPage() {
  const router = useRouter();
  const [sales, setSales] = useState<CashSale[]>([]);
  const [loading, setLoading] = useState(true);

  const handlePrint = async (saleId: string) => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/cash-sales/receipt/${saleId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        const { sale, store } = data.data;
        
        const printWindow = window.open('', '_blank');
        if (!printWindow) return;
        
        const html = `
          <!DOCTYPE html>
            <html dir="rtl">
              <head>
                <meta charset="UTF-8">
                <title>وصل بيع نقدي - ${store.name}</title>
                <style>
                  body { font-family: 'Tajawal', Arial, sans-serif; padding: 20px; max-width: 300px; margin: 0 auto; }
                  .receipt { border: 1px solid #ddd; padding: 20px; border-radius: 8px; }
                  .header { text-align: center; border-bottom: 1px solid #ddd; padding-bottom: 10px; margin-bottom: 20px; }
                  .header h1 { margin: 0; color: #0A192F; font-size: 20px; }
                  .info-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
                  .divider { border-top: 1px dashed #ddd; margin: 15px 0; }
                  .amount { font-size: 18px; font-weight: bold; text-align: center; color: #28A745; margin: 15px 0; }
                  .footer { text-align: center; font-size: 12px; color: #999; margin-top: 20px; }
                  @media print { body { padding: 0; } .no-print { display: none; }
                </style>
              </head>
              <body>
                <div class="receipt">
                  <div class="header">
                    <h1>${store.name}</h1>
                    <p>${store.receipt_header || 'بيع نقدي'}</p>
                  </div>
                  <div class="info-row"><span>رقم الوصل:</span><span>${sale.receipt_number}</span></div>
                  <div class="info-row"><span>التاريخ:</span><span>${new Date(sale.sale_date).toLocaleDateString('ar-IQ')}</span></div>
                  <div class="info-row"><span>المنتج:</span><span>${sale.products?.name || sale.product_name || '-'}</span></div>
                  ${sale.customer_name ? `<div class="info-row"><span>العميل:</span><span>${sale.customer_name}</span></div>` : ''}
                  <div class="divider"></div>
                  <div class="info-row"><span>الكمية:</span><span>${sale.quantity}</span></div>
                  <div class="info-row"><span>سعر الوحدة:</span><span>${sale.price.toLocaleString()} ${sale.currency}</span></div>
                  <div class="amount">الإجمالي: ${(sale.price * sale.quantity).toLocaleString()} ${sale.currency}</div>
                  ${sale.notes ? `<div class="info-row"><span>ملاحظات:</span><span>${sale.notes}</span></div>` : ''}
                  <div class="footer"><p>${store.receipt_footer || 'شكراً لثقتكم بنا'}</p></div>
                </div>
                <div class="no-print" style="text-align:center; margin-top:20px;">
                  <button onclick="window.print()" style="background:#3A86FF; color:white; padding:10px 20px; border:none; border-radius:5px; margin:5px;">طباعة</button>
                  <button onclick="window.close()" style="background:#DC3545; color:white; padding:10px 20px; border:none; border-radius:5px;">إغلاق</button>
                </div>
                <script>window.onload = () => setTimeout(() => window.print(), 500);</script>
              </body>
            </html>
        `;
        printWindow.document.write(html);
        printWindow.document.close();
      }
    } catch (error) {
      console.error('خطأ في الطباعة:', error);
      alert('حدث خطأ في طباعة الوصل');
    }
  };

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
      <div className="flex justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <DollarSign className="text-electric" size={28} />
          <h1 className="text-2xl font-bold text-navy dark:text-white">المبيعات النقدية</h1>
        </div>
        <Link
          href="/cash-sales/new"
          className="flex items-center gap-2 bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
        >
          <Plus size={18} />
          <span>بيع جديد</span>
        </Link>
      </div>

      {sales.length === 0 ? (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 text-center">
          <p className="text-text-primary mb-4">لا توجد مبيعات نقدية</p>
          <Link
            href="/cash-sales/new"
            className="inline-flex items-center gap-2 bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
          >
            <Plus size={18} />
            <span>أول بيع</span>
          </Link>
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
                    <td className="py-3 px-4">{sale.products?.name}</td>
                    <td className="py-3 px-4">{sale.customer_name || '-'}</td>
                    <td className="py-3 px-4">{sale.quantity}</td>
                    <td className="py-3 px-4 font-bold">{sale.price.toLocaleString()} {sale.currency}</td>
                    <td className="py-3 px-4">
                      <button onClick={() => handlePrint(sale.id)} className="text-electric hover:text-blue-700">
                        <Printer size={18} />
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
  );
}
