'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';

interface Plan {
  id: string;
  name: string;
  duration_days: number;
  price_iqd: number;
  max_customers: number;
  max_employees: number;
  features: string[];
  is_active: boolean;
}

export default function PlansPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingPlan, setEditingPlan] = useState<Plan | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    duration_days: 30,
    price_iqd: 0,
    max_customers: 100,
    max_employees: 2,
    features: '',
    is_active: true
  });

  const fetchPlans = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/plans`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) setPlans(data.data);
    } catch (error) {
      console.error('خطأ في جلب الخطط', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPlans();
  }, []);

  const handleSave = async () => {
    const token = localStorage.getItem('token');
    const url = editingPlan 
      ? `${process.env.NEXT_PUBLIC_API_URL}/admin/plans/${editingPlan.id}` 
      : `${process.env.NEXT_PUBLIC_API_URL}/admin/plans`;
    const method = editingPlan ? 'PUT' : 'POST';

    try {
      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({
          ...formData,
          features: formData.features.split(',').map(f => f.trim()).filter(f => f)
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowModal(false);
        setEditingPlan(null);
        fetchPlans();
      } else {
        alert(data.error || 'فشل في حفظ الخطة');
      }
    } catch (error) {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذه الخطة؟')) return;
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/plans/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) fetchPlans();
      else alert(data.error || 'فشل في حذف الخطة');
    } catch (error) {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-[var(--border-color)] border-electric"></div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-[var(--navy-color)]">خطط الاشتراك</h1>
          <button
            onClick={() => {
              setEditingPlan(null);
              setFormData({
                name: '',
                duration_days: 30,
                price_iqd: 0,
                max_customers: 100,
                max_employees: 2,
                features: '',
                is_active: true
              });
              setShowModal(true);
            }}
            className="bg-electric text-white px-4 py-2 rounded-lg hover:bg-blue-600"
          >
            + إضافة خطة جديدة
          </button>
        </div>

        {plans.length === 0 ? (
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-12 text-center">
            <p className="text-[var(--text-primary)]">لا توجد خطط اشتراك</p>
            <button
              onClick={() => setShowModal(true)}
              className="mt-4 bg-electric text-white px-4 py-2 rounded-lg"
            >
              إضافة الخطة الأولى
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {plans.map((plan) => (
              <div key={plan.id} className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border relative">
                {plan.name === 'سنوي' && (
                  <span className="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-electric text-white px-3 py-1 rounded-full text-sm">
                    الأكثر طلباً
                  </span>
                )}
                <div className="flex justify-between items-start">
                  <h2 className="text-xl font-bold text-[var(--navy-color)]">{plan.name}</h2>
                  <span className={`px-2 py-1 rounded-full text-xs ${plan.is_active ? 'bg-green-100 text-green-600' : 'bg-[var(--bg-primary)] text-gray-500'}`}>
                    {plan.is_active ? 'نشط' : 'غير نشط'}
                  </span>
                </div>
                <p className="text-2xl font-bold text-electric mt-2">{plan.price_iqd.toLocaleString()} IQD</p>
                <p className="text-[var(--text-primary)] text-sm">{plan.duration_days} يوم</p>
                <div className="mt-4 pt-4 border-t space-y-1">
                  <p className="text-sm">👥 عملاء: حتى {plan.max_customers}</p>
                  <p className="text-sm">👨‍💼 موظفين: حتى {plan.max_employees}</p>
                  {plan.features?.length > 0 && (
                    <p className="text-sm">✨ {plan.features.join(' • ')}</p>
                  )}
                </div>
                <div className="flex gap-2 mt-4">
                  <button
                    onClick={() => {
                      setEditingPlan(plan);
                      setFormData({
                        name: plan.name,
                        duration_days: plan.duration_days,
                        price_iqd: plan.price_iqd,
                        max_customers: plan.max_customers,
                        max_employees: plan.max_employees,
                        features: plan.features?.join(', ') || '',
                        is_active: plan.is_active
                      });
                      setShowModal(true);
                    }}
                    className="flex-1 text-electric border border-electric py-1 rounded-lg hover:bg-electric hover:text-white transition"
                  >
                    تعديل
                  </button>
                  <button
                    onClick={() => handleDelete(plan.id)}
                    className="flex-1 text-danger border border-danger py-1 rounded-lg hover:bg-danger hover:text-white transition"
                  >
                    حذف
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Modal إضافة/تعديل */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[var(--card-bg)] rounded-xl p-6 w-full max-w-md max-h-[90vh] overflow-y-auto border border-[var(--border-color)]">
            <h2 className="text-xl font-bold text-[var(--navy-color)] mb-4">
              {editingPlan ? 'تعديل الخطة' : 'إضافة خطة جديدة'}
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-[var(--text-primary)] mb-2">اسم الخطة *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
                  required
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">المدة (أيام)</label>
                <input
                  type="number"
                  value={formData.duration_days}
                  onChange={(e) => setFormData({...formData, duration_days: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg bg-[var(--card-bg)] text-[var(--text-primary)]"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">السعر (دينار)</label>
                <input
                  type="number"
                  value={formData.price_iqd}
                  onChange={(e) => setFormData({...formData, price_iqd: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg bg-[var(--card-bg)] text-[var(--text-primary)]"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">حد العملاء</label>
                <input
                  type="number"
                  value={formData.max_customers}
                  onChange={(e) => setFormData({...formData, max_customers: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg bg-[var(--card-bg)] text-[var(--text-primary)]"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">حد الموظفين</label>
                <input
                  type="number"
                  value={formData.max_employees}
                  onChange={(e) => setFormData({...formData, max_employees: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg bg-[var(--card-bg)] text-[var(--text-primary)]"
                />
              </div>
              <div>
                <label className="block text-[var(--text-primary)] mb-2">المميزات (افصل بينها بفاصلة)</label>
                <textarea
                  value={formData.features}
                  onChange={(e) => setFormData({...formData, features: e.target.value})}
                  rows={3}
                  className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg bg-[var(--card-bg)] text-[var(--text-primary)]"
                  placeholder="دعم فني, تحديثات مجانية, ..."
                />
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_active"
                  checked={formData.is_active}
                  onChange={(e) => setFormData({...formData, is_active: e.target.checked})}
                  className="w-4 h-4 text-electric border-gray-300 rounded focus:ring-electric"
                />
                <label htmlFor="is_active" className="text-[var(--text-primary)]">نشط</label>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={handleSave}
                className="flex-1 bg-electric text-white py-2 rounded-lg hover:bg-blue-600"
              >
                حفظ
              </button>
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 border border-[var(--border-color)] text-[var(--text-primary)] py-2 rounded-lg hover:bg-[var(--hover-color)]"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
