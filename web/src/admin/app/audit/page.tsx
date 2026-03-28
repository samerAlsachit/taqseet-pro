'use client';

import { useState, useEffect } from 'react';
import { useTheme } from '../../context/ThemeContext';

export default function AdminAudit() {
  const { theme } = useTheme();
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    action: 'all',
    user_id: '',
    date_from: '',
    date_to: ''
  });

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        const queryParams = new URLSearchParams(
          Object.entries(filters).filter(([_, value]) => value !== '').map(([key, value]) => [key, value])
        );
        
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/audit?${queryParams}`);
        const data = await res.json();
        if (data.success) setLogs(data.data);
      } catch (error) {
        console.error('Error fetching logs:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchLogs();
  }, [filters]);

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
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">سجل النشاط</h1>
        </div>

        {/* Filters */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 mb-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-[var(--text-primary)] mb-2">الإجراء</label>
              <select
                value={filters.action}
                onChange={(e) => setFilters({...filters, action: e.target.value})}
                className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
              >
                <option value="all">جميع الإجراءات</option>
                <option value="login">تسجيل دخول</option>
                <option value="create">إنشاء</option>
                <option value="update">تحديث</option>
                <option value="delete">حذف</option>
              </select>
            </div>
            <div>
              <label className="block text-[var(--text-primary)] mb-2">المستخدم</label>
              <input
                type="text"
                value={filters.user_id}
                onChange={(e) => setFilters({...filters, user_id: e.target.value})}
                placeholder="ID المستخدم"
                className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
              />
            </div>
            <div>
              <label className="block text-[var(--text-primary)] mb-2">من تاريخ</label>
              <input
                type="date"
                value={filters.date_from}
                onChange={(e) => setFilters({...filters, date_from: e.target.value})}
                className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
              />
            </div>
            <div>
              <label className="block text-[var(--text-primary)] mb-2">إلى تاريخ</label>
              <input
                type="date"
                value={filters.date_to}
                onChange={(e) => setFilters({...filters, date_to: e.target.value})}
                className="w-full px-4 py-2 border border-[var(--border-color)] rounded-lg focus:outline-none focus:ring-2 focus:ring-electric bg-[var(--card-bg)] text-[var(--text-primary)]"
              />
            </div>
          </div>
        </div>

        {/* Audit Logs Table */}
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">التاريخ والوقت</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">المستخدم</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">الإجراء</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">التفاصيل</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">عنوان IP</th>
                  <th className="text-right py-3 px-4 text-[var(--text-primary)] font-semibold">النتيجة</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log: any) => (
                  <tr key={log.id} className="border-b border-[var(--border-color)] hover:bg-[var(--bg-primary)]">
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      <div className="text-sm">
                        <div>{new Date(log.created_at).toLocaleDateString('ar-IQ')}</div>
                        <div className="text-[var(--text-primary)]/70">{new Date(log.created_at).toLocaleTimeString('ar-IQ')}</div>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      <div className="text-sm">
                        <div>{log.user_name}</div>
                        <div className="text-[var(--text-primary)]/70">{log.user_email}</div>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-[var(--text-primary)]">
                      <span className={`px-2 py-1 rounded-full text-sm ${
                        log.action === 'login' ? 'bg-blue-100 text-blue-800' :
                        log.action === 'create' ? 'bg-green-100 text-green-800' :
                        log.action === 'update' ? 'bg-yellow-100 text-yellow-800' :
                        log.action === 'delete' ? 'bg-red-100 text-red-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {log.action === 'login' ? 'تسجيل دخول' :
                         log.action === 'create' ? 'إنشاء' :
                         log.action === 'update' ? 'تحديث' :
                         log.action === 'delete' ? 'حذف' : log.action}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-[var(--text-primary)] text-sm max-w-xs truncate">
                      {log.details}
                    </td>
                    <td className="py-3 px-4 text-[var(--text-primary)] font-mono text-sm">
                      {log.ip_address}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-1 rounded-full text-sm ${
                        log.status === 'success' ? 'bg-success/10 text-success' :
                        'bg-danger/10 text-danger'
                      }`}>
                        {log.status === 'success' ? 'نجح' : 'فشل'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {logs.length === 0 && (
          <div className="text-center py-8">
            <p className="text-[var(--text-primary)]/70">لا توجد سجلات مطابقة للفلاتر المحددة</p>
          </div>
        )}
      </div>
    </div>
  );
}
