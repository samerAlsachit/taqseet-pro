'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';

interface ActivationCode {
  id: string;
  code: string;
  plan_id: string;
  plan_name?: string;
  duration_days: number;
  is_used: boolean;
  used_at: string | null;
  store_id: string | null;
  store_name?: string;
  notes: string | null;
  created_at: string;
}

interface Plan {
  id: string;
  name: string;
  duration_days: number;
  price_iqd: number;
}

export default function ActivationCodesPage() {
  const [codes, setCodes] = useState<ActivationCode[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState('');
  const [quantity, setQuantity] = useState(1);
  const [notes, setNotes] = useState('');
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [filter, setFilter] = useState<'all' | 'used' | 'unused'>('all');

  const limit = 20;

  const fetchCodes = async () => {
    const token = localStorage.getItem('token');
    setLoading(true);
    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/activation-codes?page=${page}&limit=${limit}&status=${filter}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await response.json();
      if (data.success) {
        setCodes(data.data.codes);
        setTotalPages(data.data.pagination.totalPages);
      }
    } catch (err) {
      setError('حدث خطأ في جلب البيانات');
    } finally {
      setLoading(false);
    }
  };

  const fetchPlans = async () => {
    const token = localStorage.getItem('token');
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/subscription-plans`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await response.json();
      if (data.success) {
        setPlans(data.data);
        if (data.data.length > 0) setSelectedPlan(data.data[0].id);
      }
    } catch (err) {
      console.error('خطأ في جلب الخطط:', err);
    }
  };

  const generateCodes = async () => {
    const token = localStorage.getItem('token');
    setGenerating(true);
    setError('');
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/activation-codes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({
          plan_id: selectedPlan,
          quantity,
          notes
        })
      });
      const data = await response.json();
      if (data.success) {
        setShowModal(false);
        setQuantity(1);
        setNotes('');
        fetchCodes();
      } else {
        setError(data.error || 'فشل في إنشاء الكودات');
      }
    } catch (err) {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setGenerating(false);
    }
  };

  const copyToClipboard = (code: string) => {
    navigator.clipboard.writeText(code);
    alert(`تم نسخ الكود: ${code}`);
  };

  useEffect(() => {
    fetchCodes();
  }, [page, filter]);

  useEffect(() => {
    fetchPlans();
  }, []);

  const getStatusBadge = (isUsed: boolean) => {
    if (isUsed) {
      return <span className="px-3 py-1 rounded-full text-sm bg-success/10 text-success">مستخدم</span>;
    }
    return <span className="px-3 py-1 rounded-full text-sm bg-warning/10 text-warning">غير مستخدم</span>;
  };

  const formatDate = (date: string | null) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('ar-IQ');
  };

  return (
    <AdminLayout>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-navy">مرساة - كودات التفعيل</h1>
        <button
          onClick={() => setShowModal(true)}
          className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
        >
          + إنشاء كود جديد
        </button>
      </div>

      {/* فلتر */}
      <div className="bg-white rounded-xl shadow-sm p-4 mb-6">
        <div className="flex gap-4">
          <button
            onClick={() => { setFilter('all'); setPage(1); }}
            className={`px-4 py-2 rounded-lg transition ${filter === 'all' ? 'bg-electric text-white' : 'bg-gray-100 text-text-primary hover:bg-gray-200'}`}
          >
            الكل
          </button>
          <button
            onClick={() => { setFilter('unused'); setPage(1); }}
            className={`px-4 py-2 rounded-lg transition ${filter === 'unused' ? 'bg-electric text-white' : 'bg-gray-100 text-text-primary hover:bg-gray-200'}`}
          >
            غير مستخدم
          </button>
          <button
            onClick={() => { setFilter('used'); setPage(1); }}
            className={`px-4 py-2 rounded-lg transition ${filter === 'used' ? 'bg-electric text-white' : 'bg-gray-100 text-text-primary hover:bg-gray-200'}`}
          >
            مستخدم
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 text-danger border border-danger/20 rounded-lg p-3 mb-4">
          {error}
        </div>
      )}

      {/* جدول الكودات */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
        </div>
      ) : codes.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm p-12 text-center">
          <p className="text-text-primary">لا توجد كودات تفعيل</p>
          <button
            onClick={() => setShowModal(true)}
            className="mt-4 bg-electric text-white px-4 py-2 rounded-lg"
          >
            إنشاء أول كود
          </button>
        </div>
      ) : (
        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الكود</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الخطة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">المدة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">الحالة</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">تاريخ الاستخدام</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">المحل المستخدم</th>
                  <th className="text-right py-3 px-4 text-text-primary font-semibold">نسخ</th>
                </tr>
              </thead>
              <tbody>
                {codes.map((code) => (
                  <tr key={code.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="py-3 px-4 font-mono text-sm">{code.code}</td>
                    <td className="py-3 px-4">{code.plan_name || '-'}</td>
                    <td className="py-3 px-4">{code.duration_days} يوم</td>
                    <td className="py-3 px-4">{getStatusBadge(code.is_used)}</td>
                    <td className="py-3 px-4">{formatDate(code.used_at)}</td>
                    <td className="py-3 px-4">{code.store_name || '-'}</td>
                    <td className="py-3 px-4">
                      <button
                        onClick={() => copyToClipboard(code.code)}
                        className="text-electric hover:text-blue-600"
                      >
                        📋 نسخ
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-center gap-2 py-4 border-t">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1 rounded border disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-3 py-1">
                صفحة {page} من {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-3 py-1 rounded border disabled:opacity-50"
              >
                التالي
              </button>
            </div>
          )}
        </div>
      )}

      {/* Modal إنشاء كود */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-xl font-bold text-navy mb-4">إنشاء كود تفعيل جديد</h2>
            
            <div className="mb-4">
              <label className="block text-text-primary mb-2">الخطة</label>
              <select
                value={selectedPlan}
                onChange={(e) => setSelectedPlan(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              >
                {plans.map((plan) => (
                  <option key={plan.id} value={plan.id}>
                    {plan.name} - {plan.price_iqd} دينار
                  </option>
                ))}
              </select>
            </div>

            <div className="mb-4">
              <label className="block text-text-primary mb-2">عدد الكودات</label>
              <input
                type="number"
                min="1"
                max="100"
                value={quantity}
                onChange={(e) => setQuantity(parseInt(e.target.value) || 1)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
              />
            </div>

            <div className="mb-6">
              <label className="block text-text-primary mb-2">ملاحظات (اختياري)</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={3}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
                placeholder="رقم الإيصال، اسم المشتري..."
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={generateCodes}
                disabled={generating}
                className="flex-1 bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition disabled:opacity-50"
              >
                {generating ? 'جاري الإنشاء...' : 'إنشاء'}
              </button>
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 bg-gray-200 hover:bg-gray-300 text-text-primary py-2 rounded-lg transition"
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
