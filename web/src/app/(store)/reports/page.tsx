'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface ReportData {
  daily: {
    total_collection: number;
    paid_count: number;
    new_installments: number;
  };
  monthly: {
    total_collection: number;
    paid_count: number;
    new_installments: number;
  };
  total: {
    total_collection: number;
    total_remaining: number;
    active_installments: number;
    total_customers: number;
  };
}

export default function ReportsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [reportType, setReportType] = useState<'daily' | 'monthly' | 'total'>('daily');
  const [data, setData] = useState<ReportData | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    const fetchReports = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/reports/summary`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const result = await res.json();
        if (result.success) {
          setData(result.data);
        }
      } catch (error) {
        console.error('خطأ في جلب التقارير', error);
      } finally {
        setLoading(false);
      }
    };

    fetchReports();
  }, [router]);

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  const currentData = reportType === 'daily' ? data?.daily : reportType === 'monthly' ? data?.monthly : data?.total;

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="text-2xl font-bold text-navy mb-6">التقارير</h1>

      {/* اختيار نوع التقرير */}
      <div className="flex gap-4 mb-8">
        <button
          onClick={() => setReportType('daily')}
          className={`px-6 py-2 rounded-lg transition ${
            reportType === 'daily'
              ? 'bg-electric text-white'
              : 'bg-white text-text-primary border border-gray-300 hover:bg-gray-50'
          }`}
        >
          يومي
        </button>
        <button
          onClick={() => setReportType('monthly')}
          className={`px-6 py-2 rounded-lg transition ${
            reportType === 'monthly'
              ? 'bg-electric text-white'
              : 'bg-white text-text-primary border border-gray-300 hover:bg-gray-50'
          }`}
        >
          شهري
        </button>
        <button
          onClick={() => setReportType('total')}
          className={`px-6 py-2 rounded-lg transition ${
            reportType === 'total'
              ? 'bg-electric text-white'
              : 'bg-white text-text-primary border border-gray-300 hover:bg-gray-50'
          }`}
        >
          إجمالي
        </button>
      </div>

      {/* بطاقات الإحصائيات */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-success">
          <p className="text-text-primary text-sm mb-1">إجمالي التحصيلات</p>
          <p className="text-2xl font-bold text-navy">
            {currentData?.total_collection?.toLocaleString() || 0} IQD
          </p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-electric">
          <p className="text-text-primary text-sm mb-1">عدد الدفعات</p>
          <p className="text-2xl font-bold text-navy">
            {reportType === 'total' ? '-' : (currentData as any)?.paid_count || 0}
          </p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6 border-r-4 border-warning">
          <p className="text-text-primary text-sm mb-1">أقساط جديدة</p>
          <p className="text-2xl font-bold text-navy">
            {reportType === 'total' ? '-' : (currentData as any)?.new_installments || 0}
          </p>
        </div>
      </div>

      {/* إحصائيات إضافية للتقرير الإجمالي */}
      {reportType === 'total' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl shadow-sm p-6">
            <p className="text-text-primary text-sm mb-1">إجمالي المبالغ المتبقية</p>
            <p className="text-2xl font-bold text-danger">
              {data?.total?.total_remaining?.toLocaleString() || 0} IQD
            </p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6">
            <p className="text-text-primary text-sm mb-1">الأقساط النشطة</p>
            <p className="text-2xl font-bold text-navy">{data?.total?.active_installments || 0}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm p-6">
            <p className="text-text-primary text-sm mb-1">إجمالي العملاء</p>
            <p className="text-2xl font-bold text-navy">{data?.total?.total_customers || 0}</p>
          </div>
        </div>
      )}

      {/* زر تصدير */}
      <div className="mt-8 flex justify-end">
        <button
          onClick={() => alert('جاري تطوير ميزة التصدير...')}
          className="bg-gray-100 hover:bg-gray-200 text-text-primary px-4 py-2 rounded-lg transition"
        >
          📥 تصدير التقرير (PDF/Excel)
        </button>
      </div>
    </div>
  );
}
