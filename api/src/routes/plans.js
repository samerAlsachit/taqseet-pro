const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// GET /api/plans - عام (بدون مصادقة)
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('is_active', true)
      .order('duration_days');

    if (error) throw error;

    res.json({
      success: true,
      data: data || [],
      message: 'تم جلب الخطط بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الخطط:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
