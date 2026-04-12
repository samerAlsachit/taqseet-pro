import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/installment_provider.dart';
import '../models/installment_model.dart';
import '../core/utils/formatter.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import 'add_installment_screen.dart';
import 'installments_screen.dart' hide InstallmentModel;
import 'login_screen.dart';
import 'payment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalDBService _localDB = LocalDBService();
  final SyncService _syncService = SyncService();

  List<InstallmentModel> _localInstallments = [];
  bool _isLoadingFromHive = true;
  SyncStatus _syncStatus = SyncStatus.idle;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Initialize Hive first
    await _localDB.init();

    // Load data from Hive immediately for fast display
    setState(() {
      _localInstallments = _localDB.getAllInstallments();
      _isLoadingFromHive = false;
      _pendingSyncCount = _localDB.getUnsyncedCount();
    });

    // Initialize sync service and start monitoring
    await _syncService.init();

    // Listen to sync status updates
    _syncService.syncStatusStream.listen((status) {
      setState(() {
        _syncStatus = status;
        if (status == SyncStatus.completed || status == SyncStatus.partial) {
          // Refresh local data after successful sync
          _localInstallments = _localDB.getAllInstallments();
          _pendingSyncCount = _localDB.getUnsyncedCount();
        }
      });
    });

    // Trigger initial sync if online
    final isOnline = await _syncService.isOnline();
    if (isOnline && _pendingSyncCount > 0) {
      _syncService.syncPendingInstallments();
    }

    // Also load from provider (for mock data fallback or remote updates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstallmentProvider>().loadInstallments();
    });
  }

  Future<void> _refreshData() async {
    // Pull-to-refresh: reload from Hive and trigger sync
    setState(() {
      _isLoadingFromHive = true;
    });

    _localInstallments = _localDB.getAllInstallments();
    _pendingSyncCount = _localDB.getUnsyncedCount();

    setState(() {
      _isLoadingFromHive = false;
    });

    // Trigger sync
    await _syncService.syncPendingInstallments();
  }

  @override
  void dispose() {
    _syncService.dispose();
    _localDB.close();
    super.dispose();
  }

  String _formatNumber(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }

  /// Count installments due today
  int _getDueTodayCount(InstallmentProvider provider) {
    final today = DateTime.now();
    return provider.installments.where((i) {
      return i.dueDate.year == today.year &&
          i.dueDate.month == today.month &&
          i.dueDate.day == today.day &&
          i.status != 'completed';
    }).length;
  }

  /// Logout function - clears session and navigates to login
  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A192F),
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج من متجرك؟',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.logOut, size: 18),
                SizedBox(width: 8),
                Text(
                  'نعم، خروج',
                  style: TextStyle(
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
    );

    if (shouldLogout == true && mounted) {
      // TODO: Clear session data from SharedPreferences if implemented
      // Example: await SharedPreferences.getInstance().then((prefs) => prefs.clear());

      // Navigate to login screen and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstallmentProvider>(
      builder: (context, provider, child) {
        // Merge local Hive data with provider data (prioritize local for speed)
        final displayInstallments = _localInstallments.isNotEmpty
            ? _localInstallments
            : provider.installments;

        if (provider.isLoading && _isLoadingFromHive) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A192F)),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSummarySection(provider),
                  const SizedBox(height: 24),
                  _buildUrgentAlertCard(provider),
                  const SizedBox(height: 24),
                  _buildQuickActionsWithSearch(),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(provider, displayInstallments),
                  const SizedBox(height: 24),
                  // Sync status indicator
                  if (_pendingSyncCount > 0) _buildSyncStatusCard(),
                ],
              ),
            ),
          ),
        );
      },
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
            const SizedBox(width: 12),
            _buildLogoutIcon(),
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

  Widget _buildLogoutIcon() {
    return InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.logOut,
          color: Color(0xFFEF4444),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSummarySection(InstallmentProvider provider) {
    final total = provider.totalRemaining + provider.todayCollected;
    final remainingPercent = total > 0 ? provider.totalRemaining / total : 0.0;
    final collectedPercent = total > 0 ? provider.todayCollected / total : 0.0;

    return Row(
      children: [
        // Remaining Card (المتبقي) - Deep Blue
        Expanded(
          child: _buildSummaryCard(
            title: 'المتبقي',
            amount: provider.totalRemaining,
            textColor: const Color(0xFF0A192F),
            progressColor: const Color(0xFF0A192F),
            progressValue: remainingPercent,
          ),
        ),
        const SizedBox(width: 12),
        // Collected Card (المحصل) - Green #27AE60
        Expanded(
          child: _buildSummaryCard(
            title: 'المحصل',
            amount: provider.todayCollected,
            textColor: const Color(0xFF27AE60),
            progressColor: const Color(0xFF27AE60),
            progressValue: collectedPercent,
          ),
        ),
        const SizedBox(width: 12),
        // Total Card (الإجمالي) - Dark Gray
        Expanded(
          child: _buildSummaryCard(
            title: 'الإجمالي',
            amount: total,
            textColor: const Color(0xFF374151),
            progressColor: const Color(0xFF6B7280),
            progressValue: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color textColor,
    required Color progressColor,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontFamily: 'Tajawal',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatNumber(amount),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          // Thin LinearProgressIndicator
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: progressColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentAlertCard(InstallmentProvider provider) {
    final dueTodayCount = _getDueTodayCount(provider);

    if (dueTodayCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Light orange
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFED7AA).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bell,
              color: Color(0xFFF97316),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لديك [$dueTodayCount] أقساط مستحقة اليوم، هل تريد تذكيرهم؟',
                  style: const TextStyle(
                    color: Color(0xFF7C2D12),
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Navigate to installments screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstallmentsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'تذكير الجميع',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsWithSearch() {
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
        // Search Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'بحث سريع عن عميل...',
              hintStyle: const TextStyle(
                fontFamily: 'Tajawal',
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: Color(0xFF64748B),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            onTap: () {
              // Navigate to installments screen for search
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstallmentsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Action Buttons Row
        Row(
          children: [
            // Add Installment Button - Elevated (Prominent)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddInstallmentScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.plusCircle, size: 20),
                label: const Text(
                  'إضافة قسط',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Collect Button - Outlined
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0A192F),
                  side: const BorderSide(color: Color(0xFF0A192F), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(LucideIcons.download, size: 20),
                label: const Text(
                  'تحصيل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    InstallmentProvider provider,
    List<InstallmentModel> displayInstallments,
  ) {
    // Use displayInstallments (from Hive) or fall back to provider.recentTransactions
    final transactions = displayInstallments.isNotEmpty
        ? displayInstallments.take(3).toList()
        : provider.recentTransactions.take(3).toList();

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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InstallmentsScreen(),
                  ),
                );
              },
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
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                'لا توجد عمليات حديثة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
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
        borderRadius: BorderRadius.circular(15),
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
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 12, color: tx.statusColor),
                    const SizedBox(width: 4),
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
              ],
            ),
          ),
          Text(
            _formatNumber(tx.remainingAmount),
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

  Widget _buildSyncStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFED7AA).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _syncStatus == SyncStatus.inProgress
                  ? LucideIcons.loader2
                  : LucideIcons.cloudOff,
              color: const Color(0xFFF97316),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_pendingSyncCount عملية معلقة',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C2D12),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _syncStatus == SyncStatus.inProgress
                      ? 'جاري المزامنة...'
                      : 'في انتظار الاتصال بالإنترنت',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_syncStatus != SyncStatus.inProgress)
            TextButton(
              onPressed: () => _syncService.syncPendingInstallments(),
              child: const Text(
                'مزامنة الآن',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
