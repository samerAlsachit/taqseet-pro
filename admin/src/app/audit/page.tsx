'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { FileText, Search, Filter, Eye, PlusCircle, Edit, Trash2 } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

interface AuditLog {
  id: string;
  user_name: string;
  store_name: string;
  action: string;
  table_name: string;
  record_id: string;
  created_at: string;
  ip_address: string;
}

export default function AuditPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [filter, setFilter] = useState('');
  const [showDetails, setShowDetails] = useState(false);
  const [selectedLog, setSelectedLog] = useState<any>(null);
  const [details, setDetails] = useState<any>(null);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const limit = 50;

  const fetchLogs = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/audit?page=${page}&limit=${limit}&action=${filter}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await res.json();
      if (data.success) {
        setLogs(data.data.logs);
        setTotalPages(data.data.pagination.totalPages);
      }
    } catch (error) {
      console.error('خطأ في جلب السجلات', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [page, filter]);

  const getActionBadge = (action: string) => {
    switch (action) {
      case 'INSERT': return (
        <span className="bg-success/10 text-success px-2 py-1 rounded-full text-xs flex items-center gap-1">
          <PlusCircle size={14} className="inline ml-1" />
          إضافة
        </span>
      );
      case 'UPDATE': return (
        <span className="bg-warning/10 text-warning px-2 py-1 rounded-full text-xs flex items-center gap-1">
          <Edit size={14} className="inline ml-1" />
          تعديل
        </span>
      );
      case 'DELETE': return (
        <span className="bg-danger/10 text-danger px-2 py-1 rounded-full text-xs flex items-center gap-1">
          <Trash2 size={14} className="inline ml-1" />
          حذف
        </span>
      );
      default: return <span className="bg-[var(--bg-primary)] px-2 py-1 rounded-full text-xs">{action}</span>;
    }
  };

  const fetchDetails = async (logId: string) => {
    const token = localStorage.getItem('token');
    setLoadingDetails(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/audit/${logId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        setDetails(data.data);
        setShowDetails(true);
      } else {
        alert(data.error || 'فشل في جلب التفاصيل');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
    } finally {
      setLoadingDetails(false);
    }
  };

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center gap-2 mb-6">
          <FileText className="text-electric" size={28} />
          <h1 className="text-2xl font-bold text-navy dark:text-white">سجل العمليات</h1>
        </div>

        {/* فلتر */}
        <div className="flex gap-4 mb-6">
          <select
            value={filter}
            onChange={(e) => { setFilter(e.target.value); setPage(1); }}
            className="px-4 py-2 border rounded-lg"
          >
            <option value="">جميع العمليات</option>
            <option value="INSERT">إضافة</option>
            <option value="UPDATE">تعديل</option>
            <option value="DELETE">حذف</option>
          </select>
        </div>

        {loading ? (
          <LoadingSpinner />
        ) : logs.length === 0 ? (
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-12 text-center">
            <p className="text-[var(--text-primary)]">لا توجد سجلات</p>
          </div>
        ) : (
          <>
            <div className="bg-[var(--card-bg)] rounded-xl shadow-sm overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-[var(--border-color)] bg-[var(--bg-primary)]">
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]">التاريخ</th>
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]">المستخدم</th>
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]">المحل</th>
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]">العملية</th>
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]">الجدول</th>
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]">IP</th>
                      <th className="text-right py-3 px-4 text-[var(--text-primary)]"></th>
                      </tr>
                  </thead>
                  <tbody>
                    {logs.map((log) => (
                      <tr key={log.id} className="border-b border-[var(--border-color)] hover:bg-[var(--bg-primary)]">
                        <td className="py-3 px-4 text-[var(--text-primary)]">
                          {new Date(log.created_at).toLocaleString('ar-IQ')}
                        </td>
                        <td className="py-3 px-4 text-[var(--text-primary)]">{log.user_name || '-'}</td>
                        <td className="py-3 px-4 text-[var(--text-primary)]">{log.store_name || '-'}</td>
                        <td className="py-3 px-4 text-[var(--text-primary)]">{getActionBadge(log.action)}</td>
                        <td className="py-3 px-4 text-[var(--text-primary)]">{log.table_name}</td>
                        <td className="py-3 px-4 text-[var(--text-primary)] text-sm font-mono">{log.ip_address || '-'}</td>
                        <td className="py-3 px-4">
                          <button
                            onClick={() => fetchDetails(log.id)}
                            className="text-electric hover:underline text-sm flex items-center gap-1"
                          >
                            <Eye size={14} />
                            <span>تفاصيل</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex justify-center gap-2 mt-6">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-4 py-2 rounded-lg border disabled:opacity-50"
                >
                  السابق
                </button>
                <span className="px-4 py-2">صفحة {page} من {totalPages}</span>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-4 py-2 rounded-lg border disabled:opacity-50"
                >
                  التالي
                </button>
              </div>
            )}
          </>
        )}
      </div>

      {/* Modal تفاصيل السجل */}
      {showDetails && details && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[var(--card-bg)] rounded-xl p-6 w-full max-w-2xl max-h-[80vh] overflow-auto border border-[var(--border-color)]">
            <h2 className="text-xl font-bold text-[var(--navy-color)] mb-4">تفاصيل العملية</h2>
            
            <div className="space-y-4">
              {/* معلومات أساسية */}
              <div className="grid grid-cols-2 gap-4 p-3 bg-[var(--bg-primary)] rounded-lg">
                <div>
                  <p className="text-[var(--text-primary)] text-sm">العملية</p>
                  <p className="font-medium">
                    {details.action === 'INSERT' ? '➕ إضافة' : 
                     details.action === 'UPDATE' ? '✏️ تعديل' : 
                     '🗑️ حذف'}
                  </p>
                </div>
                <div>
                  <p className="text-[var(--text-primary)] text-sm">الجدول</p>
                  <p className="font-medium">
                    {details.table_name === 'customers' ? 'العملاء' :
                     details.table_name === 'products' ? 'المنتجات' :
                     details.table_name === 'installment_plans' ? 'الأقساط' :
                     details.table_name === 'payments' ? 'الدفعات' :
                     details.table_name === 'users' ? 'المستخدمين' :
                     details.table_name}
                  </p>
                </div>
                <div>
                  <p className="text-[var(--text-primary)] text-sm">المستخدم</p>
                  <p className="font-medium">{details.user_name}</p>
                </div>
                <div>
                  <p className="text-[var(--text-primary)] text-sm">المحل</p>
                  <p className="font-medium">{details.store_name}</p>
                </div>
                <div>
                  <p className="text-[var(--text-primary)] text-sm">التاريخ</p>
                  <p className="font-medium">{new Date(details.created_at).toLocaleString('ar-IQ')}</p>
                </div>
                <div>
                  <p className="text-[var(--text-primary)] text-sm">IP</p>
                  <p className="font-mono text-sm">{details.ip_address || 'غير متوفر'}</p>
                </div>
              </div>
              
              {/* البيانات القديمة */}
              {details.old_data && Object.keys(details.old_data).length > 0 && (
                <div>
                  <p className="font-bold text-[var(--navy-color)] mb-2 flex items-center gap-2">
                    <span>📄</span> البيانات القديمة
                  </p>
                  <div className="bg-[var(--bg-primary)] p-3 rounded-lg overflow-auto max-h-60">
                    <pre className="text-xs whitespace-pre-wrap">
                      {JSON.stringify(details.old_data, null, 2)}
                    </pre>
                  </div>
                </div>
              )}
              
              {/* البيانات الجديدة */}
              {details.new_data && Object.keys(details.new_data).length > 0 && (
                <div>
                  <p className="font-bold text-[var(--navy-color)] mb-2 flex items-center gap-2">
                    <span>🆕</span> البيانات الجديدة
                  </p>
                  <div className="bg-[var(--bg-primary)] p-3 rounded-lg overflow-auto max-h-60">
                    <pre className="text-xs whitespace-pre-wrap">
                      {JSON.stringify(details.new_data, null, 2)}
                    </pre>
                  </div>
                </div>
              )}
              
              {/* رسالة إذا كانت العملية إضافة أو حذف */}
              {details.action === 'INSERT' && !details.old_data && (
                <div className="bg-green-50 p-3 rounded-lg text-center">
                  <p className="text-success">✨ تمت إضافة سجل جديد</p>
                </div>
              )}
              
              {details.action === 'DELETE' && !details.new_data && (
                <div className="bg-red-50 p-3 rounded-lg text-center">
                  <p className="text-danger">⚠️ تم حذف هذا السجل</p>
                </div>
              )}
            </div>
            
            <div className="flex justify-end mt-6">
              <button
                onClick={() => setShowDetails(false)}
                className="bg-gray-200 hover:bg-gray-300 text-[var(--text-primary)] px-4 py-2 rounded-lg transition"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
