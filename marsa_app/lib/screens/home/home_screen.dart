import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dashboard_stats.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/theme_notifier.dart';
import '../auth/auth_gate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _dashboard = DashboardService();
  final _biometric = BiometricService();
  String _storeName = '';
  bool _bioEnabled = false;
  DashboardStats _stats = DashboardStats.empty();
  List<Map<String, dynamic>> _latestInstallments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var name = await _auth.getStoreName();
    if (name == null || name.isEmpty) {
      name = await _auth.fetchStoreName();
    }
    final bio = await _biometric.isEnabled();
    final stats = await _dashboard.getStats();
    final installments = await _dashboard.getLatestInstallments();

    if (mounted) {
      setState(() {
        _storeName = name ?? 'مرساة';
        _bioEnabled = bio;
        _stats = stats;
        _latestInstallments = installments;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBio(bool value) async {
    if (value) {
      final available = await _biometric.isAvailable();
      if (!available) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البصمة غير متوفرة على هذا الجهاز')));
        return;
      }
      await _biometric.authenticate();
    }
    await _biometric.setEnabled(value);
    if (mounted) setState(() => _bioEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'مرحباً بك في $_storeName',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Tajawal', color: isDark ? Colors.white : AppColors.navy),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white70 : AppColors.textSecondaryLight),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.white70 : AppColors.textSecondaryLight),
                  onPressed: () => ThemeNotifier.instance.toggle(),
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: isDark ? Colors.white70 : AppColors.textSecondaryLight),
                  onPressed: () async {
                    await _auth.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthGate()), (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(isDark),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatCards(isDark),
                    const SizedBox(height: 24),
                    _buildQuickActions(isDark),
                    const SizedBox(height: 24),
                    _buildLatestInstallments(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.navy, AppColors.electric], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                    child: const Icon(Icons.anchor, size: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('مرساة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
                  Text(_storeName, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontFamily: 'Tajawal')),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('الوضع الليلي', style: TextStyle(fontFamily: 'Tajawal')),
            subtitle: Text(isDark ? 'التغيير إلى الوضع النهاري' : 'التغيير إلى الوضع الليلي', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            onChanged: (_) => ThemeNotifier.instance.toggle(),
          ),
          SwitchListTile(
            title: const Text('الدخول بالبصمة', style: TextStyle(fontFamily: 'Tajawal')),
            subtitle: const Text('تسجيل الدخول باستخدام بصمة الإصبع', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
            secondary: const Icon(Icons.fingerprint),
            value: _bioEnabled,
            onChanged: _toggleBio,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق', style: TextStyle(fontFamily: 'Tajawal')),
            subtitle: const Text('v1.0.0', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.danger)),
            onTap: () async {
              await _auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthGate()), (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(bool isDark) {
    return Column(
      children: [
        _StatCard(
          icon: Icons.people_outline,
          label: 'إجمالي العملاء',
          value: '${_stats.totalCustomers}',
          color: AppColors.electric,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.receipt_long_outlined,
          label: 'الأقساط النشطة',
          value: '${_stats.activeInstallments}',
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.trending_up,
          label: 'تحصيلات اليوم',
          value: _formatAmount(_stats.todayCollection),
          color: AppColors.electric,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.error_outline,
          label: 'الأقساط المتأخرة',
          value: _formatAmount(_stats.overdue),
          color: AppColors.danger,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'المستحقة اليوم',
          value: _formatAmount(_stats.dueToday),
          color: AppColors.warning,
          isDark: isDark,
        ),
      ],
    );
  }

  String _formatAmount(Amount amt) {
    if (amt.iqd == 0 && amt.usd == 0) return '0';
    final parts = <String>[];
    if (amt.iqd > 0) parts.add('${amt.iqd.toStringAsFixed(0)} IQD');
    if (amt.usd > 0) parts.add('\$${amt.usd.toStringAsFixed(2)}');
    return parts.join(' / ');
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionButton(label: 'عميل جديد', icon: Icons.person_add, gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)])),
            const SizedBox(width: 10),
            Expanded(child: _ActionButton(label: 'قسط جديد', icon: Icons.receipt_long, gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _ActionButton(label: 'منتج جديد', icon: Icons.inventory_2, gradient: const [Color(0xFF14B8A6), Color(0xFF0D9488)])),
            const SizedBox(width: 10),
            Expanded(child: _ActionButton(label: 'تسديد دفعة', icon: Icons.credit_card, gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)])),
          ],
        ),
      ],
    );
  }

  Widget _buildLatestInstallments(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('آخر الأقساط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.electric, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_latestInstallments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('لا توجد أقساط مسجلة', style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
              ),
            )
          else
            ..._latestInstallments.map((inst) => _buildInstallmentRow(inst, isDark)),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow(Map<String, dynamic> inst, bool isDark) {
    final status = inst['status']?.toString() ?? '';
    final currency = inst['currency']?.toString() ?? 'IQD';
    final totalPrice = (inst['total_price'] as num?)?.toDouble() ?? 0;
    final remaining = (inst['remaining_amount'] as num?)?.toDouble() ?? 0;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        statusText = 'نشط';
        break;
      case 'completed':
        statusColor = AppColors.electric;
        statusText = 'مكتمل';
        break;
      default:
        statusColor = AppColors.danger;
        statusText = 'متأخر';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF30363D) : const Color(0xFFF0F2F5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inst['customer_name']?.toString() ?? '', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827), fontSize: 14)),
                Text(inst['product_name']?.toString() ?? '', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$totalPrice $currency', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827), fontSize: 13)),
                Text('متبقي: $remaining $currency', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusText, style: TextStyle(color: statusColor, fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _ActionButton({required this.label, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: gradient.last.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
