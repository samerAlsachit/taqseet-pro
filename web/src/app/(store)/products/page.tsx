'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

interface Product {
  id: string;
  name: string;
  category: string;
  quantity: number;
  low_stock_alert: number;
  sell_price_cash_iqd: number;
  sell_price_install_iqd: number;
  cost_price_iqd: number;
  is_active: boolean;
}

export default function ProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
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
      let url = `${process.env.NEXT_PUBLIC_API_URL}/products?search=${search}&page=${page}&limit=${limit}`;
      if (showLowStock) {
        url += '&low_stock=true';
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
    if (!confirm('هل أنت متأكد من حذف هذا المنتج؟')) return;

    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        fetchProducts();
      } else {
        alert(data.error || 'فشل في حذف المنتج');
      }
    } catch {
      alert('حدث خطأ في الاتصال بالخادم');
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
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-navy">المخزن</h1>
        <Link
          href="/products/new"
          className="bg-electric hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition text-center"
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
          className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-electric"
        />
        <label className="flex items-center gap-2 px-4 py-2 bg-white rounded-lg border border-gray-300">
          <input
            type="checkbox"
            checked={showLowStock}
            onChange={(e) => {
              setShowLowStock(e.target.checked);
              setPage(1);
            }}
            className="w-4 h-4 text-electric"
          />
          <span className="text-text-primary">منتجات المخزون المنخفض فقط</span>
        </label>
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-electric"></div>
        </div>
      ) : products.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm p-12 text-center">
          <p className="text-text-primary mb-4">لا توجد منتجات</p>
          <Link
            href="/products/new"
            className="bg-electric text-white px-4 py-2 rounded-lg inline-block"
          >
            أضف أول منتج
          </Link>
        </div>
      ) : (
        <>
          <div className="bg-white rounded-xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">المنتج</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الفئة</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الكمية</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">سعر البيع نقداً</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">سعر البيع بالقسط</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">الحالة</th>
                    <th className="text-right py-3 px-4 text-text-primary font-semibold">إجراءات</th>
                  </tr>
                </thead>
                <tbody>
                  {products.map((product) => (
                    <tr key={product.id} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4 text-text-primary font-medium">{product.name}</td>
                      <td className="py-3 px-4 text-text-primary">{product.category || '-'}</td>
                      <td className="py-3 px-4 text-text-primary">{product.quantity}</td>
                      <td className="py-3 px-4 text-text-primary">{product.sell_price_cash_iqd?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4 text-text-primary">{product.sell_price_install_iqd?.toLocaleString()} IQD</td>
                      <td className="py-3 px-4">{getStockStatus(product)}</td>
                      <td className="py-3 px-4">
                        <div className="flex gap-2">
                          <Link
                            href={`/products/${product.id}`}
                            className="text-electric hover:underline"
                          >
                            تعديل
                          </Link>
                          <button
                            onClick={() => handleDelete(product.id)}
                            className="text-danger hover:underline"
                          >
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
                className="px-4 py-2 rounded-lg border border-gray-300 disabled:opacity-50"
              >
                السابق
              </button>
              <span className="px-4 py-2 text-text-primary">
                صفحة {page} من {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-4 py-2 rounded-lg border border-gray-300 disabled:opacity-50"
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
