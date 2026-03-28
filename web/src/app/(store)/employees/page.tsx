'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

interface Employee {
  id: string;
  username: string;
  full_name: string;
  phone: string;
  role: string;
  can_delete: boolean;
  can_edit: boolean;
  can_view_reports: boolean;
  is_active: boolean;
  created_at: string;
}

export default function EmployeesPage() {
  const router = useRouter();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null);
  const [editPermissions, setEditPermissions] = useState({
    can_edit: false,
    can_delete: false,
    can_view_reports: false
  });
  const [formData, setFormData] = useState({
    username: '',
    full_name: '',
    phone: '',
    password: '',
    role: 'store_employee',
    can_delete: false,
    can_edit: true,
    can_view_reports: false
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [limitInfo, setLimitInfo] = useState({ current: 0, max: 0 });

  const fetchEmployees = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/employees`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        setEmployees(data.data.employees);
        setLimitInfo({ current: data.data.current, max: data.data.max });
      }
    } catch (error) {
      console.error('خطأ في جلب الموظفين', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');

    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/employees`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      if (data.success) {
        setShowModal(false);
        setFormData({
          username: '',
          full_name: '',
          phone: '',
          password: '',
          role: 'store_employee',
          can_delete: false,
          can_edit: true,
          can_view_reports: false
        });
        fetchEmployees();
      } else {
        setError(data.error || 'فشل في إضافة الموظف');
      }
    } catch {
      setError('حدث خطأ في الاتصال بالخادم');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا الموظف؟')) return;

    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/employees/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        fetchEmployees();
      } else {
        alert(data.error || 'فشل في حذف الموظف');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  const updatePermissions = async (id: string, permissions: any) => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/employees/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(permissions)
      });
      const data = await res.json();
      if (data.success) {
        fetchEmployees();
      } else {
        alert(data.error || 'فشل في تحديث الصلاحيات');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
    }
  };

  const getRoleName = (role: string) => {
    switch (role) {
      case 'store_owner': return 'مالك';
      case 'store_manager': return 'مدير';
      default: return 'موظف';
    }
  };

  const openEditModal = (employee: Employee) => {
    setEditingEmployee(employee);
    setEditPermissions({
      can_edit: employee.can_edit,
      can_delete: employee.can_delete,
      can_view_reports: employee.can_view_reports
    });
    setEditModalOpen(true);
  };

  const savePermissions = async () => {
    if (!editingEmployee) return;
    
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/store/employees/${editingEmployee.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify(editPermissions)
      });
      const data = await res.json();
      if (data.success) {
        setEditModalOpen(false);
        fetchEmployees();
      } else {
        alert(data.error || 'فشل في تحديث الصلاحيات');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
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
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-navy">إدارة الموظفين</h1>
        <button
          onClick={() => setShowModal(true)}
          className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition"
        >
          + إضافة موظف جديد
        </button>
      </div>

      {/* معلومات الحد الأقصى */}
      <div className="bg-gray-bg rounded-lg p-4 mb-6">
        <p className="text-text-primary">
          عدد الموظفين الحالي: <span className="font-bold">{limitInfo.current}</span> من <span className="font-bold">{limitInfo.max}</span>
        </p>
        {limitInfo.current >= limitInfo.max && (
          <p className="text-danger text-sm mt-1">
            ⚠️ لقد وصلت إلى الحد الأقصى للموظفين حسب خطتك. يرجى الترقية لإضافة المزيد.
          </p>
        )}
      </div>

      {/* جدول الموظفين */}
      {employees.length === 0 ? (
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-12 text-center">
          <p className="text-text-primary">لا يوجد موظفين</p>
          <button
            onClick={() => setShowModal(true)}
            className="mt-4 bg-electric text-white px-4 py-2 rounded-lg"
          >
            إضافة أول موظف
          </button>
        </div>
      ) : (
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                  <th className="text-[var(--text-primary)]">الاسم</th>
                  <th className="text-[var(--text-primary)]">اسم المستخدم</th>
                  <th className="text-[var(--text-primary)]">الهاتف</th>
                  <th className="text-[var(--text-primary)]">الدور</th>
                  <th className="text-[var(--text-primary)]">الصلاحيات</th>
                  <th className="text-[var(--text-primary)]"></th>
                 </tr>
              </thead>
              <tbody>
                {employees.map((emp) => (
                  <tr key={emp.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="py-3 px-4">{emp.full_name}</td>
                    <td className="py-3 px-4">{emp.username}</td>
                    <td className="py-3 px-4">{emp.phone}</td>
                    <td className="py-3 px-4">{getRoleName(emp.role)}</td>
                    <td className="py-3 px-4">
                      <div className="flex gap-3">
                        <label className="flex items-center gap-1 text-sm">
                          <input
                            type="checkbox"
                            checked={emp.can_edit}
                            onChange={(e) => updatePermissions(emp.id, { can_edit: e.target.checked })}
                            className="w-4 h-4"
                          />
                          تعديل
                        </label>
                        <label className="flex items-center gap-1 text-sm">
                          <input
                            type="checkbox"
                            checked={emp.can_delete}
                            onChange={(e) => updatePermissions(emp.id, { can_delete: e.target.checked })}
                            className="w-4 h-4"
                          />
                          حذف
                        </label>
                        <label className="flex items-center gap-1 text-sm">
                          <input
                            type="checkbox"
                            checked={emp.can_view_reports}
                            onChange={(e) => updatePermissions(emp.id, { can_view_reports: e.target.checked })}
                            className="w-4 h-4"
                          />
                          تقارير
                        </label>
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      <button
                        onClick={() => openEditModal(emp)}
                        className="text-electric hover:underline ml-3"
                      >
                        تعديل
                      </button>
                      <button
                        onClick={() => handleDelete(emp.id)}
                        className="text-danger hover:underline"
                      >
                        حذف
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modal إضافة موظف */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[var(--card-bg)] rounded-xl p-6 w-full max-w-md">
            <h2 className="text-xl font-bold text-navy mb-4">إضافة موظف جديد</h2>
            {error && (
              <div className="bg-red-50 text-danger p-3 rounded-lg mb-4">{error}</div>
            )}
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-text-primary mb-2">الاسم الكامل *</label>
                <input
                  type="text"
                  required
                  value={formData.full_name}
                  onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">اسم المستخدم *</label>
                <input
                  type="text"
                  required
                  value={formData.username}
                  onChange={(e) => setFormData({...formData, username: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">رقم الهاتف</label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">كلمة المرور *</label>
                <input
                  type="password"
                  required
                  value={formData.password}
                  onChange={(e) => setFormData({...formData, password: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-text-primary mb-2">الدور</label>
                <select
                  value={formData.role}
                  onChange={(e) => setFormData({...formData, role: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                >
                  <option value="store_employee">موظف</option>
                  <option value="store_manager">مدير</option>
                </select>
              </div>
              <div className="border-t pt-4">
                <p className="font-medium mb-2">الصلاحيات</p>
                <div className="space-y-2">
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={formData.can_edit}
                      onChange={(e) => setFormData({...formData, can_edit: e.target.checked})}
                    />
                    إمكانية التعديل
                  </label>
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={formData.can_delete}
                      onChange={(e) => setFormData({...formData, can_delete: e.target.checked})}
                    />
                    إمكانية الحذف
                  </label>
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={formData.can_view_reports}
                      onChange={(e) => setFormData({...formData, can_view_reports: e.target.checked})}
                    />
                    مشاهدة التقارير
                  </label>
                </div>
              </div>
              <div className="flex gap-3 pt-4">
                <button
                  type="submit"
                  disabled={submitting}
                  className="flex-1 bg-electric text-white py-2 rounded-lg disabled:opacity-50"
                >
                  {submitting ? 'جاري الإضافة...' : 'إضافة الموظف'}
                </button>
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 border border-gray-300 text-text-primary py-2 rounded-lg"
                >
                  إلغاء
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal تعديل الصلاحيات */}
      {editModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[var(--card-bg)] rounded-xl p-6 w-full max-w-md">
            <h2 className="text-xl font-bold text-navy mb-4">تعديل صلاحيات الموظف</h2>
            <div className="mb-4">
              <p className="text-text-primary">
                الموظف: <span className="font-bold">{editingEmployee?.full_name}</span>
              </p>
            </div>
            <div className="space-y-3">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={editPermissions.can_edit}
                  onChange={(e) => setEditPermissions({...editPermissions, can_edit: e.target.checked})}
                />
                إمكانية التعديل
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={editPermissions.can_delete}
                  onChange={(e) => setEditPermissions({...editPermissions, can_delete: e.target.checked})}
                />
                إمكانية الحذف
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={editPermissions.can_view_reports}
                  onChange={(e) => setEditPermissions({...editPermissions, can_view_reports: e.target.checked})}
                />
                مشاهدة التقارير
              </label>
            </div>
            <div className="flex gap-3 pt-4">
              <button
                onClick={savePermissions}
                className="flex-1 bg-electric text-white py-2 rounded-lg hover:bg-blue-600 transition"
              >
                حفظ التغييرات
              </button>
              <button
                onClick={() => setEditModalOpen(false)}
                className="flex-1 border border-gray-300 text-text-primary py-2 rounded-lg hover:bg-gray-50 transition"
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
