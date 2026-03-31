'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { Download, Trash2, RotateCcw, Database, HardDrive } from 'lucide-react';
import toast from 'react-hot-toast';

interface BackupFile {
  name: string;
  size: number;
  created_at: string;
  path: string;
}

export default function BackupPage() {
  const [backups, setBackups] = useState<BackupFile[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  const fetchBackups = async () => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/backups`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        setBackups(data.data);
      }
    } catch (error) {
      console.error('خطأ في جلب النسخ الاحتياطية', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBackups();
  }, []);

  const createBackup = async () => {
    setCreating(true);
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/backups`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم إنشاء النسخة الاحتياطية بنجاح');
        fetchBackups();
      } else {
        toast.error(data.error || 'فشل في إنشاء النسخة');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    } finally {
      setCreating(false);
    }
  };

  const downloadBackup = async (filename: string) => {
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/backups/${filename}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch {
      toast.error('فشل في تحميل النسخة');
    }
  };

  const deleteBackup = async (filename: string) => {
    if (!confirm('هل أنت متأكد من حذف هذه النسخة؟')) return;
    
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/backups/${filename}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم حذف النسخة بنجاح');
        fetchBackups();
      } else {
        toast.error(data.error || 'فشل في حذف النسخة');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    }
  };

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
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
            <Database className="text-electric" size={28} />
            <h1 className="text-2xl font-bold text-navy dark:text-white">النسخ الاحتياطي</h1>
          </div>
          <button
            onClick={createBackup}
            disabled={creating}
            className="flex items-center gap-2 bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition disabled:opacity-50"
          >
            <HardDrive size={18} />
            <span>{creating ? 'جاري الإنشاء...' : 'إنشاء نسخة احتياطية'}</span>
          </button>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
          {backups.length === 0 ? (
            <div className="text-center py-12">
              <Database className="mx-auto text-gray-400 mb-4" size={48} />
              <p className="text-gray-500 dark:text-gray-400">لا توجد نسخ احتياطية</p>
              <button
                onClick={createBackup}
                className="mt-4 text-electric hover:underline"
              >
                إنشاء أول نسخة
              </button>
            </div>
          ) : (
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                  <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">اسم الملف</th>
                  <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">الحجم</th>
                  <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400">تاريخ الإنشاء</th>
                  <th className="text-right py-3 px-4 text-gray-600 dark:text-gray-400"></th>
                </tr>
              </thead>
              <tbody>
                {backups.map((backup) => (
                  <tr key={backup.name} className="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                    <td className="py-3 px-4 text-gray-900 dark:text-white font-mono text-sm">
                      {backup.name}
                    </td>
                    <td className="py-3 px-4 text-gray-500 dark:text-gray-400">
                      {formatSize(backup.size)}
                    </td>
                    <td className="py-3 px-4 text-gray-500 dark:text-gray-400">
                      {new Date(backup.created_at).toLocaleString('ar-IQ')}
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex gap-2">
                        <button
                          onClick={() => downloadBackup(backup.name)}
                          className="text-electric hover:text-blue-700 transition p-1"
                          title="تحميل"
                        >
                          <Download size={18} />
                        </button>
                        <button
                          onClick={() => deleteBackup(backup.name)}
                          className="text-danger hover:text-red-700 transition p-1"
                          title="حذف"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div className="mt-6 p-4 bg-yellow-50 dark:bg-yellow-900/30 rounded-lg">
          <p className="text-yellow-700 dark:text-yellow-400 text-sm">
            ⚠️ ملاحظة: النسخ الاحتياطي التلقائي يتم يومياً في الساعة 2 صباحاً. يتم الاحتفاظ بآخر 30 نسخة فقط.
          </p>
        </div>
      </div>
    </AdminLayout>
  );
}
