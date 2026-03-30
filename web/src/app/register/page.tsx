'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Anchor } from 'lucide-react';

export default function RegisterPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [plans, setPlans] = useState([]);
  const [formData, setFormData] = useState({
    store_name: '',
    owner_name: '',
    email: '',
    phone: '',
    address: '',
    city: '',
    username: '',
    password: '',
    confirm_password: ''
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (formData.password !== formData.confirm_password) {
      setError('كلمة المرور غير متطابقة');
      return;
    }
    
    setLoading(true);
    setError('');

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/register-trial`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          store_name: formData.store_name,
          owner_name: formData.owner_name,
          email: formData.email,
          phone: formData.phone,
          address: formData.address,
          city: formData.city,
          username: formData.username,
          password: formData.password
        })
      });

      const data = await response.json();

      if (data.success) {
        localStorage.setItem('token', data.data.token);
        router.push('/dashboard');
      } else {
        setError(data.error || 'فشل في إنشاء الحساب');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--bg-primary)] p-4">
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 w-full max-w-md border border-gray-200 dark:border-gray-700">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-navy mb-3">
            <Anchor className="text-white" size={32} />
          </div>
          <h1 className="text-3xl font-bold text-navy dark:text-white">مرساة</h1>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">فترة تجريبية مجانية لمدة 14 يوم</p>
        </div>

        {error && (
          <div className="bg-red-50 dark:bg-red-900/30 text-danger border border-danger/20 rounded-lg p-3 mb-4 text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div className="mb-4">
              <label className="block text-gray-900 dark:text-white mb-2">اسم المحل *</label>
              <input
                type="text"
                required
                value={formData.store_name}
                onChange={(e) => setFormData({...formData, store_name: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-900 dark:text-white mb-2">اسم المالك *</label>
              <input
                type="text"
                required
                value={formData.owner_name}
                onChange={(e) => setFormData({...formData, owner_name: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-900 dark:text-white mb-2">البريد الإلكتروني *</label>
              <input
                type="email"
                required
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-900 dark:text-white mb-2">رقم الهاتف *</label>
              <input
                type="tel"
                required
                value={formData.phone}
                onChange={(e) => setFormData({...formData, phone: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-900 dark:text-white mb-2">اسم المستخدم *</label>
              <input
                type="text"
                required
                value={formData.username}
                onChange={(e) => setFormData({...formData, username: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-900 dark:text-white mb-2">كلمة المرور *</label>
              <input
                type="password"
                required
                value={formData.password}
                onChange={(e) => setFormData({...formData, password: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
            <div className="mb-6">
              <label className="block text-gray-900 dark:text-white mb-2">تأكيد كلمة المرور *</label>
              <input
                type="password"
                required
                value={formData.confirm_password}
                onChange={(e) => setFormData({...formData, confirm_password: e.target.value})}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition disabled:opacity-50 mt-2"
          >
            {loading ? 'جاري إنشاء الحساب...' : 'ابدأ التجربة المجانية'}
          </button>
        </form>

        <p className="text-center text-gray-500 dark:text-gray-400 text-sm mt-6">
          لديك حساب؟{' '}
          <Link href="/login" className="text-electric hover:underline">تسجيل الدخول</Link>
        </p>
      </div>
    </div>
  );
}
