import 'package:flutter/material.dart';
import '../models/installment_plan_model.dart';
import '../models/payment_schedule_model.dart';
import '../models/customer_model.dart';
import '../services/thabit_local_db_service.dart';
import '../core/utils/formatter.dart';

/// شاشة تفاصيل القسط
/// تعرض معلومات القسط الكاملة مع جدول الأقساط
class InstallmentDetailsScreen extends StatefulWidget {
  final String installmentPlanId;
  final CustomerModel customer;

  const InstallmentDetailsScreen({
    super.key,
    required this.installmentPlanId,
    required this.customer,
  });

  @override
  State<InstallmentDetailsScreen> createState() =>
      _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  final ThabitLocalDBService _localDB = ThabitLocalDBService();

  InstallmentPlanModel? _installmentPlan;
  List<PaymentScheduleModel> _paymentSchedule = [];
  bool _isLoading = true;

  // Calculated values
  int _totalAmount = 0;
  int _totalPaid = 0;
  int _remainingAmount = 0;
  int _paidInstallments = 0;
  int _totalInstallments = 0;
  double _progressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _localDB.init();

      // Load installment plan
      _installmentPlan = _localDB.getInstallmentPlanById(
        widget.installmentPlanId,
      );

      if (_installmentPlan != null) {
        // Load payment schedule
        _paymentSchedule = _localDB.getPaymentScheduleByPlan(
          widget.installmentPlanId,
        );

        // Calculate totals
        _calculateTotals();
      }
    } catch (e) {
      print('❌ Error loading installment details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    if (_installmentPlan == null) return;

    _totalAmount = _installmentPlan!.totalPrice;
    _totalInstallments = _paymentSchedule.length;

    _totalPaid = _paymentSchedule.fold<int>(
      0,
      (sum, schedule) => sum + (schedule.paidAmount ?? 0),
    );

    _remainingAmount = _totalAmount - _totalPaid;

    _paidInstallments = _paymentSchedule.where((s) => s.isPaid).length;

    if (_totalInstallments > 0) {
      _progressPercentage = _paidInstallments / _totalInstallments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تفاصيل القسط',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _installmentPlan == null
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'لم يتم العثور على بيانات القسط',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Customer Info
            _buildHeaderCard(),

            const SizedBox(height: 20),

            // Progress Section
            _buildProgressSection(),

            const SizedBox(height: 20),

            // Payment Schedule Header
            _buildSectionHeader('جدول الأقساط', Icons.calendar_today),

            const SizedBox(height: 12),

            // Payment Schedule Table
            _buildPaymentScheduleTable(),

            const SizedBox(height: 20),

            // Notes Section
            if (_installmentPlan?.notes != null &&
                _installmentPlan!.notes!.isNotEmpty)
              _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Name
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اسم العميل',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      widget.customer.fullName,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: Colors.white24),

          // Financial Summary Row
          Row(
            children: [
              // Total Amount
              Expanded(
                child: _buildFinancialItem(
                  'المبلغ الكلي',
                  CurrencyFormatter.formatCurrency(_totalAmount.toDouble()),
                  Icons.account_balance_wallet,
                ),
              ),

              Container(height: 40, width: 1, color: Colors.white24),

              // Remaining Amount
              Expanded(
                child: _buildFinancialItem(
                  'المبلغ المتبقي',
                  CurrencyFormatter.formatCurrency(_remainingAmount.toDouble()),
                  Icons.pending_actions,
                  isWarning: _remainingAmount > 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Monthly Installment
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'القسط الشهري: ',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCurrency(
                    _totalInstallments > 0
                        ? (_installmentPlan?.financedAmount ?? 0) /
                              _totalInstallments
                        : 0,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isWarning ? Colors.orange.shade300 : Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.orange.shade300 : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'حالة السداد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _progressPercentage == 1.0
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_paidInstallments / $_totalInstallments قسط',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _progressPercentage == 1.0
                        ? const Color(0xFF10B981)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressPercentage,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _progressPercentage == 1.0
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Percentage Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progressPercentage * 100).toStringAsFixed(1)}% مكتمل',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: _progressPercentage == 1.0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _progressPercentage == 1.0
                    ? '✓ تم السداد بالكامل'
                    : 'متبقي ${_totalInstallments - _paidInstallments} أقساط',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: _progressPercentage == 1.0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentScheduleTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'تاريخ الاستحقاق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'المبلغ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الحالة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paymentSchedule.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final schedule = _paymentSchedule[index];
              return _buildScheduleRow(schedule);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(PaymentScheduleModel schedule) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: schedule.isOverdue
            ? const Color(0xFFEF4444).withOpacity(0.05)
            : schedule.isPaid
            ? const Color(0xFF10B981).withOpacity(0.05)
            : null,
      ),
      child: Row(
        children: [
          // Installment Number
          Expanded(
            flex: 1,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: schedule.isPaid
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${schedule.installmentNo}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: schedule.isPaid
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),

          // Due Date
          Expanded(
            flex: 3,
            child: Text(
              schedule.formattedDueDate,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.formatCurrency(schedule.amount.toDouble()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(schedule).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(schedule),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(schedule),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentScheduleModel schedule) {
    if (schedule.isPaid) {
      return const Color(0xFF10B981); // Green
    } else if (schedule.isOverdue) {
      return const Color(0xFFEF4444); // Red
    } else if (schedule.isPartiallyPaid) {
      return const Color(0xFFF59E0B); // Orange
    } else {
      return const Color(0xFF64748B); // Gray
    }
  }

  String _getStatusText(PaymentScheduleModel schedule) {
    if (schedule.isPaid) {
      return 'مدفوع';
    } else if (schedule.isOverdue) {
      return 'متأخر';
    } else if (schedule.isPartiallyPaid) {
      return 'جزئي';
    } else {
      return 'معلق';
    }
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                size: 18,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              const Text(
                'ملاحظات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _installmentPlan!.notes!,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Color(0xFF78350F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
