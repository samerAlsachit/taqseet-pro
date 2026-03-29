'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { connectToBluetoothPrinter } from '@/lib/bluetoothPrint';

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
  plan_id?: string;
  subscription_end?: string;
}

interface SubscriptionData {
  is_trial: boolean;
  trial_days_remaining: number | null;
  days_remaining: number | null;
  expires_at: string | null;
  is_active: boolean;
}

export default function SettingsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [store, setStore] = useState<StoreSettings | null>(null);
  const [subscription, setSubscription] = useState<SubscriptionData | null>(null);
  const [plans, setPlans] = useState<any[]>([]);
  const [activeTab, setActiveTab] = useState<'info' | 'subscription'>('info');
  const [bluetoothPrinter, setBluetoothPrinter] = useState<any>(null);
  const [formData, setFormData] = useState({
    name: '',
    owner_name: '',
    phone: '',
    address: '',
    city: '',
    receipt_header: '',
    receipt_footer: '',
    default_currency: 'IQD',
  });

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/plans`);
        const data = await res.json();
        if (data.success) setPlans(data.data);
      } catch (error) {
        console.error('خطأ في جلب الخطط', error);
      }
    };
    fetchPlans();
  }, []);

  useEffect(() => {
    const fetchStore = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        router.push('/login');
        return;
      }

      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = await res.json();
        if (data.success) {
          const storeData = data.data.store;
          const subscriptionData = data.data.subscription;
          setStore(storeData);
          setSubscription(subscriptionData);
          setFormData({
            name: storeData.name || '',
            owner_name: storeData.owner_name || '',
            phone: storeData.phone || '',
            address: storeData.address || '',
            city: storeData.city || '',
            receipt_header: storeData.receipt_header || '',
            receipt_footer: storeData.receipt_footer || '',
            default_currency: storeData.default_currency || 'IQD',
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

  useEffect(() => {
    const tab = searchParams.get('tab');
    if (tab === 'subscription') {
      setActiveTab('subscription');
    }
  }, [searchParams]);

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
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (data.success) {
        setSuccess('تم تحديث إعدادات المحل بنجاح');
        setStore((prev) => (prev ? { ...prev, ...formData } : null));
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
      <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-6">إعدادات المحل</h1>

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

      {/* تبويبات */}
      <div className="bg-[var(--card-bg)] rounded-xl shadow-sm mb-6">
        <div className="border-b border-[var(--border-color)]">
          <nav className="flex space-x-8 px-6" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('info')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'info'
                  ? 'border-electric text-electric'
                  : 'border-transparent text-[var(--text-primary)] hover:border-gray-300'
              }`}
            >
              معلومات المحل
            </button>
            <button
              onClick={() => setActiveTab('subscription')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'subscription'
                  ? 'border-electric text-electric'
                  : 'border-transparent text-[var(--text-primary)] hover:border-gray-300'
              }`}
            >
              الاشتراك
            </button>
          </nav>
        </div>

        {/* محتوى تبويب معلومات المحل */}
        {activeTab === 'info' && (
          <form onSubmit={handleSubmit} className="p-6">
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4 pb-2 border-b">
              معلومات المحل
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
              <div>
                <label className="block text-[var(--text-primary)] mb-2">اسم المحل *</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">اسم المالك *</label>
                <input
                  type="text"
                  required
                  value={formData.owner_name}
                  onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">رقم الهاتف *</label>
                <input
                  type="tel"
                  required
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">المدينة</label>
                <input
                  type="text"
                  value={formData.city}
                  onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-[var(--text-primary)] mb-2">العنوان</label>
                <input
                  type="text"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
            </div>

            {/* إعدادات العملة */}
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4 pb-2 border-b mt-6">
              إعدادات العملة
            </h2>
            <div className="grid grid-cols-1 gap-6 mb-8">
              <div>
                <label className="block text-[var(--text-primary)] mb-2">العملة الافتراضية</label>
                <select
                  value={formData.default_currency}
                  onChange={(e) => setFormData({ ...formData, default_currency: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                >
                  <option value="IQD">دينار عراقي (IQD)</option>
                  <option value="USD">دولار أمريكي (USD)</option>
                </select>
                <p className="text-xs text-[var(--text-primary)] mt-1">
                  سيتم استخدام هذه العملة كافتراضية عند إنشاء الأقساط
                </p>
              </div>
            </div>

            {/* إعدادات الوصل */}
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4 pb-2 border-b mt-6">
              إعدادات الوصل
            </h2>
            <div className="grid grid-cols-1 gap-6 mb-8">
              <div>
                <label className="block text-[var(--text-primary)] mb-2">رأس الوصل (Header)</label>
                <textarea
                  rows={3}
                  value={formData.receipt_header}
                  onChange={(e) => setFormData({ ...formData, receipt_header: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                  placeholder="نص يظهر أعلى الوصل مثل: شكراً لثقتكم بنا"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">تذييل الوصل (Footer)</label>
                <textarea
                  rows={3}
                  value={formData.receipt_footer}
                  onChange={(e) => setFormData({ ...formData, receipt_footer: e.target.value })}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
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
                className="border border-[var(--border-color)] text-[var(--text-primary)] hover:bg-[var(--bg-primary)] px-6 py-2 rounded-lg transition"
              >
                إلغاء
              </button>
            </div>
          </form>
        )}

        {/* محتوى تبويب الاشتراك */}
        {activeTab === 'subscription' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">معلومات الاشتراك</h2>

            {subscription && (
              <div className="mb-6 p-4 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]">
                {subscription.is_trial ? (
                  <p className="text-[var(--text-primary)]">
                    أنت في فترة التجربة المجانية.{' '}
                    {subscription.trial_days_remaining !== null && (
                      <span className="font-bold text-electric">
                        متبقي {subscription.trial_days_remaining} يوم
                      </span>
                    )}
                  </p>
                ) : subscription.is_active ? (
                  <p className="text-[var(--text-primary)]">
                    اشتراكك نشط.{' '}
                    {subscription.days_remaining !== null && (
                      <span className="font-bold text-electric">
                        متبقي {subscription.days_remaining} يوم
                      </span>
                    )}
                  </p>
                ) : (
                  <p className="text-danger font-bold">اشتراكك منتهي. يرجى تجديد الاشتراك.</p>
                )}
              </div>
            )}

            <h3 className="text-lg font-bold text-[var(--text-primary)] mb-4">الخطط المتاحة</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {plans.map((plan: any) => (
                <div
                  key={plan.id}
                  className="border border-[var(--border-color)] rounded-xl p-4 bg-[var(--card-bg)]"
                >
                  <h4 className="text-lg font-bold text-[var(--text-primary)]">{plan.name}</h4>
                  <p className="text-electric font-bold text-xl my-2">
                    {plan.price} {plan.currency}
                  </p>
                  <ul className="text-[var(--text-primary)] text-sm space-y-1 mb-4">
                    {plan.features?.map((f: string, i: number) => (
                      <li key={i}>✅ {f}</li>
                    ))}
                  </ul>
                  <button
                    onClick={() =>
                      alert(`طلب اشتراك في خطة ${plan.name} - سيتم التواصل معك قريباً`)
                    }
                    className="w-full bg-electric text-white py-2 rounded-lg hover:bg-blue-600 transition"
                  >
                    اشتراك
                  </button>
                </div>
              ))}
            </div>

            <div className="mt-8 p-4 bg-[var(--bg-primary)] rounded-lg text-center border border-[var(--border-color)]">
              <p className="text-[var(--text-primary)] text-sm">
                للاستفسار عن الاشتراك، يرجى التواصل مع الدعم:
                <br />
                📞 077XXXXXXXX | 📧 support@marsat.com
              </p>
            </div>
          </div>
        )}
      </div>

      {/* إعدادات الطباعة */}
      <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
        <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">إعدادات الطباعة</h2>
        <p className="text-[var(--text-primary)] mb-4">طابعة بلوتوث</p>
        {bluetoothPrinter ? (
          <div className="flex justify-between items-center">
            <span className="text-[var(--text-primary)]">
              الطابعة المتصلة: {bluetoothPrinter.name}
            </span>
            <button
              onClick={() => setBluetoothPrinter(null)}
              className="text-danger hover:underline"
            >
              قطع الاتصال
            </button>
          </div>
        ) : (
          <button
            onClick={async () => {
              const printer = await connectToBluetoothPrinter();
              if (printer) setBluetoothPrinter(printer);
            }}
            className="bg-electric text-white px-4 py-2 rounded-lg"
          >
            توصيل طابعة بلوتوث
          </button>
        )}
        <p className="text-[var(--text-primary)] text-sm mt-4">
          ملاحظة: هذه الميزة تعمل على المتصفحات التي تدعم Web Bluetooth (Chrome, Edge)
        </p>
      </div>
    </div>
  );
}