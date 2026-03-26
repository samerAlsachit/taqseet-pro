'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Customer {
  id: string;
  full_name: string;
  phone: string;
}

interface Product {
  id: string;
  name: string;
  sell_price_install_iqd: number;
  quantity: number;
}

interface ScheduleItem {
  installment_no: number;
  due_date: string;
  amount: number;
}

export default function NewInstallmentPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const preSelectedCustomerId = searchParams.get('customer_id');

  const [step, setStep] = useState<'customer' | 'product' | 'details' | 'preview'>('customer');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  // بيانات الخطوات
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  
  // بيانات القسط
  const [formData, setFormData] = useState({
    down_payment: 0,
    installment_amount: 0,
    frequency: 'monthly',
    start_date: new Date().toISOString().split('T')[0],
    currency: 'IQD'
  });
  
  const [schedule, setSchedule] = useState<ScheduleItem[]>([]);
  const [calculated, setCalculated] = useState(false);

  // جلب العملاء
  useEffect(() => {
    const fetchCustomers = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        router.push('/login');
        return;
      }
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers?limit=100`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          setCustomers(data.data.customers);
          if (preSelectedCustomerId) {
            const customer = data.data.customers.find((c: Customer) => c.id === preSelectedCustomerId);
            if (customer) setSelectedCustomer(customer);
          }
        }
      } catch (err) {
        console.error('خطأ في جلب العملاء', err);
      }
    };
    fetchCustomers();
  }, [router, preSelectedCustomerId]);

  // جلب المنتجات
  useEffect(() => {
    const fetchProducts = async () => {
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products?limit=100`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          setProducts(data.data.products.filter((p: Product) => p.quantity > 0));
        }
      } catch (err) {
        console.error('خطأ في جلب المنتجات', err);
      }
    };
    fetchProducts();
  }, []);

  // حساب جدول الأقساط
  const calculateSchedule = async () => {
    if (!selectedProduct) return;
    
    setLoading(true);
    setError('');
    
    const totalPrice = selectedProduct.sell_price_install_iqd;
    const financedAmount = totalPrice - formData.down_payment;
    
    if (formData.installment_amount <= 0) {
      setError('مبلغ القسط مطلوب');
      setLoading(false);
      return;
    }
    
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/installments/calculate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('token')}` 
        },
        body: JSON.stringify({
          total_price: totalPrice,
          down_payment: formData.down_payment,
          installment_amount: formData.installment_amount,
          frequency: formData.frequency,
          start_date: formData.start_date,
          currency: formData.currency
        })
      });
      
      const data = await res.json();
      if (data.success) {
        setSchedule(data.data.schedule);
        setCalculated(true);
        setStep('preview');
      } else {
        setError(data.error || 'فشل في حساب الأقساط');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  // إنشاء القسط
  const createInstallment = async () => {
    if (!selectedCustomer || !selectedProduct) return;
    
    setLoading(true);
    setError('');
    
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/installments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('token')}` 
        },
        body: JSON.stringify({
          customer_id: selectedCustomer.id,
          product_id: selectedProduct.id,
          total_price: selectedProduct.sell_price_install_iqd,
          down_payment: formData.down_payment,
          installment_amount: formData.installment_amount,
          frequency: formData.frequency,
          start_date: formData.start_date,
          currency: formData.currency,
          notes: `قسط ${selectedProduct.name}` 
        })
      });
      
      const data = await res.json();
      if (data.success) {
        router.push(`/installments/${data.data.id}`);
      } else {
        setError(data.error || 'فشل في إنشاء القسط');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/installments" className="text-electric hover:underline">
          ← العودة إلى الأقساط
        </Link>
        <h1 className="text-2xl font-bold text-navy">إضافة قسط جديد</h1>
      </div>

      {/* Steps Indicator */}
      <div className="flex mb-8 border-b border-gray-200">
        <button
          onClick={() => setStep('customer')}
          className={`pb-2 px-4 ${step === 'customer' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'}`}
        >
          1. اختيار العميل
        </button>
        <button
          onClick={() => selectedCustomer && setStep('product')}
          disabled={!selectedCustomer}
          className={`pb-2 px-4 ${step === 'product' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'} ${!selectedCustomer && 'opacity-50'}`}
        >
          2. اختيار المنتج
        </button>
        <button
          onClick={() => selectedProduct && setStep('details')}
          disabled={!selectedProduct}
          className={`pb-2 px-4 ${step === 'details' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'} ${!selectedProduct && 'opacity-50'}`}
        >
          3. تفاصيل القسط
        </button>
        <button
          disabled={!calculated}
          className={`pb-2 px-4 ${step === 'preview' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'} ${!calculated && 'opacity-50'}`}
        >
          4. تأكيد
        </button>
      </div>

      {error && (
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      {/* Step 1: Customer Selection */}
      {step === 'customer' && (
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-navy mb-4">اختر العميل</h2>
          <div className="grid gap-3">
            {customers.map((customer) => (
              <button
                key={customer.id}
                onClick={() => {
                  setSelectedCustomer(customer);
                  setStep('product');
                }}
                className={`p-4 text-right border rounded-lg hover:bg-gray-50 transition ${
                  selectedCustomer?.id === customer.id ? 'border-electric bg-electric/5' : 'border-gray-200'
                }`}
              >
                <div className="font-medium">{customer.full_name}</div>
                <div className="text-sm text-text-primary/70">{customer.phone}</div>
              </button>
            ))}
            {customers.length === 0 && (
              <p className="text-text-primary text-center py-8">
                لا يوجد عملاء. 
                <Link href="/customers/new" className="text-electric mr-1">
                  أضف عميلاً أولاً
                </Link>
              </p>
            )}
          </div>
        </div>
      )}

      {/* Step 2: Product Selection */}
      {step === 'product' && (
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-navy mb-4">اختر المنتج</h2>
          <div className="grid gap-3">
            {products.map((product) => (
              <button
                key={product.id}
                onClick={() => {
                  setSelectedProduct(product);
                  setStep('details');
                }}
                className={`p-4 text-right border rounded-lg hover:bg-gray-50 transition ${
                  selectedProduct?.id === product.id ? 'border-electric bg-electric/5' : 'border-gray-200'
                }`}
              >
                <div className="font-medium">{product.name}</div>
                <div className="text-sm text-text-primary/70">
                  السعر: {product.sell_price_install_iqd.toLocaleString()} IQD | المتوفر: {product.quantity}
                </div>
              </button>
            ))}
            {products.length === 0 && (
              <p className="text-text-primary text-center py-8">
                لا توجد منتجات متوفرة. 
                <Link href="/products/new" className="text-electric mr-1">
                  أضف منتجاً أولاً
                </Link>
              </p>
            )}
          </div>
        </div>
      )}

      {/* Step 3: Installment Details */}
      {step === 'details' && selectedProduct && (
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-navy mb-4">تفاصيل القسط</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-text-primary mb-2">المبلغ الكلي</label>
              <input
                type="text"
                value={`${selectedProduct.sell_price_install_iqd.toLocaleString()} IQD`}
                disabled
                className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-50"
              />
            </div>
            <div>
              <label className="block text-text-primary mb-2">الدفعة المقدمة (اختياري)</label>
              <input
                type="number"
                value={formData.down_payment}
                onChange={(e) => setFormData({ ...formData, down_payment: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              />
            </div>
            <div>
              <label className="block text-text-primary mb-2">مبلغ القسط الشهري *</label>
              <input
                type="number"
                required
                value={formData.installment_amount}
                onChange={(e) => setFormData({ ...formData, installment_amount: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              />
            </div>
            <div>
              <label className="block text-text-primary mb-2">نظام الدفع</label>
              <select
                value={formData.frequency}
                onChange={(e) => setFormData({ ...formData, frequency: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              >
                <option value="monthly">شهري</option>
                <option value="weekly">أسبوعي</option>
                <option value="daily">يومي</option>
              </select>
            </div>
            <div>
              <label className="block text-text-primary mb-2">تاريخ بداية الأقساط</label>
              <input
                type="date"
                value={formData.start_date}
                onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              />
            </div>
          </div>
          
          <div className="mt-6 p-4 bg-gray-bg rounded-lg">
            <p className="text-text-primary">
              المبلغ المتبقي بعد الدفعة المقدمة: <strong>{(selectedProduct.sell_price_install_iqd - formData.down_payment).toLocaleString()} IQD</strong>
            </p>
          </div>

          <div className="flex gap-3 mt-6">
            <button
              onClick={calculateSchedule}
              disabled={loading || !formData.installment_amount}
              className="bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
            >
              {loading ? 'جاري الحساب...' : 'حساب الأقساط'}
            </button>
            <button
              onClick={() => setStep('product')}
              className="border border-gray-300 text-text-primary hover:bg-gray-50 px-6 py-2 rounded-lg transition"
            >
              رجوع
            </button>
          </div>
        </div>
      )}

      {/* Step 4: Preview & Confirm */}
      {step === 'preview' && schedule.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-navy mb-4">تأكيد معلومات القسط</h2>
          
          <div className="bg-gray-bg rounded-lg p-4 mb-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-text-primary text-sm">العميل</p>
                <p className="font-medium">{selectedCustomer?.full_name}</p>
              </div>
              <div>
                <p className="text-text-primary text-sm">المنتج</p>
                <p className="font-medium">{selectedProduct?.name}</p>
              </div>
              <div>
                <p className="text-text-primary text-sm">المبلغ الكلي</p>
                <p className="font-medium">{selectedProduct?.sell_price_install_iqd.toLocaleString()} IQD</p>
              </div>
              <div>
                <p className="text-text-primary text-sm">الدفعة المقدمة</p>
                <p className="font-medium">{formData.down_payment.toLocaleString()} IQD</p>
              </div>
              <div>
                <p className="text-text-primary text-sm">عدد الأقساط</p>
                <p className="font-medium">{schedule.length} قسط</p>
              </div>
              <div>
                <p className="text-text-primary text-sm">قيمة القسط</p>
                <p className="font-medium">{formData.installment_amount.toLocaleString()} IQD</p>
              </div>
            </div>
          </div>

          <h3 className="font-bold text-navy mb-3">جدول الأقساط</h3>
          <div className="overflow-x-auto mb-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-right py-2 px-3">#</th>
                  <th className="text-right py-2 px-3">تاريخ الاستحقاق</th>
                  <th className="text-right py-2 px-3">المبلغ</th>
                 </tr>
              </thead>
              <tbody>
                {schedule.map((item) => (
                  <tr key={item.installment_no} className="border-b border-gray-100">
                    <td className="py-2 px-3">{item.installment_no}</td>
                    <td className="py-2 px-3">{new Date(item.due_date).toLocaleDateString('ar-IQ')}</td>
                    <td className="py-2 px-3">{item.amount.toLocaleString()} IQD</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex gap-3">
            <button
              onClick={createInstallment}
              disabled={loading}
              className="bg-success hover:bg-green-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
            >
              {loading ? 'جاري الإنشاء...' : 'تأكيد وإنشاء القسط'}
            </button>
            <button
              onClick={() => setStep('details')}
              className="border border-gray-300 text-text-primary hover:bg-gray-50 px-6 py-2 rounded-lg transition"
            >
              رجوع
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
