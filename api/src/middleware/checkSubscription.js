const { supabase } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES, SUBSCRIPTION_STATUS } = require('../config/constants');
const moment = require('moment');

/**
 * middleware للتحقق من صلاحية اشتراك المحل
 */
const checkSubscription = async (req, res, next) => {
  try {
    if (!req.user || !req.user.store_id) {
      return res.status(401).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.UNAUTHORIZED],
        code: ERROR_CODES.UNAUTHORIZED
      });
    }

    const storeId = req.user.store_id;

    // جلب بيانات المحل أولاً
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('subscription_end, subscription_start, plan_id')
      .eq('id', storeId)
      .single();

    if (storeError || !store) {
      console.error('خطأ في جلب بيانات المحل:', storeError);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    let plan = null;
    if (store.plan_id) {
      // جلب تفاصيل الخطة إذا كانت موجودة
      const { data: planData, error: planError } = await supabase
        .from('subscription_plans')
        .select('name, duration_days')
        .eq('id', store.plan_id)
        .single();

      if (planError) {
        console.error('خطأ في جلب بيانات الخطة:', planError);
      } else {
        plan = planData;
      }
    }

    // حساب الأيام المتبقية
    const daysRemaining = Math.ceil((new Date(store.subscription_end) - new Date()) / (1000 * 60 * 60 * 24));

    // التحقق من انتهاء الاشتراك
    if (daysRemaining <= 0) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.SUBSCRIPTION_EXPIRED],
        code: ERROR_CODES.SUBSCRIPTION_EXPIRED
      });
    }

    let response = null;

    // التحقق من المدة المتبقية (أقل من 7 أيام)
    if (daysRemaining <= 7 && daysRemaining > 0) {
      // إضافة تحذير للاستجابة
      response = {
        success: true,
        data: null,
        warning: `ينتهي اشتراكك خلال ${daysRemaining} ${daysRemaining === 1 ? 'يوم' : 'أيام'}`
      };
    }

    // إضافة بيانات الاشتراك للطلب
    req.subscription = {
      store,
      plan,
      daysRemaining
    };

    if (response) {
      // إذا كان هناك تحذير، نمرر البيانات للmiddleware التالي
      req.subscriptionWarning = response.warning;
    }

    next();
  } catch (error) {
    console.error('خطأ في التحقق من الاشتراك:', error);
    return res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = checkSubscription;
