import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Map<String, dynamic>? plan;

  const ReceiptScreen({
    super.key,
    required this.payment,
    this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final currency = plan?['currency'] ?? 'IQD';
    final amount = payment['amount_paid'] ?? 0;
    final receiptNumber = payment['receipt_number'] ?? '';
    final paymentDate = payment['payment_date'] ?? '';
    final customerName = plan?['customer_name'] ?? 'غير محدد';
    final productName = plan?['product_name'] ?? 'غير محدد';
    final remaining = plan?['remaining_amount'] ?? 0;
    final notes = payment['notes'] ?? '';

    // Light theme colors
    const Color primaryColor = AppColors.navy;
    const Color lightBackground = Colors.white;
    const Color cardBackground = Color(0xFFF5F7FA);
    const Color darkText = Color(0xFF2D3748);
    const Color greyText = Color(0xFF718096);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'وصل الدفع',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareReceipt(context),
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'مشاركة الوصل',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Receipt Content
            Container(
              color: lightBackground,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Logo placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child:
                        const Icon(Icons.store, size: 40, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مرساة - نظام إدارة الأقساط',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'THABAT - Installment Management System',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: greyText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Receipt Details - Light Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow('رقم الوصل', receiptNumber,
                            isBold: true),
                        const Divider(height: 20, color: Colors.grey),
                        _buildReceiptRow('العميل', customerName),
                        _buildReceiptRow('المنتج', productName),
                        _buildReceiptRow(
                            'تاريخ الدفع', _formatDate(paymentDate)),
                        const Divider(height: 20, color: Colors.grey),
                        _buildReceiptRow(
                          'المبلغ المدفوع',
                          '$amount $currency',
                          isHighlighted: true,
                          valueColor: AppColors.success,
                        ),
                        _buildReceiptRow(
                          'المتبقي',
                          '$remaining $currency',
                          valueColor: Colors.orange[700],
                        ),
                        if (notes.isNotEmpty) ...[
                          const Divider(height: 20, color: Colors.grey),
                          _buildReceiptRow('ملاحظات', notes),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Signature placeholder
                  Text(
                    'تم الدفع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: greyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 1,
                    color: greyText.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Print Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _printReceipt(context),
                  icon: const Icon(Icons.print),
                  label: const Text(
                    'طباعة',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Share Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareReceipt(context),
                  icon: const Icon(Icons.share),
                  label: const Text(
                    'مشاركة',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electric,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: isHighlighted ? 16 : 14,
              color: const Color(0xFF718096),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: isHighlighted ? 18 : 14,
              fontWeight:
                  isBold || isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }

  void _shareReceipt(BuildContext context) {
    final currency = plan?['currency'] ?? 'IQD';
    final amount = payment['amount_paid'] ?? 0;
    final receiptNumber = payment['receipt_number'] ?? '';
    final customerName = plan?['customer_name'] ?? 'غير محدد';
    final productName = plan?['product_name'] ?? 'غير محدد';

    final text = '''
وصل دفع - مرساة

رقم الوصل: $receiptNumber
العميل: $customerName
المنتج: $productName
المبلغ المدفوع: $amount $currency

شكراً لثقتكم بنا!
'''
        .trim();

    Share.share(text);
  }

  Future<void> _printReceipt(BuildContext context) async {
    final currency = plan?['currency'] ?? 'IQD';
    final amount = payment['amount_paid'] ?? 0;
    final receiptNumber = payment['receipt_number'] ?? '';
    final paymentDate = payment['payment_date'] ?? '';
    final customerName = plan?['customer_name'] ?? 'غير محدد';
    final productName = plan?['product_name'] ?? 'غير محدد';
    final remaining = plan?['remaining_amount'] ?? 0;
    final notes = payment['notes'] ?? '';

    // Create PDF document
    final pdf = pw.Document();

    // Use default PDF font for now
    final font = pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(20),
                    topRight: pw.Radius.circular(20),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Icon(
                      const pw.IconData(0xe8d5), // receipt_long icon
                      color: PdfColors.white,
                      size: 28,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'وصل دفع',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              // Company Info
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.blue800, width: 1),
                ),
                child: pw.Center(
                  child: pw.Icon(
                    const pw.IconData(0xe8d7), // store icon
                    color: PdfColors.blue800,
                    size: 40,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'مرساة - نظام إدارة الأقساط',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'THABAT - Installment Management System',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 24),
              // Receipt Details
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(16)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfRow('رقم الوصل', receiptNumber, font,
                        isBold: true),
                    pw.Divider(height: 20, color: PdfColors.grey),
                    _buildPdfRow('العميل', customerName, font),
                    _buildPdfRow('المنتج', productName, font),
                    _buildPdfRow('تاريخ الدفع', _formatDate(paymentDate), font),
                    pw.Divider(height: 20, color: PdfColors.grey),
                    _buildPdfRow(
                      'المبلغ المدفوع',
                      '$amount $currency',
                      font,
                      isHighlighted: true,
                      valueColor: PdfColors.green700,
                    ),
                    _buildPdfRow(
                      'المتبقي',
                      '$remaining $currency',
                      font,
                      valueColor: PdfColors.orange700,
                    ),
                    if (notes.isNotEmpty) ...[
                      pw.Divider(height: 20, color: PdfColors.grey),
                      _buildPdfRow('ملاحظات', notes, font),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              // Signature
              pw.Text(
                'تم الدفع',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: 120,
                height: 1,
                color: PdfColors.grey700,
              ),
              pw.SizedBox(height: 16),
              // Footer
              pw.Text(
                'شكراً لثقتكم بنا!',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print preview dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'وصل_دفع_$receiptNumber.pdf',
      format: PdfPageFormat.a4,
    );
  }

  pw.Widget _buildPdfRow(
    String label,
    String value,
    pw.Font font, {
    bool isBold = false,
    bool isHighlighted = false,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: isHighlighted ? 16 : 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: isHighlighted ? 18 : 14,
              fontWeight: isBold || isHighlighted
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
