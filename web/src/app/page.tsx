import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gray-bg">
      {/* Hero Section */}
      <div className="relative overflow-hidden">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute inset-0" style={{ 
            backgroundImage: 'radial-gradient(circle at 2px 2px, var(--color-navy) 1px, transparent 1px)',
            backgroundSize: '40px 40px'
          }} />
        </div>
        
        <div className="relative max-w-7xl mx-auto px-4 py-20 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-br from-navy to-electric mb-4">
              <span className="text-4xl">⚓</span>
            </div>
            <h1 className="text-5xl md:text-6xl font-bold bg-gradient-to-r from-navy to-electric bg-clip-text text-transparent mb-4">
              مرساة
            </h1>
            <p className="text-xl text-text-primary mb-8 max-w-2xl mx-auto">
              نظام متكامل لإدارة الأقساط والديون للمحلات التجارية في العراق
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link 
                href="/login"
                className="bg-electric hover:bg-blue-600 text-white px-8 py-3 rounded-lg font-medium transition transform hover:scale-105"
              >
                تسجيل الدخول
              </Link>
              <Link 
                href="/activate"
                className="border-2 border-electric text-electric hover:bg-electric hover:text-white px-8 py-3 rounded-lg font-medium transition"
              >
                تفعيل حساب جديد
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="max-w-7xl mx-auto px-4 py-16 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-navy mb-4">مميزات النظام</h2>
          <p className="text-text-primary">كل ما تحتاجه لإدارة أقساطك بكل سهولة</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white rounded-xl shadow-sm p-6 text-center hover:shadow-md transition">
            <div className="text-4xl mb-4">📊</div>
            <h3 className="text-xl font-bold text-navy mb-2">إدارة الأقساط</h3>
            <p className="text-text-primary">جدولة الأقساط اليومية، الأسبوعية، والشهرية مع حساب تلقائي</p>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-6 text-center hover:shadow-md transition">
            <div className="text-4xl mb-4">👥</div>
            <h3 className="text-xl font-bold text-navy mb-2">إدارة العملاء</h3>
            <p className="text-text-primary">سجل كامل للعملاء مع إمكانية إضافة كفلاء ووثائق</p>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-6 text-center hover:shadow-md transition">
            <div className="text-4xl mb-4">📦</div>
            <h3 className="text-xl font-bold text-navy mb-2">إدارة المخزون</h3>
            <p className="text-text-primary">تتبع المنتجات والمخزون مع تنقيص تلقائي عند البيع</p>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-6 text-center hover:shadow-md transition">
            <div className="text-4xl mb-4">📱</div>
            <h3 className="text-xl font-bold text-navy mb-2">تطبيق موبايل</h3>
            <p className="text-text-primary">تطبيق Flutter يعمل بدون إنترنت ويتزامن مع السيرفر</p>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-6 text-center hover:shadow-md transition">
            <div className="text-4xl mb-4">🧾</div>
            <h3 className="text-xl font-bold text-navy mb-2">وصلات وطباعة</h3>
            <p className="text-text-primary">طباعة وصلات للعملاء وإرسالها عبر واتساب</p>
          </div>
          
          <div className="bg-white rounded-xl shadow-sm p-6 text-center hover:shadow-md transition">
            <div className="text-4xl mb-4">📈</div>
            <h3 className="text-xl font-bold text-navy mb-2">تقارير مفصلة</h3>
            <p className="text-text-primary">تقارير يومية وشهرية عن الأرباح والمستحقات</p>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-navy py-16 mt-12">
        <div className="max-w-7xl mx-auto px-4 text-center sm:px-6 lg:px-8">
          <h2 className="text-3xl font-bold text-white mb-4">ابدأ الآن مجاناً</h2>
          <p className="text-white/80 mb-8">سجل حسابك اليوم واستمتع بتجربة فريدة في إدارة الأقساط</p>
          <Link 
            href="/activate"
            className="bg-electric hover:bg-blue-600 text-white px-8 py-3 rounded-lg font-medium transition inline-block"
          >
            تفعيل حساب جديد
          </Link>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 py-8">
        <div className="max-w-7xl mx-auto px-4 text-center sm:px-6 lg:px-8">
          <p className="text-text-primary">© 2026 تقسيط برو. جميع الحقوق محفوظة</p>
        </div>
      </footer>
    </div>
  );
}
