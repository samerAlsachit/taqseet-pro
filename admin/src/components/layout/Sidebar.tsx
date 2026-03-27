'use client';

import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = () => {
    localStorage.removeItem('token');
    document.cookie = 'token=; path=/; max-age=0';
    router.push('/login');
  };

  const navItems = [
    { name: 'الرئيسية', path: '/dashboard', icon: '📊' },
    { name: 'المحلات', path: '/stores', icon: '🏪' },
    { name: 'كودات التفعيل', path: '/activation-codes', icon: '🔑' },
  ];

  return (
    <aside className="w-64 bg-navy min-h-screen flex flex-col">
      <div className="p-6 border-b border-white/10">
  <div className="flex flex-col items-center">
    <span className="text-3xl mb-2">⚓</span>
    <h1 className="text-2xl font-bold tracking-wide bg-gradient-to-r from-white to-electric bg-clip-text text-transparent">
      مرساة
    </h1>
    <p className="text-white/50 text-xs mt-1">نظام إدارة الأقساط</p>
  </div>
</div>

      <nav className="flex-1 p-4">
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

      <div className="p-4 border-t border-white/10">
        <div className="text-center text-white/50 text-xs">
          مرساة - نظام إدارة الأقساط
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-white/70 hover:bg-white/10 hover:text-white transition mt-3"
        >
          <span>🚪</span>
          <span>تسجيل الخروج</span>
        </button>
      </div>
    </aside>
  );
}
