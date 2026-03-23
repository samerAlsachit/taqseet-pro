const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { v4: uuidv4 } = require('uuid');

/**
 * إنشاء كفيل جديد
 */
const createGuarantor = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const {
      full_name,
      phone,
      phone_alt,
      address,
      national_id,
      notes,
      id_doc_url,
      extra_docs,
      local_id
    } = req.body;

    // التحقق من الحقول المطلوبة
    if (!full_name || !phone) {
      return res.status(400).json({
        success: false,
        error: 'الاسم الكامل ورقم الهاتف مطلوبان',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // التحقق من عدم تكرار رقم الهاتف في نفس المحل
    const { data: existingGuarantor, error: checkError } = await supabase
      .from('guarantors')
      .select('id')
      .eq('store_id', storeId)
      .eq('phone', phone)
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      console.error('خطأ في التحقق من الكفيل:', checkError);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    if (existingGuarantor) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مسجل بالفعل في هذا المحل',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // إنشاء الكفيل الجديد
    const { data: guarantor, error } = await supabaseAdmin
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
        id_doc_url: id_doc_url || '',
        extra_docs: extra_docs || [],
        local_id: local_id || null,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('خطأ في إنشاء الكفيل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الكفيل',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // تسجيل العملية في سجل التدقيق
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'create_guarantor',
        entity_type: 'guarantor',
        entity_id: guarantor.id,
        new_data: guarantor,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.status(201).json({
      success: true,
      data: guarantor,
      message: 'تم إنشاء الكفيل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إنشاء الكفيل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب بيانات كفيل محدد
 */
const getGuarantor = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;

    // جلب بيانات الكفيل
    const { data: guarantor, error } = await supabase
      .from('guarantors')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (error || !guarantor) {
      return res.status(404).json({
        success: false,
        error: 'الكفيل غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // جلب قائمة العملاء الذين يكفلهم هذا الكفيل
    const { data: guaranteedCustomers, error: customersError } = await supabase
      .from('installment_plans')
      .select(`
        customer_id,
        customers (
          id,
          full_name,
          phone
        )
      `)
      .eq('guarantor_id', id)
      .eq('store_id', storeId);

    if (customersError) {
      console.error('خطأ في جلب العملاء المكفولين:', customersError);
    }

    res.json({
      success: true,
      data: {
        guarantor,
        guaranteed_customers: guaranteedCustomers || []
      },
      message: 'تم جلب بيانات الكفيل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب بيانات الكفيل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * تحديث بيانات كفيل
 */
const updateGuarantor = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;
    const {
      full_name,
      phone,
      phone_alt,
      address,
      national_id,
      notes,
      id_doc_url,
      extra_docs
    } = req.body;

    // التحقق من الصلاحية
    if (!req.user.can_edit) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    // جلب بيانات الكفيل الحالية
    const { data: currentGuarantor, error: fetchError } = await supabase
      .from('guarantors')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (fetchError || !currentGuarantor) {
      return res.status(404).json({
        success: false,
        error: 'الكفيل غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // التحقق من عدم تكرار رقم الهاتف (إذا تم تغييره)
    if (phone && phone !== currentGuarantor.phone) {
      const { data: existingGuarantor, error: checkError } = await supabase
        .from('guarantors')
        .select('id')
        .eq('store_id', storeId)
        .eq('phone', phone)
        .neq('id', id)
        .single();

      if (checkError && checkError.code !== 'PGRST116') {
        console.error('خطأ في التحقق من الكفيل:', checkError);
        return res.status(500).json({
          success: false,
          error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
          code: ERROR_CODES.INTERNAL_ERROR
        });
      }

      if (existingGuarantor) {
        return res.status(400).json({
          success: false,
          error: 'رقم الهاتف مسجل بالفعل في هذا المحل',
          code: ERROR_CODES.VALIDATION_ERROR
        });
      }
    }

    // تحديث بيانات الكفيل
    const updateData = {
      full_name: full_name || currentGuarantor.full_name,
      phone: phone || currentGuarantor.phone,
      phone_alt: phone_alt !== undefined ? phone_alt : currentGuarantor.phone_alt,
      address: address !== undefined ? address : currentGuarantor.address,
      national_id: national_id !== undefined ? national_id : currentGuarantor.national_id,
      notes: notes !== undefined ? notes : currentGuarantor.notes,
      id_doc_url: id_doc_url !== undefined ? id_doc_url : currentGuarantor.id_doc_url,
      extra_docs: extra_docs !== undefined ? extra_docs : currentGuarantor.extra_docs,
      updated_at: new Date().toISOString()
    };

    const { data: updatedGuarantor, error } = await supabaseAdmin
      .from('guarantors')
      .update(updateData)
      .eq('id', id)
      .eq('store_id', storeId)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث الكفيل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث الكفيل',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // تسجيل العملية في سجل التدقيق
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'update_guarantor',
        entity_type: 'guarantor',
        entity_id: id,
        old_data: currentGuarantor,
        new_data: updatedGuarantor,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: updatedGuarantor,
      message: 'تم تحديث بيانات الكفيل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تحديث الكفيل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب قائمة الكفلاء
 */
const getGuarantors = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { search = '', page = 1, limit = 20 } = req.query;

    // حساب الإزاحة للصفحة
    const offset = (page - 1) * limit;
    const limitNum = parseInt(limit);

    // بناء الاستعلام
    let query = supabase
      .from('guarantors')
      .select('*', { count: 'exact' })
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    // إضافة البحث إذا وجد
    if (search) {
      query = query.or(`full_name.ilike.%${search}%,phone.ilike.%${search}%,phone_alt.ilike.%${search}%`);
    }

    // تطبيق الصفحة
    query = query.range(offset, offset + limitNum - 1);

    const { data: guarantors, error, count } = await query;

    if (error) {
      console.error('خطأ في جلب الكفلاء:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // حساب عدد الصفحات
    const totalPages = Math.ceil(count / limitNum);

    res.json({
      success: true,
      data: {
        guarantors: guarantors || [],
        total: count || 0,
        page: parseInt(page),
        totalPages,
        limit: limitNum
      },
      message: 'تم جلب قائمة الكفلاء بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب الكفلاء:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  createGuarantor,
  getGuarantor,
  updateGuarantor,
  getGuarantors
};
