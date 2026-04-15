import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../providers/installment_provider.dart';
import '../models/installment_model.dart' as app_models;
import '../models/customer_model.dart';
import 'installment_details_screen.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load installments from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstallmentProvider>().loadInstallments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<app_models.InstallmentModel> getFilteredInstallments(
    String status,
    List<app_models.InstallmentModel> installments,
  ) {
    List<app_models.InstallmentModel> filtered = installments;

    if (status == 'active') {
      filtered = installments.where((i) => i.status == 'active').toList();
    } else if (status == 'completed') {
      filtered = installments.where((i) => i.status == 'completed').toList();
    } else if (status == 'overdue') {
      filtered = installments.where((i) => i.status == 'overdue').toList();
    }

    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (i) =>
              i.customerName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  String _formatNumber(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'overdue':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'overdue':
        return 'متأخر';
      default:
        return 'غير معروف';
    }
  }

  /// Send WhatsApp reminder message
  Future<void> _sendWhatsAppReminder(
    app_models.InstallmentModel installment,
  ) async {
    // TODO: Get phone number from customer record
    // For now, show message that feature needs customer data
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ميزة التذكير عبر الواتساب تحتاج إلى ربط بيانات العميل',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstallmentProvider>(
      builder: (context, provider, child) {
        final installments = provider.installments;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'الأقساط',
              style: TextStyle(
                color: Color(0xFF0A192F),
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0A192F),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0A192F),
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal'),
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'مكتمل'),
                Tab(text: 'متأخر'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  decoration: InputDecoration(
                    hintText: 'البحث عن قسط...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF0A192F),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Stats Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'إجمالي الأقساط',
                        '${provider.installments.length}',
                        LucideIcons.fileText,
                        const Color(0xFF0A192F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'المتأخرة',
                        '${provider.installments.where((i) => i.status == 'overdue').length}',
                        LucideIcons.alertCircle,
                        const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInstallmentsList('all', provider.installments),
                    _buildInstallmentsList('completed', provider.installments),
                    _buildInstallmentsList('overdue', provider.installments),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A192F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsList(
    String filter,
    List<app_models.InstallmentModel> installments,
  ) {
    final filtered = getFilteredInstallments(filter, installments);

    if (filtered.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildInstallmentCard(filtered[index]);
      },
    );
  }

  Widget _buildInstallmentCard(app_models.InstallmentModel installment) {
    final statusColor = _getStatusColor(installment.status);
    final daysRemaining = installment.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0 || installment.status == 'overdue';

    return InkWell(
      onTap: () => _navigateToDetails(installment),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      installment.status == 'completed'
                          ? LucideIcons.checkCircle2
                          : installment.status == 'overdue'
                          ? LucideIcons.alertCircle
                          : LucideIcons.clock,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installment.customerName,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A192F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(installment.status),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // WhatsApp Button (only for active/overdue installments)
                  // TODO: Enable when customer phone data is available
                  // if (installment.status != 'completed' && hasPhoneNumber)
                  //   _buildWhatsAppButton(installment),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(value, installment),
                    icon: const Icon(
                      LucideIcons.moreVertical,
                      color: Color(0xFF64748B),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(LucideIcons.eye, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'عرض التفاصيل',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'payment',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.banknote,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'تسجيل دفعة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (installment.status != 'completed')
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.check,
                                size: 18,
                                color: Color(0xFF3B82F6),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'إكمال القسط',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      'المبلغ المتبقي',
                      '${_formatNumber(installment.remainingAmount)} د.ع',
                      LucideIcons.wallet,
                      const Color(0xFF0A192F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      'المبلغ المدفوع',
                      '${_formatNumber(installment.paidAmount)} د.ع',
                      LucideIcons.calendar,
                      const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverdue
                          ? LucideIcons.alertTriangle
                          : LucideIcons.calendarClock,
                      color: isOverdue
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverdue
                            ? 'متأخر عن الدفع بـ ${daysRemaining.abs()} يوم'
                            : 'تاريخ الاستحقاق: ${intl.DateFormat('yyyy/MM/dd').format(installment.dueDate)}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: isOverdue
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Status indicator (replaced progress bar since we don't have months data)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            installment.status == 'completed'
                                ? LucideIcons.checkCircle2
                                : LucideIcons.clock,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(installment.status),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(app_models.InstallmentModel installment) {
    // Create a CustomerModel from available data
    final customer = CustomerModel(
      id: installment.customerId,
      fullName: installment.customerName,
      phone: '', // Will be loaded from DB in details screen if needed
      address: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallmentDetailsScreen(
          installmentPlanId: installment.id,
          customer: customer,
        ),
      ),
    );
  }

  void _handleMenuAction(
    String value,
    app_models.InstallmentModel installment,
  ) {
    switch (value) {
      case 'view':
        _navigateToDetails(installment);
        break;
      case 'payment':
        // TODO: Navigate to payment screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تسجيل الدفعة - قريباً')));
        break;
      case 'complete':
        // TODO: Handle complete installment
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('إكمال القسط - قريباً')));
        break;
    }
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A192F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'completed':
        message = 'لا توجد أقساط مكتملة';
        icon = LucideIcons.checkCircle2;
        break;
      case 'overdue':
        message = 'لا توجد أقساط متأخرة';
        icon = LucideIcons.alertCircle;
        break;
      default:
        message = 'لا توجد أقساط';
        icon = LucideIcons.fileText;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
