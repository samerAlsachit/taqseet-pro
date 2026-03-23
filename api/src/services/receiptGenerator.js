const QRCode = require('qrcode');
const moment = require('moment');

/**
 * توليد HTML للوصل للطباعة
 * @param {Object} receiptData - بيانات الوصل
 * @param {string} receiptData.receipt_number - رقم الوصل
 * @param {string} receiptData.payment_date - تاريخ الدفع
 * @param {Object} receiptData.customer - بيانات العميل
 * @param {Object} receiptData.store - بيانات المحل
 * @param {string} receiptData.product_name - اسم المنتج
 * @param {number} receiptData.amount_paid - المبلغ المدفوع
 * @param {number} receiptData.remaining_amount - المبلغ المتبقي
 * @param {number} receiptData.installments_remaining - عدد الأقساط المتبقية
 * @param {Object} receiptData.plan_summary - ملخص الخطة
 * @param {string} type - نوع الطباعة ('a4', 'thermal58', 'thermal80')
 * @returns {string} HTML جاهز للطباعة
 */
const generateReceiptHTML = async (receiptData, type = 'a4') => {
  const {
    receipt_number,
    payment_date,
    customer,
    store,
    product_name,
    amount_paid,
    remaining_amount,
    installments_remaining,
    plan_summary
  } = receiptData;

  // توليد QR code لرقم الوصل
  const qrCodeDataURL = await QRCode.toDataURL(receipt_number, {
    width: type === 'a4' ? 100 : 60,
    margin: 1,
    color: {
      dark: '#000000',
      light: '#FFFFFF'
    }
  });

  // تنسيق المبالغ
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('ar-IQ', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount || 0);
  };

  // تنسيق التاريخ
  const formatDate = (date) => {
    return moment(date).format('YYYY-MM-DD');
  };

  // تحديد الأنماط حسب نوع الطباعة
  const getStyles = () => {
    if (type === 'thermal58') {
      return `
        <style>
          body { 
            font-family: Arial, sans-serif; 
            font-size: 12px; 
            margin: 5px; 
            padding: 10px;
            direction: rtl;
            text-align: right;
            width: 384px; /* 58mm */
          }
          .header { text-align: center; margin-bottom: 10px; }
          .store-name { font-size: 16px; font-weight: bold; margin-bottom: 5px; }
          .store-info { font-size: 10px; margin-bottom: 10px; }
          .receipt-title { font-size: 14px; font-weight: bold; border-bottom: 1px dashed #000; padding-bottom: 5px; margin-bottom: 10px; }
          .section { margin-bottom: 10px; }
          .row { display: flex; justify-content: space-between; margin-bottom: 3px; }
          .label { font-weight: bold; }
          .amount { font-weight: bold; font-size: 14px; }
          .qr-code { text-align: center; margin: 10px 0; }
          .footer { text-align: center; font-size: 10px; margin-top: 15px; border-top: 1px dashed #000; padding-top: 5px; }
          .summary { border: 1px solid #000; padding: 5px; margin: 10px 0; }
        </style>
      `;
    } else if (type === 'thermal80') {
      return `
        <style>
          body { 
            font-family: Arial, sans-serif; 
            font-size: 14px; 
            margin: 10px; 
            padding: 15px;
            direction: rtl;
            text-align: right;
            width: 480px; /* 80mm */
          }
          .header { text-align: center; margin-bottom: 15px; }
          .store-name { font-size: 18px; font-weight: bold; margin-bottom: 8px; }
          .store-info { font-size: 12px; margin-bottom: 15px; }
          .receipt-title { font-size: 16px; font-weight: bold; border-bottom: 2px solid #000; padding-bottom: 8px; margin-bottom: 15px; }
          .section { margin-bottom: 15px; }
          .row { display: flex; justify-content: space-between; margin-bottom: 5px; }
          .label { font-weight: bold; }
          .amount { font-weight: bold; font-size: 16px; }
          .qr-code { text-align: center; margin: 15px 0; }
          .footer { text-align: center; font-size: 12px; margin-top: 20px; border-top: 2px solid #000; padding-top: 8px; }
          .summary { border: 2px solid #000; padding: 10px; margin: 15px 0; }
        </style>
      `;
    } else {
      // A4 default
      return `
        <style>
          body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            font-size: 16px; 
            margin: 20px; 
            padding: 30px;
            direction: rtl;
            text-align: right;
            max-width: 600px;
            margin: 0 auto;
            border: 1px solid #ddd;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          }
          .header { text-align: center; margin-bottom: 30px; }
          .store-name { font-size: 24px; font-weight: bold; margin-bottom: 10px; color: #2c3e50; }
          .store-info { font-size: 14px; color: #7f8c8d; margin-bottom: 20px; }
          .receipt-title { font-size: 20px; font-weight: bold; border-bottom: 3px solid #3498db; padding-bottom: 10px; margin-bottom: 25px; color: #2c3e50; }
          .section { margin-bottom: 20px; }
          .section-title { font-size: 18px; font-weight: bold; margin-bottom: 10px; color: #34495e; border-right: 4px solid #3498db; padding-right: 10px; }
          .row { display: flex; justify-content: space-between; margin-bottom: 8px; padding: 5px 0; }
          .row:nth-child(even) { background-color: #f8f9fa; }
          .label { font-weight: bold; color: #2c3e50; }
          .value { color: #34495e; }
          .amount { font-weight: bold; font-size: 18px; color: #27ae60; }
          .qr-code { text-align: center; margin: 20px 0; }
          .footer { text-align: center; font-size: 14px; margin-top: 30px; border-top: 2px solid #bdc3c7; padding-top: 15px; color: #7f8c8d; }
          .summary { border: 2px solid #3498db; padding: 15px; margin: 20px 0; border-radius: 8px; background-color: #ecf0f1; }
          .receipt-header, .receipt-footer { font-size: 12px; color: #7f8c8d; margin: 10px 0; font-style: italic; }
        </style>
      `;
    }
  };

  const styles = getStyles();

  const html = `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>وصل دفع - ${receipt_number}</title>
      ${styles}
    </head>
    <body>
      <div class="header">
        ${store.logo_url ? `<img src="${store.logo_url}" alt="${store.name}" style="max-width: 100px; margin-bottom: 10px;">` : ''}
        <div class="store-name">${store.name}</div>
        <div class="store-info">
          <div>${store.phone || ''}</div>
          <div>${store.address || ''}</div>
        </div>
        ${store.receipt_header ? `<div class="receipt-header">${store.receipt_header}</div>` : ''}
        <div class="receipt-title">وصل دفع</div>
      </div>

      <div class="section">
        <div class="section-title">معلومات الوصل</div>
        <div class="row">
          <span class="label">رقم الوصل:</span>
          <span class="value">${receipt_number}</span>
        </div>
        <div class="row">
          <span class="label">التاريخ:</span>
          <span class="value">${formatDate(payment_date)}</span>
        </div>
      </div>

      <div class="section">
        <div class="section-title">بيانات العميل</div>
        <div class="row">
          <span class="label">الاسم:</span>
          <span class="value">${customer.full_name}</span>
        </div>
        <div class="row">
          <span class="label">الهاتف:</span>
          <span class="value">${customer.phone}</span>
        </div>
      </div>

      <div class="section">
        <div class="section-title">تفاصيل الدفع</div>
        <div class="row">
          <span class="label">المنتج:</span>
          <span class="value">${product_name}</span>
        </div>
        <div class="row">
          <span class="label">المبلغ المدفوع:</span>
          <span class="amount">${formatCurrency(amount_paid)} د.ع</span>
        </div>
        <div class="row">
          <span class="label">المبلغ المتبقي:</span>
          <span class="value">${formatCurrency(remaining_amount)} د.ع</span>
        </div>
        <div class="row">
          <span class="label">الأقساط المتبقية:</span>
          <span class="value">${installments_remaining}</span>
        </div>
      </div>

      <div class="summary">
        <div class="section-title">ملخص الخطة</div>
        <div class="row">
          <span class="label">إجمالي المبلغ:</span>
          <span class="value">${formatCurrency(plan_summary.total)} د.ع</span>
        </div>
        <div class="row">
          <span class="label">المبلغ المدفوع:</span>
          <span class="value">${formatCurrency(plan_summary.paid)} د.ع</span>
        </div>
        <div class="row">
          <span class="label">المبلغ المتبقي:</span>
          <span class="value">${formatCurrency(plan_summary.remaining)} د.ع</span>
        </div>
      </div>

      <div class="qr-code">
        <img src="${qrCodeDataURL}" alt="QR Code" />
        <div style="font-size: 12px; margin-top: 5px;">رقم الوصل: ${receipt_number}</div>
      </div>

      <div class="footer">
        <div>شكراً لتعاملكم معنا</div>
        <div>هذا الوصل صالح للإثبات</div>
        ${store.receipt_footer ? `<div>${store.receipt_footer}</div>` : ''}
      </div>

      <script>
        // طباعة تلقائية عند فتح الصفحة
        window.onload = function() {
          setTimeout(() => {
            window.print();
          }, 500);
        };
        
        // إغلاق النافذة بعد الطباعة
        window.onafterprint = function() {
          window.close();
        };
      </script>
    </body>
    </html>
  `;

  return html;
};

/**
 * توليد بيانات الوصل للطباعة
 * @param {Object} payment - بيانات الدفع
 * @param {Object} plan - بيانات خطة الأقساط
 * @param {Object} store - بيانات المحل
 * @returns {Object} بيانات الوصل المنسقة
 */
const prepareReceiptData = (payment, plan, store) => {
  const remainingAmount = plan.total_amount - (plan.total_paid || 0);
  const installmentsRemaining = plan.installments_count - (plan.paid_installments || 0);

  return {
    receipt_number: payment.receipt_number,
    payment_date: payment.payment_date,
    customer: {
      full_name: plan.customers.full_name,
      phone: plan.customers.phone
    },
    store: {
      name: store.name,
      phone: store.phone,
      address: store.address,
      logo_url: store.logo_url,
      receipt_header: store.receipt_header,
      receipt_footer: store.receipt_footer
    },
    product_name: plan.products.name,
    amount_paid: payment.amount_paid,
    remaining_amount: remainingAmount,
    installments_remaining: installmentsRemaining,
    plan_summary: {
      total: plan.total_amount,
      paid: plan.total_paid || 0,
      remaining: remainingAmount
    }
  };
};

module.exports = {
  generateReceiptHTML,
  prepareReceiptData
};
