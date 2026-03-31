const { createClient } = require('@supabase/supabase-js');

// إعدادات الاتصال بقاعدة بيانات Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

// إنشاء عميل Supabase للعميل (anon key)
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// إنشاء عميل Supabase للخادم (service key) - للعمليات التي تتطلب صلاحيات عالية
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

const runMigrations = async () => {
  try {
    // التحقق من وجود سوبر أدمن
    const { data, count } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('role', 'super_admin');
    
    if (count === 0) {
      console.log('⚠️ لا يوجد سوبر أدمن. يرجى إضافته يدوياً أو تشغيل migration.');
    } else {
      console.log(`✅ يوجد ${count} سوبر أدمن في النظام.`);
    }
  } catch (error) {
    console.error('خطأ في التحقق من السوبر أدمن:', error);
  }
};

module.exports = {
  supabase,
  supabaseAdmin,
  runMigrations
};
