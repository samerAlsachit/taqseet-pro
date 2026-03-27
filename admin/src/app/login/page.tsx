'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [showForgotUsername, setShowForgotUsername] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotPhone, setForgotPhone] = useState('');
  const [forgotUsername, setForgotUsername] = useState('');
  const [forgotMessage, setForgotMessage] = useState('');
  const [forgotLoading, setForgotLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      const data = await response.json();

      if (data.success) {
        const token = data.data.token;
        localStorage.setItem('token', token);
        document.cookie = `token=${token}; path=/; max-age=2592000`;
        router.push('/dashboard');
      } else {
        setError(data.error || 'فشل تسجيل الدخول');
      }
    } catch (err) {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  const handleForgotUsername = async () => {
    setForgotLoading(true);
    setForgotMessage('');
    const input = forgotEmail;
    const isEmail = input.includes('@');
    const payload = isEmail ? { email: input } : { phone: input };
    
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/forgot-username`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await response.json();
      if (data.success) {
        setForgotMessage(data.message);
        setTimeout(() => setShowForgotUsername(false), 3000);
      } else {
        setForgotMessage(data.error);
      }
    } catch {
      setForgotMessage('حدث خطأ في الاتصال بالخادم');
    } finally {
      setForgotLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    setForgotLoading(true);
    setForgotMessage('');
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/forgot-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: forgotUsername })
      });
      const data = await response.json();
      if (data.success) {
        setForgotMessage(data.message);
        setTimeout(() => setShowForgotPassword(false), 3000);
      } else {
        setForgotMessage(data.error);
      }
    } catch {
      setForgotMessage('حدث خطأ في الاتصال بالخادم');
    } finally {
      setForgotLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-bg p-4">
      <div className="bg-white rounded-xl shadow-lg p-8 w-full max-w-md">
        <div className="text-center mb-8">
  <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-navy to-electric mb-4">
    <span className="text-3xl">⚓</span>
  </div>
  <h1 className="text-4xl font-bold bg-gradient-to-r from-navy to-electric bg-clip-text text-transparent">
    مرساة
  </h1>
  <p className="text-text-primary mt-2">لوحة التحكم</p>
</div>

        {error && (
          <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-4 text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-text-primary mb-2">اسم المستخدم</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric focus:border-transparent"
              placeholder="أدخل اسم المستخدم"
              required
            />
          </div>

          <div className="mb-6">
            <label className="block text-text-primary mb-2">كلمة المرور</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric focus:border-transparent"
              placeholder="أدخل كلمة المرور"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-electric hover:bg-blue-600 text-white py-2 px-4 rounded-lg transition duration-200 disabled:opacity-50"
          >
            {loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول'}
          </button>

          <div className="flex justify-between items-center mt-6 pt-4 border-t border-gray-200">
            <button
              type="button"
              onClick={() => setShowForgotUsername(true)}
              className="text-sm text-electric hover:underline"
            >
              نسيت اسم المستخدم؟
            </button>
            <button
              type="button"
              onClick={() => setShowForgotPassword(true)}
              className="text-sm text-electric hover:underline"
            >
              نسيت كلمة المرور؟
            </button>
          </div>
        </form>

        {/* Modal استعادة اسم المستخدم */}
        {showForgotUsername && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl p-6 w-full max-w-md">
              <h2 className="text-xl font-bold text-navy mb-4">استعادة اسم المستخدم</h2>
              <p className="text-text-primary text-sm mb-4">أدخل بريدك الإلكتروني أو رقم هاتفك</p>
              <input
                type="text"
                placeholder="البريد الإلكتروني أو رقم الهاتف"
                value={forgotEmail}
                onChange={(e) => setForgotEmail(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg mb-4 focus:outline-none focus:ring-2 focus:ring-electric"
              />
              {forgotMessage && (
                <div className="mb-4 text-center text-sm text-success">{forgotMessage}</div>
              )}
              <div className="flex gap-3">
                <button
                  onClick={handleForgotUsername}
                  disabled={forgotLoading || !forgotEmail}
                  className="flex-1 bg-electric text-white py-2 rounded-lg disabled:opacity-50"
                >
                  {forgotLoading ? 'جاري الإرسال...' : 'إرسال'}
                </button>
                <button
                  onClick={() => { setShowForgotUsername(false); setForgotMessage(''); setForgotEmail(''); }}
                  className="flex-1 border border-gray-300 text-text-primary py-2 rounded-lg"
                >
                  إلغاء
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal استعادة كلمة المرور */}
        {showForgotPassword && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl p-6 w-full max-w-md">
              <h2 className="text-xl font-bold text-navy mb-4">استعادة كلمة المرور</h2>
              <p className="text-text-primary text-sm mb-4">أدخل اسم المستخدم الخاص بك</p>
              <input
                type="text"
                placeholder="اسم المستخدم *"
                value={forgotUsername}
                onChange={(e) => setForgotUsername(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg mb-4 focus:outline-none focus:ring-2 focus:ring-electric"
              />
              {forgotMessage && (
                <div className="mb-4 text-center text-sm text-success">{forgotMessage}</div>
              )}
              <div className="flex gap-3">
                <button
                  onClick={handleForgotPassword}
                  disabled={forgotLoading || !forgotUsername}
                  className="flex-1 bg-electric text-white py-2 rounded-lg disabled:opacity-50"
                >
                  {forgotLoading ? 'جاري الإرسال...' : 'إرسال'}
                </button>
                <button
                  onClick={() => { setShowForgotPassword(false); setForgotMessage(''); setForgotUsername(''); }}
                  className="flex-1 border border-gray-300 text-text-primary py-2 rounded-lg"
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
