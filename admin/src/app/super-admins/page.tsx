'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { UserPlus, Trash2, Shield } from 'lucide-react';
import toast from 'react-hot-toast';

interface SuperAdmin {
  id: string;
  username: string;
  full_name: string;
  phone: string;
  created_at: string;
}

export default function SuperAdminsPage() {
  const [admins, setAdmins] = useState<SuperAdmin[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    full_name: '',
    phone: ''
  });
  const [submitting, setSubmitting] = useState(false);

  const fetchAdmins = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/super-admins`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) setAdmins(data.data);
    } catch (error) {
      console.error('خطأ في جلب السوبر أدمن', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAdmins();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/super-admins`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم إضافة السوبر أدمن بنجاح');
        setShowModal(false);
        setFormData({ username: '', password: '', full_name: '', phone: '' });
        fetchAdmins();
      } else {
        toast.error(data.error || 'فشل في الإضافة');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا السوبر أدمن؟')) return;
    
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/super-admins/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم الحذف بنجاح');
        fetchAdmins();
      } else {
        toast.error(data.error || 'فشل في الحذف');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    }
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-2">
            <Shield className="text-electric" size={28} />
            <h1 className="text-2xl font-bold text-navy dark:text-white">إدارة السوبر أدمن</h1>
          </div>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
          >
            <UserPlus size={18} />
            <span>إضافة سوبر أدمن</span>
          </button>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">اسم المستخدم</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">الاسم الكامل</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">رقم الهاتف</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">تاريخ التسجيل</th>
                <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400"></th>
              </tr>
            </thead>
            <tbody>
              {admins.map((admin) => (
                <tr key={admin.id} className="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                  <td className="py-3 px-4 text-gray-900 dark:text-white">{admin.username}</td>
                  <td className="py-3 px-4 text-gray-900 dark:text-white">{admin.full_name}</td>
                  <td className="py-3 px-4 text-gray-900 dark:text-white">{admin.phone || '-'}</td>
                  <td className="py-3 px-4 text-gray-900 dark:text-white">
                    {new Date(admin.created_at).toLocaleDateString('ar-IQ')}
                  </td>
                  <td className="py-3 px-4">
                    <button
                      onClick={() => handleDelete(admin.id)}
                      className="text-danger hover:text-red-700 transition"
                    >
                      <Trash2 size={18} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {showModal && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 w-full max-w-md">
              <h2 className="text-xl font-bold text-navy dark:text-white mb-4">إضافة سوبر أدمن جديد</h2>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-gray-700 dark:text-gray-300 mb-2">اسم المستخدم *</label>
                  <input
                    type="text"
                    required
                    value={formData.username}
                    onChange={(e) => setFormData({...formData, username: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 dark:text-gray-300 mb-2">كلمة المرور *</label>
                  <input
                    type="password"
                    required
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 dark:text-gray-300 mb-2">الاسم الكامل *</label>
                  <input
                    type="text"
                    required
                    value={formData.full_name}
                    onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 dark:text-gray-300 mb-2">رقم الهاتف</label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({...formData, phone: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  />
                </div>
                <div className="flex gap-3 pt-4">
                  <button
                    type="submit"
                    disabled={submitting}
                    className="flex-1 bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition disabled:opacity-50"
                  >
                    {submitting ? 'جاري الإضافة...' : 'إضافة'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowModal(false)}
                    className="flex-1 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 py-2 rounded-lg"
                  >
                    إلغاء
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
