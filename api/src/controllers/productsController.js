const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { v4: uuidv4 } = require('uuid');

const getProducts = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { search, category, low_stock, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const limitNum = parseInt(limit);

    let query = supabase
      .from('products')
      .select('*', { count: 'exact' })
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    if (search) {
      query = query.or(`name.ilike.%${search}%,sku.ilike.%${search}%,description.ilike.%${search}%`);
    }
    if (category) {
      query = query.eq('category', category);
    }

    const { data: products, error, count } = await query.range(offset, offset + limitNum - 1);

    if (error) {
      console.error('خطأ في جلب المنتجات:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // إضافة تحذيرات المخزون المنخفض
    const productsWithWarnings = (products || []).map(product => ({
      ...product,
      low_stock_warning: product.quantity <= (product.low_stock_alert || 5)
    }));

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      success: true,
      data: {
        products: productsWithWarnings,
        total: count || 0,
        page: parseInt(page),
        totalPages,
        limit: limitNum
      },
      message: 'تم جلب قائمة المنتجات بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب المنتجات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

const createProduct = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const {
      name,
      sell_price_cash_iqd,
      sell_price_install_iqd,
      cost_price_iqd,
      quantity,
      category,
      sku,
      description,
      sell_price_cash_usd,
      sell_price_install_usd,
      cost_price_usd,
      low_stock_alert
    } = req.body;

    if (!name || !sell_price_cash_iqd || !sell_price_install_iqd || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'الاسم وسعر البيع والكمية مطلوبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    if (quantity < 0 || sell_price_cash_iqd < 0 || sell_price_install_iqd < 0) {
      return res.status(400).json({
        success: false,
        error: 'الكميات والأسعار يجب أن تكون أرقام موجبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const { data: product, error } = await supabaseAdmin
      .from('products')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        name,
        sell_price_cash_iqd,
        sell_price_install_iqd,
        cost_price_iqd: cost_price_iqd || 0,
        quantity,
        category: category || '',
        sku: sku || '',
        description: description || '',
        sell_price_cash_usd: sell_price_cash_usd || 0,
        sell_price_install_usd: sell_price_install_usd || 0,
        cost_price_usd: cost_price_usd || 0,
        low_stock_alert: low_stock_alert || 5,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('خطأ في إنشاء المنتج:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المنتج',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'create_product',
        entity_type: 'product',
        entity_id: product.id,
        new_data: product,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.status(201).json({
      success: true,
      data: product,
      message: 'تم إنشاء المنتج بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إنشاء المنتج:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

const updateProduct = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;
    const updateData = req.body;

    if (!req.user.can_edit) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    const { data: currentProduct, error: fetchError } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (fetchError || !currentProduct) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    updateData.updated_at = new Date().toISOString();

    const { data: updatedProduct, error } = await supabaseAdmin
      .from('products')
      .update(updateData)
      .eq('id', id)
      .eq('store_id', storeId)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث المنتج:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث المنتج',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'update_product',
        entity_type: 'product',
        entity_id: id,
        old_data: currentProduct,
        new_data: updatedProduct,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: updatedProduct,
      message: 'تم تحديث المنتج بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تحديث المنتج:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

const deleteProduct = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;

    if (!req.user.can_delete) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    const { data: product, error: fetchError } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (fetchError || !product) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    const { data: activePlans, error: plansError } = await supabase
      .from('installment_plans')
      .select('id')
      .eq('store_id', storeId)
      .eq('product_id', id)
      .in('status', ['active', 'pending'])
      .limit(1);

    if (plansError) {
      console.error('خطأ في التحقق من خطط الأقساط:', plansError);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    if (activePlans && activePlans.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن حذف منتج مستخدم في خطة قسط نشطة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const { error: deleteError } = await supabaseAdmin
      .from('products')
      .delete()
      .eq('id', id)
      .eq('store_id', storeId);

    if (deleteError) {
      console.error('خطأ في حذف المنتج:', deleteError);
      return res.status(500).json({
        success: false,
        error: 'فشل في حذف المنتج',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'delete_product',
        entity_type: 'product',
        entity_id: id,
        old_data: product,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: null,
      message: 'تم حذف المنتج بنجاح'
    });

  } catch (error) {
    console.error('خطأ في حذف المنتج:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

const updateStock = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;
    const { quantity, operation, reason } = req.body;

    if (!quantity || !operation || !['add', 'subtract'].includes(operation)) {
      return res.status(400).json({
        success: false,
        error: 'الكمية والعملية مطلوبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const { data: product, error: fetchError } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (fetchError || !product) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    const oldQuantity = product.quantity;
    let newQuantity;

    if (operation === 'add') {
      newQuantity = oldQuantity + quantity;
    } else {
      newQuantity = oldQuantity - quantity;
      if (newQuantity < 0) {
        return res.status(400).json({
          success: false,
          error: 'الكمية الناتجة سلبية',
          code: ERROR_CODES.VALIDATION_ERROR
        });
      }
    }

    const { data: updatedProduct, error } = await supabaseAdmin
      .from('products')
      .update({ quantity: newQuantity, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('store_id', storeId)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث المخزون:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث المخزون',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'update_stock',
        entity_type: 'product',
        entity_id: id,
        old_data: { quantity: oldQuantity },
        new_data: { quantity: newQuantity, operation, reason },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: updatedProduct,
      message: `تم ${operation === 'add' ? 'إضافة' : 'خصم'} ${quantity} من المخزون بنجاح`
    });

  } catch (error) {
    console.error('خطأ في تحديث المخزون:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  getProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  updateStock
};
