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
  sell_price_install_usd: number;
  currency: string;
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
  
  // State للمنتجات المضافة
  const [cart, setCart] = useState<any[]>([]);
  const [totalPrice, setTotalPrice] = useState(0);
  
  // بيانات القسط
  const [formData, setFormData] = useState({
    down_payment: 0,
    installment_amount: 0,
    frequency: 'monthly',
    start_date: new Date().toISOString().split('T')[0],
    currency: 'IQD',
    total_price: 0
  });
  
  const [exchangeRate, setExchangeRate] = useState(1300);
  
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

  // دالة حساب المجموع الكلي
  const calculateTotal = (items: any[]) => {
    const total = items.reduce((sum, item) => {
      const price = item.currency === 'IQD' 
        ? (item.sell_price_install_iqd || 0) 
        : (item.sell_price_install_usd || 0);
      return sum + (price * (item.quantity || 1));
    }, 0);
    setTotalPrice(total);
    setFormData({ ...formData, total_price: total });
    return total;
  };

  // إضافة منتج للسلة
  const addToCart = (product: any) => {
    setCart(prevCart => {
      const existing = prevCart.find(item => item.id === product.id);
      let newCart;
      if (existing) {
        newCart = prevCart.map(item => 
          item.id === product.id 
            ? { ...item, quantity: (item.quantity || 1) + 1 }
            : item
        );
      } else {
        newCart = [...prevCart, { 
          ...product, 
          quantity: 1,
          price: product.currency === 'IQD' 
            ? product.sell_price_install_iqd 
            : product.sell_price_install_usd
        }];
      }
      calculateTotal(newCart);
      return newCart;
    });
  };

  // إزالة منتج من السلة
  const removeFromCart = (productId: string) => {
    setCart(prevCart => {
      const newCart = prevCart.filter(item => item.id !== productId);
      calculateTotal(newCart);
      return newCart;
    });
  };

  // تحديث الكمية
  const updateQuantity = (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    setCart(prevCart => {
      const newCart = prevCart.map(item =>
        item.id === productId ? { ...item, quantity } : item
      );
      calculateTotal(newCart);
      return newCart;
    });
  };

  // عند تحميل الصفحة أو تغيير السلة، احسب المجموع
  useEffect(() => {
    calculateTotal(cart);
  }, [cart]);

  const handleProductSelect = (product: any) => {
    setSelectedProduct(product);
    const totalPrice = product.currency === 'IQD' 
      ? product.sell_price_install_iqd 
      : product.sell_price_install_usd;
    
    setFormData({
      ...formData,
      currency: product.currency,
      total_price: totalPrice
    });
  };

  // حساب جدول الأقساط
  const calculateSchedule = async () => {
    if (cart.length === 0) return;
    
    setLoading(true);
    setError('');
    
    const totalPrice = formData.total_price;
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
    if (!selectedCustomer || cart.length === 0) return;
    
    setLoading(true);
    setError('');
    
    // تحضير مصفوفة المنتجات للإرسال
    const productsData = cart.map(item => ({
      product_id: item.id,
      quantity: item.quantity,
      price: item.currency === 'IQD' ? item.sell_price_install_iqd : item.sell_price_install_usd,
      name: item.name,
      currency: item.currency
    }));
    
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/installments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('token')}` 
        },
        body: JSON.stringify({
          customer_id: selectedCustomer.id,
          products: productsData,
          total_price: totalPrice,
          down_payment: formData.down_payment,
          installment_amount: formData.installment_amount,
          frequency: formData.frequency,
          start_date: formData.start_date,
          currency: cart[0]?.currency || 'IQD',
          notes: cart.length === 1 
            ? `قسط ${cart[0].name}` 
            : `قسط ${cart.length} منتج`
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
    <div className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8 bg-[#F0F2F5] dark:bg-[#0D1117]">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/installments" className="text-blue-600 dark:text-blue-400 hover:underline">
          ← العودة إلى الأقساط
        </Link>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إنشاء قسط جديد</h1>
      </div>

      {/* Steps Indicator */}
      <div className="flex mb-8 border-b border-[var(--border-color)]">
        <button
          onClick={() => setStep('customer')}
          className={`pb-2 px-4 ${step === 'customer' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-700 dark:text-gray-300'}`}
        >
          1. اختيار العميل
        </button>
        <button
          onClick={() => selectedCustomer && setStep('product')}
          disabled={!selectedCustomer}
          className={`pb-2 px-4 ${step === 'product' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-700 dark:text-gray-300'} ${!selectedCustomer && 'opacity-50'}`}
        >
          2. اختيار المنتج
        </button>
        <button
          onClick={() => selectedProduct && setStep('details')}
          disabled={!selectedProduct}
          className={`pb-2 px-4 ${step === 'details' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-700 dark:text-gray-300'} ${!selectedProduct && 'opacity-50'}`}
        >
          3. تفاصيل القسط
        </button>
        <button
          disabled={!calculated}
          className={`pb-2 px-4 ${step === 'preview' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-700 dark:text-gray-300'} ${!calculated && 'opacity-50'}`}
        >
          4. تأكيد
        </button>
      </div>

      {error && (
        <div className="bg-red-50 text-red-600 border border-red-200 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      {/* Step 1: Customer Selection */}
      {step === 'customer' && (
        <div className="bg-white dark:bg-[#1C2128] rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">اختر العميل</h2>
          <div className="grid gap-3">
            {customers.map((customer) => (
              <button
                key={customer.id}
                onClick={() => {
                  setSelectedCustomer(customer);
                  setStep('product');
                }}
                className={`p-4 text-right border rounded-lg hover:bg-gray-50 dark:hover:bg-[#1C2128] transition ${
                  selectedCustomer?.id === customer.id ? 'border-blue-600 bg-blue-600/5' : 'border-gray-300 dark:border-[#30363D]'
                }`}
              >
                <div className="font-medium">{customer.full_name}</div>
                <div className="text-sm text-gray-500 dark:text-gray-400">{customer.phone}</div>
              </button>
            ))}
            {customers.length === 0 && (
              <p className="text-gray-500 dark:text-gray-400 text-center py-8">
                لا يوجد عملاء. 
                <Link href="/customers/new" className="text-blue-600 dark:text-blue-400 mr-1">
                  أضف عميلاً أولاً
                </Link>
              </p>
            )}
          </div>
        </div>
      )}

      {/* Step 2: Product Selection */}
      {step === 'product' && (
        <div className="bg-white dark:bg-[#1C2128] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">اختر المنتجات</h2>
          
          {/* قائمة المنتجات المتاحة */}
          <div className="grid gap-3 mb-6">
            {products.map((product) => (
              <div key={product.id} className="flex justify-between items-center p-4 border border-gray-200 dark:border-[#30363D] rounded-lg">
                <div>
                  <div className="font-medium text-gray-900 dark:text-white">{product.name}</div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">
                    {product.currency === 'IQD' 
                      ? `${product.sell_price_install_iqd.toLocaleString()} IQD` 
                      : `${product.sell_price_install_usd.toLocaleString()} USD`}
                  </div>
                  <div className="text-xs text-gray-400 dark:text-gray-500">المتوفر: {product.quantity}</div>
                </div>
                <button
                  onClick={() => addToCart(product)}
                  className="bg-[#3A86FF] text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition-colors"
                >
                  + إضافة
                </button>
              </div>
            ))}
            {products.length === 0 && (
              <p className="text-gray-500 dark:text-gray-400 text-center py-8">
                لا توجد منتجات متوفرة. 
                <Link href="/products/new" className="text-blue-600 dark:text-blue-400 mr-1">
                  أضف منتجاً أولاً
                </Link>
              </p>
            )}
          </div>
          
          {/* سلة المنتجات */}
          {cart.length > 0 && (
            <div className="border-t border-gray-200 dark:border-[#30363D] pt-4">
              <h3 className="font-bold text-gray-900 dark:text-white mb-3">المنتجات المختارة</h3>
              <div className="space-y-2">
                {cart.map((item) => (
                  <div key={item.id} className="flex justify-between items-center p-3 bg-gray-50 dark:bg-[#1C2128] rounded-lg">
                    <div>
                      <div className="font-medium text-gray-900 dark:text-white">{item.name}</div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        {item.currency === 'IQD' 
                          ? `${item.sell_price_install_iqd.toLocaleString()} IQD` 
                          : `${item.sell_price_install_usd.toLocaleString()} USD`}
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                        className="w-8 h-8 rounded-full bg-gray-200 dark:bg-gray-600 text-gray-900 dark:text-white hover:bg-gray-300 dark:hover:bg-gray-500 transition-colors"
                      >
                        -
                      </button>
                      <span className="w-8 text-center text-gray-900 dark:text-white font-medium">{item.quantity}</span>
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                        className="w-8 h-8 rounded-full bg-gray-200 dark:bg-gray-600 text-gray-900 dark:text-white hover:bg-gray-300 dark:hover:bg-gray-500 transition-colors"
                      >
                        +
                      </button>
                      <button
                        onClick={() => removeFromCart(item.id)}
                        className="text-red-600 dark:text-red-400 hover:underline"
                      >
                        حذف
                      </button>
                    </div>
                  </div>
                ))}
              </div>
              
              <div className="mt-4 p-3 bg-gray-100 dark:bg-[#1C2128] rounded-lg">
                <div className="flex justify-between font-bold">
                  <span className="text-gray-900 dark:text-white">المجموع الكلي:</span>
                  <span className="text-blue-600 dark:text-blue-400">
                    {totalPrice.toLocaleString()} {cart[0]?.currency === 'USD' ? 'USD' : 'IQD'}
                  </span>
                </div>
              </div>
              
              <button
                onClick={() => setStep('details')}
                className="btn-success"
              >
                متابعة ({cart.length} منتج)
              </button>
            </div>
          )}
        </div>
      )}

      {/* Step 3: Installment Details */}
      {step === 'details' && cart.length > 0 && (
        <div className="bg-white dark:bg-[#1C2128] rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">تفاصيل القسط</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">المبلغ الكلي</label>
              <input
                type="text"
                value={`${formData.total_price.toLocaleString()} ${formData.currency}`}
                disabled
                className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
              />
            </div>
            <div>
              <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">الدفعة المقدمة (اختياري)</label>
              <input
                type="number"
                value={formData.down_payment}
                onChange={(e) => setFormData({ ...formData, down_payment: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
              />
            </div>
            <div>
              <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">مبلغ القسط الشهري *</label>
              <input
                type="number"
                required
                value={formData.installment_amount}
                onChange={(e) => setFormData({ ...formData, installment_amount: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
              />
            </div>
            <div>
              <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">نظام الدفع</label>
              <select
                value={formData.frequency}
                onChange={(e) => setFormData({ ...formData, frequency: e.target.value })}
                className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
              >
                <option value="monthly">شهري</option>
                <option value="weekly">أسبوعي</option>
                <option value="daily">يومي</option>
              </select>
            </div>
            <div>
              <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">تاريخ بداية الأقساط</label>
              <input
                type="date"
                value={formData.start_date}
                onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
                className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
              />
            </div>
            
            <div>
              <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">العملة</label>
              <select
                value={formData.currency}
                onChange={(e) => setFormData({...formData, currency: e.target.value})}
                className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
              >
                <option value="IQD">دينار عراقي (IQD)</option>
                <option value="USD">دولار أمريكي (USD)</option>
              </select>
            </div>
            
            {formData.currency === 'USD' && (
              <div className="md:col-span-2">
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر الصرف (دولار → دينار)</label>
                <input
                  type="number"
                  value={exchangeRate}
                  onChange={(e) => setExchangeRate(parseInt(e.target.value) || 1300)}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                  placeholder="مثال: 1300"
                />
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">سعر صرف الدولار مقابل الدينار وقت إنشاء القسط</p>
              </div>
            )}
          </div>
          
          <div className="mt-6 p-4 bg-gray-100 dark:bg-[#1C2128] rounded-lg">
            <p className="text-gray-500 dark:text-gray-400">
              المبلغ المتبقي بعد الدفعة المقدمة: <strong>{(formData.total_price - formData.down_payment).toLocaleString()} {formData.currency}</strong>
            </p>
          </div>

          <div className="flex gap-3 mt-6">
            <button
              onClick={calculateSchedule}
              disabled={loading || !formData.installment_amount}
              className="btn-success"
            >
              {loading ? 'جاري الحساب...' : 'حساب الأقساط'}
            </button>
            <button
              onClick={() => setStep('product')}
              className="btn-outline"
            >
              رجوع
            </button>
          </div>
        </div>
      )}

      {/* Step 4: Preview & Confirm */}
      {step === 'preview' && schedule.length > 0 && (
        <div className="bg-white dark:bg-[#1C2128] rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">تأكيد معلومات القسط</h2>
          
          <div className="bg-gray-100 dark:bg-[#1C2128] rounded-lg p-4 mb-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-gray-500 dark:text-gray-400 text-sm">العميل</p>
                <p className="font-medium">{selectedCustomer?.full_name}</p>
              </div>
              <div>
                <p className="text-gray-500 dark:text-gray-400 text-sm">المنتج</p>
                <p className="font-medium">{selectedProduct?.name}</p>
              </div>
              <div>
                <p className="text-gray-500 dark:text-gray-400 text-sm">المبلغ الكلي</p>
                <p className="font-medium">{selectedProduct?.sell_price_install_iqd.toLocaleString()} IQD</p>
              </div>
              <div>
                <p className="text-gray-500 dark:text-gray-400 text-sm">الدفعة المقدمة</p>
                <p className="font-medium">{formData.down_payment.toLocaleString()} IQD</p>
              </div>
              <div>
                <p className="text-gray-500 dark:text-gray-400 text-sm">عدد الأقساط</p>
                <p className="font-medium">{schedule.length} قسط</p>
              </div>
              <div>
                <p className="text-gray-500 dark:text-gray-400 text-sm">قيمة القسط</p>
                <p className="font-medium">{formData.installment_amount.toLocaleString()} IQD</p>
              </div>
            </div>
          </div>

          <h3 className="font-bold text-gray-900 dark:text-white mb-3">جدول الأقساط</h3>
          <div className="overflow-x-auto mb-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-[#30363D] bg-gray-100 dark:bg-[#1C2128]">
                  <th className="text-right py-2 px-3 text-gray-500 dark:text-gray-400 font-semibold">#</th>
                  <th className="text-right py-2 px-3 text-gray-500 dark:text-gray-400 font-semibold">تاريخ الاستحقاق</th>
                  <th className="text-right py-2 px-3 text-gray-500 dark:text-gray-400 font-semibold">المبلغ</th>
                </tr>
              </thead>
              <tbody>
                {schedule.map((item) => (
                  <tr key={item.installment_no} className="border-b border-gray-200 dark:border-[#30363D] hover:bg-gray-50 dark:hover:bg-[#1C2128]">
                    <td className="py-2 px-3 text-gray-900 dark:text-white">{item.installment_no}</td>
                    <td className="py-2 px-3 text-gray-900 dark:text-white">{new Date(item.due_date).toLocaleDateString('ar-IQ')}</td>
                    <td className="py-2 px-3 text-gray-900 dark:text-white">{item.amount.toLocaleString()} IQD</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex gap-3">
            <button
              onClick={createInstallment}
              disabled={loading}
              className="btn-success"
            >
              {loading ? 'جاري الإنشاء...' : 'تأكيد وإنشاء القسط'}
            </button>
            <button
              onClick={() => setStep('details')}
              className="btn-outline"
            >
              رجوع
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
