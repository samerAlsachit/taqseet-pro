'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { connectToBluetoothPrinter, printReceipt, isBluetoothAvailable } from '@/lib/bluetoothPrint';
import toast from 'react-hot-toast';
import { Printer, MessageCircle } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

interface InstallmentPlan {
  id: string;
  customer_id: string;
  product_id: string;
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
  currency: string;
  exchange_rate: number;
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

  const [plan, setPlan] = useState<any>(null);
  const [schedule, setSchedule] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [bluetoothPrinter, setBluetoothPrinter] = useState<any>(null);
  const [connecting, setConnecting] = useState(false);
  
  // أضف state لجلب إعدادات المحل
  const [storeSettings, setStoreSettings] = useState<any>(null);

  // في useEffect، جلب الإعدادات
  const fetchStoreSettings = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/settings`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        setStoreSettings(data.data);
      }
    } catch (error) {
      // خطأ في جلب إعدادات المحل
    }
  };

  // دالة طباعة البلوتوث
  const handleBluetoothPrint = async (payment: Payment) => {
    if (!navigator.bluetooth) {
      alert('المتصفح لا يدعم تقنية Bluetooth. يرجى استخدام Chrome أو Edge.');
      return;
    }

    setConnecting(true);
    try {
      const device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: ['000018f0-0000-1000-8000-00805f9b34fb']
      });

      const server = await device.gatt?.connect();
      if (!server) throw new Error('فشل الاتصال بالطابعة');

      const service = await server.getPrimaryService('000018f0-0000-1000-8000-00805f9b34fb');
      const characteristic = await service.getCharacteristic('00002af1-0000-1000-8000-00805f9b34fb');

      const receiptText = `
${storeSettings?.receipt_header || 'مرساة'}
================================
رقم الوصل: ${payment.receipt_number}
التاريخ: ${new Date(payment.payment_date).toLocaleDateString('ar-IQ')}
العميل: ${plan?.customer_name}
المنتج: ${plan?.product_name}
================================
المبلغ المدفوع: ${payment.amount_paid.toLocaleString()} IQD
المبلغ المتبقي: ${plan?.remaining_amount?.toLocaleString()} IQD
================================
${payment.notes ? `ملاحظات: ${payment.notes}` : ''}
${storeSettings?.receipt_footer || 'شكراً لثقتكم'}
================================
    `;

      const encoder = new TextEncoder();
      const data = encoder.encode(receiptText);
      await characteristic.writeValue(data);

      alert('تم إرسال الوصل للطباعة بنجاح');
    } catch (error) {
      console.error('خطأ في الطباعة:', error);
      alert('فشل في الطباعة: ' + (error as Error).message);
    } finally {
      setConnecting(false);
    }
  };

  // دالة الطباعة العادية
  const handlePrintReceipt = async (payment: Payment) => {
  // جلب إعدادات المحل الطازجة
  const token = localStorage.getItem('token');
  let storeName = 'مرساة';
  let receiptHeader = 'شكراً لثقتكم بنا';
  let receiptFooter = 'مرساة - نظام إدارة الأقساط';  
  try {
    const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/settings`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (data.success) {
      storeName = data.data.name || storeName;
      receiptHeader = data.data.receipt_header || receiptHeader;
      receiptFooter = data.data.receipt_footer || receiptFooter;
    }
  } catch (error) {
    // استخدم القيم الافتراضية
  }

  const productsText = plan?.products && plan.products.length > 0
    ? plan.products.map((p: any) => `${p.product_name} (${p.quantity})`).join(', ')
    : plan?.product_name;

  const printWindow = window.open('', '_blank');
  if (!printWindow) return;  
  const html = `
    <!DOCTYPE html>
    <html dir="rtl">
    <head>
      <meta charset="UTF-8">
      <title>وصل دفع - ${storeName}</title>
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
          <h1>${storeName}</h1>
          <p>${receiptHeader}</p>
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
            <span class="info-label">المنتجات:</span>
            <span class="info-value">${productsText}</span>
          </div>
        </div>
        
        <div class="divider"></div>
        
        <div class="amount">
          المبلغ: ${payment?.amount_paid ? payment.amount_paid.toLocaleString() : '0'} IQD
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
          <p>${receiptFooter}</p>
        </div>
      </div>
      
      <div class="no-print" style="text-align: center; margin-top: 20px;">
        <button onclick="window.print()" style="padding: 10px 20px; margin:5px; background: #3A86FF; color: white; border: none; border-radius:5px; cursor: pointer;">طباعة</button>
        <button onclick="window.close()" style="padding: 10px 20px; margin: 5px; background: #DC3545; color: white; border: none; border-radius: 5px; cursor: pointer;">إغلاق</button>
      </div>
      
      <script>
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
    const productsText = plan.products && plan.products.length > 0
      ? plan.products.map((p: any) => p.product_name + ' (' + p.quantity + ')').join(', ')
      : plan.product_name;

    const message = `
*مرساة - وصل دفع*

رقم الوصل: ${payment.receipt_number}
التاريخ: ${new Date(payment.payment_date).toLocaleDateString('ar-IQ')}
العميل: ${plan?.customer_name}
المنتجات: ${productsText}

المبلغ المدفوع: ${payment?.amount_paid ? payment.amount_paid.toLocaleString() : '0'} IQD
المبلغ المتبقي: ${plan?.remaining_amount ? plan.remaining_amount.toLocaleString() : '0'} IQD

${payment.notes ? `ملاحظات: ${payment.notes}` : ''}

شكراً لثقتكم بنا
مرساة
`.trim();
    
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

  const fetchInstallmentData = async () => {
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
    const result = await res.json();
    
    if (result.success) {
      setPlan(result.data.plan);
      setSchedule(result.data.installments);
      setPayments(result.data.payments);
    } else {
      setError(result.error || 'القسط غير موجود');
    }
  } catch (err) {
    setError('حدث خطأ في جلب البيانات');
  } finally {
    setLoading(false);
  }
};

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
      } catch(e) {
        // Cannot decode token
      }
    }

    if (installmentId) {
      fetchInstallmentData();
    }
  }, [router, installmentId]);

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
        toast.success('تم تسجيل الدفعة بنجاح');
        setShowPaymentModal(false);
        fetchInstallmentData();
      } else {
        toast.error(data.error || 'فشل في تسجيل الدفعة');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
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
        return <span className="px-2 py-1 rounded-full text-sm bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-200">{status}</span>;
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
    return <LoadingSpinner />;
  }

  if (error || !plan) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-4 text-center">
          {error || 'القسط غير موجود'}
        </div>
        <div className="text-center mt-4">
          <Link href="/installments" className="text-blue-600 dark:text-blue-400 hover:underline">
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
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">تفاصيل القسط</h1>
      </div>

      
      {/* معلومات القسط */}
      <div className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6 mb-8">
        <div className="flex justify-between items-start mb-4">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">معلومات القسط</h2>
          {plan && getPlanStatusBadge(plan?.status)}
        </div>
        {plan && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <p className="text-[var(--text-secondary)] text-sm">العميل</p>
              <p className="font-medium text-[var(--text-primary)]">{plan.customer_name || 'غير محدد'}</p>
              <p className="text-sm text-[var(--text-secondary)]">{plan.customer_phone || ''}</p>
            </div>
            <div>
              <p className="text-text-primary text-sm">المنتجات</p>
              {plan?.products && plan.products.length > 0 ? (
                <div className="mt-1 space-y-1">
                  {plan.products.map((p: any, idx: number) => (
                    <div key={idx} className="text-sm">
                      • {p.product_name} ({p.quantity} × {p.price?.toLocaleString()} {plan.currency})
                    </div>
                  ))}
                </div>
              ) : (
                <p className="font-medium">{plan?.product_name || 'غير محدد'}</p>
              )}
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">المبلغ الكلي</p>
              <p className="font-medium text-[var(--text-primary)]">{plan.total_price?.toLocaleString() || 0} {plan.currency === 'USD' ? 'USD' : 'IQD'}</p>
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">المبلغ المتبقي</p>
              <p className="font-medium text-gray-900 dark:text-white text-danger">{plan.remaining_amount?.toLocaleString() || 0} {plan.currency === 'USD' ? 'USD' : 'IQD'}</p>
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">الدفعة المقدمة</p>
              <p className="font-medium text-[var(--text-primary)]">{plan.down_payment?.toLocaleString() || 0} {plan.currency === 'USD' ? 'USD' : 'IQD'}</p>
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">قيمة القسط</p>
              <p className="font-medium text-[var(--text-primary)]">{plan.installment_amount?.toLocaleString() || 0} {plan.currency === 'USD' ? 'USD' : 'IQD'}</p>
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">نظام الدفع</p>
              <p className="font-medium text-[var(--text-primary)]">
                {plan.frequency === 'monthly' ? 'شهري' : plan.frequency === 'weekly' ? 'أسبوعي' : 'يومي'}
              </p>
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">المدة</p>
              <p className="font-medium text-[var(--text-primary)]">{plan.installments_count} قسط</p>
            </div>
            <div>
              <p className="text-[var(--text-secondary)] text-sm">العملة</p>
              <p className="font-medium text-[var(--text-primary)]">{plan?.currency === 'USD' ? 'دولار أمريكي (USD)' : 'دينار عراقي (IQD)'}</p>
              {plan?.exchange_rate > 1 && (
                <p className="text-xs text-gray-500 dark:text-gray-400">سعر الصرف: 1 USD = {plan.exchange_rate} IQD</p>
              )}
            </div>
          </div>
        )}
        
        <div className="mt-4">
          <div className="flex justify-between text-sm mb-1">
            <span>التقدم</span>
            <span>{paidCount}/{plan?.installments_count || 0} قسط مدفوع</span>
          </div>
          <div className="w-full bg-gray-100 dark:bg-[#30363D] rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${(paidCount / (plan?.installments_count || 1)) * 100}%` }}
            ></div>
          </div>
        </div>

        {plan?.notes && (
          <div className="mt-4 p-3 bg-gray-50 dark:bg-[#1C2128] rounded-lg">
            <p className="text-gray-600 dark:text-gray-400 text-sm">ملاحظات</p>
            <p className="text-gray-900 dark:text-white">{plan.notes}</p>
          </div>
        )}
      </div>

      {/* جدول الأقساط */}
      <div className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6 mb-8">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">جدول الأقساط</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-t border-gray-100 dark:border-[#30363D] bg-gray-50 dark:bg-[#1C2128]">
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">#</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">تاريخ الاستحقاق</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">المبلغ</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold">الحالة</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400 font-semibold"></th>
              </tr>
            </thead>
            <tbody>
              {schedule.length > 0 ? (
              schedule.map((item) => (
                <tr key={item.id} className="border-t border-gray-100 dark:border-[#30363D] hover:bg-gray-50 dark:hover:bg-[#1C2128]">
                  <td className="py-3 px-4 text-gray-900 dark:text-white">{item.installment_no}</td>
                  <td className="py-3 px-4 text-gray-900 dark:text-white">{new Date(item.due_date).toLocaleDateString('ar-IQ')}</td>
                  <td className="py-3 px-4 text-gray-900 dark:text-white">{item?.amount ? item.amount.toLocaleString() : '0'} {plan?.currency === 'USD' ? 'USD' : 'IQD'}</td>
                  <td className="py-3 px-4">{getStatusBadge(item.status)}</td>
                  <td className="py-3 px-4">
                    {item.status === 'pending' && (
                      <button
                        onClick={() => openPaymentModal(item)}
                        className="bg-[#28A745] hover:bg-[#1F8B3A] text-white px-3 py-1 rounded-lg text-sm transition"
                      >
                        تسديد
                      </button>
                    )}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="text-center py-8 text-gray-500 dark:text-gray-400">
                  لا توجد أقساط مسجلة
                </td>
              </tr>
            )}
            </tbody>
          </table>
        </div>
      </div>

      {/* سجل الدفعات */}
      {payments.length > 0 && (
        <div className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">سجل الدفعات</h2>
          <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">سجل الدفعات</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] dark:border-gray-700 bg-[var(--bg-primary)] dark:bg-gray-800">
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] dark:text-gray-400 font-semibold">رقم الوصل</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] dark:text-gray-400 font-semibold">التاريخ</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] dark:text-gray-400 font-semibold">المبلغ</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] dark:text-gray-400 font-semibold">ملاحظات</th>
                  <th className="text-right py-3 px-4 text-[var(--text-secondary)] dark:text-gray-400 font-semibold"></th>
                 </tr>
              </thead>
              <tbody>
                {payments.length > 0 ? (
                payments.map((payment) => (
                  <tr key={payment.id} className="border-b border-[var(--border-color)] dark:border-gray-700 hover:bg-[var(--border-color)]">
                    <td className="py-3 px-4 text-[var(--text-primary)] font-mono text-sm">{payment.receipt_number}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{new Date(payment.payment_date).toLocaleDateString('ar-IQ')}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{payment?.amount_paid ? payment.amount_paid.toLocaleString() : '0'} {plan?.currency === 'USD' ? 'USD' : 'IQD'}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{payment.notes || '-'}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      <div className="flex gap-2">
                        <button
                          onClick={() => handlePrintReceipt(payment)}
                          className="text-[#3A86FF] hover:underline text-sm"
                        >
                          <Printer size={16} className="inline ml-1" />
                          طباعة
                        </button>
                        <button
                          onClick={() => handleBluetoothPrint(payment)}
                          disabled={connecting}
                          className="text-[#3A86FF] hover:underline text-sm"
                        >
                          <Printer size={16} className="inline ml-1" />
                          {connecting ? 'جاري الاتصال...' : 'طباعة بلوتوث'}
                        </button>
                        <button
                          onClick={() => handleSendWhatsApp(payment)}
                          className="text-[#28A745] hover:underline text-sm"
                        >
                          <MessageCircle size={16} className="inline ml-1" />
                          WhatsApp
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr><td colSpan={4} className="text-center py-8">لا توجد دفعات</td></tr>
              )}
              </tbody>
             </table>
          </div>
        </div>
      )}

      {/* Modal تسديد */}
      {showPaymentModal && selectedSchedule && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[var(--card-bg)] rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">تسديد قسط</h2>
            <div className="mb-4">
              <p className="text-[var(--text-primary)]">القسط رقم {selectedSchedule.installment_no}</p>
              <p className="text-[var(--text-primary)]">تاريخ الاستحقاق: {new Date(selectedSchedule.due_date).toLocaleDateString('ar-IQ')}</p>
              <p className="text-[var(--text-primary)] font-bold mt-2">المبلغ المستحق: {selectedSchedule?.amount ? selectedSchedule.amount.toLocaleString() : '0'} IQD</p>
            </div>
            <div className="mb-4">
              <label className="block text-[var(--text-secondary)] mb-2">المبلغ المدفوع</label>
              <input
                type="number"
                value={paymentAmount}
                onChange={(e) => setPaymentAmount(parseInt(e.target.value) || 0)}
                className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-[var(--card-bg)] text-[var(--text-primary)]"
              />
            </div>
            <div className="mb-6">
              <label className="block text-[var(--text-secondary)] mb-2">ملاحظات</label>
              <textarea
                value={paymentNotes}
                onChange={(e) => setPaymentNotes(e.target.value)}
                rows={2}
                className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-[var(--card-bg)] text-[var(--text-primary)]"
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={handlePayment}
                disabled={paymentLoading || paymentAmount <= 0}
                className="bg-[#28A745] hover:bg-[#1F8B3A] text-white px-3 py-1 rounded-lg text-sm transition"
              >
                {paymentLoading ? 'جاري التسديد...' : 'تأكيد التسديد'}
              </button>
              <button
                onClick={() => setShowPaymentModal(false)}
                className="btn-outline"
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
