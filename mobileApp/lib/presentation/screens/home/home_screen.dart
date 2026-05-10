import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../customers/customers_screen.dart';
import '../installments/installments_screen.dart';
import '../inventory/inventory_screen.dart';
import '../cash_sales/cash_sales_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final user = authProvider.user;

    // Check for subscription errors from API calls
    if (customerProvider.error != null) {
      final isSubscriptionError =
          customerProvider.error!.toLowerCase().contains('subscription') ||
              customerProvider.error!.toLowerCase().contains('expired') ||
              customerProvider.error!.toLowerCase().contains('403') ||
              customerProvider.error!.contains('اشتراك') ||
              customerProvider.error!.contains('منتهي') ||
              customerProvider.error!.contains('تجديد');

      if (isSubscriptionError && !authProvider.isSubscriptionExpired) {
        // Use Future.microtask to avoid setState during build
        Future.microtask(() {
          authProvider.checkAndHandleSubscriptionError(customerProvider.error);
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription Expired Warning Banner
              if (authProvider.isSubscriptionExpired)
                _buildSubscriptionWarning(
                    authProvider.subscriptionErrorMessage),
              if (authProvider.isSubscriptionExpired)
                const SizedBox(height: 16),

              // Header
              _buildHeader(context, user?.fullName ?? 'مستخدم'),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsCards(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build subscription expired warning banner
  Widget _buildSubscriptionWarning(String? message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ تنبيه مهم',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message ??
                      'انتهى اشتراكك. لم يتم جلب البيانات. يرجى التجديد للاستمرار.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: AppColors.danger.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحباً بك',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.logout, color: AppColors.danger),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'العملاء',
        'value': '0',
        'icon': Icons.people,
        'color': AppColors.electric
      },
      {
        'title': 'الأقساط النشطة',
        'value': '0',
        'icon': Icons.payment,
        'color': AppColors.success
      },
      {
        'title': 'المبيعات اليوم',
        'value': '0',
        'icon': Icons.point_of_sale,
        'color': AppColors.warning
      },
      {
        'title': 'المخزون',
        'value': '0',
        'icon': Icons.inventory,
        'color': AppColors.navy
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: stats.map((stat) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                stat['value'] as String,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat['title'] as String,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'عميل جديد',
        'icon': Icons.person_add,
        'screen': const CustomersScreen()
      },
      {
        'title': 'قسط جديد',
        'icon': Icons.add_card,
        'screen': const InstallmentsScreen()
      },
      {
        'title': 'بيع نقدي',
        'icon': Icons.point_of_sale,
        'screen': const CashSalesScreen()
      },
      {
        'title': 'إضافة منتج',
        'icon': Icons.add_box,
        'screen': const InventoryScreen()
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: actions.map((action) {
            return GestureDetector(
              onTap: () {
                // Navigate to respective screen
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.electric.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: AppColors.electric,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['title'] as String,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر النشاطات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'لا توجد نشاطات حديثة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
