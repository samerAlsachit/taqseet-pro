'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState, useEffect } from 'react';

export default function StoreLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [storeName, setStoreName] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }

    // جلب اسم المحل
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/me`, {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setStoreName(data.data.store?.name || 'المحل');
        }
      })
      .catch(console.error);
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('token');
    document.cookie = 'token=; path=/; max-age=0';
    router.push('/login');
  };

  const navItems = [
    { name: 'الرئيسية', path: '/dashboard', icon: '📊' },
    { name: 'العملاء', path: '/customers', icon: '👥' },
    { name: 'المخزن', path: '/products', icon: '📦' },
    { name: 'الأقساط', path: '/installments', icon: '💰' },
    { name: 'التقارير', path: '/reports', icon: '📈' },
    { name: 'الإعدادات', path: '/settings', icon: '⚙️' },
  ];

  return (
    <div className="min-h-screen bg-gray-bg">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-20">
        <div className="flex items-center justify-between px-4 py-3">
          <div className="flex items-center gap-2">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="lg:hidden p-2 rounded-lg hover:bg-gray-100"
            >
              ☰
            </button>
            <div className="flex items-center gap-2">
              <span className="text-xl">⚓</span>
              <h1 className="text-xl font-bold text-navy">مرساة</h1>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 text-danger hover:bg-red-50 px-3 py-2 rounded-lg transition"
          >
            <span>🚪</span>
            <span className="hidden sm:inline">خروج</span>
          </button>
        </div>
      </header>

      {/* Mobile Sidebar */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-30 lg:hidden">
          <div className="absolute inset-0 bg-black/50" onClick={() => setSidebarOpen(false)} />
          <aside className="absolute right-0 top-0 h-full w-64 bg-navy shadow-lg">
            <div className="p-4 border-b border-white/10">
              <div className="flex flex-col items-center">
                <span className="text-2xl mb-2">⚓</span>
                <h2 className="text-white text-xl font-bold">مرساة</h2>
                <p className="text-white/60 text-sm mt-1">{storeName}</p>
              </div>
            </div>
            <nav className="p-4">
              {navItems.map((item) => (
                <Link
                  key={item.path}
                  href={item.path}
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg mb-2 transition ${
                    pathname === item.path
                      ? 'bg-electric text-white'
                      : 'text-white/70 hover:bg-white/10 hover:text-white'
                  }`}
                >
                  <span>{item.icon}</span>
                  <span>{item.name}</span>
                </Link>
              ))}
            </nav>
            <div className="p-4 border-t border-white/10">
              <button
                onClick={handleLogout}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-white/70 hover:bg-white/10 hover:text-white transition"
              >
                <span>🚪</span>
                <span>تسجيل الخروج</span>
              </button>
            </div>
          </aside>
        </div>
      )}

      {/* Desktop Layout */}
      <div className="hidden lg:flex">
        <aside className="w-64 bg-navy min-h-screen sticky top-0">
          <div className="p-6 border-b border-white/10">
            <div className="flex flex-col items-center">
              <span className="text-3xl mb-2">⚓</span>
              <h1 className="text-2xl font-bold text-white tracking-wide">
                مرساة
              </h1>
              <p className="text-white/50 text-xs mt-1">نظام الأقساط</p>
            </div>
          </div>
          <nav className="p-4">
            {navItems.map((item) => (
              <Link
                key={item.path}
                href={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-lg mb-2 transition ${
                  pathname === item.path
                    ? 'bg-electric text-white'
                    : 'text-white/70 hover:bg-white/10 hover:text-white'
                }`}
              >
                <span>{item.icon}</span>
                <span>{item.name}</span>
              </Link>
            ))}
          </nav>
          
          <div className="mt-auto p-4 border-t border-white/10">
            <button
              onClick={handleLogout}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-white/70 hover:bg-white/10 hover:text-white transition"
            >
              <span>🚪</span>
              <span>تسجيل الخروج</span>
            </button>
          </div>
        </aside>
        <main className="flex-1">
          {children}
        </main>
      </div>

      {/* Mobile Content */}
      <div className="lg:hidden">
        {children}
      </div>
    </div>
  );
}
