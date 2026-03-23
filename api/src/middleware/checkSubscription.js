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

    // جلب بيانات اشتراك المحل
    const { data: subscription, error } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('store_id', storeId)
      .eq('status', SUBSCRIPTION_STATUS.ACTIVE)
      .single();

    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('خطأ في جلب بيانات الاشتراك:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // التحقق من وجود اشتراك فعال
    if (!subscription) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.SUBSCRIPTION_EXPIRED],
        code: ERROR_CODES.SUBSCRIPTION_EXPIRED
      });
    }

    // التحقق من تاريخ انتهاء الاشتراك
    const now = moment();
    const endDate = moment(subscription.end_date);

    if (now.isAfter(endDate)) {
      // تحديث حالة الاشتراك إلى منتهي
      await supabase
        .from('subscriptions')
        .update({ status: SUBSCRIPTION_STATUS.EXPIRED })
        .eq('id', subscription.id);

      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.SUBSCRIPTION_EXPIRED],
        code: ERROR_CODES.SUBSCRIPTION_EXPIRED
      });
    }

    // التحقق من المدة المتبقية (أقل من 7 أيام)
    const daysRemaining = endDate.diff(now, 'days');
    let response = null;

    if (daysRemaining <= 7 && daysRemaining > 0) {
      // إضافة تحذير للاستجابة
      response = {
        success: true,
        data: null,
        warning: `ينتهي اشتراكك خلال ${daysRemaining} ${daysRemaining === 1 ? 'يوم' : 'أيام'}`
      };
    }

    // إضافة بيانات الاشتراك للطلب
    req.subscription = subscription;

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
