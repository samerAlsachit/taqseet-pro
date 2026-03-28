const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { checkSubscription } = require('../middleware/checkSubscription');
const { logAudit } = require('../middleware/audit');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

// GET /api/products
router.get('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    
    // إذا كان المستخدم super_admin (لا يوجد store_id)
    if (!storeId) {
      return res.json({
        success: true,
        data: {
          products: [],
          pagination: { page: 1, limit: 20, total: 0, totalPages: 0 }
        },
        message: 'لا توجد منتجات للمشرف العام'
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const lowStock = req.query.low_stock === 'true';

    let query = supabase
      .from('products')
      .select('*', { count: 'exact' })
      .eq('store_id', storeId);

    if (search) {
      query = query.ilike('name', `%${search}%`);
    }

    const { data: allProducts, error, count } = await query;

    if (error) throw error;

    // فلترة المخزون المنخفض في JavaScript (لأن supabase.raw لا يعمل)
    let products = allProducts || [];
    
    if (lowStock) {
      products = products.filter(p => p.quantity < p.low_stock_alert);
    }

    // Pagination بعد الفلترة
    const paginatedProducts = products.slice(offset, offset + limit);
    const totalCount = products.length;

    res.json({
      success: true,
      data: {
        products: paginatedProducts,
        pagination: {
          page,
          limit,
          total: totalCount,
          totalPages: Math.ceil(totalCount / limit)
        }
      },
      message: 'تم جلب المنتجات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب المنتجات:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/products
router.post('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const {
      name, category, quantity, low_stock_alert,
      cost_price_iqd, cost_price_usd,
      sell_price_cash_iqd, sell_price_cash_usd,
      sell_price_install_iqd, sell_price_install_usd,
      description, currency
    } = req.body;

    if (!name || quantity === undefined) {
      return res.status(400).json({
        success: false,
        error: 'اسم المنتج والكمية مطلوبة',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من سعر البيع حسب العملة
    if (currency === 'IQD') {
      if (!sell_price_cash_iqd || !sell_price_install_iqd) {
        return res.status(400).json({
          success: false,
          error: 'سعر البيع نقداً وبالقسط مطلوبة',
          code: 'VALIDATION_ERROR'
        });
      }
    } else if (currency === 'USD') {
      if (!sell_price_cash_usd || !sell_price_install_usd) {
        return res.status(400).json({
          success: false,
          error: 'سعر البيع نقداً وبالقسط (دولار) مطلوبة',
          code: 'VALIDATION_ERROR'
        });
      }
    }

    const { data: product, error } = await supabase
      .from('products')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        name,
        category: category || '',
        quantity: parseInt(quantity),
        low_stock_alert: low_stock_alert || 5,
        currency: currency || 'IQD',
        cost_price_iqd: cost_price_iqd || 0,
        cost_price_usd: cost_price_usd || 0,
        sell_price_cash_iqd: sell_price_cash_iqd || 0,
        sell_price_cash_usd: sell_price_cash_usd || 0,
        sell_price_install_iqd: sell_price_install_iqd || 0,
        sell_price_install_usd: sell_price_install_usd || 0,
        description: description || '',
        created_by: req.user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('خطأ في إنشاء المنتج:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المنتج',
        code: 'INTERNAL_ERROR'
      });
    }

    res.status(201).json({
      success: true,
      data: product,
      message: 'تم إنشاء المنتج بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'INSERT', 'products', product.id, null, product);
  } catch (error) {
    console.error('خطأ في إنشاء المنتج:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/products/:id
router.get('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;

    const { data: product, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (error || !product) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: 'NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: product,
      message: 'تم جلب المنتج بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب المنتج:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// PUT /api/products/:id
router.put('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;
    const {
      name, category, quantity, low_stock_alert,
      cost_price_iqd, sell_price_cash_iqd, sell_price_install_iqd,
      cost_price_usd, sell_price_cash_usd, sell_price_install_usd,
      description
    } = req.body;

    // جلب البيانات القديمة قبل التحديث
    const { data: oldProduct } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    const { data: product, error } = await supabase
      .from('products')
      .update({
        name,
        category: category || '',
        quantity: parseInt(quantity),
        low_stock_alert: low_stock_alert || 5,
        cost_price_iqd: cost_price_iqd || 0,
        sell_price_cash_iqd: parseInt(sell_price_cash_iqd),
        sell_price_install_iqd: parseInt(sell_price_install_iqd),
        cost_price_usd: cost_price_usd || 0,
        sell_price_cash_usd: sell_price_cash_usd || 0,
        sell_price_install_usd: sell_price_install_usd || 0,
        description: description || '',
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .eq('store_id', storeId)
      .select()
      .single();

    if (error) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: 'NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: product,
      message: 'تم تحديث المنتج بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'UPDATE', 'products', id, oldProduct, product);
  } catch (error) {
    console.error('خطأ في تحديث المنتج:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// DELETE /api/products/:id
router.delete('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;
    
    // التحقق من صلاحية الحذف
    if (!req.user.can_delete) {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح، ليس لديك صلاحية الحذف',
        code: 'FORBIDDEN'
      });
    }

    // التحقق من وجود المنتج في أقساط نشطة
    const { data: usedInInstallments } = await supabase
      .from('installment_plans')
      .select('id')
      .eq('product_id', id)
      .eq('store_id', storeId)
      .eq('status', 'active')
      .limit(1);

    if (usedInInstallments && usedInInstallments.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن حذف منتج مستخدم في أقساط نشطة',
        code: 'PRODUCT_IN_USE'
      });
    }

    // جلب بيانات المنتج قبل الحذف
    const { data: deletedProduct } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id)
      .eq('store_id', storeId);

    if (error) throw error;

    res.json({
      success: true,
      message: 'تم حذف المنتج بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'DELETE', 'products', id, deletedProduct, null);
  } catch (error) {
    console.error('خطأ في حذف المنتج:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
