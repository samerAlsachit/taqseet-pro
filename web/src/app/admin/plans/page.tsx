'use client';

import { useEffect, useState } from 'react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

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
          features: formData.features.split(',').map(f => f.trim())
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
      if (data.success) {
        fetchPlans();
      } else {
        alert(data.error || 'فشل في حذف الخطة');
      }
    } catch (error) {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  return (
    <div className="min-h-screen bg-gray-bg">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold text-navy">إدارة خطط الاشتراك</h1>
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
              className="bg-electric text-white px-4 py-2 rounded-lg"
            >
              + إضافة خطة جديدة
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        {loading ? (
          <LoadingSpinner />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {plans.map((plan) => (
              <div key={plan.id} className="bg-white rounded-xl shadow-sm p-6">
                <div className="flex justify-between items-start mb-4">
                  <h2 className="text-xl font-bold text-navy">{plan.name}</h2>
                  <span className={`px-2 py-1 rounded-full text-xs ${plan.is_active ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>
                    {plan.is_active ? 'نشط' : 'غير نشط'}
                  </span>
                </div>
                <p className="text-2xl font-bold text-electric mb-2">{plan.price_iqd.toLocaleString()} IQD</p>
                <p className="text-text-primary text-sm mb-4">{plan.duration_days} يوم</p>
                <div className="space-y-2 mb-4">
                  <p className="text-sm">👥 عملاء: حتى {plan.max_customers}</p>
                  <p className="text-sm">👨‍💼 موظفين: حتى {plan.max_employees}</p>
                  <p className="text-sm">✨ المميزات: {plan.features?.join(', ') || '-'}</p>
                </div>
                <div className="flex gap-2">
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
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h2 className="text-xl font-bold text-navy mb-4">
              {editingPlan ? 'تعديل الخطة' : 'إضافة خطة جديدة'}
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-text-primary mb-2">اسم الخطة</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  required
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">المدة (أيام)</label>
                <input
                  type="number"
                  value={formData.duration_days}
                  onChange={(e) => setFormData({...formData, duration_days: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">السعر (دينار)</label>
                <input
                  type="number"
                  value={formData.price_iqd}
                  onChange={(e) => setFormData({...formData, price_iqd: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">حد العملاء</label>
                <input
                  type="number"
                  value={formData.max_customers}
                  onChange={(e) => setFormData({...formData, max_customers: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">حد الموظفين</label>
                <input
                  type="number"
                  value={formData.max_employees}
                  onChange={(e) => setFormData({...formData, max_employees: parseInt(e.target.value)})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">المميزات (افصل بينها بفاصلة)</label>
                <textarea
                  value={formData.features}
                  onChange={(e) => setFormData({...formData, features: e.target.value})}
                  rows={3}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="دعم فني, تحديثات مجانية, ..."
                />
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={formData.is_active}
                  onChange={(e) => setFormData({...formData, is_active: e.target.checked})}
                  id="is_active"
                />
                <label htmlFor="is_active">نشط</label>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={handleSave}
                className="flex-1 bg-electric text-white py-2 rounded-lg"
              >
                حفظ
              </button>
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 border border-gray-300 text-text-primary py-2 rounded-lg"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
