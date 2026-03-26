'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function NewProductPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    quantity: 0,
    low_stock_alert: 5,
    cost_price_iqd: 0,
    sell_price_cash_iqd: 0,
    sell_price_install_iqd: 0,
    description: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // التحقق من صحة البيانات
    if (formData.sell_price_install_iqd < formData.sell_price_cash_iqd) {
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
        body: JSON.stringify(formData)
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

      <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* اسم المنتج */}
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">
              اسم المنتج <span className="text-danger">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="مثال: تلفزيون سامسونج 55 بوصة"
            />
          </div>

          {/* الفئة */}
          <div>
            <label className="block text-text-primary mb-2">الفئة</label>
            <input
              type="text"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="مثال: إلكترونيات"
            />
          </div>

          {/* الكمية */}
          <div>
            <label className="block text-text-primary mb-2">
              الكمية المتوفرة <span className="text-danger">*</span>
            </label>
            <input
              type="number"
              required
              min="0"
              value={formData.quantity}
              onChange={(e) => setFormData({ ...formData, quantity: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          {/* حد التنبيه للمخزون */}
          <div>
            <label className="block text-text-primary mb-2">حد التنبيه للمخزون المنخفض</label>
            <input
              type="number"
              min="0"
              value={formData.low_stock_alert}
              onChange={(e) => setFormData({ ...formData, low_stock_alert: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
            <p className="text-xs text-text-primary mt-1">عند وصول المخزون لهذا العدد يظهر تنبيه</p>
          </div>

          {/* سعر الشراء */}
          <div>
            <label className="block text-text-primary mb-2">سعر الشراء (دينار)</label>
            <input
              type="number"
              min="0"
              value={formData.cost_price_iqd || ''}
              onChange={(e) => setFormData({ ...formData, cost_price_iqd: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="0"
            />
          </div>

          {/* سعر البيع نقداً */}
          <div>
            <label className="block text-text-primary mb-2">
              سعر البيع نقداً (دينار) <span className="text-danger">*</span>
            </label>
            <input
              type="number"
              required
              min="0"
              value={formData.sell_price_cash_iqd || ''}
              onChange={(e) => setFormData({ ...formData, sell_price_cash_iqd: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="0"
            />
          </div>

          {/* سعر البيع بالقسط */}
          <div>
            <label className="block text-text-primary mb-2">
              سعر البيع بالقسط (دينار) <span className="text-danger">*</span>
            </label>
            <input
              type="number"
              required
              min="0"
              value={formData.sell_price_install_iqd || ''}
              onChange={(e) => setFormData({ ...formData, sell_price_install_iqd: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="0"
            />
          </div>

          {/* وصف المنتج */}
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">وصف المنتج</label>
            <textarea
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="مواصفات المنتج، اللون، الحجم..."
            />
          </div>
        </div>

        {/* ملخص الأسعار */}
        <div className="mt-6 p-4 bg-gray-bg rounded-lg">
          <h3 className="font-semibold text-navy mb-2">ملخص الأسعار</h3>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
            <div>
              <span className="text-text-primary">سعر الشراء:</span>
              <span className="block font-medium">{formatNumber(formData.cost_price_iqd)} IQD</span>
            </div>
            <div>
              <span className="text-text-primary">سعر البيع نقداً:</span>
              <span className="block font-medium text-success">{formatNumber(formData.sell_price_cash_iqd)} IQD</span>
            </div>
            <div>
              <span className="text-text-primary">سعر البيع بالقسط:</span>
              <span className="block font-medium text-electric">{formatNumber(formData.sell_price_install_iqd)} IQD</span>
            </div>
            {formData.sell_price_install_iqd > formData.sell_price_cash_iqd && (
              <div className="col-span-2 md:col-span-3 mt-2">
                <span className="text-text-primary">الفرق (ربح القسط):</span>
                <span className="block font-medium text-warning">
                  {formatNumber(formData.sell_price_install_iqd - formData.sell_price_cash_iqd)} IQD
                </span>
              </div>
            )}
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
            className="border border-gray-300 text-text-primary hover:bg-gray-50 px-6 py-2 rounded-lg transition"
          >
            إلغاء
          </Link>
        </div>
      </form>
    </div>
  );
}
