'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

interface StoreSettings {
  id: string;
  name: string;
  owner_name: string;
  phone: string;
  address: string;
  city: string;
  logo_url: string;
  receipt_header: string;
  receipt_footer: string;
  default_currency: string;
}

export default function SettingsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [store, setStore] = useState<StoreSettings | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    owner_name: '',
    phone: '',
    address: '',
    city: '',
    receipt_header: '',
    receipt_footer: '',
    default_currency: 'IQD'
  });

  // جلب بيانات المحل
  useEffect(() => {
    const fetchStore = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        router.push('/login');
        return;
      }

      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          const storeData = data.data.store;
          setStore(storeData);
          setFormData({
            name: storeData.name || '',
            owner_name: storeData.owner_name || '',
            phone: storeData.phone || '',
            address: storeData.address || '',
            city: storeData.city || '',
            receipt_header: storeData.receipt_header || '',
            receipt_footer: storeData.receipt_footer || '',
            default_currency: storeData.default_currency || 'IQD'
          });
        } else {
          setError(data.error || 'فشل في جلب بيانات المحل');
        }
      } catch {
        setError('حدث خطأ في الاتصال بالخادم');
      } finally {
        setLoading(false);
      }
    };

    fetchStore();
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    setSuccess('');

    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/settings`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        setSuccess('تم تحديث إعدادات المحل بنجاح');
        // تحديث store في state
        setStore(prev => prev ? { ...prev, ...formData } : null);
      } else {
        setError(data.error || 'فشل في تحديث الإعدادات');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setSaving(false);
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
      <h1 className="text-2xl font-bold text-navy mb-6">إعدادات المحل</h1>

      {error && (
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      {success && (
        <div className="bg-green-50 text-success border border-success/20 rounded-lg p-3 mb-6">
          {success}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-6">
        {/* معلومات المحل الأساسية */}
        <h2 className="text-xl font-bold text-navy mb-4 pb-2 border-b">معلومات المحل</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div>
            <label className="block text-text-primary mb-2">اسم المحل *</label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>
          <div>
            <label className="block text-text-primary mb-2">اسم المالك *</label>
            <input
              type="text"
              required
              value={formData.owner_name}
              onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>
          <div>
            <label className="block text-text-primary mb-2">رقم الهاتف *</label>
            <input
              type="tel"
              required
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>
          <div>
            <label className="block text-text-primary mb-2">المدينة</label>
            <input
              type="text"
              value={formData.city}
              onChange={(e) => setFormData({ ...formData, city: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">العنوان</label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>
          <div>
            <label className="block text-text-primary mb-2">العملة الافتراضية</label>
            <select
              value={formData.default_currency}
              onChange={(e) => setFormData({ ...formData, default_currency: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            >
              <option value="IQD">دينار عراقي (IQD)</option>
              <option value="USD">دولار أمريكي (USD)</option>
            </select>
          </div>
        </div>

        {/* إعدادات الوصل */}
        <h2 className="text-xl font-bold text-navy mb-4 pb-2 border-b mt-6">إعدادات الوصل</h2>
        <div className="grid grid-cols-1 gap-6 mb-8">
          <div>
            <label className="block text-text-primary mb-2">رأس الوصل (Header)</label>
            <textarea
              rows={3}
              value={formData.receipt_header}
              onChange={(e) => setFormData({ ...formData, receipt_header: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="نص يظهر أعلى الوصل مثل: شكراً لثقتكم بنا"
            />
          </div>
          <div>
            <label className="block text-text-primary mb-2">تذييل الوصل (Footer)</label>
            <textarea
              rows={3}
              value={formData.receipt_footer}
              onChange={(e) => setFormData({ ...formData, receipt_footer: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              placeholder="نص يظهر أسفل الوصل مثل: للاستفسار: 077XXXXXXXX"
            />
          </div>
        </div>

        <div className="flex gap-3 pt-4 border-t">
          <button
            type="submit"
            disabled={saving}
            className="bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
          >
            {saving ? 'جاري الحفظ...' : 'حفظ التغييرات'}
          </button>
          <button
            type="button"
            onClick={() => router.push('/dashboard')}
            className="border border-gray-300 text-text-primary hover:bg-gray-50 px-6 py-2 rounded-lg transition"
          >
            إلغاء
          </button>
        </div>
      </form>

      {/* قسم الاشتراك (اختياري) */}
      {store && (
        <div className="bg-white rounded-xl shadow-sm p-6 mt-8">
          <h2 className="text-xl font-bold text-navy mb-4 pb-2 border-b">معلومات الاشتراك</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-text-primary text-sm">تاريخ بداية الاشتراك</p>
              <p className="font-medium">{new Date(store.subscription_start).toLocaleDateString('ar-IQ')}</p>
            </div>
            <div>
              <p className="text-text-primary text-sm">تاريخ انتهاء الاشتراك</p>
              <p className="font-medium text-danger">{new Date(store.subscription_end).toLocaleDateString('ar-IQ')}</p>
            </div>
          </div>
          <div className="mt-4 p-3 bg-gray-bg rounded-lg">
            <p className="text-text-primary text-sm">للتجديد أو الاستفسار عن الاشتراك، يرجى التواصل مع الدعم:</p>
            <p className="text-electric text-sm mt-1">📞 077XXXXXXXX | 📧 support@marsat.com</p>
          </div>
        </div>
      )}
    </div>
  );
}
