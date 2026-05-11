import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/dashboard_bloc/dashboard_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) return const LoadingWidget(message: 'جاري تحميل البيانات...');
        if (state is DashboardError) return ErrorDisplay(message: state.message, onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()));
        if (state is DashboardLoaded) return _buildDashboard(state);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDashboard(DashboardLoaded state) {
    final stats = state.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحباً', style: TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                  Text('المحل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.danger),
                onPressed: () => _logout(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard('إجمالي العملاء', '${stats?.totalCustomers ?? 0}', Icons.people, AppColors.electric),
              _statCard('الأقساط النشطة', '${stats?.activeInstallments ?? 0}', Icons.receipt_long, AppColors.success),
              _statCard('تحصيلات اليوم', _formatCurrency(stats?.todayCollection), Icons.trending_up, AppColors.electric),
              _statCard('مستحقة اليوم', _formatCurrency(stats?.dueToday), Icons.calendar_today, AppColors.warning),
              _statCard('متأخرات', _formatCurrency(stats?.overdue), Icons.error_outline, AppColors.danger),
            ],
          ),
          const SizedBox(height: 20),
          const Text('الوصول السريع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _quickAction(context, 'إضافة عميل', Icons.person_add, AppColors.electric, '/customers/new'),
                _quickAction(context, 'قسط جديد', Icons.add_chart, const Color(0xFF7C3AED), '/installments/new'),
                _quickAction(context, 'منتج جديد', Icons.inventory_2, const Color(0xFF0D9488), '/products/new'),
                _quickAction(context, 'تسديد دفعة', Icons.payment, const Color(0xFFD97706), '/payment'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('آخر الأقساط', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          const SizedBox(height: 12),
          if (state.recentInstallments.isEmpty)
            const EmptyState(message: 'لا توجد أقساط مسجلة', icon: Icons.receipt_long)
          else
            ...state.recentInstallments.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.customerName ?? '#${item.customerId}', style: const TextStyle(fontFamily: 'Tajawal')),
                subtitle: Text('${Formatters.currency(item.totalPrice)} - ${Formatters.status(item.status)}', style: const TextStyle(fontFamily: 'Tajawal')),
                trailing: Text(Formatters.currency(item.remainingAmount), style: const TextStyle(color: AppColors.electric, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                onTap: () => Navigator.pushNamed(context, '/installments/${item.id}'),
              ),
            )),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, fontFamily: 'Tajawal')),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontFamily: 'Tajawal'), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(Map<String, double>? map) {
    if (map == null || map.isEmpty) return '0';
    return map.entries.map((e) => '${e.value.toInt()} ${e.key}').join(' / ');
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Tajawal')),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('خروج', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }
}
