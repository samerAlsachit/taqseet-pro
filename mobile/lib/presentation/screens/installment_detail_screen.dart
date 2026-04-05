import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/installment.dart';
import '../../data/models/payment_schedule.dart';
import '../../presentation/providers/installment_provider.dart';
import '../../core/theme/app_theme.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final Installment installment;

  const InstallmentDetailScreen({super.key, required this.installment});

  @override
  State<InstallmentDetailScreen> createState() => _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  List<PaymentSchedule> _schedule = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstallmentDetails();
  }

  Future<void> _loadInstallmentDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<InstallmentProvider>(context, listen: false);
      await provider.fetchInstallmentDetails(id: widget.installment.id!);
      
      if (mounted) {
        setState(() {
          _schedule = provider.schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makePayment(PaymentSchedule payment) async {
    try {
      final provider = Provider.of<InstallmentProvider>(context, listen: false);
      await provider.makePayment(scheduleId: payment.id!, amount: payment.amount);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسديد القسط بنجاح')),
        );
        // Refresh the data
        await _loadInstallmentDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التسديد: $e')),
        );
      }
    }
  }

  double get _progressPercentage {
    if (_schedule.isEmpty) return 0.0;
    final paidCount = _schedule.where((s) => s.status == 'paid').length;
    return paidCount / _schedule.length;
  }

  int get _paidAmount {
    return _schedule
        .where((s) => s.status == 'paid')
        .fold(0, (sum, s) => sum + s.amount);
  }

  int get _remainingAmount {
    return widget.installment.remainingAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل القسط'),
        backgroundColor: AppColors.electric,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstallmentDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInstallmentDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error,
                          size: 64,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ: $_error',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInstallmentDetails,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Installment Info Card
                        _buildInstallmentInfoCard(),
                        const SizedBox(height: 24),
                        
                        // Progress Card
                        _buildProgressCard(),
                        const SizedBox(height: 24),
                        
                        // Payment Schedule Card
                        _buildPaymentScheduleCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInstallmentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات القسط',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            if (widget.installment.customerName?.isNotEmpty == true) ...[
              _buildInfoRow('العميل:', widget.installment.customerName!),
              const SizedBox(height: 8),
            ],
            
            _buildInfoRow('المنتج:', widget.installment.productName),
            const SizedBox(height: 8),
            
            _buildInfoRow('المبلغ الكلي:', '${widget.installment.formattedTotalPrice}'),
            const SizedBox(height: 8),
            
            _buildInfoRow('الدفعة المقدمة:', '${widget.installment.downPayment} IQD'),
            const SizedBox(height: 8),
            
            _buildInfoRow('المبلغ الممول:', '${widget.installment.financedAmount} IQD'),
            const SizedBox(height: 8),
            
            _buildInfoRow('مبلغ القسط:', '${widget.installment.installmentAmount} IQD'),
            const SizedBox(height: 8),
            
            _buildInfoRow('عدد الأقساط:', '${widget.installment.installmentsCount}'),
            const SizedBox(height: 8),
            
            _buildInfoRow('نظام الدفع:', _getFrequencyDisplay(widget.installment.frequency)),
            const SizedBox(height: 8),
            
            _buildInfoRow('تاريخ البدء:', widget.installment.startDate.toString().split(' ')[0]),
            const SizedBox(height: 8),
            
            _buildInfoRow('تاريخ الانتهاء:', widget.installment.endDate.toString().split(' ')[0]),
            const SizedBox(height: 8),
            
            _buildInfoRow('الحالة:', _getStatusDisplay(widget.installment.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تقدم السداد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            LinearProgressIndicator(
              value: _progressPercentage,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.installment.isCompleted
                    ? AppColors.success
                    : AppColors.electric,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      '${(_progressPercentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.electric,
                      ),
                    ),
                    const Text(
                      'نسبة الإكمال',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$_paidAmount IQD',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const Text(
                      'المبلغ المدفوع',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$_remainingAmount IQD',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    const Text(
                      'المبلغ المتبقي',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'جدول الأقساط',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_schedule.length} قسط',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_schedule.isEmpty)
              const Center(
                child: Text('لا توجد أقساط'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedule.length,
                itemBuilder: (context, index) {
                  final payment = _schedule[index];
                  return _buildPaymentItem(payment);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentSchedule payment) {
    final isPaid = payment.status == 'paid';
    final isOverdue = !isPaid && DateTime.now().isAfter(payment.dueDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPaid 
          ? AppColors.success.withOpacity(0.1)
          : isOverdue
              ? AppColors.danger.withOpacity(0.1)
              : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid
              ? AppColors.success
              : isOverdue
                  ? AppColors.danger
                  : AppColors.electric,
          child: Icon(
            isPaid ? Icons.check : isOverdue ? Icons.warning : Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('القسط ${payment.installmentNo}'),
        subtitle: Text(
          'تاريخ الاستحقاق: ${payment.dueDate.toString().split(' ')[0]}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${payment.amount} IQD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.electric,
                  ),
                ),
                Text(
                  _getStatusDisplay(payment.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaid
                        ? AppColors.success
                        : isOverdue
                            ? AppColors.danger
                            : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!isPaid) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _makePayment(payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electric,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('سدد'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFrequencyDisplay(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      default:
        return frequency;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'pending':
        return 'معلق';
      case 'paid':
        return 'مدفوع';
      default:
        return status;
    }
  }
}
