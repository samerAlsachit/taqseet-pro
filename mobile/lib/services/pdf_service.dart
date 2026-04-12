import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import '../models/installment_model.dart';

/// PdfService - خدمة توليد الوصل الرقمي والتقارير PDF
///
/// ⚠️ DEPRECATED: تم تعطيل هذه الخدمة لصالح ImageService
/// بسبب مشاكل في عرض اللغة العربية في مكتبة PDF
/// يُفضل استخدام ImageService لتوليد الوصولات كصور
@deprecated
class PdfService {
  // This service is deprecated - use ImageService instead
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  pw.Font? _tajawalFont;
  pw.Font? _tajawalBoldFont;

  /// Initialize fonts
  Future<void> init() async {
    // Load Tajawal font from assets
    try {
      final regularFontData = await rootBundle.load(
        'assets/fonts/Tajawal-Regular.ttf',
      );
      _tajawalFont = pw.Font.ttf(regularFontData);

      final boldFontData = await rootBundle.load(
        'assets/fonts/Tajawal-Bold.ttf',
      );
      _tajawalBoldFont = pw.Font.ttf(boldFontData);
    } catch (e) {
      // Fallback to default font if Tajawal not available
      _tajawalFont = null;
      _tajawalBoldFont = null;
    }
  }

  /// Get Arabic text theme
  pw.TextStyle get _arabicStyle =>
      pw.TextStyle(font: _tajawalFont, fontSize: 12, color: PdfColors.black);

  pw.TextStyle get _arabicBoldStyle => pw.TextStyle(
    font: _tajawalBoldFont ?? _tajawalFont,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  pw.TextStyle get _arabicHeaderStyle => pw.TextStyle(
    font: _tajawalBoldFont ?? _tajawalFont,
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    color: PdfColor.fromHex('#0A192F'),
  );

  pw.TextStyle get _arabicTitleStyle => pw.TextStyle(
    font: _tajawalBoldFont ?? _tajawalFont,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: PdfColor.fromHex('#3B82F6'),
  );

  /// ============================================
  /// وصل استلام دفعة (Payment Receipt)
  /// ============================================

  /// Generate payment receipt PDF
  Future<File> generateReceipt({
    required String receiptNumber,
    required DateTime date,
    required String customerName,
    required String? customerPhone,
    required double amountPaid,
    required double remainingBalance,
    required String? installmentId,
    String storeName = 'مرساة',
    String? notes,
  }) async {
    await _ensureInitialized();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header - Logo and Store Name
                _buildHeader(storeName),

                pw.SizedBox(height: 20),

                // Receipt Title
                pw.Text(
                  prepareArabicText('وصل استلام دفعة'),
                  style: _arabicHeaderStyle,
                  textDirection: pw.TextDirection.rtl,
                ),

                pw.SizedBox(height: 4),
                pw.Text(
                  'Receipt # $receiptNumber',
                  style: _arabicStyle.copyWith(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),

                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Receipt Details Table
                _buildDetailRow('التاريخ:', _formatDate(date)),
                _buildDetailRow('رقم الوصل:', receiptNumber),
                if (installmentId != null)
                  _buildDetailRow('رقم القسط:', installmentId),

                pw.SizedBox(height: 20),

                // Customer Info
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('معلومات العميل', style: _arabicTitleStyle),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('الاسم:', customerName),
                      if (customerPhone != null && customerPhone.isNotEmpty)
                        _buildDetailRow('الهاتف:', customerPhone),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Amount Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#DBEAFE'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#3B82F6'),
                      width: 2,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      // Amount Paid
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            prepareArabicText('المبلغ المدفوع:'),
                            style: _arabicBoldStyle.copyWith(fontSize: 14),
                          ),
                          pw.Text(
                            '${_formatCurrency(amountPaid)} د.ع',
                            style: _arabicBoldStyle.copyWith(
                              fontSize: 16,
                              color: PdfColor.fromHex('#059669'),
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 12),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 12),

                      // Remaining Balance - Most Important
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            prepareArabicText('الرصيد المتبقي بذمة العميل:'),
                            style: _arabicBoldStyle.copyWith(fontSize: 14),
                          ),
                          pw.Text(
                            '${_formatCurrency(remainingBalance)} د.ع',
                            style: _arabicBoldStyle.copyWith(
                              fontSize: 18,
                              color: remainingBalance > 0
                                  ? PdfColor.fromHex('#DC2626') // Red if debt
                                  : PdfColor.fromHex(
                                      '#059669',
                                    ), // Green if settled
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (notes != null && notes.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'ملاحظات: $notes',
                    style: _arabicStyle.copyWith(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text(
                  prepareArabicText('شكراً لثقتكم - نظام مرساة لإدارة الديون'),
                  style: _arabicStyle.copyWith(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  prepareArabicText('تم إنشاء هذا الوصل إلكترونياً'),
                  style: _arabicStyle.copyWith(
                    fontSize: 9,
                    color: PdfColors.grey400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save to temporary file
    final output = await getTemporaryDirectory();
    final fileName =
        'receipt_${receiptNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// ============================================
  /// كشف حساب كامل (Full Account Statement)
  /// ============================================

  /// Generate full account statement PDF
  Future<File> generateStatement({
    required String customerName,
    required String? customerPhone,
    required List<InstallmentModel> installments,
    required List<Map<String, dynamic>> payments,
    DateTime? startDate,
    DateTime? endDate,
    String storeName = 'مرساة',
  }) async {
    await _ensureInitialized();

    final pdf = pw.Document();

    // Calculate totals
    double totalInstallments = 0;
    double totalPaid = 0;
    for (final i in installments) {
      totalInstallments += i.totalAmount;
      totalPaid += i.paidAmount;
    }
    final remainingBalance = totalInstallments - totalPaid;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                _buildHeader(storeName),

                pw.SizedBox(height: 16),

                // Statement Title
                pw.Text(
                  prepareArabicText('كشف حساب كامل'),
                  style: _arabicHeaderStyle,
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Account Statement',
                  style: _arabicStyle.copyWith(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),

                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Customer Info
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        prepareArabicText('معلومات العميل'),
                        style: _arabicTitleStyle,
                      ),
                      pw.SizedBox(height: 8),
                      _buildDetailRow(
                        prepareArabicText('الاسم:'),
                        customerName,
                      ),
                      if (customerPhone != null && customerPhone.isNotEmpty)
                        _buildDetailRow(
                          prepareArabicText('الهاتف:'),
                          customerPhone,
                        ),
                      if (startDate != null && endDate != null)
                        _buildDetailRow(
                          prepareArabicText('الفترة:'),
                          '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                        ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // Summary Cards
                pw.Row(
                  children: [
                    _buildSummaryCard(
                      prepareArabicText('إجمالي الأقساط'),
                      totalInstallments,
                      PdfColor.fromHex('#3B82F6'),
                    ),
                    pw.SizedBox(width: 8),
                    _buildSummaryCard(
                      prepareArabicText('إجمالي المدفوع'),
                      totalPaid,
                      PdfColor.fromHex('#059669'),
                    ),
                    pw.SizedBox(width: 8),
                    _buildSummaryCard(
                      prepareArabicText('المتبقي'),
                      remainingBalance,
                      remainingBalance > 0
                          ? PdfColor.fromHex('#DC2626')
                          : PdfColor.fromHex('#059669'),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Transactions Table Header (RTL Order)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0A192F'),
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // For RTL layout, columns are in visual order: Date | Operation | Paid | Remaining
                      // Date (rightmost in RTL)
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          prepareArabicText('التاريخ'),
                          style: _arabicStyle.copyWith(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      // Operation
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          prepareArabicText('العملية'),
                          style: _arabicStyle.copyWith(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      // Paid
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          prepareArabicText('المدفوع'),
                          style: _arabicStyle.copyWith(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      // Remaining (leftmost in RTL)
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          prepareArabicText('المتبقي'),
                          style: _arabicStyle.copyWith(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions List (RTL Order - matches header)
                pw.ListView.builder(
                  itemCount: installments.length,
                  itemBuilder: (context, index) {
                    final installment = installments[index];
                    final isEven = index % 2 == 0;

                    return pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: isEven
                            ? PdfColors.white
                            : PdfColor.fromHex('#F8FAFC'),
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          // Date (rightmost)
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              _formatDate(installment.dueDate),
                              style: _arabicStyle.copyWith(fontSize: 10),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Operation
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              prepareArabicText('قسط ${installment.id}'),
                              style: _arabicStyle.copyWith(fontSize: 10),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Paid
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              _formatCurrency(installment.paidAmount),
                              style: _arabicStyle.copyWith(
                                fontSize: 10,
                                color: PdfColor.fromHex('#059669'),
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Remaining (leftmost)
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              _formatCurrency(installment.remainingAmount),
                              style: _arabicStyle.copyWith(
                                fontSize: 10,
                                color: installment.remainingAmount > 0
                                    ? PdfColor.fromHex('#DC2626')
                                    : PdfColor.fromHex('#059669'),
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text(
                  prepareArabicText(
                    'نظام مرساة لإدارة الديون - هذا الكشف صادر إلكترونياً',
                  ),
                  style: _arabicStyle.copyWith(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save file
    final output = await getTemporaryDirectory();
    final fileName =
        'statement_${customerName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// ============================================
  /// مشاركة PDF (Share PDF)
  /// ============================================

  /// Share PDF file via WhatsApp or other apps
  Future<void> sharePdf(
    File pdfFile, {
    String? message,
    String? phoneNumber,
  }) async {
    final filePath = pdfFile.path;

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Format phone for WhatsApp
      String formattedPhone = phoneNumber;
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '964${formattedPhone.substring(1)}';
      }

      // Share with WhatsApp hint
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message ?? 'مرفق لكم وصل الاستلام',
        subject: 'وصل استلام - مرساة',
      );
    } else {
      // General share
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message,
        subject: 'وصل استلام - مرساة',
      );
    }
  }

  /// ============================================
  /// Helpers - دوال مساعدة
  /// ============================================

  pw.Widget _buildHeader(String storeName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0A192F'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            children: [
              pw.Text(
                prepareArabicText(storeName),
                style: _arabicBoldStyle.copyWith(
                  fontSize: 24,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                prepareArabicText('نظام إدارة الديون والأقساط'),
                style: _arabicStyle.copyWith(
                  fontSize: 11,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    // For RTL Arabic: Label on right, Value on left
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          // Label (right side in RTL) - processed for Arabic shaping
          pw.Text(prepareArabicText(label), style: _arabicBoldStyle),
          pw.SizedBox(width: 8),
          // Value (left side in RTL) - processed for Arabic shaping
          pw.Text(prepareArabicText(value), style: _arabicStyle),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(String title, double amount, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              prepareArabicText(title),
              style: _arabicStyle.copyWith(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _formatCurrency(amount),
              style: _arabicBoldStyle.copyWith(fontSize: 12, color: color),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0').format(amount);
  }

  Future<void> _ensureInitialized() async {
    if (_tajawalFont == null) {
      await init();
    }
  }

  /// ============================================
  /// Arabic Text Processing - معالجة النص العربي
  /// ============================================

  /// Prepare Arabic text for PDF rendering
  /// تقوم بإعادة تشكيل الحروف العربية ومعالجة الاتجاه
  String prepareArabicText(String text) {
    if (text.isEmpty) return text;
    // 1. Reshape Arabic letters (connect them properly)
    final reshapedText = ArabicReshaper().reshape(text);
    // 2. Reverse text for RTL display in PDF
    return reshapedText.split('').reversed.join('');
  }
}
