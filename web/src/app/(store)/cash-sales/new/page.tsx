'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { DollarSign, Package, User } from 'lucide-react';
import toast from 'react-hot-toast';

export default function NewCashSalePage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [products, setProducts] = useState<any[]>([]);
  const [customers, setCustomers] = useState<any[]>([]);
  const [formData, setFormData] = useState({
    customer_id: '',
    product_id: '',
    quantity: 1,
    price: 0,
    currency: 'IQD',
    notes: ''
  });

  useEffect(() => {
    const fetchData = async () => {
      const token = localStorage.getItem('token');
      try {
        const [productsRes, customersRes] = await Promise.all([
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/products?limit=100`, {
            headers: { Authorization: `Bearer ${token}` }
          }),
          fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers?limit=100`, {
            headers: { Authorization: `Bearer ${token}` }
          })
        ]);
        const productsData = await productsRes.json();
        const customersData = await customersRes.json();
        if (productsData.success) setProducts(productsData.data.products);
        if (customersData.success) setCustomers(customersData.data.customers);
      } catch (error) {
        console.error('خطأ في جلب البيانات', error);
      }
    };
    fetchData();
  }, []);

  useEffect(() => {
    if (formData.product_id) {
      const product = products.find(p => p.id === formData.product_id);
      if (product) {
        const price = product.currency === 'IQD' 
          ? product.sell_price_cash_iqd 
          : product.sell_price_cash_usd;
        setFormData(prev => ({ ...prev, price, currency: product.currency }));
      }
    }
  }, [formData.product_id, products]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/cash-sales`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم تسجيل البيع النقدي بنجاح');
        router.push('/cash-sales');
      } else {
        toast.error(data.error || 'فشل في التسجيل');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  const selectedProduct = products.find(p => p.id === formData.product_id);
  const totalPrice = formData.price * formData.quantity;

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/dashboard" className="text-electric hover:underline">
          ← العودة
        </Link>
        <h1 className="text-2xl font-bold text-navy dark:text-white">بيع نقدي</h1>
      </div>

      <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
        <div className="space-y-4">
          <div>
            <label className="block text-text-primary mb-2">المنتج *</label>
            <select
              required
              value={formData.product_id}
              onChange={(e) => setFormData({...formData, product_id: e.target.value})}
              className="w-full px-4 py-2 border border-border rounded-lg bg-card text-text-primary"
            >
              <option value="">اختر منتجاً</option>
              {products.map(p => (
                <option key={p.id} value={p.id}>
                  {p.name} - {(p.currency === 'IQD' ? p.sell_price_cash_iqd : p.sell_price_cash_usd).toLocaleString()} {p.currency}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-text-primary mb-2">الكمية *</label>
              <input
                type="number"
                min="1"
                required
                value={formData.quantity}
                onChange={(e) => setFormData({...formData, quantity: parseInt(e.target.value) || 1})}
                className="w-full px-4 py-2 border border-border rounded-lg bg-card text-text-primary"
              />
            </div>
            <div>
              <label className="block text-text-primary mb-2">سعر الوحدة *</label>
              <input
                type="number"
                min="0"
                required
                value={formData.price}
                readOnly
                className="w-full px-4 py-2 border border-border rounded-lg bg-gray-100 dark:bg-gray-700 text-text-primary cursor-not-allowed"
              />
              <p className="text-xs text-gray-500 mt-1">السعر محدد مسبقاً من المنتج</p>
            </div>
          </div>

          <div>
            <label className="block text-text-primary mb-2">العميل (اختياري)</label>
            <select
              value={formData.customer_id}
              onChange={(e) => setFormData({...formData, customer_id: e.target.value})}
              className="w-full px-4 py-2 border border-border rounded-lg bg-card text-text-primary"
            >
              <option value="">بدون عميل</option>
              {customers.map(c => (
                <option key={c.id} value={c.id}>{c.full_name} - {c.phone}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-text-primary mb-2">ملاحظات</label>
            <textarea
              rows={3}
              value={formData.notes}
              onChange={(e) => setFormData({...formData, notes: e.target.value})}
              className="w-full px-4 py-2 border border-border rounded-lg bg-card text-text-primary"
            />
          </div>

          {selectedProduct && (
            <div className="p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
              <p className="font-bold text-navy dark:text-white">ملخص البيع</p>
              <div className="mt-2 space-y-1 text-sm">
                <p>المنتج: {selectedProduct.name}</p>
                <p>الكمية: {formData.quantity}</p>
                <p>سعر الوحدة: {formData.price.toLocaleString()} {formData.currency}</p>
                <p className="font-bold text-electric">الإجمالي: {totalPrice.toLocaleString()} {formData.currency}</p>
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-success hover:bg-green-600 text-white py-2 rounded-lg transition disabled:opacity-50"
          >
            {loading ? 'جاري التسجيل...' : 'تسجيل وتسجيل'}
          </button>
        </div>
      </form>
    </div>
  );
}
