-- إضافة سوبر أدمن أول إذا لم يكن موجوداً
-- كلمة المرور: Super@12345 (مشفر بـ bcrypt)

INSERT INTO users (
  id,
  username,
  password_hash,
  full_name,
  phone,
  role,
  can_delete,
  can_edit,
  can_view_reports,
  is_active,
  created_at
)
SELECT 
  gen_random_uuid(),
  'superadmin',
  '$2b$10$rQvK5kqXqLzX5y5qXqLzX5y5qXqLzX5y5qXqLzX5y5qXqLzX5y5qXqLzX5y',
  'مدير النظام',
  '07700000000',
  'super_admin',
  true,
  true,
  true,
  true,
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE role = 'super_admin'
);

-- إضافة رسالة في سجل العمليات
INSERT INTO audit_logs (id, user_id, action, table_name, new_data, created_at)
SELECT 
  gen_random_uuid(),
  NULL,
  'SYSTEM_SEED',
  'users',
  jsonb_build_object('message', 'تم إنشاء السوبر أدمن الأول تلقائياً'),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE role = 'super_admin'
);
