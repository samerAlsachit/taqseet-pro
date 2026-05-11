import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/installment_bloc/installment_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/print_service.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final String installmentId;
  const InstallmentDetailScreen({super.key, required this.installmentId});

  @override
  State<InstallmentDetailScreen> createState() => _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  final _printService = PrintService();

  @override
  void initState() {
    super.initState();
    context.read<InstallmentBloc>().add(LoadInstallmentDetail(widget.installmentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل القسط'), actions: [
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: () => _printReceipt(),
          tooltip: 'طباعة الوصل',
        ),
      ]),
      body: BlocBuilder<InstallmentBloc, InstallmentState>(
        builder: (context, state) {
          if (state is InstallmentLoading) return const LoadingWidget();
          if (state is InstallmentError) return ErrorDisplay(message: state.message);
          if (state is InstallmentDetailLoaded) return _buildDetail(state);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetail(InstallmentDetailLoaded state) {
    final inst = state.installment;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('معلومات القسط', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: inst.status == 'active' ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(Formatters.status(inst.status), style: TextStyle(color: inst.status == 'active' ? AppColors.success : AppColors.danger, fontFamily: 'Tajawal')),
                    ),
                  ],
                ),
                const Divider(),
                _row('العميل', inst.customerName ?? '#${inst.customerId}'),
                _row('المبلغ', Formatters.currency(inst.totalPrice, currency: inst.currency)),
                _row('الدفعة الأولى', Formatters.currency(inst.downPayment, currency: inst.currency)),
                _row('المتبقي', Formatters.currency(inst.remainingAmount, currency: inst.currency)),
                _row('نوع القسط', Formatters.frequency(inst.frequency)),
                _row('تاريخ البداية', Formatters.date(inst.startDate)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('جدول الدفعات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('تسديد', style: TextStyle(fontFamily: 'Tajawal')),
              onPressed: () => Navigator.pushNamed(context, '/payment', arguments: {'plan_id': widget.installmentId}),
            ),
          ],
        ),
        if (state.schedules.isEmpty)
          const EmptyState(message: 'لا توجد دفعات مجدولة', icon: Icons.calendar_view_month)
        else
          ...state.schedules.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              title: Text('الدفعة #${s.installmentNo}', style: const TextStyle(fontFamily: 'Tajawal')),
              subtitle: Text(Formatters.date(s.dueDate), style: const TextStyle(fontFamily: 'Tajawal')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formatters.currency(s.amount), style: const TextStyle(fontFamily: 'Tajawal')),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: s.status == 'paid' ? AppColors.success.withValues(alpha: 0.1) : s.status == 'overdue' ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(Formatters.status(s.status), style: TextStyle(fontSize: 11, color: s.status == 'paid' ? AppColors.success : s.status == 'overdue' ? AppColors.danger : AppColors.warning, fontFamily: 'Tajawal')),
                  ),
                ],
              ),
            ),
          )),
        const SizedBox(height: 16),
        const Text('الوصولات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        if (state.payments.isEmpty)
          const EmptyState(message: 'لا توجد وصولات', icon: Icons.receipt)
        else
          ...state.payments.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.receipt, color: AppColors.electric),
              title: Text('وصل #${p.receiptNumber ?? p.id}', style: const TextStyle(fontFamily: 'Tajawal')),
              subtitle: Text(Formatters.date(p.paymentDate), style: const TextStyle(fontFamily: 'Tajawal')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formatters.currency(p.amountPaid), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print, size: 18),
                    onPressed: () => _printReceipt(),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Tajawal')),
      ],
    ),
  );

  Future<void> _printReceipt() async {
    try {
      await _printService.printReceipt(
        '<h2 style="font-family: Tajawal; text-align: center;">مرساة</h2>'
        '<p style="text-align: center;">وصل دفع</p>'
        '<hr>'
        '<p>رقم القسط: ${widget.installmentId}</p>'
        '<p>التاريخ: ${Formatters.date(DateTime.now())}</p>'
        '<hr>'
        '<p style="text-align: center;">شكراً لتعاملكم</p>'
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الوصل للطباعة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشلت الطباعة: $e')));
      }
    }
  }
}
