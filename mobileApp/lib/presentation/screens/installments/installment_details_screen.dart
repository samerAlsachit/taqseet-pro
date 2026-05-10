import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api/api_service.dart';
import 'receipt_screen.dart';

class InstallmentDetailsScreen extends StatefulWidget {
  final String planId;

  const InstallmentDetailsScreen({super.key, required this.planId});

  @override
  State<InstallmentDetailsScreen> createState() =>
      _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  Map<String, dynamic>? _plan;
  List<dynamic> _schedule = [];
  List<dynamic> _payments = [];
  bool _isLoading = true;
  bool _isPaying = false;
  String? _error;

  // Light theme colors
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access provider after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get apiService from context safely after build
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.get('/installments/${widget.planId}');

      if (result.success && result.data != null) {
        final data = result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : <String, dynamic>{};
        final innerData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        setState(() {
          _plan = innerData['plan'] is Map<String, dynamic>
              ? innerData['plan'] as Map<String, dynamic>
              : null;
          _schedule = innerData['installments'] is List
              ? innerData['installments'] as List<dynamic>
              : [];
          _payments = innerData['payments'] is List
              ? innerData['payments'] as List<dynamic>
              : [];
          _isLoading = false;
        });

        debugPrint('✅ Loaded installment plan: ${_plan?['product_name']}');
        debugPrint('📊 Schedule items: ${_schedule.length}');
        debugPrint('💰 Payments: ${_payments.length}');
      } else {
        setState(() {
          _error = result.message ?? 'القسط غير موجود';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في جلب البيانات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'تفاصيل القسط',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plan Info Card
                        _buildPlanInfoCard(),
                        const SizedBox(height: 24),
                        // Schedule Table with Quick Pay
                        _buildScheduleTable(),
                        const SizedBox(height: 24),
                        // Payments History with Print
                        if (_payments.isNotEmpty) _buildPaymentsHistory(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPlanInfoCard() {
    final totalPrice = _plan?['total_price'] ?? 0;
    final remaining = _plan?['remaining_amount'] ?? 0;
    final downPayment = _plan?['down_payment'] ?? 0;
    final installmentAmount = _plan?['installment_amount'] ?? 0;
    final installmentsCount = _plan?['installments_count'] ?? 0;
    final frequency = _plan?['frequency'] ?? 'monthly';
    final status = _plan?['status'] ?? 'active';
    final currency = _plan?['currency'] ?? 'IQD';
    final customerName = _plan?['customer_name'] ?? 'غير محدد';
    final productName = _plan?['product_name'] ?? 'غير محدد';

    final paidCount = _schedule.where((s) => s['status'] == 'paid').length;
    final progress =
        installmentsCount > 0 ? (paidCount / installmentsCount) : 0;

    String frequencyText;
    switch (frequency) {
      case 'monthly':
        frequencyText = 'شهري';
        break;
      case 'weekly':
        frequencyText = 'أسبوعي';
        break;
      case 'daily':
        frequencyText = 'يومي';
        break;
      default:
        frequencyText = frequency;
    }

    Color statusColor;
    String statusText;
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'نشط';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'مكتمل';
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusText = 'متأخر';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'معلق';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'معلومات القسط',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('العميل', customerName),
            _buildInfoRow('المنتج', productName),
            _buildInfoRow('المبلغ الكلي', '$totalPrice $currency'),
            _buildInfoRow('المتبقي', '$remaining $currency', isHighlight: true),
            _buildInfoRow('الدفعة المقدمة', '$downPayment $currency'),
            _buildInfoRow('قيمة القسط', '$installmentAmount $currency'),
            _buildInfoRow('نظام الدفع', frequencyText),
            _buildInfoRow('عدد الأقساط', '$installmentsCount'),
            const SizedBox(height: 20),
            // Progress Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقدم',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$paidCount/$installmentsCount قسط مدفوع',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      backgroundColor: cardBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.electric),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.red : textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable() {
    final currency = _plan?['currency'] ?? 'IQD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جدول الأقساط',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: _schedule.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
            itemBuilder: (context, index) {
              final item = _schedule[index];
              final installmentNo = item['installment_no'] ?? (index + 1);
              final dueDate = item['due_date'] ?? '';
              final amount = item['amount'] ?? 0;
              final status = item['status'] ?? 'pending';
              final scheduleId = item['id']?.toString();

              Color statusColor;
              String statusText;
              IconData statusIcon;
              switch (status) {
                case 'paid':
                  statusColor = Colors.green;
                  statusText = 'مدفوع';
                  statusIcon = Icons.check_circle;
                  break;
                case 'pending':
                  statusColor = Colors.orange;
                  statusText = 'قيد الانتظار';
                  statusIcon = Icons.access_time;
                  break;
                case 'overdue':
                  statusColor = Colors.red;
                  statusText = 'متأخر';
                  statusIcon = Icons.warning;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = 'معلق';
                  statusIcon = Icons.help;
              }

              final isPending = status == 'pending';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withOpacity(0.05)
                      : cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPending
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    // Installment Number
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$installmentNo',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Amount and Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$amount $currency',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'تاريخ الاستحقاق: ${_formatDate(dueDate)}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge or Pay Button
                    if (isPending)
                      ElevatedButton.icon(
                        onPressed: _isPaying
                            ? null
                            : () => _showPayConfirmation(
                                scheduleId, amount, installmentNo),
                        icon: _isPaying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.payment, size: 18),
                        label: Text(
                          _isPaying ? 'جاري...' : 'سداد',
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Quick Pay - Show confirmation dialog
  void _showPayConfirmation(
      String? scheduleId, dynamic amount, dynamic installmentNo) {
    if (scheduleId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تأكيد السداد',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد تأكيد سداد القسط رقم $installmentNo؟',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المبلغ:',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  Text(
                    '$amount ${_plan?['currency'] ?? 'IQD'}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(scheduleId, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'تأكيد السداد',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  // Process Payment - Call API
  Future<void> _processPayment(String scheduleId, dynamic amount) async {
    setState(() => _isPaying = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Call payment API like the web app
      final result = await apiService.post('/payments', data: {
        'plan_id': widget.planId,
        'schedule_id': scheduleId,
        'amount_paid': amount,
        'payment_date': DateTime.now().toIso8601String().split('T')[0],
        'notes': 'تم السداد عبر التطبيق',
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الدفعة بنجاح',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh data
        await _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'فشل في تسجيل الدفعة',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isPaying = false);
    }
  }

  Widget _buildPaymentsHistory() {
    final currency = _plan?['currency'] ?? 'IQD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل الدفعات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: _payments.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
            itemBuilder: (context, index) {
              final payment = _payments[index];
              final receiptNumber = payment['receipt_number'] ?? '';
              final paymentDate = payment['payment_date'] ?? '';
              final amount = payment['amount_paid'] ?? 0;
              final notes = payment['notes'] ?? '';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptScreen(
                        payment: payment,
                        plan: _plan,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Success Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      // Payment Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$amount $currency',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'رقم الوصل: $receiptNumber',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              _formatDate(paymentDate),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: textSecondary.withOpacity(0.8),
                              ),
                            ),
                            if (notes.isNotEmpty)
                              Text(
                                notes,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Print/Share Button
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _showReceiptPreview(payment),
                            icon: const Icon(Icons.visibility,
                                color: AppColors.navy),
                            tooltip: 'معاينة الوصل',
                          ),
                          IconButton(
                            onPressed: () => _shareReceipt(payment),
                            icon: const Icon(Icons.share,
                                color: AppColors.electric),
                            tooltip: 'مشاركة الوصل',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Show Receipt Preview Dialog - Light Theme with Dark Text
  void _showReceiptPreview(Map<String, dynamic> payment) {
    final currency = _plan?['currency'] ?? 'IQD';
    final amount = payment['amount_paid'] ?? 0;
    final receiptNumber = payment['receipt_number'] ?? '';
    final paymentDate = payment['payment_date'] ?? '';
    final customerName = _plan?['customer_name'] ?? 'غير محدد';
    final productName = _plan?['product_name'] ?? 'غير محدد';
    final remaining = _plan?['remaining_amount'] ?? 0;

    // Light theme colors
    const Color primaryColor = AppColors.navy;
    const Color lightBackground = Colors.white;
    const Color cardBackground = Color(0xFFF5F7FA);
    const Color darkText = Color(0xFF2D3748);
    const Color greyText = Color(0xFF718096);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: lightBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'وصل دفع',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
                          border:
                              Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.store,
                            size: 40, color: primaryColor),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _buildReceiptRowLight('رقم الوصل', receiptNumber),
                            Divider(height: 16, color: Colors.grey.shade300),
                            _buildReceiptRowLight(
                                'التاريخ', _formatDate(paymentDate)),
                            Divider(height: 16, color: Colors.grey.shade300),
                            _buildReceiptRowLight('العميل', customerName),
                            Divider(height: 16, color: Colors.grey.shade300),
                            _buildReceiptRowLight('المنتج', productName),
                            Divider(height: 16, color: Colors.grey.shade300),
                            _buildReceiptRowLight(
                                'المبلغ المدفوع', '$amount $currency',
                                isBold: true, isHighlighted: true),
                            Divider(height: 16, color: Colors.grey.shade300),
                            _buildReceiptRowLight(
                                'المتبقي', '$remaining $currency'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'شكراً لثقتكم بنا',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                color: AppColors.navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thank you for your trust',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                color: greyText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareReceipt(payment);
                          },
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text(
                            'مشاركة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إغلاق',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Light theme receipt row builder
  Widget _buildReceiptRowLight(String label, String value,
      {bool isBold = false, bool isHighlighted = false}) {
    const Color darkText = Color(0xFF2D3748);
    const Color primaryColor = AppColors.navy;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? primaryColor : darkText,
          ),
        ),
      ],
    );
  }

  // Share Receipt
  void _shareReceipt(Map<String, dynamic> payment) {
    final currency = _plan?['currency'] ?? 'IQD';
    final amount = payment['amount_paid'] ?? 0;
    final receiptNumber = payment['receipt_number'] ?? '';
    final paymentDate = payment['payment_date'] ?? '';
    final customerName = _plan?['customer_name'] ?? 'غير محدد';
    final productName = _plan?['product_name'] ?? 'غير محدد';
    final remaining = _plan?['remaining_amount'] ?? 0;

    final receiptText = '''
*مرساة - وصل دفع*

رقم الوصل: $receiptNumber
التاريخ: ${_formatDate(paymentDate)}
العميل: $customerName
المنتج: $productName

*المبلغ المدفوع: $amount $currency*
المتبقي: $remaining $currency

شكراً لثقتكم بنا
مرساة - نظام إدارة الأقساط
'''
        .trim();

    Share.share(receiptText, subject: 'وصل دفع - $receiptNumber');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
