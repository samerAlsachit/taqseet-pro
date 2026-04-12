import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/installment_model.dart';

/// StatementWidget - واجهة كشف حساب العميل
///
/// تصميم طويل (Scrollable) يعرض جميع العمليات في جدول أنيق
class StatementWidget extends StatelessWidget {
  final String storeName;
  final String customerName;
  final String? customerPhone;
  final List<InstallmentModel> installments;
  final double totalInstallments;
  final double totalPaid;
  final double remainingBalance;
  final DateTime? startDate;
  final DateTime? endDate;
  final String statementNumber;
  final DateTime generatedDate;

  const StatementWidget({
    super.key,
    required this.storeName,
    required this.customerName,
    this.customerPhone,
    required this.installments,
    required this.totalInstallments,
    required this.totalPaid,
    required this.remainingBalance,
    this.startDate,
    this.endDate,
    required this.statementNumber,
    required this.generatedDate,
  });

  String get _formattedDateTime =>
      DateFormat('yyyy/MM/dd - HH:mm').format(generatedDate);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        width: 400,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Statement Title
            _buildStatementTitle(),

            const SizedBox(height: 16),

            // Customer Info
            _buildCustomerInfo(),

            const SizedBox(height: 16),

            // Summary Cards
            _buildSummarySection(),

            const SizedBox(height: 20),

            // Transactions Table
            _buildTransactionsTable(),

            const SizedBox(height: 20),

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
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.anchor, size: 32, color: Color(0xFF0A192F)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            storeName,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'نظام إدارة الديون والأقساط',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
      ),
      child: const Column(
        children: [
          Text(
            'كشف حساب كامل',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A192F),
            ),
          ),
          Text(
            'Account Statement',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
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
          _buildInfoRow('رقم الكشف:', statementNumber),
          _buildInfoRow('التاريخ:', _formattedDateTime),
          const Divider(height: 16),
          _buildInfoRow('العميل:', customerName),
          if (customerPhone != null && customerPhone!.isNotEmpty)
            _buildInfoRow('الهاتف:', customerPhone!),
          if (startDate != null && endDate != null)
            _buildInfoRow(
              'الفترة:',
              '${DateFormat('yyyy/MM/dd').format(startDate!)} - ${DateFormat('yyyy/MM/dd').format(endDate!)}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
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

  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildSummaryCard(
            'إجمالي الأقساط',
            totalInstallments,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'إجمالي المدفوع',
            totalPaid,
            const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'المتبقي',
            remainingBalance,
            remainingBalance > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat('#,##0').format(amount),
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF0A192F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'التاريخ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'العملية',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'المدفوع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'المتبقي',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...List.generate(installments.length, (index) {
            final installment = installments[index];
            final isEven = index % 2 == 0;

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                border: index < installments.length - 1
                    ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('yyyy/MM/dd').format(installment.dueDate),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Color(0xFF0A192F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'قسط ${installment.id}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Color(0xFF0A192F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      NumberFormat('#,##0').format(installment.paidAmount),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Color(0xFF059669),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      NumberFormat('#,##0').format(installment.remainingAmount),
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: installment.remainingAmount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 8),
              Text(
                'كشف معتمد إلكترونياً',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A192F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'نظام مرساة لإدارة الديون - تم إنشاء هذا الكشف إلكترونياً',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'تاريخ الإنشاء: $_formattedDateTime',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
