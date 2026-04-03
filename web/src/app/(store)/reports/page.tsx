'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import * as XLSX from 'xlsx';
import { 
  FileText, 
  DollarSign, 
  Calendar, 
  Download, 
  Printer,
  BarChart3,
  PieChart,
  TrendingUp,
  Package,
  Wallet
} from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

export default function ReportsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [reportType, setReportType] = useState<'daily' | 'monthly' | 'total' | 'profit'>('daily');
  const [data, setData] = useState<any>(null);
  const [profitData, setProfitData] = useState<any>(null);
  const [profitPeriod, setProfitPeriod] = useState('monthly');
  const [profitLoading, setProfitLoading] = useState(false);

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
        if (result.success) setData(result.data);
      } catch (error) {
        console.error('Error fetching reports:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchReports();
  }, [router]);

  const fetchProfitData = async () => {
    setProfitLoading(true);
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/reports/profit?period=${profitPeriod}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const result = await res.json();
      if (result.success) setProfitData(result.data);
    } catch (error) {
      console.error('Error fetching profit:', error);
    } finally {
      setProfitLoading(false);
    }
  };

  useEffect(() => {
    if (reportType === 'profit') {
      fetchProfitData();
    }
  }, [profitPeriod, reportType]);

  const exportToExcel = () => {
    if (!data) return;
    // ... كود التصدير
  };

  const handlePrint = () => {
    const printContent = document.querySelector('.print-area');
    if (!printContent) {
      // إذا لم يوجد print-area، اطبع الصفحة كاملة
      window.print();
      return;
    }
    
    const originalTitle = document.title;
    document.title = `تقرير مرساة - ${reportType === 'profit' ? 'الأرباح' : reportType === 'daily' ? 'يومي' : reportType === 'monthly' ? 'شهري' : 'إجمالي'}`;
    
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <!DOCTYPE html>
        <html dir="rtl">
        <head>
          <title>${document.title}</title>
          <meta charset="UTF-8">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
              font-family: 'Cairo', 'Tajawal', sans-serif;
              padding: 20px;
              background: white;
              color: #333;
            }
            .print-container {
              max-width: 1200px;
              margin: 0 auto;
            }
            .header {
              text-align: center;
              margin-bottom: 30px;
              padding-bottom: 20px;
              border-bottom: 2px solid #3A86FF;
            }
            .header h1 {
              font-size: 24px;
              color: #0A192F;
            }
            .header p {
              color: #666;
              margin-top: 5px;
            }
            table {
              width: 100%;
              border-collapse: collapse;
              margin: 15px 0;
            }
            th, td {
              border: 1px solid #ddd;
              padding: 8px;
              text-align: right;
            }
            th {
              background-color: #3A86FF;
              color: white;
            }
            .card {
              border: 1px solid #ddd;
              border-radius: 8px;
              padding: 15px;
              margin-bottom: 15px;
              background: #f9f9f9;
            }
            @media print {
              body { padding: 0; }
              button { display: none; }
            }
          </style>
        </head>
        <body>
          <div class="print-container">
            ${printContent.outerHTML}
          </div>
          <script>
            window.onload = () => window.print();
          </script>
        </body>
        </html>
      `);
      printWindow.document.close();
    }
    document.title = originalTitle;
  };

  if (loading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 print-area">
      <div className="flex items-center gap-2 mb-6">
        <FileText className="text-electric" size={28} />
        <h1 className="text-2xl font-bold text-navy dark:text-white">التقارير</h1>
      </div>

      {/* أزرار التبويب */}
      <div className="flex gap-4 mb-6 border-b border-gray-200 dark:border-gray-700">
        <button
          onClick={() => setReportType('daily')}
          className={`pb-2 px-4 transition ${reportType === 'daily' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'}`}
        >
          التقارير
        </button>
        <button
          onClick={() => setReportType('profit')}
          className={`pb-2 px-4 transition ${reportType === 'profit' ? 'border-b-2 border-electric text-electric' : 'text-text-primary'}`}
        >
          الأرباح
        </button>
      </div>

      {/* محتوى التقارير العادية */}
      {reportType !== 'profit' && (
        <>
          {/* أزرار الفترة */}
          <div className="flex flex-wrap gap-3 mb-8">
            <button onClick={() => setReportType('daily')} className={`px-6 py-2 rounded-lg transition ${reportType === 'daily' ? 'bg-electric text-white' : 'bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600'}`}>
              يومي
            </button>
            <button onClick={() => setReportType('monthly')} className={`px-6 py-2 rounded-lg transition ${reportType === 'monthly' ? 'bg-electric text-white' : 'bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600'}`}>
              شهري
            </button>
            <button onClick={() => setReportType('total')} className={`px-6 py-2 rounded-lg transition ${reportType === 'total' ? 'bg-electric text-white' : 'bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600'}`}>
              إجمالي
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
                  ? `${(data?.daily?.total_collection?.IQD || 0).toLocaleString()} IQD` 
                  : reportType === 'monthly'
                  ? `${(data?.monthly?.total_collection?.IQD || 0).toLocaleString()} IQD` 
                  : `${(data?.total?.total_collection?.IQD || 0).toLocaleString()} IQD` 
                }
              </div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border-r-4 border-blue-600">
              <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">عدد الدفعات</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
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
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {reportType === 'daily' 
                  ? data?.daily?.new_installments || 0
                  : reportType === 'monthly'
                  ? data?.monthly?.new_installments || 0
                  : data?.total?.new_installments || 0
                }
              </p>
            </div>
          </div>
        </>
      )}

      {/* محتوى الأرباح */}
      {reportType === 'profit' && profitData && (
        <div className="space-y-8">
          {/* أزرار الفترة */}
          <div className="flex flex-wrap gap-3 border-b border-gray-200 dark:border-gray-700 pb-4">
            <button
              onClick={() => setProfitPeriod('daily')}
              className={`px-5 py-2 rounded-lg transition-all duration-200 ${
                profitPeriod === 'daily'
                  ? 'bg-electric text-white shadow-md'
                  : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              يومي
            </button>
            <button
              onClick={() => setProfitPeriod('monthly')}
              className={`px-5 py-2 rounded-lg transition-all duration-200 ${
                profitPeriod === 'monthly'
                  ? 'bg-electric text-white shadow-md'
                  : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              شهري
            </button>
            <button
              onClick={() => setProfitPeriod('yearly')}
              className={`px-5 py-2 rounded-lg transition-all duration-200 ${
                profitPeriod === 'yearly'
                  ? 'bg-electric text-white shadow-md'
                  : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              سنوي
            </button>
            <button
              onClick={() => setProfitPeriod('all')}
              className={`px-5 py-2 rounded-lg transition-all duration-200 ${
                profitPeriod === 'all'
                  ? 'bg-electric text-white shadow-md'
                  : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              إجمالي
            </button>
          </div>

          {/* بطاقات إجمالي الأرباح والمبيعات */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/20 rounded-2xl p-6 border border-green-200 dark:border-green-800">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-green-100 dark:bg-green-900/50 rounded-xl">
                  <DollarSign className="text-green-600 dark:text-green-400" size={24} />
                </div>
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">إجمالي الأرباح</p>
                  <h3 className="text-lg font-bold text-navy dark:text-white">صافي الربح</h3>
                </div>
              </div>
              <div className="space-y-2">
                {profitData?.total_profit?.IQD > 0 && (
                  <p className="text-3xl font-bold text-green-600 dark:text-green-400">
                    {profitData?.total_profit?.IQD.toLocaleString()} <span className="text-sm font-normal">IQD</span>
                  </p>
                )}
                {profitData?.total_profit?.USD > 0 && (
                  <p className="text-2xl font-bold text-green-600 dark:text-green-400">
                    {profitData?.total_profit?.USD.toLocaleString()} <span className="text-sm font-normal">USD</span>
                  </p>
                )}
                <div className="mt-3 pt-3 border-t border-green-200 dark:border-green-800">
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    هامش الربح: <span className="font-bold text-green-600">{profitData?.profit_margin?.IQD}%</span> IQD / <span className="font-bold text-green-600">{profitData?.profit_margin?.USD}%</span> USD
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 rounded-2xl p-6 border border-blue-200 dark:border-blue-800">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-blue-100 dark:bg-blue-900/50 rounded-xl">
                  <TrendingUp className="text-blue-600 dark:text-blue-400" size={24} />
                </div>
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">إجمالي المبيعات</p>
                  <h3 className="text-lg font-bold text-navy dark:text-white">حجم المبيعات</h3>
                </div>
              </div>
              <div className="space-y-2">
                {profitData?.total_sales?.IQD > 0 && (
                  <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
                    {profitData?.total_sales?.IQD.toLocaleString()} <span className="text-sm font-normal">IQD</span>
                  </p>
                )}
                {profitData?.total_sales?.USD > 0 && (
                  <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                    {profitData?.total_sales?.USD.toLocaleString()} <span className="text-sm font-normal">USD</span>
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* تفصيل الأرباح حسب النوع */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* أرباح التقسيط */}
            <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-6 border border-gray-200 dark:border-gray-700 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-purple-100 dark:bg-purple-900/50 rounded-xl">
                  <Wallet className="text-purple-600 dark:text-purple-400" size={22} />
                </div>
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">أرباح المبيعات بالتقسيط</p>
                  <h3 className="text-lg font-bold text-navy dark:text-white">التقسيط</h3>
                </div>
              </div>
              <div className="space-y-3">
                {profitData?.installment_profit?.IQD > 0 && (
                  <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">
                    {profitData?.installment_profit?.IQD.toLocaleString()} <span className="text-sm font-normal">IQD</span>
                  </p>
                )}
                <div className="pt-3 border-t border-gray-200 dark:border-gray-700">
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    إجمالي مبيعات التقسيط: <span className="font-medium">{profitData?.installment_sales?.IQD?.toLocaleString() || 0} IQD</span>
                  </p>
                </div>
              </div>
            </div>

            {/* أرباح البيع النقدي */}
            <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-6 border border-gray-200 dark:border-gray-700 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-orange-100 dark:bg-orange-900/50 rounded-xl">
                  <Package className="text-orange-600 dark:text-orange-400" size={22} />
                </div>
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">أرباح المبيعات النقدية</p>
                  <h3 className="text-lg font-bold text-navy dark:text-white">نقدي</h3>
                </div>
              </div>
              <div className="space-y-3">
                {profitData?.cash_profit?.IQD > 0 && (
                  <p className="text-2xl font-bold text-orange-600 dark:text-orange-400">
                    {profitData?.cash_profit?.IQD.toLocaleString()} <span className="text-sm font-normal">IQD</span>
                  </p>
                )}
                {profitData?.cash_profit?.USD > 0 && (
                  <p className="text-lg font-bold text-orange-600 dark:text-orange-400">
                    {profitData?.cash_profit?.USD.toLocaleString()} <span className="text-sm font-normal">USD</span>
                  </p>
                )}
                <div className="pt-3 border-t border-gray-200 dark:border-gray-700">
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    إجمالي المبيعات النقدية: {profitData?.cash_sales?.IQD?.toLocaleString() || 0} IQD
                    {profitData?.cash_sales?.USD > 0 && ` / ${profitData?.cash_sales?.USD.toLocaleString()} USD`}
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* ملخص إضافي */}
          <div className="bg-gray-50 dark:bg-gray-800/50 rounded-xl p-4 text-center">
            <p className="text-sm text-gray-500 dark:text-gray-400">
              التقرير يشمل جميع المبيعات النقدية والمبيعات بالتقسيط
            </p>
          </div>
        </div>
      )}

      {/* أزرار التصدير */}
      <div className="flex justify-end gap-3 mt-8">
        <button onClick={exportToExcel} className="flex items-center gap-2 bg-success hover:bg-green-700 text-white px-4 py-2 rounded-lg transition">
          <Download size={18} />
          <span>Excel</span>
        </button>
        <button onClick={handlePrint} className="flex items-center gap-2 bg-navy hover:bg-navy/80 text-white px-4 py-2 rounded-lg transition">
          <Printer size={18} />
          <span>طباعة</span>
        </button>
      </div>
    </div>
  );
}
