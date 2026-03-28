'use client';

import { useState, useEffect } from 'react';
import { useTheme } from '../../context/ThemeContext';

export default function AdminPlans() {
  const { theme } = useTheme();
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    price_iqd: 0,
    duration_days: 30,
    max_customers: 10,
    max_employees: 3,
    features: []
  });

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/plans`);
        const data = await res.json();
        if (data.success) setPlans(data.data);
      } catch (error) {
        console.error('Error fetching plans:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchPlans();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/plans`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await res.json();
      if (data.success) {
        setPlans([data.data, ...plans]);
        setShowForm(false);
        setFormData({
          name: '',
          price_iqd: 0,
          duration_days: 30,
          max_customers: 10,
          max_employees: 3,
          features: []
        });
      }
    } catch (error) {
      console.error('Error creating plan:', error);
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
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">الخطط</h1>
          <button
            onClick={() => setShowForm(true)}
            className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
          >
            إنشاء خطة جديدة
          </button>
        </div>

        {/* Create Plan Form */}
        {showForm && (
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 mb-8">
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">إنشاء خطة جديدة</h2>
            <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-[var(--text-primary)] mb-2">اسم الخطة</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">السعر (دينار)</label>
                <input
                  type="number"
                  value={formData.price_iqd}
                  onChange={(e) => setFormData({...formData, price_iqd: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">المدة (أيام)</label>
                <input
                  type="number"
                  value={formData.duration_days}
                  onChange={(e) => setFormData({...formData, duration_days: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">الحد الأقصى للعملاء</label>
                <input
                  type="number"
                  value={formData.max_customers}
                  onChange={(e) => setFormData({...formData, max_customers: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">الحد الأقصى للموظفين</label>
                <input
                  type="number"
                  value={formData.max_employees}
                  onChange={(e) => setFormData({...formData, max_employees: parseInt(e.target.value)})}
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

        {/* Plans Table */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">اسم الخطة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">السعر</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">المدة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">العملاء</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الموظفين</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody>
                {plans.map((plan: any) => (
                  <tr key={plan.id} className="border-b border-[var(--border-color)] hover:bg-[var(--bg-primary)]">
                    <td className="py-3 px-4 text-[var(--text-primary)]">{plan.name}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{plan.price_iqd?.toLocaleString()} IQD</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{plan.duration_days} يوم</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{plan.max_customers}</td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">{plan.max_employees}</td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-1 rounded-full text-sm ${
                        plan.status === 'active' ? 'bg-success/10 text-success' :
                        'bg-danger/10 text-danger'
                      }`}>
                        {plan.status === 'active' ? 'نشط' : 'غير نشط'}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <button className="text-electric hover:underline text-sm">
                        تعديل
                      </button>
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
