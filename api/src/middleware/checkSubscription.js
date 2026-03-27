const { supabase } = require('../config/supabase');

const checkSubscription = async (req, res, next) => {
  try {
    const storeId = req.user?.store_id;
    
    if (!storeId) {
      return next();
    }

    const { data: store, error } = await supabase
      .from('stores')
      .select('subscription_end, is_active')
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
    
    if (endDate < now) {
      return res.status(403).json({
        success: false,
        error: 'انتهى اشتراكك، يرجى التجديد',
        code: 'SUBSCRIPTION_EXPIRED'
      });
    }

    next();
  } catch (error) {
    console.error('خطأ في التحقق من الاشتراك:', error);
    next(error);
  }
};

module.exports = { checkSubscription };
