'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';

export default function EditCustomerPage() {
  const router = useRouter();
  const params = useParams();
  const customerId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    full_name: '',
    phone: '',
    phone_alt: '',
    address: '',
    national_id: '',
    notes: ''
  });

  // جلب بيانات العميل
  useEffect(() => {
    const fetchCustomer = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        router.push('/login');
        return;
      }

      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers/${customerId}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          const customer = data.data.customer;
          setFormData({
            full_name: customer.full_name || '',
            phone: customer.phone || '',
            phone_alt: customer.phone_alt || '',
            address: customer.address || '',
            national_id: customer.national_id || '',
            notes: customer.notes || ''
          });
        } else {
          setError(data.error || 'العميل غير موجود');
        }
      } catch {
        setError('حدث خطأ في جلب البيانات');
      } finally {
        setLoading(false);
      }
    };

    if (customerId) {
      fetchCustomer();
    }
  }, [customerId, router]);

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
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/customers/${customerId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        router.push(`/customers/${customerId}`);
      } else {
        setError(data.error || 'فشل في تحديث العميل');
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
    <div className="max-w-3xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href={`/customers/${customerId}`} className="text-electric hover:underline">
          ← العودة إلى ملف العميل
        </Link>
        <h1 className="text-2xl font-bold text-navy">تعديل بيانات العميل</h1>
      </div>

      {error && (
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-6">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">
              اسم العميل <span className="text-danger">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.full_name}
              onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">
              رقم الهاتف <span className="text-danger">*</span>
            </label>
            <input
              type="tel"
              required
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">هاتف إضافي</label>
            <input
              type="tel"
              value={formData.phone_alt}
              onChange={(e) => setFormData({ ...formData, phone_alt: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
            />
          </div>

          <div>
            <label className="block text-text-primary mb-2">الرقم الوطني</label>
            <input
              type="text"
              value={formData.national_id}
              onChange={(e) => setFormData({ ...formData, national_id: e.target.value })}
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

          <div className="md:col-span-2">
            <label className="block text-text-primary mb-2">ملاحظات</label>
            <textarea
              rows={3}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
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
            href={`/customers/${customerId}`}
            className="border border-gray-300 text-text-primary hover:bg-gray-50 px-6 py-2 rounded-lg transition"
          >
            إلغاء
          </Link>
        </div>
      </form>
    </div>
  );
}
