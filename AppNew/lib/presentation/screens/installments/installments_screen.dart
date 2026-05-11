import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/installment_bloc/installment_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<InstallmentBloc>().add(LoadInstallments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأقساط'), actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.pushNamed(context, '/installments/new'),
        ),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'بحث...', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (v) => context.read<InstallmentBloc>().add(LoadInstallments(search: v, status: _statusFilter)),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('الكل', null),
                _filterChip('نشط', 'active'),
                _filterChip('مكتمل', 'completed'),
                _filterChip('متأخر', 'overdue'),
                _filterChip('ملغي', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<InstallmentBloc, InstallmentState>(
              builder: (context, state) {
                if (state is InstallmentLoading) return const LoadingWidget();
                if (state is InstallmentError) return ErrorDisplay(message: state.message);
                if (state is InstallmentLoaded && state.installments.isEmpty) return const EmptyState(message: 'لا توجد أقساط');
                if (state is InstallmentLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.installments.length,
                    itemBuilder: (context, index) {
                      final item = state.installments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.customerName ?? '#${item.customerId}', style: const TextStyle(fontFamily: 'Tajawal')),
                          subtitle: Text('متبقي: ${Formatters.currency(item.remainingAmount)}', style: const TextStyle(fontFamily: 'Tajawal')),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(Formatters.currency(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                              Text(Formatters.status(item.status), style: TextStyle(fontSize: 12, color: item.status == 'active' ? AppColors.success : item.status == 'overdue' ? AppColors.danger : AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                            ],
                          ),
                          onTap: () => Navigator.pushNamed(context, '/installments/${item.id}'),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          context.read<InstallmentBloc>().add(LoadInstallments(search: _searchController.text, status: status));
        },
        selectedColor: AppColors.electric.withValues(alpha: 0.2),
        checkmarkColor: AppColors.electric,
      ),
    );
  }
}
