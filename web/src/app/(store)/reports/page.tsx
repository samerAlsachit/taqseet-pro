'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import * as XLSX from 'xlsx';
import { 
  FileText, 
  TrendingUp, 
  DollarSign, 
  Calendar, 
  Download, 
  Printer,
  BarChart3,
  PieChart,
  LineChart
} from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

interface ReportData {
  daily: {
    total_collection: { IQD: number; USD: number };
    paid_count: number;
    new_installments: number;
  };
  monthly: {
    total_collection: { IQD: number; USD: number };
    paid_count: number;
    new_installments: number;
  };
  total: {
    total_collection: { IQD: number; USD: number };
    total_remaining: { IQD: number; USD: number };
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
    return <LoadingSpinner />;
  }

  const currentData = reportType === 'daily' ? data?.daily : reportType === 'monthly' ? data?.monthly : data?.total;

  // تصدير إلى Excel
  const exportToExcel = () => {
    if (!data) return;

    let headers: string[] = [];
    let rows: any[][] = [];

    // استخدام currentReport الحالي
    if (currentReport === 'daily') {
      headers = ['البيان', 'IQD', 'USD'];
      rows = [
        ['إجمالي التحصيلات', data.daily.total_collection.IQD.toLocaleString(), data.daily.total_collection.USD.toLocaleString()],
        ['عدد الدفعات', data.daily.paid_count, ''],
        ['أقساط جديدة', data.daily.new_installments, ''],
      ];
    } else if (currentReport === 'monthly') {
      headers = ['البيان', 'IQD', 'USD'];
      rows = [
        ['إجمالي التحصيلات', data.monthly.total_collection.IQD.toLocaleString(), data.monthly.total_collection.USD.toLocaleString()],
        ['عدد الدفعات', data.monthly.paid_count, ''],
        ['أقساط جديدة', data.monthly.new_installments, ''],
      ];
    } else {
      headers = ['البيان', 'IQD', 'USD'];
      rows = [
        ['إجمالي التحصيلات الكلي', data.total.total_collection.IQD.toLocaleString(), data.total.total_collection.USD.toLocaleString()],
        ['إجمالي المبالغ المتبقية', data.total.total_remaining.IQD.toLocaleString(), data.total.total_remaining.USD.toLocaleString()],
        ['الأقساط النشطة', data.total.active_installments, ''],
        ['إجمالي العملاء', data.total.total_customers, ''],
        ['إجمالي الأقساط', data.total.total_installments, ''],
        ['عدد الدفعات', data.total.paid_count || 0, ''],
        ['أقساط جديدة', data.total.new_installments || 0, ''],
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
        <div className="flex items-center gap-2 mb-6">
          <FileText className="text-electric" size={28} />
          <h1 className="text-2xl font-bold text-navy dark:text-white">التقارير</h1>
        </div>
        <button
          onClick={() => setReportType('daily')}
          className={`flex items-center gap-2 px-6 py-2 rounded-lg transition ${
            reportType === 'daily'
              ? 'bg-electric text-white'
              : 'bg-white dark:bg-gray-800 text-text-primary border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
          }`}
        >
          <Calendar size={18} />
          <span>يومي</span>
        </button>
        <button
          onClick={() => setReportType('monthly')}
          className={`flex items-center gap-2 px-6 py-2 rounded-lg transition ${
            reportType === 'monthly'
              ? 'bg-electric text-white'
              : 'bg-white dark:bg-gray-800 text-text-primary border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
          }`}
        >
          <BarChart3 size={18} />
          <span>شهري</span>
        </button>
        <button
          onClick={() => setReportType('total')}
          className={`flex items-center gap-2 px-6 py-2 rounded-lg transition ${
            reportType === 'total'
              ? 'bg-electric text-white'
              : 'bg-white dark:bg-gray-800 text-text-primary border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
          }`}
        >
          <PieChart size={18} />
          <span>إجمالي</span>
        </button>
      </div>

      {/* بطاقات الإحصائيات */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-green-600">
          <div className="flex items-center justify-between mb-2">
            <DollarSign className="text-green-600" size={24} />
            <p className="text-gray-500 dark:text-gray-400 text-sm">إجمالي التحصيلات</p>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {reportType === 'daily' 
              ? `${(data?.daily?.total_collection?.IQD || 0).toLocaleString()} IQD${data?.daily?.total_collection?.USD > 0 ? ` / ${data.daily.total_collection.USD.toLocaleString()} USD` : ''}` 
              : reportType === 'monthly'
              ? `${(data?.monthly?.total_collection?.IQD || 0).toLocaleString()} IQD${data?.monthly?.total_collection?.USD > 0 ? ` / ${data.monthly.total_collection.USD.toLocaleString()} USD` : ''}` 
              : `${(data?.total?.total_collection?.IQD || 0).toLocaleString()} IQD${data?.total?.total_collection?.USD > 0 ? ` / ${data.total.total_collection.USD.toLocaleString()} USD` : ''}` 
            }
          </div>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-blue-600">
          <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">عدد الدفعات</p>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {reportType === 'daily' 
              ? data?.daily?.paid_count || 0
              : reportType === 'monthly'
              ? data?.monthly?.paid_count || 0
              : data?.total?.paid_count || 0
            }
          </p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-yellow-600">
          <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">أقساط جديدة</p>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
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
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">إجمالي المبالغ المتبقية</p>
            <div className="text-2xl font-bold text-red-600 dark:text-red-400">
              {data?.total?.total_remaining?.IQD > 0 && (
                <div>{data.total.total_remaining.IQD.toLocaleString()} IQD</div>
              )}
              {data?.total?.total_remaining?.USD > 0 && (
                <div>{data.total.total_remaining.USD.toLocaleString()} USD</div>
              )}
              {(!data?.total?.total_remaining?.IQD && !data?.total?.total_remaining?.USD) && (
                <div>0</div>
              )}
            </div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">الأقساط النشطة</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{data?.total?.active_installments || 0}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">إجمالي العملاء</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{data?.total?.total_customers || 0}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">إجمالي الأقساط</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{data?.total?.total_installments || 0}</p>
          </div>
        </div>
      )}
      {/* زر تصدير */}
      <div className="mt-8 flex justify-end gap-3">
        <button
          onClick={exportToExcel}
          className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg transition"
        >
          <Download size={18} />
          <span>Excel</span>
        </button>
        <button
          onClick={handlePrint}
          className="flex items-center gap-2 bg-navy hover:bg-navy/80 text-white px-4 py-2 rounded-lg transition"
        >
          <Printer size={18} />
          <span>طباعة</span>
        </button>
      </div>
    </>
  );
}
