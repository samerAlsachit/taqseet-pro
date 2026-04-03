'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { connectToBluetoothPrinter } from '@/lib/bluetoothPrint';
import { Settings, User, Store, CreditCard, FileText, Save, X, Users, CheckCircle, Star, Rocket, Calendar, Zap, Phone, Mail, MessageCircle, Bell } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

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
  telegram_chat_id?: string;
  plan_id?: string;
  subscription_end?: string;
  telegram_enabled?: boolean;
  customer_notifications?: boolean;
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
  const [activeTab, setActiveTab] = useState<'info' | 'subscription' | 'notifications'>('info');
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
    telegram_chat_id: '',
    telegram_enabled: false,
    customer_notifications: false,
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
            telegram_chat_id: storeData.telegram_chat_id || '',
            telegram_enabled: storeData.telegram_enabled || false,
            customer_notifications: storeData.customer_notifications || false,
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
    return <LoadingSpinner />;
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
        <Settings size={24} />
        إعدادات المحل
      </h1>

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
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm mb-6">
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="flex space-x-8 px-6" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('info')}
              className={`flex items-center gap-2 pb-2 px-4 ${
                activeTab === 'info'
                  ? 'border-b-2 border-electric text-electric'
                  : 'text-text-primary'
              }`}
            >
              <Store size={18} />
              <span>معلومات المحل</span>
            </button>
            <button
              onClick={() => setActiveTab('subscription')}
              className={`flex items-center gap-2 pb-2 px-4 ${
                activeTab === 'subscription'
                  ? 'border-b-2 border-electric text-electric'
                  : 'text-text-primary'
              }`}
            >
              <CreditCard size={18} />
              <span>الاشتراك</span>
            </button>
            {/* تبويب الإشعارات */}
            <button
              onClick={() => setActiveTab('notifications')}
              className={`flex items-center gap-2 pb-2 px-4 ${
                activeTab === 'notifications' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'
              }`}
            >
              <Bell size={18} />
              <span>الإشعارات</span>
            </button>
          </nav>
        </div>

        {/* محتوى تبويب معلومات المحل */}
        {activeTab === 'info' && (
          <form onSubmit={handleSubmit} className="p-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4 pb-2 border-b">
              معلومات المحل
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">اسم المحل *</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">اسم المالك *</label>
                <input
                  type="text"
                  required
                  value={formData.owner_name}
                  onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">رقم الهاتف *</label>
                <input
                  type="tel"
                  required
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">المدينة</label>
                <input
                  type="text"
                  value={formData.city}
                  onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">معرف تلجرام (Chat ID)</label>
                <input
                  type="text"
                  value={formData.telegram_chat_id}
                  onChange={(e) => setFormData({...formData, telegram_chat_id: e.target.value})}
                  placeholder="أدخل معرف التلجرام لتلقي الإشعارات"
                  className="w-full px-4 py-2 border border-border rounded-lg"
                />
                <p className="text-xs text-gray-500 mt-1">
                  للحصول على Chat ID، ابحث عن @MarsatBot في تلجرام وأرسل /start
                </p>
              </div>
              <div className="md:col-span-2">
                <label className="block text-gray-500 dark:text-gray-400 mb-2">العنوان</label>
                <input
                  type="text"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                />
              </div>
            </div>

            {/* إعدادات العملة */}
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4 pb-2 border-b mt-6">
              إعدادات العملة
            </h2>
            <div className="grid grid-cols-1 gap-6 mb-8">
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">العملة الافتراضية</label>
                <select
                  value={formData.default_currency}
                  onChange={(e) => setFormData({ ...formData, default_currency: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                >
                  <option value="IQD">دينار عراقي (IQD)</option>
                  <option value="USD">دولار أمريكي (USD)</option>
                </select>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  سيتم استخدام هذه العملة كافتراضية عند إنشاء الأقساط
                </p>
              </div>
            </div>

            {/* إعدادات الوصل */}
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4 pb-2 border-b mt-6">
              إعدادات الوصل
            </h2>
            <div className="grid grid-cols-1 gap-6 mb-8">
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">رأس الوصل (Header)</label>
                <textarea
                  rows={3}
                  value={formData.receipt_header}
                  onChange={(e) => setFormData({ ...formData, receipt_header: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  placeholder="نص يظهر أعلى الوصل مثل: شكراً لثقتكم بنا"
                />
              </div>
              <div>
                <label className="block text-gray-500 dark:text-gray-400 mb-2">تذييل الوصل (Footer)</label>
                <textarea
                  rows={3}
                  value={formData.receipt_footer}
                  onChange={(e) => setFormData({ ...formData, receipt_footer: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  placeholder="نص يظهر أسفل الوصل مثل: للاستفسار: 077XXXXXXXX"
                />
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                type="submit"
                disabled={saving}
                className="flex items-center gap-2 bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition disabled:opacity-50"
              >
                <Save size={18} />
                <span>{saving ? 'جاري الحفظ...' : 'حفظ التغييرات'}</span>
              </button>
              <button
                type="button"
                onClick={() => router.push('/dashboard')}
                className="flex items-center gap-2 border border-gray-300 dark:border-gray-600 text-text-primary hover:bg-gray-100 dark:hover:bg-gray-700 px-6 py-2 rounded-lg transition"
              >
                <X size={18} />
                <span>إلغاء</span>
              </button>
            </div>
          </form>
        )}

        {/* محتوى تبويب الاشتراك */}
        {activeTab === 'subscription' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">معلومات الاشتراك</h2>

            {subscription && (
              <div className="mb-6 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600">
                {subscription.is_trial ? (
                  <p className="text-gray-900 dark:text-gray-200">
                    أنت في فترة التجربة المجانية.{' '}
                    {subscription.trial_days_remaining !== null && (
                      <span className="font-bold text-blue-600">
                        متبقي {subscription.trial_days_remaining} يوم
                      </span>
                    )}
                  </p>
                ) : subscription.is_active ? (
                  <p className="text-gray-900 dark:text-gray-200">
                    اشتراكك نشط.{' '}
                    {subscription.days_remaining !== null && (
                      <span className="font-bold text-blue-600">
                        متبقي {subscription.days_remaining} يوم
                      </span>
                    )}
                  </p>
                ) : (
                  <p className="text-danger font-bold">اشتراكك منتهي. يرجى تجديد الاشتراك.</p>
                )}
              </div>
            )}

            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">الخطط المتاحة</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {plans.map((plan: any) => {
                const isYearly = plan.name === 'سنوي';
                const isThreeYear = plan.name === '3 سنوات';
                const isMonthly = plan.name === 'شهري';
                
                return (
                  <div
                    key={plan.id}
                    className={`border rounded-xl p-6 hover:shadow-lg transition relative ${
                      isYearly ? 'border-2 border-electric' : 'border border-gray-300 dark:border-gray-600'
                    } bg-white dark:bg-gray-800`}
                  >
                    {isYearly && (
                      <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-electric text-white px-3 py-1 rounded-full text-sm flex items-center gap-1">
                        <Star size={12} />
                        <span>الأكثر طلباً</span>
                      </div>
                    )}
                    
                    {isMonthly && (
                      <Calendar className="text-electric w-10 h-10 mb-3" />
                    )}
                    
                    {isThreeYear && (
                      <Rocket className="text-electric w-10 h-10 mb-3" />
                    )}
                    
                    {isYearly && (
                      <Star className="text-yellow-500 w-10 h-10 mb-3" />
                    )}
                    
                    <h3 className="text-xl font-bold text-navy dark:text-white mb-2">{plan.name}</h3>
                    <p className="text-blue-600 font-bold text-xl my-2">
                      {plan.price} {plan.currency}
                    </p>
                    <ul className="text-gray-900 dark:text-gray-200 text-sm space-y-1 mb-6">
                      {plan.features?.map((f: string, i: number) => (
                        <li key={i} className="flex items-center gap-2">
                          <CheckCircle size={16} className="text-success" />
                          <span>{f}</span>
                        </li>
                      ))}
                    </ul>
                    <button
                      onClick={() =>
                        alert(`طلب اشتراك في خطة ${plan.name} - سيتم التواصل معك قريباً`)
                      }
                      className="btn-primary"
                    >
                      اشتراك
                    </button>
                  </div>
                );
              })}
            </div>
            <div className="mt-8 p-4 bg-gray-50 dark:bg-gray-800/50 rounded-lg text-center">
              <p className="text-gray-700 dark:text-gray-300 text-sm mb-3">للاستفسار عن الاشتراك، يرجى التواصل مع الدعم:</p>
              <div className="flex flex-col sm:flex-row justify-center gap-4 text-sm">
                <div className="flex items-center justify-center gap-2 text-gray-600 dark:text-gray-400">
                  <Phone size={16} className="text-electric" />
                  <span>077XXXXXXXX</span>
                </div>
                <div className="flex items-center justify-center gap-2 text-gray-600 dark:text-gray-400">
                  <Mail size={16} className="text-electric" />
                  <span>support@marsat.com</span>
                </div>
                <div className="flex items-center justify-center gap-2 text-gray-600 dark:text-gray-400">
                  <MessageCircle size={16} className="text-success" />
                  <span>واتساب</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* تبويب الإشعارات */}
        {activeTab === 'notifications' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">إعدادات الإشعارات</h2>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">إشعارات تلجرام</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">استقبال إشعارات انتهاء الاشتراك والأقساط المستحقة</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={settings.telegram_enabled} onChange={(e) => setFormData({ ...formData, telegram_enabled: e.target.checked })} />
                  <div className="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-electric"></div>
                </label>
              </div>

              <div className="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">إشعارات الزبائن</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">إرسال تذكير للزبائن قبل موعد القسط</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={settings.customer_notifications} onChange={(e) => setFormData({ ...formData, customer_notifications: e.target.checked })} />
                  <div className="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-electric"></div>
                </label>
              </div>
            </div>
          </div>
        )}

        {/* إعدادات الطباعة */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">إعدادات الطباعة</h2>
          <p className="text-gray-900 dark:text-gray-200 mb-4">طابعة بلوتوث</p>
          {bluetoothPrinter ? (
            <div className="flex justify-between items-center">
              <span className="text-gray-900 dark:text-gray-200">
                الطابعة المتصلة: {bluetoothPrinter.name}
              </span>
              <button
                onClick={() => setBluetoothPrinter(null)}
                className="btn-outline"
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
              className="btn-primary"
            >
              توصيل طابعة بلوتوث
            </button>
          )}
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-4">
            ملاحظة: هذه الميزة تعمل على المتصفحات التي تدعم Web Bluetooth (Chrome, Edge)
          </p>
        </div>
      </div>
    </div>
  );
}
