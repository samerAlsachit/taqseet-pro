'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Customer {
  id: string;
  full_name: string;
  phone: string;
}

interface Installment {
  id: string;
  customer_name: string;
  product_name: string;
  remaining_amount: number;
  next_due_date: string;
  next_due_amount: number;
  installment_amount: number;
  total_count: number;
  paid_count: number;
}

export default function NewPaymentPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const preSelectedCustomer = searchParams.get('customer_id');

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [customers, setCustomers] = useState<Customer[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState('');
  const [showCustomerDropdown, setShowCustomerDropdown] = useState(false);
  const [installments, setInstallments] = useState<Installment[]>([]);
  const [selectedInstallment, setSelectedInstallment] = useState('');
  const [paymentAmount, setPaymentAmount] = useState(0);
  const [paymentNotes, setPaymentNotes] = useState('');
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().split('T')[0]);

  // أضف هذه الـ states
  const [paymentType, setPaymentType] = useState<'installment' | 'full'>('installment');
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed'>('percentage');
  const [discountValue, setDiscountValue] = useState(0);
  const [finalAmount, setFinalAmount] = useState(0);

  // جلب العملاء
  useEffect(() => {
    const fetchCustomers = async () => {
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers?limit=200`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          setCustomers(data.data.customers);
          if (preSelectedCustomer) {
            const customer = data.data.customers.find((c: Customer) => c.id === preSelectedCustomer);
            if (customer) {
              setSelectedCustomer(customer.id);
              setSearchTerm(customer.full_name);
            }
          }
        }
      } catch (err) {
        console.error('خطأ في جلب العملاء', err);
      }
    };
    fetchCustomers();
  }, [preSelectedCustomer]);

  // فلترة العملاء حسب البحث
  const filteredCustomers = customers.filter(customer =>
    customer.full_name.includes(searchTerm) || customer.phone.includes(searchTerm)
  );

  // اختيار عميل
  const handleSelectCustomer = (customer: Customer) => {
    setSelectedCustomer(customer.id);
    setSearchTerm(customer.full_name);
    setShowCustomerDropdown(false);
    setSelectedInstallment('');
    setInstallments([]);
  };

  // جلب الأقساط النشطة للعميل
  useEffect(() => {
    if (!selectedCustomer) {
      setInstallments([]);
      return;
    }

    const fetchInstallments = async () => {
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/installments?customer_id=${selectedCustomer}&status=active`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          const formatted = data.data.installments.map((inst: any) => ({
            id: inst.id,
            customer_name: inst.customer_name,
            product_name: inst.product_name,
            remaining_amount: inst.remaining_amount,
            next_due_date: inst.next_due_date || inst.start_date,
            next_due_amount: inst.installment_amount,
            installment_amount: inst.installment_amount,
            total_count: inst.total_count,
            paid_count: inst.paid_count,
            currency: inst.currency || 'IQD'  // <-- أضف هذا السطر
          }));
          setInstallments(formatted);
        }
      } catch (err) {
        console.error('خطأ في جلب الأقساط', err);
      }
    };
    fetchInstallments();
  }, [selectedCustomer]);

  // عند اختيار قسط، تعيين المبلغ المستحق
  useEffect(() => {
    const installment = installments.find(i => i.id === selectedInstallment);
    if (installment) {
      setPaymentAmount(installment.next_due_amount);
    } else {
      setPaymentAmount(0);
    }
  }, [selectedInstallment, installments]);

  // حساب المبلغ النهائي بعد التخفيض
  useEffect(() => {
    const installment = installments.find(i => i.id === selectedInstallment);
    if (!installment) return;
    
    const remaining = installment.remaining_amount;
    
    if (paymentType === 'full') {
      let discounted = remaining;
      if (discountValue > 0) {
        if (discountType === 'percentage') {
          discounted = remaining - (remaining * discountValue / 100);
        } else {
          discounted = remaining - discountValue;
        }
      }
      setFinalAmount(Math.max(0, discounted));
      setPaymentAmount(Math.max(0, discounted));
    } else {
      setFinalAmount(installment.next_due_amount);
      setPaymentAmount(installment.next_due_amount);
    }
  }, [paymentType, discountType, discountValue, selectedInstallment, installments]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedInstallment) {
      setError('الرجاء اختيار قسط');
      return;
    }
    if (paymentAmount <= 0) {
      setError('المبلغ غير صحيح');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    const token = localStorage.getItem('token');
    try {
      if (paymentType === 'full') {
        // استخدام endpoint التسديد الكامل
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/payments/full-settlement`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}` 
          },
          body: JSON.stringify({
            plan_id: selectedInstallment,
            amount_paid: paymentAmount,
            payment_date: paymentDate,
            notes: `تسديد كامل المبلغ${discountValue > 0 ? ` مع تخفيض ${discountType === 'percentage' ? `${discountValue}%` : `${discountValue} IQD`}` : ''} - ${paymentNotes}`,
            discount_type: discountValue > 0 ? discountType : null,
            discount_value: discountValue > 0 ? discountValue : null
          })
        });

        const data = await res.json();
        if (data.success) {
          setSuccess(data.message);
          setTimeout(() => {
            router.push(`/installments/${selectedInstallment}`);
          }, 2000);
        } else {
          setError(data.error || 'فشل في تسجيل الدفعة');
        }
      } else {
        // التسديد العادي (قسط واحد)
        // جلب تفاصيل القسط
        const planRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/installments/${selectedInstallment}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const planData = await planRes.json();
        
        if (!planData.success) {
          setError('فشل في جلب تفاصيل القسط');
          setLoading(false);
          return;
        }

        let scheduleIds: string[] = [];
        
        if (paymentType === 'full') {
          // جلب جميع الأقساط المتبقية
          const pendingSchedules = planData.data.installments.filter((s: any) => s.status === 'pending');
          scheduleIds = pendingSchedules.map((s: any) => s.id);
        } else {
          // جلب القسط التالي فقط
          const nextSchedule = planData.data.installments.find((s: any) => s.status === 'pending');
          if (!nextSchedule) {
            setError('لا توجد أقساط مستحقة للدفع');
            setLoading(false);
            return;
          }
          scheduleIds = [nextSchedule.id];
        }

        // إنشاء دفعة واحدة لكل قسط
        for (const scheduleId of scheduleIds) {
          const scheduleAmount = scheduleIds.length === 1 
            ? paymentAmount 
            : (paymentAmount / scheduleIds.length); // توزيع المبلغ على الأقساط

          const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/payments`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${token}` 
            },
            body: JSON.stringify({
              plan_id: selectedInstallment,
              schedule_id: scheduleId,
              amount_paid: Math.round(scheduleAmount),
              payment_date: paymentDate,
              notes: paymentType === 'full' 
                ? `تسديد كامل المبلغ${discountValue > 0 ? ` مع تخفيض ${discountType === 'percentage' ? `${discountValue}%` : `${discountValue} IQD`}` : ''} - ${paymentNotes}` 
                : paymentNotes
            })
          });
          
          const data = await res.json();
          if (!data.success) {
            throw new Error(data.error);
          }
        }

        setSuccess(`تم تسجيل الدفعة بنجاح (${scheduleIds.length} قسط)`);
        setTimeout(() => {
          router.push(`/installments/${selectedInstallment}`);
        }, 2000);
      }
    } catch (err: any) {
      setError(err.message || 'فشل في تسجيل الدفعة');
    } finally {
      setLoading(false);
    }
  };

  const selectedCustomerData = customers.find(c => c.id === selectedCustomer);
  const selectedInstallmentData = installments.find(i => i.id === selectedInstallment);

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/dashboard" className="text-electric hover:underline">
          ← العودة إلى لوحة التحكم
        </Link>
        <h1 className="text-2xl font-bold text-navy dark:text-white">تسديد دفعة</h1>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/30 text-danger border border-danger/20 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      {success && (
        <div className="bg-green-50 dark:bg-green-900/30 text-success border border-success/20 rounded-lg p-3 mb-6">
          {success}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
        {/* اختيار العميل مع بحث */}
        <div className="mb-6 relative">
          <label className="block text-text-primary dark:text-gray-300 mb-2">العميل *</label>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setShowCustomerDropdown(true);
              if (e.target.value === '') {
                setSelectedCustomer('');
              }
            }}
            onFocus={() => setShowCustomerDropdown(true)}
            placeholder="ابحث باسم العميل أو رقم الهاتف..."
            className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-card text-text-primary dark:text-white"
            required
          />
          
          {showCustomerDropdown && filteredCustomers.length > 0 && (
            <div className="absolute z-10 w-full mt-1 bg-white dark:bg-gray-800 border border-border rounded-lg shadow-lg max-h-60 overflow-auto">
              {filteredCustomers.map((customer) => (
                <button
                  key={customer.id}
                  type="button"
                  onClick={() => handleSelectCustomer(customer)}
                  className="w-full text-right px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 transition text-text-primary dark:text-white"
                >
                  <div className="font-medium">{customer.full_name}</div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">{customer.phone}</div>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* عرض أقساط العميل */}
        {selectedCustomer && installments.length > 0 && (
          <div className="mb-6">
            <label className="block text-text-primary dark:text-gray-300 mb-2">اختر القسط *</label>
            <div className="space-y-3">
              {installments.map((inst) => (
                <button
                  key={inst.id}
                  type="button"
                  onClick={() => setSelectedInstallment(inst.id)}
                  className={`w-full text-right p-4 border rounded-lg transition ${
                    selectedInstallment === inst.id
                      ? 'border-electric bg-electric/5 dark:bg-electric/10'
                      : 'border-border hover:border-electric'
                  }`}
                >
                  <div className="flex justify-between items-center">
                    <div>
                      <div className="font-medium text-text-primary dark:text-white">{inst.product_name}</div>
                      <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        المتبقي: {inst.remaining_amount?.toLocaleString() ?? '0'} {inst.currency === 'USD' ? 'USD' : 'IQD'}
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        التقدم: {inst.paid_count ?? 0}/{inst.total_count ?? 0} قسط
                      </div>
                    </div>
                    <div className="text-left">
                      <div className="text-sm text-warning">القسط القادم</div>
                      <div className="font-bold text-electric">{inst.next_due_amount?.toLocaleString() ?? '0'} {inst.currency === 'USD' ? 'USD' : 'IQD'}</div>
                      <div className="text-xs text-gray-500">{new Date(inst.next_due_date).toLocaleDateString('ar-IQ')}</div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {selectedCustomer && installments.length === 0 && (
          <div className="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/30 rounded-lg text-center">
            <p className="text-warning">لا توجد أقساط نشطة لهذا العميل</p>
            <Link href={`/installments/new?customer_id=${selectedCustomer}`} className="text-electric hover:underline mt-2 inline-block">
              إضافة قسط جديد
            </Link>
          </div>
        )}

        {/* تفاصيل الدفعة */}
        {selectedInstallment && selectedInstallmentData && (
          <>
            {/* خيارات التسديد */}
            <div className="mb-6">
              <label className="block text-text-primary dark:text-gray-300 mb-2">نوع التسديد</label>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    value="installment"
                    checked={paymentType === 'installment'}
                    onChange={(e) => setPaymentType(e.target.value as any)}
                    className="w-4 h-4 text-electric"
                  />
                  <span>تسديد القسط الحالي فقط</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    value="full"
                    checked={paymentType === 'full'}
                    onChange={(e) => setPaymentType(e.target.value as any)}
                    className="w-4 h-4 text-electric"
                  />
                  <span>تسديد كامل المبلغ المتبقي دفعة واحدة</span>
                </label>
              </div>
            </div>

            {/* خيارات التخفيض (للتسديد الكامل) */}
            {paymentType === 'full' && (
              <div className="mb-6 p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <label className="block text-text-primary dark:text-gray-300 mb-2">تخفيض</label>
                <div className="flex gap-4 mb-3">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      value="percentage"
                      checked={discountType === 'percentage'}
                      onChange={(e) => setDiscountType(e.target.value as any)}
                      className="w-4 h-4 text-electric"
                    />
                    <span>نسبة مئوية (%)</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      value="fixed"
                      checked={discountType === 'fixed'}
                      onChange={(e) => setDiscountType(e.target.value as any)}
                      className="w-4 h-4 text-electric"
                    />
                    <span>قيمة ثابتة (IQD)</span>
                  </label>
                </div>
                
                <input
                  type="number"
                  value={discountValue}
                  onChange={(e) => setDiscountValue(parseInt(e.target.value) || 0)}
                  placeholder={discountType === 'percentage' ? 'نسبة التخفيض (مثال: 10)' : 'قيمة التخفيض (مثال: 50000)'}
                  className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-card text-text-primary dark:text-white"
                />
                
                <div className="mt-3 p-3 bg-green-50 dark:bg-green-900/30 rounded-lg">
                  <p className="text-text-primary dark:text-gray-300 text-sm">
                    المبلغ الأصلي: <strong>{selectedInstallmentData?.remaining_amount?.toLocaleString()} {selectedInstallmentData?.currency === 'USD' ? 'USD' : 'IQD'}</strong>
                  </p>
                  {discountValue > 0 && (
                    <p className="text-text-primary dark:text-gray-300 text-sm mt-1">
                      التخفيض: <strong className="text-danger">
                        {discountType === 'percentage' 
                          ? `${discountValue}% (${Math.round(selectedInstallmentData.remaining_amount * discountValue / 100).toLocaleString()} IQD)` 
                          : `${discountValue.toLocaleString()} IQD`}
                      </strong>
                    </p>
                  )}
                  <p className="text-text-primary dark:text-gray-300 text-sm mt-1 font-bold">
                    المبلغ النهائي: <strong className="text-success text-lg">{finalAmount.toLocaleString()} {selectedInstallmentData?.currency === 'USD' ? 'USD' : 'IQD'}</strong>
                  </p>
                </div>
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-text-primary dark:text-gray-300 mb-2">المبلغ المدفوع *</label>
                <input
                  type="number"
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(parseInt(e.target.value) || 0)}
                  className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-card text-text-primary dark:text-white"
                  required
                  min="1"
                />
                <p className="text-xs text-gray-500 mt-1">المبلغ المستحق: {(selectedInstallmentData?.next_due_amount ?? 0).toLocaleString()} {selectedInstallmentData?.currency === 'USD' ? 'USD' : 'IQD'}</p>
              </div>

              <div>
                <label className="block text-text-primary dark:text-gray-300 mb-2">تاريخ الدفع *</label>
                <input
                  type="date"
                  value={paymentDate}
                  onChange={(e) => setPaymentDate(e.target.value)}
                  className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-card text-text-primary dark:text-white"
                  required
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-text-primary dark:text-gray-300 mb-2">ملاحظات</label>
                <textarea
                  rows={3}
                  value={paymentNotes}
                  onChange={(e) => setPaymentNotes(e.target.value)}
                  className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-card text-text-primary dark:text-white"
                  placeholder="ملاحظات إضافية (اختياري)"
                />
              </div>
            </div>

            <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
              <p className="text-text-primary dark:text-gray-300 text-sm">
                العميل: <strong>{selectedCustomerData?.full_name}</strong>
              </p>
              <p className="text-text-primary dark:text-gray-300 text-sm mt-1">
                المنتج: <strong>{selectedInstallmentData.product_name}</strong>
              </p>
              <p className="text-text-primary dark:text-gray-300 text-sm mt-1">
                المبلغ المتبقي بعد الدفع: <strong>
                  {((selectedInstallmentData?.remaining_amount ?? 0) - (paymentAmount ?? 0)).toLocaleString()} {selectedInstallmentData?.currency === 'USD' ? 'USD' : 'IQD'}
                </strong>
              </p>
            </div>
          </>
        )}

        <div className="flex gap-3 mt-6">
          <button
            type="submit"
            disabled={loading || !selectedInstallment}
            className="flex-1 bg-success hover:bg-green-600 text-white py-2 rounded-lg transition disabled:opacity-50"
          >
            {loading ? 'جاري التسديد...' : 'تأكيد التسديد'}
          </button>
          <Link
            href="/dashboard"
            className="flex-1 border border-border text-text-primary hover:bg-gray-50 dark:hover:bg-gray-700 py-2 rounded-lg transition text-center"
          >
            إلغاء
          </Link>
        </div>
      </form>
    </div>
  );
}
