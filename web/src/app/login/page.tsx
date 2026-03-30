'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import toast from 'react-hot-toast';
import { Anchor } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showForgotUsername, setShowForgotUsername] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotUsername, setForgotUsername] = useState('');
  const [forgotMessage, setForgotMessage] = useState('');
  const [forgotLoading, setForgotLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      const data = await response.json();

      if (data.success) {
        localStorage.setItem('token', data.data.token);
        toast.success('تم تسجيل الدخول بنجاح');
        router.push('/dashboard');
      } else {
        toast.error(data.error || 'فشل تسجيل الدخول');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  const handleForgotUsername = async () => {
    if (!forgotEmail) {
      toast.error('يرجى إدخال البريد الإلكتروني');
      return;
    }

    setForgotLoading(true);
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/forgot-username`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: forgotEmail })
      });
      const data = await response.json();
      if (data.success) {
        toast.success('تم إرسال اسم المستخدم إلى بريدك الإلكتروني');
        setShowForgotUsername(false);
        setForgotEmail('');
      } else {
        toast.error(data.error || 'فشل في استعادة اسم المستخدم');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    } finally {
      setForgotLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    if (!forgotUsername) {
      toast.error('يرجى إدخال اسم المستخدم');
      return;
    }

    setForgotLoading(true);
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/forgot-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: forgotUsername })
      });
      const data = await response.json();
      if (data.success) {
        toast.success('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
        setShowForgotPassword(false);
        setForgotUsername('');
      } else {
        toast.error(data.error || 'فشل في استعادة كلمة المرور');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    } finally {
      setForgotLoading(false);
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
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">تسجيل الدخول</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-gray-500 dark:text-gray-400 mb-2">اسم المستخدم</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              placeholder="أدخل اسم المستخدم"
              required
            />
          </div>

          <div className="mb-6">
            <label className="block text-gray-500 dark:text-gray-400 mb-2">كلمة المرور</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              placeholder="أدخل كلمة المرور"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition disabled:opacity-50 mt-2"
          >
            {loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول'}
          </button>
        </form>

        <div className="flex justify-between items-center mt-4">
          <button
            type="button"
            onClick={() => setShowForgotUsername(true)}
            className="text-electric hover:underline"
          >
            نسيت اسم المستخدم؟
          </button>
          <button
            type="button"
            onClick={() => setShowForgotPassword(true)}
            className="text-electric hover:underline"
          >
            نسيت كلمة المرور؟
          </button>
        </div>

        <div className="text-center text-gray-500 dark:text-gray-400 text-sm mt-6">
          ليس لديك حساب؟{' '}
          <Link href="/register" className="text-electric hover:underline">سجل الآن</Link>
        </div>

        {/* Modal Forgot Username */}
        {showForgotUsername && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 w-full max-w-md border border-gray-300 dark:border-gray-600">
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white text-center mb-6">استعادة اسم المستخدم</h2>
              <p className="text-gray-500 dark:text-gray-400 text-sm mb-4">أدخل بريدك الإلكتروني</p>
              <input
                type="email"
                placeholder="البريد الإلكتروني"
                value={forgotEmail}
                onChange={(e) => setForgotEmail(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg mb-4 focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
              />
              <div className="flex gap-3">
                <button
                  onClick={handleForgotUsername}
                  disabled={forgotLoading || !forgotEmail}
                  className="flex-1 bg-blue-600 text-white py-2 rounded-lg disabled:opacity-50"
                >
                  {forgotLoading ? 'جاري الإرسال...' : 'إرسال'}
                </button>
                <button
                  onClick={() => setShowForgotUsername(false)}
                  className="flex-1 border border-gray-300 dark:border-gray-600 text-gray-500 dark:text-gray-400 py-2 rounded-lg"
                >
                  إلغاء
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal Forgot Password */}
        {showForgotPassword && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 w-full max-w-md border border-gray-300 dark:border-gray-600">
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white text-center mb-6">استعادة كلمة المرور</h1>
              <p className="text-gray-500 dark:text-gray-400 text-sm mb-4">أدخل اسم المستخدم الخاص بك</p>
              <input
                type="text"
                placeholder="اسم المستخدم"
                value={forgotUsername}
                onChange={(e) => setForgotUsername(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg mb-4 focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
              />
              <div className="flex gap-3">
                <button
                  onClick={handleForgotPassword}
                  disabled={forgotLoading}
                  className="flex-1 bg-blue-600 text-white py-2 rounded-lg disabled:opacity-50"
                >
                  {forgotLoading ? 'جاري الإرسال...' : 'إرسال'}
                </button>
                <button
                  onClick={() => { setShowForgotPassword(false); setForgotUsername(''); }}
                  className="flex-1 border border-gray-300 dark:border-gray-600 text-gray-500 dark:text-gray-400 py-2 rounded-lg"
                >
                  إلغاء
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}