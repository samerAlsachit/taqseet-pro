'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';

export default function EditProductPage() {
  const router = useRouter();
  const params = useParams();
  const productId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
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

  // جلب بيانات المنتج
  useEffect(() => {
    const fetchProduct = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        router.push('/login');
        return;
      }

      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products/${productId}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          const product = data.data;
          setFormData({
            name: product.name || '',
            category: product.category || '',
            quantity: product.quantity || 0,
            low_stock_alert: product.low_stock_alert || 5,
            cost_price_iqd: product.cost_price_iqd || 0,
            sell_price_cash_iqd: product.sell_price_cash_iqd || 0,
            sell_price_install_iqd: product.sell_price_install_iqd || 0,
            description: product.description || ''
          });
        } else {
          setError(data.error || 'المنتج غير موجود');
        }
      } catch {
        setError('حدث خطأ في جلب البيانات');
      } finally {
        setLoading(false);
      }
    };

    if (productId) {
      fetchProduct();
    }
  }, [productId, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');

    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products/${productId}`, {
        method: 'PUT',
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
        setError(data.error || 'فشل في تحديث المنتج');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/products" className="text-electric hover:underline">
          ← العودة إلى المخزن
        </Link>
        <h1 className="text-2xl font-bold text-navy">تعديل المنتج</h1>
      </div>

      {error && (
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">اسم المنتج *</label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">الفئة</label>
            <input
              type="text"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">الكمية *</label>
            <input
              type="number"
              required
              min="0"
              value={formData.quantity}
              onChange={(e) => setFormData({ ...formData, quantity: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">حد التنبيه للمخزون المنخفض</label>
            <input
              type="number"
              min="0"
              value={formData.low_stock_alert}
              onChange={(e) => setFormData({ ...formData, low_stock_alert: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">سعر الشراء (دينار)</label>
            <input
              type="number"
              min="0"
              value={formData.cost_price_iqd || ''}
              onChange={(e) => setFormData({ ...formData, cost_price_iqd: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">سعر البيع نقداً *</label>
            <input
              type="number"
              required
              min="0"
              value={formData.sell_price_cash_iqd || ''}
              onChange={(e) => setFormData({ ...formData, sell_price_cash_iqd: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">سعر البيع بالقسط *</label>
            <input
              type="number"
              required
              min="0"
              value={formData.sell_price_install_iqd || ''}
              onChange={(e) => setFormData({ ...formData, sell_price_install_iqd: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">وصف المنتج</label>
            <textarea
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button
            type="submit"
            disabled={submitting}
            className="bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
          >
            {submitting ? 'جاري الحفظ...' : 'حفظ التغييرات'}
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
