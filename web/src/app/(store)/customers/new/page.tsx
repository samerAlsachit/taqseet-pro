'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function NewCustomerPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    full_name: '',
    phone: '',
    phone_alt: '',
    address: '',
    national_id: '',
    notes: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        router.push('/customers');
      } else {
        setError(data.error || 'فشل في إضافة العميل');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 sm:px-6 lg:px-8 bg-[#F0F2F5] dark:bg-[#0D1117]">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/customers" className="text-blue-600 dark:text-blue-400 hover:underline">
          ← العودة إلى العملاء
        </Link>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إضافة عميل جديد</h1>
      </div>

      {error && (
        <div className="bg-red-50 text-red-600 border border-red-200 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white dark:bg-[#161B22] rounded-xl shadow-md border border-gray-100 dark:border-[#30363D] p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">
              اسم العميل <span className="text-danger">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.full_name}
              onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">
              رقم الهاتف <span className="text-danger">*</span>
            </label>
            <input
              type="tel"
              required
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">هاتف إضافي</label>
            <input
              type="tel"
              value={formData.phone_alt}
              onChange={(e) => setFormData({ ...formData, phone_alt: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          <div>
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">الرقم الوطني</label>
            <input
              type="text"
              value={formData.national_id}
              onChange={(e) => setFormData({ ...formData, national_id: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          <div className="md:col-span-2">
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">العنوان</label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>

          <div className="md:col-span-2">
            <label className="block text-gray-700 dark:text-gray-300 font-medium mb-2">ملاحظات</label>
            <textarea
              rows={3}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="w-full px-4 py-2 bg-white dark:bg-[#1C2128] border border-gray-300 dark:border-[#30363D] text-gray-900 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3A86FF] focus:border-transparent transition-colors duration-200"
            />
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button
            type="submit"
            disabled={loading}
            className="btn-primary"
          >
            {loading ? 'جاري الحفظ...' : 'حفظ العميل'}
          </button>
          <Link
            href="/customers"
            className="btn-outline"
          >
            إلغاء
          </Link>
        </div>
      </form>
    </div>
  );
}
