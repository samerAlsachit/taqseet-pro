import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/installment_provider.dart';
import '../models/installment_model.dart';
import 'add_installment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstallmentProvider>().loadInstallments();
    });
  }

  String _formatNumber(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Consumer<InstallmentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A192F)),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadInstallments(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSummarySection(provider),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    _buildRecentTransactions(provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك،',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontFamily: 'Tajawal',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'سامر',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A192F),
                fontFamily: 'Tajawal',
                fontSize: 24,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIcon(LucideIcons.bell),
            const SizedBox(width: 12),
            _buildCircleIcon(LucideIcons.user),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF0A192F), size: 20),
    );
  }

  Widget _buildSummarySection(InstallmentProvider provider) {
    return Column(
      children: [
        _buildMainCard('إجمالي الديون', provider.totalRemaining),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                'المحصل',
                provider.todayCollected,
                LucideIcons.trendingUp,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallCard(
                'المتبقي',
                provider.totalRemaining,
                LucideIcons.creditCard,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard(String title, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatNumber(amount)} د.ع',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontFamily: 'Tajawal',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatNumber(amount)} د.ع',
            style: const TextStyle(
              color: Color(0xFF0A192F),
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            color: Color(0xFF0A192F),
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionItem(
              LucideIcons.plusCircle,
              'إضافة قسط',
              const Color(0xFFE3F2FD),
              const Color(0xFF1976D2),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddInstallmentScreen(),
                  ),
                );
              },
            ),
            _buildActionItem(
              LucideIcons.download,
              'تحصيل',
              const Color(0xFFE8F5E8),
              const Color(0xFF388E3C),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ميزة التحصيل قريباً',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                    backgroundColor: Color(0xFF0A192F),
                  ),
                );
              },
            ),
            _buildActionItem(
              LucideIcons.barChart3,
              'تقارير',
              const Color(0xFFFFF3E0),
              const Color(0xFFF57C00),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ميزة التقارير قريباً',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                    backgroundColor: Color(0xFF0A192F),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0A192F),
              fontFamily: 'Tajawal',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(InstallmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'أحدث العمليات',
              style: TextStyle(
                color: Color(0xFF0A192F),
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                fontSize: 18,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  color: Color(0xFF1976D2),
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.recentTransactions.length,
          itemBuilder: (context, index) {
            final tx = provider.recentTransactions[index];
            return _buildTransactionItem(tx);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(InstallmentModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx.statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.status == 'completed' ? LucideIcons.check : LucideIcons.clock,
              color: tx.statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                  ),
                ),
                Text(
                  tx.statusDisplay,
                  style: TextStyle(
                    color: tx.statusColor,
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatNumber(tx.remainingAmount)} د.ع',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
