const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { supabase } = require('../config/supabase');

// GET /api/store/settings
router.get('/settings', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    
    if (!storeId) {
      return res.status(400).json({
        success: false,
        error: 'لا يوجد محل مرتبط بهذا المستخدم',
        code: 'NO_STORE'
      });
    }

    const { data: store, error } = await supabase
      .from('stores')
      .select('id, name, owner_name, phone, address, city, logo_url, receipt_header, receipt_footer, default_currency, subscription_start, subscription_end, is_active')
      .eq('id', storeId)
      .single();

    if (error || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: 'NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: store,
      message: 'تم جلب إعدادات المحل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب إعدادات المحل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// PUT /api/store/settings
router.put('/settings', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { name, owner_name, phone, address, city, receipt_header, receipt_footer, default_currency } = req.body;

    if (!storeId) {
      return res.status(400).json({
        success: false,
        error: 'لا يوجد محل مرتبط بهذا المستخدم',
        code: 'NO_STORE'
      });
    }

    const { data: store, error } = await supabase
      .from('stores')
      .update({
        name: name || undefined,
        owner_name: owner_name || undefined,
        phone: phone || undefined,
        address: address || '',
        city: city || '',
        receipt_header: receipt_header || '',
        receipt_footer: receipt_footer || '',
        default_currency: req.body.default_currency || 'IQD',
        updated_at: new Date().toISOString()
      })
      .eq('id', storeId)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث إعدادات المحل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث الإعدادات',
        code: 'INTERNAL_ERROR'
      });
    }

    res.json({
      success: true,
      data: store,
      message: 'تم تحديث إعدادات المحل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في تحديث إعدادات المحل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
