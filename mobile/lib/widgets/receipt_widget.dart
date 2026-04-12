import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ReceiptWidget - واجهة الوصل الاحترافية
///
/// تصميم عمودي يشبه وصول المحلات الاحترافية
class ReceiptWidget extends StatelessWidget {
  final String storeName;
  final String customerName;
  final String? customerPhone;
  final double amountPaid;
  final double remainingBalance;
  final String receiptNumber;
  final DateTime date;
  final String? installmentId;

  const ReceiptWidget({
    super.key,
    required this.storeName,
    required this.customerName,
    this.customerPhone,
    required this.amountPaid,
    required this.remainingBalance,
    required this.receiptNumber,
    required this.date,
    this.installmentId,
  });

  String get _formattedDate => DateFormat('yyyy/MM/dd - HH:mm').format(date);
  String get _formattedAmount => NumberFormat('#,##0').format(amountPaid);
  String get _formattedRemaining =>
      NumberFormat('#,##0').format(remainingBalance);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        width: 380,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Logo Area
            _buildHeader(),

            // Receipt Title
            _buildReceiptTitle(),

            const SizedBox(height: 16),

            // Receipt Details
            _buildDetailsSection(),

            const SizedBox(height: 20),

            // Amount Section
            _buildAmountSection(),

            const SizedBox(height: 20),

            // Signature Section
            _buildSignatureSection(),

            const SizedBox(height: 16),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0A192F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Logo Circle
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.anchor, size: 40, color: Color(0xFF0A192F)),
            ),
          ),
          const SizedBox(height: 12),
          // Store Name
          Text(
            storeName,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'نظام إدارة الديون والأقساط',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6), width: 1),
      ),
      child: const Text(
        'وصل استلام دفعة',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A192F),
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildDetailRow('رقم الوصل:', receiptNumber),
          if (installmentId != null)
            _buildDetailRow('رقم القسط:', installmentId!),
          _buildDetailRow('التاريخ:', _formattedDate),
          const Divider(height: 16),
          _buildDetailRow('العميل:', customerName),
          if (customerPhone != null && customerPhone!.isNotEmpty)
            _buildDetailRow('الهاتف:', customerPhone!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A192F),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A192F).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Amount Paid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المبلغ المدفوع:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formattedAmount,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'د.ع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white24),
          // Remaining Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المتبقي:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formattedRemaining,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: remainingBalance > 0
                          ? const Color(0xFFFB7185)
                          : const Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'د.ع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توقيع المستلم',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF64748B).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توقيع المحاسب',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF64748B).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 24),
          const SizedBox(height: 8),
          const Text(
            'شكراً لثقتكم - نظام مرساة لإدارة الديون',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تم إنشاء هذا الوصل إلكترونياً بتاريخ $_formattedDate',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
