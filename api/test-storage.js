const { createClient } = require('@supabase/supabase-js');

// ضع الـ key مباشرة بدون أي نص عربي
const supabaseAdmin = createClient(
  'https://sdygpgchcyxkgqmswgyb.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWdwZ2NoY3l4a2dxbXN3Z3liIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDI4MzgxNSwiZXhwIjoyMDg5ODU5ODE1fQ.uhS-1QEEZzMbCueAl_oif3c2YQ4x-XPtgzwGZW0bPQ0'
);

const test = async () => {
  console.log('🔍 اختبار الاتصال...');
  
  const { data: buckets, error: bucketsError } = await supabaseAdmin.storage.listBuckets();
  console.log('البكتات:', buckets?.map(b => b.name));
  if (bucketsError) console.error('خطأ البكتات:', bucketsError.message);

  const { data, error } = await supabaseAdmin
    .storage
    .from('backups')
    .upload('test-file.json', '{"test": true}', {
      contentType: 'application/json',
      upsert: true
    });

  if (error) console.error('خطأ الرفع:', error.message);
  else console.log('✅ تم الرفع بنجاح:', data.path);
};

test();