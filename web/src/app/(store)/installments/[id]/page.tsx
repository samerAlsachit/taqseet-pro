'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';

interface InstallmentDetail {
  id: string;
  customer_name: string;
  customer_phone: string;
  product_name: string;
  total_price: number;
  down_payment: number;
  financed_amount: number;
  remaining_amount: number;
  status: string;
  start_date: string;
  end_date: string;
  frequency: string;
  installment_amount: number;
  installments_count: number;
  notes: string;
}

interface ScheduleItem {
  id: string;
  installment_no: number;
  due_date: string;
  amount: number;
  status: string;
}

interface Payment {
  id: string;
  amount_paid: number;
  payment_date: string;
  receipt_number: string;
  notes: string;
}

export default function InstallmentDetailPage() {
  const router = useRouter();
  const params = useParams();
  const installmentId = params.id as string;

  const [plan, setPlan] = useState<InstallmentDetail | null>(null);
  const [schedule, setSchedule] = useState<ScheduleItem[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const handlePrintReceipt = (payment: Payment) => {
    // إنشاء محتوى الوصل للطباعة
    const printWindow = window.open('', '_blank');
    if (!printWindow) return;
    
    const html = `
      <!DOCTYPE html>
      <html dir="rtl">
      <head>
        <meta charset="UTF-8">
        <title>وصل دفع - تقسيط برو</title>
        <style>
          body {
            font-family: 'Tajawal', 'Arial', sans-serif;
            padding: 20px;
            max-width: 300px;
            margin: 0 auto;
          }
          .receipt {
            border: 1px solid #ddd;
            padding: 20px;
            border-radius: 8px;
          }
          .header {
            text-align: center;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
            margin-bottom: 20px;
          }
          .header h1 {
            margin: 0;
            color: #0A192F;
            font-size: 20px;
          }
          .header p {
            margin: 5px 0;
            color: #666;
            font-size: 12px;
          }
          .info {
            margin-bottom: 20px;
          }
          .info-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
          }
          .info-label {
            font-weight: bold;
            color: #333;
          }
          .info-value {
            color: #666;
          }
          .divider {
            border-top: 1px dashed #ddd;
            margin: 15px 0;
          }
          .amount {
            font-size: 18px;
            font-weight: bold;
            text-align: center;
            color: #28A745;
            margin: 15px 0;
          }
          .footer {
            text-align: center;
            font-size: 12px;
            color: #999;
            margin-top: 20px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
          }
          @media print {
            body {
              padding: 0;
            }
            .no-print {
              display: none;
            }
          }
        </style>
      </head>
      <body>
        <div class="receipt">
          <div class="header">
            <h1>تقسيط برو</h1>
            <p>${plan?.customer_name || ''}</p>
          </div>
          
          <div class="info">
            <div class="info-row">
              <span class="info-label">رقم الوصل:</span>
              <span class="info-value">${payment.receipt_number}</span>
            </div>
            <div class="info-row">
              <span class="info-label">التاريخ:</span>
              <span class="info-value">${new Date(payment.payment_date).toLocaleDateString('ar-IQ')}</span>
            </div>
            <div class="info-row">
              <span class="info-label">المنتج:</span>
              <span class="info-value">${plan?.product_name || ''}</span>
            </div>
          </div>
          
          <div class="divider"></div>
          
          <div class="amount">
            المبلغ: ${payment.amount_paid.toLocaleString()} IQD
          </div>
          
          <div class="divider"></div>
          
          <div class="info">
            <div class="info-row">
              <span class="info-label">المبلغ المتبقي:</span>
              <span class="info-value">${plan?.remaining_amount?.toLocaleString() || '0'} IQD</span>
            </div>
            ${payment.notes ? `
            <div class="info-row">
              <span class="info-label">ملاحظات:</span>
              <span class="info-value">${payment.notes}</span>
            </div>
            ` : ''}
          </div>
          
          <div class="footer">
            <p>شكراً لثقتكم بنا</p>
            <p>تقسيط برو - نظام إدارة الأقساط</p>
          </div>
        </div>
        
        <div class="no-print" style="text-align: center; margin-top: 20px;">
          <button onclick="window.print()" style="padding: 10px 20px; margin: 5px; background: #3A86FF; color: white; border: none; border-radius: 5px; cursor: pointer;">طباعة</button>
          <button onclick="window.close()" style="padding: 10px 20px; margin: 5px; background: #DC3545; color: white; border: none; border-radius: 5px; cursor: pointer;">إغلاق</button>
        </div>
        
        <script>
          // طباعة تلقائية عند فتح النافذة
          window.onload = () => {
            setTimeout(() => {
              window.print();
            }, 500);
          };
        </script>
      </body>
      </html>
    `;
    
    printWindow.document.write(html);
    printWindow.document.close();
  };

  const handleSendWhatsApp = (payment: Payment) => {
    const message = `*تقسيط برو - وصل دفع*\n\nرقم الوصل: ${payment.receipt_number}\nالتاريخ: ${new Date(payment.payment_date).toLocaleDateString('ar-IQ')}\nالعميل: ${plan?.customer_name}\nالمنتج: ${plan?.product_name}\n\nالمبلغ المدفوع: ${payment.amount_paid.toLocaleString()} IQD\nالمبلغ المتبقي: ${plan?.remaining_amount?.toLocaleString()} IQD\n\n${payment.notes ? `ملاحظات: ${payment.notes}\n\n` : ''}شكراً لثقتكم بنا\nتقسيط برو`;
    
    const encodedMessage = encodeURIComponent(message);
    const phoneNumber = plan?.customer_phone?.replace(/[^0-9]/g, '');
    
    if (!phoneNumber) {
      alert('رقم هاتف العميل غير متوفر');
      return;
    }
    
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedMessage}`;
    window.open(whatsappUrl, '_blank');
  };
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [selectedSchedule, setSelectedSchedule] = useState<ScheduleItem | null>(null);
  const [paymentAmount, setPaymentAmount] = useState(0);
  const [paymentNotes, setPaymentNotes] = useState('');
  const [paymentLoading, setPaymentLoading] = useState(false);

  const fetchData = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/installments/${installmentId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await res.json();
      if (data.success) {
        setPlan(data.data.plan);
        setSchedule(data.data.installments);
        setPayments(data.data.payments);
      } else {
        setError(data.error || 'القسط غير موجود');
      }
    } catch {
      setError('حدث خطأ في جلب البيانات');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (installmentId) {
      fetchData();
    }
  }, [installmentId]);

  const handlePayment = async () => {
    if (!selectedSchedule) return;

    const token = localStorage.getItem('token');
    setPaymentLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/payments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({
          plan_id: installmentId,
          schedule_id: selectedSchedule.id,
          amount_paid: paymentAmount,
          payment_date: new Date().toISOString().split('T')[0],
          notes: paymentNotes
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowPaymentModal(false);
        fetchData();
      } else {
        alert(data.error || 'فشل في تسجيل الدفعة');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
    } finally {
      setPaymentLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'paid':
        return <span className="px-2 py-1 rounded-full text-sm bg-success/10 text-success">مدفوع</span>;
      case 'pending':
        return <span className="px-2 py-1 rounded-full text-sm bg-warning/10 text-warning">قيد الانتظار</span>;
      case 'overdue':
        return <span className="px-2 py-1 rounded-full text-sm bg-danger/10 text-danger">متأخر</span>;
      default:
        return <span className="px-2 py-1 rounded-full text-sm bg-gray-100">{status}</span>;
    }
  };

  const getPlanStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <span className="px-3 py-1 rounded-full text-sm bg-success/10 text-success">نشط</span>;
      case 'completed':
        return <span className="px-3 py-1 rounded-full text-sm bg-electric/10 text-electric">مكتمل</span>;
      case 'overdue':
        return <span className="px-3 py-1 rounded-full text-sm bg-danger/10 text-danger">متأخر</span>;
      default:
        return <span className="px-3 py-1 rounded-full text-sm bg-gray-100">{status}</span>;
    }
  };

  const openPaymentModal = (item: ScheduleItem) => {
    setSelectedSchedule(item);
    setPaymentAmount(item.amount);
    setPaymentNotes('');
    setShowPaymentModal(true);
  };

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  if (error || !plan) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-4 text-center">
          {error || 'القسط غير موجود'}
        </div>
        <div className="text-center mt-4">
          <Link href="/installments" className="text-electric hover:underline">
            ← العودة إلى الأقساط
          </Link>
        </div>
      </div>
    );
  }

  const paidCount = schedule.filter(s => s.status === 'paid').length;
  const progress = (paidCount / schedule.length) * 100;

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/installments" className="text-electric hover:underline">
          ← العودة إلى الأقساط
        </Link>
        <h1 className="text-2xl font-bold text-navy">تفاصيل القسط</h1>
      </div>

      {/* معلومات القسط */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-8">
        <div className="flex justify-between items-start mb-4">
          <h2 className="text-xl font-bold text-navy">معلومات القسط</h2>
          {getPlanStatusBadge(plan.status)}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <p className="text-text-primary text-sm">العميل</p>
            <p className="font-medium">{plan.customer_name}</p>
            <p className="text-sm text-text-primary/70">{plan.customer_phone}</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">المنتج</p>
            <p className="font-medium">{plan.product_name}</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">المبلغ الكلي</p>
            <p className="font-medium">{plan.total_price.toLocaleString()} IQD</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">المبلغ المتبقي</p>
            <p className="font-medium text-danger">{plan.remaining_amount.toLocaleString()} IQD</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">الدفعة المقدمة</p>
            <p className="font-medium">{plan.down_payment.toLocaleString()} IQD</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">قيمة القسط</p>
            <p className="font-medium">{plan.installment_amount.toLocaleString()} IQD</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">نظام الدفع</p>
            <p className="font-medium">{plan.frequency === 'monthly' ? 'شهري' : plan.frequency === 'weekly' ? 'أسبوعي' : 'يومي'}</p>
          </div>
          <div>
            <p className="text-text-primary text-sm">المدة</p>
            <p className="font-medium">{plan.installments_count} قسط</p>
          </div>
        </div>
        
        <div className="mt-4">
          <div className="flex justify-between text-sm mb-1">
            <span>التقدم</span>
            <span>{paidCount}/{plan.installments_count} قسط مدفوع</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-electric rounded-full h-2"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {plan.notes && (
          <div className="mt-4 p-3 bg-gray-bg rounded-lg">
            <p className="text-text-primary text-sm">ملاحظات</p>
            <p className="text-text-primary">{plan.notes}</p>
          </div>
        )}
      </div>

      {/* جدول الأقساط */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-8">
        <h2 className="text-xl font-bold text-navy mb-4">جدول الأقساط</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="text-right py-3 px-4">#</th>
                <th className="text-right py-3 px-4">تاريخ الاستحقاق</th>
                <th className="text-right py-3 px-4">المبلغ</th>
                <th className="text-right py-3 px-4">الحالة</th>
                <th className="text-right py-3 px-4"></th>
               </tr>
            </thead>
            <tbody>
              {schedule.map((item) => (
                <tr key={item.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="py-3 px-4">{item.installment_no}</td>
                  <td className="py-3 px-4">{new Date(item.due_date).toLocaleDateString('ar-IQ')}</td>
                  <td className="py-3 px-4">{item.amount.toLocaleString()} IQD</td>
                  <td className="py-3 px-4">{getStatusBadge(item.status)}</td>
                  <td className="py-3 px-4">
                    {item.status === 'pending' && plan.status === 'active' && (
                      <button
                        onClick={() => openPaymentModal(item)}
                        className="bg-electric hover:bg-blue-600 text-white px-3 py-1 rounded-lg text-sm transition"
                      >
                        تسديد
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
           </table>
        </div>
      </div>

      {/* سجل الدفعات */}
      {payments.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-navy mb-4">سجل الدفعات</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-right py-3 px-4">رقم الوصل</th>
                  <th className="text-right py-3 px-4">التاريخ</th>
                  <th className="text-right py-3 px-4">المبلغ</th>
                  <th className="text-right py-3 px-4">ملاحظات</th>
                  <th className="text-right py-3 px-4"></th>
                 </tr>
              </thead>
              <tbody>
                {payments.map((payment) => (
                  <tr key={payment.id} className="border-b border-gray-100">
                    <td className="py-3 px-4 font-mono text-sm">{payment.receipt_number}</td>
                    <td className="py-3 px-4">{new Date(payment.payment_date).toLocaleDateString('ar-IQ')}</td>
                    <td className="py-3 px-4">{payment.amount_paid.toLocaleString()} IQD</td>
                    <td className="py-3 px-4">{payment.notes || '-'}</td>
                    <td className="py-3 px-4">
                      <div className="flex gap-2">
                        <button
                          onClick={() => handlePrintReceipt(payment)}
                          className="text-electric hover:underline text-sm"
                        >
                          🖨️ طباعة
                        </button>
                        <button
                          onClick={() => handleSendWhatsApp(payment)}
                          className="text-success hover:underline text-sm"
                        >
                          📱 واتساب
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
             </table>
          </div>
        </div>
      )}

      {/* Modal تسديد */}
      {showPaymentModal && selectedSchedule && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-xl font-bold text-navy mb-4">تسديد قسط</h2>
            <div className="mb-4">
              <p className="text-text-primary">القسط رقم {selectedSchedule.installment_no}</p>
              <p className="text-text-primary">تاريخ الاستحقاق: {new Date(selectedSchedule.due_date).toLocaleDateString('ar-IQ')}</p>
              <p className="text-text-primary font-bold mt-2">المبلغ المستحق: {selectedSchedule.amount.toLocaleString()} IQD</p>
            </div>
            <div className="mb-4">
              <label className="block text-text-primary mb-2">المبلغ المدفوع</label>
              <input
                type="number"
                value={paymentAmount}
                onChange={(e) => setPaymentAmount(parseInt(e.target.value) || 0)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              />
            </div>
            <div className="mb-6">
              <label className="block text-text-primary mb-2">ملاحظات</label>
              <textarea
                value={paymentNotes}
                onChange={(e) => setPaymentNotes(e.target.value)}
                rows={2}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={handlePayment}
                disabled={paymentLoading || paymentAmount <= 0}
                className="flex-1 bg-success hover:bg-green-600 text-white py-2 rounded-lg transition disabled:opacity-50"
              >
                {paymentLoading ? 'جاري التسديد...' : 'تأكيد التسديد'}
              </button>
              <button
                onClick={() => setShowPaymentModal(false)}
                className="flex-1 border border-gray-300 text-text-primary hover:bg-gray-50 py-2 rounded-lg transition"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
