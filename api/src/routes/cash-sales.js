const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');
const { logAudit } = require('../middleware/audit');

// تعريف checkSubscription مؤقتاً في هذا الملف
const checkSubscription = async (req, res, next) => {
  // super_admin يمر بدون تحقق
  if (req.user?.role === 'super_admin') {
    return next();
  }
  
  const storeId = req.user?.store_id;
  if (!storeId) return next();
  
  // باقي التحقق...
  next();
};

// GET /api/cash-sales - جلب المبيعات النقدية
router.get('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    
    const { data, error, count } = await supabase
      .from('cash_sales')
      .select(`
        *,
        customers:customer_id (full_name, phone),
        products:product_id (name, currency)
      `, { count: 'exact' })
      .eq('store_id', storeId)
      .range(offset, offset + limit - 1)
      .order('sale_date', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: {
        sales: data || [],
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      },
      message: 'تم جلب المبيعات النقدية بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب المبيعات النقدية:', error);
    res.status(500).json({ success: false, error: 'حدث خطأ في الخادم' });
  }
});

// POST /api/cash-sales - إضافة بيع نقدي
router.post('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { customer_id, product_id, quantity, price, currency, sale_date, notes } = req.body;

    if (!product_id || !quantity || !price) {
      return res.status(400).json({
        success: false,
        error: 'المنتج والكمية والسعر مطلوبة',
        code: 'VALIDATION_ERROR'
      });
    }

    // جلب المنتج
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('*')
      .eq('id', product_id)
      .eq('store_id', storeId)
      .single();

    if (productError || !product) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: 'NOT_FOUND'
      });
    }

    if (product.quantity < quantity) {
      return res.status(400).json({
        success: false,
        error: 'الكمية المطلوبة غير متوفرة في المخزون',
        code: 'INSUFFICIENT_STOCK'
      });
    }

    // حساب سعر الشراء والربح
    const costPrice = currency === 'IQD' ? product.cost_price_iqd : product.cost_price_usd;
    const profit = (price - costPrice) * quantity;

    // إنشاء رقم وصل
    const receiptNumber = `CSH-${storeId.slice(0, 8)}-${Date.now()}`;

    // إدراج البيع
    const { data: sale, error } = await supabase
      .from('cash_sales')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        customer_id: customer_id || null,
        product_id,
        quantity,
        price,
        cost_price: costPrice,
        profit,
        currency: currency || 'IQD',
        sale_date: sale_date || new Date().toISOString().split('T')[0],
        notes: notes || '',
        receipt_number: receiptNumber,
        created_by: req.user.id,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    // تنقيص المخزون
    await supabase
      .from('products')
      .update({ quantity: product.quantity - quantity })
      .eq('id', product_id);

    await logAudit(req, 'INSERT', 'cash_sales', sale.id, null, sale);

    res.status(201).json({
      success: true,
      data: sale,
      message: 'تم تسجيل البيع النقدي بنجاح'
    });
  } catch (error) {
    console.error('خطأ في تسجيل البيع النقدي:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/cash-sales/receipt/:id
router.get('/receipt/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;

    const { data: sale, error } = await supabase
      .from('cash_sales')
      .select(`
        *,
        customers:customer_id (full_name, phone),
        products:product_id (name, currency)
      `)
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (error || !sale) {
      return res.status(404).json({ success: false, error: 'البيع غير موجود' });
    }

    if (!sale.product_id) {
      return res.status(400).json({ success: false, error: 'البيع غير مرتبط بمنتج' });
    }

    const { data: store } = await supabase
      .from('stores')
      .select('name, phone, address, receipt_header, receipt_footer')
      .eq('id', storeId)
      .single();

    res.json({
      success: true,
      data: { sale, store },
      message: 'تم جلب بيانات الوصل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الوصل:', error);
    res.status(500).json({ success: false, error: 'حدث خطأ في الخادم' });
  }
});

module.exports = router;
