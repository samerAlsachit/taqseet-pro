const { supabase } = require('../config/supabase');

const checkSubscription = async (req, res, next) => {
  try {
    const storeId = req.user?.store_id;
    
    if (!storeId) {
      return next();
    }

    const { data: store, error } = await supabase
      .from('stores')
      .select('subscription_end, is_active, trial_end, plan_id')
      .eq('id', storeId)
      .single();

    if (error || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: 'STORE_NOT_FOUND'
      });
    }

    if (!store.is_active) {
      return res.status(403).json({
        success: false,
        error: 'المحل غير نشط، يرجى التواصل مع الدعم',
        code: 'STORE_INACTIVE'
      });
    }

    const now = new Date();
    const endDate = new Date(store.subscription_end);
    
    // التحقق من الفترة التجريبية
    const isTrial = !store.plan_id && store.trial_end;
    const trialEnd = store.trial_end ? new Date(store.trial_end) : null;
    
    if (isTrial && trialEnd && trialEnd < now) {
      return res.status(403).json({
        success: false,
        error: 'انتهت الفترة التجريبية، يرجى الاشتراك للاستمرار',
        code: 'TRIAL_EXPIRED'
      });
    }
    
    // التحقق من الاشتراك المدفوع
    if (!isTrial && endDate < now) {
      return res.status(403).json({
        success: false,
        error: 'انتهى اشتراكك، يرجى التجديد',
        code: 'SUBSCRIPTION_EXPIRED'
      });
    }

    // إضافة معلومات الفترة التجريبية إلى req
    req.subscription = {
      is_trial: isTrial,
      trial_days_remaining: isTrial && trialEnd ? Math.ceil((trialEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)) : 0,
      subscription_days_remaining: !isTrial ? Math.ceil((endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)) : 0
    };

    next();
  } catch (error) {
    console.error('خطأ في التحقق من الاشتراك:', error);
    next(error);
  }
};

const checkCustomerLimit = async (storeId) => {
  const { data: store } = await supabase
    .from('stores')
    .select('plan_id')
    .eq('id', storeId)
    .single();
  
  if (!store.plan_id) return true; // فترة تجريبية
  
  const { data: plan } = await supabase
    .from('subscription_plans')
    .select('max_customers')
    .eq('id', store.plan_id)
    .single();
  
  const { count } = await supabase
    .from('customers')
    .select('*', { count: 'exact', head: true })
    .eq('store_id', storeId);
  
  return count < plan.max_customers;
};

const checkEmployeeLimit = async (storeId) => {
  const { data: store } = await supabase
    .from('stores')
    .select('plan_id')
    .eq('id', storeId)
    .single();
  
  if (!store.plan_id) return true;
  
  const { data: plan } = await supabase
    .from('subscription_plans')
    .select('max_employees')
    .eq('id', store.plan_id)
    .single();
  
  const { count } = await supabase
    .from('users')
    .select('*', { count: 'exact', head: true })
    .eq('store_id', storeId);
  
  return count <= plan.max_employees;
};

module.exports = { checkSubscription, checkCustomerLimit, checkEmployeeLimit };
