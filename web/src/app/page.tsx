'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { useTheme } from '@/context/ThemeContext';

export default function HomePage() {
  const { theme } = useTheme();
  const [plans, setPlans] = useState([]);

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/plans`);
        const data = await res.json();
        if (data.success) setPlans(data.data);
      } catch (error) {
        console.error('خطأ في جلب الخطط', error);
      }
    };
    fetchPlans();
  }, []);

  return (
    <div className="min-h-screen bg-[var(--bg-primary)]">
      {/* Hero Section */}
      <div className="relative overflow-hidden bg-gradient-to-br from-navy to-electric dark:from-navy dark:to-navy/80">
        <div className="relative max-w-7xl mx-auto px-4 py-20 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-white/20 mb-6">
              <span className="text-4xl">⚓</span>
            </div>
            <h1 className="text-5xl md:text-6xl font-bold text-white mb-6">
              مرساة
            </h1>
            <p className="text-xl text-white/90 mb-8 max-w-2xl mx-auto">
              نظام متكامل لإدارة الأقساط والديون للمحلات التجارية في العراق
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link 
                href="/login"
                className="bg-white text-navy hover:bg-gray-100 px-8 py-3 rounded-lg font-medium transition"
              >
                تسجيل الدخول
              </Link>
              <Link 
                href="/register"
                className="border-2 border-white text-white hover:bg-white hover:text-navy px-8 py-3 rounded-lg font-medium transition"
              >
                ✨ تجربة مجانية 14 يوم
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="max-w-7xl mx-auto px-4 py-16 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-[var(--text-primary)] mb-4">مميزات النظام</h2>
          <p className="text-[var(--text-primary)]/70">كل ما تحتاجه لإدارة أقساطك بكل سهولة</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            { icon: '📊', title: 'إدارة الأقساط', desc: 'جدولة الأقساط اليومية، الأسبوعية، والشهرية مع حساب تلقائي' },
            { icon: '👥', title: 'إدارة العملاء', desc: 'سجل كامل للعملاء مع إمكانية إضافة كفالة ووثائق' },
            { icon: '📦', title: 'إدارة المخزون', desc: 'تتبع المنتجات والمخزون مع تنبيه تلقائي عند البيع' },
            { icon: '📱', title: 'تطبيق موبايل', desc: 'تطبيق Flutter يعمل بدون إنترنت ويتزامن مع السيرفر' },
            { icon: '📄', title: 'وصلات وطباعة', desc: 'طباعة وصلات للعملاء وإرسالها عبر واتساب' },
            { icon: '📈', title: 'تقارير مفصلة', desc: 'تقارير يومية وشهرية عن الأرباح والمستحقات' },
          ].map((feature, i) => (
            <div key={i} className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 text-center hover:shadow-md transition border border-[var(--border-color)]">
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-xl font-bold text-[var(--text-primary)] mb-2">{feature.title}</h3>
              <p className="text-[var(--text-primary)]/70">{feature.desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Plans Section */}
      <div className="bg-[var(--bg-primary)] py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-[var(--text-primary)] mb-4">خطط تناسب جميع المحلات</h2>
            <p className="text-[var(--text-primary)]/70">اختر الخطة المناسبة لمتجرك وابدأ الآن</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {plans.map((plan: any) => (
              <div key={plan.id} className={`bg-[var(--card-bg)] rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition border ${plan.name === 'سنوي' ? 'border-electric' : 'border-[var(--border-color)]'}`}>
                {plan.name === 'سنوي' && (
                  <div className="bg-electric text-white text-center py-1 text-sm">الأكثر طلباً</div>
                )}
                <div className="p-6 text-center">
                  <h3 className="text-2xl font-bold text-[var(--text-primary)]">{plan.name}</h3>
                  <p className="text-4xl font-bold text-electric mt-4">{plan.price_iqd.toLocaleString()} <span className="text-base text-[var(--text-primary)]/70">IQD</span></p>
                  <p className="text-[var(--text-primary)]/70 text-sm mt-1">{plan.duration_days} يوم</p>
                  <ul className="mt-6 space-y-3 text-right">
                    <li className="flex items-center gap-2 text-[var(--text-primary)]">✅ حتى {plan.max_customers} عميل</li>
                    <li className="flex items-center gap-2 text-[var(--text-primary)]">✅ حتى {plan.max_employees} موظف</li>
                    {plan.features?.map((f: string, i: number) => (
                      <li key={i} className="flex items-center gap-2 text-[var(--text-primary)]">✅ {f}</li>
                    ))}
                  </ul>
                  <Link href="/register" className="block mt-8 bg-electric text-white py-2 rounded-lg hover:bg-blue-600 transition">
                    ابدأ الآن
                  </Link>
                </div>
              </div>
            ))}
          </div>
          
          <div className="text-center mt-12">
            <p className="text-[var(--text-primary)]/70 mb-4">وجرب النظام مجاناً</p>
            <Link href="/register" className="inline-block border border-success text-success px-6 py-2 rounded-lg hover:bg-success hover:text-white transition">
              ✨ تجربة مجانية 14 يوم
            </Link>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-[var(--card-bg)] border-t border-[var(--border-color)] py-8">
        <div className="max-w-7xl mx-auto px-4 text-center sm:px-6 lg:px-8">
          <p className="text-[var(--text-primary)]/70">© 2026 مرساة. جميع الحقوق محفوظة</p>
        </div>
      </footer>
    </div>
  );
}
