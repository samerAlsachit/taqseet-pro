'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { Bell, Edit, Save, RotateCcw } from 'lucide-react';
import toast from 'react-hot-toast';

interface Template {
  id: string;
  type: string;
  name: string;
  body: string;
  is_active: boolean;
}

export default function NotificationsPage() {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editBody, setEditBody] = useState('');

  const fetchTemplates = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/notification-templates`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) setTemplates(data.data);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTemplates();
  }, []);

  const handleSave = async (id: string, body: string) => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/notification-templates/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({ body })
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم حفظ القالب');
        setEditingId(null);
        fetchTemplates();
      } else {
        toast.error(data.error);
      }
    } catch {
      toast.error('حدث خطأ');
    }
  };

  const handleReset = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/notification-templates/reset`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        }
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم إعادة تعيين القوالب');
        fetchTemplates();
      } else {
        toast.error(data.error);
      }
    } catch {
      toast.error('حدث خطأ');
    }
  };

  const getTypeName = (type: string) => {
    const types: Record<string, string> = {
      reminder: 'تذكير قبل القسط',
      due: 'قسط مستحق اليوم',
      overdue: 'قسط متأخر',
      expiry: 'انتهاء اشتراك',
      payment_receipt: 'وصل دفع'
    };
    return types[type] || type;
  };

  if (loading) return <AdminLayout><div>جاري التحميل...</div></AdminLayout>;

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center gap-2 mb-6">
          <Bell className="text-electric" size={28} />
          <h1 className="text-2xl font-bold text-navy dark:text-white">إدارة الإشعارات</h1>
          <button
            onClick={handleReset}
            className="flex items-center gap-2 px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 rounded-lg transition-colors"
          >
            <RotateCcw size={18} />
            <span>إعادة تعيين القوالب</span>
          </button>
        </div>

        <div className="grid grid-cols-1 gap-6">
          {templates.map((template) => (
            <div key={template.id} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h2 className="text-xl font-bold text-navy dark:text-white">{template.name}</h2>
                  <p className="text-sm text-gray-500 dark:text-gray-400">{getTypeName(template.type)}</p>
                </div>
                <div className="flex gap-2">
                  {editingId === template.id ? (
                    <button
                      onClick={() => handleSave(template.id, editBody)}
                      className="flex items-center gap-1 text-success hover:text-green-700"
                    >
                      <Save size={18} />
                      <span>حفظ</span>
                    </button>
                  ) : (
                    <button
                      onClick={() => {
                        setEditingId(template.id);
                        setEditBody(template.body);
                      }}
                      className="flex items-center gap-1 text-electric hover:text-blue-700"
                    >
                      <Edit size={18} />
                      <span>تعديل</span>
                    </button>
                  )}
                </div>
              </div>

              {editingId === template.id ? (
                <textarea
                  value={editBody}
                  onChange={(e) => setEditBody(e.target.value)}
                  rows={6}
                  className="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white font-mono text-sm"
                />
              ) : (
                <pre className="p-3 bg-gray-50 dark:bg-gray-900 rounded-lg text-sm whitespace-pre-wrap font-mono">
                  {template.body}
                </pre>
              )}

              <div className="mt-2 text-xs text-gray-400">
                المتغيرات المتاحة: {'{customer_name}'}, {'{amount}'}, {'{currency}'}, {'{due_date}'}, {'{store_name}'}, {'{days_left}'}
              </div>
            </div>
          ))}
        </div>
      </div>
    </AdminLayout>
  );
}
