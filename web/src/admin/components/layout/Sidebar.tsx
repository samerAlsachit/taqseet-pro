'use client';

import Link from 'next/link';
import { useTheme } from '../../context/ThemeContext';
import { useRouter, usePathname } from 'next/navigation';

export default function Sidebar() {
  const { theme, toggleTheme } = useTheme();
  const pathname = usePathname();
  const router = useRouter();

  // أضف console.log للتأكد
  console.log('Theme:', theme);

  const handleLogout = () => {
    localStorage.removeItem('admin-token');
    router.push('/admin/login');
  };

  const menuItems = [
    { path: '/admin', icon: '📊', name: 'لوحة التحكم' },
    { path: '/admin/plans', icon: '📋', name: 'الخطط' },
    { path: '/admin/stores', icon: '🏪', name: 'المحلات' },
    { path: '/admin/users', icon: '👥', name: 'المستخدمون' },
    { path: '/admin/settings', icon: '⚙️', name: 'الإعدادات' },
  ];

  return (
    <aside className="w-64 bg-navy min-h-screen flex flex-col">
      <div className="p-6 border-b border-white/10">
        <div className="flex flex-col items-center">
          <span className="text-3xl mb-2">⚓</span>
          <h1 className="text-2xl font-bold text-white tracking-wide">
            مرساة
          </h1>
          <p className="text-white/50 text-xs mt-1">لوحة الإدارة</p>
        </div>
      </div>
      
      <nav className="flex-1 p-4">
        {menuItems.map((item) => (
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
      
      <div className="p-4 border-t border-white/10 space-y-2">
        <button
          onClick={toggleTheme}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-white/70 hover:bg-white/10 hover:text-white transition"
        >
          <span>{theme === 'light' ? '🌙' : '☀️'}</span>
          <span>{theme === 'light' ? 'الوضع الليلي' : 'الوضع النهاري'}</span>
        </button>
        
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-white/70 hover:bg-white/10 hover:text-white transition"
        >
          <span>🚪</span>
          <span>تسجيل الخروج</span>
        </button>
      </div>
    </aside>
  );
}
