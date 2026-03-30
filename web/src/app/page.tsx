'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import LoadingSpinner from '@/components/ui/LoadingSpinner';
import { Anchor, Calendar, Star, Rocket, CheckCircle, BarChart3, Users, Package, Smartphone, FileText, TrendingUp, Gift } from 'lucide-react';

export default function HomePage() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/plans`);
        const data = await res.json();
        if (data.success) setPlans(data.data);
      } catch (error) {
        console.error('Error fetching plans:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchPlans();
  }, []);

  if (loading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Hero Section */}
      <div className="relative overflow-hidden bg-gradient-to-br from-navy to-electric dark:from-navy dark:to-navy/80">
        <div className="relative max-w-7xl mx-auto px-4 py-20 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-white/20 mb-6">
              <Anchor className="text-white" size={40} />
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
                <Gift className="inline ml-1" size={18} />
                تجربة مجانية 14 يوم
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="max-w-7xl mx-auto px-4 py-16 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">مميزات النظام</h2>
          <p className="text-gray-500 dark:text-gray-400">كل ما تحتاجه لإدارة أقساطك بكل سهولة</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            { icon: BarChart3, title: 'إدارة الأقساط', desc: 'جدولة الأقساط اليومية، الأسبوعية، والشهرية مع حساب تلقائي' },
            { icon: Users, title: 'إدارة العملاء', desc: 'سجل كامل للعملاء مع إمكانية إضافة كفلاء ووثائق' },
            { icon: Package, title: 'إدارة المخزون', desc: 'تتبع المنتجات والمخزون مع تنقيص تلقائي عند البيع' },
            { icon: Smartphone, title: 'تطبيق موبايل', desc: 'تطبيق Flutter يعمل بدون إنترنت ويتزامن مع السيرفر' },
            { icon: FileText, title: 'وصلات وطباعة', desc: 'طباعة وصلات للعملاء وإرسالها عبر واتساب' },
            { icon: TrendingUp, title: 'تقارير مفصلة', desc: 'تقارير يومية وشهرية عن الأرباح والمستحقات' },
          ].map((feature, i) => (
            <div key={i} className="bg-[var(--card-bg)] rounded-xl shadow-sm p-6 text-center hover:shadow-md transition border border-[var(--border-color)]">
              <feature.icon className="w-12 h-12 mx-auto mb-4 text-electric" />
              <h3 className="text-xl font-bold text-[var(--text-primary)] mb-2">{feature.title}</h3>
              <p className="text-[var(--text-primary)]/70">{feature.desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Plans Section */}
      <div className="py-16 bg-[var(--bg-primary)]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-[var(--text-primary)] mb-4">خطط تناسب جميع المحلات</h2>
            <p className="text-[var(--text-primary)]/70">اختر الخطة المناسبة لمتجرك وابدأ الآن</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* الخطة الشهرية */}
            <div className="bg-[var(--card-bg)] rounded-2xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 border border-[var(--border-color)]">
              <div className="p-6">
                <Calendar className="w-8 h-8 text-electric mb-2" />
                <h3 className="text-2xl font-bold text-[var(--text-primary)] mb-2">شهري</h3>
                <div className="mb-4">
                  <span className="text-4xl font-bold text-electric">15,000</span>
                  <span className="text-[var(--text-primary)]/60"> IQD</span>
                </div>
                <p className="text-[var(--text-primary)]/60 text-sm mb-6">لمدة 30 يوم</p>
                <ul className="space-y-3 mb-8">
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> حتى 200 عميل
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> حتى 2 موظف
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> دعم فني
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> تحديثات مجانية
                  </li>
                </ul>
                <Link
                  href="/register"
                  className="block w-full text-center bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition"
                >
                  ابدأ الآن
                </Link>
              </div>
            </div>

            {/* الخطة السنوية (الأكثر طلباً) */}
            <div className="bg-[var(--card-bg)] rounded-2xl shadow-xl overflow-hidden hover:shadow-2xl transition-all duration-300 border-2 border-electric relative">
              <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-electric text-white px-4 py-1 rounded-full text-sm font-medium">
                الأكثر طلباً
              </div>
              <div className="p-6 pt-8">
                <Star className="w-8 h-8 text-yellow-500 mb-2" />
                <h3 className="text-2xl font-bold text-[var(--text-primary)] mb-2">سنوي</h3>
                <div className="mb-2">
                  <span className="text-3xl font-bold text-electric">130,000</span>
                  <span className="text-[var(--text-primary)]/60"> IQD</span>
                </div>
                <div className="mb-4">
                  <span className="text-sm line-through text-gray-400">180,000 IQD</span>
                  <span className="text-sm text-success mr-2">وفر 50,000 (28%)</span>
                </div>
                <p className="text-[var(--text-primary)]/60 text-sm mb-6">لمدة 365 يوم</p>
                <ul className="space-y-3 mb-8">
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> حتى 1000 عميل
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> حتى 5 موظف
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> دعم فني أولوية
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> تحديثات مجانية
                  </li>
                </ul>
                <Link
                  href="/register"
                  className="block w-full text-center bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition"
                >
                  ابدأ الآن
                </Link>
              </div>
            </div>

            {/* الخطة الثلاث سنوات */}
            <div className="bg-[var(--card-bg)] rounded-2xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 border border-[var(--border-color)]">
              <div className="p-6">
                <Rocket className="w-8 h-8 text-electric mb-2" />
                <h3 className="text-2xl font-bold text-[var(--text-primary)] mb-2">3 سنوات</h3>
                <div className="mb-2">
                  <span className="text-4xl font-bold text-electric">350,000</span>
                  <span className="text-[var(--text-primary)]/60"> IQD</span>
                </div>
                <div className="mb-4">
                  <span className="text-sm line-through text-gray-400">540,000 IQD</span>
                  <span className="text-sm text-success mr-2">وفر 190,000 (35%)</span>
                </div>
                <p className="text-[var(--text-primary)]/60 text-sm mb-6">لمدة 1095 يوم</p>
                <ul className="space-y-3 mb-8">
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> غير محدود العملاء
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> حتى 10 موظف
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> دعم VIP
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> تحديثات مجانية
                  </li>
                  <li className="flex items-center gap-2 text-[var(--text-primary)]">
                    <span className="text-success">✓</span> استشارات مجانية
                  </li>
                </ul>
                <Link
                  href="/register"
                  className="block w-full text-center bg-electric hover:bg-blue-600 text-white py-2 rounded-lg transition"
                >
                  ابدأ الآن
                </Link>
              </div>
            </div>
          </div>
          
          <div className="text-center mt-12">
            <p className="text-[var(--text-primary)]/70 mb-4">أو جرب النظام مجاناً</p>
            <Link
              href="/register"
              className="inline-block border border-success text-success px-6 py-2 rounded-lg hover:bg-success hover:text-white transition"
            >
              <Gift className="inline ml-1" size={18} />
              تجربة مجانية 14 يوم
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
