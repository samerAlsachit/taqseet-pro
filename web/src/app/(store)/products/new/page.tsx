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
    <div className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8 bg-[#F0F2F5] dark:bg-[#0D1117]">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/products" className="text-blue-600 dark:text-blue-400 hover:underline">
          ← العودة إلى المخزن
        </Link>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إضافة منتج جديد</h1>
      </div>

      {error && (
        <div className="bg-red-50 text-red-600 border border-red-200 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* اسم المنتج */}
          <div className="md:col-span-2">
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">اسم المنتج *</label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          {/* اختيار العملة */}
          <div className="md:col-span-2">
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">عملة المنتج *</label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  value="IQD"
                  checked={currency === 'IQD'}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-4 h-4 text-blue-600"
                />
                <span className="text-[var(--text-primary)]">دينار عراقي (IQD)</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  value="USD"
                  checked={currency === 'USD'}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-4 h-4 text-blue-600"
                />
                <span className="text-[var(--text-primary)]">دولار أمريكي (USD)</span>
              </label>
            </div>
          </div>

          {/* الفئة */}
          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">الفئة</label>
            <input
              type="text"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          {/* الكمية */}
          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">الكمية المتوفرة *</label>
            <input
              type="number"
              required
              min="0"
              value={formData.quantity}
              onChange={(e) => setFormData({ ...formData, quantity: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          {/* حد التنبيه */}
          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">حد التنبيه للمخزون المنخفض</label>
            <input
              type="number"
              min="0"
              value={formData.low_stock_alert}
              onChange={(e) => setFormData({ ...formData, low_stock_alert: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          {/* الأسعار حسب العملة */}
          {currency === 'IQD' ? (
            <>
              <div>
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر الشراء (دينار)</label>
                <input
                  type="number"
                  min="0"
                  value={formData.cost_price}
                  onChange={(e) => setFormData({ ...formData, cost_price: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                />
              </div>
              <div>
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر البيع نقداً (دينار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_cash}
                  onChange={(e) => setFormData({ ...formData, sell_price_cash: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                />
              </div>
              <div>
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر البيع بالقسط (دينار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_install}
                  onChange={(e) => setFormData({ ...formData, sell_price_install: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر الشراء (دولار)</label>
                <input
                  type="number"
                  min="0"
                  value={formData.cost_price}
                  onChange={(e) => setFormData({ ...formData, cost_price: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                />
              </div>
              <div>
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر البيع نقداً (دولار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_cash}
                  onChange={(e) => setFormData({ ...formData, sell_price_cash: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                />
              </div>
              <div>
                <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">سعر البيع بالقسط (دولار) *</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.sell_price_install}
                  onChange={(e) => setFormData({ ...formData, sell_price_install: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
                />
              </div>
            </>
          )}

          {/* وصف المنتج */}
          <div className="md:col-span-2">
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">وصف المنتج</label>
            <textarea
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button
            type="submit"
            disabled={loading}
              className="bg-[#3A86FF] hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
          >
            {loading ? 'جاري الحفظ...' : 'حفظ المنتج'}
          </button>
          <Link
            href="/products"
            className="border border-gray-300 dark:border-[#30363D] text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#1C2128] px-6 py-2 rounded-lg transition"
          >
            إلغاء
          </Link>
        </div>
      </form>
    </div>
  );
}
