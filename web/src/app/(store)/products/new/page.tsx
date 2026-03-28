'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function NewProductPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [currency, setCurrency] = useState('IQD');
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    quantity: 0,
    low_stock_alert: 5,
    cost_price: 0,
    sell_price_cash: 0,
    sell_price_install: 0,
    description: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    if (formData.sell_price_install < formData.sell_price_cash) {
      setError('سعر البيع بالقسط يجب أن يكون أكبر من أو يساوي سعر البيع النقدي');
      setLoading(false);
      return;
    }

    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({
          ...formData,
          currency,
          cost_price_iqd: currency === 'IQD' ? formData.cost_price : 0,
          cost_price_usd: currency === 'USD' ? formData.cost_price : 0,
          sell_price_cash_iqd: currency === 'IQD' ? formData.sell_price_cash : 0,
          sell_price_cash_usd: currency === 'USD' ? formData.sell_price_cash : 0,
          sell_price_install_iqd: currency === 'IQD' ? formData.sell_price_install : 0,
          sell_price_install_usd: currency === 'USD' ? formData.sell_price_install : 0
        })
      });

      const data = await response.json();

      if (data.success) {
        router.push('/products');
      } else {
        setError(data.error || 'فشل في إضافة المنتج');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  const formatNumber = (value: number) => {
    return value.toLocaleString();
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/products" className="text-electric hover:underline">
          ← العودة إلى المخزن
        </Link>
        <h1 className="text-2xl font-bold text-navy">إضافة منتج جديد</h1>
      </div>

      {error && (
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* اسم المنتج */}
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">اسم المنتج *</label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          {/* اختيار العملة */}
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">عملة المنتج *</label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  value="IQD"
                  checked={currency === 'IQD'}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-4 h-4 text-electric"
                />
                <span>دينار عراقي (IQD)</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  value="USD"
                  checked={currency === 'USD'}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-4 h-4 text-electric"
                />
                <span>دولار أمريكي (USD)</span>
              </label>
            </div>
          </div>

          {/* الفئة */}
          <div>
            <label className="block text-text-primary mb-2">الفئة</label>
            <input
              type="text"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          {/* الكمية */}
          <div>
            <label className="block text-text-primary mb-2">الكمية المتوفرة *</label>
            <input
              type="number"
              required
              min="0"
              value={formData.quantity}
              onChange={(e) => setFormData({ ...formData, quantity: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          {/* حد التنبيه */}
          <div>
            <label className="block text-text-primary mb-2">حد التنبيه للمخزون المنخفض</label>
            <input
              type="number"
              min="0"
              value={formData.low_stock_alert}
              onChange={(e) => setFormData({ ...formData, low_stock_alert: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          {/* الأسعار حسب العملة */}
          {currency === 'IQD' ? (
            <>
              <div>
                <label className="block text-text-primary mb-2">سعر الشراء (دينار)</label>
                <input
                  type="number"
                  min="0"
                  value={formData.cost_price}
                  onChange={(e) => setFormData({ ...formData, cost_price: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">سعر البيع نقداً (دينار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_cash}
                  onChange={(e) => setFormData({ ...formData, sell_price_cash: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">سعر البيع بالقسط (دينار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_install}
                  onChange={(e) => setFormData({ ...formData, sell_price_install: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-text-primary mb-2">سعر الشراء (دولار)</label>
                <input
                  type="number"
                  min="0"
                  value={formData.cost_price}
                  onChange={(e) => setFormData({ ...formData, cost_price: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">سعر البيع نقداً (دولار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_cash}
                  onChange={(e) => setFormData({ ...formData, sell_price_cash: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">سعر البيع بالقسط (دولار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_install}
                  onChange={(e) => setFormData({ ...formData, sell_price_install: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
                />
              </div>
            </>
          )}

          {/* وصف المنتج */}
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">وصف المنتج</label>
            <textarea
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg"
            />
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button
            type="submit"
            disabled={loading}
            className="bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
          >
            {loading ? 'جاري الحفظ...' : 'حفظ المنتج'}
          </button>
          <Link
            href="/products"
            className="border border-[var(--border-color)] text-text-primary hover:bg-[var(--bg-primary)] px-6 py-2 rounded-lg transition"
          >
            إلغاء
          </Link>
        </div>
      </form>
    </div>
  );
}
