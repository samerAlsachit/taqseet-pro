'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import * as XLSX from 'xlsx';

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
    total_installments: number;
    paid_count: number;
    new_installments: number;
  };
}

export default function ReportsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [reportType, setReportType] = useState<'daily' | 'monthly' | 'total'>('daily');
  const [data, setData] = useState<ReportData | null>(null);
  const [currentReport, setCurrentReport] = useState(reportType);

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
        console.error('Error fetching reports:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchReports();
  }, [router]);

  useEffect(() => {
    setCurrentReport(reportType);
  }, [reportType]);

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
      </div>
    );
  }

  const currentData = reportType === 'daily' ? data?.daily : reportType === 'monthly' ? data?.monthly : data?.total;

  // تصدير إلى Excel
  const exportToExcel = () => {
    if (!data) return;

    let headers: string[] = [];
    let rows: any[][] = [];

    // استخدام currentReport الحالي
    if (currentReport === 'daily') {
      headers = ['البيان', 'القيمة'];
      rows = [
        ['إجمالي التحصيلات', `${data.daily.total_collection.toLocaleString()} IQD`],
        ['عدد الدفعات', data.daily.paid_count],
        ['أقساط جديدة', data.daily.new_installments],
      ];
    } else if (currentReport === 'monthly') {
      headers = ['البيان', 'القيمة'];
      rows = [
        ['إجمالي التحصيلات', `${data.monthly.total_collection.toLocaleString()} IQD`],
        ['عدد الدفعات', data.monthly.paid_count],
        ['أقساط جديدة', data.monthly.new_installments],
      ];
    } else {
      headers = ['البيان', 'القيمة'];
      rows = [
        ['إجمالي التحصيلات الكلي', `${data.total.total_collection.toLocaleString()} IQD`],
        ['إجمالي المبالغ المتبقية', `${data.total.total_remaining.toLocaleString()} IQD`],
        ['الأقساط النشطة', data.total.active_installments],
        ['إجمالي العملاء', data.total.total_customers],
        ['إجمالي الأقساط', data.total.total_installments],
        ['عدد الدفعات', data.total.paid_count || 0],
        ['أقساط جديدة', data.total.new_installments || 0],
      ];
    }

    const worksheet = XLSX.utils.aoa_to_sheet([headers, ...rows]);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'التقرير');
    XLSX.writeFile(workbook, `marsat_${currentReport}_${new Date().toISOString().split('T')[0]}.xlsx`);
  };

  // طباعة الصفحة
  const handlePrint = () => {
    // إنشاء نسخة مؤقتة من المحتوى للطباعة
    const printContent = document.querySelector('.print-area')?.cloneNode(true) as HTMLElement;
    if (!printContent) return;

    // إضافة عنوان التقرير حسب النوع
    const title = document.createElement('div');
    title.style.textAlign = 'center';
    title.style.marginBottom = '20px';
    title.style.fontSize = '20px';
    title.style.fontWeight = 'bold';
    title.style.color = '#0A192F';
    
    let reportTitle = '';
    if (reportType === 'daily') reportTitle = 'التقرير اليومي';
    else if (reportType === 'monthly') reportTitle = 'التقرير الشهري';
    else reportTitle = 'التقرير الإجمالي';
    
    title.innerHTML = `مرساة - ${reportTitle}<br><span style="font-size: 12px; color: #666;">تاريخ: ${new Date().toLocaleDateString('ar-IQ')}</span>`;
    
    printContent.insertBefore(title, printContent.firstChild);

    // فتح نافذة طباعة
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <!DOCTYPE html>
        <html dir="rtl">
        <head>
          <title>تقرير مرساة - ${reportTitle}</title>
          <meta charset="UTF-8">
          <style>
            body {
              font-family: 'Tajawal', 'Arial', sans-serif;
              padding: 20px;
              background: white;
            }
            @media print {
              body {
                padding: 0;
              }
              button, .no-print {
                display: none;
              }
            }
          </style>
        </head>
        <body>
          ${printContent.outerHTML}
        </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.print();
      printWindow.close();
    }
  };

  return (
    <>
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 print-area">
      <h1 className="text-2xl font-bold text-[var(--text-primary)]/70white mb-6">التقارير</h1>

      {/* اختيار نوع التقرير */}
      <div className="flex gap-4 mb-8">
        <button
          onClick={() => setReportType('daily')}
          className={`px-6 py-2 rounded-lg transition ${
            reportType === 'daily'
              ? 'bg-electric text-white'
              : 'bg-[var(--card-bg)] text-[var(--text-primary)] border border-[var(--border-color)] hover:bg-[var(--bg-primary)]'
          }`}
        >
          يومي
        </button>
        <button
          onClick={() => setReportType('monthly')}
          className={`px-6 py-2 rounded-lg transition ${
            reportType === 'monthly'
              ? 'bg-electric text-white'
              : 'bg-[var(--card-bg)] text-[var(--text-primary)] border border-[var(--border-color)] hover:bg-[var(--bg-primary)]'
          }`}
        >
          شهري
        </button>
        <button
          onClick={() => setReportType('total')}
          className={`px-6 py-2 rounded-lg transition ${
            reportType === 'total'
              ? 'bg-electric text-white'
              : 'bg-[var(--card-bg)] text-[var(--text-primary)] border border-[var(--border-color)] hover:bg-[var(--bg-primary)]'
          }`}
        >
          إجمالي
        </button>
      </div>

      {/* بطاقات الإحصائيات */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-success">
          <p className="text-[var(--text-primary)] text-sm mb-1">إجمالي التحصيلات</p>
          <p className="text-2xl font-bold text-[var(--text-primary)]/70white">
            {reportType === 'daily' 
              ? `${(data?.daily?.total_collection || 0).toLocaleString()} IQD` 
              : reportType === 'monthly'
              ? `${(data?.monthly?.total_collection || 0).toLocaleString()} IQD` 
              : `${(data?.total?.total_collection || 0).toLocaleString()} IQD` 
            }
          </p>
        </div>
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-electric">
          <p className="text-[var(--text-primary)] text-sm mb-1">عدد الدفعات</p>
          <p className="text-2xl font-bold text-[var(--text-primary)]/70white">
            {reportType === 'daily' 
              ? data?.daily?.paid_count || 0
              : reportType === 'monthly'
              ? data?.monthly?.paid_count || 0
              : data?.total?.paid_count || 0
            }
          </p>
        </div>
        <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 border-r-4 border-warning">
          <p className="text-[var(--text-primary)] text-sm mb-1">أقساط جديدة</p>
          <p className="text-2xl font-bold text-[var(--text-primary)]/70white">
            {reportType === 'daily' 
              ? data?.daily?.new_installments || 0
              : reportType === 'monthly'
              ? data?.monthly?.new_installments || 0
              : data?.total?.new_installments || 0
            }
          </p>
        </div>
      </div>

      {/* إحصائيات إضافية للتقرير الإجمالي */}
      {reportType === 'total' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
            <p className="text-[var(--text-primary)] text-sm mb-1">إجمالي المبالغ المتبقية</p>
            <p className="text-2xl font-bold text-[var(--text-danger)]">
              {data?.total?.total_remaining?.toLocaleString() || 0} IQD
            </p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
            <p className="text-[var(--text-primary)] text-sm mb-1">الأقساط النشطة</p>
            <p className="text-2xl font-bold text-[var(--text-primary)]/70white">{data?.total?.active_installments || 0}</p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
            <p className="text-[var(--text-primary)] text-sm mb-1">إجمالي العملاء</p>
            <p className="text-2xl font-bold text-[var(--text-primary)]/70white">{data?.total?.total_customers || 0}</p>
          </div>
          <div className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6">
            <p className="text-[var(--text-primary)] text-sm mb-1">إجمالي الأقساط</p>
            <p className="text-2xl font-bold text-[var(--text-primary)]/70white">{data?.total?.total_installments || 0}</p>
          </div>
        </div>
      )}

      {/* زر تصدير */}
      <div className="mt-8 flex justify-end gap-3">
        <button
          onClick={exportToExcel}
          className="bg-success hover:bg-green-600 text-white px-4 py-2 rounded-lg transition flex items-center gap-2"
        >
          📊 Excel
        </button>
        <button
          onClick={handlePrint}
          className="bg-navy hover:bg-navy/80 text-white px-4 py-2 rounded-lg transition flex items-center gap-2"
        >
          🖨️ طباعة
        </button>
      </div>
    </div>
    <style jsx global>{`
      @media print {
        body * {
          visibility: hidden;
        }
        .print-area, .print-area * {
          visibility: visible;
        }
        .print-area {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
        }
        button, .no-print, nav, header {
          display: none !important;
        }
      }
    `}</style>
    </>
  );
}
