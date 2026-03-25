'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function ActivatePage() {
  const router = useRouter();
  const [step, setStep] = useState<'code' | 'form'>('code');
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    store_name: '',
    owner_name: '',
    phone: '',
    address: '',
    city: '',
    username: '',
    password: '',
    confirm_password: ''
  });

  const verifyCode = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/verify-code`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code })
      });
      const data = await res.json();
      if (data.success) {
        setStep('form');
      } else {
        setError(data.error || 'الكود غير صالح');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (formData.password !== formData.confirm_password) {
      setError('كلمة المرور غير متطابقة');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/activate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code, ...formData })
      });
      const data = await res.json();
      if (data.success) {
        localStorage.setItem('token', data.data.token);
        router.push('/dashboard');
      } else {
        setError(data.error || 'فشل في تفعيل المحل');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-bg p-4">
      <div className="bg-white rounded-xl shadow-lg p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-navy">تقسيط برو</h1>
          <p className="text-text-primary mt-2">تفعيل حساب المحل</p>
        </div>

        {error && (
          <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-4 text-center">
            {error}
          </div>
        )}

        {step === 'code' ? (
          <div>
            <label className="block text-text-primary mb-2">كود التفعيل</label>
            <input
              type="text"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="مثال: TQST-XXXX-XXXX"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric mb-4"
            />
            <button
              onClick={verifyCode}
              disabled={loading || !code}
              className="w-full bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition disabled:opacity-50"
            >
              {loading ? 'جاري التحقق...' : 'التحقق من الكود'}
            </button>
            <p className="text-center text-text-primary text-sm mt-4">
              لديك حساب؟{' '}
              <Link href="/login" className="text-electric hover:underline">
                تسجيل الدخول
              </Link>
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="space-y-4">
              <div>
                <label className="block text-text-primary mb-2">اسم المحل *</label>
                <input
                  type="text"
                  required
                  value={formData.store_name}
                  onChange={(e) => setFormData({...formData, store_name: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">اسم المالك *</label>
                <input
                  type="text"
                  required
                  value={formData.owner_name}
                  onChange={(e) => setFormData({...formData, owner_name: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">رقم الهاتف *</label>
                <input
                  type="tel"
                  required
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">اسم المستخدم *</label>
                <input
                  type="text"
                  required
                  value={formData.username}
                  onChange={(e) => setFormData({...formData, username: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">كلمة المرور *</label>
                <input
                  type="password"
                  required
                  value={formData.password}
                  onChange={(e) => setFormData({...formData, password: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">تأكيد كلمة المرور *</label>
                <input
                  type="password"
                  required
                  value={formData.confirm_password}
                  onChange={(e) => setFormData({...formData, confirm_password: e.target.value})}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                />
              </div>
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition disabled:opacity-50"
              >
                {loading ? 'جاري التفعيل...' : 'تفعيل المحل'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
