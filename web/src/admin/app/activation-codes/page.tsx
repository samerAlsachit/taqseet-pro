'use client';

import { useState, useEffect } from 'react';
import { useTheme } from '../../context/ThemeContext';

export default function AdminActivationCodes() {
  const { theme } = useTheme();
  const [codes, setCodes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    code: '',
    plan_id: '',
    max_uses: 1,
    expires_at: ''
  });

  useEffect(() => {
    const fetchCodes = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/activation-codes`);
        const data = await res.json();
        if (data.success) setCodes(data.data);
      } catch (error) {
        console.error('Error fetching codes:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchCodes();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/activation-codes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await res.json();
      if (data.success) {
        setCodes([data.data, ...codes]);
        setShowForm(false);
        setFormData({ code: '', plan_id: '', max_uses: 1, expires_at: '' });
      }
    } catch (error) {
      console.error('Error creating code:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--bg-primary)]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--bg-primary)]">
      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">رموز التفعيل</h1>
          <button
            onClick={() => setShowForm(true)}
            className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
          >
            إنشاء رمز جديد
          </button>
        </div>

        {/* Create Code Form */}
        {showForm && (
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 mb-8">
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">إنشاء رمز تفعيل جديد</h2>
            <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-[var(--text-primary)] mb-2">رمز التفعيل</label>
                <input
                  type="text"
                  value={formData.code}
                  onChange={(e) => setFormData({...formData, code: e.target.value})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">الخطة</label>
                <select
                  value={formData.plan_id}
                  onChange={(e) => setFormData({...formData, plan_id: e.target.value})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                >
                  <option value="">اختر خطة</option>
                  <option value="1">تجريبي</option>
                  <option value="2">شهري</option>
                  <option value="3">سنوي</option>
                </select>
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">الحد الأقصى للاستخدام</label>
                <input
                  type="number"
                  value={formData.max_uses}
                  onChange={(e) => setFormData({...formData, max_uses: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">تاريخ الانتهاء</label>
                <input
                  type="date"
                  value={formData.expires_at}
                  onChange={(e) => setFormData({...formData, expires_at: e.target.value})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div className="md:col-span-2 flex gap-3">
                <button
                  type="submit"
                  className="bg-electric hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition"
                >
                  إنشاء
                </button>
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
                  className="border border-[var(--border-color)] text-[var(--text-primary)] hover:bg-[var(--bg-primary)] px-6 py-2 rounded-lg transition"
                >
                  إلغاء
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Codes Table */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">رمز التفعيل</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الخطة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الاستخدامات</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">تاريخ الانتهاء</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">تاريخ الإنشاء</th>
                </tr>
              </thead>
              <tbody>
                {codes.map((code: any) => (
                  <tr key={code.id} className="border-b border-[var(--border-color)] hover:bg-[var(--bg-primary)]">
                    <td className="py-3 px-4 text-[var(--text-primary)] font-mono">{code.code}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{code.plan_name}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{code.used_count}/{code.max_uses}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      {new Date(code.expires_at).toLocaleDateString('ar-IQ')}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-1 rounded-full text-sm ${
                        code.status === 'active' ? 'bg-success/10 text-success' :
                        'bg-danger/10 text-danger'
                      }`}>
                        {code.status === 'active' ? 'نشط' : 'منتهي'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      {new Date(code.created_at).toLocaleDateString('ar-IQ')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
