const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { v4: uuidv4 } = require('uuid');

/**
 * جلب قائمة العملاء
 */
const getCustomers = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { search = '', page = 1, limit = 20 } = req.query;

    // حساب الإزاحة للصفحة
    const offset = (page - 1) * limit;
    const limitNum = parseInt(limit);

    // بناء الاستعلام
    let query = supabase
      .from('customers')
      .select('*', { count: 'exact' })
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    // إضافة البحث إذا وجد
    if (search) {
      query = query.or(`full_name.ilike.%${search}%,phone.ilike.%${search}%,phone_alt.ilike.%${search}%`);
    }

    // تطبيق الصفحة
    query = query.range(offset, offset + limitNum - 1);

    const { data: customers, error, count } = await query;

    if (error) {
      console.error('خطأ في جلب العملاء:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // حساب عدد الصفحات
    const totalPages = Math.ceil(count / limitNum);

    // ✅ Parse extra_docs if stored as JSON string and ensure it's an array
    const processedCustomers = customers?.map(customer => {
      let extraDocs = customer.extra_docs;
      if (typeof extraDocs === 'string') {
        try {
          extraDocs = JSON.parse(extraDocs);
        } catch (e) {
          console.warn('⚠️ Failed to parse extra_docs for customer:', customer.id);
          extraDocs = [];
        }
      }
      if (!Array.isArray(extraDocs)) {
        extraDocs = extraDocs ? [extraDocs] : [];
      }
      return {
        ...customer,
        extra_docs: extraDocs
      };
    }) || [];

    // ✅ Log first customer to verify extra_docs
    if (processedCustomers.length > 0) {
      console.log('📤 [GET /customers] Pulled', processedCustomers.length, 'customers');
      console.log('📤 [GET /customers] Sample:', {
        id: processedCustomers[0].id,
        extra_docs: processedCustomers[0].extra_docs,
        extra_docs_count: processedCustomers[0].extra_docs?.length || 0
      });
    }

    res.json({
      success: true,
      data: {
        customers: processedCustomers,
        total: count || 0,
        page: parseInt(page),
        totalPages,
        limit: limitNum
      },
      message: 'تم جلب قائمة العملاء بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب العملاء:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * إنشاء عميل جديد
 */
const createCustomer = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const {
      id,  // ✅ قبول ID من الموبايل (اختياري)
      full_name,
      phone,
      phone_alt,
      address,
      national_id,
      notes,
      id_doc_url,
      extra_docs,
      documents_urls,  // ← من الموبايل
      local_id
    } = req.body;

    // ✅ استخدام documents_urls من الموبايل إذا لم يكن extra_docs موجوداً
    const finalExtraDocs = extra_docs || documents_urls || [];

    // التحقق من الحقول المطلوبة
    if (!full_name || !phone) {
      return res.status(400).json({
        success: false,
        error: 'الاسم الكامل ورقم الهاتف مطلوبان',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // ✅ Log incoming data for debugging
    console.log('🔥 [API] Creating customer:', {
      id: id || '(will generate)',
      full_name,
      phone,
      id_doc_url: id_doc_url || '(none)',
      extra_docs: finalExtraDocs?.length || 0,
      extra_docs_type: typeof finalExtraDocs,
      extra_docs_sample: finalExtraDocs?.slice(0, 2),
      source: extra_docs ? 'extra_docs' : (documents_urls ? 'documents_urls' : 'none')
    });

    // التحقق من عدم تكرار رقم الهاتف في نفس المحل
    const { data: existingCustomer, error: checkError } = await supabase
      .from('customers')
      .select('id')
      .eq('store_id', storeId)
      .eq('phone', phone)
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      console.error('خطأ في التحقق من العميل:', checkError);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    if (existingCustomer) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مسجل بالفعل في هذا المحل',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // ✅ استخدام ID من الموبايل أو توليد جديد
    const customerId = id || uuidv4();
    if (id) {
      console.log('✅ [API] Using mobile-provided ID:', customerId);
    } else {
      console.log('⚠️ [API] No ID from mobile, generated new ID:', customerId);
    }

    // ✅ تحويل extra_docs إلى نص JSON لـ PostgreSQL JSONB
    const extraDocsForDb = finalExtraDocs.length > 0 ? JSON.stringify(finalExtraDocs) : '[]';
    console.log('🔥 [API] extra_docs for DB:', extraDocsForDb);

    // إنشاء العميل الجديد
    const { data: customer, error } = await supabaseAdmin
      .from('customers')
      .insert({
        id: customerId,
        store_id: storeId,
        full_name,
        phone,
        phone_alt: phone_alt || '',
        address: address || '',
        national_id: national_id || '',
        notes: notes || '',
        id_doc_url: id_doc_url || '',
        extra_docs: extraDocsForDb,  // ✅ JSON string for PostgreSQL
        local_id: local_id || null,
        created_at: new Date().toISOString()
      })
      .select('*')  // ✅ تأكد من إرجاع جميع الحقول
      .single();

    if (error) {
      console.error('❌ [API] خطأ في إنشاء العميل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء العميل',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // ✅ Parse extra_docs if it's a JSON string from PostgreSQL
    let parsedExtraDocs = customer.extra_docs;
    if (typeof customer.extra_docs === 'string') {
      try {
        parsedExtraDocs = JSON.parse(customer.extra_docs);
      } catch (e) {
        console.warn('⚠️ Failed to parse extra_docs for response:', customer.id);
        parsedExtraDocs = [];
      }
    }
    if (!Array.isArray(parsedExtraDocs)) {
      parsedExtraDocs = parsedExtraDocs ? [parsedExtraDocs] : [];
    }

    // ✅ Create response customer object with parsed extra_docs
    const responseCustomer = {
      ...customer,
      extra_docs: parsedExtraDocs  // ✅ Array for mobile client
    };

    // ✅ Log saved customer data to verify id_doc_url and extra_docs
    console.log('✅ [API] Customer created successfully:', {
      id: customer.id,
      id_doc_url: customer.id_doc_url,
      extra_docs: responseCustomer.extra_docs,
      extra_docs_count: responseCustomer.extra_docs?.length || 0,
      extra_docs_type: typeof responseCustomer.extra_docs
    });

    // تسجيل العملية في سجل التدقيق
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'create_customer',
        entity_type: 'customer',
        entity_id: customer.id,
        new_data: customer,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.status(201).json({
      success: true,
      data: responseCustomer,  // ✅ Send parsed customer data
      message: 'تم إنشاء العميل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إنشاء العميل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب بيانات عميل محدد
 */
const getCustomer = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;

    // جلب بيانات العميل
    const { data: customer, error: customerError } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (customerError || !customer) {
      return res.status(404).json({
        success: false,
        error: 'العميل غير موجود',
        code: ERROR_CODES.CUSTOMER_NOT_FOUND
      });
    }

    // جلب خطط الأقساط للعميل
    const { data: installmentPlans, error: plansError } = await supabase
      .from('installment_plans')
      .select(`
        *,
        installments (
          id,
          amount,
          due_date,
          status,
          paid_amount,
          paid_at
        )
      `)
      .eq('customer_id', id)
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    if (plansError) {
      console.error('خطأ في جلب خطط الأقساط:', plansError);
    }

    // حساب ملخص الأقساط
    let totalDebt = 0;
    let totalPaid = 0;
    let activeInstallments = 0;
    let overdueInstallments = 0;

    if (installmentPlans) {
      installmentPlans.forEach(plan => {
        if (plan.installments) {
          plan.installments.forEach(installment => {
            totalDebt += installment.amount;
            totalPaid += installment.paid_amount || 0;
            
            if (installment.status === 'pending') {
              activeInstallments++;
            } else if (installment.status === 'overdue') {
              activeInstallments++;
              overdueInstallments++;
            }
          });
        }
      });
    }

    res.json({
      success: true,
      data: {
        customer,
        installment_plans: installmentPlans || [],
        summary: {
          total_debt: totalDebt,
          total_paid: totalPaid,
          remaining_balance: totalDebt - totalPaid,
          active_installments: activeInstallments,
          overdue_installments: overdueInstallments
        }
      },
      message: 'تم جلب بيانات العميل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب بيانات العميل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * تحديث بيانات عميل
 */
const updateCustomer = async (req, res) => {
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
      extra_docs,
      documents_urls  // ← من الموبايل
    } = req.body;

    // ✅ استخدام documents_urls من الموبايل إذا أُرسل
    const finalExtraDocs = documents_urls || extra_docs;

    // ✅ Log incoming update data
    console.log('🔥 [API] Updating customer:', {
      id,
      id_doc_url: id_doc_url || '(unchanged)',
      extra_docs: finalExtraDocs?.length || '(unchanged)',
      source: documents_urls ? 'documents_urls' : (extra_docs ? 'extra_docs' : 'none'),
      national_id: national_id || '(unchanged)'
    });

    // التحقق من الصلاحية
    if (!req.user.can_edit) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    // جلب بيانات العميل الحالية
    const { data: currentCustomer, error: fetchError } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (fetchError || !currentCustomer) {
      return res.status(404).json({
        success: false,
        error: 'العميل غير موجود',
        code: ERROR_CODES.CUSTOMER_NOT_FOUND
      });
    }

    // التحقق من عدم تكرار رقم الهاتف (إذا تم تغييره)
    if (phone && phone !== currentCustomer.phone) {
      const { data: existingCustomer, error: checkError } = await supabase
        .from('customers')
        .select('id')
        .eq('store_id', storeId)
        .eq('phone', phone)
        .neq('id', id)
        .single();

      if (checkError && checkError.code !== 'PGRST116') {
        console.error('خطأ في التحقق من العميل:', checkError);
        return res.status(500).json({
          success: false,
          error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
          code: ERROR_CODES.INTERNAL_ERROR
        });
      }

      if (existingCustomer) {
        return res.status(400).json({
          success: false,
          error: 'رقم الهاتف مسجل بالفعل في هذا المحل',
          code: ERROR_CODES.VALIDATION_ERROR
        });
      }
    }

    // تحديث بيانات العميل
    // ✅ تحويل extra_docs إلى نص JSON إذا كان يتم تحديثه
    const extraDocsForDb = finalExtraDocs !== undefined && finalExtraDocs !== null
      ? JSON.stringify(finalExtraDocs)
      : currentCustomer.extra_docs;

    const updateData = {
      full_name: full_name || currentCustomer.full_name,
      phone: phone || currentCustomer.phone,
      phone_alt: phone_alt !== undefined ? phone_alt : currentCustomer.phone_alt,
      address: address !== undefined ? address : currentCustomer.address,
      national_id: national_id !== undefined ? national_id : currentCustomer.national_id,
      notes: notes !== undefined ? notes : currentCustomer.notes,
      id_doc_url: id_doc_url !== undefined ? id_doc_url : currentCustomer.id_doc_url,
      extra_docs: extraDocsForDb,  // ✅ JSON string for PostgreSQL
      updated_at: new Date().toISOString()
    };

    const { data: updatedCustomer, error } = await supabaseAdmin
      .from('customers')
      .update(updateData)
      .eq('id', id)
      .eq('store_id', storeId)
      .select()
      .single();

    if (error) {
      console.error('❌ [API] خطأ في تحديث العميل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث العميل',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // ✅ Log updated customer data
    console.log('✅ [API] Customer updated successfully:', {
      id: updatedCustomer.id,
      id_doc_url: updatedCustomer.id_doc_url,
      extra_docs_count: updatedCustomer.extra_docs?.length || 0
    });

    // تسجيل العملية في سجل التدقيق
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'update_customer',
        entity_type: 'customer',
        entity_id: id,
        old_data: currentCustomer,
        new_data: updatedCustomer,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: updatedCustomer,
      message: 'تم تحديث بيانات العميل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تحديث العميل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * حذف عميل
 */
const deleteCustomer = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;

    // التحقق من الصلاحية
    if (!req.user.can_delete) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    // جلب بيانات العميل
    const { data: customer, error: fetchError } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (fetchError || !customer) {
      return res.status(404).json({
        success: false,
        error: 'العميل غير موجود',
        code: ERROR_CODES.CUSTOMER_NOT_FOUND
      });
    }

    // التحقق من وجود أقساط نشطة
    const { data: activeInstallments, error: installmentsError } = await supabase
      .from('installment_plans')
      .select('id')
      .eq('customer_id', id)
      .eq('status', 'active')
      .limit(1);

    if (installmentsError) {
      console.error('خطأ في التحقق من الأقساط:', installmentsError);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    if (activeInstallments && activeInstallments.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن حذف زبون لديه أقساط نشطة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // ✅ حذف ملفات الصور من Supabase Storage قبل حذف السجل
    try {
      const filesToDelete = [];

      // حذف صورة Avatar إذا وجدت
      if (customer.id_doc_url) {
        const avatarPath = customer.id_doc_url.replace('avatars/', '');
        if (avatarPath) filesToDelete.push(`avatars/${avatarPath}`);
      }

      // حذف المستمسكات الإضافية إذا وجدت
      if (customer.extra_docs && Array.isArray(customer.extra_docs)) {
        customer.extra_docs.forEach(doc => {
          if (typeof doc === 'string' && doc.includes('documents/')) {
            const docPath = doc.replace('documents/', '');
            if (docPath) filesToDelete.push(`documents/${docPath}`);
          }
        });
      }

      if (filesToDelete.length > 0) {
        console.log('🗑️ Deleting files from storage:', filesToDelete);
        const { error: storageError } = await supabaseAdmin
          .storage
          .from('customers')
          .remove(filesToDelete);

        if (storageError) {
          console.warn('⚠️ Failed to delete some files from storage:', storageError);
          // نستمر في حذف السجل حتى لو فشل حذف الملفات
        } else {
          console.log('✅ Files deleted from storage successfully');
        }
      }
    } catch (storageCleanupError) {
      console.warn('⚠️ Storage cleanup error (continuing with delete):', storageCleanupError);
      // نستمر في حذف السجل حتى لو فشل تنظيف التخزين
    }

    // حذف العميل
    const { error: deleteError } = await supabaseAdmin
      .from('customers')
      .delete()
      .eq('id', id)
      .eq('store_id', storeId);

    if (deleteError) {
      console.error('خطأ في حذف العميل:', deleteError);
      return res.status(500).json({
        success: false,
        error: 'فشل في حذف العميل',
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
        action: 'delete_customer',
        entity_type: 'customer',
        entity_id: id,
        old_data: customer,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: null,
      message: 'تم حذف العميل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في حذف العميل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  getCustomers,
  createCustomer,
  getCustomer,
  updateCustomer,
  deleteCustomer
};
