const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { checkSubscription } = require('../middleware/checkSubscription');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

// GET /api/guarantors
router.get('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { data: guarantors, error } = await supabase
      .from('guarantors')
      .select('*')
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: guarantors || [],
      message: 'تم جلب الكفلاء بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الكفلاء:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/guarantors
router.post('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { full_name, phone, phone_alt, address, national_id, notes } = req.body;

    if (!full_name || !phone) {
      return res.status(400).json({
        success: false,
        error: 'الاسم ورقم الهاتف مطلوبان',
        code: 'VALIDATION_ERROR'
      });
    }

    const { data: guarantor, error } = await supabase
      .from('guarantors')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        full_name,
        phone,
        phone_alt: phone_alt || '',
        address: address || '',
        national_id: national_id || '',
        notes: notes || '',
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      data: guarantor,
      message: 'تم إنشاء الكفيل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في إنشاء الكفيل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
