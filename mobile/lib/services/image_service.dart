import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../widgets/receipt_widget.dart';
import '../widgets/statement_widget.dart';
import '../models/installment_model.dart';

/// ImageService - خدمة توليد الوصل كصورة ومشاركته
///
/// تستخدم ScreenshotController لالتقاط صورة من Widget
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ScreenshotController _screenshotController = ScreenshotController();

  /// توليد صورة الوصل ومشاركتها
  ///
  /// [storeName] - اسم المتجر
  /// [customerName] - اسم العميل
  /// [customerPhone] - رقم هاتف العميل (اختياري)
  /// [amountPaid] - المبلغ المدفوع
  /// [remainingBalance] - الرصيد المتبقي
  /// [receiptNumber] - رقم الوصل
  /// [date] - تاريخ العملية
  /// [installmentId] - رقم القسط (اختياري)
  /// [phoneNumber] - رقم الهاتف للمشاركة عبر واتساب (اختياري)
  Future<void> generateAndShareReceipt({
    required String storeName,
    required String customerName,
    String? customerPhone,
    required double amountPaid,
    required double remainingBalance,
    required String receiptNumber,
    required DateTime date,
    String? installmentId,
    String? phoneNumber,
  }) async {
    try {
      // Capture screenshot of the receipt widget
      final Uint8List? imageBytes = await _screenshotController
          .captureFromWidget(
            ReceiptWidget(
              storeName: storeName,
              customerName: customerName,
              customerPhone: customerPhone,
              amountPaid: amountPaid,
              remainingBalance: remainingBalance,
              receiptNumber: receiptNumber,
              date: date,
              installmentId: installmentId,
            ),
            context: null,
            delay: const Duration(milliseconds: 100),
          );

      if (imageBytes == null) {
        throw Exception('فشل في توليد صورة الوصل');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = 'receipt_$timestamp.png';
      final String filePath = '${tempDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Prepare share message
      final String message = phoneNumber != null && phoneNumber.isNotEmpty
          ? 'مرفق لكم وصل استلام الدفعة'
          : 'وصل استلام دفعة - $storeName';

      // Share the image
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message,
        subject: 'وصل استلام - $storeName',
      );
    } catch (e) {
      throw Exception('خطأ في توليد أو مشاركة الوصل: $e');
    }
  }

  /// توليد صورة الوصل فقط (بدون مشاركة)
  ///
  /// تُستخدم لعرض معاينة قبل المشاركة
  Future<Uint8List?> generateReceiptImage({
    required String storeName,
    required String customerName,
    String? customerPhone,
    required double amountPaid,
    required double remainingBalance,
    required String receiptNumber,
    required DateTime date,
    String? installmentId,
  }) async {
    try {
      final Uint8List? imageBytes = await _screenshotController
          .captureFromWidget(
            ReceiptWidget(
              storeName: storeName,
              customerName: customerName,
              customerPhone: customerPhone,
              amountPaid: amountPaid,
              remainingBalance: remainingBalance,
              receiptNumber: receiptNumber,
              date: date,
              installmentId: installmentId,
            ),
            context: null,
            delay: const Duration(milliseconds: 100),
          );

      return imageBytes;
    } catch (e) {
      print('Error generating receipt image: $e');
      return null;
    }
  }

  /// حفظ صورة الوصل في الملفات المؤقتة
  ///
  /// تُرجع مسار الملف المحفوظ
  Future<String?> saveReceiptToFile({
    required Uint8List imageBytes,
    String? customFileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = customFileName ?? 'receipt_$timestamp.png';
      final String filePath = '${tempDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      print('Error saving receipt file: $e');
      return null;
    }
  }

  /// مشاركة ملف صورة مباشرة
  Future<void> shareReceiptFile({
    required String filePath,
    String? message,
    String? subject,
  }) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: message ?? 'مرفق لكم وصل الاستلام',
      subject: subject ?? 'وصل استلام',
    );
  }

  /// إنشاء ScreenshotController للاستخدام في واجهة المستخدم
  ///
  /// يمكن استخدامه لالتقاط صورة من أي Widget في الشاشة
  ScreenshotController get screenshotController => _screenshotController;

  /// ============================================
  /// توليد كشف الحساب كصورة (Statement as Image)
  /// ============================================

  /// توليد كشف حساب العميل كصورة ومشاركته
  Future<void> generateAndShareStatement({
    required String storeName,
    required String customerName,
    String? customerPhone,
    required List<InstallmentModel> installments,
    required double totalInstallments,
    required double totalPaid,
    required double remainingBalance,
    DateTime? startDate,
    DateTime? endDate,
    String? phoneNumber,
  }) async {
    try {
      // Generate statement number
      final statementNumber =
          'STMT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // Create Statement Widget with SingleChildScrollView for long content
      final statementWidget = Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: StatementWidget(
            storeName: storeName,
            customerName: customerName,
            customerPhone: customerPhone,
            installments: installments,
            totalInstallments: totalInstallments,
            totalPaid: totalPaid,
            remainingBalance: remainingBalance,
            startDate: startDate,
            endDate: endDate,
            statementNumber: statementNumber,
            generatedDate: DateTime.now(),
          ),
        ),
      );

      // Capture screenshot with increased pixel Ratio for better quality
      final Uint8List? imageBytes = await _screenshotController
          .captureFromWidget(
            statementWidget,
            context: null,
            delay: const Duration(milliseconds: 200),
            pixelRatio: 2.0, // Higher quality for statements
          );

      if (imageBytes == null) {
        throw Exception('فشل في توليد صورة كشف الحساب');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = 'statement_$timestamp.png';
      final String filePath = '${tempDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Prepare share message
      final String message = 'كشف حساب كامل - $customerName';

      // Share the image
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message,
        subject: 'كشف حساب - $storeName',
      );
    } catch (e) {
      throw Exception('خطأ في توليد أو مشاركة كشف الحساب: $e');
    }
  }

  /// توليد صورة كشف الحساب فقط (بدون مشاركة)
  Future<Uint8List?> generateStatementImage({
    required String storeName,
    required String customerName,
    String? customerPhone,
    required List<InstallmentModel> installments,
    required double totalInstallments,
    required double totalPaid,
    required double remainingBalance,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statementNumber =
          'STMT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final statementWidget = Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: StatementWidget(
            storeName: storeName,
            customerName: customerName,
            customerPhone: customerPhone,
            installments: installments,
            totalInstallments: totalInstallments,
            totalPaid: totalPaid,
            remainingBalance: remainingBalance,
            startDate: startDate,
            endDate: endDate,
            statementNumber: statementNumber,
            generatedDate: DateTime.now(),
          ),
        ),
      );

      final Uint8List? imageBytes = await _screenshotController
          .captureFromWidget(
            statementWidget,
            context: null,
            delay: const Duration(milliseconds: 200),
            pixelRatio: 2.0,
          );

      return imageBytes;
    } catch (e) {
      print('Error generating statement image: $e');
      return null;
    }
  }
}
