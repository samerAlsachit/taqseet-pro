'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import { Edit, Trash2 } from 'lucide-react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

interface Product {
  id: string;
  name: string;
  category: string;
  quantity: number;
  low_stock_alert: number;
  sell_price_cash_iqd: number;
  sell_price_install_iqd: number;
  sell_price_cash_usd: number;
  sell_price_install_usd: number;
  cost_price_iqd: number;
  is_active: boolean;
  currency: string;
}

export default function ProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [isStoreActive, setIsStoreActive] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [showLowStock, setShowLowStock] = useState(false);
  const limit = 20;

  const fetchProducts = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    setLoading(true);
    try {
      // جلب بيانات المستخدم والمحل
      const meRes = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const meData = await meRes.json();
      
      if (meData.success) {
        const store = meData.data.store;
        if (store && !store.is_active) {
          setIsStoreActive(false);
          alert('حساب المحل غير نشط. يرجى التواصل مع الدعم.');
        }
      }

      let url = `${process.env.NEXT_PUBLIC_API_URL}/products?search=${search}&page=${page}&limit=${limit}`;
      if (showLowStock) {
        url += `&low_stock=true`;
      }
        
        const res = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        setProducts(data.data.products);
        setTotalPages(data.data.pagination.totalPages);
      }
    } catch (error) {
      console.error('خطأ في جلب المنتجات', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, [page, search, showLowStock]);

  const handleDelete = async (id: string) => {
    if (!isStoreActive) {
      alert('حساب المحل غير نشط. لا يمكن إجراء عمليات.');
      return;
    }

    if (!confirm('هل أنت متأكد من حذف هذا المنتج؟')) return;

    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        toast.success('تم حذف المنتج بنجاح');
        fetchProducts();
      } else {
        toast.error(data.error || 'فشل في حذف المنتج');
      }
    } catch {
      toast.error('حدث خطأ في الاتصال بالخادم');
    }
  };

  const getStockStatus = (product: Product) => {
    if (product.quantity <= 0) {
      return <span className="px-2 py-1 rounded-full text-sm bg-danger/10 text-danger">نفد</span>;
    }
    if (product.quantity <= product.low_stock_alert) {
      return <span className="px-2 py-1 rounded-full text-sm bg-warning/10 text-warning">مخزون منخفض</span>;
    }
    return <span className="px-2 py-1 rounded-full text-sm bg-success/10 text-success">متوفر</span>;
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      {/* تحذير المحل غير النشط */}
      {!isStoreActive && (
        <div className="bg-red-50 dark:bg-red-900/30 border border-red-300 dark:border-red-700 rounded-lg p-4 mb-6">
          <div className="flex items-center gap-3">
            <div className="text-red-600 dark:text-red-400 text-xl">⚠️</div>
            <div>
              <p className="font-bold text-red-700 dark:text-red-400">حساب المحل غير نشط</p>
              <p className="text-red-600 dark:text-red-300 text-sm">
                حسابك غير نشط حالياً. يرجى التواصل مع الدعم لتفعيله.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">المخزن</h1>
        <Link
          href="/products/new"
          className={`px-4 py-2 rounded-lg transition ${
            isStoreActive
              ? 'bg-[#3A86FF] hover:bg-[#2563EB] text-white'
              : 'bg-gray-300 dark:bg-gray-600 cursor-not-allowed opacity-50'
          }`}
          onClick={(e) => !isStoreActive && e.preventDefault()}
        >
          + إضافة منتج جديد
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <input
          type="text"
          placeholder="بحث باسم المنتج..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
        />
        <label className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-gray-800 rounded-lg border border-gray-300 dark:border-gray-600">
          <input
            type="checkbox"
            checked={showLowStock}
            onChange={(e) => {
              setShowLowStock(e.target.checked);
              setPage(1);
            }}
            className="w-4 h-4 text-blue-600"
          />
          <span className="text-gray-900 dark:text-white">منتجات المخزون المنخفض فقط</span>
        </label>
      </div>

      {/* Table */}
      {loading ? (
        <LoadingSpinner />
      ) : products.length === 0 ? (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 text-center">
          <p className="text-gray-900 dark:text-white mb-4">لا توجد منتجات</p>
          <Link
            href="/products/new"
            className="btn-primary"
          >
            أضف أول منتج
          </Link>
        </div>
      ) : (
        <>
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">المنتج</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الفئة</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الكمية</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">العملة</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">سعر البيع نقداً</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">سعر البيع بالقسط</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">الحالة</th>
                    <th className="text-right py-3 px-4 text-gray-500 dark:text-gray-400 font-semibold">إجراءات</th>
                  </tr>
                </thead>
                <tbody>
                  {products.map((product) => (
                    <tr key={product.id} className="border-b border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                      <td className="py-3 px-4 text-gray-900 dark:text-white font-medium">{product.name}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{product.category || '-'}</td>
                      <td className="py-3 px-4 text-gray-900 dark:text-white">{product.quantity}</td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-700">
                          {product.currency === 'USD' ? 'دولار' : 'دينار'}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        {product.currency === 'IQD' 
                          ? `${product.sell_price_cash_iqd?.toLocaleString()} IQD` 
                          : `${product.sell_price_cash_usd?.toLocaleString()} USD`}
                      </td>
                      <td className="py-3 px-4">
                        {product.currency === 'IQD' 
                          ? `${product.sell_price_install_iqd?.toLocaleString()} IQD` 
                          : `${product.sell_price_install_usd?.toLocaleString()} USD`}
                      </td>
                      <td className="py-3 px-4">{getStockStatus(product)}</td>
                      <td className="py-3 px-4">
                        <div className="flex gap-2">
                          <Link
                            href={`/products/${product.id}/edit`}
                            className="text-[#3A86FF] hover:underline text-sm"
                          >
                            <Edit size={16} className="inline ml-1" />
                            تعديل
                          </Link>
                          <button
                            onClick={() => handleDelete(product.id)}
                            className="text-[#DC3545] hover:underline text-sm"
                          >
                            <Trash2 size={16} className="inline ml-1" />
                            حذف
                          </button>
                        </div>
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
                className="px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-900 dark:text-white disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-4 py-2 text-gray-900 dark:text-white">
                صفحة {page} من {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-900 dark:text-white disabled:opacity-50"
              >
                التالي
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
