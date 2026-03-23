const { createClient } = require('@supabase/supabase-js');

// إعدادات الاتصال بقاعدة بيانات Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

// إنشاء عميل Supabase للعميل (anon key)
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// إنشاء عميل Supabase للخادم (service key) - للعمليات التي تتطلب صلاحيات عالية
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

module.exports = {
  supabase,
  supabaseAdmin
};
