import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../core/logger/app_logger.dart';

class PrintService {
  static final PrintService _instance = PrintService._();
  factory PrintService() => _instance;
  PrintService._();

  Future<void> printReceipt(String htmlContent) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _generatePdf(htmlContent),
        format: PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm),
      );
      AppLogger.info('Receipt sent to printer');
    } catch (e) {
      AppLogger.error('Print failed', e);
      rethrow;
    }
  }

  Future<void> printReceiptThermal(String htmlContent, {double widthMM = 58}) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _generatePdf(htmlContent),
        format: PdfPageFormat(widthMM * PdfPageFormat.mm, 297 * PdfPageFormat.mm),
      );
      AppLogger.info('Thermal receipt sent to printer');
    } catch (e) {
      AppLogger.error('Thermal print failed', e);
      rethrow;
    }
  }

  Future<Uint8List> _generatePdf(String html) async {
    return await Printing.convertHtml(html: html);
  }
}
